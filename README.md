# KeyNote Chat (KeyChat)

A modern, glassmorphic Flutter application for managing keys, secure notes, and AI-assisted conversations, featuring a powerful Python FastAPI backend and Supabase for secure authentication and real-time database syncing.

## Features

- **User Authentication**: Secure Login and Signup via Supabase with OTP verification and Reset Password functionality.
- **App Pin Lock**: Additional layer of security with a custom PIN lock screen to protect sensitive data.
- **Key Management**: Create, organize, and favorite security keys, API tokens, or secrets.
- **Secure Notes**: A responsive and rich UI for jotting down secure notes.
- **KeyNote Chat**: An intelligent, ChatGPT-style interface for seamless conversation and seamless key integration.
- **Profile & Customization**: Personalization with multiple chat styles (Glass, Bubble, Minimal), Dark/Light mode theme switching, and robust profile management.
- **FastAPI Backend**: A scalable Python backend handling advanced API operations, structured file uploads, and core integrations.

## Prerequisites

- **Flutter SDK** (>= 3.10.8)
- **Python** (>= 3.9)
- **Supabase Account/Project**

## Installation & Setup Guide

### 1. Clone the repository
```bash
git clone https://github.com/JithinGK51/keychat.git
cd keychat
```

### 2. Backend Setup (FastAPI)
The backend provides essential API capabilities and enhanced business logic.

Navigate to the backend directory:
```bash
cd backend
```

Create a virtual environment:
```bash
python -m venv venv
```

Activate the virtual environment:
- **Windows**: `.\venv\Scripts\Activate.ps1` (or `.\venv\Scripts\activate.bat`)
- **Mac/Linux**: `source venv/bin/activate`

Install dependencies:
```bash
pip install -r requirements.txt
```

Environment Setup:
Create a `.env` file in the `backend/` directory and configure the environment variables:
```env
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_api_key
# Add other required backend secrets here
```

Run the Backend Server:
```bash
uvicorn main:app --reload
```
Alternatively, on Windows, you can just run the initialization script:
```powershell
.\run.ps1
```
The API will be available at `http://localhost:8000`.

### 3. Frontend Setup (Flutter)
The frontend uses Riverpod for state management and Supabase Flutter for client-side queries.

Navigate back to the project root:
```bash
cd ..
```

Fetch Flutter dependencies:
```bash
flutter pub get
```

Environment Setup:
Configure your Supabase Project URL and Anon Key inside your Flutter environment securely (e.g., inside `lib/services/supabase_service.dart` or via `.env` if utilizing a flutter dotenv package).

Run the Application:
```bash
flutter run
```

## Project Structure

- `lib/`: Contains the main Flutter application source code.
  - `models/`: Data definitions (User, Key, Note, Conversation).
  - `providers/`: Riverpod state providers for global app state routing.
  - `screens/`: Core App Views (`auth/`, `home/`, `keys/`, `profile/`, `settings/`).
  - `services/`: Logic for Supabase, Uploads, Exports, and Authentication.
  - `widgets/`: Reusable UI components including sidebars and overlays.
- `backend/`: FastAPI Python server source code.
  - `routes/`: Isolated router endpoints for `auth`, `notes`, `keys`, `uploads`, and `conversations`.
  - `main.py`: Entry point to boot the Uvicorn ASGI server.
- `pubspec.yaml`: Flutter project metadata and package dependencies.

## Technologies Used

- **Frontend**: Flutter, Riverpod, Supabase Flutter, Flutter Animate, Google Fonts, Shimmer
- **Backend**: Python 3, FastAPI, Uvicorn, Passlib (bcrypt), Python-Jose
- **Database & Auth**: Supabase (PostgreSQL)
