import { useEffect, useMemo, useState } from 'react';
import {
  createItem,
  deleteItem,
  deleteItemsBulk,
  getItems,
  getItemsByCategory,
  toggleItemAvailability,
} from '../api/admin';
import LoadingSpinner from '../components/common/LoadingSpinner';

const categories = ['ALL', 'VEG', 'BEVERAGE', 'SNACK', 'BREAKFAST'];

export default function ItemsPage() {
  const [items, setItems] = useState([]);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [category, setCategory] = useState('ALL');
  const [selected, setSelected] = useState([]);
  const [form, setForm] = useState({ itemName: '', price: '', category: 'VEG', itemImage: null, readyIn: 0 });
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);

  const selectedSet = useMemo(() => new Set(selected), [selected]);

  const load = async (nextPage = page, nextCategory = category) => {
    setLoading(true);
    try {
      const pageData =
        nextCategory === 'ALL'
          ? await getItems(nextPage)
          : await getItemsByCategory(nextCategory, nextPage);
      setItems(pageData.content || []);
      setTotalPages(pageData.totalPages || 1);
      setPage(pageData.number || 0);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load(0, category);
  }, [category]);

  const submitItem = async (e) => {
    e.preventDefault();
    const fd = new FormData();
    fd.append('itemName', form.itemName);
    fd.append('price', form.price);
    fd.append('category', form.category);
    fd.append('itemImage', form.itemImage);
    fd.append('isAvailable', 'true');
    fd.append('readyIn', form.readyIn);

    setSubmitting(true);
    try {
      await createItem(fd);
      setForm({ itemName: '', price: '', category: 'VEG', itemImage: null, readyIn: 0 });
      setMessage('Item created successfully');
      await load(0, category);
    } finally {
      setSubmitting(false);
    }
  };

  const toggleSelect = (id) => {
    setSelected((prev) => (prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]));
  };

  const handleDelete = async (id) => {
    setActionLoading(true);
    try {
      await deleteItem(id);
      await load(page, category);
    } finally {
      setActionLoading(false);
    }
  };

  const handleBulkDelete = async () => {
    if (!selected.length) return;
    setActionLoading(true);
    try {
      await deleteItemsBulk(selected);
      setSelected([]);
      await load(page, category);
    } finally {
      setActionLoading(false);
    }
  };

  const handleToggleAvailability = async (id) => {
    setActionLoading(true);
    try {
      await toggleItemAvailability(id);
      await load(page, category);
    } finally {
      setActionLoading(false);
    }
  };

  return (
    <div className="grid gap-16 page-enter">
      <div className="card">
        <h3>Add New Item</h3>
        <form className="grid-form" onSubmit={submitItem}>
          <input
            placeholder="Item name"
            value={form.itemName}
            onChange={(e) => setForm((s) => ({ ...s, itemName: e.target.value }))}
            required
          />
          <input
            type="number"
            min="1"
            placeholder="Price"
            value={form.price}
            onChange={(e) => setForm((s) => ({ ...s, price: e.target.value }))}
            required
          />
          <select value={form.category} onChange={(e) => setForm((s) => ({ ...s, category: e.target.value }))}>
            {categories.filter((c) => c !== 'ALL').map((c) => (
              <option key={c} value={c}>{c}</option>
            ))}
          </select>
          <div className="ready-in-field">
            <label>Ready In (min)</label>
            <input
              type="number"
              min="0"
              placeholder="Prep time (0 = instant)"
              value={form.readyIn}
              onChange={(e) => setForm((s) => ({ ...s, readyIn: parseInt(e.target.value) || 0 }))}
            />
          </div>
          <input
            type="file"
            accept="image/*"
            onChange={(e) => setForm((s) => ({ ...s, itemImage: e.target.files?.[0] || null }))}
            required
          />
          <button type="submit" disabled={submitting}>
            {submitting ? <span className="btn-inline-loader"><span className="spinner sm" />Saving...</span> : 'Save Item'}
          </button>
        </form>
        {message && <p className="success-msg">{message}</p>}
      </div>

      <div className="card">
        <div className="row between">
          <h3>Manage Menu</h3>
          <div className="row gap-8">
            <select value={category} onChange={(e) => setCategory(e.target.value)}>
              {categories.map((c) => (
                <option key={c} value={c}>{c}</option>
              ))}
            </select>
            <button className="danger" onClick={handleBulkDelete} disabled={actionLoading || loading}>
              {actionLoading ? <span className="btn-inline-loader"><span className="spinner sm" />Working...</span> : 'Delete Selected'}
            </button>
          </div>
        </div>

        {(loading || actionLoading) && (
          <div className="table-loader">
            <LoadingSpinner label="Updating items..." />
          </div>
        )}

        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th></th>
                <th>Image</th>
                <th>Name</th>
                <th>Category</th>
                <th>Price</th>
                <th>Ready In (min)</th>
                <th>Availability</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {items.map((item) => (
                <tr key={item.itemId}>
                  <td>
                    <input
                      type="checkbox"
                      checked={selectedSet.has(item.itemId)}
                      onChange={() => toggleSelect(item.itemId)}
                    />
                  </td>
                  <td><img src={item.imageUrl} alt={item.itemName} className="thumb" /></td>
                  <td>{item.itemName}</td>
                  <td>{item.category}</td>
                  <td>₹{item.price}</td>
                  <td>{item.readyIn === 0 ? <span className="chip" style={{background:'#d5f9e1',color:'#136f3f',borderColor:'#b0f0c6'}}>Instant</span> : `${item.readyIn} min`}</td>
                  <td>{item.available ? 'Available' : item.isAvailable ? 'Available' : 'Unavailable'}</td>
                  <td className="row gap-8">
                    <button onClick={() => handleToggleAvailability(item.itemId)} disabled={actionLoading}>Toggle</button>
                    <button className="danger" onClick={() => handleDelete(item.itemId)} disabled={actionLoading}>Delete</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <div className="row between top-12">
          <button disabled={page <= 0} onClick={() => load(page - 1, category)}>Previous</button>
          <span>Page {page + 1} / {Math.max(totalPages, 1)}</span>
          <button disabled={page >= totalPages - 1} onClick={() => load(page + 1, category)}>Next</button>
        </div>
      </div>
    </div>
  );
}
