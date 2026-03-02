# DAMA Kenya Mobile App - AI Agent Instructions

## Quick Start

**Project:** Flutter 3.7.2+ (managed via FVM 3.29.3) multi-platform mobile app for DAMA Kenya  
**Entry Points:** [main.dart](../lib/main.dart) (dependency injection), [app.dart](../lib/app.dart) (routing)  
**Key Docs:** See [AGENTS.md](../AGENTS.md) for comprehensive architecture details

## Build & Test Commands

```bash
# Setup
flutter clean && flutter pub get

# Run (device auto-detected)
flutter run

# Development
flutter run --debug          # Hot reload enabled
flutter run -d chrome        # Web development
fvm use 3.29.3              # Ensure FVM version

# Production builds
flutter build apk --release
flutter build appbundle --release
flutter build ios --release
flutter build web --release

# Code quality
flutter analyze              # Check lint violations
dart format .              # Format code
flutter test                # Run tests
```

## Code Style & Organization

**Language:** Dart with `package:flutter_lints` rules (no `print()` - use `debugPrint()`)  
**File Naming:** `snake_case.dart` for all files

### Directory Structure
- **[lib/models/](../lib/models/)** → 34 data models (e.g., `user_model.dart`)
- **[lib/controller/](../lib/controller/)** → 44 GetX controllers managing business logic and state
- **[lib/services/](../lib/services/)** → API calls, auth, chat, local storage, notifications
- **[lib/views/](../lib/views/)** → 47 UI screens organized by feature (auth/, dashboard/, drawer_screen/, etc.)
- **[lib/widgets/](../lib/widgets/)** → 47 reusable components (cards/, buttons/, modals/, shimmer/)
- **[lib/providers/](../lib/providers/)** → Provider-based state (theme, chat, sessions)
- **[lib/routes/](../lib/routes/)** → Route constants and GetX routing config
- **[lib/utils/](../lib/utils/)** → Constants, utilities, theme colors

## Architecture & State Management

### GetX Pattern (Primary)
- **Controllers** extend `GetxController` with `.obs` reactive variables
- **Registration:** Global controllers in [main.dart](../lib/main.dart) via `Get.put()`, lazy-loaded via `Get.lazyPut()`
- **Access:** `Get.find<YourController>()` or `Obx(() => controller.variable.value)` in views
- **44 Active Controllers:** Each handles one feature's business logic

**Example Pattern:**
```dart
class ExampleController extends GetxController {
  var isLoading = false.obs;
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
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
```

### Provider Pattern (Secondary)
Used for: `ThemeProvider` (dark/light), `ChatProvider`, `SessionsProvider`  
Initialized in [main.dart](../lib/main.dart) via `MultiProvider`

## API Integration

**Base URL:** `https://api.damakenya.org/v1` (see [lib/utils/constants.dart](../lib/utils/constants.dart))  
**Service:** [lib/services/api_service.dart](../lib/services/api_service.dart) (~2,460 lines - main HTTP facade)

### Standard Pattern
- **Service Layer (_service):** HTTP calls, token management, response parsing
- **Controller Layer:** Business logic, error handling, state updates
- **View Layer:** Build UI from controller observables

**Error Handling:**
- 401/403 → Auto-logout dialog via `HandleUnauthorizedService` in [lib/services/modal/handle_unauthorized.dart](../lib/services/modal/handle_unauthorized.dart)
- Network errors → Modal via [lib/services/modal/network_modal.dart](../lib/services/modal/network_modal.dart)
- Token refresh → Automatic on 401 via `AuthService`

**Common Service Methods:**
- `login()`, `register()`, `refreshToken()` → Auth
- `getBlogs()`, `getNews()`, `getEvents()` → Content
- `makePayment()` → M-Pesa integration
- `sendMessage()` → Chat via WebSocket

## Key Features & Their Controllers

| Feature | Controller | Model | View |
|---------|-----------|-------|------|
| **Auth** | `auth_controller.dart` | `login_model.dart`, `register_model.dart` | `lib/views/auth/` (6 screens) |
| **News** | `news_controller.dart` | `news_model.dart` | `news.dart`, `selected_news_screen.dart` |
| **Blogs** | `blog_controller.dart` | `blogs_model.dart` | `blogs.dart`, `selected_blog_screen.dart` |
| **Events** | `events_controller.dart` | `event_model.dart` | `events.dart`, `selected_event_screen.dart` |
| **Training** | `training_controller.dart` | `training_model.dart` | `training_screen.dart`, `course_sessions_screen.dart` |
| **Payments** | `payment_controller.dart` | `payment_model.dart`, `transaction_model.dart` | `lib/views/drawer_screen/transactions.dart` |
| **Chat** | `chat_controller.dart` + `conversations_controller.dart` | `message_model.dart`, `conversation_model.dart` | `lib/views/chat/` |
| **Membership Plans** | `plans_controller.dart` | `plans_model.dart` | `lib/views/drawer_screen/plans_screen.dart` |

## Project Conventions

### Observable Patterns

**Reactive Variables (GetX .obs):**
```dart
var isLoading = false.obs;           // Boolean flag
var items = <Item>[].obs;            // List
var selectedItem = Rxn<Item>();     // Nullable
```

**Watching Changes:**
```dart
ever(controller.isLoading, (_) {
  // Triggered on every change
});

once(controller.data, (_) {
  // Triggered only once
});
```

### Navigation

**Routes defined in [lib/routes/routes.dart](../lib/routes/routes.dart)**  
**Navigation via GetX:**
```dart
Get.toNamed(Routes.SCREEN_NAME);      // Push
Get.offNamed(Routes.SCREEN_NAME);     // Replace
Get.back();                            // Pop
```

### Widget Reusability

- **Buttons:** [lib/widgets/buttons/](../lib/widgets/buttons/) - `CustomButton`, `CustomIconButton`
- **Cards:** [lib/widgets/cards/](../lib/widgets/cards/) - Blog, news, events, plans cards with consistent styling
- **Inputs:** [lib/widgets/inputs/](../lib/widgets/inputs/) - `CustomInput`, `CustomDropdown`
- **Modals:** [lib/widgets/modals/](../lib/widgets/modals/) - Dialogs, bottom sheets for alerts, ratings, subscriptions
- **Shimmer (Loading):** [lib/widgets/shimmer/](../lib/widgets/shimmer/) - `*_shimmer.dart` for skeleton screens

## Security & Storage

- **JWT Tokens:** Stored securely in `flutter_secure_storage` (Keychain on iOS, EncryptedSharedPreferences on Android)
- **Sensitive Data:** Use `FlutterSecureStorage` from [lib/services/local_storage_service.dart](../lib/services/local_storage_service.dart)
- **Preferences:** Non-sensitive data in `SharedPreferences`
- **Biometric Auth:** Via `local_auth` package in `AuthController`
- **Token Refresh:** Automatic on 401 - no manual refresh needed

**Key Methods:**
- `AuthService.saveTokens()` / `getToken()`
- `LocalStorageService.saveData()` / `getData()`

## Platform-Specific Notes

**Android (SDK 36, Java 11, ProGuard enabled):**
- Namespace: `com.dama.mobile`
- Deep link scheme: `com.dama.mobile://linkedin` (LinkedIn OAuth)
- [android/app/build.gradle](../android/app/build.gradle) has Firebase, desugaring config

**iOS (iOS 13+):**
- Minimum deployment target: 13.0
- Face ID/Touch ID via `local_auth`
- [ios/Podfile](../ios/Podfile) manages CocoaPods dependencies

**Web:**
- Light theme default (check `ThemeProvider` for `kIsWeb` logic)
- Firebase skipped on web
- Deep linking via `app_links` package

## Common Gotchas & Debug Tips

1. **"Controller not found"** → Controller not registered in `main.dart`. Use `Get.put()` or `Get.lazyPut()`
2. **401 responses** → Token refresh automatic, but check `ApiService._headers` includes `Authorization` header
3. **Network errors** → Verify `BASE_URL` in [lib/utils/constants.dart](../lib/utils/constants.dart) is accessible
4. **Hot reload issues** → Run `flutter clean && flutter pub get`
5. **Debug logging** → Use `debugPrint()` not `print()` to comply with lints
6. **State not updating** → Verify controller is `.obs` reactive variable, not plain field
7. **ChatController not found** → Check [lib/controller/chat_controller.dart](../lib/controller/chat_controller.dart) is registered

## Testing

- **Test file location:** [test/widget_test.dart](../test/widget_test.dart) (minimal coverage - expand as needed)
- **Run tests:** `flutter test [--coverage]`
- **Recommended packages:** `mockito` for mocking, `http_mock_adapter` for API mocking

See AGENTS.md § Testing Strategy for detailed patterns.

## External Services

- **API:** `https://api.damakenya.org/v1` (REST)
- **Chat WebSocket:** `http://167.71.68.0:5000/v1` (Socket.IO)
- **Firebase:** Push notifications (FCM), configured via `google-services.json` (Android)
- **M-Pesa:** STK Push payments (production Kenya only)
- **LinkedIn OAuth:** Deep linking integration, WebView-based auth flow

## References

- Full documentation: [AGENTS.md](../AGENTS.md)
- API reference: [API_DOCUMENTATION.md](../API_DOCUMENTATION.md)
- Public repo patterns: GetX docs, Provider docs
