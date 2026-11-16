// Firebase Cloud Messaging Service Worker
// Must be at the root of the web folder so the browser can register it.

importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Same config as firebase_options.dart → web
firebase.initializeApp({
  apiKey: 'AIzaSyDLyzbgwzcIqzf7IEFyPzXgENY3N6sVkJw',
  appId: '1:784598194727:web:2518ebc6254b5cc9c64c02',
  messagingSenderId: '784598194727',
  projectId: 'college-bridge-96f08',
  authDomain: 'college-bridge-96f08.firebaseapp.com',
  storageBucket: 'college-bridge-96f08.firebasestorage.app',
});

const messaging = firebase.messaging();

// Handle background messages (app not in foreground tab)
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Background message received:', payload);

  const title = payload.notification?.title ?? payload.data?.title ?? 'College Bridge';
  const body  = payload.notification?.body  ?? payload.data?.body  ?? payload.data?.message ?? '';

  self.registration.showNotification(title, {
    body: body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data ?? {},
  });
});

// Also listen for raw push events in case of data-only payload
self.addEventListener('push', (event) => {
  if (event.data) {
    try {
      const data = event.data.json();
      console.log('[firebase-messaging-sw.js] Raw push event:', data);
      const title = data.notification?.title ?? data.data?.title ?? 'College Bridge Notice';
      const body = data.notification?.body ?? data.data?.body ?? data.data?.message ?? '';
      event.waitUntil(
        self.registration.showNotification(title, {
          body: body,
          icon: '/icons/Icon-192.png',
          badge: '/icons/Icon-192.png',
          data: data.data ?? {},
        })
      );
    } catch (e) {
      console.warn('[firebase-messaging-sw.js] Push parse error:', e);
    }
  }
});

// Handle notification click — focus the tab or open the app
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
      for (const client of windowClients) {
        if ('focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});
