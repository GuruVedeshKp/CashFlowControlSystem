# CFCS Mobile App

CFCS Mobile is the Flutter frontend application for the Cash Flow Control System (CFCS), designed to help small businesses manage receivables, customer payments, reminders, invoices, and collection tracking from a mobile-first interface.

## Overview

The mobile application provides an intuitive dashboard-driven experience for business owners to:

- Track pending customer payments
- Manage receivables
- Record full and split payments
- Send WhatsApp reminders
- View invoices and uploaded documents
- Monitor dashboard analytics
- Manage customers and their transaction history

---

## Features

### Authentication
- User registration
- User login
- JWT token-based authentication
- Persistent login using Shared Preferences
- Secure API access

### Dashboard
- Total receivables summary
- Overdue amount tracking
- Due today summary
- Expected payments this week
- Upcoming payment follow-ups

### Customer Management
- Add customer
- View customer list
- Customer detail screen
- Full customer receivable ledger/history
- Business/customer profile information

### Receivables Management
- Create new receivable
- View receivables list
- Filter by:
  - Pending
  - Overdue
  - Partially Paid
  - Paid
- View receivable details
- Update due dates

### Payments
- Record payment
- Split/partial payments
- Payment history tracking
- Dynamic pending balance updates

### Reminders
- Send WhatsApp reminders
- Reminder tone support:
  - Polite
  - Firm
- Reminder history view

### Invoice & Documents
- View generated invoices
- Upload documents
- View attached documents
- Delete documents

### Settings
- Business profile customization
- Invoice branding settings
- App configuration settings

---

## Tech Stack

### Framework
- Flutter

### Language
- Dart

### State Management
- Stateful Widgets

### Networking
- Dio

### Local Storage
- Shared Preferences

### Platform Support
- Android
- Web (for testing/demo)

---

## Project Structure

```text
lib/
 ┣ screens/
 ┃ ┣ auth/
 ┃ ┣ customers/
 ┃ ┣ dashboard/
 ┃ ┣ notifications/
 ┃ ┣ receivables/
 ┃ ┣ settings/
 ┃ ┗ main_shell_screen.dart
 ┣ services/
 ┃ ┣ api_service.dart
 ┃ ┣ auth_service.dart
 ┃ ┣ customers_service.dart
 ┃ ┣ dashboard_service.dart
 ┃ ┣ notifications_service.dart
 ┃ ┣ receivables_service.dart
 ┃ ┗ settings_service.dart
 ┣ widgets/
 ┗ main.dart
```

---

## Setup Instructions

### Prerequisites

Install:

- Flutter SDK
- Android Studio / Android SDK
- VS Code
- Java 17
- Physical Android device or emulator

Check installation:

```bash
flutter doctor
```

---

## Installation

Clone repository:

```bash
git clone YOUR_REPO_URL
```

Go to frontend:

```bash
cd cfcs_mobile
```

Install dependencies:

```bash
flutter pub get
```

---

## API Configuration

Update backend API URL in:

```dart
lib/services/api_service.dart
```

Example:

```dart
static const String baseUrl =
    'http://192.168.1.15:3000/api/v1';
```

For emulator:

```dart
http://10.0.2.2:3000/api/v1
```

For physical device:

```dart
http://YOUR_LOCAL_IP:3000/api/v1
```

---

## Run Application

Android:

```bash
flutter run
```

Specific device:

```bash
flutter run -d android
```

Web:

```bash
flutter run -d chrome
```

---

## Demo Flow

Suggested application walkthrough:

1. Register user
2. Login
3. Add customer
4. Create receivable
5. Generate invoice
6. Upload document
7. Record partial payment
8. Send WhatsApp reminder
9. View customer ledger
10. Check dashboard analytics

---

## Additional Enhancements

Implemented beyond base assignment:

- Persistent login
- Full customer ledger history
- Split payment support
- Reminder history UI
- Business profile invoice customization
- Dashboard analytics improvements
- Better empty states and refresh handling
- Mobile deployment support

---

## Author

Developed as part of the CFCS collections management project.
