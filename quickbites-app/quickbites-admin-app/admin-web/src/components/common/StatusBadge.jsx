const colors = {
  PENDING: 'status pending',
  IN_PROGRESS: 'status progress',
  READY: 'status ready',
  DELIVERED: 'status delivered',
  CANCELLED: 'status cancelled',
};

export default function StatusBadge({ status }) {
  return <span className={colors[status] || 'status'}>{status}</span>;
}
