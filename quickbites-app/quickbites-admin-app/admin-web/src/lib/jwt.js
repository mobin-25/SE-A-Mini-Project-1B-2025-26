export function decodeJwt(token) {
  try {
    const payload = token.split('.')[1];
    const normalized = payload.replace(/-/g, '+').replace(/_/g, '/');
    const decoded = JSON.parse(atob(normalized));
    return decoded;
  } catch {
    return null;
  }
}

export function isExpired(token) {
  const data = decodeJwt(token);
  if (!data?.exp) return true;
  return Date.now() >= data.exp * 1000;
}
