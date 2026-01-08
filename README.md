**ExpenseX** is a modern, offline-first personal finance application built with **Flutter**. It allows users to seamlessly track income and expenses, manage multiple accounts and visualize financial health through interactive charts, all secured locally on the device using **SQLite**.

---

## 📱 Features

### 🚀 **Smart Dashboard**
- Real-time updates of Total Balance, Income, and Expenses.
- Stream-based architecture ensures the UI always reflects the latest database state.

### 🌍 **Location-Based Currency**
- Automatically detects the user's country using the device's **GPS Sensors**.
- Instantly switches currency symbols (e.g., LKR, USD, EUR) based on location.
- *Powered by `geolocator` and `geocoding`.*

### 📊 **Financial Insights**
- Visual breakdown of spending habits using interactive **Pie Charts**.
- Track monthly category budgets to avoid overspending.

### 💾 **Offline-First Data**
- All data is stored locally using **SQLite**, ensuring privacy and accessibility without an internet connection.
- Supports backup/restore of default categories and accounts.

### 🎨 **Customization**
- Profile management with camera/gallery integration.
- Custom categories with color-coded icons.

---

## 🛠️ Tech Stack

- **Framework:** Flutter (Dart)
- **Database:** SQLite (via `sqflite` & `path`)
- **State Management:** Provider & StreamControllers
- **Charts:** fl_chart
- **Location:** geolocator, geocoding
- **Storage:** shared_preferences (for user settings), path_provider

---

## ⚙️ Installation & Setup

Follow these steps to run the project on your local machine.

### 1. Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) installed.
- VS Code or Android Studio.
- An Android Emulator or Physical Device.

### 2. Clone the Repository

git clone [https://github.com/thesarakasun/expensex.git](https://github.com/thesarakasun/expensex.git)
cd expensex

### 3. Install Dependencies

- flutter pub get


### 4. Run the App

- Important: Ensure you have an Android Emulator running. Do not run on Windows Desktop as GPS features require mobile sensors.

flutter run


### 5.🔒 Permissions

- ACCESS_FINE_LOCATION - Required to detect the user's country for currency automation.
- ACCESS_COARSE_LOCATION - Fallback for when precise GPS is unavailable.
- INTERNET - Minimal usage required by the Geocoding API to resolve coordinates.
- READ_EXTERNAL_STORAGE - Required to pick a profile picture from the gallery.

