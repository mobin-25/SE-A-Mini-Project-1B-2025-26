# 🚗 APSIT Smart Park

A smart parking management mobile application built using **Flutter** and **Firebase** to streamline parking operations within the APSIT campus.

---

## 📱 Overview

APSIT Smart Park is designed to simplify and optimize parking for students and staff by providing **real-time slot availability**, **quick reservations**, and **smart alerts**.

---

## ✨ Features

- 🔐 **Secure Login**
  - Login using APSIT Moodle ID for authorized access

- 🗺️ **Interactive Parking Map**
  - View parking layout with real-time slot availability

- 🅿️ **Slot Reservation**
  - Reserve parking slots instantly based on vehicle type

- 🔔 **Parking Alerts**
  - Notifications for wrong or restricted parking

- 🧭 **Zone Segregation**
  - Separate parking areas for students and faculty

---

## 🎯 Objectives

- Provide real-time parking availability  
- Reduce time spent searching for parking  
- Enable quick and easy slot reservation  
- Improve parking discipline on campus  
- Ensure efficient space utilization  
- Minimize congestion and unorganized parking  
- Enhance user convenience through a mobile app  

---

## 🛠️ Tech Stack

### Front-End
- **Flutter (Dart)** – Cross-platform mobile development  
- **Material Design 3** – Modern UI components  
- **Provider** – State management  
- **Google Fonts (Poppins)** – UI styling  

### Back-End
- **Firebase Authentication** – Secure login  
- **Cloud Firestore** – NoSQL database  
- **Firebase Realtime Database** – Live updates  
- **Firebase Cloud Messaging (FCM)** – Push notifications  

---

## 📋 Platform Requirements

- Android / iOS smartphone  
- Active internet connection  

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK installed  
- Firebase project setup  
- Android Studio / VS Code  

### Installation

```bash
# Clone the repository
git clone https://github.com/shivanshshukla778/APSIT-SMART-PARK.git

# Navigate to project folder
cd apsit_smart_park

# Install dependencies
flutter pub get

# Run the app
flutter run
```

---

## 📂 Project Structure

```
lib/
 ├── models/
 ├── services/
 ├── providers/
 ├── screens/
 ├── widgets/
 └── main.dart
```

---

## 🔒 Security

- Authentication via Firebase
- Database rules enforced for authorized access
- Role-based parking access (Student/Faculty)

---

## 📸 Screenshots & Design

### 🧩 PROJECT DESIGN
![PROJECT DESIGN](https://github.com/shivanshshukla778/APSIT-SMART-PARK/raw/main/PROJECT%20DESIGN.jpeg)

---

### 📱 APP SCREENSHOT
![APP SCREENSHOT](https://github.com/shivanshshukla778/APSIT-SMART-PARK/raw/main/app%20screenshot.jpeg)

---

### 📱 APP SCREENSHOT 2
![APP SCREENSHOT 2](https://github.com/shivanshshukla778/APSIT-SMART-PARK/raw/main/app%20screenshot%202.png)

---

## 📄 License

This project is part of the APSIT Smart Parking System initiative.

---

## 👨‍💻 Author

**Shivanshu Shukla**  
GitHub: [@shivanshshukla778](https://github.com/shivanshshukla778)

---

**Happy Parking! 🚗**
# KYB App - Food Ingredient Analysis

## Overview
KYB App is a Flutter-based mobile application designed to help users analyze food products and their ingredients.  
The application integrates the OpenFoodFacts API to fetch product data and includes an in-app Ingredient Directory that provides detailed information about various food ingredients.

---

## Features
- Search food products using OpenFoodFacts API  
- Scan product barcodes for quick results  
- OCR-based text recognition for ingredient extraction  
- Ingredient Directory with detailed descriptions  
- Basic authentication and authorization  
- Clean and user-friendly interface  

---

## Tech Stack
- Flutter  
- Dart  
- OpenFoodFacts API
- SQLite (for local data storage and authentication)

---

## Project Structure
- `lib/` – Core application logic  
- `assets/` – Images and resources  
- `android/` – Android platform files  

---

## How to Run
1. Download or clone the repository  
2. Open the project in VS Code or Android Studio  
3. Run the following commands:

```bash
flutter pub get
flutter run
