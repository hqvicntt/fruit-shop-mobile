# 📱 Fruit Shop POS & VietQR - Cross-Platform App (Android & iOS PWA)

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?logo=android&logoColor=white)
![PWA](https://img.shields.io/badge/PWA-5A0FC8?logo=pwa&logoColor=white)

A cross-platform Point-of-Sale (POS) application built with Flutter, designed with an accessible, high-contrast Vietnamese UI for retail vendors. Features dynamic **VietQR** generation, split cash/transfer payments, automated voice notifications, and real-time inventory synchronization.

---

## ✨ Key Features

- **Precision Weighing (`0.1 kg` Increments):** Easily adjust fruit quantities with floating-point rounding safeguards and automatic stock limits.
- **Split Payment & Dynamic VietQR:** Enter partial cash received from customers to automatically calculate the remaining balance and generate a dynamic **VietQR** code pre-filled with the exact transfer amount and unique order reference.
- **Automated Payment Polling & Voice Alerts:** Polls the backend every 3 seconds for incoming bank transfers; upon confirmation, triggers a Vietnamese Text-to-Speech (TTS) audio alert, deducts stock, and saves the order automatically.
- **On-the-Go Inventory & Revenue Tracking:** Add, edit, or delete products directly from the mobile app and review daily cash vs. transfer summaries.
- **Multi-Platform Deployment:** Compiles to native Android `.apk` and deploys as a Progressive Web App (PWA) for seamless installation on iOS devices.

---

## 🚀 Local Setup & Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/hqvicntt/fruit-shop-mobile
   cd fruit-shop-mobile
   ```
2. **Fetch Flutter dependencies:**
   ```bash
   flutter pub get
   ```
3. **Configure environment variables:**
   Create a `.env` file in the project root with your server domain and bank details:
   ```env
   COMPUTER_IP=your-backend-domain.up.railway.app
   BANK_ID=vietinbank
   ACCOUNT_NO=YOUR_BANK_ACCOUNT_NUMBER
   ACCOUNT_NAME=YOUR_ACCOUNT_NAME
   ```
4. **Run the application:**
   ```bash
   flutter run
   ```

---

## 👨‍💻 Author

- **Huynh Quang Vi** – Information Technology Student, Can Tho University (CTU).

---
