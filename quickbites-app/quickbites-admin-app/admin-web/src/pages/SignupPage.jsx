import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export default function SignupPage() {
  const { signupAdmin } = useAuth();
  const navigate = useNavigate();
  const [form, setForm] = useState({ username: '', password: '', mobileNumber: '' });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const onSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await signupAdmin(form);
      navigate('/login');
    } catch (err) {
      setError(err?.response?.data?.message || err?.message || 'Signup failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-page">
      <form className="auth-card" onSubmit={onSubmit}>
        <h2>Create Admin Account</h2>
        <p>Calls /auth/signup with role ADMIN</p>
        <input
          placeholder="Username"
          value={form.username}
          onChange={(e) => setForm((s) => ({ ...s, username: e.target.value }))}
          required
        />
        <input
          placeholder="Mobile Number"
          value={form.mobileNumber}
          onChange={(e) => setForm((s) => ({ ...s, mobileNumber: e.target.value }))}
          required
        />
        <input
          placeholder="Password"
          type="password"
          value={form.password}
          onChange={(e) => setForm((s) => ({ ...s, password: e.target.value }))}
          required
        />
        {error && <div className="error-msg">{error}</div>}
        <button type="submit" disabled={loading}>
          {loading ? <span className="btn-inline-loader"><span className="spinner sm" />Creating...</span> : 'Create Admin'}
        </button>
        <span>
          Already have account? <Link to="/login">Login</Link>
        </span>
      </form>
    </div>
  );
}
