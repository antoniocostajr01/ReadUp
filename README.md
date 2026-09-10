# ReadUp 📚

**ReadUp** is an iOS application designed to help users build and maintain a consistent reading habit through goal setting, progress tracking, and gamification.

The app focuses on simplicity and engagement, transforming reading sessions into a motivating and rewarding experience.

This repository is the iOS app. It talks to a separate Express/Prisma backend
(`ReadUpBackend`) for accounts, library data, and search — the app is online-only,
aside from a small local queue that holds a reading session if it can't reach the
backend right away.

## ✨ Features

- ⏱ Track reading sessions with time and progress monitoring, shown live on the
  lock screen and Dynamic Island via a Live Activity.
- 📚 Book organization: to-read list, completed books, abandoned/rereading states,
  and reading history.
- 🔍 Book search backed by Open Library, with a barcode scanner for batch-adding
  books by ISBN.
- 📤 Share a finished session to Instagram Stories, or export it as an image.
- 🔥 Reading streaks and a reward system inspired by gamified learning apps.
- 📊 Dashboard with reading statistics and progress insights.

## 🛠 Technologies

- Swift  
- SwiftUI  
- iOS Development (Xcode)  
- Express + Prisma + PostgreSQL backend (`ReadUpBackend`, separate repository)
- Git & GitHub  

## 🚀 Getting Started

To run the project locally:

1. Clone the repository:
   ```bash
   git clone https://github.com/antoniocostajr01/ReadUp.git

2. Open the ReadUp.xcodeproj file in Xcode.

3. Select an iOS simulator or a physical device and run the project.

## 🎯 Purpose and Target Audience
ReadUp was created for young readers (ages 13–20) who want to develop a consistent reading habit.
It supports academic, technical, and leisure reading by combining productivity, education, and gamification in a single experience.


## 📂 Project Structure

```
ReadUp/
├── ReadUp.xcodeproj      # Xcode project file
├── ReadUp/               # SwiftUI views, view models, models, services, design system
├── ReadUpWidgets/         # Widget extension — the reading-session Live Activity
├── Shared/                # Code shared by the app and the widget extension
├── .gitignore
└── README.md
```

See `CLAUDE.md` for how the codebase is organized in detail and for the backend
repository's location.

## 👨‍💻 Author
Developed by Antônio Costa
📧 Email: antonioclaudiocostajr@gmail.com
🔗 GitHub: https://github.com/antoniocostajr01

## 📄 License
This project is licensed under the MIT License.
Feel free to use, modify, and distribute this project.


