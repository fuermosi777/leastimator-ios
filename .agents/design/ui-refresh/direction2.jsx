// Direction 2 — "Glass Cockpit"
// Deep midnight blue with frosted glass panels. Cooler, more "premium sedan".
// Shows light + dark balance via layered translucent surfaces.

const D2 = {
  bg: '#0a1220',
  bgDeep: '#050a14',
  glass: 'rgba(255,255,255,0.05)',
  glassStroke: 'rgba(255,255,255,0.08)',
  text: '#eef2f8',
  dim: '#7d8aa0',
  dimmer: '#4a5468',
  accent: '#5de2ff', // cyan
  accentSoft: 'rgba(93,226,255,0.12)',
  warn: '#ffb545',
  danger: '#ff4d6d',
  mono: '"JetBrains Mono", "SF Mono", ui-monospace, monospace',
  sans: '"Inter", -apple-system, BlinkMacSystemFont, system-ui, sans-serif',
};

// Half-circle gauge (automotive fuel-gauge style)
function GlassGauge({ progress, projected, variance, allowed, unit = "mi" }) {
  const size = 260;
  const stroke = 16;
  const r = size / 2 - stroke - 6;
  const c = Math.PI * r; // half circumference
  const p = Math.min(Math.max(progress, 0), 1.1);
  const color = p >= 1 ? D2.danger : p >= 0.9 ? D2.warn : D2.accent;

  return (
    <div style={{ position: 'relative', width: size, height: size / 2 + 30 }}>
      <svg width={size} height={size / 2 + 30} viewBox={`0 0 ${size} ${size/2 + 30}`} style={{ overflow: 'visible' }}>
        <defs>
          <linearGradient id="d2grad" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stopColor={color} stopOpacity="0.6" />
            <stop offset="100%" stopColor={color} stopOpacity="1" />
          </linearGradient>
          <filter id="d2glow" x="-50%" y="-50%" width="200%" height="200%">
            <feGaussianBlur stdDeviation="4" />
          </filter>
        </defs>
        {/* Background track */}
        <path
          d={`M ${stroke/2 + 6} ${size/2} A ${r} ${r} 0 0 1 ${size - stroke/2 - 6} ${size/2}`}
          stroke={D2.glassStroke}
          strokeWidth={stroke}
          fill="none"
          strokeLinecap="round"
        />
        {/* Progress glow */}
        <path
          d={`M ${stroke/2 + 6} ${size/2} A ${r} ${r} 0 0 1 ${size - stroke/2 - 6} ${size/2}`}
          stroke="url(#d2grad)"
          strokeWidth={stroke}
          fill="none"
          strokeLinecap="round"
          strokeDasharray={`${c * Math.min(p, 1)} ${c}`}
          opacity="0.7"
          filter="url(#d2glow)"
        />
        {/* Progress */}
        <path
          d={`M ${stroke/2 + 6} ${size/2} A ${r} ${r} 0 0 1 ${size - stroke/2 - 6} ${size/2}`}
          stroke="url(#d2grad)"
          strokeWidth={stroke}
          fill="none"
          strokeLinecap="round"
          strokeDasharray={`${c * Math.min(p, 1)} ${c}`}
        />
        {/* Needle */}
        {(() => {
          const ang = Math.PI + Math.min(p, 1.1) * Math.PI;
          const x = size/2 + Math.cos(ang) * (r - 6);
          const y = size/2 + Math.sin(ang) * (r - 6);
          const xi = size/2 + Math.cos(ang) * 14;
          const yi = size/2 + Math.sin(ang) * 14;
          return (
            <>
              <line x1={xi} y1={yi} x2={x} y2={y}
                stroke={D2.text} strokeWidth="2.5" strokeLinecap="round" />
              <circle cx={size/2} cy={size/2} r="8" fill={D2.bgDeep} stroke={color} strokeWidth="2" />
            </>
          );
        })()}
        {/* Scale labels */}
        <text x={stroke/2 + 6} y={size/2 + 28} fill={D2.dim} fontSize="10" fontFamily={D2.mono} textAnchor="middle">0</text>
        <text x={size - stroke/2 - 6} y={size/2 + 28} fill={D2.dim} fontSize="10" fontFamily={D2.mono} textAnchor="middle">{fmt(allowed)}</text>
        <text x={size/2} y={28} fill={D2.dim} fontSize="10" fontFamily={D2.mono} textAnchor="middle">{fmt(allowed/2)}</text>
      </svg>

      {/* Under-gauge readout */}
      <div style={{
        position: 'absolute',
        bottom: -4, left: 0, right: 0,
        textAlign: 'center',
      }}>
        <div style={{
          fontSize: 10, color: D2.dim, letterSpacing: 2,
          textTransform: 'uppercase', marginBottom: 4,
          fontFamily: D2.sans,
        }}>Projected by end of lease</div>
        <div style={{
          fontSize: 44, fontWeight: 500,
          fontFamily: D2.mono,
          color: D2.text, letterSpacing: -1.5,
          lineHeight: 1,
          fontFeatureSettings: '"tnum"',
        }}>{fmt(projected)}</div>
      </div>
    </div>
  );
}

function D2Dashboard({ danger = false }) {
  const v = danger ? vehicleDanger : vehicleSample;
  const progress = (v.projected - v.starting) / v.allowed;
  const positive = v.variance < 0;

  return (
    <div style={{
      width: SCREEN_W, height: SCREEN_H,
      background: `radial-gradient(ellipse at 50% -10%, ${D2.accentSoft}, transparent 60%), linear-gradient(180deg, ${D2.bg} 0%, ${D2.bgDeep} 100%)`,
      position: 'relative',
      fontFamily: D2.sans,
      color: D2.text,
      overflow: 'hidden',
    }}>
      {/* Subtle grid pattern overlay */}
      <div style={{
        position: 'absolute', inset: 0,
        backgroundImage: `linear-gradient(${D2.glassStroke} 1px, transparent 1px), linear-gradient(90deg, ${D2.glassStroke} 1px, transparent 1px)`,
        backgroundSize: '48px 48px',
        opacity: 0.35,
        pointerEvents: 'none',
      }} />

      <StatusBar dark={true} />

      {/* Vehicle header */}
      <div style={{ padding: '4px 24px 18px', position: 'relative' }}>
        <div style={{
          display: 'flex', justifyContent: 'space-between',
          alignItems: 'flex-start',
        }}>
          <div>
            <div style={{ fontSize: 11, color: D2.dim, letterSpacing: 1.5, textTransform: 'uppercase', marginBottom: 4 }}>
              My Vehicle
            </div>
            <div style={{ fontSize: 26, fontWeight: 600, letterSpacing: -0.5 }}>{v.name}</div>
            <div style={{ fontSize: 13, color: D2.dim, marginTop: 2 }}>{v.subtitle}</div>
          </div>
          <button style={{
            width: 44, height: 44, borderRadius: 22,
            background: D2.glass,
            backdropFilter: 'blur(20px)',
            border: `1px solid ${D2.glassStroke}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
              <path d="M3 5 L8 10 L13 5" stroke={D2.text} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </button>
        </div>
      </div>

      {/* Gauge card */}
      <div style={{ padding: '0 20px', position: 'relative' }}>
        <div style={{
          background: D2.glass,
          backdropFilter: 'blur(30px)',
          border: `1px solid ${D2.glassStroke}`,
          borderRadius: 28,
          padding: '24px 20px 32px',
          position: 'relative',
          overflow: 'hidden',
        }}>
          {/* subtle radial highlight */}
          <div style={{
            position: 'absolute', top: -80, left: '50%',
            transform: 'translateX(-50%)',
            width: 300, height: 160,
            background: `radial-gradient(ellipse, ${danger ? 'rgba(255,77,109,0.18)' : 'rgba(93,226,255,0.15)'}, transparent 70%)`,
            pointerEvents: 'none',
          }} />

          {/* Coach pill */}
          <div style={{
            display: 'inline-flex', alignItems: 'center', gap: 6,
            padding: '6px 12px',
            background: positive ? 'rgba(93,226,255,0.1)' : 'rgba(255,77,109,0.12)',
            border: `1px solid ${positive ? 'rgba(93,226,255,0.25)' : 'rgba(255,77,109,0.3)'}`,
            borderRadius: 100,
            fontSize: 12, fontWeight: 500,
            color: positive ? D2.accent : D2.danger,
            marginBottom: 20,
            letterSpacing: 0.2,
          }}>
            <div style={{ width: 6, height: 6, borderRadius: 3, background: positive ? D2.accent : D2.danger }} />
            {positive ? "On track — under budget" : "Over pace — ease up"}
          </div>

          <div style={{ display: 'flex', justifyContent: 'center' }}>
            <GlassGauge
              progress={progress}
              projected={v.projected}
              variance={v.variance}
              allowed={v.allowed}
            />
          </div>

          {/* Variance chip */}
          <div style={{
            display: 'flex', justifyContent: 'center',
            marginTop: 16,
          }}>
            <div style={{
              display: 'inline-flex', alignItems: 'center', gap: 8,
              padding: '8px 14px',
              background: positive ? 'rgba(93,226,255,0.08)' : 'rgba(255,77,109,0.1)',
              borderRadius: 100,
              fontSize: 13, fontWeight: 500,
              color: positive ? D2.accent : D2.danger,
              fontFamily: D2.mono,
              fontFeatureSettings: '"tnum"',
            }}>
              {fmtSigned(v.variance)} mi
              <span style={{ color: D2.dim, fontWeight: 400, fontFamily: D2.sans }}>
                vs {fmt(v.allowed)} limit
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Stats row */}
      <div style={{
        padding: '18px 20px 0',
        display: 'grid', gridTemplateColumns: '1fr 1fr 1fr',
        gap: 10,
      }}>
        <D2Stat label="Today" value={v.maxDriveToday} unit="mi left" accent />
        <D2Stat label="Daily avg" value={v.mileagePerDay} unit="mi" />
        <D2Stat label="Months left" value={v.leaseLeft} unit="of 36" />
      </div>

      {/* Add reading CTA */}
      <div style={{
        position: 'absolute', left: 20, right: 20, bottom: 40,
      }}>
        <button style={{
          width: '100%', height: 56,
          background: `linear-gradient(180deg, ${D2.accent}, #3bb8d4)`,
          color: D2.bgDeep,
          border: 'none',
          borderRadius: 28,
          fontFamily: D2.sans,
          fontSize: 16, fontWeight: 600,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          gap: 8,
          boxShadow: `0 10px 30px rgba(93,226,255,0.3), inset 0 1px 0 rgba(255,255,255,0.3)`,
        }}>
          <svg width="18" height="18" viewBox="0 0 18 18" fill="none">
            <path d="M9 3 V15 M3 9 H15" stroke={D2.bgDeep} strokeWidth="2.5" strokeLinecap="round" />
          </svg>
          Log odometer reading
        </button>
      </div>

      <HomeIndicator dark />
    </div>
  );
}

function D2Stat({ label, value, unit, accent = false }) {
  return (
    <div style={{
      background: D2.glass,
      backdropFilter: 'blur(20px)',
      border: `1px solid ${D2.glassStroke}`,
      borderRadius: 18,
      padding: '14px 12px',
    }}>
      <div style={{
        fontSize: 10, color: D2.dim, letterSpacing: 1.3,
        textTransform: 'uppercase', marginBottom: 8,
      }}>{label}</div>
      <div style={{
        display: 'flex', alignItems: 'baseline', gap: 4,
        fontFamily: D2.mono, fontFeatureSettings: '"tnum"',
      }}>
        <div style={{
          fontSize: 22, fontWeight: 500,
          color: accent ? D2.accent : D2.text,
          letterSpacing: -0.5,
        }}>{fmt(value)}</div>
        <div style={{ fontSize: 10, color: D2.dim, letterSpacing: 0.5 }}>{unit}</div>
      </div>
    </div>
  );
}

Object.assign(window, { D2Dashboard, D2 });
