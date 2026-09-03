# BDO Events Test Coverage Plan

## Goal

Build deterministic unit, state, widget, integration, and manual coverage for the application. Coverage percentage is a supporting metric; authorization, registration integrity, invitation, check-in, and storage behavior are release gates.

## Measurement

- Test-plan completeness: 100%; every planned area has an implementation or concrete test-case specification.
- Expanded full-slice status: 24 of 30 planned slices (80%) are implemented at their planned scope. All six P2 slices have deterministic seams or host tests, but their device portions remain unverified on supported hardware.
- P2 host-contract status: 6 of 6 cases have deterministic seam or host coverage; P2 device-runtime status: 0 of 6 cases verified.
- Named priority catalog: 24 IDs total (`10 P0 + 8 P1 + 6 P2`); this is a separate planning denominator and is not the denominator for the 80% figure.
- Executed line/branch coverage: not measured; no coverage report has been generated.
- Runtime validation: blocked because Windows denies the Flutter/Dart executables before tests or analysis start.
- A `[~]` item means implemented, partially covered, or specified; it does not mean that a runtime test has passed.

## Execution Order

- [!] 0. Baseline: runtime-validation blocker is documented; executable test output remains pending because Windows denies the Flutter/Dart processes.
- [~] 1. Pure models and utilities: tests added; focused run pending toolchain access.
- [~] 2. Repository and Supabase adapter contracts: registration, event data-source, and event authorization slices added; Flutter execution remains blocked.
- [~] 3. Cubit success, error, duplicate, rollback, stale-result, and closed-state paths: registered-event and event-screen slices added; Flutter execution remains blocked.
- [~] 4. Widget validation and loading/empty/error/success states.
- [~] 5. Analytics rendering and responsive layout.
- [~] 6. Local Supabase RPC, RLS, storage, invitation, and concurrency case matrix is specified; execution remains pending.
- [~] 7. Manual and end-to-end platform case matrix is specified; device execution remains pending.
- [~] 8. Coverage report and CI-gate steps are specified; report generation remains pending until the toolchain runs.

## Test Layout

Tests mirror the production ownership tree under `lib`:

- `test/unit/core/` contains shared model and utility tests.
- `test/unit/features/<feature>/` mirrors the feature's `data`, `domain`, and `presentation` layers, including `cubit`, `pages`, and `widgets` folders.
- `test/shared/` contains legacy cross-feature and service tests until they can be split by owner.
- [Integration test blueprint](../test/integration_test/INTEGRATION_TEST_PLAN.md) defines the cross-layer harness, case catalog, folder structure, and execution gates.

## Current Batch

### Batch 1: Pure Models and Utilities

- [~] Event and category JSON mapping.
- [~] User roles and permissions.
- [~] Registration code encode/decode and malformed input handling.
- [~] Event date and time formatting.
- [~] Email validation.
- [~] Notification count boundaries are covered in `test/unit/core/model/notification_model_test.dart`.
- [~] Location serialization, display-name formatting, and office-catalog lookup.
- [~] Shared MIME types, date formats, typography sizes, spacing values, identifiers, database/storage keys, payload keys, notification settings, and utility constants exposed through the resource facade.
- [~] Deep-link URI construction and event-ID parsing for HTTPS/custom links and invalid inputs.
- [~] Core visibility-button and validated form-field helper behavior.
- [~] Recent-event persistence ordering, duplicate replacement, per-user isolation, and null-storage behavior.

Validation command:

```powershell
flutter test test/unit/core/model/pure_unit_test.dart
```

Status: test file added. `flutter test test/unit/core/model/pure_unit_test.dart` could not start because the Flutter batch wrapper returned a Windows access-denied error before Dart execution.

Known follow-ups exposed by this batch:

- `Event.copyWith` and `User.copyWith` cannot currently clear nullable fields explicitly.
- `Event.toJson` writes a null category as `{}`, while `Event.fromJson` maps that to `Other`.
- Reminder policy date parsing must be aligned with the UI's supported date formats.

## Batch 2: Repository and Adapter Contracts

- [~] Registration authentication, availability, duplicate, capacity, activation, cancellation, and error mapping.
- [~] Registration deadline boundary covered with an injectable clock: just-before, exact, and just-after cases.
- [~] Event loading counts, creator metadata, update metadata preservation, missing-event handling, and storage-error mapping.
- [~] Event delete/storage behavior covered through an injectable image-delete seam, including cleanup ordering and failure mapping. Direct Supabase storage integration remains pending.
- [~] Event repository admin, owner, unrelated-user authorization, create denial, and load forwarding.
- [~] Event owner/admin authorization and metadata preservation at the repository boundary. Supabase-side authorization remains pending.
- [~] Event, registered-event, and SQL registration DTO mapping, including nested payload and checked-in conversion.
- [~] Empty-input short circuits are covered at the event data-source and SupabaseStore boundaries. RPC/table mapping, numeric/null conversion, and storage error translation remain pending.
- [~] Profile preference local-data-source defaults, hydration, complete persistence, and null-storage behavior.
- [~] Invitation, notification, and token contract coverage added across core models and presentation paths. Arrival persistence/error mapping remains pending.

## Batch 3: Cubits and State

- [~] Registered-event token loading, null-token clearing, token errors, cancellation success/error, and duplicate cancellation.
- [~] Event loading orchestration, filtering, duplicate-load protection, delete rollback, and saved-event persistence.
- [~] Event save errors, unauthenticated save protection, delete rollback, duplicate loads, and closed-state save behavior.
- [~] Event detail registration, cancellation, duplicate submission protection, owner-only attendance authorization, and stale-result handling.
- [~] Calendar search normalization, clear-state behavior, and signed-out loading.
- [~] Reminder policy parsing, preference boundaries, adapter-backed calendar reconciliation, and non-fatal notification initialization/permission/scheduling/cancellation failures are covered. OS notification delivery remains pending.
- [~] Watcher permission denial, JSON/compact-code validation, malformed input, check-in history, status mapping, auto-open behavior, partial failure, dashboard isolation, reset/clear-state, and closed-state behavior.
- [~] Authentication DTO/Cubit success and error mapping, duplicate-request suppression, role forwarding, session restore failure, navigation, logout, and logout-everywhere behavior.
- [~] Profile Cubit preference hydration/persistence, display toggles, volume clamping, reminder boundaries, profile update success/error, password delegation, notification success/rollback, and clear-state behavior.
- [~] Biometric gating for unavailable devices, startup/pause/resume lock behavior, failed authentication retention, missing-service fail-closed behavior, disabling the lock, profile visibility load/save persistence, and adapter-backed biometric service outcomes are covered. OS prompts and authenticated platform-service failure paths remain pending.
- [~] Main navigation loading completion, tab transitions, duplicate-tab no-op, and closed-state guard.

## Batch 4: Widgets

- [~] Authentication forms and validation, including sign-in errors, password visibility, sign-up field validation, and terms gating.
- [~] Event page empty state, populated event cards, and Upcoming/My Events/Past tab filtering.
- [~] Saved-event filtering/toggling and category-to-create navigation.
- [~] Calendar empty prompt, registered-event list rendering, explore-events navigation intent, and no-match search state.
- [~] Registration status rendering: available, unavailable, full, past deadline, and already registered/ticket action.
- [~] Ticket rendering, token loading/error states, QR output, manual registration-code visibility, copy confirmation, and cancellation-dialog dismissal.
- [~] Successful cancellation and ticket-page close after refresh orchestration. Calendar refresh success and reminder cleanup remain pending.
- [~] Notification empty/loading/content/invitation states, load errors, arrival success/failure, and invitation recipient selection/send success/failure. Invitation refresh edge cases remain pending.
- [~] Event create/edit required-field validation and edit-mode field hydration.
- [~] Event required-field, time-range, capacity and past-deadline validation, edit hydration, successful save, image lifecycle, and location-search dispatch are covered. Native picker and date/time/deadline channel execution remain pending.
- [~] Attendee loading/empty/error states, list rendering, avatar fallback, attendance summary/overflow, CSV generation, clipboard copy/failure handling, and adapter-backed platform share dispatch/failure handling are covered. Device share-sheet behavior and broader ticket-display coverage remain pending.
- [~] Event-detail location expansion, unavailable-coordinate fallback, coordinate map/marker rendering, and map-line painter output.
- [~] Profile details hydration/locale/save/error/photo-removal, preference controls, account/support callbacks, watcher settings/history controls, organizer-tool role visibility, main-screen destination/shell navigation, and adapter-backed profile image upload/removal are covered. Native picker, device camera lifecycle, QR frames, and permissions remain pending.
- [~] Watcher scanner dashboard counters, history badge, icon-button wiring, target-overlay rendering, adapter-backed manual-entry journey, scanner callback routing, cooldown protection, torch/camera controls, voice/haptic dispatch, native failure containment, and adapter disposal are covered. Camera lifecycle, real QR frames, and device permissions remain pending.

## Batch 5: Analytics

- [~] Zero, unlimited-capacity, exact-capacity, over-capacity, and checked-in conversion boundary values.
- [~] Loading placeholder and backend-error states are covered.
- [~] Wide and narrow layouts around the breakpoint, metric-grid columns, insight/status branches, and custom-paint chart/donut presence.
- [~] Nonblank chart and donut painter pixel output is asserted through a rendered RGBA buffer.
- [~] Repaint behavior when attendance input changes.

## Batch 6: Supabase Integration

- [~] Repository-level role authorization and event mutation tests cover current-role boundaries; Supabase RLS remains pending.
- [~] Local attendee/profile/storage visibility contracts and cleanup seams are covered; Supabase visibility-policy tests remain pending.
- [~] Sequential duplicate/capacity invariants are covered, including post-success duplicate rejection; concurrent transaction invariants remain pending.
- [~] Local watcher token validation and already-checked-in idempotent outcomes are covered; Supabase RPC/idempotence tests remain pending.
- [~] Local invitation, notification, reminder-policy, arrival, and profile-persistence contracts are covered; end-to-end Supabase sequencing remains pending.

## Batch 7: Manual and E2E

- [~] Sign-up, authentication, role navigation, and settings cases are specified; local unit/widget coverage exists and device execution remains pending.
- [~] Event create/edit/delete and registration-race cases are specified; local create/delete/duplicate coverage exists and race execution remains pending.
- [~] Ticket QR/manual code, cancellation, and calendar-refresh cases are specified; ticket/cancellation coverage exists and full refresh execution remains pending.
- [~] Invitation accept/decline cases are specified; accept/send coverage exists and decline/device execution remains pending.
- [~] Watcher scan and check-in-all cases are specified; Cubit/history coverage exists and camera execution remains pending.
- [~] Notification, camera, biometric, deep-link, sharing, clipboard, image, and responsive cases are specified; deterministic adapter/host portions are covered and platform execution remains pending.

## Final Execution Matrix

The complete case inventory is now defined. A `[~]` item means the behavior is implemented or has a concrete test specification; it does not mean that a runtime test has passed.

### Supabase and Integration Cases

1. Verify regular users, watchers, and administrators against event create, update, delete, registration, attendee, and profile-visibility policies; repeat mutations as unrelated users and with revoked sessions.
2. Verify attendee, profile, event-image, and profile-image reads/writes under owner, registered-user, administrator, and anonymous visibility rules; verify storage cleanup after database failure and success.
3. Start two registrations for the same user/event concurrently, repeat at exact capacity, and verify one active registration, no duplicate rows, and a stable capacity response after retries.
4. Validate malformed, expired, duplicate, and already-checked-in tokens; repeat check-in requests and verify idempotent status, audit data, and unchanged attendance totals.
5. Send invitations to one, many, empty, duplicate, and unauthorized recipients; accept and decline invitations, update arrival status, reconcile reminders, persist notification/profile changes, and verify rollback on failures.

### Manual and End-to-End Cases

1. Complete sign-up, sign-in, session restore, role-based navigation, settings changes, logout, and logout-everywhere on supported platforms.
2. Create, edit, delete, and revisit an event; exercise image replacement, deadline/capacity validation, registration races, and recovery after network interruption.
3. Open a ticket, verify QR/manual-code output, copy/share it, cancel registration, refresh the calendar, and confirm reminder cleanup.
4. Open an invitation notification, accept and decline it, verify the event/calendar state, and repeat after a stale or failed backend response.
5. Scan valid and invalid QR/manual codes, check in one attendee and all pending attendees, verify voice/vibration/torch/camera behavior, and recover from permission denial.
6. Verify notifications, camera, biometrics, deep links, sharing, clipboard, image picking, dark mode, large text, high contrast, and narrow/wide responsive layouts.

## Recommended Gates

- P0 authorization, capacity, duplicate-registration, invitation, check-in, and storage invariants must pass.
- Target 90%+ branch coverage for authentication, registration, event, watcher, profile, and invitation logic.
- Target 80%+ branch coverage for utilities and presentation helpers.
- Cover every error, duplicate, rollback, stale-result, and closed-state branch explicitly.
- Treat framework-generated and platform-only code as excluded or manually verified, not as a reason to weaken domain coverage.

## Required Test Seams

- Injectable clock and `SharedPreferences`.
- Injectable Supabase adapter/client boundary.
- Injectable image picker, storage, geocoder, notification, biometric, camera, TTS, haptic, clipboard, and sharing services.
- Resettable `getIt` registrations.
- Deferred-result helper for stale and concurrent async tests.
