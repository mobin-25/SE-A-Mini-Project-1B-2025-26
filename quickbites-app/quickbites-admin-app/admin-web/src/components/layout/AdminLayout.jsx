import { LayoutDashboard, Package, ClipboardList, ScanLine, UserRoundCog, LogOut } from 'lucide-react';
import { Link, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';

const navItems = [
  { to: '/', label: 'Dashboard', icon: LayoutDashboard },
  { to: '/items', label: 'Items', icon: Package },
  { to: '/orders', label: 'Orders', icon: ClipboardList },
  { to: '/claim', label: 'Claim Order', icon: ScanLine },
  { to: '/profile', label: 'Profile', icon: UserRoundCog },
];

export default function AdminLayout() {
  const { pathname } = useLocation();
  const { logout, profile } = useAuth();

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <h2>Canteen Admin</h2>
        <nav>
          {navItems.map((item) => {
            const Icon = item.icon;
            const active = pathname === item.to;
            return (
              <Link key={item.to} to={item.to} className={active ? 'nav-link active' : 'nav-link'}>
                <Icon size={18} />
                <span>{item.label}</span>
              </Link>
            );
          })}
        </nav>
        <button className="logout-btn" onClick={logout}>
          <LogOut size={16} /> Logout
        </button>
      </aside>

      <main className="content">
        <header className="topbar">
          <div>
            <h1>Admin Control Panel</h1>
            <p>Welcome, {profile?.username || 'Admin'}</p>
          </div>
        </header>
        <Outlet />
      </main>
    </div>
  );
}
