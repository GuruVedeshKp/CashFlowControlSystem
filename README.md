# CFCS - Cash Flow Control System

CFCS is a mobile receivables and collections management application built for small businesses to manage customer dues, invoices, reminders, and payment tracking.

## Features

- User authentication (JWT)
- Persistent login
- Customer management
- Receivables management
- Due date tracking
- Partial / split payments
- Payment history ledger
- WhatsApp reminder integration
- Reminder history tracking
- PDF invoice generation
- Document upload / delete / view
- Dashboard analytics
- Customer ledger history
- Business profile customization

## Tech Stack

Frontend:
- Flutter

Backend:
- NestJS
- PostgreSQL
- TypeORM

Integrations:
- PDFKit
- WhatsApp Deep Links
- Shared Preferences

## Setup

Open Postman and get JWT

### Backend

```bash
cd cfcs-backend
npm install
npm run start:dev
```
### Frontend
```bash
cd cfcs_mobile
flutter clean
flutter pub get
flutter run
```
