import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid, Cell } from 'recharts';
import {
  fetchDeliveredTodayCount,
  fetchOrderCount,
  fetchOrdersByStatus,
  getInstantReadyItems,
  getItems,
  getItemsByCategory,
  getItemsByPriceRange,
} from '../api/admin';
import LoadingSpinner from '../components/common/LoadingSpinner';
import StatusBadge from '../components/common/StatusBadge';
import { subscribeToAdminOrderEvents } from '../lib/adminRealtime';

// Live pipeline statuses shown as stat cards (DELIVERED excluded — shown separately as "Today" via dedicated endpoint)
const PIPELINE_STATUSES = ['PENDING', 'IN_PROGRESS', 'READY', 'CANCELLED'];
const MENU_CATEGORIES = ['VEG', 'BEVERAGE', 'SNACK', 'BREAKFAST'];

const STATUS_LABELS = {
  PENDING: 'Pending',
  IN_PROGRESS: 'In Progress',
  READY: 'Ready',
  CANCELLED: 'Cancelled',
};

const BAR_COLORS = {
  PENDING: '#f59e0b',
  IN_PROGRESS: '#3b82f6',
  READY: '#10b981',
  CANCELLED: '#ef4444',
  'Delivered Today': '#7c3aed',
};

export default function DashboardPage() {
  const [stats, setStats] = useState({});
  const [deliveredToday, setDeliveredToday] = useState(0);
  const [queueStats, setQueueStats] = useState(null);
  const [spotlightOrders, setSpotlightOrders] = useState([]);
  const [itemInsights, setItemInsights] = useState({
    totalItems: 0,
    instantReady: 0,
    budgetItems: 0,
    categories: {},
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let isMounted = true;

    async function refreshLiveStatsOnly() {
      const [pendingRes, inProgressRes, readyRes, cancelledRes, todayRes] = await Promise.allSettled([
        fetchOrderCount('PENDING'),
        fetchOrderCount('IN_PROGRESS'),
        fetchOrderCount('READY'),
        fetchOrderCount('CANCELLED'),
        fetchDeliveredTodayCount(),
      ]);

      if (!isMounted) return;

      const pendingCount = pendingRes.status === 'fulfilled' ? pendingRes.value : 0;
      const inProgressCount = inProgressRes.status === 'fulfilled' ? inProgressRes.value : 0;
      const readyCount = readyRes.status === 'fulfilled' ? readyRes.value : 0;
      const cancelledCount = cancelledRes.status === 'fulfilled' ? cancelledRes.value : 0;
      const today = todayRes.status === 'fulfilled' ? todayRes.value : 0;

      setQueueStats({
        totalOrdersInQueue: pendingCount + inProgressCount,
        pendingOrders: pendingCount,
        inProgressOrders: inProgressCount,
      });

      setStats({
        PENDING: pendingCount,
        IN_PROGRESS: inProgressCount,
        READY: readyCount,
        CANCELLED: cancelledCount,
      });

      setDeliveredToday(today || 0);
    }

    async function loadOrdersPanel(isInitial = false) {
      if (isInitial) setLoading(true);
      try {
        const [
          pendingRes,
          inProgressRes,
          readyRes,
          cancelledRes,
          todayRes,
          pendingOrdersRes,
          inProgressOrdersRes,
          readyOrdersRes,
        ] = await Promise.allSettled([
          fetchOrderCount('PENDING'),
          fetchOrderCount('IN_PROGRESS'),
          fetchOrderCount('READY'),
          fetchOrderCount('CANCELLED'),
          fetchDeliveredTodayCount(),
          fetchOrdersByStatus('PENDING', 0),
          fetchOrdersByStatus('IN_PROGRESS', 0),
          fetchOrdersByStatus('READY', 0),
        ]);

        if (!isMounted) return;

        const pendingCount = pendingRes.status === 'fulfilled' ? pendingRes.value : 0;
        const inProgressCount = inProgressRes.status === 'fulfilled' ? inProgressRes.value : 0;
        const readyCount = readyRes.status === 'fulfilled' ? readyRes.value : 0;
        const cancelledCount = cancelledRes.status === 'fulfilled' ? cancelledRes.value : 0;
        const today = todayRes.status === 'fulfilled' ? todayRes.value : 0;

        const pendingOrders = pendingOrdersRes.status === 'fulfilled' ? (pendingOrdersRes.value?.content || []) : [];
        const inProgressOrders = inProgressOrdersRes.status === 'fulfilled' ? (inProgressOrdersRes.value?.content || []) : [];
        const readyOrders = readyOrdersRes.status === 'fulfilled' ? (readyOrdersRes.value?.content || []) : [];

        setQueueStats({
          totalOrdersInQueue: pendingCount + inProgressCount,
          pendingOrders: pendingCount,
          inProgressOrders: inProgressCount,
        });
        setStats({
          PENDING: pendingCount,
          IN_PROGRESS: inProgressCount,
          READY: readyCount || 0,
          CANCELLED: cancelledCount || 0,
        });
        setSpotlightOrders([
          ...inProgressOrders.slice(0, 2),
          ...pendingOrders.slice(0, 2),
          ...readyOrders.slice(0, 2),
        ].slice(0, 6));

        setDeliveredToday(today || 0);
      } finally {
        if (isMounted && isInitial) setLoading(false);
      }
    }

    async function loadMenuPanel() {
      const [allItemsRes, instantReadyRes, budgetRes, ...categoryResults] = await Promise.allSettled([
        getItems(0),
        getInstantReadyItems(),
        getItemsByPriceRange(0, 100),
        ...MENU_CATEGORIES.map((category) => getItemsByCategory(category, 0)),
      ]);

      if (!isMounted) return;

      const categories = {};
      MENU_CATEGORIES.forEach((category, idx) => {
        const result = categoryResults[idx];
        categories[category] = result.status === 'fulfilled'
          ? (result.value?.totalElements ?? (result.value?.content || []).length)
          : 0;
      });

      setItemInsights({
        totalItems: allItemsRes.status === 'fulfilled'
          ? (allItemsRes.value?.totalElements ?? (allItemsRes.value?.content || []).length)
          : 0,
        instantReady: instantReadyRes.status === 'fulfilled' ? (instantReadyRes.value || []).length : 0,
        budgetItems: budgetRes.status === 'fulfilled' ? (budgetRes.value || []).length : 0,
        categories,
      });
    }

    loadOrdersPanel(true);
    loadMenuPanel();
    const unsubscribe = subscribeToAdminOrderEvents((payload) => {
      if (payload?.orderStatus === 'PENDING') {
        setStats((prev) => ({
          ...prev,
          PENDING: (prev.PENDING || 0) + 1,
        }));
        setQueueStats((prev) => ({
          totalOrdersInQueue: (prev?.totalOrdersInQueue || 0) + 1,
          pendingOrders: (prev?.pendingOrders || 0) + 1,
          inProgressOrders: prev?.inProgressOrders || 0,
        }));
        setSpotlightOrders((prev) => [payload, ...prev].slice(0, 6));
      }

      refreshLiveStatsOnly();
    });

    return () => {
      isMounted = false;
      unsubscribe();
    };
  }, []);

  const chartData = [
    ...PIPELINE_STATUSES.map((status) => ({
      label: STATUS_LABELS[status],
      count: stats[status] || 0,
    })),
    { label: 'Delivered Today', count: deliveredToday },
  ];

  if (loading) {
    return (
      <div className="grid gap-16 page-enter">
        <div className="stats-grid">
          {Array.from({ length: 5 }).map((_, i) => (
            <div key={i} className="stat-card skeleton-block" />
          ))}
        </div>
        <div className="card chart-skeleton">
          <LoadingSpinner label="Loading dashboard insights..." />
        </div>
      </div>
    );
  }

  return (
    <div className="grid gap-16 page-enter">
      <div className="stats-grid">
        {PIPELINE_STATUSES.map((status) => (
          <div key={status} className="stat-card">
            <h4>{STATUS_LABELS[status]}</h4>
            <strong>{stats[status] || 0}</strong>
          </div>
        ))}
        {/* Delivered Today: sourced exclusively from GET /admin/orders/delivered/count */}
        <div className="stat-card highlight">
          <h4>Delivered Today</h4>
          <strong>{deliveredToday}</strong>
        </div>
      </div>

      <div className="dashboard-grid-2">
        {queueStats && (
          <div className="card queue-stats-card">
            <div className="row between">
              <h3>Live Queue Metrics</h3>
              <Link to="/orders" className="inline-link">Open orders</Link>
            </div>
            <div className="stats-grid top-12">
              <div className="stat-card">
                <h4>Total In Queue</h4>
                <strong>{queueStats.totalOrdersInQueue || 0}</strong>
              </div>
              <div className="stat-card">
                <h4>Queue Coverage</h4>
                <strong>Pending + In Progress</strong>
              </div>
              <div className="stat-card">
                <h4>Realtime</h4>
                <strong>WebSocket</strong>
              </div>
            </div>
          </div>
        )}

        <div className="card">
          <div className="row between">
            <h3>Menu Intelligence</h3>
            <Link to="/items" className="inline-link">Open items</Link>
          </div>
          <div className="stats-grid top-12">
            <div className="stat-card">
              <h4>Total Menu Items</h4>
              <strong>{itemInsights.totalItems}</strong>
            </div>
            <div className="stat-card">
              <h4>Instant Ready Items</h4>
              <strong>{itemInsights.instantReady}</strong>
            </div>
            <div className="stat-card">
              <h4>Budget Items (₹0-₹100)</h4>
              <strong>{itemInsights.budgetItems}</strong>
            </div>
          </div>

          <div className="category-chips top-12">
            {MENU_CATEGORIES.map((category) => (
              <span key={category} className="chip">
                {category}: {itemInsights.categories?.[category] || 0}
              </span>
            ))}
          </div>
        </div>
      </div>

      <div className="card">
        <div className="row between">
          <h3>Orders Needing Attention</h3>
          <Link to="/orders" className="inline-link">Manage</Link>
        </div>
        {spotlightOrders.length === 0 ? (
          <p className="top-12">No active orders right now.</p>
        ) : (
          <div className="attention-grid top-12">
            {spotlightOrders.map((order) => (
              <div key={order.id} className="attention-card">
                <div className="row between">
                  <strong>#{order.id}</strong>
                  <StatusBadge status={order.orderStatus} />
                </div>
                <p>{order.username}</p>
                <p>₹{order.totalAmount}</p>
                <p>Prep: {order.estPrepTime || 0} min</p>
              </div>
            ))}
          </div>
        )}
      </div>

      <div className="card chart-card">
        <h3>Order Pipeline Overview</h3>
        <ResponsiveContainer width="100%" height={320}>
          <BarChart data={chartData}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="label" />
            <YAxis allowDecimals={false} />
            <Tooltip />
            <Bar dataKey="count" radius={[8, 8, 0, 0]}>
              {chartData.map((entry) => (
                <Cell key={entry.label} fill={BAR_COLORS[entry.label] || '#5b7cfa'} />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
