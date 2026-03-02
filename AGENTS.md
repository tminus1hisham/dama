# DAMA Kenya Mobile App - Agent Documentation

## Project Overview

**DAMA Kenya** is a comprehensive Flutter mobile application for the Digital Asset Management Association (DAMA) in Kenya. The app provides a platform for members to access news, blogs, events, training resources, and manage their memberships.

- **App Name:** dama
- **Version:** 1.0.8+8
- **Flutter SDK:** ^3.7.2 (managed via FVM 3.29.3)
- **Package Name:** com.dama.mobile
- **Platforms:** Android, iOS, Web

---

## Technology Stack

### Core Framework
- **Flutter:** Cross-platform UI framework (SDK ^3.7.2)
- **Dart:** Programming language

### State Management
- **GetX:** Primary state management and dependency injection (44 controllers, reactive variables via `.obs`)
- **Provider:** Used for theme management (`ThemeProvider`), chat state (`ChatProvider`), and training sessions (`SessionsProvider`)

### Backend Integration
- **Base API URL:** `https://api.damakenya.org/v1`
- **Chat Server:** WebSocket at `http://167.71.68.0:5000/v1`
- **Authentication:** JWT Bearer Token with automatic refresh

### Key Dependencies
| Category | Package | Version | Purpose |
|----------|---------|---------|---------|
| State Management | `get` | ^4.7.2 | Reactive state management (GetX) |
| State Management | `provider` | ^6.1.5 | Theme and chat state management |
| HTTP/Networking | `http` | ^1.3.0 | REST API calls |
| WebSocket | `socket_io_client` | ^3.1.2 | Real-time chat |
| Local Storage | `shared_preferences` | ^2.5.3 | Non-sensitive data persistence |
| Local Storage | `flutter_secure_storage` | ^9.2.4 | Token and sensitive data storage |
| Local Storage | `get_storage` | ^2.1.1 | Simple caching |
| Firebase | `firebase_core` | ^3.13.0 | Firebase core integration |
| Firebase | `firebase_messaging` | ^15.2.5 | Push notifications (FCM) |
| Notifications | `flutter_local_notifications` | ^19.1.0 | Local notifications |
| Auth | `local_auth` | ^2.3.0 | Biometric authentication |
| UI Components | `motion_tab_bar_v2` | ^0.4.0 | Animated tab bar |
| UI Components | `sidebarx` | ^0.17.1 | Side navigation drawer |
| UI Components | `panara_dialogs` | ^0.1.5 | Beautiful alert dialogs |
| UI Components | `flutter_chat_bubble` | ^2.0.2 | Chat message bubbles |
| UI Components | `infinite_scroll_pagination` | ^4.0.0 | Paginated list views |
| UI Components | `flutter_expandable_fab` | ^2.5.1 | Expandable floating action button |
| Media | `image_picker` | ^1.1.2 | Camera and gallery access |
| Media | `file_picker` | ^10.1.2 | File selection |
| Media | `flutter_pdfview` | ^1.4.0+1 | PDF document viewing |
| Media | `flutter_html` | ^3.0.0 | HTML content rendering |
| Media | `image` | ^4.5.4 | Image processing |
| Media | `flutter_svg` | ^2.0.10+1 | SVG support |
| Media | `path_provider` | ^2.1.5 | File system access |
| Payments | `in_app_purchase` | ^3.2.3 | Membership subscriptions |
| QR/Scanner | `qr_code_scanner_plus` | ^2.0.10+1 | QR code scanning |
| QR/Scanner | `qr_flutter` | ^4.1.0 | QR code generation |
| PDF | `pdf` | ^3.11.1 | PDF generation |
| PDF | `printing` | ^5.13.4 | Print and share PDFs |
| Navigation | `page_transition` | ^2.2.1 | Smooth page transitions |
| Navigation | `app_links` | ^6.4.0 | Deep linking (LinkedIn OAuth) |
| Navigation | `animated_splash_screen` | ^1.3.0 | Splash screen animation |
| WebView | `webview_flutter` | ^4.11.0 | LinkedIn OAuth WebView |
| Intl | `intl` | ^0.20.2 | Date/number formatting |
| Intl | `country_picker` | ^2.0.27 | Country selection |
| Intl | `intl_phone_field` | ^3.2.0 | Phone input with validation |
| Phone Input | `intl_phone_number_input` | git | Phone number input with country selection |
| Calendar | `add_2_calendar` | ^3.0.1 | Add events to device calendar |
| Share | `share_plus` | ^11.0.0 | Content sharing |
| URL Launcher | `url_launcher` | ^6.3.1 | Open external URLs |
| Permissions | `permission_handler` | ^11.3.1 | Runtime permissions |
| Loading | `flutter_spinkit` | ^5.2.1 | Loading indicators |
| Shimmer | `skeletonizer` | ^2.1.0+1 | Loading skeletons |
| OTP Input | `pinput` | ^5.0.1 | PIN/OTP input fields |
| Icons | `font_awesome_flutter` | ^10.8.0 | Font Awesome icons |
| Tabs | `dynamic_tabbar` | ^1.0.9 | Dynamic tab bar |
| Info | `package_info_plus` | ^8.3.0 | App version information |
| Splash | `flutter_native_splash` | ^2.4.6 | Native splash screen |

### Development Dependencies
- **flutter_test:** SDK built-in testing framework
- **flutter_lints:** ^5.0.0 (Dart/Flutter lint rules)

---

## Project Structure

```
lib/
├── main.dart                    # Application entry point - dependency injection setup
├── app.dart                     # Main app widget with GetX routing and initial route logic
├── routes/
│   └── routes.dart              # Route constants and navigation transitions
├── models/                      # 34 data models
│   ├── user_model.dart
│   ├── login_model.dart
│   ├── register_model.dart
│   ├── blogs_model.dart
│   ├── news_model.dart
│   ├── event_model.dart
│   ├── training_model.dart
│   ├── certificate_model.dart
│   ├── transaction_model.dart
│   ├── payment_model.dart
│   ├── plans_model.dart
│   ├── comment_model.dart
│   ├── chat_models.dart
│   ├── message_model.dart
│   ├── notification_model.dart
│   ├── resources_model.dart
│   ├── session_model.dart
│   ├── attendance_model.dart
│   ├── role_model.dart
│   ├── rating_model.dart
│   ├── article_count_model.dart
│   ├── alert_model.dart
│   ├── verify_qr_code_model.dart
│   ├── role_request_model.dart
│   ├── verify_by_phone_model.dart
│   ├── user_event_model.dart
│   ├── user_progress_model.dart
│   ├── other_user_profile_model.dart
│   ├── conversation_model.dart
│   ├── change_password_model.dart
│   ├── get_user_model.dart
│   ├── otp_verification.dart
│   ├── request_reset_password.dart
│   └── reset_password_model.dart
├── controller/                  # 44 GetX controllers
│   ├── auth_controller.dart     # Authentication logic with biometric support
│   ├── register_controller.dart
│   ├── blog_controller.dart
│   ├── news_controller.dart
│   ├── events_controller.dart
│   ├── payment_controller.dart  # M-Pesa payments
│   ├── certificate_controller.dart
│   ├── transaction_controller.dart
│   ├── verify_qr_code_controller.dart
│   ├── feed_controller.dart
│   ├── like_controller.dart
│   ├── linkedin_controller.dart # LinkedIn OAuth
│   ├── chat_controller.dart
│   ├── conversations_controller.dart
│   ├── training_controller.dart
│   ├── user_training_controller.dart
│   ├── plans_controller.dart
│   ├── notification_controller.dart
│   ├── comment_controller.dart
│   ├── news_comment_contoller.dart
│   ├── news_like_controller.dart
│   ├── otp_verification_controller.dart
│   ├── global_search_controller.dart
│   ├── alert_controller.dart
│   ├── article_count_controller.dart
│   ├── change_password_controller.dart
│   ├── fetch_roles_controller.dart
│   ├── fetchUserProfile.dart
│   ├── get_blog_by_id.dart
│   ├── get_event_by_id.dart
│   ├── get_news_by_id.dart
│   ├── get_user_data.dart
│   ├── rating_controller.dart
│   ├── request_change_password.dart
│   ├── request_delete_account.dart
│   ├── reset_password_controller.dart
│   ├── resource_controller.dart
│   ├── role_request_controller.dart
│   ├── theme_controller.dart
│   ├── update_user_profile_controller.dart
│   ├── user_event_controller.dart
│   ├── user_progress_controller.dart
│   ├── user_resources_controller.dart
│   └── verify_by_phone_controler.dart
├── services/                    # 9 business logic and API services
│   ├── api_service.dart         # Main REST API service (~2,460 lines comprehensive)
│   ├── auth_service.dart        # Authentication with token refresh
│   ├── socket_service.dart      # WebSocket chat service
│   ├── chat_service.dart        # Chat business logic
│   ├── local_storage_service.dart
│   ├── firebase_messaging_service.dart
│   ├── deep_link_service.dart   # LinkedIn OAuth deep linking
│   └── modal/
│       ├── handle_unauthorized.dart  # 401/403 error handling
│       └── network_modal.dart        # Network error modal
├── providers/                   # 3 Provider state managers
│   ├── chat_provider.dart
│   ├── sessions_provider.dart
│   └── theme_provider.dart      # Dark/light theme management
├── views/                       # 47 UI screens organized by feature
│   ├── auth/                    # 6 authentication screens
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── otp_screen.dart
│   │   ├── reset_password.dart
│   │   ├── request_change_password.dart
│   │   ├── linkedin_webview.dart
│   │   └── linkedin_auth_webview.dart
│   ├── dashboard.dart           # Main dashboard with tabs
│   ├── dashboard/               # 5 tab screens
│   │   ├── blogs.dart
│   │   ├── news.dart
│   │   ├── events.dart
│   │   ├── resources.dart
│   │   └── search_result.dart
│   ├── drawer_screen/           # 7 side drawer screens
│   │   ├── profile_screen.dart
│   │   ├── plans_screen.dart
│   │   ├── transactions.dart
│   │   ├── notifications_screen.dart
│   │   ├── change_password.dart
│   │   ├── about_dama.dart
│   │   └── QRscanner.dart
│   ├── selected_screens/        # 7 detail views
│   │   ├── selected_blog_screen.dart
│   │   ├── selected_event_screen.dart
│   │   ├── selected_news_screen.dart
│   │   ├── selected_resource_screen.dart
│   │   ├── selected_training.dart
│   │   ├── blog_selected.dart
│   │   └── news_selected.dart
│   ├── chat/                    # 2 chat screens
│   │   ├── chat_screen.dart
│   │   └── chat_users_screen.dart
│   ├── chat_home_screen.dart
│   ├── chat_screen.dart
│   ├── training_screen.dart
│   ├── my_trainings_screen.dart
│   ├── my_certificates_screen.dart
│   ├── course_sessions_screen.dart
│   ├── today_sessions_screen.dart
│   ├── personal_details.dart
│   ├── professional_details.dart
│   ├── training_dashboard.dart
│   ├── training_detail_screen.dart
│   ├── session_detail_screen.dart
│   ├── home_screen.dart
│   ├── other_user_profile.dart
│   ├── pdf_viewer.dart
│   ├── splash_screen.dart
│   └── web/                     # 2 web-specific views
│       ├── web_homepage.dart
│       └── custom_web_appbar.dart
├── widgets/                     # 47 reusable UI components
│   ├── buttons/                 # 2 button widgets
│   │   ├── custom_button.dart
│   │   └── custom_icon_button.dart
│   ├── cards/                   # 16 card widgets
│   │   ├── blog_card.dart
│   │   ├── news_card.dart
│   │   ├── event_card.dart
│   │   ├── plans_card.dart
│   │   ├── profile_card.dart
│   │   ├── transaction_card.dart
│   │   ├── notification_card.dart
│   │   ├── chat_card.dart
│   │   ├── blog_search_card.dart
│   │   ├── event_search_card.dart
│   │   ├── news_search_card.dart
│   │   ├── resource_search_card.dart
│   │   ├── selected_event_card.dart
│   │   ├── selected_resource.dart
│   │   ├── resources_card.dart
│   │   └── user_search_card.dart
│   ├── inputs/                  # 3 input widgets
│   │   ├── custom_input.dart
│   │   ├── custom_dropdown.dart
│   │   └── dict_dropdown.dart
│   ├── modals/                  # 7 modal widgets
│   │   ├── alert_modal.dart
│   │   ├── comment_bottomsheet.dart
│   │   ├── network_modal.dart
│   │   ├── rating_dialog.dart
│   │   ├── subscription_modal.dart
│   │   ├── success_bottomsheet.dart
│   │   └── training_detail_modal.dart
│   ├── shimmer/                 # 6 loading skeletons
│   │   ├── blog_card_shimmer.dart
│   │   ├── news_card_shimmer.dart
│   │   ├── events_card_shimmer.dart
│   │   ├── plan_card_shimmer.dart
│   │   ├── resources_card_shimmer.dart
│   │   └── transaction_shimmer.dart
│   ├── web/                     # 1 web widget
│   │   └── custom_web_appbar.dart
│   ├── certificate_card.dart
│   ├── certificate_earned_banner.dart
│   ├── certificate_preview_sheet.dart
│   ├── chat_navigationbar.dart
│   ├── chat_overlay.dart
│   ├── custom_appbar.dart
│   ├── custom_spinner.dart
│   ├── profile_avatar.dart
│   ├── sources_references_section.dart
│   ├── theme_aware_logo.dart
│   ├── top_navigation_bar.dart
│   └── users_chat_topbar.dart
└── utils/                       # 4 utility files
    ├── constants.dart           # App colors, API URLs, constants
    ├── theme_provider.dart      # Dark/light theme management
    ├── session_utils.dart
    └── utils.dart

test/
└── widget_test.dart             # Basic widget tests (needs expansion)

android/                         # Android-specific configuration
├── app/build.gradle            # SDK 36, Java 11, ProGuard enabled
├── app/google-services.json    # Firebase configuration
├── build.gradle                # Google Services plugin
└── ...

ios/                            # iOS-specific configuration
├── Runner/
├── Podfile                     # iOS 13.0 minimum
└── ...

web/                            # Web-specific configuration
├── index.html
├── manifest.json
└── ...

images/                         # Asset images (logo, icons)
├── blue_logo.png
└── ...
```

**Total Dart Files:** 190 files
- 44 Controllers
- 34 Models
- 47 Views
- 47 Widgets
- 9 Services
- 3 Providers

---

## Build Commands

### Prerequisites
- Flutter SDK ^3.7.2 (or use FVM 3.29.3)
- Dart SDK compatible with Flutter version
- Android SDK 36 (for Android builds)
- Java 11 (for Android builds)
- Xcode (for iOS builds)

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

# Run with FVM
fvm flutter run
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
dart format .

# Run tests
flutter test

# Run tests with coverage
flutter test --coverage
```

### FVM Commands (recommended)
```bash
# Use specific Flutter version
fvm use 3.29.3

# Run with FVM
fvm flutter run

# Build with FVM
fvm flutter build apk --release
```

---

## Development Conventions

### Code Style
- Follows `package:flutter_lints/flutter.yaml` rules (see `analysis_options.yaml`)
- Uses `debugPrint()` for debug output (not `print()`) - **avoid_print lint enabled**
- Prefer const constructors where possible
- File naming: `snake_case.dart`

### File Naming Conventions
| Type | Pattern | Example |
|------|---------|---------|
| Models | `snake_case_model.dart` | `user_model.dart` |
| Controllers | `snake_case_controller.dart` | `auth_controller.dart` |
| Views/Screens | `snake_case_screen.dart` or `snake_case.dart` | `login_screen.dart` |
| Services | `snake_case_service.dart` | `api_service.dart` |
| Providers | `snake_case_provider.dart` | `chat_provider.dart` |
| Widgets | `snake_case.dart` | `custom_button.dart` |
| Utils | `snake_case.dart` | `constants.dart` |

### State Management Patterns

#### 1. GetX Controllers
```dart
class ExampleController extends GetxController {
  var isLoading = false.obs;  // Observable variable
  var data = <Model>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    fetchData();
  }
  
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

Controllers are injected via:
- `Get.put()` in `main.dart` for global controllers
- `Get.lazyPut()` for lazy initialization
- `Get.find<YourController>()` to retrieve registered controllers

#### 2. Providers
Used for:
- `ThemeProvider` - Dark/light mode with system theme support
- `ChatProvider` - Chat state management across screens
- `SessionsProvider` - Training sessions state management

Initialized in `main.dart` via `MultiProvider`.

### API Integration Pattern
```dart
// Service layer handles HTTP calls in services/api_service.dart
class ApiService {
  final Map<String, String> _headers = {'Content-Type': 'application/json'};
  
  Future<Model> getData() async {
    final response = await http.get(
      Uri.parse('$BASE_URL/endpoint'),
      headers: _headers,
    );
    // Handle 401/403 with HandleUnauthorizedService
    return Model.fromJson(jsonDecode(response.body));
  }
}

// Controller handles business logic and UI state
class DataController extends GetxController {
  final _service = Get.find<ApiService>();
  final data = <Model>[].obs;
  final isLoading = false.obs;
  
  void fetchData() async {
    isLoading.value = true;
    try {
      data.value = await _service.getData();
    } catch (e) {
      debugPrint('Error fetching data: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
```

### Error Handling
- **401/403 responses:** Automatically show unauthorized dialog via `HandleUnauthorizedService`
- **Network errors:** Show network error modal via `NetworkModal`
- **Token refresh:** Automatic token refresh on 401 via `AuthService.refreshToken()`
- All API calls wrapped in try-catch blocks
- Use `debugPrint()` for logging errors in development

---

## Testing Strategy

### Current State
- Basic widget test in `test/widget_test.dart` (default Flutter test)
- Tests need significant expansion for production coverage

### Running Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage report
flutter test --coverage

# Run tests for specific widget
dart test test/widget_test.dart
```

### Testing Patterns

#### Widget Testing
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dama/app.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
```

#### Controller Testing
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dama/controller/auth_controller.dart';

void main() {
  group('AuthController', () {
    late AuthController controller;
    
    setUp(() {
      controller = AuthController();
    });
    
    test('initial state is correct', () {
      expect(controller.isLoggedIn.value, false);
      expect(controller.isLoading.value, false);
    });
  });
}
```

#### Service Testing (with mocking)
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dama/services/api_service.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  group('ApiService', () {
    late MockApiService mockService;
    
    setUp(() {
      mockService = MockApiService();
    });
    
    test('fetch data returns expected result', () async {
      // Mock your service methods here
    });
  });
}
```

### Recommended Testing Approach
1. **Widget Tests:** Test critical UI flows (authentication, payments, content viewing)
2. **Controller Tests:** Mock API services using `mockito` or `http_mock_adapter`
3. **Integration Tests:** Test complete user flows
4. **Golden Tests:** Capture UI snapshots for regression testing

### Test File Organization
```
test/
├── widget_test.dart           # Basic app smoke test
├── controllers/               # Controller unit tests (recommended)
│   └── auth_controller_test.dart
├── widgets/                   # Widget unit tests (recommended)
│   └── custom_button_test.dart
├── services/                  # Service unit tests (recommended)
│   └── api_service_test.dart
└── integration/               # Integration tests (recommended)
    └── auth_flow_test.dart
```

---

## Security Considerations

### Data Storage
- **Secure Storage:** Authentication tokens stored in `flutter_secure_storage`
  - iOS: Keychain
  - Android: EncryptedSharedPreferences (Keystore)
- **Shared Preferences:** Non-sensitive user preferences (theme settings)
- **Get Storage:** Alternative local storage for simple caching

### Authentication
- JWT tokens with automatic refresh mechanism
- Biometric authentication option via `local_auth`
- 2FA/OTP for sensitive operations
- LinkedIn OAuth with PKCE flow
- Password reset via secure OTP

### Network Security
- HTTPS for all API calls (production endpoints)
- Automatic token refresh on 401 responses
- Deep link validation for OAuth callbacks
- Certificate pinning (recommended for production)

### Input Validation
- All user inputs validated before API calls
- Phone number validation with country code support
- File uploads validated for type and size
- Form validation with user feedback

---

## Platform-Specific Notes

### Android
- **Namespace:** com.dama.mobile
- **Compile SDK:** 36
- **Target SDK:** 36
- **NDK Version:** 27.0.12077973
- **Java Version:** 11 (sourceCompatibility/targetCompatibility)
- **Min SDK:** Flutter default (typically 21)
- **ProGuard:** Enabled for release builds (minifyEnabled, shrinkResources)
- **Desugaring:** Enabled (coreLibraryDesugaringEnabled)
- **Firebase:** Google Services plugin enabled
- **Dependencies:** Firebase BOM 33.13.0, desugar_jdk_libs 2.1.4

**Android Permissions:**
- `INTERNET` - Network access
- `USE_BIOMETRIC` - Fingerprint/Face ID
- `WRITE_CALENDAR`, `READ_CALENDAR` - Event calendar integration
- `CAMERA` - QR scanning and image capture
- `READ_EXTERNAL_STORAGE`, `READ_MEDIA_IMAGES` - File access

**Deep Link Configuration:**
- Scheme: `com.dama.mobile`
- Host: `linkedin`
- Used for LinkedIn OAuth callback

**Build Configuration (android/app/build.gradle):**
```gradle
android {
    namespace = "com.dama.mobile"
    compileSdk = 36
    ndkVersion = "27.0.12077973"
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        coreLibraryDesugaringEnabled true
    }
    
    defaultConfig {
        applicationId = "com.dama.mobile"
        targetSdk = 36
    }
    
    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation(platform("com.google.firebase:firebase-bom:33.13.0"))
}
```

### iOS
- **Minimum Version:** iOS 13.0
- Standard iOS project structure
- Podfile dependencies managed via CocoaPods
- Firebase configuration via `GoogleService-Info.plist`
- Local authentication (Face ID/Touch ID) enabled
- Camera and photo library permissions configured

**Podfile Configuration:**
```ruby
platform :ios, '13.0'
ENV['COCOAPODS_DISABLE_STATS'] = 'true'
```

### Web
- Defaults to light theme (`kIsWeb` check in `ThemeProvider`)
- Deep linking supported via `app_links`
- Firebase initialization skipped on web (`kIsWeb` check)
- Web-specific views in `lib/views/web/`

---

## Environment Configuration

### API Endpoints (lib/utils/constants.dart)
```dart
const BASE_URL = "https://api.damakenya.org/v1";
const CHAT_BASE_URL = "http://167.71.68.0:5000/v1";
const DEFAULT_IMAGE_URL = "https://thispersondoesnotexist.com/";
```

### Theme Colors
```dart
const kBlue = Color(0xFF0b65c3);        // Primary brand color
const kGrey = Color(0xFF7E99A3);        // Secondary text
const kGreen = Color(0xFF5CB338);       // Success states
const kRed = Color(0xFFFF0B55);         // Error states
const kYellow = Color(0xFFF7AD45);      // Warning states
const kOrange = Color(0xFFFF9B17);      // Accent color
const kWhite = Color(0xFFFFFFFF);       // White
const kBGColor = Color(0xFFe2e8f0);     // Light background
const kLightBlue = Color(0xFF64b5f6);   // Light accent
const kLblue = Color(0xFFcee0f3);       // Very light blue
const kLightGrey = Color(0xFFEFEFEF);   // Light grey

// Dark Theme
const kDarkBG = Color(0xFF121212);      // Dark background
const kDarkCard = Color(0xFF0b111e);    // Dark card
const kDarkText = Color(0xFFE0E0E0);    // Dark text
const kDarkThemeBg = Color(0xFF0e1521); // Dark theme bg
const kBlack = Color(0xFF0b1120);       // Black variant

// Glassmorphism border color
const Color kGlassBorder = Color(0xFF1C3D72);
```

### Text Sizes
```dart
const kNormalTextSize = 15.0;
const kMidText = 17.0;
const kBigTextSize = 20.0;
const kSmallTextSize = 12.0;
const kSidePadding = 15.0;
```

### Assets
```yaml
flutter:
  assets:
    - images/
```

### FVM Configuration
```json
// .fvmrc
{
  "flutter": "3.29.3"
}
```

---

## Key Features

### 1. Authentication
- **Email/Password Login:** Standard authentication with optional 2FA/OTP
- **LinkedIn OAuth:** Integration with deep linking via `app_links`
- **Biometric Authentication:** Fingerprint/Face ID via `local_auth`
- **JWT Token Management:** Secure storage with automatic refresh
- **Password Reset:** OTP-based password reset flow
- **Registration:** Multi-step registration with personal and professional details

### 2. Content Management
- **News:** Latest industry news with categories, comments, and likes
- **Blogs:** Member-contributed articles with comments, likes, and sharing
- **Events:** Upcoming events with registration, QR verification, and calendar integration
- **Resources:** Downloadable documents and materials with payment integration

### 3. Membership & Payments
- **M-Pesa Integration:** STK Push for Kenya mobile money payments
- **In-App Purchases:** Subscription management via `in_app_purchase`
- **Membership Plans:** Plan display and subscription management
- **Transaction History:** Complete payment history with receipts
- **Digital Certificates:** PDF membership certificate generation and download

### 4. Training
- **Course Catalog:** Training course listings with categories
- **Session Management:** Course sessions with enrollment
- **Progress Tracking:** User progress monitoring
- **Certificates:** Course completion certificate generation (PDF)
- **Today's Sessions:** Quick access to scheduled sessions
- **My Trainings:** Enrolled courses overview

### 5. Real-time Chat
- **Socket.IO Integration:** Real-time messaging via WebSocket
- **Conversation List:** All user conversations
- **Individual Chats:** One-on-one messaging with chat bubbles
- **Chat Provider:** State management for chat functionality

### 6. Notifications
- **Firebase Cloud Messaging:** Push notifications for all platforms
- **Local Notifications:** In-app scheduled notifications
- **Notification Center:** In-app notification history

### 7. QR Code Features
- **QR Scanner:** Event attendance verification
- **QR Generation:** Digital membership cards

---

## Common Development Tasks

### Adding a New Screen
1. Create screen file in `lib/views/` or appropriate subdirectory
2. Add route constant to `lib/routes/routes.dart`
3. Add route to `getPages` in `lib/app.dart`
4. Create controller if needed in `lib/controller/`
5. Use `Get.toNamed()` or `Get.offNamed()` for navigation

### Adding a New API Endpoint
1. Add method to `ApiService` in `lib/services/api_service.dart`
2. Create model in `lib/models/` if response structure is new
3. Create/update controller to use the service
4. Handle 401/403 errors - service automatically triggers unauthorized dialog

### Adding a New Dependency
1. Add to `pubspec.yaml` with semantic version
2. Run `flutter pub get`
3. Update this documentation if significant
4. Test on all target platforms

### Adding a New Controller
1. Create file in `lib/controller/` following naming convention
2. Extend `GetxController`
3. Register in `main.dart` with `Get.put()` or `Get.lazyPut()`
4. Use `Get.find<YourController>()` to access from views

---

## Troubleshooting

### Common Issues

1. **Firebase initialization fails**
   - App continues without push notifications
   - Login still works without FCM
   - Check `google-services.json` configuration

2. **Network errors**
   - Modal automatically shown via `NetworkModal`
   - Check connectivity before API calls
   - Verify API endpoint availability

3. **401 errors**
   - User automatically logged out with dialog
   - Token refresh attempted first
   - Check `HandleUnauthorizedService` for navigation

4. **LinkedIn OAuth issues**
   - Check deep link configuration in `AndroidManifest.xml`
   - Verify callback URL matches LinkedIn app settings
   - Ensure `app_links` is properly configured

5. **Build failures**
   - Run `flutter clean` and `flutter pub get`
   - Check Flutter version matches `.fvmrc`
   - Verify Android SDK and NDK versions

### Debug Tips
- Use `debugPrint()` for API request/response logging
- Use Flutter DevTools for state inspection
- Enable verbose logging: `flutter run --verbose`
- Check `HandleUnauthorizedService.navigatorKey` for navigation issues
- Use `Get.log()` for GetX-specific debugging

---

## API Documentation

Comprehensive API documentation is available in `API_DOCUMENTATION.md` covering:

- Authentication endpoints (login, register, OTP, password reset)
- User management (profile, update, article count)
- Content endpoints (blogs, news, events, resources)
- Chat API and WebSocket events
- Transactions & M-Pesa payments
- Membership plans
- Training courses and sessions
- Search functionality
- QR code verification

---

## Resources

- **Flutter Docs:** https://docs.flutter.dev/
- **GetX Docs:** https://chornthorn.github.io/getx-docs/
- **Provider Docs:** https://pub.dev/packages/provider
- **FVM:** https://fvm.app/ for Flutter version management

---

*Last updated: February 25, 2026*
