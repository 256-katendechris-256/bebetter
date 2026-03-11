import { useState, useEffect, useRef } from "react";

const PDFJS_URL = "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js";
const PDFJS_WORKER = "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js";

function usePDFJS() {
  const [ready, setReady] = useState(false);
  useEffect(() => {
    if (window.pdfjsLib) { setReady(true); return; }
    const s = document.createElement("script");
    s.src = PDFJS_URL;
    s.onload = () => { window.pdfjsLib.GlobalWorkerOptions.workerSrc = PDFJS_WORKER; setReady(true); };
    document.head.appendChild(s);
  }, []);
  return ready;
}

function isBold(fontName = "") {
  const f = fontName.toLowerCase();
  return f.includes("bold") || f.includes("heavy") || f.includes("black") || f.includes("demi");
}

function isLikelyChapterTitle(text = "") {
  const t = text.trim();
  if (t.length < 3 || t.length > 120) return false;
  if (t.split(" ").length > 15) return false; // Too many words to be a heading
  // Exclude things that are clearly not titles
  if (/^\d+$/.test(t)) return false;
  if (/^(the|a|an|and|or|but|in|on|at|to|for|of|with|by|from)$/i.test(t)) return false;
  return true;
}

async function extractTextFromPDF(file) {
  const arrayBuffer = await file.arrayBuffer();
  const pdf = await window.pdfjsLib.getDocument({ data: arrayBuffer }).promise;

  let fullText = "";
  const boldCandidates = []; // { text, position } where position = char offset in fullText

  for (let pageNum = 1; pageNum <= pdf.numPages; pageNum++) {
    const page = await pdf.getPage(pageNum);
    const content = await page.getTextContent({ includeMarkedContent: false });

    // Group items by their vertical position to detect lines
    const lines = {};
    for (const item of content.items) {
      if (!item.str || !item.str.trim()) continue;
      const y = Math.round(item.transform[5]); // vertical position
      if (!lines[y]) lines[y] = [];
      lines[y].push(item);
    }

    // Process lines top-to-bottom (descending y in PDF coords)
    const sortedYs = Object.keys(lines).map(Number).sort((a, b) => b - a);

    for (const y of sortedYs) {
      const lineItems = lines[y];
      const lineText = lineItems.map(i => i.str).join(" ").trim();
      if (!lineText) continue;

      // Check if majority of items in this line are bold
      const boldItems = lineItems.filter(i => isBold(i.fontName));
      const isBoldLine = boldItems.length > 0 && boldItems.length >= lineItems.length * 0.6;

      if (isBoldLine && isLikelyChapterTitle(lineText)) {
        boldCandidates.push({ text: lineText, charOffset: fullText.length });
      }

      fullText += lineText + "\n";
    }
    fullText += "\n";
  }

  // De-duplicate very similar bold candidates
  const dedupedBold = boldCandidates.filter((c, i) => {
    if (i === 0) return true;
    const prev = boldCandidates[i - 1].text.toLowerCase().trim();
    const curr = c.text.toLowerCase().trim();
    return prev !== curr;
  });

  return {
    text: fullText,
    numPages: pdf.numPages,
    boldHeadings: dedupedBold // [{ text, charOffset }]
  };
}

async function organizeWithClaude(title, text, boldHeadings) {
  const truncated = text.slice(0, 10000);

  // Build a clean list of bold headings to show Claude
  const headingsList = boldHeadings.slice(0, 60).map((h, i) =>
    `${i + 1}. "${h.text}" (at ~${Math.round((h.charOffset / text.length) * 100)}% into document)`
  ).join("\n");

  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      model: "claude-sonnet-4-20250514",
      max_tokens: 2000,
      messages: [{
        role: "user",
        content: `You are analysing a PDF book. Your job is to identify the real chapter titles and extract book metadata.

IMPORTANT INSTRUCTIONS:
- The PDF extraction has detected the following BOLD text lines from the document. These are the most likely chapter/section titles since they appear in bold in the original PDF.
- Use these bold headings to identify chapters. Group sub-sections under their parent chapter where appropriate.
- For the author: scan the text carefully for author names — they often appear on the cover page, title page, or in the introduction. Look for phrases like "by [Name]", "Author:", or a standalone name near the beginning.
- For "The Let Them Theory" or similar books, the author is Mel Robbins.
- Create between 5 and 20 chapters based on the bold headings — use all that are real chapter-level headings, not sub-items.

BOLD HEADINGS DETECTED (these are in bold in the original PDF — USE THESE as chapters):
${headingsList || "No bold headings detected — infer chapters from content."}

FIRST 10,000 CHARACTERS OF TEXT:
${truncated}

Return ONLY raw JSON, no markdown, no explanation:
{
  "title": "exact book title",
  "author": "author full name (look carefully — for Let Them Theory it is Mel Robbins)",
  "description": "2-3 sentence summary of the book",
  "chapters": [
    {
      "id": "ch1",
      "title": "Chapter Title (use the exact bold heading text)",
      "summary": "1-2 sentence description of what this chapter covers",
      "startRatio": 0.05
    }
  ]
}

startRatio is a 0-1 float showing where this chapter starts in the full document text.`
      }]
    })
  });

  const data = await res.json();
  const raw = data.content?.[0]?.text || "{}";
  try {
    const parsed = JSON.parse(raw.replace(/```json|```/g, "").trim());
    // Fallback: if Claude didn't populate chapters, build from boldHeadings directly
    if (!parsed.chapters || parsed.chapters.length === 0) {
      parsed.chapters = boldHeadings.slice(0, 20).map((h, i) => ({
        id: "ch" + (i + 1),
        title: h.text,
        summary: "",
        startRatio: h.charOffset / text.length
      }));
    }
    return parsed;
  } catch {
    // Absolute fallback
    return {
      title,
      author: "Unknown",
      description: "Uploaded document.",
      chapters: boldHeadings.slice(0, 20).map((h, i) => ({
        id: "ch" + (i + 1),
        title: h.text,
        summary: "",
        startRatio: h.charOffset / text.length
      }))
    };
  }
}

function getChapterText(book, idx) {
  const chapters = book.chapters;
  const len = book.fullText.length;
  const start = Math.floor((chapters[idx].startRatio ?? (idx / chapters.length)) * len);
  const endRatio = idx + 1 < chapters.length
    ? (chapters[idx + 1].startRatio ?? ((idx + 1) / chapters.length))
    : 1;
  const end = Math.floor(endRatio * len);
  return book.fullText.slice(start, end).trim();
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const FONTS = `@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,600;0,700;1,400&family=EB+Garamond:ital,wght@0,400;0,500;1,400&display=swap');`;

const css = `
* { margin:0; padding:0; box-sizing:border-box; }
:root {
  --bg:#0f0e0c; --bg2:#0d0c0a; --bg3:#13120f;
  --border:#2a2520; --border2:#1e1c18;
  --gold:#c9a96e; --gold-dim:#8a6f42;
  --text:#e8e0d0; --text-dim:#b5a898;
  --text-muted:#6b6355; --text-faint:#3a342c;
  --shelf-w:260px; --toc-w:240px;
}
body { background:var(--bg); }
.app { height:100vh; display:flex; flex-direction:column; background:var(--bg); color:var(--text); font-family:'EB Garamond',serif; }

/* HEADER */
.header { flex-shrink:0; border-bottom:1px solid var(--border); padding:0 32px; height:56px; display:flex; align-items:center; justify-content:space-between; background:var(--bg); }
.logo { font-family:'Playfair Display',serif; font-size:20px; color:var(--gold); letter-spacing:2px; text-transform:uppercase; }
.logo span { color:var(--text); }
.header-right { display:flex; align-items:center; gap:16px; }
.lib-count { font-size:12px; color:var(--text-muted); letter-spacing:1px; }
.add-btn { padding:7px 18px; background:var(--gold); color:var(--bg); border:none; font-family:'EB Garamond',serif; font-size:14px; letter-spacing:1px; cursor:pointer; transition:opacity .2s; }
.add-btn:hover { opacity:.85; }

/* LAYOUT */
.layout { flex:1; display:flex; overflow:hidden; }

/* SHELF */
.shelf { width:var(--shelf-w); min-width:var(--shelf-w); background:var(--bg2); border-right:1px solid var(--border); display:flex; flex-direction:column; overflow:hidden; }
.shelf-head { padding:18px 20px 12px; border-bottom:1px solid var(--border2); flex-shrink:0; }
.shelf-label { font-size:10px; letter-spacing:3px; text-transform:uppercase; color:var(--text-muted); }
.shelf-list { overflow-y:auto; flex:1; padding:6px 0; }
.shelf-item { padding:11px 20px; cursor:pointer; border-left:3px solid transparent; transition:all .15s; }
.shelf-item:hover { background:#161410; }
.shelf-item.active { border-left-color:var(--gold); background:#161410; }
.shelf-title { font-family:'Playfair Display',serif; font-size:13px; color:#c9b99a; margin-bottom:2px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.shelf-author { font-size:11px; color:var(--text-faint); }
.shelf-empty { padding:24px 20px; font-size:13px; color:var(--text-faint); font-style:italic; text-align:center; line-height:1.7; }

/* READING AREA */
.reading-area { flex:1; display:flex; overflow:hidden; }
.reader-scroll { flex:1; overflow-y:auto; }

/* WELCOME */
.welcome { display:flex; flex-direction:column; align-items:center; justify-content:center; min-height:100%; padding:80px 40px; text-align:center; }
.welcome-glyph { font-size:72px; opacity:.12; margin-bottom:28px; }
.welcome h2 { font-family:'Playfair Display',serif; font-size:36px; font-weight:400; color:#c9b99a; margin-bottom:12px; }
.welcome p { color:var(--text-muted); font-size:17px; line-height:1.8; max-width:400px; }

/* COVER PAGE */
.cover-page { padding:64px 72px 48px; background:linear-gradient(180deg,#13120f 0%,var(--bg) 100%); border-bottom:1px solid var(--border2); }
.cover-eyebrow { font-size:10px; letter-spacing:4px; text-transform:uppercase; color:var(--gold); margin-bottom:20px; }
.cover-title { font-family:'Playfair Display',serif; font-size:46px; font-weight:400; color:var(--text); line-height:1.15; margin-bottom:10px; }
.cover-author { font-size:19px; color:var(--text-muted); font-style:italic; margin-bottom:24px; }
.cover-desc { font-size:16px; color:#8a7f72; line-height:1.85; max-width:580px; }
.cover-stats { display:flex; gap:36px; margin-top:36px; }
.stat-val { font-family:'Playfair Display',serif; font-size:26px; color:var(--gold); display:block; }
.stat-label { font-size:10px; letter-spacing:2px; text-transform:uppercase; color:var(--text-faint); }

/* TABLE OF CONTENTS */
.toc-section { padding:48px 72px 72px; }
.toc-heading { font-size:10px; letter-spacing:4px; text-transform:uppercase; color:var(--text-faint); margin-bottom:28px; padding-bottom:14px; border-bottom:1px solid var(--border2); display:flex; align-items:center; justify-content:space-between; }
.toc-start-btn { font-size:12px; color:var(--gold); letter-spacing:1px; cursor:pointer; text-transform:uppercase; transition:opacity .2s; }
.toc-start-btn:hover { opacity:.7; }

.toc-row { display:flex; align-items:flex-start; padding:16px 0; border-bottom:1px solid #161410; cursor:pointer; transition:all .15s; }
.toc-row:hover .toc-row-title { color:var(--gold); }
.toc-row:hover .toc-arrow { opacity:1; transform:translateX(0); }
.toc-num { font-family:'Playfair Display',serif; font-size:11px; letter-spacing:2px; color:var(--text-faint); min-width:52px; padding-top:5px; flex-shrink:0; }
.toc-row-body { flex:1; }
.toc-row-title { font-family:'Playfair Display',serif; font-size:18px; font-weight:400; color:#c9b99a; margin-bottom:4px; transition:color .15s; line-height:1.3; }
.toc-row-summary { font-size:13px; color:var(--text-muted); line-height:1.55; }
.toc-arrow { color:var(--gold); font-size:15px; opacity:0; transform:translateX(-8px); transition:all .2s; padding-top:5px; padding-left:16px; flex-shrink:0; }

/* STICKY TOC PANEL */
.toc-panel { width:var(--toc-w); min-width:var(--toc-w); border-left:1px solid var(--border2); background:var(--bg2); overflow-y:auto; padding:24px 0; flex-shrink:0; }
.toc-panel-head { font-size:10px; letter-spacing:3px; text-transform:uppercase; color:var(--text-muted); padding:0 20px 14px; border-bottom:1px solid var(--border2); margin-bottom:6px; }
.toc-panel-item { padding:9px 20px; cursor:pointer; border-left:3px solid transparent; transition:all .15s; }
.toc-panel-item:hover { background:#0f0e0c; }
.toc-panel-item.active { border-left-color:var(--gold); background:#0f0e0c; }
.toc-panel-item.active .tpi-title { color:var(--gold); }
.tpi-num { font-size:10px; letter-spacing:2px; color:var(--text-faint); margin-bottom:2px; }
.tpi-title { font-family:'Playfair Display',serif; font-size:12px; color:#9a8f82; line-height:1.35; transition:color .15s; }
.toc-panel-back { padding:18px 20px 0; border-top:1px solid var(--border2); margin-top:10px; }
.toc-panel-back-btn { font-size:11px; letter-spacing:2px; text-transform:uppercase; color:var(--gold); cursor:pointer; transition:opacity .2s; }
.toc-panel-back-btn:hover { opacity:.7; }

/* CHAPTER READER */
.chapter-view { padding:52px 72px 80px; max-width:820px; }
.ch-nav-top { display:flex; align-items:center; justify-content:space-between; margin-bottom:44px; }
.back-link { display:inline-flex; align-items:center; gap:8px; color:var(--gold); font-size:12px; letter-spacing:1.5px; text-transform:uppercase; cursor:pointer; transition:opacity .2s; background:none; border:none; }
.back-link:hover { opacity:.7; }
.ch-counter { font-size:12px; color:var(--text-faint); letter-spacing:1px; }
.ch-title { font-family:'Playfair Display',serif; font-size:36px; font-weight:400; color:var(--text); line-height:1.25; margin-bottom:12px; }
.ch-summary-banner { font-size:15px; color:var(--text-muted); font-style:italic; line-height:1.7; padding:18px 22px; border-left:2px solid var(--gold-dim); margin-bottom:36px; background:#13120f; }
.ch-rule { height:1px; background:var(--border2); margin-bottom:38px; }
.ch-text { font-size:18px; line-height:1.95; color:var(--text-dim); white-space:pre-wrap; word-break:break-word; }

/* CHAPTER BOTTOM NAV */
.ch-nav-bottom { display:flex; gap:1px; margin-top:72px; border-top:1px solid var(--border2); padding-top:28px; }
.ch-nav-btn { flex:1; padding:18px 22px; background:var(--bg3); border:1px solid var(--border2); cursor:pointer; transition:all .2s; display:flex; align-items:center; gap:14px; text-align:left; }
.ch-nav-btn:hover { background:#161410; border-color:var(--gold-dim); }
.ch-nav-btn.next-btn { flex-direction:row-reverse; text-align:right; }
.ch-nav-btn:disabled { opacity:.2; cursor:default; pointer-events:none; }
.cnb-dir { font-size:10px; letter-spacing:3px; text-transform:uppercase; color:var(--text-faint); margin-bottom:4px; }
.cnb-title { font-family:'Playfair Display',serif; font-size:14px; color:#c9b99a; line-height:1.3; }
.cnb-arrow { font-size:20px; color:var(--gold-dim); flex-shrink:0; }

/* UPLOAD MODAL */
.modal-bg { position:fixed; inset:0; background:rgba(0,0,0,.9); display:flex; align-items:center; justify-content:center; z-index:200; padding:24px; }
.modal { background:var(--bg3); border:1px solid var(--border); padding:48px; max-width:500px; width:100%; animation:fadeUp .25s ease; }
@keyframes fadeUp { from{opacity:0;transform:translateY(16px)} to{opacity:1;transform:none} }
.modal h3 { font-family:'Playfair Display',serif; font-size:26px; font-weight:400; color:#c9b99a; margin-bottom:8px; }
.modal-sub { color:var(--text-muted); font-size:15px; margin-bottom:32px; line-height:1.65; }
.drop-zone { border:1px dashed #3a342c; padding:52px 24px; text-align:center; cursor:pointer; transition:all .2s; margin-bottom:20px; }
.drop-zone:hover,.drop-zone.drag-over { border-color:var(--gold); background:#16140f; }
.drop-icon { font-size:40px; opacity:.35; margin-bottom:14px; }
.drop-label { color:var(--text-muted); font-size:15px; }
.drop-label strong { color:var(--gold); }
.modal-note { font-size:13px; color:var(--text-faint); font-style:italic; margin-bottom:20px; line-height:1.5; }
.btn-cancel { display:block; width:100%; padding:10px; background:transparent; border:1px solid var(--border); color:var(--text-muted); font-family:'EB Garamond',serif; font-size:14px; cursor:pointer; transition:all .2s; }
.btn-cancel:hover { border-color:var(--text-muted); color:var(--text); }
input[type=file] { display:none; }
.prog-area { padding:20px 0; }
.prog-label { font-size:14px; color:var(--text-muted); margin-bottom:12px; }
.prog-track { height:2px; background:var(--border2); border-radius:2px; overflow:hidden; }
.prog-fill { height:100%; background:var(--gold); transition:width .4s ease; }
`;

// ─── App ──────────────────────────────────────────────────────────────────────

export default function App() {
  const pdfReady = usePDFJS();
  const [books, setBooks] = useState([]);
  const [selectedBook, setSelectedBook] = useState(null);
  const [chapterIdx, setChapterIdx] = useState(null);
  const [showUpload, setShowUpload] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [progress, setProgress] = useState({ step: "", pct: 0 });
  const [dragOver, setDragOver] = useState(false);
  const fileRef = useRef();
  const readerRef = useRef();

  useEffect(() => { loadBooks(); }, []);

  useEffect(() => {
    readerRef.current?.scrollTo({ top: 0, behavior: "smooth" });
  }, [chapterIdx, selectedBook]);

  async function loadBooks() {
    try {
      const result = await window.storage.list("book:", true);
      if (!result) return;
      const loaded = [];
      for (const key of result.keys) {
        try {
          const r = await window.storage.get(key, true);
          if (r) loaded.push(JSON.parse(r.value));
        } catch {}
      }
      loaded.sort((a, b) => b.createdAt - a.createdAt);
      setBooks(loaded);
    } catch {}
  }

  async function handleFile(file) {
    if (!file || file.type !== "application/pdf") return alert("Please upload a PDF file.");
    if (!pdfReady) return alert("PDF engine still loading, try again in a moment.");
    setUploading(true);
    setProgress({ step: "Extracting text & detecting bold headings…", pct: 20 });
    try {
      const { text, numPages, boldHeadings } = await extractTextFromPDF(file);
      setProgress({ step: `Found ${boldHeadings.length} bold headings — analysing structure…`, pct: 50 });
      const name = file.name.replace(/\.pdf$/i, "");
      const structured = await organizeWithClaude(name, text, boldHeadings);
      setProgress({ step: "Saving to shared library…", pct: 85 });

      const book = {
        id: "book:" + Date.now(),
        title: structured.title || name,
        author: structured.author || "Unknown",
        description: structured.description || "",
        chapters: structured.chapters || [],
        fullText: text,
        numPages,
        wordCount: text.split(/\s+/).length,
        createdAt: Date.now()
      };
      await window.storage.set(book.id, JSON.stringify(book), true);
      setProgress({ step: "Done!", pct: 100 });
      await new Promise(r => setTimeout(r, 500));
      setBooks(prev => [book, ...prev]);
      setSelectedBook(book);
      setChapterIdx(null);
      setShowUpload(false);
    } catch (e) {
      alert("Error: " + e.message);
    } finally {
      setUploading(false);
      setProgress({ step: "", pct: 0 });
    }
  }

  const chapters = selectedBook?.chapters || [];
  const isReading = selectedBook && chapterIdx !== null;

  return (
    <>
      <style>{FONTS}{css}</style>
      <div className="app">
        {/* Header */}
        <header className="header">
          <div className="logo">📖 Tome<span>Reader</span></div>
          <div className="header-right">
            <span className="lib-count">{books.length} Book{books.length !== 1 ? "s" : ""} in Library</span>
            <button className="add-btn" onClick={() => setShowUpload(true)}>+ Add Book</button>
          </div>
        </header>

        <div className="layout">
          {/* Shelf sidebar */}
          <aside className="shelf">
            <div className="shelf-head"><div className="shelf-label">Library</div></div>
            <div className="shelf-list">
              {books.length === 0
                ? <div className="shelf-empty">No books yet.<br />Upload a PDF to begin.</div>
                : books.map(b => (
                  <div key={b.id}
                    className={"shelf-item" + (selectedBook?.id === b.id ? " active" : "")}
                    onClick={() => { setSelectedBook(b); setChapterIdx(null); }}>
                    <div className="shelf-title">{b.title}</div>
                    <div className="shelf-author">{b.author}</div>
                  </div>
                ))
              }
            </div>
          </aside>

          {/* Reading area */}
          <div className="reading-area">
            <div className="reader-scroll" ref={readerRef}>

              {!selectedBook && (
                <div className="welcome">
                  <div className="welcome-glyph">📚</div>
                  <h2>Your Shared Library</h2>
                  <p>Upload any PDF — bold text is used to automatically detect real chapter titles, no matter how they're formatted.</p>
                </div>
              )}

              {/* Cover + TOC */}
              {selectedBook && chapterIdx === null && (
                <>
                  <div className="cover-page">
                    <div className="cover-eyebrow">Now Reading</div>
                    <h1 className="cover-title">{selectedBook.title}</h1>
                    <div className="cover-author">by {selectedBook.author}</div>
                    <div className="cover-desc">{selectedBook.description}</div>
                    <div className="cover-stats">
                      <div><span className="stat-val">{selectedBook.numPages}</span><span className="stat-label">Pages</span></div>
                      <div><span className="stat-val">{(selectedBook.wordCount / 1000).toFixed(1)}k</span><span className="stat-label">Words</span></div>
                      <div><span className="stat-val">{chapters.length}</span><span className="stat-label">Chapters</span></div>
                    </div>
                  </div>

                  <div className="toc-section">
                    <div className="toc-heading">
                      <span>Table of Contents</span>
                      <span className="toc-start-btn" onClick={() => setChapterIdx(0)}>Start Reading →</span>
                    </div>
                    {chapters.map((ch, i) => (
                      <div key={ch.id} className="toc-row" onClick={() => setChapterIdx(i)}>
                        <div className="toc-num">CH {String(i + 1).padStart(2, "0")}</div>
                        <div className="toc-row-body">
                          <div className="toc-row-title">{ch.title}</div>
                          {ch.summary && <div className="toc-row-summary">{ch.summary}</div>}
                        </div>
                        <div className="toc-arrow">→</div>
                      </div>
                    ))}
                  </div>
                </>
              )}

              {/* Chapter view */}
              {isReading && (
                <div className="chapter-view">
                  <div className="ch-nav-top">
                    <button className="back-link" onClick={() => setChapterIdx(null)}>← {selectedBook.title}</button>
                    <span className="ch-counter">Ch. {chapterIdx + 1} / {chapters.length}</span>
                  </div>

                  <h2 className="ch-title">{chapters[chapterIdx].title}</h2>
                  {chapters[chapterIdx].summary && (
                    <div className="ch-summary-banner">{chapters[chapterIdx].summary}</div>
                  )}
                  <div className="ch-rule" />
                  <div className="ch-text">{getChapterText(selectedBook, chapterIdx)}</div>

                  <div className="ch-nav-bottom">
                    <button className="ch-nav-btn" disabled={chapterIdx === 0} onClick={() => setChapterIdx(i => i - 1)}>
                      <span className="cnb-arrow">←</span>
                      <div>
                        <div className="cnb-dir">Previous</div>
                        <div className="cnb-title">{chapterIdx > 0 ? chapters[chapterIdx - 1].title : ""}</div>
                      </div>
                    </button>
                    <button className="ch-nav-btn next-btn" disabled={chapterIdx === chapters.length - 1} onClick={() => setChapterIdx(i => i + 1)}>
                      <span className="cnb-arrow">→</span>
                      <div>
                        <div className="cnb-dir">Next</div>
                        <div className="cnb-title">{chapterIdx < chapters.length - 1 ? chapters[chapterIdx + 1].title : ""}</div>
                      </div>
                    </button>
                  </div>
                </div>
              )}
            </div>

            {/* Sticky TOC panel (only while reading) */}
            {isReading && (
              <div className="toc-panel">
                <div className="toc-panel-head">Contents</div>
                {chapters.map((ch, i) => (
                  <div key={ch.id}
                    className={"toc-panel-item" + (i === chapterIdx ? " active" : "")}
                    onClick={() => setChapterIdx(i)}>
                    <div className="tpi-num">CH {String(i + 1).padStart(2, "0")}</div>
                    <div className="tpi-title">{ch.title}</div>
                  </div>
                ))}
                <div className="toc-panel-back">
                  <div className="toc-panel-back-btn" onClick={() => setChapterIdx(null)}>← Book Cover</div>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Upload modal */}
        {showUpload && (
          <div className="modal-bg" onClick={e => { if (!uploading && e.target === e.currentTarget) setShowUpload(false); }}>
            <div className="modal">
              <h3>Add to Library</h3>
              <p className="modal-sub">Upload a PDF — bold text in the document is used to precisely detect chapter titles automatically.</p>
              {uploading ? (
                <div className="prog-area">
                  <div className="prog-label">{progress.step}</div>
                  <div className="prog-track"><div className="prog-fill" style={{ width: progress.pct + "%" }} /></div>
                </div>
              ) : (
                <>
                  <div className={"drop-zone" + (dragOver ? " drag-over" : "")}
                    onDragOver={e => { e.preventDefault(); setDragOver(true); }}
                    onDragLeave={() => setDragOver(false)}
                    onDrop={e => { e.preventDefault(); setDragOver(false); handleFile(e.dataTransfer.files[0]); }}
                    onClick={() => fileRef.current.click()}>
                    <div className="drop-icon">📄</div>
                    <div className="drop-label">Drop your PDF here or <strong>click to browse</strong></div>
                    <input ref={fileRef} type="file" accept=".pdf" onChange={e => handleFile(e.target.files[0])} />
                  </div>
                  <p className="modal-note">Chapters are detected from bold text in the PDF, so even disguised or unlabelled chapters are identified correctly.</p>
                  <button className="btn-cancel" onClick={() => setShowUpload(false)}>Cancel</button>
                </>
              )}
            </div>
          </div>
        )}
      </div>
    </>
  );
}
