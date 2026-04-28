export default function LoadingSpinner({ label = 'Loading...', fullScreen = false, size = 'md' }) {
  return (
    <div className={fullScreen ? 'loading-wrap full-screen' : 'loading-wrap'}>
      <span className={`spinner ${size}`} aria-hidden="true" />
      <span>{label}</span>
    </div>
  );
}
