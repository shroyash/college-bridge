# Holiday Notices Design Inventory & System Audit

> **Target**: `bridge_mobile` Flutter application  
> **Date**: 2026-11-08  
> **Audited Features**: Notifications (`NotificationInboxScreen`, `BroadcastNotificationScreen`), Dashboard (`AdminDashboardScreen`), Auth (`LoginScreen`, `AuthNotifier`)

---

## 1. Project Structure & File Conventions

* **Architecture**: Clean Architecture / Feature-Driven Development.
* **Layout**:
  * `lib/app/`: App-level themes (`app_colors.dart`, `app_typography.dart`, `app_spacing.dart`, `app_theme.dart`).
  * `lib/core/`: Cross-cutting concerns:
    * `network/`: `api_client.dart` (Dio singleton with interceptors), `api_response.dart`, `page_response.dart`, `error_interceptor.dart`.
    * `error/`: `failures.dart` (`ServerFailure`, `ValidationFailure`, `ConflictFailure`, `NotFoundFailure`, `ForbiddenFailure`, `NetworkFailure`).
    * `router/`: `app_router.dart` (GoRouter definition).
    * `services/`: `fcm_service.dart` (FCM + local notifications).
    * `storage/`: `secure_storage_service.dart` (Encrypted token & role storage).
    * `widgets/`: Shared UI atoms (`PrimaryButton`, `AppLoading`, `AppEmptyState`, `AppErrorState`, `Clickable`).
    * `helpers/`: `snackbar_helper.dart`.
  * `lib/features/<feature_name>/`:
    * `data/`: `datasources/`, `models/`, `repositories/`.
    * `domain/`: `entities/`, `repositories/` (interfaces), `usecases/`.
    * `presentation/`: `controllers/` (Riverpod `StateNotifier` / `AsyncNotifier`), `screens/`, `widgets/`.
* **Naming Conventions**:
  * Snake_case for files: `holiday_notice.dart`, `holiday_notice_model.dart`, `holiday_notice_notifier.dart`.
  * Class names: PascalCase (`HolidayNotice`, `HolidayNoticeModel`, `HolidayNoticeNotifier`).
  * Providers: Lower camelCase ending in `Provider` (`holidayNoticeNotifierProvider`, `holidayRepositoryProvider`).

---

## 2. State Management, Dependency Injection & Code Generation

* **State Management**: **Flutter Riverpod** (`StateNotifierProvider`, `Provider`, `FutureProvider`).
* **Dependency Injection**: Functional DI via Riverpod `ref.watch(...)`.
* **Immutability / Equality**: `Equatable` is used across entities, states, models, and failures (e.g. `extends Equatable`). Freezed is available in `pubspec.yaml` but `Equatable` is dominant in models and entities.
* **JSON Serialization**: Clean manual serialization `fromJson`/`toJson` alongside `ApiResponse<T>` and `PageResponse<T>` generics.

---

## 3. Networking & Error Handling

* **HTTP Client**: `Dio` configured in `ApiClient` (`lib/core/network/api_client.dart`).
* **Base URL**: Externalized in `ApiEndpoints.baseUrl` (`http://localhost:8080` in dev).
* **Auth Interception**: `AuthInterceptor` automatically attaches `Authorization: Bearer <accessToken>` from `SecureStorageService`. Refreshes expired tokens on 401.
* **Error Model**:
  * `ErrorInterceptor` catches `DioException` and converts response status codes to typed `Failure` instances.
  * Backend returns RFC 7807 `application/problem+json`: `{"type", "title", "status", "detail"}`.
  * UI extracts human-readable text via `extractErrorMessage(error)` or `failure.message`.

---

## 4. Routing & Push Navigation

* **Routing Library**: `GoRouter` (`lib/core/router/app_router.dart`).
* **Route Declaration Style**: Declarative paths like `/dashboard`, `/notifications`, `/notifications/:id`.
* **Push Tap Navigation**:
  * `FcmService.onNavigate` callback is configured to invoke `GoRouter.go(...)` or `push(...)`.
  * Handled uniformly for foreground (via local notifications tap response), background, and terminated launch (`getInitialMessage`).

---

## 5. Design System & Visual Style

* **Colors** (`AppColors`):
  * Primary: `Color(0xFF4F46E5)` (Indigo 600), Hover: `Color(0xFF4338CA)`, Light: `Color(0xFFEEF2FF)`.
  * Secondary: `Color(0xFF0EA5E9)` (Sky 500), Accent: `Color(0xFF8B5CF6)`.
  * Background Light: `Color(0xFFF8FAFC)` (Slate 50), Surface/Card: `Color(0xFFFFFFFF)`.
  * Borders: `Color(0xFFE2E8F0)` (Slate 200), Dividers: `Color(0xFFF1F5F9)`.
  * Text: Primary `Color(0xFF0F172A)`, Secondary `Color(0xFF475569)`, Muted `Color(0xFF94A3B8)`.
  * Feedback: Success `Color(0xFF10B981)`, Error `Color(0xFFEF4444)`, Warning `Color(0xFFF59E0B)`.
* **Typography** (`AppTypography`):
  * Powered by `GoogleFonts.inter(...)`.
  * Sizes: `displayLarge` (32), `titleLarge` (22, w600), `titleMedium` (16, w600), `bodyLarge` (16, w400), `bodyMedium` (14, w400), `bodySmall` (12, w400), `labelLarge` (14, w600).
* **Spacing & Radii**:
  * `AppSpacing`: `xs` (4), `sm` (8), `md` (16), `lg` (24), `xl` (32).
  * `AppRadius`: `borderSm` (8), `borderMd` (12), `borderLg` (16), `borderCircular` (999).
* **Buttons**:
  * `PrimaryButton`: Full-width or custom, height 52dp, scale animation (0.97) on tap, loading spinner, disabled state.
* **Feedback / Modals**:
  * `SnackBarHelper.showError(context, message)`: Floating, red background, error icon.
  * `SnackBarHelper.showSuccess(context, message)`: Floating, green background, check icon.
* **Loading / Empty / Error**:
  * `AppLoading`: Standard centered spinner.
  * `AppEmptyState`: Clean icon + title + message.
  * `AppErrorState`: Error icon + title + message + "Try Again" retry callback.

---

## 6. Localisation & Dates

* Current date handling in screens uses standard `DateTime.parse()` formatted in ISO or custom English string interpolations.
* Bikram Sambat (BS) date is returned directly from the backend as `dateBs` (e.g. `"2081-07-01"`).
* **Requirement**: Nepal Time is fixed at `UTC+5:45` (no DST). A dedicated `NepalTimeHelper` will calculate relative calendar labels ("Today", "Tomorrow", "In N days", "Yesterday", "Passed") anchored to Kathmandu time.

---

## 7. Push Notifications & Role Handling

* **Firebase Messaging**: Integrated via `FcmService` (`lib/core/services/fcm_service.dart`).
* **Lifecycle**:
  * Foreground: Displays banner via `FlutterLocalNotificationsPlugin` and triggers local tap.
  * Background / Terminated: Handled in `_handleMessageOpenedApp` and `getInitialMessage`.
* **Role Verification**:
  * User roles: `ADMIN`, `SUPER_ADMIN`, `TEACHER`, `STUDENT`.
  * Stored in `SecureStorageService` and accessible via `ref.watch(authNotifierProvider)`.

---

## 8. Reuse Inventory

| Need | Reusable App Component / Helper | Path |
|------|---------------------------------|------|
| Primary Submit Action | `PrimaryButton` (supports `isLoading`, disabled, icons) | `lib/core/widgets/primary_button.dart` |
| Floating Notifications | `SnackBarHelper.showError`, `SnackBarHelper.showSuccess` | `lib/core/helpers/snackbar_helper.dart` |
| Screen Background | `AppColors.backgroundLight` (`Color(0xFFF8FAFC)`) | `lib/app/theme/app_colors.dart` |
| Card Container | White surface + `AppRadius.borderMd` + `AppColors.borderLight` border | `lib/app/theme/app_spacing.dart` |
| Empty List Display | `AppEmptyState` (custom title, message, icon) | `lib/core/widgets/app_empty_state.dart` |
| Failed Network Load | `AppErrorState` (message + `onRetry` button) | `lib/core/widgets/app_error_state.dart` |
| Loading Spinner | `AppLoading` | `lib/core/widgets/app_loading.dart` |
| Network Requests | `ApiClient` (`get`, `post`) | `lib/core/network/api_client.dart` |
| Standard Envelopes | `ApiResponse<T>`, `PageResponse<T>` | `lib/core/network/` |
| Secure Token / Role | `SecureStorageService` | `lib/core/storage/secure_storage_service.dart` |
| Push Routing | `FcmService.onNavigate` | `lib/core/services/fcm_service.dart` |
| Interactive Taps | `Clickable` | `lib/core/widgets/clickable.dart` |
