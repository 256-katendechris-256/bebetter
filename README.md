# BeBetter Book Club

A Flutter mobile application for book club management, reading tracking, and community engagement.

## Features

### Authentication
- Email/password registration with email verification
- Google Sign-In integration
- Secure token storage with auto-refresh

### Home Dashboard
- Personalized greeting based on time of day
- Reading statistics (XP, streak, books read, hours)
- Currently reading section with progress tracking
- Daily inspirational quotes from ZenQuotes API

### Library
- Browse all available books
- Search by title or author
- Bookmark/save books for later
- PDF reading with progress tracking

### Reading Experience
- In-app PDF reader using pdfx
- Session logging (pages read, time spent)
- XP and streak system for gamification
- Offline reading support for downloaded books

### Bookstore
- Browse nearby bookstores with geolocation
- View store-specific book catalogs
- Shopping cart with single-store enforcement
- Order placement

### Notifications
- Firebase Cloud Messaging integration
- In-app notification inbox
- Customizable notification preferences
- Streak alerts, league updates, and goal reminders

### Downloads & Offline
- Download books for offline reading
- Storage management
- Connectivity-aware reading experience

## Project Structure

```
lib/
├── Auth/                    # Authentication screens and service
│   ├── auth_service.dart
│   ├── login.dart
│   ├── signup.dart
│   └── verify_email.dart
├── config/                  # App configuration
│   ├── env_config.dart      # Environment-specific settings
│   └── theme.dart           # Design tokens and styles
├── models/                  # Data models
│   ├── book.dart
│   ├── bookstore_book.dart
│   ├── genre.dart
│   ├── notification.dart
│   ├── paginated_response.dart
│   ├── reading_stats.dart
│   ├── store.dart
│   ├── user.dart
│   └── user_book.dart
├── screens/                 # App screens
│   ├── book_reader_screen.dart
│   ├── bookstore_cart_screen.dart
│   ├── bookstore_home_screen.dart
│   ├── downloads_screen.dart
│   ├── notification_preferences_screen.dart
│   ├── notifications_screen.dart
│   ├── offline_reader_wrapper.dart
│   ├── settings_screen.dart
│   └── store_books_screen.dart
├── services/                # Business logic services
│   ├── api_service.dart     # REST API client
│   ├── cart_service.dart    # Shopping cart
│   ├── download_service.dart
│   ├── notification_service.dart
│   └── pdf_reader_service.dart
├── widgets/                 # Reusable widgets
│   ├── app_bottom_nav.dart
│   ├── app_search_bar.dart
│   ├── app_top_bar.dart
│   ├── download_button.dart
│   ├── empty_state.dart
│   ├── leaderboard_row.dart
│   ├── library_book_card.dart
│   ├── quote_carousel.dart
│   ├── reading_card.dart
│   └── stats_hero.dart
├── dashboard.dart           # Main app shell
├── main.dart                # App entry point
├── splash_screen.dart
└── welcome_screen.dart
```

## Getting Started

### Prerequisites
- Flutter SDK ^3.10.8
- Android Studio / VS Code with Flutter extensions
- Firebase project configured

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd bebetter
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
```bash
flutterfire configure
```

4. Set environment (optional):
```dart
// In main.dart, before runApp():
EnvConfig.setEnvironment(Environment.development);
```

5. Run the app:
```bash
flutter run
```

## Environment Configuration

The app supports three environments:

| Environment | API Base URL | Logging |
|-------------|--------------|---------|
| Development | `http://10.0.2.2:8000/api` | Enabled |
| Staging | `https://bud-staging.vercel.app/api` | Enabled |
| Production | `https://bud-ruby.vercel.app/api` | Disabled |

Switch environments in code:
```dart
EnvConfig.setEnvironment(Environment.development);
```

## API Integration

The app integrates with a Django REST Framework backend:

- **Auth**: `/api/auth/` - Registration, login, Google OAuth, profile
- **Books**: `/api/books/` - Library, search, upload
- **Reading**: `/api/reading/progress/` - Progress tracking, sessions, stats
- **Notifications**: `/api/notifications/` - FCM tokens, preferences, inbox

## Dependencies

| Package | Purpose |
|---------|---------|
| `dio` | HTTP client with interceptors |
| `flutter_secure_storage` | Secure token storage |
| `google_sign_in` | Google authentication |
| `pdfx` | PDF rendering |
| `firebase_core` | Firebase SDK |
| `firebase_messaging` | Push notifications |
| `flutter_local_notifications` | Local notifications |
| `connectivity_plus` | Network status |
| `geolocator` | Location services |
| `path_provider` | File system access |
| `shared_preferences` | Key-value storage |

## Testing

Run tests:
```bash
flutter test
```

Test coverage includes:
- Model serialization/deserialization
- Environment configuration
- Reading stats calculations

## Architecture Notes

### State Management
Currently uses `StatefulWidget` with `setState`. Consider migrating to Riverpod for:
- Better testability
- Separation of concerns
- Easier state sharing

### Data Models
Typed Dart models exist for all API entities:
- `User` - Authentication and profile
- `Book` / `Genre` - Library content
- `UserBook` / `ReadingStats` - Progress tracking
- `NotificationLog` / `NotificationPreferences` - Notifications

### Navigation
Uses named routes defined in `MaterialApp`:
- `/login` - Login screen
- `/signup` - Registration screen
- `/dashboard` - Main app
- `/welcome` - Welcome/onboarding
- `/notifications` - Notification inbox

## Known Limitations

1. **Leaderboard**: Uses static data - backend API needed
2. **Chat**: Placeholder only - not implemented
3. **Bookmarks**: In-memory only - lost on restart
4. **Firebase**: Only configured for Android

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Write/update tests
5. Submit a pull request

## License

This project is private and not licensed for public use.
