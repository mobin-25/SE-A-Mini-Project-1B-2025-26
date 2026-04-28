import { useEffect, useState } from 'react';
import { acceptOrder, fetchOrderCount, fetchOrdersByStatus, markOrderReady, rejectOrder } from '../api/admin';
import StatusBadge from '../components/common/StatusBadge';
import LoadingSpinner from '../components/common/LoadingSpinner';
import { subscribeToAdminOrderEvents } from '../lib/adminRealtime';

const statuses = ['PENDING', 'IN_PROGRESS', 'READY', 'DELIVERED', 'CANCELLED'];

export default function OrdersPage() {
  const [status, setStatus] = useState('PENDING');
  const [page, setPage] = useState(0);
  const [orders, setOrders] = useState([]);
  const [totalPages, setTotalPages] = useState(1);
  const [loading, setLoading] = useState(true);
  const [actionOrderId, setActionOrderId] = useState(null);
  const [queueStats, setQueueStats] = useState(null);

  const load = async (nextStatus = status, nextPage = page, withLoader = true) => {
    if (withLoader) setLoading(true);
    try {
      const data = await fetchOrdersByStatus(nextStatus, nextPage);
      setOrders(data.content || []);
      setPage(data.number || 0);
      setTotalPages(data.totalPages || 1);

      try {
        const [pendingCount, inProgressCount] = await Promise.all([
          fetchOrderCount('PENDING'),
          fetchOrderCount('IN_PROGRESS'),
        ]);
        setQueueStats({
          totalOrdersInQueue: (pendingCount || 0) + (inProgressCount || 0),
          pendingOrders: pendingCount || 0,
          inProgressOrders: inProgressCount || 0,
        });
      } catch {
        setQueueStats(null);
      }
    } finally {
      if (withLoader) setLoading(false);
    }
  };

  useEffect(() => {
    load(status, 0, true);
  }, [status]);

  useEffect(() => {
    const unsubscribe = subscribeToAdminOrderEvents(() => {
      load(status, page, false);
    });

    return () => {
      unsubscribe();
    };
  }, [status, page]);

  const action = async (handler, orderId) => {
    setActionOrderId(orderId);
    try {
      await handler(orderId);
      await load(status, page);
    } finally {
      setActionOrderId(null);
    }
  };

  return (
    <div className="card page-enter">
      <div className="row between">
        <h3>Order Management</h3>
        <select value={status} onChange={(e) => setStatus(e.target.value)}>
          {statuses.map((s) => (
            <option key={s} value={s}>{s}</option>
          ))}
        </select>
      </div>

      {loading && <LoadingSpinner label="Loading orders..." />}

      {(status === 'PENDING' || status === 'IN_PROGRESS') && queueStats && (
        <div className="queue-info-banner">
          <strong>Queue:</strong> {queueStats.totalOrdersInQueue || 0} orders •
          {' '}Pending: {queueStats.pendingOrders || 0} •
          {' '}In Progress: {queueStats.inProgressOrders || 0} •
          {' '}Est. Wait: {queueStats.estimatedWaitTime || 0} min
        </div>
      )}

      <div className="orders-grid">
        {orders.map((order) => (
          <div key={order.id} className="order-card">
            <div className="row between">
              <h4>#{order.id} • {order.username}</h4>
              <StatusBadge status={order.orderStatus} />
            </div>
            <p><strong>Total:</strong> ₹{order.totalAmount}</p>
            <p><strong>Created:</strong> {order.createdAt ? new Date(order.createdAt).toLocaleString() : '-'}</p>
            <p><strong>Token:</strong> {order.orderToken || '-'}</p>

            <div className="order-items">
              {(order.orderItems || []).map((it, idx) => (
                <div key={idx} className="row between">
                  <span>{it.menuItem?.itemName} × {it.quantity}</span>
                  <span>₹{it.historicalPrice}</span>
                </div>
              ))}
            </div>

            <div className="row gap-8 top-12">
              {order.orderStatus === 'PENDING' && (
                <>
                  <button onClick={() => action(acceptOrder, order.id)} disabled={actionOrderId === order.id}>
                    {actionOrderId === order.id ? <span className="btn-inline-loader"><span className="spinner sm" />Updating...</span> : 'Accept'}
                  </button>
                  <button className="danger" onClick={() => action(rejectOrder, order.id)} disabled={actionOrderId === order.id}>
                    {actionOrderId === order.id ? <span className="btn-inline-loader"><span className="spinner sm" />Updating...</span> : 'Reject'}
                  </button>
                </>
              )}
              {order.orderStatus === 'IN_PROGRESS' && (
                <button onClick={() => action(markOrderReady, order.id)} disabled={actionOrderId === order.id}>
                  {actionOrderId === order.id ? <span className="btn-inline-loader"><span className="spinner sm" />Updating...</span> : 'Mark Ready'}
                </button>
              )}
            </div>
          </div>
        ))}
      </div>

      <div className="row between top-12">
        <button disabled={page <= 0} onClick={() => load(status, page - 1, true)}>Previous</button>
        <span>Page {page + 1} / {Math.max(totalPages, 1)}</span>
        <button disabled={page >= totalPages - 1} onClick={() => load(status, page + 1, true)}>Next</button>
      </div>
    </div>
  );
}
