# FlowOS Accessibility, Responsive, and Localization Acceptance Baseline

This document defines the quality and acceptance baselines for FlowOS across screen readers, large text scaling, responsive layout form factors, and localization readiness.

---

## 1. Assistive Technology & Semantics Baseline

- **Screen Reader Support**: All primary interactive buttons, chips, tabs, and garden controls must expose explicit accessibility labels, hints, and roles (`Semantics(button: true, label: ..., hint: ...)`).
- **Decorations & Decorative Graphics**: Non-interactive decorative icons or background particle effects must be excluded from accessibility tree traversal via `ExcludeSemantics`.
- **Focus Traversal**: Primary screen controls must follow logical top-to-bottom, left-to-right focus order.

---

## 2. Touch Target & Sizing Baseline

- **Minimum Touch Target Size**: Interactive touch targets (buttons, icon buttons, tab chips) must meet or exceed **48×48 dp** in visual bounds or padding box to ensure usability across touch devices.
- **Spacing Guidelines**: Interactive controls must maintain a minimum of **8 dp** gap between adjacent touch targets.

---

## 3. Dynamic Text Scaling Baseline

- **Text Scale Range**: All core UI journeys (Focus Timer, Task List, Settings, Home Garden, Onboarding) must support text scaling factors from **1.0× to 2.0×** (`TextScaler.linear(2.0)`).
- **Layout Safety**: Text scaling to 2.0× must not cause rendering exceptions, unhandled overflow assertions (`A RenderFlex overflowed...`), or hide primary call-to-action buttons.

---

## 4. Responsive Device & Orientation Form Factors

- **Supported Viewport Sizes**:
  - Compact Phone: `360 × 640 dp`
  - Standard Phone: `390 × 844 dp`
  - Tablet: `768 × 1024 dp`
  - Landscape: `844 × 390 dp`
- **Layout Resilience**: Screens must dynamically compute container bounds using flexible layouts (`Expanded`, `Flexible`, `SingleChildScrollView`, `FittedBox`) rather than hard-coded fixed height containers.

---

## 5. Localization & RTL Readiness

- **Text Direction Neutrality**: All custom layouts, padding, and alignments must support right-to-left (`TextDirection.rtl`) layout direction without throwing layout errors.
- **String Extraction Policy**: User-facing copy must avoid concatenation of sentence fragments to allow localized translation structure.
