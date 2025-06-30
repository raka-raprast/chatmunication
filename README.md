# Chatmunication
![Wireframe - 1](https://github.com/user-attachments/assets/6bbdea8b-e7a8-4f5b-8b36-c61a742b959a)


**Chatmunication** is a Flutter-based mobile application designed to enable real-time communication, offering features like messaging, voice, and video calls. This project is currently under development.

## 🚀 Getting Started

To get started with this Flutter project:

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Dart SDK (usually bundled with Flutter)
- A suitable IDE (e.g., VS Code, Android Studio)
- A connected device or emulator

### 🧱 Features
✉️ Real-time messaging
📞 Voice and video call support
🔐 Firebase authentication
🗂️ User profiles
📲 Responsive UI across Android and iOS

## 🛠 Backend

This app is powered by a custom backend built with:

- **Language**: [Go (Golang)](https://golang.org/)
- **Real-time Communication**: WebSocket & [WebRTC](https://webrtc.org/)
- **Signaling Server**: Custom implementation for managing WebRTC call setup
- **Authentication**: Firebase Authentication (handled in the Flutter app)

> The backend handles user presence, signaling for calls, and real-time messaging via WebSockets.

🔗 You can find the backend code here: [github.com/raka-raprast/chatmunication-api](https://github.com/raka-raprast/chatmunication-api)

