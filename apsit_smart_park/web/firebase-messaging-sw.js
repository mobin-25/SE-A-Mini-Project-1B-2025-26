// Firebase Messaging Service Worker
// Required for Firebase Cloud Messaging on web.
// IMPORTANT: The config values here MUST match firebase_options.dart exactly.

importScripts("https://www.gstatic.com/firebasejs/11.6.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/11.6.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyBfdm_IUhkuFiVkc-Vra79ES9Cq55qu1NM",
  authDomain: "apsit-smart-park-31d03.firebaseapp.com",
  projectId: "apsit-smart-park-31d03",
  storageBucket: "apsit-smart-park-31d03.appspot.com",
  messagingSenderId: "64688450202",
  // Use the Android App ID as fallback until a Web app is registered in Firebase Console.
  // Once registered, replace with the actual web appId from Project Settings → Your apps → Web.
  appId: "1:64688450202:android:82bd0eff33ed0c9aca0d23",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function (payload) {
  console.log("[firebase-messaging-sw.js] Background message received:", payload);
  const notificationTitle = payload.notification?.title || "APSIT Smart Park";
  const notificationOptions = {
    body: payload.notification?.body || "",
    icon: "/icons/Icon-192.png",
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});
