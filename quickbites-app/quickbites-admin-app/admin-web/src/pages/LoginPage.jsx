import { useMemo, useState } from 'react';
import { AlertCircle } from 'lucide-react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export default function LoginPage() {
  const navigate = useNavigate();
  const { login } = useAuth();
  const [form, setForm] = useState({ username: '', password: '' });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const friendlyError = useMemo(() => {
    if (!error) return '';

    const normalizedError = error.toLowerCase();
    if (
      normalizedError.includes('bad credentials') ||
      normalizedError.includes('wrong') ||
      normalizedError.includes('invalid') ||
      normalizedError.includes('username') ||
      normalizedError.includes('password')
    ) {
      return 'Wrong username or password. Please try again.';
    }

    return error;
  }, [error]);

  const hasError = Boolean(friendlyError);

  const updateField = (key, value) => {
    setForm((current) => ({ ...current, [key]: value }));
    if (error) setError('');
  };

  const onSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await login(form);
      navigate('/');
    } catch (err) {
      setError(err?.response?.data?.message || err?.message || 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-page">
      <form className={hasError ? 'auth-card auth-card-error' : 'auth-card'} onSubmit={onSubmit}>
        <h2>Admin Login</h2>
        <p>Uses /auth/admin-login flow</p>
        {hasError && (
          <div className="auth-alert" role="alert" aria-live="polite">
            <AlertCircle size={18} />
            <div>
              <strong>Couldn’t sign you in</strong>
              <span>{friendlyError}</span>
            </div>
          </div>
        )}
        <input
          placeholder="Username"
          value={form.username}
          className={hasError ? 'input-error' : ''}
          onChange={(e) => updateField('username', e.target.value)}
          required
        />
        <input
          placeholder="Password"
          type="password"
          value={form.password}
          className={hasError ? 'input-error' : ''}
          onChange={(e) => updateField('password', e.target.value)}
          required
        />
        <button type="submit" disabled={loading}>
          {loading ? <span className="btn-inline-loader"><span className="spinner sm" />Signing in...</span> : 'Sign in'}
        </button>
        <span>
          No admin account? <Link to="/signup">Create admin account</Link>
        </span>
      </form>
    </div>
  );
}
