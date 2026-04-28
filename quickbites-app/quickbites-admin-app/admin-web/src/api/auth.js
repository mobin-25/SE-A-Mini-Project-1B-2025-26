import { api } from './http';

export async function adminLogin(payload) {
  const response = await api.post('/auth/admin-login', payload);
  return response.data;
}

export async function adminSignup(payload) {
  const response = await api.post('/auth/admin/signup', payload);
  return response.data;
}

export async function getCurrentUser() {
  const response = await api.get('/users');
  return response.data;
}
