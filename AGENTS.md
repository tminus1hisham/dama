# DAMA Kenya Mobile App - Agent Documentation

## Project Overview

**DAMA Kenya** is a comprehensive Flutter mobile application for the Digital Asset Management Association (DAMA) in Kenya. The app provides a platform for members to access news, blogs, events, training resources, and manage their memberships.

- **App Name:** dama
- **Version:** 1.0.8+8
- **Flutter SDK:** ^3.27.2 (managed via FVM 3.29.3)
- **Package Name:** com.dama.mobile
- **Platforms:** Android, iOS, Web

---

## Architecture & Technology Stack

### Core Framework
- **Flutter:** Cross-platform UI framework
- **Dart:** Programming language

### State Management
- **GetX:** Primary state management and dependency injection
- **Provider:** Used for theme management and chat/sessions providers

### Backend Integration
- **Base API URL:** `https://api.damakenya.org/v1`
- **Chat Server:** `https://chats.damakenya.org` (WebSocket via Socket.IO)
- **Chat API:** `http://167.71.68.0:5000/v1`
- **Authentication:** JWT Bearer Token

### Key Dependencies
| Category | Package | Purpose |
|----------|---------|---------|
| State Management | `get` | Reactive state management |
| HTTP/Networking | `http` | REST API calls |
| WebSocket | `socket_io_client` | Real-time chat |
| Local Storage | `shared_preferences`, `flutter_secure_storage` | Data persistence |
| Firebase | `firebase_core`, `firebase_messaging` | Push notifications |
| Auth | `local_auth` | Biometric authentication |
| UI Components | `motion_tab_bar_v2`, `sidebarx`, `panara_dialogs` | Enhanced UI |
| Media | `image_picker`, `file_picker`, `flutter_pdfview` | File handling |
| Payments | `in_app_purchase` | Membership subscriptions |
| QR/Scanner | `qr_code_scanner_plus`, `qr_flutter` | Event verification |

---

## Project Structure

```
lib/
├── main.dart                    # Application entry point
├── app.dart                     # Main app widget with routing
├── routes/
│   └── routes.dart              # Route definitions and navigation
├── models/                      # Data models (34+ models)
│   ├── user_model.dart
│   ├── login_model.dart
│   ├── blogs_model.dart
│   ├── news_model.dart
│   ├── event_model.dart
│   └── ... (see API_DOCUMENTATION.md for complete list)
├── controller/                  # GetX controllers (40+ controllers)
│   ├── auth_controller.dart     # Authentication logic
│   ├── blog_controller.dart     # Blog operations
│   ├── events_controller.dart   # Event management
│   ├── payment_controller.dart  # M-Pesa payments
│   └── ...
├── services/                    # Business logic and API calls
│   ├── api_service.dart         # Main REST API service
│   ├── auth_service.dart        # Authentication service
│   ├── socket_service.dart      # WebSocket chat service
│   ├── local_storage_service.dart
│   ├── firebase_messaging_service.dart
│   └── deep_link_service.dart
├── providers/                   # Provider state management
│   ├── chat_provider.dart
│   └── sessions_provider.dart
├── views/                       # UI Screens
│   ├── auth/                    # Login, Register, OTP, Password reset
│   ├── dashboard.dart           # Main dashboard with tabs
│   ├── dashboard/               # Blogs, News, Events, Resources tabs
│   ├── drawer_screen/           # Side drawer screens
│   ├── selected_screens/        # Detail views
│   ├── chat/                    # Chat functionality
│   └── web/                     # Web-specific views
├── widgets/                     # Reusable UI components
│   ├── buttons/
│   ├── cards/
│   ├── inputs/
│   ├── modals/
│   ├── shimmer/                 # Loading skeletons
│   └── web/
└── utils/
    ├── constants.dart           # App constants, colors, API URLs
    ├── theme_provider.dart      # Dark/light theme
    └── utils.dart

test/
└── widget_test.dart             # Basic widget tests

android/                         # Android-specific configuration
ios/                            # iOS-specific configuration
web/                            # Web-specific configuration
images/                         # Asset images
```

---

## Build Commands

### Development
```bash
# Run on connected device
flutter run

# Run on specific device
flutter run -d <device_id>

# Run in debug mode with hot reload
flutter run --debug

# Run on web
flutter run -d chrome
```

### Build for Production
```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
flutter format .

# Run tests
flutter test
```

---

## Development Conventions

### Code Style
- Follows `package:flutter_lints/flutter.yaml` rules
- Use `debugPrint()` instead of `print()` for debug output
- Prefer single quotes for strings (optional, not enforced)
- Use const constructors where possible

### File Naming
- **Models:** `snake_case_model.dart` (e.g., `user_model.dart`)
- **Controllers:** `snake_case_controller.dart` (e.g., `auth_controller.dart`)
- **Views/Screens:** `snake_case_screen.dart` (e.g., `login_screen.dart`)
- **Widgets:** `snake_case.dart` for generic widgets, organized in subfolders

### State Management Patterns
1. **GetX Controllers:** Extend `GetxController` for reactive state
   - Use `.obs` for observable variables
   - Use `update()` for manual UI updates when needed
   - Controllers are injected via `Get.put()` in `main.dart`

2. **Providers:** Used for:
   - `ThemeProvider` - Dark/light mode
   - `ChatProvider` - Chat state
   - `SessionsProvider` - Training sessions

### API Integration Pattern
```dart
// Service layer handles HTTP calls
class ApiService {
  Future<Model> getData() async {
    final response = await http.get(...);
    // Handle 401/403 with HandleUnauthorizedService
    return Model.fromJson(json);
  }
}

// Controller handles business logic
class DataController extends GetxController {
  final _service = Get.find<ApiService>();
  var data = <Model>[].obs;
  
  void fetchData() async {
    isLoading.value = true;
    try {
      data.value = await _service.getData();
    } finally {
      isLoading.value = false;
    }
  }
}
```

### Error Handling
- **401/403 responses:** Automatically show unauthorized dialog via `HandleUnauthorizedService`
- **Network errors:** Show network error modal via `NetworkModal`
- **SocketException:** Caught and displayed as network error
- Always wrap API calls in try-catch blocks

---

## Key Features

### 1. Authentication
- Email/password login with optional 2FA/OTP
- LinkedIn OAuth integration
- Biometric authentication (fingerprint/face)
- JWT token management with secure storage
- Password reset via OTP

### 2. Content
- **News:** Latest industry news with categories
- **Blogs:** Member-contributed articles with comments and likes
- **Events:** Upcoming events with registration and QR verification
- **Resources:** Downloadable documents and materials

### 3. Membership & Payments
- M-Pesa STK Push integration for payments
- Membership plans and subscriptions
- Transaction history
- Digital membership certificates

### 4. Training
- Training course listings
- Session management
- Progress tracking
- Certificate generation (PDF)

### 5. Chat
- Real-time messaging via Socket.IO
- Conversation list
- Individual chat threads

### 6. Notifications
- Firebase Cloud Messaging (FCM)
- Local notifications
- In-app notification center

---

## Testing Strategy

### Current State
- Basic widget test in `test/widget_test.dart`
- Tests need to be expanded for production

### Recommended Testing Approach
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

### Testing Guidelines
1. Write widget tests for critical UI flows
2. Mock API services using `mockito` or `http_mock_adapter`
3. Test controllers independently
4. Use `testWidgets` for UI testing

---

## Security Considerations

### Data Storage
- **Secure Storage:** Tokens stored in `flutter_secure_storage`
- **Shared Preferences:** Non-sensitive user preferences
- **Keychain/Keystore:** Used by secure storage on iOS/Android

### Authentication
- JWT tokens with automatic refresh
- Biometric authentication option
- 2FA/OTP for sensitive operations

### Network Security
- HTTPS for all API calls
- Certificate pinning not implemented (consider for production)

### Input Validation
- All user inputs validated before API calls
- File uploads validated for type and size

---

## Platform-Specific Notes

### Android
- **Min SDK:** Flutter default (typically 21)
- **Target SDK:** 36
- **Compile SDK:** 36
- **NDK:** 27.0.12077973
- **Java Version:** 11
- Firebase services enabled via `google-services` plugin

### iOS
- Standard iOS project structure
- Podfile dependencies managed via CocoaPods
- Firebase configuration via `GoogleService-Info.plist`

### Web
- Default to light theme (`kIsWeb` check in `ThemeProvider`)
- Deep linking supported via `app_links`
- Responsive design considerations needed

---

## Environment Configuration

### API Endpoints (in `lib/utils/constants.dart`)
```dart
const BASE_URL = "https://api.damakenya.org/v1";
const CHAT_BASE_URL = "http://167.71.68.0:5000/v1";
```

### Theme Colors
```dart
const kBlue = Color(0xFF0b65c3);      // Primary brand color
const kGrey = Color(0xFF7E99A3);      // Secondary
const kGreen = Color(0xFF5CB338);     // Success
const kRed = Color(0xFFFF0B55);       // Error
const kDarkBG = Color(0xFF121212);    // Dark theme background
```

---

## Common Development Tasks

### Adding a New Screen
1. Create screen file in `lib/views/`
2. Add route constant to `lib/routes/routes.dart`
3. Add route to `getPages` in `lib/app.dart`
4. Create controller if needed in `lib/controller/`

### Adding a New API Endpoint
1. Add method to `ApiService` in `lib/services/api_service.dart`
2. Create model in `lib/models/` if needed
3. Create/update controller to use the service
4. Handle 401/403 errors using `HandleUnauthorizedService`

### Adding a New Dependency
1. Add to `pubspec.yaml`
2. Run `flutter pub get`
3. Update this documentation if it's a significant dependency

---

## Troubleshooting

### Common Issues
1. **Firebase initialization fails:** App continues without push notifications
2. **Network errors:** Modal automatically shown, check connectivity
3. **401 errors:** User automatically logged out with dialog

### Debug Tips
- Check `debugPrint` output for API request/response logging
- Use Flutter DevTools for state inspection
- Enable verbose logging: `flutter run --verbose`

---

## Resources

- **API Documentation:** See `API_DOCUMENTATION.md` for complete endpoint reference
- **Flutter Docs:** https://docs.flutter.dev/
- **GetX Docs:** https://chornthorn.github.io/getx-docs/
- **Project README:** See `README.md` for basic setup

---

*Last updated: February 20, 2026*
