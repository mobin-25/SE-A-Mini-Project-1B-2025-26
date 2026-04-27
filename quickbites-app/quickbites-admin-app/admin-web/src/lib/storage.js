const AUTH_KEY = 'canteen_admin_auth';

export const authStorage = {
  get() {
    try {
      const raw = localStorage.getItem(AUTH_KEY);
      return raw ? JSON.parse(raw) : null;
    } catch {
      return null;
    }
  },
  set(payload) {
    localStorage.setItem(AUTH_KEY, JSON.stringify(payload));
  },
  clear() {
    localStorage.removeItem(AUTH_KEY);
  },
};
