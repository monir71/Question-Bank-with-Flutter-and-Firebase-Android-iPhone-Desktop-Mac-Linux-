# 📚 Question Bank

**A modern, secure, cross-platform Question Bank and Examination Management System built with Flutter and Firebase.**









---

## 🌟 Overview

**Question Bank** is a Flutter-based, cross-platform application designed to manage questions, examinations, examinees, examiners, and examination results in a unified system.

The application uses **Firebase Authentication** and **Cloud Firestore** as core backend services and is designed with a maintainable architecture that can evolve as the system grows.

The same application codebase targets:

* 📱 Android
* 📱 iOS
* 🪟 Windows
* 🍎 macOS
* 🐧 Linux

---

## ✨ Key Features

### 🔐 Authentication & Users

* Firebase Authentication
* Secure user authentication
* Role-based access
* User profiles
* Profile photo support
* Active/inactive user management

### 👥 User Roles

The application currently defines three primary roles:

| Role               | Responsibility                                    |
| ------------------ | ------------------------------------------------- |
| 👑 **Admin**       | System and question-bank management               |
| 🧑‍🏫 **Examiner** | Examination and question-related activities       |
| 🧑‍🎓 **Examinee** | Taking examinations and viewing permitted results |

The role-based architecture allows additional permissions and workflows to be introduced later.

---

## 📝 Question Management

Questions are organized using structured metadata such as:

* Subject
* Category
* Sub-category
* Question type
* Difficulty
* Correct answer(s)
* Question description
* Options

### Supported Question Types

#### 🔘 Multiple Choice

Supports:

* 2–6 options
* Single correct answer
* Multiple correct answers

#### ☑️ True / False

A simple two-option question format.

#### ✍️ Written

Designed for written-answer examinations.

The assessment architecture is intended to support:

* Manual evaluation
* Automatic evaluation where appropriate
* Partial marks
* Flexible marking criteria

---

## 🎯 Difficulty Levels

Questions can be classified as:

* 🟢 Easy
* 🟡 Medium
* 🔴 Hard

This allows examinations to be constructed with different levels of difficulty.

---

## 📊 Examination & Results

The examination system is designed to record:

* Examination name
* Total questions
* Correct answers
* Wrong answers
* Unanswered questions
* Score
* Percentage
* Pass/fail status
* Start time
* Completion time

This provides a foundation for detailed examination reporting and future analytics.

---

## 🏗️ Architecture

The project follows a modular architecture intended to separate responsibilities between the presentation layer, business logic, models, and data services.

A simplified structure is:

```text
lib/
│
├── config/
│
├── models/
│
├── services/
│
├── screens/
│
├── widgets/
│
└── main.dart
```

The architecture will evolve as new features are introduced.

### Design Principles

The project emphasizes:

* Separation of responsibilities
* Reusable services
* Strong data models
* Maintainable UI components
* Backend abstraction
* Platform independence
* Secure authentication and authorization
* Future extensibility

---

## 🔥 Firebase

Firebase provides the core cloud infrastructure.

Current services include:

* 🔐 Firebase Authentication
* ☁️ Cloud Firestore

Firebase is used to provide authentication and cloud-based application data without requiring a traditional application server for every operation.

---

## 🖼️ Image Storage

The application is designed so that image storage can remain independent from the application's core models and business logic.

This allows storage providers to be changed in the future without requiring major changes to application models.

Possible future storage options include:

* Existing web hosting
* Firebase Storage
* Other cloud storage providers

---

## 🖥️ Supported Platforms

| Platform | Status |
| -------- | :----: |
| Android  |    ✅   |
| iOS      |    ✅   |
| Windows  |    ✅   |
| macOS    |    ✅   |
| Linux    |    ✅   |

The goal is to maintain a shared Flutter codebase across all supported platforms.

---

## 🛠️ Technology Stack

| Technology                  | Purpose                              |
| --------------------------- | ------------------------------------ |
| **Flutter**                 | Cross-platform application framework |
| **Dart**                    | Application programming language     |
| **Firebase Authentication** | User authentication                  |
| **Cloud Firestore**         | Cloud database                       |
| **Firebase Services**       | Supporting cloud infrastructure      |

---

## 🚀 Getting Started

### Prerequisites

Install the required development tools:

* Flutter SDK
* Dart SDK
* Android Studio for Android development
* Xcode for iOS/macOS development
* Visual Studio for Windows development
* Appropriate Linux development packages for Linux builds

Check the Flutter environment:

```bash
flutter doctor
```

---

### Clone the Repository

```bash
gh repo clone monir71/Question-Bank-with-Flutter-and-Firebase-Android-iPhone-Desktop-Mac-Linux-
```

Move into the project directory:

```bash
cd question_bank
```

Install dependencies:

```bash
flutter pub get
```

---

## 🔥 Firebase Setup

Configure the application with the Firebase project associated with your development environment.

Firebase client configuration files may include:

```text
firebase.json
lib/firebase_options.dart
android/app/google-services.json
```

These files contain client/project configuration and are not equivalent to Firebase Admin credentials.

### ⚠️ Security

**Never commit Firebase Admin SDK service-account credentials to GitHub.**

Do not commit files containing sensitive private keys such as:

```text
-----BEGIN PRIVATE KEY-----
```

Server-side credentials should be stored securely outside source control.

A suitable `.gitignore` should exclude sensitive files and directories, for example:

```gitignore
.env
*.pem
*.key
firebase_credentials/
service-account*.json
*-firebase-adminsdk-*.json
```

---

## ▶️ Running the Application

Check available devices:

```bash
flutter devices
```

Run the application:

```bash
flutter run
```

You can select Android, iOS, Windows, macOS, or Linux depending on the development environment.

---

## 📦 Building

### Android

```bash
flutter build apk
```

### iOS

```bash
flutter build ios
```

### Windows

```bash
flutter build windows
```

### macOS

```bash
flutter build macos
```

### Linux

```bash
flutter build linux
```

---

## 🧪 Development Philosophy

This project is being developed with an emphasis on **learning, clean architecture, maintainability, and long-term extensibility** rather than simply implementing individual features as quickly as possible.

The development process focuses on:

1. Understanding the requirement
2. Designing the data model
3. Separating responsibilities
4. Implementing reusable services
5. Building the UI
6. Testing the feature
7. Refactoring where necessary
8. Preparing the architecture for future expansion

---

## 🗺️ Roadmap

Potential future development includes:

* [ ] Advanced question management
* [ ] Examination creation and scheduling
* [ ] Question randomization
* [ ] Question pools
* [ ] Examination time limits
* [ ] Automatic result generation
* [ ] Manual written-answer evaluation
* [ ] Partial marking
* [ ] Detailed result reports
* [ ] Examiner workflows
* [ ] Advanced user management
* [ ] Question import/export
* [ ] Image-rich questions
* [ ] Examination analytics
* [ ] Improved offline support
* [ ] Enhanced security rules
* [ ] Additional Firebase services

The roadmap may change as the application develops.

---

## 🔒 Security Principles

Security is an important part of the application architecture.

The project aims to follow these principles:

* Authenticate users through Firebase Authentication
* Authorize users according to their roles
* Protect Firestore with appropriate Security Rules
* Never expose server-side private credentials
* Use HTTPS for network communication
* Validate user input
* Avoid storing unnecessary sensitive information
* Keep credentials outside source control
* Apply least-privilege access wherever possible

---

## 📁 Project Status

🚧 **Active Development**

The application is under continuous development. Architecture, models, screens, services, and features may change as the project evolves.

---

## 🎯 Vision

The long-term goal is to develop a **flexible and reliable examination platform** that can serve as a foundation for educational institutions, training organizations, and other examination-based systems.

The project is designed to grow from a Question Bank into a broader examination management platform while maintaining a clean and understandable codebase.

---

## 🤝 Contributing

Contribution guidelines will be added when the project reaches a suitable stage for external contributions.

For development and experimentation, please feel free to fork the repository and adapt it to your own requirements.

---

## 📄 License

License information will be added when the project license is finalized.

---

### Built with ❤️ using Flutter & Firebase
