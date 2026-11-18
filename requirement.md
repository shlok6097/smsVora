# smsVora
## Project Goals & Development Guidelines

### 1. Project Overview

smsVora is an AI-powered Android SMS application designed to make message management smarter, safer, and more organized.

The application uses lightweight on-device machine learning and rule-based processing to categorize messages, detect potential scams, manage OTPs, and convert important messages into actionable information.

The primary focus is privacy, reliability, performance, and simplicity.

### 2. Primary Goals

The main goals of smsVora are:

1. **Intelligent Message Management:** Automatically categorize SMS messages into Personal, OTPs, Banking, Bills & Deliveries, Actions, and Spam.
2. **AI-Based Scam Detection:** Identify suspicious messages, phishing attempts, and potential financial scams with understandable explanations.
3. **OTP Management:** Extract verification codes, identify expiry information, and provide convenient OTP management.
4. **Smart Action Center:** Convert important messages into useful actions such as bill reminders, delivery tracking, and transaction summaries.
5. **Privacy-First Architecture:** Perform message classification and AI processing locally on the device without uploading private SMS content to external servers.
6. **Performance:** Maintain fast message processing, low memory consumption, and efficient battery usage.

### 3. Core Product Principles

Every feature must follow these principles:

- Privacy must be a priority.
- Message delivery and reliability must never be compromised for AI functionality.
- Users must remain in control of their messages and data.
- AI predictions must not be treated as guaranteed facts.
- Important messages must never be silently discarded.
- The interface must remain simple, consistent, and accessible.
- Performance must be prioritized over unnecessary complexity.

### 4. Technical Goals

**Target Platform:** Android 8.0 and above.

**Primary Technologies:**
- Kotlin
- Jetpack Compose
- Material 3
- Room Database
- Kotlin Coroutines and Flow
- LiteRT (TensorFlow Lite)
- WorkManager
- Android Telephony APIs

**Architecture:**
- MVVM
- Clean Architecture
- Repository Pattern
- Dependency Injection
- Modular and maintainable codebase

**AI Requirements:**
- Lightweight on-device classification model.
- Target model size below 30 MB.
- Efficient CPU inference.
- No mandatory cloud-based AI processing.
- Support for Indian SMS patterns, English, and regional language variations.

### 5. Development Phases

**Phase 1: SMS Foundation**
- Default SMS application integration.
- Message sending and receiving.
- Conversation management.
- Local database and message synchronization.

**Phase 2: Intelligent Inbox**
- Automatic message categorization.
- Smart folders.
- Sender identification and custom rules.

**Phase 3: AI Security**
- On-device scam classification.
- Phishing detection.
- Explainable security warnings.
- User feedback and correction system.

**Phase 4: OTP Management**
- OTP extraction.
- Expiry detection.
- Countdown interface.
- Configurable archive and cleanup.

**Phase 5: Smart Actions**
- Bill reminders.
- Transaction summaries.
- Delivery tracking.
- Smart message search.

**Phase 6: Testing and Release**
- Performance optimization.
- Security testing.
- Compatibility testing.
- Play Store policy compliance.
- Production release.

### 6. AI Coding Agent Instructions

All AI coding agents working on smsVora must follow these instructions.

**Code Quality**
- Write clean, readable, maintainable, and industry-standard code.
- Follow Kotlin and Android development conventions.
- Use established design patterns appropriately.
- Maintain proper separation of concerns.
- Avoid unnecessary code duplication.
- Use meaningful class, function, variable, and file names.
- Prefer reusable and modular implementations.
- Handle exceptions and edge cases properly.
- Avoid unnecessary dependencies and overengineering.

**Code Formatting**
- Never use emojis in source code.
- Never use emojis in code comments, logs, identifiers, or code-generated messages.
- Use professional and descriptive naming conventions.
- Write meaningful comments only when necessary.
- Maintain consistent formatting and indentation.

**Architecture and Implementation**
- Respect the existing project architecture.
- Do not introduce architectural changes without a valid reason.
- Do not create unnecessary files or modules.
- Use Kotlin Coroutines and Flow for appropriate asynchronous operations.
- Follow lifecycle-aware Android development practices.
- Use dependency injection where appropriate.
- Never hardcode sensitive information.
- Avoid deprecated APIs when supported alternatives exist.

**Development Discipline**
- Understand existing code before modifying it.
- Do not replace working implementations without justification.
- Do not introduce placeholder implementations as finished features.
- Verify imports, dependencies, and API compatibility.
- Test changes before considering a feature complete.
- Report incomplete functionality and known limitations honestly.

### 7. Quality Standards

Every feature must be evaluated against:

- Functional correctness.
- Reliability and stability.
- Security and privacy.
- Performance and resource efficiency.
- Maintainability.
- Accessibility and usability.
- Compatibility across supported Android versions.

### 8. Product Vision

The long-term vision of smsVora is to transform traditional SMS messaging into an intelligent personal communication assistant.

smsVora should help users understand their messages, identify potential threats, manage important information, and take action without compromising privacy.

**Core Philosophy:**

Build a reliable messaging application first, make it intelligent second, and make it genuinely useful through automation.