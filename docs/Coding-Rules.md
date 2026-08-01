# Coding Standards & Guidelines

## 1. Core Principles
* **SOLID Principles**: Adhere strictly to Single Responsibility and Dependency Inversion.
* **Immutability**: Prefer immutable DTOs (`record` in Java 17+) and unmodifiable lists where applicable.
* **Fail Fast**: Validate incoming requests at the Controller/DTO level before passing payloads into service logic.

## 2. Naming Conventions
* **Classes & Interfaces**: `PascalCase` (e.g., `BroadcastService`, `FcmMulticastProcessor`).
* **Variables & Methods**: `camelCase` (e.g., `sendMulticastNotification()`, `sentCount`).
* **Constants & Enums**: `UPPER_SNAKE_CASE` (e.g., `MAX_RETRY_ATTEMPTS`, `PENDING_APPROVAL`).
* **Database Tables/Columns**: `snake_case` (e.g., `messaging_queue`, `device_token`).

## 3. Asynchronous & Multi-threading Guidelines
* Use **Java Virtual Threads** (`Executors.newVirtualThreadPerTaskExecutor()`) for I/O-intensive operations like FCM multicast calls.
* Worker Thread Pools for heavy DB batch reads must be bounded (**max 2–3 concurrent jobs**) to prevent database connection starvation.

## 4. Error Handling & Response Standard
* All controller endpoints **must** return payloads wrapped in `ApiResponse<T>`.
* Use custom domain exceptions (e.g., `BroadcastNotFoundException`) handled globally via `@ControllerAdvice`.