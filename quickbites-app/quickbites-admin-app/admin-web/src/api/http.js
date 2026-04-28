import axios from 'axios';
import { authStorage } from '../lib/storage';

const baseURL = import.meta.env.VITE_API_BASE_URL || 'https://apsit-canteen.onrender.com/api/v1';

export const api = axios.create({
  baseURL,
  withCredentials: false,
});

let refreshInFlight = null;

api.interceptors.request.use((config) => {
  const auth = authStorage.get();
  if (auth?.jwt) {
    config.headers.Authorization = `Bearer ${auth.jwt}`;
  }
  return config;
});

api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;
    const status = error?.response?.status;

    if (status !== 401 || originalRequest?._retry) {
      return Promise.reject(error);
    }

    const auth = authStorage.get();
    if (!auth?.refreshToken) {
      authStorage.clear();
      window.location.href = '/login';
      return Promise.reject(error);
    }

    originalRequest._retry = true;

    try {
      if (!refreshInFlight) {
        refreshInFlight = axios.post(`${baseURL}/auth/refresh-jwt`, {
          refreshToken: auth.refreshToken,
        });
      }

      const refreshRes = await refreshInFlight;
      const next = {
        ...auth,
        jwt: refreshRes.data.jwt,
        refreshToken: refreshRes.data.refreshToken,
      };
      authStorage.set(next);

      originalRequest.headers.Authorization = `Bearer ${next.jwt}`;
      return api(originalRequest);
    } catch (refreshError) {
      authStorage.clear();
      window.location.href = '/login';
      return Promise.reject(refreshError);
    } finally {
      refreshInFlight = null;
    }
  }
);
