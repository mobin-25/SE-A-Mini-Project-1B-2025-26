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
