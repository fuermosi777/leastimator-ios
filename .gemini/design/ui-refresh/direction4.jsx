// Direction 4 — "Track Day"
// Most aggressive/performance-inspired. Sharp geometry, racing-stripe accents,
// segmented bar rather than arc, bold condensed display type.

const D4 = {
  bg: '#0c0c0e',
  panel: '#16161a',
  panelHi: '#1d1d22',
  stroke: 'rgba(255,255,255,0.06)',
  text: '#f7f7fa',
  dim: '#787884',
  dimmer: '#3d3d46',
  accent: '#ff5e1f',     // racing orange
  accentDim: 'rgba(255,94,31,0.15)',
  pos: '#3dd980',
  danger: '#ff2440',
  display: '"Azeret Mono", "JetBrains Mono", "SF Mono", ui-monospace, monospace',
  sans: '"Inter", -apple-system, system-ui, sans-serif',
};

// Segmented linear gauge - 20 segments
function SegmentBar({ progress, segments = 24 }) {
  const filled = Math.round(progress * segments);
  const segs = [];
  for (let i = 0; i < segments; i++) {
    const isFilled = i < filled;
    const isLimit = i === Math.floor(segments * (1 / 1.1));
    let color;
    if (!isFilled) color = D4.dimmer;
    else if (i / segments >= 1) color = D4.danger;
    else if (i / segments >= 0.85) color = '#ffb347';
    else color = D4.accent;
    segs.push(
      <div key={i} style={{
        flex: 1,
        height: i < 4 || i > segments - 5 ? 14 : 22,
        background: color,
        opacity: isFilled ? 1 : 0.35,
        boxShadow: isFilled ? `0 0 12px ${color}80` : 'none',
        transform: i % 2 === 0 ? 'skewX(-12deg)' : 'skewX(-12deg)',
      }} />
    );
  }
  return (
    <div style={{
      display: 'flex', gap: 3,
      alignItems: 'center',
      height: 22,
    }}>{segs}</div>
  );
}

function D4Dashboard({ danger = false }) {
  const v = danger ? vehicleDanger : vehicleSample;
  const progress = (v.projected - v.starting) / v.allowed;
  const positive = v.variance < 0;

  return (
    <div style={{
      width: SCREEN_W, height: SCREEN_H,
      background: D4.bg,
      position: 'relative',
      fontFamily: D4.sans,
      color: D4.text,
      overflow: 'hidden',
    }}>
      {/* Diagonal racing stripes in bg */}
      <div style={{
        position: 'absolute', inset: 0,
        backgroundImage: `repeating-linear-gradient(-20deg, transparent 0, transparent 60px, ${D4.stroke} 60px, ${D4.stroke} 61px)`,
        pointerEvents: 'none',
      }} />

      <StatusBar dark={true} />

      {/* Header strip */}
      <div style={{
        padding: '8px 20px 0',
        display: 'flex', alignItems: 'center', gap: 10,
      }}>
        <div style={{
          padding: '4px 8px',
          background: D4.accent,
          color: D4.bg,
          fontFamily: D4.display, fontSize: 10,
          fontWeight: 700, letterSpacing: 1.5,
          clipPath: 'polygon(6% 0, 100% 0, 94% 100%, 0 100%)',
        }}>LEASE · 23MO LEFT</div>
        <div style={{ flex: 1, height: 1, background: D4.stroke }} />
        <div style={{
          fontFamily: D4.display, fontSize: 11, color: D4.dim, letterSpacing: 1.5,
        }}>#001</div>
      </div>

      {/* Vehicle badge */}
      <div style={{ padding: '14px 20px 0' }}>
        <div style={{
          fontFamily: D4.display, fontSize: 46, fontWeight: 700,
          color: D4.text, letterSpacing: -2,
          lineHeight: 0.95,
          textTransform: 'uppercase',
        }}>
          MODEL<span style={{ color: D4.accent }}>/</span>3
        </div>
        <div style={{
          fontSize: 11, color: D4.dim, marginTop: 6,
          letterSpacing: 2, textTransform: 'uppercase',
          fontFamily: D4.sans, fontWeight: 500,
        }}>
          Long Range · 2023 · AWD
        </div>
      </div>

      {/* Main projection panel */}
      <div style={{
        margin: '20px 20px 0',
        background: D4.panel,
        border: `1px solid ${D4.stroke}`,
        padding: '22px 22px 26px',
        clipPath: 'polygon(0 0, 100% 0, 100% calc(100% - 18px), calc(100% - 18px) 100%, 0 100%)',
        position: 'relative',
      }}>
        <div style={{
          display: 'flex', justifyContent: 'space-between',
          alignItems: 'flex-start', marginBottom: 14,
        }}>
          <div>
            <div style={{ fontSize: 9, color: D4.dim, letterSpacing: 2, fontWeight: 600 }}>PROJECTED EOL</div>
            <div style={{
              fontFamily: D4.display, fontSize: 56, fontWeight: 700,
              letterSpacing: -2, lineHeight: 1,
              marginTop: 4,
              color: D4.text,
              fontFeatureSettings: '"tnum"',
            }}>{fmt(v.projected)}</div>
            <div style={{ fontSize: 11, color: D4.dim, marginTop: 2, letterSpacing: 1 }}>MILES</div>
          </div>
          <div style={{
            padding: '6px 10px',
            background: positive ? 'rgba(61,217,128,0.12)' : 'rgba(255,36,64,0.15)',
            border: `1px solid ${positive ? D4.pos : D4.danger}40`,
            fontFamily: D4.display, fontSize: 13, fontWeight: 700,
            color: positive ? D4.pos : D4.danger,
            letterSpacing: 0.5,
            fontFeatureSettings: '"tnum"',
          }}>
            {fmtSigned(v.variance)}
          </div>
        </div>

        {/* Segmented bar */}
        <SegmentBar progress={progress} />

        {/* Scale ruler */}
        <div style={{
          display: 'flex', justifyContent: 'space-between',
          marginTop: 10,
          fontFamily: D4.display, fontSize: 10, color: D4.dim,
          letterSpacing: 0.5,
          fontFeatureSettings: '"tnum"',
        }}>
          <span>0</span>
          <span>{fmt(v.allowed / 2)}</span>
          <span style={{ color: D4.accent }}>{fmt(v.allowed)} LIMIT</span>
        </div>
      </div>

      {/* Coach bar */}
      <div style={{
        margin: '14px 20px 0',
        padding: '12px 14px',
        border: `1px solid ${D4.stroke}`,
        background: positive ? 'rgba(61,217,128,0.06)' : 'rgba(255,36,64,0.08)',
        display: 'flex', alignItems: 'center', gap: 10,
      }}>
        <div style={{
          width: 20, height: 20,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          background: positive ? D4.pos : D4.danger,
          color: D4.bg,
          fontFamily: D4.display, fontSize: 11, fontWeight: 700,
        }}>{positive ? '✓' : '!'}</div>
        <div style={{ fontSize: 12, color: D4.text, letterSpacing: 0.3, lineHeight: 1.35, flex: 1 }}>
          {positive
            ? <>You've got <strong style={{ fontFamily: D4.display, color: D4.pos }}>{v.maxDriveToday} mi</strong> to play with today.</>
            : <>Slow down. You're burning <strong style={{ fontFamily: D4.display, color: D4.danger }}>+{v.mileagePerDay - 32} mi/day</strong> over pace.</>
          }
        </div>
      </div>

      {/* Split metrics */}
      <div style={{
        margin: '14px 20px 0',
        display: 'grid', gridTemplateColumns: '1fr 1fr',
        gap: 1, background: D4.stroke,
        border: `1px solid ${D4.stroke}`,
      }}>
        <D4Metric label="AVG/DAY" value={v.mileagePerDay} unit="MI" />
        <D4Metric label="ODO" value={v.currentMileage} unit="MI" small />
        <D4Metric label="ELAPSED" value={v.usedDays} unit="DAYS" />
        <D4Metric label="BUDGET/DAY" value={33} unit="MI" target />
      </div>

      {/* Add reading FAB */}
      <div style={{
        position: 'absolute', left: 20, right: 20, bottom: 38,
      }}>
        <button style={{
          width: '100%', height: 56,
          background: D4.accent,
          color: D4.bg,
          border: 'none',
          fontFamily: D4.display, fontSize: 14,
          fontWeight: 700, letterSpacing: 2,
          textTransform: 'uppercase',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          gap: 10,
          clipPath: 'polygon(0 0, 100% 0, 96% 100%, 4% 100%)',
          boxShadow: `0 0 30px ${D4.accentDim}`,
        }}>
          <span style={{ fontSize: 18 }}>+</span>
          LOG READING
        </button>
      </div>

      <HomeIndicator dark />
    </div>
  );
}

function D4Metric({ label, value, unit, small = false, target = false }) {
  return (
    <div style={{
      background: D4.panel,
      padding: '14px 14px',
    }}>
      <div style={{
        fontSize: 9, color: D4.dim, letterSpacing: 2,
        fontWeight: 600, marginBottom: 6,
      }}>{label}</div>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 5 }}>
        <div style={{
          fontFamily: D4.display, fontSize: small ? 22 : 28,
          fontWeight: 700, letterSpacing: -0.8,
          color: target ? D4.accent : D4.text,
          fontFeatureSettings: '"tnum"',
        }}>{fmt(value)}</div>
        <div style={{
          fontFamily: D4.display, fontSize: 10, color: D4.dim,
          letterSpacing: 1,
        }}>{unit}</div>
      </div>
    </div>
  );
}

Object.assign(window, { D4Dashboard, D4 });
