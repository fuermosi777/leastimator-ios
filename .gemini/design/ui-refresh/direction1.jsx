// Direction 1 — "Instrument Cluster"
// Pure black OLED feel. Giant circular gauge like a speedometer.
// Tick marks, glow, monospace numerals.
// Palette: electric cyan-lime accent on near-black.

const D1 = {
  bg: '#060607',
  panel: '#0f0f11',
  hairline: 'rgba(255,255,255,0.07)',
  text: '#f4f4f6',
  dim: '#6b6b74',
  accent: '#c6ff3a', // electric lime
  accentDim: 'rgba(198,255,58,0.18)',
  warn: '#ffb545',
  danger: '#ff3a5e',
  mono: '"JetBrains Mono", "SF Mono", ui-monospace, monospace',
  sans: '"Inter", -apple-system, BlinkMacSystemFont, system-ui, sans-serif',
};

// Full circular gauge with tick marks
function GaugeCluster({ progress, projected, variance, allowed, unit = "mi" }) {
  const size = 288;
  const stroke = 14;
  const r = (size - stroke) / 2 - 12;
  const c = 2 * Math.PI * r;
  const p = Math.min(Math.max(progress, 0), 1.15);
  const color = p >= 1 ? D1.danger : p >= 0.9 ? D1.warn : D1.accent;
  const arc = 0.78; // how much of the circle is used (sweep angle)
  const startAngle = (1 - arc) / 2 * 360 + 90;
  const sweepLen = c * arc;

  // Tick marks
  const ticks = [];
  const tickCount = 40;
  for (let i = 0; i <= tickCount; i++) {
    const t = i / tickCount;
    const ang = startAngle + t * arc * 360;
    const rad = (ang * Math.PI) / 180;
    const isMajor = i % 5 === 0;
    const innerR = r + (isMajor ? 14 : 18);
    const outerR = r + 24;
    const x1 = size / 2 + Math.cos(rad) * innerR;
    const y1 = size / 2 + Math.sin(rad) * innerR;
    const x2 = size / 2 + Math.cos(rad) * outerR;
    const y2 = size / 2 + Math.sin(rad) * outerR;
    const filled = t <= p / 1.15;
    ticks.push(
      <line key={i} x1={x1} y1={y1} x2={x2} y2={y2}
        stroke={filled ? color : D1.dim}
        strokeOpacity={filled ? 1 : 0.35}
        strokeWidth={isMajor ? 2 : 1}
        strokeLinecap="round" />
    );
  }

  return (
    <div style={{ position: 'relative', width: size, height: size }}>
      <svg width={size} height={size} style={{ position: 'absolute', inset: 0, overflow: 'visible' }}>
        <defs>
          <filter id="d1glow" x="-40%" y="-40%" width="180%" height="180%">
            <feGaussianBlur stdDeviation="6" />
          </filter>
        </defs>
        {/* Tick marks */}
        <g>{ticks}</g>
        {/* Background arc */}
        <circle cx={size/2} cy={size/2} r={r}
          stroke={D1.hairline}
          strokeWidth={stroke}
          fill="none"
          strokeDasharray={`${sweepLen} ${c}`}
          strokeDashoffset={-c * (1 - arc) / 2}
          transform={`rotate(90 ${size/2} ${size/2})`}
          strokeLinecap="round" />
        {/* Glow under progress */}
        <circle cx={size/2} cy={size/2} r={r}
          stroke={color}
          strokeWidth={stroke}
          fill="none"
          strokeDasharray={`${sweepLen * Math.min(p, 1)} ${c}`}
          strokeDashoffset={-c * (1 - arc) / 2}
          transform={`rotate(90 ${size/2} ${size/2})`}
          strokeLinecap="round"
          opacity="0.6"
          filter="url(#d1glow)" />
        {/* Progress */}
        <circle cx={size/2} cy={size/2} r={r}
          stroke={color}
          strokeWidth={stroke}
          fill="none"
          strokeDasharray={`${sweepLen * Math.min(p, 1)} ${c}`}
          strokeDashoffset={-c * (1 - arc) / 2}
          transform={`rotate(90 ${size/2} ${size/2})`}
          strokeLinecap="round" />
      </svg>

      {/* Center readout */}
      <div style={{
        position: 'absolute', inset: 0,
        display: 'flex', flexDirection: 'column',
        alignItems: 'center', justifyContent: 'center',
        fontFamily: D1.mono,
      }}>
        <div style={{
          fontSize: 10, color: D1.dim, letterSpacing: 2,
          textTransform: 'uppercase', marginBottom: 10,
        }}>Projected</div>
        <div style={{
          fontSize: 54, fontWeight: 500, color: D1.text,
          letterSpacing: -2, lineHeight: 1,
          fontFeatureSettings: '"tnum"',
        }}>{fmt(projected)}</div>
        <div style={{
          fontSize: 11, color: D1.dim, marginTop: 6,
          letterSpacing: 1.5,
        }}>{unit.toUpperCase()} · BY LEASE END</div>
        <div style={{
          marginTop: 18, padding: '6px 12px',
          background: variance < 0 ? D1.accentDim : 'rgba(255,58,94,0.15)',
          borderRadius: 20,
          fontSize: 12, fontWeight: 500,
          color: variance < 0 ? D1.accent : D1.danger,
          letterSpacing: 0.5,
          fontFeatureSettings: '"tnum"',
        }}>
          {fmtSigned(variance)} {unit} vs limit
        </div>
      </div>
    </div>
  );
}

function D1Dashboard({ danger = false }) {
  const v = danger ? vehicleDanger : vehicleSample;
  const progress = (v.projected - v.starting) / v.allowed;

  return (
    <div style={{
      width: SCREEN_W, height: SCREEN_H,
      background: D1.bg,
      position: 'relative',
      fontFamily: D1.sans,
      color: D1.text,
      overflow: 'hidden',
    }}>
      <StatusBar dark={true} />

      {/* Top bar: vehicle switcher + menu */}
      <div style={{
        padding: '6px 20px 20px',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
      }}>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 10,
          padding: '8px 14px 8px 10px',
          background: D1.panel,
          border: `1px solid ${D1.hairline}`,
          borderRadius: 100,
        }}>
          <div style={{
            width: 22, height: 22, borderRadius: 11,
            background: D1.accent,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontFamily: D1.mono, fontSize: 10, fontWeight: 700,
            color: D1.bg,
          }}>M3</div>
          <div style={{ fontSize: 14, fontWeight: 500 }}>{v.name}</div>
          <svg width="10" height="10" viewBox="0 0 10 10" fill="none">
            <path d="M2 3.5 L5 6.5 L8 3.5" stroke={D1.dim} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </div>
        <button style={{
          width: 40, height: 40, borderRadius: 20,
          background: D1.panel,
          border: `1px solid ${D1.hairline}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
            <circle cx="8" cy="3" r="1.3" fill={D1.text} />
            <circle cx="8" cy="8" r="1.3" fill={D1.text} />
            <circle cx="8" cy="13" r="1.3" fill={D1.text} />
          </svg>
        </button>
      </div>

      {/* Coach message */}
      <div style={{
        padding: '0 24px 8px',
        display: 'flex', alignItems: 'center', gap: 8,
      }}>
        <div style={{
          width: 6, height: 6, borderRadius: 3,
          background: danger ? D1.danger : D1.accent,
          boxShadow: `0 0 10px ${danger ? D1.danger : D1.accent}`,
        }} />
        <div style={{ fontSize: 13, color: D1.dim, letterSpacing: 0.2 }}>
          {danger ? "Heads up — you're over pace" : "Nice pace. You're on track."}
        </div>
      </div>

      {/* Big gauge */}
      <div style={{
        display: 'flex', justifyContent: 'center',
        padding: '24px 0 16px',
      }}>
        <GaugeCluster
          progress={progress}
          projected={v.projected}
          variance={v.variance}
          allowed={v.allowed}
        />
      </div>

      {/* Primary stats — big monospace numerals */}
      <div style={{ padding: '20px 24px 0' }}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 1, background: D1.hairline, border: `1px solid ${D1.hairline}`, borderRadius: 18, overflow: 'hidden' }}>
          <StatCell label="DAILY AVG" value={v.mileagePerDay} unit="mi" />
          <StatCell label="ODOMETER" value={v.currentMileage} unit="mi" small />
          <StatCell label="LEASE LEFT" value={v.leaseLeft} unit="mo" />
        </div>
      </div>

      {/* Add Reading FAB */}
      <div style={{
        position: 'absolute',
        left: 24, right: 24, bottom: 40,
        display: 'flex', gap: 12,
      }}>
        <button style={{
          flex: 1, height: 56,
          background: D1.accent,
          color: D1.bg,
          border: 'none',
          borderRadius: 28,
          fontFamily: D1.sans,
          fontSize: 16, fontWeight: 600,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          gap: 8,
          boxShadow: `0 0 40px ${D1.accentDim}`,
        }}>
          <svg width="18" height="18" viewBox="0 0 18 18" fill="none">
            <path d="M9 3 V15 M3 9 H15" stroke={D1.bg} strokeWidth="2.5" strokeLinecap="round" />
          </svg>
          Add Reading
        </button>
        <button style={{
          width: 56, height: 56,
          background: D1.panel,
          border: `1px solid ${D1.hairline}`,
          borderRadius: 28,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="18" height="18" viewBox="0 0 18 18" fill="none">
            <rect x="2" y="10" width="3" height="6" rx="0.5" fill={D1.text} />
            <rect x="7.5" y="5" width="3" height="11" rx="0.5" fill={D1.text} />
            <rect x="13" y="2" width="3" height="14" rx="0.5" fill={D1.text} />
          </svg>
        </button>
      </div>

      <HomeIndicator dark />
    </div>
  );
}

function StatCell({ label, value, unit, small = false }) {
  return (
    <div style={{
      background: D1.bg,
      padding: '16px 14px',
      display: 'flex', flexDirection: 'column',
      gap: 8,
    }}>
      <div style={{
        fontSize: 9, letterSpacing: 1.3,
        color: D1.dim,
        fontFamily: D1.sans,
        fontWeight: 500,
      }}>{label}</div>
      <div style={{
        display: 'flex', alignItems: 'baseline', gap: 3,
        fontFamily: D1.mono,
        fontFeatureSettings: '"tnum"',
      }}>
        <div style={{
          fontSize: small ? 20 : 24,
          fontWeight: 500,
          color: D1.text,
          letterSpacing: -0.5,
        }}>{fmt(value)}</div>
        <div style={{ fontSize: 10, color: D1.dim, letterSpacing: 1 }}>{unit}</div>
      </div>
    </div>
  );
}

Object.assign(window, { D1Dashboard, D1 });
