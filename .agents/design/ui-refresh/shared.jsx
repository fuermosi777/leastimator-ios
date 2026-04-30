// Shared UI atoms for all Leastimator design directions
// iPhone screen size: 393 × 852 (iPhone 15 Pro dimensions, but we render full-bleed)

const SCREEN_W = 390;
const SCREEN_H = 844;

// Shared sample vehicle data
const vehicleSample = {
  name: "Model 3",
  subtitle: "Long Range · 2023",
  startDate: "Mar 14, 2024",
  endDate: "Mar 14, 2027",
  lengthOfLease: 36, // months
  starting: 12,
  currentMileage: 18420,
  allowed: 36000,
  projected: 34180,
  variance: -1820,
  mileagePerDay: 42,
  mileagePerMonth: 1260,
  usedDays: 399,
  totalDays: 1096,
  leaseLeft: 23, // months left
  maxDriveToday: 71,
  odoShouldLessThan: 18702,
  excessMileage: 0,
  excessCharge: 0,
  fee: 0.25,
};

// "Danger" variant — over the limit
const vehicleDanger = {
  ...vehicleSample,
  currentMileage: 24980,
  projected: 41250,
  variance: 5250,
  mileagePerDay: 62,
  mileagePerMonth: 1874,
  maxDriveToday: 0,
  odoShouldLessThan: 18702,
  excessMileage: 5250,
  excessCharge: 1313,
};

// Format numbers with thousand separators
const fmt = (n) => new Intl.NumberFormat('en-US').format(Math.round(n));
const fmtSigned = (n) => (n >= 0 ? '+' : '−') + fmt(Math.abs(n));

// Status bar — iOS style
function StatusBar({ dark = true, time = "9:41" }) {
  const color = dark ? '#fff' : '#000';
  return (
    <div style={{
      height: 54,
      padding: '14px 28px 0',
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Text", system-ui',
      fontSize: 17,
      fontWeight: 600,
      color,
      position: 'relative',
      zIndex: 10,
    }}>
      <div style={{ letterSpacing: -0.2 }}>{time}</div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
        {/* signal */}
        <svg width="18" height="11" viewBox="0 0 18 11" fill="none">
          <rect x="0" y="7" width="3" height="4" rx="0.8" fill={color} />
          <rect x="5" y="5" width="3" height="6" rx="0.8" fill={color} />
          <rect x="10" y="3" width="3" height="8" rx="0.8" fill={color} />
          <rect x="15" y="0" width="3" height="11" rx="0.8" fill={color} />
        </svg>
        {/* wifi */}
        <svg width="16" height="11" viewBox="0 0 16 11" fill="none">
          <path d="M8 10.5 L6 8.5 A2.83 2.83 0 0 1 10 8.5 Z" fill={color} />
          <path d="M8 7 A5.66 5.66 0 0 0 4 8.66 L3 7.66 A7.07 7.07 0 0 1 13 7.66 L12 8.66 A5.66 5.66 0 0 0 8 7 Z" fill={color} />
          <path d="M8 3.5 A8.49 8.49 0 0 0 2 6 L1 5 A9.9 9.9 0 0 1 15 5 L14 6 A8.49 8.49 0 0 0 8 3.5 Z" fill={color} />
        </svg>
        {/* battery */}
        <svg width="27" height="12" viewBox="0 0 27 12" fill="none">
          <rect x="0.5" y="0.5" width="22" height="11" rx="2.5" stroke={color} strokeOpacity="0.4" fill="none" />
          <rect x="2" y="2" width="19" height="8" rx="1.5" fill={color} />
          <rect x="24" y="4" width="1.5" height="4" rx="0.5" fill={color} opacity="0.4" />
        </svg>
      </div>
    </div>
  );
}

// Home indicator bar
function HomeIndicator({ dark = true }) {
  return (
    <div style={{
      position: 'absolute',
      bottom: 8,
      left: '50%',
      transform: 'translateX(-50%)',
      width: 134,
      height: 5,
      borderRadius: 3,
      background: dark ? '#fff' : '#000',
    }} />
  );
}

Object.assign(window, {
  SCREEN_W, SCREEN_H,
  vehicleSample, vehicleDanger,
  fmt, fmtSigned,
  StatusBar, HomeIndicator,
});
