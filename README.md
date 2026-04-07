# Smart Plant Health Monitor

An app that monitors plant “health” using environmental and soil sensors. 

## Description

The app acts as a real-time plant health dashboard with its main features including watering alerts, growth history and plant-specific recommendations. It has various screens for the different features. The main page contains a plant overview, from which the user can navigate to see specific sensor readings. A different page contains the plant’s history timeline. Moreover, there is a page with care tips based on the user’s plant. The user can choose to enable water reminders via push notifications or they can check the app manually to see updates on the plant.

## Installation.
- Open the root directory (`smart_plant_monitor/`) in an IDE of your choice
- From root directory, run `flutter pub get`
- For Android, ensure the Android SDK is configured in your IDE settings.
- For ios (if you are on macOS), navigate to the `ios/` folder and run `pod install`
- Run `flutter doctor` and fix any missing requirements or issues

## Usage
Choose a target device and execute `flutter run` in the terminal to start the app. Alternatively, use the 'run' button in your IDE

Please note that plant alerts (notifications) currently only work on andoid due to development restrictions with ios/macOS and chrome.
