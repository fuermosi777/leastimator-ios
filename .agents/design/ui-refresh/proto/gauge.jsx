// The hero gauge — 3 variants (circular / segmented / bar)

function GaugeCircular({ progress, accent, theme, size = 280 }) {
  const stroke = 14;
  const r = (size - stroke) / 2 - 12;
  const c = 2 * Math.PI * r;
  const p = Math.min(Math.max(progress, 0), 1.15);
  const color = p >= 1 ? theme.danger : p >= 0.9 ? theme.warn : accent.main;
  const arc = 0.78;
  const startAngle = (1 - arc) / 2 * 360 + 90;
  const sweepLen = c * arc;

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
        stroke={filled ? color : theme.dimmer}
        strokeOpacity={filled ? 1 : 0.6}
        strokeWidth={isMajor ? 2 : 1}
        strokeLinecap="round" />
    );
  }
  return (
    <svg width={size} height={size} style={{ overflow: 'visible' }}>
      <defs>
        <filter id="gglow" x="-40%" y="-40%" width="180%" height="180%">
          <feGaussianBlur stdDeviation="6" />
        </filter>
      </defs>
      <g>{ticks}</g>
      <circle cx={size/2} cy={size/2} r={r}
        stroke={theme.hairline} strokeWidth={stroke} fill="none"
        strokeDasharray={`${sweepLen} ${c}`}
        strokeDashoffset={-c * (1 - arc) / 2}
        transform={`rotate(90 ${size/2} ${size/2})`}
        strokeLinecap="round" />
      <circle cx={size/2} cy={size/2} r={r}
        stroke={color} strokeWidth={stroke} fill="none"
        strokeDasharray={`${sweepLen * Math.min(p, 1)} ${c}`}
        strokeDashoffset={-c * (1 - arc) / 2}
        transform={`rotate(90 ${size/2} ${size/2})`}
        strokeLinecap="round"
        opacity="0.6" filter="url(#gglow)" />
      <circle cx={size/2} cy={size/2} r={r}
        stroke={color} strokeWidth={stroke} fill="none"
        strokeDasharray={`${sweepLen * Math.min(p, 1)} ${c}`}
        strokeDashoffset={-c * (1 - arc) / 2}
        transform={`rotate(90 ${size/2} ${size/2})`}
        strokeLinecap="round" />
    </svg>
  );
}

function GaugeSegmented({ progress, accent, theme, size = 280 }) {
  const segments = 32;
  const filled = Math.min(Math.round(progress * segments), segments);
  const stroke = 10;
  const r = (size - stroke) / 2 - 8;
  const arc = 0.78;
  const startAngle = (1 - arc) / 2 * 360 + 90;
  const segs = [];
  for (let i = 0; i < segments; i++) {
    const t = (i + 0.5) / segments;
    const ang = startAngle + t * arc * 360;
    const rad = (ang * Math.PI) / 180;
    const x1 = size / 2 + Math.cos(rad) * (r - 10);
    const y1 = size / 2 + Math.sin(rad) * (r - 10);
    const x2 = size / 2 + Math.cos(rad) * (r + 10);
    const y2 = size / 2 + Math.sin(rad) * (r + 10);
    const isFilled = i < filled;
    const isOver = progress >= 1 && i >= Math.floor(segments / 1.15);
    const color = isOver ? theme.danger : (isFilled ? accent.main : theme.dimmer);
    segs.push(
      <line key={i} x1={x1} y1={y1} x2={x2} y2={y2}
        stroke={color}
        strokeOpacity={isFilled ? 1 : 0.35}
        strokeWidth={5}
        strokeLinecap="round"
        style={{ filter: isFilled ? `drop-shadow(0 0 6px ${color}80)` : 'none' }} />
    );
  }
  return (
    <svg width={size} height={size}>{segs}</svg>
  );
}

function GaugeBar({ progress, accent, theme, size = 280 }) {
  const p = Math.min(Math.max(progress, 0), 1.15);
  const color = p >= 1 ? theme.danger : p >= 0.9 ? theme.warn : accent.main;
  return (
    <div style={{
      width: size, height: size,
      display: 'flex', flexDirection: 'column',
      alignItems: 'center', justifyContent: 'center',
      gap: 32,
    }}>
      <div style={{
        fontSize: 11, color: theme.dim, letterSpacing: 2,
        textTransform: 'uppercase', fontFamily: SANS,
      }}>0 → {fmt(36000)} mi</div>
      <div style={{ width: size - 30, position: 'relative' }}>
        <div style={{
          height: 16, borderRadius: 8, background: theme.hairline,
          overflow: 'hidden', position: 'relative',
        }}>
          <div style={{
            height: '100%', width: `${Math.min(p, 1) * 100}%`,
            background: color,
            borderRadius: 8,
            boxShadow: `0 0 20px ${color}80`,
          }} />
        </div>
        {/* tick ruler */}
        <div style={{
          display: 'flex', justifyContent: 'space-between',
          marginTop: 8,
          fontFamily: MONO, fontSize: 9,
          color: theme.dim, letterSpacing: 1,
        }}>
          {[0, 25, 50, 75, 100].map(t => <span key={t}>{t}%</span>)}
        </div>
      </div>
    </div>
  );
}

function HeroGauge({ progress, projected, variance, accent, theme, gaugeStyle, unit = 'mi' }) {
  const GaugeComp = { circular: GaugeCircular, segmented: GaugeSegmented, bar: GaugeBar }[gaugeStyle];
  const positive = variance < 0;
  return (
    <div style={{ position: 'relative', width: 288, height: 288 }}>
      <GaugeComp progress={progress} accent={accent} theme={theme} />
      <div style={{
        position: 'absolute', inset: 0,
        display: 'flex', flexDirection: 'column',
        alignItems: 'center', justifyContent: 'center',
        fontFamily: MONO, pointerEvents: 'none',
      }}>
        <div style={{
          fontSize: 10, color: theme.dim, letterSpacing: 2,
          textTransform: 'uppercase', marginBottom: 10,
          fontFamily: SANS, fontWeight: 500,
        }}>Projected</div>
        <div style={{
          fontSize: 54, fontWeight: 500, color: theme.text,
          letterSpacing: -2, lineHeight: 1,
          fontFeatureSettings: '"tnum"',
        }}>{fmt(projected)}</div>
        <div style={{
          fontSize: 11, color: theme.dim, marginTop: 6,
          letterSpacing: 1.5, fontFamily: SANS,
        }}>{unit.toUpperCase()} · BY LEASE END</div>
        <div style={{
          marginTop: 18, padding: '6px 12px',
          background: positive ? accent.soft : theme.dangerSoft,
          borderRadius: 20,
          fontSize: 12, fontWeight: 500,
          color: positive ? accent.main : theme.danger,
          letterSpacing: 0.5, fontFamily: MONO,
          fontFeatureSettings: '"tnum"',
        }}>
          {fmtSigned(variance)} {unit} vs limit
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { HeroGauge });
