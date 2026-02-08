# Project Context: NeetFlow (Flutter)

## 1. Project Overview
*   **Goal:** A high-performance, premium medical MCQ practice application for NEET PG aspirants. This project is a meticulous migration from React Native (Expo) to Flutter, aimed at achieving 60fps performance and superior UI fidelity across all Android and iOS devices.
*   **Target Audience:** Medical interns, undergraduate medical students, and postgraduate aspirants (NEET PG, INI-CET, FMGE).
*   **Key Value Proposition:** Providing a "Flow" state for medical students—low friction, high-yield practice sessions with beautiful aesthetics that reduce study fatigue.

## 2. Technical Stack
*   **Framework:** Flutter SDK (targetting latest stable 3.x).
*   **State Management:** **Riverpod** (Primary for all business logic, utilizing `StateNotifierProvider` and `AsyncValue` for robust state handling).
*   **Database & Backend:**
    *   **External:** Firebase Firestore (NoSQL) for questions, user profiles, and global stats.
    *   **Auth:** Firebase Authentication (Email/Password & Google Sign-In support).
    *   **Local:** **Hive** (Extremely fast, NoSQL local storage used for caching MCQs, bookmarks, and persisting user preferences/auth tokens).
*   **Network:** **Dio** (Advanced HTTP client for any external API needs).
*   **Navigation:** **GoRouter** (Declarative, deep-link ready routing system).
*   **UI Architecture:** Custom Design System based on HSL color tokens, emphasizing Glassmorphism, smooth gradients, and premium typography.

## 3. Directory Structure (`/lib`)
*   **/core:** Root of the infrastructure.
    *   `theme/`: App-wide styles, color extensions (`app_colors.dart`), and standard shapes.
    *   `ui/`: The "Atomic Library" containing `AppButton`, `AppTextField`, `AppCard`, and custom loaders.
    *   `storage/`: Hive box configurations and `HiveService` wrappers.
    *   `models/`: Global data structures (e.g., `UserProfile`).
*   **/features:** Organized by domain for scalability.
    *   `auth/`: Login, Signup, and Password recovery logic.
    *   `mcq/`: Horizontal swiping card interface, logic for "Mark as Viewed", and explanation modals.
    *   `exam/`: Timed sessions, negative marking calculators, and result analysis.
    *   `stats/`: Performance charts and daily streak visualizations.
*   **/services:** Dedicated bridge for Firebase and heavy computation logic.

## 4. Coding Conventions & Standards
*   **Null Safety & Strict Types:** Explicit types are mandatory. `dynamic` is strictly avoided unless communicating with non-typed JSON.
*   **Component Composition:** Preferred over large monolithic builds. Small, reusable widgets that consume `context` via extensions (e.g., `context.primaryColor`).
*   **Error Handling:** Every async operation must be wrapped in `try/catch`. Auth errors must be mapped to specific UI fields.
*   **Proactivity:** AI assistants should verify builds and run lint checks before declaring a task complete.
*   **Aesthetics:** Every UI change must adhere to the "Premium" mandate—consistent padding (8dp grid), smooth border radii (12-16dp), and subtle shadows.

## 5. Domain Logic (Medical MCQs)
*   **Standard Scoring:** +4 for a correct answer, -1 for an incorrect answer. Unattempted = 0.
*   **Content Model:**
    *   **Stem:** The question scenario.
    *   **Options:** 4 distinct choices.
    *   **Explanation:** High-yield medical notes + diagrams/media URLs.
    *   **Metadata:** Subject (Anatomy, Surgery, etc.), Chapter/Topic, and Difficulty Level.
*   **Performance:** MCQ batches are pre-fetched (25 questions at a time) and synchronized with Firebase in the background to prevent lag.

## 6. Current Development Roadmap
*   **[✓] Phase 1:** Core Framework & Theme Engine.
*   **[✓] Phase 2:** Firebase Auth Integration & Field-specific validation.
*   **[→] Phase 3 (Current):** MCQ Swipe card stability and Interactive Explanation View.
*   **[ ] Phase 4:** Mock Exam Engine & Real-time Leaderboards.
*   **[ ] Phase 5:** Analytics Dashboard & Hive-based Offline Mode.
