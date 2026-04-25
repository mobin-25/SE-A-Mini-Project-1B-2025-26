import { authStorage } from './storage';

function resolveWsBaseUrl() {
  const apiBase = import.meta.env.VITE_API_BASE_URL || 'https://apsit-canteen.onrender.com/api/v1';
  return apiBase.replace(/\/$/, '');
}

export function subscribeToAdminOrderEvents(onMessage) {
  const auth = authStorage.get();
  if (!auth?.jwt) {
    return () => {};
  }

  let client = null;
  let isUnmounted = false;

  (async () => {
    try {
      const wsBaseUrl = resolveWsBaseUrl();
      const [{ Client }, sockJsModule] = await Promise.all([
        import('@stomp/stompjs'),
        import('sockjs-client/dist/sockjs'),
      ]);

      if (isUnmounted) return;

      const SockJS = sockJsModule.default || sockJsModule;

      client = new Client({
        reconnectDelay: 5000,
        connectHeaders: {
          Authorization: `Bearer ${auth.jwt}`,
        },
        webSocketFactory: () => new SockJS(`${wsBaseUrl}/ws`),
      });

      client.onConnect = () => {
        client.subscribe('/topic/admin/order', (frame) => {
          try {
            const payload = JSON.parse(frame.body);
            onMessage?.(payload);
          } catch {
            onMessage?.(null);
          }
        });
      };

      client.onStompError = () => {
        // Keep UI alive if broker returns a STOMP error frame.
      };

      client.activate();
    } catch {
      // Fail silently to avoid breaking the whole page.
    }
  })();

  return () => {
    isUnmounted = true;
    client?.deactivate();
  };
}
