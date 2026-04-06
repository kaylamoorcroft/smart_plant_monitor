importScripts(
  "https://www.gstatic.com/firebasejs/10.12.4/firebase-app-compat.js"
);
importScripts(
  "https://www.gstatic.com/firebasejs/10.12.4/firebase-messaging-compat.js"
);

// For Firebase JS SDK v7.20.0 and later, measurementId is optional
firebase.initializeApp({
  apiKey: "AIzaSyCUETSy0XK5qQe3eHZF4X890a9Es5uBg2g",
  authDomain: "smart-plant-health-monitor.firebaseapp.com",
  projectId: "smart-plant-health-monitor",
  storageBucket: "smart-plant-health-monitor.firebasestorage.app",
  messagingSenderId: "828732015536",
  appId: "1:828732015536:web:b40b22aedc54fa0ac88c75",
  measurementId: "G-9FWSV02EP9"
});

const messaging = firebase.messaging();

// Optional: Background message handler
messaging.onBackgroundMessage((payload) => {
  console.log("Received background message: ", payload);
});