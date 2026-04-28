import { useMemo, useState } from 'react';
import { ArrowLeft } from 'lucide-react';
import { Link } from 'react-router-dom';
import { changeAdminPassword } from '../api/admin';

export default function ChangePasswordPage() {
  const [form, setForm] = useState({
    oldPassword: '',
    newPassword: '',
    confirmPassword: '',
  });
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState({ success: '', error: '' });

  const canSubmit = useMemo(() => {
    return (
      form.oldPassword.trim().length > 0 &&
      form.newPassword.trim().length >= 6 &&
      form.newPassword === form.confirmPassword
    );
  }, [form]);

  const onSubmit = async (e) => {
    e.preventDefault();
    setStatus({ success: '', error: '' });

    if (form.newPassword !== form.confirmPassword) {
      setStatus({ success: '', error: 'New password and confirm password must match.' });
      return;
    }

    setLoading(true);
    try {
      await changeAdminPassword({
        oldPassword: form.oldPassword,
        newPassword: form.newPassword,
      });
      setForm({ oldPassword: '', newPassword: '', confirmPassword: '' });
      setStatus({ success: 'Password changed successfully.', error: '' });
    } catch (err) {
      setStatus({ success: '', error: err?.response?.data?.message || 'Failed to change password.' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="grid gap-16 page-enter">
      <div className="row between">
        <h3>Change Password</h3>
        <Link to="/profile" className="secondary-btn link-btn">
          <ArrowLeft size={14} /> Back to Profile
        </Link>
      </div>

      {status.success && <div className="success-msg profile-banner success">{status.success}</div>}
      {status.error && <div className="error-msg profile-banner error">{status.error}</div>}

      <div className="card narrow">
        <form className="grid-form" onSubmit={onSubmit}>
          <div className="field-group">
            <label className="field-label">Current Password</label>
            <input
              type="password"
              placeholder="Enter current password"
              value={form.oldPassword}
              onChange={(e) => setForm((s) => ({ ...s, oldPassword: e.target.value }))}
              required
            />
          </div>

          <div className="field-group">
            <label className="field-label">New Password</label>
            <input
              type="password"
              placeholder="At least 6 characters"
              value={form.newPassword}
              onChange={(e) => setForm((s) => ({ ...s, newPassword: e.target.value }))}
              required
            />
          </div>

          <div className="field-group">
            <label className="field-label">Confirm New Password</label>
            <input
              type="password"
              placeholder="Re-enter new password"
              value={form.confirmPassword}
              onChange={(e) => setForm((s) => ({ ...s, confirmPassword: e.target.value }))}
              required
            />
          </div>

          <button type="submit" disabled={loading || !canSubmit}>
            {loading ? <span className="btn-inline-loader"><span className="spinner sm" />Updating...</span> : 'Update Password'}
          </button>
        </form>
      </div>
    </div>
  );
}
