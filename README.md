# MIT Campus

MIT Campus is a Flutter project designed to facilitate communication and task management within the ECE Department of MIT. The project aims to provide a platform for students and faculty to interact, share information, and manage tasks efficiently.

## Table of Contents

- [Project Description](#project-description)
- [Setup Instructions](#setup-instructions)
- [Usage Guidelines](#usage-guidelines)
- [Project Features](#project-features)
- [Dependencies](#dependencies)
- [Architecture and Code Structure](#architecture-and-code-structure)
- [Contribution Guidelines](#contribution-guidelines)
- [License](#license)

## Project Description

MIT Campus is a comprehensive platform for the ECE Department of MIT. It includes features such as user authentication, chat functionality, task management, and more. The project is built using Flutter and Firebase, providing a robust and scalable solution for departmental communication and task management.

## Setup Instructions

To set up the project locally, follow these steps:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Rudra-ravi/mitcampus-prod.git
   cd mitcampus-prod
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase:**
   - Create a Firebase project in the [Firebase Console](https://console.firebase.google.com/).
   - Add an Android and iOS app to your Firebase project.
   - Download the `google-services.json` file for Android and place it in the `android/app` directory.
   - Download the `GoogleService-Info.plist` file for iOS and place it in the `ios/Runner` directory.
   - Enable Firebase Authentication, Firestore, and Cloud Messaging in the Firebase Console.

4. **Run the project:**
   ```bash
   flutter run
   ```

## Usage Guidelines

To use the project, follow these guidelines:

- **Login:** Use your MIT email to log in. If you are a HOD, use the HOD email provided.
- **Chat:** Use the chat feature to communicate with other users in the department.
- **Tasks:** Create, update, and manage tasks. Assign tasks to users and track their progress.

## Project Features

- **User Authentication:** Secure login using Firebase Authentication.
- **Chat Functionality:** Real-time chat using Firestore.
- **Task Management:** Create, update, and manage tasks. Assign tasks to users and track their progress.
- **Notifications:** Receive notifications for new messages and task updates.

## Screenshots

<img src="https://github.com/user-attachments/assets/95cc0213-184d-4a64-8b99-f4897016447c" alt="2024-11-17 at 10 48 44 AM" width="200">
<img src="https://github.com/user-attachments/assets/0b856100-4b96-433a-99d3-beda91e97373" alt="2024-11-17 at 10 40 31 AM (2)" width="200">
<img src="https://github.com/user-attachments/assets/87602b01-7cef-484f-844c-1abae7889420" alt="2024-11-17 at 10 40 31 AM (1)" width="200">
<img src="https://github.com/user-attachments/assets/852c4489-1735-451c-bd0b-5783b1692a93" alt="2024-11-17 at 10 40 31 AM" width="200">
<img src="https://github.com/user-attachments/assets/d2939dbb-8b26-4d88-be38-055e10df63d0" alt="2024-11-17 at 10 40 30 AM (2)" width="200">
<img src="https://github.com/user-attachments/assets/275e551b-d38a-426a-b71e-4ef3c1612964" alt="2024-11-17 at 10 40 30 AM (1)" width="200">
<img src="https://github.com/user-attachments/assets/a956d958-15a6-4258-b472-e13a80060389" alt="2024-11-17 at 10 40 30 AM" width="200">

## Dependencies

The project uses the following dependencies:

- `flutter_bloc: ^8.1.6`
- `firebase_core: ^3.7.0`
- `firebase_auth: ^5.3.2`
- `cloud_firestore: ^5.4.5`
- `shared_preferences: ^2.3.3`
- `connectivity_plus: ^6.1.0`
- `package_info_plus: ^8.1.1`
- `rxdart: ^0.28.0`
- `multi_select_flutter: ^4.1.3`
- `url_launcher: ^6.3.1`
- `firebase_messaging: ^15.1.4`
- `flutter_local_notifications: ^18.0.1`
- `intl: ^0.19.0`
- `flutter_native_splash: ^2.4.2`
- `flutter_secure_storage: ^8.0.0`

## Architecture and Code Structure

The project follows a modular architecture with the following main components:

- **Blocs:** Handles the business logic of the application using the BLoC pattern.
- **Models:** Defines the data structures used in the application.
- **Repositories:** Handles data operations and interactions with Firebase.
- **Services:** Provides utility functions and services such as notifications and credential management.
- **Screens:** Contains the UI components of the application.
- **Widgets:** Contains reusable UI components.

## Contribution Guidelines

We welcome contributions to the project. To contribute, follow these steps:

1. **Fork the repository:**
   - Click the "Fork" button at the top right of the repository page.

2. **Clone your forked repository:**
   ```bash
   git clone https://github.com/<your-username>/mitcampus-prod.git
   cd mitcampus-prod
   ```

3. **Create a new branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

4. **Make your changes and commit them:**
   ```bash
   git add .
   git commit -m "Add your commit message"
   ```

5. **Push your changes to your forked repository:**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a pull request:**
   - Go to the original repository and click the "New pull request" button.
   - Select your branch and submit the pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
