import { useState } from 'react';
import { deliverOrder } from '../api/admin';

export default function ClaimOrderPage() {
  const [orderToken, setOrderToken] = useState('');
  const [result, setResult] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const onSubmit = async (e) => {
    e.preventDefault();
    setResult('');
    setError('');
    setLoading(true);

    try {
      const res = await deliverOrder(orderToken);
      setResult(typeof res === 'string' ? res : 'Order delivered successfully');
      setOrderToken('');
    } catch (err) {
      setError(err?.response?.data?.message || err?.response?.data || 'Unable to claim order');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="card narrow page-enter">
      <h3>Verify & Claim Order</h3>
      <p>Enter token from QR flow to mark order DELIVERED.</p>
      <form onSubmit={onSubmit} className="grid-form">
        <input
          placeholder="Order Token"
          value={orderToken}
          onChange={(e) => setOrderToken(e.target.value)}
          required
        />
        <button type="submit" disabled={loading}>
          {loading ? <span className="btn-inline-loader"><span className="spinner sm" />Claiming...</span> : 'Claim Order'}
        </button>
      </form>
      {result && <div className="success-msg">{result}</div>}
      {error && <div className="error-msg">{error}</div>}
    </div>
  );
}
