// iOS chrome: StatusBar, HomeIndicator, NavBar, generic atoms.

function StatusBar({ theme, time = "9:41" }) {
  const dark = theme.bg === '#060607';
  const color = dark ? '#fff' : '#000';
  return (
    <div style={{
      height: 54,
      padding: '14px 28px 0',
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      fontFamily: SANS,
      fontSize: 17, fontWeight: 600, color,
      position: 'relative', zIndex: 10,
      flexShrink: 0,
    }}>
      <div style={{ letterSpacing: -0.2 }}>{time}</div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
        <svg width="18" height="11" viewBox="0 0 18 11" fill="none">
          <rect x="0" y="7" width="3" height="4" rx="0.8" fill={color} />
          <rect x="5" y="5" width="3" height="6" rx="0.8" fill={color} />
          <rect x="10" y="3" width="3" height="8" rx="0.8" fill={color} />
          <rect x="15" y="0" width="3" height="11" rx="0.8" fill={color} />
        </svg>
        <svg width="16" height="11" viewBox="0 0 16 11" fill="none">
          <path d="M8 10.5 L6 8.5 A2.83 2.83 0 0 1 10 8.5 Z" fill={color} />
          <path d="M8 7 A5.66 5.66 0 0 0 4 8.66 L3 7.66 A7.07 7.07 0 0 1 13 7.66 L12 8.66 A5.66 5.66 0 0 0 8 7 Z" fill={color} />
          <path d="M8 3.5 A8.49 8.49 0 0 0 2 6 L1 5 A9.9 9.9 0 0 1 15 5 L14 6 A8.49 8.49 0 0 0 8 3.5 Z" fill={color} />
        </svg>
        <svg width="27" height="12" viewBox="0 0 27 12" fill="none">
          <rect x="0.5" y="0.5" width="22" height="11" rx="2.5" stroke={color} strokeOpacity="0.4" fill="none" />
          <rect x="2" y="2" width="19" height="8" rx="1.5" fill={color} />
          <rect x="24" y="4" width="1.5" height="4" rx="0.5" fill={color} opacity="0.4" />
        </svg>
      </div>
    </div>
  );
}

function HomeIndicator({ theme }) {
  const dark = theme.bg === '#060607';
  return (
    <div style={{
      position: 'absolute',
      bottom: 8, left: '50%',
      transform: 'translateX(-50%)',
      width: 134, height: 5, borderRadius: 3,
      background: dark ? '#fff' : '#000',
      zIndex: 20,
    }} />
  );
}

function NavBar({ theme, title, onBack, right }) {
  return (
    <div style={{
      height: 48,
      padding: '0 16px',
      display: 'flex', alignItems: 'center',
      justifyContent: 'space-between',
      flexShrink: 0,
    }}>
      <button onClick={onBack} style={{
        width: 36, height: 36, borderRadius: 18,
        background: theme.panel,
        border: `1px solid ${theme.hairline}`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        cursor: 'pointer',
      }}>
        <svg width="14" height="14" viewBox="0 0 14 14">
          <path d="M9 2 L4 7 L9 12" stroke={theme.text} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" fill="none" />
        </svg>
      </button>
      <div style={{ fontSize: 16, fontWeight: 600, color: theme.text }}>{title}</div>
      <div style={{ width: 36, height: 36, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{right}</div>
    </div>
  );
}

// Icon pack (inline SVGs)
function Icon({ name, size = 18, color = 'currentColor', stroke = 1.8 }) {
  const sw = stroke;
  const props = { width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: color, strokeWidth: sw, strokeLinecap: 'round', strokeLinejoin: 'round' };
  switch (name) {
    case 'plus':     return <svg {...props}><path d="M12 5v14M5 12h14"/></svg>;
    case 'chart':    return <svg {...props}><path d="M3 3v18h18"/><path d="M7 14l4-4 3 3 5-6"/></svg>;
    case 'settings': return <svg {...props}><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>;
    case 'car':      return <svg {...props}><path d="M14 16H9m10 0h1a1 1 0 0 0 1-1v-3.34a2 2 0 0 0-.26-.99L19 7.56A2 2 0 0 0 17.25 6.5H6.75A2 2 0 0 0 5 7.56L2.26 10.67a2 2 0 0 0-.26.99V15a1 1 0 0 0 1 1h1"/><circle cx="6.5" cy="16.5" r="1.5"/><circle cx="17.5" cy="16.5" r="1.5"/></svg>;
    case 'calendar': return <svg {...props}><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4M8 2v4M3 10h18"/></svg>;
    case 'check':    return <svg {...props}><path d="M4 12l5 5L20 6"/></svg>;
    case 'close':    return <svg {...props}><path d="M6 6l12 12M18 6L6 18"/></svg>;
    case 'chev-r':   return <svg {...props}><path d="M9 6l6 6-6 6"/></svg>;
    case 'chev-d':   return <svg {...props}><path d="M6 9l6 6 6-6"/></svg>;
    case 'info':     return <svg {...props}><circle cx="12" cy="12" r="10"/><path d="M12 16v-4M12 8h.01"/></svg>;
    case 'edit':     return <svg {...props}><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.12 2.12 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>;
    case 'history':  return <svg {...props}><path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5"/><path d="M12 7v5l4 2"/></svg>;
    case 'alert':    return <svg {...props}><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><path d="M12 9v4M12 17h.01"/></svg>;
    case 'bolt':     return <svg {...props}><path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"/></svg>;
    case 'trend-up': return <svg {...props}><path d="M23 6l-9.5 9.5-5-5L1 18"/><path d="M17 6h6v6"/></svg>;
    case 'sun':      return <svg {...props}><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M4.93 19.07l1.41-1.41M17.66 6.34l1.41-1.41"/></svg>;
    case 'moon':     return <svg {...props}><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>;
    default: return null;
  }
}

Object.assign(window, { StatusBar, HomeIndicator, NavBar, Icon });
