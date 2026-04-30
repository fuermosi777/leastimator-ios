// Direction 3 — "Editorial"
// Pure typography-led. High contrast, monochrome with single accent.
// Think magazine / financial terminal crossed with Braun.
// Off-white warm bg, no glass, no gradients. Data is the design.

const D3 = {
  bg: '#f2efe8',           // warm off-white
  panel: '#ffffff',
  ink: '#1a1816',
  rule: '#1a1816',
  dim: '#8a8478',
  accent: '#d93a2b',       // editorial red
  positive: '#1a8050',
  serif: '"GT Sectra", "Source Serif Pro", Georgia, serif',
  mono: '"JetBrains Mono", "SF Mono", ui-monospace, monospace',
  sans: '"Inter", -apple-system, system-ui, sans-serif',
};

function EditorialRing({ progress, size = 240 }) {
  const stroke = 3;
  const r = size / 2 - stroke;
  const c = 2 * Math.PI * r;
  const p = Math.min(progress, 1.1);
  const color = p >= 1 ? D3.accent : D3.ink;

  // tick marks at every 10%
  const ticks = [];
  for (let i = 0; i <= 10; i++) {
    const ang = -Math.PI / 2 + (i / 10) * 2 * Math.PI;
    const r1 = r + 6;
    const r2 = r + (i % 5 === 0 ? 16 : 10);
    ticks.push(
      <line key={i}
        x1={size/2 + Math.cos(ang) * r1}
        y1={size/2 + Math.sin(ang) * r1}
        x2={size/2 + Math.cos(ang) * r2}
        y2={size/2 + Math.sin(ang) * r2}
        stroke={D3.ink}
        strokeWidth={i % 5 === 0 ? 1.5 : 0.8}
      />
    );
  }

  return (
    <svg width={size + 40} height={size + 40} viewBox={`${-20} ${-20} ${size + 40} ${size + 40}`}>
      {ticks}
      <circle cx={size/2} cy={size/2} r={r}
        stroke={D3.ink}
        strokeOpacity="0.15"
        strokeWidth={stroke}
        fill="none" />
      <circle cx={size/2} cy={size/2} r={r}
        stroke={color}
        strokeWidth={stroke}
        fill="none"
        strokeDasharray={`${c * Math.min(p, 1)} ${c}`}
        transform={`rotate(-90 ${size/2} ${size/2})`}
        strokeLinecap="butt" />
      {/* End-of-progress tick marker */}
      {(() => {
        const ang = -Math.PI / 2 + Math.min(p, 1) * 2 * Math.PI;
        const x = size/2 + Math.cos(ang) * r;
        const y = size/2 + Math.sin(ang) * r;
        return <circle cx={x} cy={y} r="5" fill={color} />;
      })()}
    </svg>
  );
}

function D3Dashboard({ danger = false }) {
  const v = danger ? vehicleDanger : vehicleSample;
  const progress = (v.projected - v.starting) / v.allowed;
  const positive = v.variance < 0;

  return (
    <div style={{
      width: SCREEN_W, height: SCREEN_H,
      background: D3.bg,
      position: 'relative',
      fontFamily: D3.sans,
      color: D3.ink,
      overflow: 'hidden',
    }}>
      <StatusBar dark={false} />

      {/* Masthead */}
      <div style={{
        padding: '8px 22px 14px',
        display: 'flex', justifyContent: 'space-between', alignItems: 'baseline',
        borderBottom: `1px solid ${D3.ink}`,
      }}>
        <div style={{
          fontFamily: D3.serif,
          fontSize: 26, fontWeight: 500,
          letterSpacing: -0.5,
          fontStyle: 'italic',
        }}>
          Leastimator
        </div>
        <div style={{
          fontSize: 10, letterSpacing: 1.8,
          textTransform: 'uppercase', color: D3.dim,
          fontFamily: D3.mono,
        }}>
          Vol. 23 · Apr 17
        </div>
      </div>

      {/* Headline block */}
      <div style={{ padding: '20px 22px 0' }}>
        <div style={{
          fontSize: 10, letterSpacing: 2,
          textTransform: 'uppercase', color: D3.dim,
          fontFamily: D3.mono, marginBottom: 8,
        }}>
          {v.name} · {v.subtitle}
        </div>
        <div style={{
          fontFamily: D3.serif,
          fontSize: 34, fontWeight: 400,
          letterSpacing: -1, lineHeight: 1.05,
          marginBottom: 6,
        }}>
          {positive ? (
            <>You're driving <em style={{ color: D3.positive, fontStyle: 'italic' }}>under pace.</em></>
          ) : (
            <>You're driving <em style={{ color: D3.accent, fontStyle: 'italic' }}>above pace.</em></>
          )}
        </div>
        <div style={{
          fontSize: 14, color: D3.dim, lineHeight: 1.4,
          maxWidth: 300,
        }}>
          At today's rate, you'll finish {fmt(Math.abs(v.variance))} miles {positive ? 'under' : 'over'} your {fmt(v.allowed)} mi allowance.
        </div>
      </div>

      {/* Hero figure + ring */}
      <div style={{
        padding: '16px 22px 0',
        display: 'flex', alignItems: 'center', gap: 20,
      }}>
        <div style={{ position: 'relative', flexShrink: 0 }}>
          <EditorialRing progress={progress} size={150} />
          <div style={{
            position: 'absolute', inset: 0,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            flexDirection: 'column',
          }}>
            <div style={{
              fontFamily: D3.mono, fontSize: 28, fontWeight: 500,
              letterSpacing: -1, fontFeatureSettings: '"tnum"',
            }}>{Math.round(progress * 100)}%</div>
            <div style={{ fontSize: 9, color: D3.dim, letterSpacing: 1.5, textTransform: 'uppercase' }}>used</div>
          </div>
        </div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 10, color: D3.dim, letterSpacing: 1.5, textTransform: 'uppercase', marginBottom: 4 }}>
            Projected total
          </div>
          <div style={{
            fontFamily: D3.serif,
            fontSize: 44, fontWeight: 500,
            letterSpacing: -2, lineHeight: 1,
            fontFeatureSettings: '"tnum"',
          }}>{fmt(v.projected)}</div>
          <div style={{ fontSize: 11, color: D3.dim, marginTop: 2, fontFamily: D3.mono }}>mi · by Mar 2027</div>
          <div style={{
            marginTop: 10,
            fontFamily: D3.mono, fontSize: 13,
            color: positive ? D3.positive : D3.accent,
            fontWeight: 500,
            fontFeatureSettings: '"tnum"',
          }}>
            {fmtSigned(v.variance)} mi
          </div>
        </div>
      </div>

      {/* Data table */}
      <div style={{ padding: '24px 22px 0' }}>
        <div style={{
          fontSize: 10, letterSpacing: 2,
          textTransform: 'uppercase', color: D3.dim,
          fontFamily: D3.mono,
          paddingBottom: 8,
          borderBottom: `1px solid ${D3.ink}`,
          marginBottom: 0,
        }}>Summary</div>
        <TableRow label="Current odometer" value={fmt(v.currentMileage)} unit="mi" />
        <TableRow label="Daily average" value={fmt(v.mileagePerDay)} unit="mi/day" />
        <TableRow label="Monthly average" value={fmt(v.mileagePerMonth)} unit="mi/mo" />
        <TableRow label="Today's target" value={fmt(v.maxDriveToday)} unit="mi left" />
        <TableRow label="Lease remaining" value={v.leaseLeft} unit="months" last />
      </div>

      {/* Add reading */}
      <div style={{
        position: 'absolute', left: 22, right: 22, bottom: 36,
        display: 'flex', gap: 8,
      }}>
        <button style={{
          flex: 1, height: 52,
          background: D3.ink,
          color: D3.bg,
          border: 'none',
          borderRadius: 0,
          fontFamily: D3.sans,
          fontSize: 14, fontWeight: 600,
          letterSpacing: 1,
          textTransform: 'uppercase',
        }}>
          Log Reading →
        </button>
        <button style={{
          width: 52, height: 52,
          background: 'transparent',
          color: D3.ink,
          border: `1px solid ${D3.ink}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
            <path d="M2 12 L6 8 L10 10 L14 4" stroke={D3.ink} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </button>
      </div>

      <HomeIndicator dark={false} />
    </div>
  );
}

function TableRow({ label, value, unit, last = false }) {
  return (
    <div style={{
      display: 'flex', justifyContent: 'space-between',
      alignItems: 'baseline',
      padding: '12px 0',
      borderBottom: last ? 'none' : `1px solid rgba(26,24,22,0.12)`,
    }}>
      <div style={{ fontSize: 14, color: D3.ink }}>{label}</div>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
        <div style={{
          fontFamily: D3.mono, fontSize: 16, fontWeight: 500,
          letterSpacing: -0.3, fontFeatureSettings: '"tnum"',
        }}>{value}</div>
        <div style={{ fontSize: 10, color: D3.dim, letterSpacing: 0.5, minWidth: 40, textAlign: 'right' }}>{unit}</div>
      </div>
    </div>
  );
}

Object.assign(window, { D3Dashboard, D3 });
