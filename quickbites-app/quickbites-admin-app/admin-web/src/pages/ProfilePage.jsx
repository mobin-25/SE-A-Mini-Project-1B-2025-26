import { useEffect, useState } from 'react';
import { KeyRound, Pencil, Save, X } from 'lucide-react';
import { Link } from 'react-router-dom';
import {
  fetchAdminProfile,
  fetchCanteenOpenStatus,
  toggleAdminDutyStatus,
  updateAdminProfile,
} from '../api/admin';
import { useAuth } from '../context/AuthContext';

const PROFILE_CACHE_KEY = 'canteen_admin_profile_cache';

function readCachedProfile() {
  try {
    const raw = localStorage.getItem(PROFILE_CACHE_KEY);
    return raw ? JSON.parse(raw) : {};
  } catch {
    return {};
  }
}

export default function ProfilePage() {
  const { profile, updateProfile } = useAuth();
  const cachedProfile = readCachedProfile();

  const [profileForm, setProfileForm] = useState({
    username: profile?.username || cachedProfile?.username || '',
    email: profile?.email || cachedProfile?.email || '',
    staffCount: profile?.staffCount || cachedProfile?.staffCount || 1,
  });

  const [canteenOpen, setCanteenOpen] = useState(null);
  const [dutyStatusLoading, setDutyStatusLoading] = useState(true);
  const [editMode, setEditMode] = useState(false);
  const [loading, setLoading] = useState({ update: false, duty: false });
  const [status, setStatus] = useState({ success: '', error: '' });
  const canteenStatusText = dutyStatusLoading
    ? 'Loading status...'
    : canteenOpen === null
      ? 'Status unavailable'
      : canteenOpen
        ? 'Canteen Open'
        : 'Canteen Closed';

  const setMessage = (success = '', error = '') => setStatus({ success, error });

  useEffect(() => {
    let mounted = true;

    async function loadAdminProfile() {
      try {
        const liveProfile = await fetchAdminProfile();
        if (!mounted) return;

        setProfileForm({
          username: liveProfile?.username || '',
          email: liveProfile?.email || '',
          staffCount: liveProfile?.staffCount || 1,
        });
        updateProfile(liveProfile);
        localStorage.setItem(PROFILE_CACHE_KEY, JSON.stringify(liveProfile));
      } catch {
        // Keep JWT/cached fallback values when profile fetch fails.
      }
    }

    async function loadCanteenStatus() {
      try {
        const liveStatus = await fetchCanteenOpenStatus();
        if (mounted) setCanteenOpen(Boolean(liveStatus));
      } catch {
        if (mounted) setCanteenOpen(null);
      } finally {
        if (mounted) setDutyStatusLoading(false);
      }
    }

    loadAdminProfile();
    loadCanteenStatus();
    return () => {
      mounted = false;
    };
  }, [updateProfile]);

  const cancelEdit = () => {
    setProfileForm({
      username: profile?.username || cachedProfile?.username || '',
      email: profile?.email || cachedProfile?.email || '',
      staffCount: profile?.staffCount || cachedProfile?.staffCount || 1,
    });
    setEditMode(false);
    setMessage();
  };

  const handleUpdateProfile = async (e) => {
    e.preventDefault();
    setMessage();
    setLoading((prev) => ({ ...prev, update: true }));
    try {
      const payload = {
        username: profileForm.username,
        email: profileForm.email,
        staffCount: Number(profileForm.staffCount) || 1,
      };
      const updated = await updateAdminProfile(payload);
      updateProfile(updated);
      localStorage.setItem(PROFILE_CACHE_KEY, JSON.stringify(updated));
      setEditMode(false);
      setMessage('Profile updated successfully.');
    } catch (err) {
      setMessage('', err?.response?.data?.message || 'Failed to update profile.');
    } finally {
      setLoading((prev) => ({ ...prev, update: false }));
    }
  };

  const handleToggleDuty = async () => {
    setMessage();
    setLoading((prev) => ({ ...prev, duty: true }));
    try {
      const nextState = await toggleAdminDutyStatus();
      setCanteenOpen(Boolean(nextState));
      setMessage(`Canteen is now ${nextState ? 'OPEN' : 'CLOSED'}.`);
    } catch (err) {
      setMessage('', err?.response?.data?.message || 'Failed to toggle canteen status.');
    } finally {
      setLoading((prev) => ({ ...prev, duty: false }));
    }
  };

  return (
    <div className="profile-shell page-enter">
      <div className="card profile-hero">
        <div>
          <h3>Admin Profile</h3>
          <p>Manage account details, security settings, and canteen availability.</p>
        </div>
        <div className="canteen-status-chip">
          {dutyStatusLoading
            ? <span className="status-loading-bar" />
            : <span className="duty-dot" data-state={canteenOpen === true ? 'open' : canteenOpen === false ? 'closed' : 'unknown'} />}
          <strong>{canteenStatusText}</strong>
          <button className="secondary-btn" onClick={handleToggleDuty} disabled={loading.duty || dutyStatusLoading}>
            {loading.duty ? 'Updating...' : 'Toggle'}
          </button>
        </div>
      </div>

      {status.success && <div className="success-msg profile-banner success">{status.success}</div>}
      {status.error && <div className="error-msg profile-banner error">{status.error}</div>}

      <div className="profile-summary-grid">
        <div className="card summary-card">
          <span>Admin</span>
          <strong>{profileForm.username || '—'}</strong>
        </div>
        <div className="card summary-card">
          <span>Email</span>
          <strong>{profileForm.email || '—'}</strong>
        </div>
        <div className="card summary-card">
          <span>Staff Capacity</span>
          <strong>{profileForm.staffCount || 1}</strong>
        </div>
      </div>

      <div className="profile-grid">
        <div className="card profile-card">
          <div className="row between">
            <h4>Profile Details</h4>
            {!editMode ? (
              <button type="button" className="secondary-btn" onClick={() => setEditMode(true)}>
                <Pencil size={14} /> Edit
              </button>
            ) : (
              <button type="button" className="secondary-btn" onClick={cancelEdit}>
                <X size={14} /> Cancel
              </button>
            )}
          </div>

          <form className="profile-form top-12" onSubmit={handleUpdateProfile}>
            <div className="field-group">
              <label className="field-label">Username</label>
              <input
                className={!editMode ? 'readonly-input' : ''}
                placeholder="Username"
                value={profileForm.username}
                onChange={(e) => setProfileForm((s) => ({ ...s, username: e.target.value }))}
                disabled={!editMode}
                required
              />
            </div>
            <div className="field-group">
              <label className="field-label">Email Address</label>
              <input
                className={!editMode ? 'readonly-input' : ''}
                placeholder="Email"
                type="email"
                value={profileForm.email}
                onChange={(e) => setProfileForm((s) => ({ ...s, email: e.target.value }))}
                disabled={!editMode}
                required
              />
            </div>
            <div className="field-group">
              <label className="field-label">Staff Count</label>
              <input
                className={!editMode ? 'readonly-input' : ''}
                placeholder="Staff Count"
                type="number"
                min="1"
                value={profileForm.staffCount}
                onChange={(e) => setProfileForm((s) => ({ ...s, staffCount: e.target.value }))}
                disabled={!editMode}
                required
              />
            </div>
            {editMode && (
              <button type="submit" disabled={loading.update}>
                {loading.update
                  ? <span className="btn-inline-loader"><span className="spinner sm" />Saving...</span>
                  : <span className="btn-inline-loader"><Save size={14} />Save Profile</span>}
              </button>
            )}
          </form>
        </div>

        <div className="card profile-card security-card">
          <div className="row between">
            <h4>Security</h4>
            <Link to="/profile/change-password" className="secondary-btn link-btn">
              <KeyRound size={14} /> Change Password
            </Link>
          </div>
          <p className="top-12 muted-text">
            Protect your admin account by rotating your password regularly and avoiding reuse across platforms.
          </p>
        </div>
      </div>
    </div>
  );
}
