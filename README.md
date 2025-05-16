# TravelBuddy 🌍✈️ [Working Title]

TravelBuddy is an all-in-one travel app. It helps users track their travel plans, explore travel styles, and connect with other travelers.  This app was developed as part of the CMSC 23 - Mobile Programming course at the University of the Philippines - Los Baños.
## Features 🚀

- **User Authentication**: Sign in with email/password or Google Sign-In.
- **Travel Management**: Add, edit, and delete travel records.
- **Travel Styles**: Customize your travel preferences.
- **Cloud Integration**: Data is stored and synced using Firebase Firestore, a popular document database.
## Screenshots 📸

| Home Page | Travel Styles | Travel Planning |
|-----------|---------------|-----------------|
| ![Home](assets/screenshots/home.png) | ![Travel Styles](assets/screenshots/travel_styles.png) | ![Expenses](assets/screenshots/expenses.png) |

## Installation 🛠️

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Firebase Project](https://firebase.google.com/)
- A code editor like [VS Code](https://code.visualstudio.com/)

### Steps
1. Clone the repository:
   ```bash
   git clone https://github.com/smmariquit/travelbuddy.git
   cd travelbuddy
   ```
2. Install dependencies:
    ```bash
    flutter pub get
    ```
3. Set up Firebase
4. Run the app
    ```bash
    flutter run
    ```
---
## Folder Structure 📂
```
lib/
├── api/                  # Firebase API integrations
├── providers/            # State management using Provider
├── screens/              # UI screens
├── models/               # Templates for data entities
├── main.dart             # Entry point of the app
```
Created with https://ascii-tree-generator.com/

## Technologies Used 🛠️
* Flutter - front-end
* Firebase - back-end
  * Firebase Authentication
  * Cloud Firestore
## Developers 👩‍💻👨‍💻👨‍💻

* Windee Rose De Ramos - II BSCS
* Simonee Ezekiel Mariquit - II BSCS ([LinkedIn](https://linkedin.com/in/stimmie))
* Jason Duran - II BSCS
## References 📚
* [Flutter Documentation](https://flutter.dev/docs)
* [Firebase Documentation](https://firebase.google.com/docs)
* [Material Design](https://m3.material.io/)
* CMSC 23 Resources
## Acknowledgements 🙏
* Many thanks to the CMSC 23 instructors for their guidance* Some parts of this app were developed with the assistance of ChatGPT and other LLMs
