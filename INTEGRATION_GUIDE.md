# BBeta Flutter + Django Backend Integration Guide

## ✅ Project Setup

**Backend:** `c:\Users\DevOps\Desktop\bud` (Django)  
**Frontend:** `c:\Users\DevOps\Desktop\bbeta` (Flutter)

---

## 🔌 API Endpoint Mapping

All Flutter API calls go to Django backend with baseUrl: `http://10.0.2.2:8000/api`

| Feature | Flutter Method | Django Endpoint | Status |
|---------|---|---|---|
| **Register** | `ApiService.register()` | `POST /api/auth/register/` | ✅ Implemented |
| **Verify Email** | `ApiService.verifyEmail()` | `POST /api/auth/register/verify_email/` | ✅ Implemented |
| **Login** | `ApiService.login()` | `POST /api/auth/login/` | ✅ Implemented |
| **Google Auth** | `ApiService.googleAuth()` | `POST /api/auth/google/` | ✅ Implemented |
| **Get Profile** | `ApiService.getProfile()` | `GET /api/auth/profile/profile/` | ✅ Implemented |
| **Logout** | `ApiService.logout()` | `POST /api/auth/logout/logout/` | ✅ Implemented |
| **Refresh Token** | `_refreshToken()` | `POST /api/auth/refresh/` | ✅ Implemented |
| **Get Books** | `ApiService.getBooks()` | `GET /api/books/` | ✅ Implemented |
| **Get Reading Stats** | `ApiService.getReadingStats()` | `GET /api/reading/progress/stats/` | ✅ Implemented |
| **Get Currently Reading** | `ApiService.getCurrentlyReading()` | `GET /api/reading/progress/currently-reading/` | ✅ Implemented |

---

## 🔐 Authentication Flow

### 1. Email Signup Flow
```
User enters email/password
         ↓
POST /api/auth/register/ 
(serializer validates → creates user → sends verification email)
         ↓
Backend returns HTTP 201 with message
         ↓
Flutter navigates to VerifyEmailScreen
         ↓
User enters 6-digit code
         ↓
POST /api/auth/register/verify_email/ with {code: "123456"}
         ↓
Backend verifies token → marks user as verified → generates JWT tokens
         ↓
Backend returns HTTP 200 with {access, refresh, user}
         ↓
Flutter saves tokens to secure storage → navigates to Dashboard
```

### 2. Google Signup Flow
```
User taps "Sign in with Google"
         ↓
Flutter gets Google ID token
         ↓
POST /api/auth/google/ with {credential: "google_id_token"}
         ↓
Backend verifies token with Google → gets user email
         ↓
Django creates/updates user with email_verified=True
         ↓
Backend returns HTTP 200 with {access, refresh, user}
         ↓
Flutter saves tokens → navigates to Dashboard
```

### 3. Login Flow
```
User enters email/password
         ↓
POST /api/auth/login/
(backend validates credentials)
         ↓
Backend checks: 
  - user.email_verified == True
  - user.is_active == True
         ↓
Backend returns HTTP 200 with {access, refresh, user}
         ↓
Flutter saves tokens → navigates to Dashboard
```

---

## 🐛 Troubleshooting Checklist

### Issue: "Something went wrong. Please try again."

**Step 1: Check Backend is Running**
```powershell
cd c:\Users\DevOps\Desktop\bud
python manage.py runserver 0.0.0.0:8000
```

Expected output:
```
Starting development server at http://0.0.0.0:8000/
```

**Step 2: Verify Network Connection**
From your Android device/emulator, check if you can reach the backend:
```bash
adb shell
ping 10.0.2.2  # Should succeed
```

**Step 3: Check the Detailed Logs**

In Flutter console (after running `flutter run`), look for:
- 📤 `[API]` messages showing requests
- 📥 `[API]` messages showing responses  
- ❌ `[API]` messages showing errors
- ⚠️ `[Auth]` messages showing auth errors
- 🔍 `[Auth]` Error Response Data

**Example: Email Sending Failure**
```
⚠️ [Auth] SignUp Error: email: Could not send verification email: ...
📥 [API] Response 400: /auth/register/
📥 [API] Data: {email: ["Could not send verification email: ..."], ...}
```

### Issue: Email Verification Code Not Received

**Check Backend Email Configuration:**

In `c:\Users\DevOps\Desktop\bud\.env`:
```env
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=smtp.gmail.com
EMAIL_HOST_USER=hamzakatende51@gmail.com
EMAIL_HOST_PASSWORD=jcql nfli eabg juzo  # App-specific password required!
```

**Test Email Sending Manually:**
```python
# In Django shell
python manage.py shell
>>> from django.core.mail import send_mail
>>> send_mail(
...     'Test Subject',
...     'Test message',
...     'hamzakatende51@gmail.com',
...     ['test@example.com'],
...     fail_silently=False
... )
```

If this fails, your Gmail password/config is wrong.

**To use Gmail:**
1. Enable 2-Factor Authentication on your Gmail account
2. Generate an **App Password** (not regular password!)
3. Use the 16-character app password in `.env`

### Issue: "Invalid token" or "Token expired" on Email Verification

The token is likely:
- Expired (tokens are valid for 24 hours)
- Already used
- Invalid format (must be exactly 6 digits)

Check in Django admin:
```
http://localhost:8000/admin/
Login → accounts → Email Verification Tokens
```

---

## 📱 Testing Workflow

### Test Email Signup
```
1. Open Flutter app → SignUp screen
2. Email: testuser@example.com
3. Password: TestPass123!
4. Confirm: TestPass123!
5. Click "Sign Up"

Expected:
   ✅ HTTP 201 response
   ✅ Navigation to VerifyEmailScreen
   ✅ Email received at testuser@example.com with 6-digit code
   ✅ Enter code → HTTP 200 response → Dashboard
```

### Test Google Signup
```
1. Click "Sign up with Google"
2. Select Google account
3. Authorize app

Expected:
   ✅ HTTP 200 response
   ✅ Direct navigation to Dashboard (no email verification needed)
   ✅ JWT tokens saved to secure storage
```

### Test Login
```
1. Go to LoginScreen (after logout or restart)
2. Email: testuser@example.com
3. Password: TestPass123!

Expected:
   ✅ HTTP 200 response
   ✅ Navigation to Dashboard
   ✅ Dashboard shows user profile
```

### Test Dashboard Data Loading
```
Expected GET requests:
   GET /api/auth/profile/profile/
   GET /api/reading/progress/stats/
   GET /api/reading/progress/currently-reading/
   GET /api/books/

Check Flutter console for:
   📥 All 4 responses with HTTP 200
   ✅ Dashboard displays data (greeting, stats cards, reading list)
```

---

## 🔧 Configuration

### Backend URL
In `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://10.0.2.2:8000/api';
```

**For different environments:**
- Local emulator: `http://10.0.2.2:8000/api`
- Physical device on same WiFi: `http://<your-pc-ip>:8000/api`
- Production (Vercel): `https://your-backend.vercel.app/api`

After changing baseUrl:
```bash
flutter clean
flutter pub get
flutter run
```

---

## 🧪 Debug Logging

All API calls now include detailed console logging:

```
📤 [API] POST /auth/register/
📤 [API] Data: {email: test@example.com, password: ..., password2: ...}
📥 [API] Response 201: /auth/register/
📥 [API] Data: {message: User registered successfully...}
```

If you see an error:
```
❌ [API] Error: ...
❌ [API] Status: 400
❌ [API] Response: {email: ["Could not send verification email"]}
⚠️ [Auth] SignUp Error: email: Could not send verification email
```

This means the Django backend encountered an error during signup.

---

## 📋 Common Django Endpoints Reference

All endpoints require `/api` prefix in the URL path:

**Auth Endpoints:**
- `POST /api/auth/register/` — Create new user (no auth required)
- `POST /api/auth/register/verify_email/` — Verify email with code (no auth required)
- `POST /api/auth/login/` — Login with email/password (no auth required)
- `POST /api/auth/google/` — Google OAuth (no auth required)
- `GET /api/auth/profile/profile/` — Get user profile (requires Bearer token)
- `POST /api/auth/logout/logout/` — Logout (requires Bearer token)
- `POST /api/auth/refresh/` — Refresh access token (no auth required)

**Books Endpoints:**
- `GET /api/books/` — List all books (requires Bearer token)
- `GET /api/books/{id}/` — Get book details (requires Bearer token)

**Reading Endpoints:**
- `GET /api/reading/progress/` — Get all reading progress (requires Bearer token)
- `GET /api/reading/progress/stats/` — Get reading stats (requires Bearer token)
- `GET /api/reading/progress/currently-reading/` — Get currently reading books (requires Bearer token)

---

## ✨ Next Steps

1. **Start Backend:**
   ```bash
   cd c:\Users\DevOps\Desktop\bud
   python manage.py runserver 0.0.0.0:8000
   ```

2. **Run Flutter App:**
   ```bash
   cd c:\Users\DevOps\Desktop\bbeta
   flutter run
   ```

3. **Monitor Logs:** Watch the Flutter console for debug messages

4. **Test Signup:** Try creating a new account and entering verification code

5. **Check Errors:** If signup fails, look for detailed error messages in the logs

---

**Last Updated:** March 1, 2026
