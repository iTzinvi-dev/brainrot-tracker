# Agent Directives & Architecture Rules for Brainrot Tracker Pro

## 1. Zero-Error Cloud Compilation Mandate
- Every file inside `lib/` must be 100% self-contained, valid Dart code.
- Zero missing imports, zero undefined variables, and zero syntax errors at all times.
- All code must pass static analysis (`dart analyze` / `flutter analyze`) cleanly according to `analysis_options.yaml`.
- Headless compilation safeguards: All builds must succeed non-interactively without local GUI or emulator dependencies.
- No dummy/facade implementations or hardcoded values intended to bypass verification; code must produce genuine state transitions.

## 2. Automatic Skill Application
All agents and developers modifying code in this repository MUST automatically load and apply all specialized skills located in `.agent/skills/` (and `.agents/skills/`):
1. **`flutter-expert`**:
   - Dart 3.x idioms (patterns, sealed classes, records, strict null safety).
   - Riverpod 2.x state management with immutable states and compile-time safety.
   - Clean Architecture: presentation, domain, and data layers cleanly isolated.
   - Platform channel best practices and battery/background efficiency for accessibility services.
2. **`frontend-design`**:
   - Distinctive, intentional visual hierarchy.
   - Avoid generic, bland template designs; deliver purposeful visual identity.
   - Rich color schemes with high contrast and harmonious accent tones.
3. **`mobile-design`**:
   - Ergonomic touch targets (minimum 48x48dp).
   - Fluid transitions, responsive layouts, safe area awareness, and navigation paradigms.
   - Graceful offline operation and robust error/empty states.
4. **`ui-ux-designer`**:
   - User-centric workflows, clear feedback loops, and micro-interactions.
   - WCAG 2.1 AA accessibility standards, semantic labels, and screen-reader friendliness.
5. **`ui-ux-pro-max`**:
   - Industry-grade component design, responsive breakpoint handling.
   - Micro-animations, polished dopamine-reduction visual metaphors (e.g., rotting brain visualization).

## 3. Cloud-Native CI/CD Guidelines & Headless Safeguards
- **GitHub Actions Automation**:
  - The CI workflow (`.github/workflows/build.yml`) automatically triggers on pushes to `main` and `master`, as well as on `workflow_dispatch`.
  - Android Release Builds (`build-android` on `ubuntu-latest`):
    - Java 17 (Zulu distribution) and Flutter stable channel.
    - Safe native directory generation: If `android/` is not committed, the workflow generates it via `flutter create --platforms=android,ios --org com.app.premium .` while safely preserving `pubspec.yaml`, `lib/`, and `assets/`.
    - Idempotent AndroidManifest permission injection: Ensures `android.permission.INTERNET` and `android.permission.VIBRATE` exist prior to compilation.
    - Generates ABI-split APKs and universal release APK.
    - Artifact upload via `actions/upload-artifact@v4` with fail-on-missing enforcement.
  - iOS Release Builds (`build-ios` on `macos-latest`):
    - Flutter stable channel.
    - Safe native directory generation preserving `pubspec.yaml`, `lib/`, and `assets/`.
    - Generates unsigned release bundle (`flutter build ios --release --no-codesign`).
    - Artifact upload via `actions/upload-artifact@v4`.
- **Native Android Accessibility Service**:
  - Requires `android.permission.BIND_ACCESSIBILITY_SERVICE` and explicit intent filters.
  - Low battery overhead: passive window state event observation only.
- **Repository Hygiene**:
  - `.gitignore` strictly tracks `lib/` and `.github/workflows/` while keeping secrets (`.env`, keystores) and ephemeral artifacts uncommitted.
  - All declared assets in `pubspec.yaml` must exist on disk and be tracked with `.gitkeep` where directories are maintained.
