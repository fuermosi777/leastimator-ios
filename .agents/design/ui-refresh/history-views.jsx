// History / Chart views — one matching variant per direction (showing 1 & 2 to keep canvas manageable)
// Focused on the history chart experience: line graph over time, reading log, trend insights.

// Helper — generate sample reading history
const generateReadings = () => {
  const readings = [];
  const months = 13;
  let mileage = 12;
  for (let i = 0; i < months; i++) {
    mileage += 1200 + Math.random() * 400 - 150;
    readings.push({
      month: i,
      value: Math.round(mileage),
      date: new Date(2024, 2 + i, 14),
    });
  }
  return readings;
};

const sampleReadings = generateReadings();

// Sparkline/line chart — shared
function LineChart({ readings, allowed, starting, width = 330, height = 140, color = '#c6ff3a', textColor = '#fff', dimColor = '#666', limitColor, bg = 'transparent' }) {
  const padding = { top: 10, bottom: 20, left: 8, right: 8 };
  const W = width - padding.left - padding.right;
  const H = height - padding.top - padding.bottom;
  const maxVal = Math.max(allowed + starting, readings[readings.length - 1].value) * 1.05;
  const scaleX = (i) => padding.left + (i / (readings.length - 1)) * W;
  const scaleY = (v) => padding.top + H - (v / maxVal) * H;

  // projection line (from last reading, extend to lease end at current pace)
  const last = readings[readings.length - 1];
  const perMonth = (last.value - starting) / (readings.length);
  const projectionX = padding.left + W;
  const projectionY = scaleY(starting + perMonth * 36);

  // target line (diagonal from start to allowed)
  const targetStart = { x: scaleX(0), y: scaleY(starting) };
  const targetEnd = { x: padding.left + W, y: scaleY(starting + allowed) };

  const points = readings.map((r, i) => `${scaleX(i)},${scaleY(r.value)}`).join(' ');
  const areaPoints = `${scaleX(0)},${scaleY(starting)} ${points} ${scaleX(readings.length - 1)},${padding.top + H}`;

  return (
    <svg width={width} height={height} style={{ background: bg }}>
      <defs>
        <linearGradient id={`area-${color.replace('#','')}`} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor={color} stopOpacity="0.25" />
          <stop offset="100%" stopColor={color} stopOpacity="0" />
        </linearGradient>
      </defs>
      {/* gridlines */}
      {[0.25, 0.5, 0.75].map((g, i) => (
        <line key={i}
          x1={padding.left} x2={padding.left + W}
          y1={padding.top + H * g} y2={padding.top + H * g}
          stroke={dimColor} strokeOpacity="0.15" strokeDasharray="2 4" />
      ))}
      {/* target */}
      <line x1={targetStart.x} y1={targetStart.y} x2={targetEnd.x} y2={targetEnd.y}
        stroke={limitColor || dimColor} strokeOpacity="0.5" strokeWidth="1" strokeDasharray="4 4" />
      {/* projection extension */}
      <line x1={scaleX(readings.length-1)} y1={scaleY(last.value)} x2={projectionX} y2={projectionY}
        stroke={color} strokeOpacity="0.4" strokeWidth="1.5" strokeDasharray="3 3" />
      {/* area */}
      <polyline points={areaPoints.replace(/,/g,' ').replace(/ /g, ',').replace(/^,/,'')}
        fill={`url(#area-${color.replace('#','')})`}
        stroke="none" />
      {/* line */}
      <polyline points={points} fill="none"
        stroke={color} strokeWidth="2.5"
        strokeLinecap="round" strokeLinejoin="round" />
      {/* dots */}
      {readings.map((r, i) => (
        <circle key={i} cx={scaleX(i)} cy={scaleY(r.value)}
          r={i === readings.length - 1 ? 4 : 2}
          fill={color}
          stroke={bg !== 'transparent' ? bg : '#000'}
          strokeWidth={i === readings.length - 1 ? 2 : 0} />
      ))}
    </svg>
  );
}

// History view for Direction 1 (Instrument Cluster)
function D1History() {
  const readings = sampleReadings;
  return (
    <div style={{
      width: SCREEN_W, height: SCREEN_H,
      background: D1.bg,
      position: 'relative',
      fontFamily: D1.sans, color: D1.text,
      overflow: 'hidden',
    }}>
      <StatusBar dark />

      {/* Header */}
      <div style={{ padding: '8px 20px 20px', display: 'flex', alignItems: 'center', gap: 12 }}>
        <button style={{
          width: 36, height: 36, borderRadius: 18,
          background: D1.panel, border: `1px solid ${D1.hairline}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="14" height="14" viewBox="0 0 14 14"><path d="M9 2 L4 7 L9 12" stroke={D1.text} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" fill="none"/></svg>
        </button>
        <div>
          <div style={{ fontSize: 11, color: D1.dim, letterSpacing: 1.5, textTransform: 'uppercase' }}>History</div>
          <div style={{ fontSize: 17, fontWeight: 600 }}>Model 3</div>
        </div>
      </div>

      {/* Range selector */}
      <div style={{
        margin: '0 20px 16px',
        padding: 4,
        background: D1.panel,
        border: `1px solid ${D1.hairline}`,
        borderRadius: 100,
        display: 'flex',
      }}>
        {['1M', '3M', '6M', '1Y', 'ALL'].map((r, i) => (
          <div key={r} style={{
            flex: 1, textAlign: 'center',
            padding: '8px 0',
            borderRadius: 100,
            fontSize: 12, fontWeight: 500,
            fontFamily: D1.mono,
            letterSpacing: 1,
            background: i === 3 ? D1.accent : 'transparent',
            color: i === 3 ? D1.bg : D1.dim,
          }}>{r}</div>
        ))}
      </div>

      {/* Headline stat */}
      <div style={{ padding: '0 24px 8px' }}>
        <div style={{ fontSize: 10, color: D1.dim, letterSpacing: 1.5, textTransform: 'uppercase', marginBottom: 6 }}>
          Past 12 months
        </div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 10 }}>
          <div style={{
            fontFamily: D1.mono, fontSize: 38, fontWeight: 500,
            letterSpacing: -1.5, fontFeatureSettings: '"tnum"',
          }}>{fmt(readings[readings.length - 1].value - readings[0].value)}</div>
          <div style={{ fontSize: 12, color: D1.dim }}>mi driven</div>
        </div>
      </div>

      {/* Chart card */}
      <div style={{
        margin: '8px 20px 0',
        padding: '16px 12px 12px',
        background: D1.panel,
        border: `1px solid ${D1.hairline}`,
        borderRadius: 20,
      }}>
        <LineChart readings={readings} allowed={36000} starting={12}
          color={D1.accent} dimColor={D1.dim} limitColor={D1.warn}
          width={326} height={160} bg={D1.panel} />
        <div style={{
          display: 'flex', justifyContent: 'space-between',
          padding: '0 4px',
          fontFamily: D1.mono, fontSize: 9, color: D1.dim,
          letterSpacing: 1,
        }}>
          <span>APR '24</span><span>AUG</span><span>DEC</span><span>APR '25</span>
        </div>
        {/* legend */}
        <div style={{
          display: 'flex', gap: 14, padding: '14px 4px 0',
          borderTop: `1px solid ${D1.hairline}`,
          marginTop: 12,
        }}>
          <Legend color={D1.accent} label="Actual" />
          <Legend color={D1.warn} label="Target" dashed />
          <Legend color={D1.accent} label="Projected" dashed soft />
        </div>
      </div>

      {/* Recent readings list */}
      <div style={{ padding: '20px 24px 0' }}>
        <div style={{
          fontSize: 10, color: D1.dim, letterSpacing: 1.5, textTransform: 'uppercase',
          marginBottom: 12,
          display: 'flex', justifyContent: 'space-between',
        }}>
          <span>Recent readings</span>
          <span style={{ color: D1.accent }}>View all →</span>
        </div>
        {readings.slice(-3).reverse().map((r, i, arr) => {
          const prev = arr[i + 1] || readings[readings.length - arr.length - 1];
          const diff = prev ? r.value - prev.value : 0;
          return (
            <div key={i} style={{
              display: 'flex', justifyContent: 'space-between', alignItems: 'center',
              padding: '12px 0',
              borderBottom: i < 2 ? `1px solid ${D1.hairline}` : 'none',
            }}>
              <div>
                <div style={{
                  fontFamily: D1.mono, fontSize: 16, fontWeight: 500,
                  fontFeatureSettings: '"tnum"',
                }}>{fmt(r.value)} mi</div>
                <div style={{ fontSize: 11, color: D1.dim, marginTop: 2 }}>
                  {r.date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
                </div>
              </div>
              {prev && (
                <div style={{
                  fontFamily: D1.mono, fontSize: 12,
                  color: D1.accent,
                  background: D1.accentDim,
                  padding: '4px 8px', borderRadius: 4,
                  fontFeatureSettings: '"tnum"',
                }}>+{fmt(diff)}</div>
              )}
            </div>
          );
        })}
      </div>

      <HomeIndicator dark />
    </div>
  );
}

function Legend({ color, label, dashed, soft }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 10, color: D1.dim, fontFamily: D1.sans }}>
      <div style={{
        width: 14, height: 2,
        background: dashed ? 'transparent' : color,
        borderTop: dashed ? `2px ${soft ? 'dashed' : 'dashed'} ${color}` : 'none',
        opacity: soft ? 0.5 : 1,
      }} />
      {label}
    </div>
  );
}

// History view for Direction 4 (Track Day)
function D4History() {
  const readings = sampleReadings;
  return (
    <div style={{
      width: SCREEN_W, height: SCREEN_H,
      background: D4.bg,
      position: 'relative',
      fontFamily: D4.sans, color: D4.text,
      overflow: 'hidden',
    }}>
      <div style={{
        position: 'absolute', inset: 0,
        backgroundImage: `repeating-linear-gradient(-20deg, transparent 0, transparent 60px, ${D4.stroke} 60px, ${D4.stroke} 61px)`,
        pointerEvents: 'none',
      }} />
      <StatusBar dark />

      <div style={{ padding: '8px 20px 0', display: 'flex', alignItems: 'center', gap: 10 }}>
        <button style={{
          width: 36, height: 36,
          background: D4.panel, border: `1px solid ${D4.stroke}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="14" height="14" viewBox="0 0 14 14"><path d="M9 2 L4 7 L9 12" stroke={D4.text} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" fill="none"/></svg>
        </button>
        <div style={{ flex: 1 }}>
          <div style={{
            fontFamily: D4.display, fontSize: 11, color: D4.accent,
            letterSpacing: 2, fontWeight: 700,
          }}>TELEMETRY LOG</div>
          <div style={{ fontSize: 14, fontWeight: 600 }}>Model 3 · 13 mo</div>
        </div>
      </div>

      {/* KPI row */}
      <div style={{ padding: '18px 20px 0', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 1, background: D4.stroke, border: `1px solid ${D4.stroke}`, margin: '18px 20px 0' }}>
        <div style={{ background: D4.panel, padding: '14px' }}>
          <div style={{ fontSize: 9, color: D4.dim, letterSpacing: 2, fontWeight: 600, marginBottom: 6 }}>TOTAL DRIVEN</div>
          <div style={{ fontFamily: D4.display, fontSize: 26, fontWeight: 700, letterSpacing: -0.5, color: D4.text, fontFeatureSettings: '"tnum"' }}>
            {fmt(readings[readings.length - 1].value - readings[0].value)} <span style={{ fontSize: 10, color: D4.dim }}>MI</span>
          </div>
        </div>
        <div style={{ background: D4.panel, padding: '14px' }}>
          <div style={{ fontSize: 9, color: D4.dim, letterSpacing: 2, fontWeight: 600, marginBottom: 6 }}>PACE</div>
          <div style={{ fontFamily: D4.display, fontSize: 26, fontWeight: 700, letterSpacing: -0.5, color: D4.pos, fontFeatureSettings: '"tnum"' }}>
            +12% <span style={{ fontSize: 10, color: D4.dim }}>UNDER</span>
          </div>
        </div>
      </div>

      {/* Big chart */}
      <div style={{
        margin: '14px 20px 0',
        padding: '18px 8px 12px',
        background: D4.panel,
        border: `1px solid ${D4.stroke}`,
      }}>
        <div style={{
          display: 'flex', justifyContent: 'space-between', padding: '0 12px 8px',
          fontSize: 9, color: D4.dim, letterSpacing: 2, fontWeight: 600,
        }}>
          <span>ODOMETER · MI</span>
          <span style={{ color: D4.accent }}>13 MO</span>
        </div>
        <LineChart readings={readings} allowed={36000} starting={12}
          color={D4.accent} dimColor={D4.dim} limitColor={D4.pos}
          width={326} height={180} bg={D4.panel} />
        <div style={{
          display: 'flex', justifyContent: 'space-between', padding: '0 12px',
          fontFamily: D4.display, fontSize: 10, color: D4.dim, letterSpacing: 1.5,
          fontFeatureSettings: '"tnum"',
        }}>
          <span>APR'24</span><span>JUL</span><span>OCT</span><span>JAN'25</span><span>APR</span>
        </div>
      </div>

      {/* Insight */}
      <div style={{
        margin: '14px 20px 0',
        padding: '14px',
        border: `1px solid ${D4.accent}`,
        background: 'rgba(255,94,31,0.06)',
        display: 'flex', gap: 12, alignItems: 'flex-start',
      }}>
        <div style={{
          fontFamily: D4.display, fontSize: 28, fontWeight: 700,
          color: D4.accent, letterSpacing: -1,
          fontFeatureSettings: '"tnum"',
        }}>14%</div>
        <div>
          <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 2 }}>Summer surge</div>
          <div style={{ fontSize: 11, color: D4.dim, lineHeight: 1.4 }}>
            You drove 14% more in Jun–Aug. Budget for that again this year.
          </div>
        </div>
      </div>

      <HomeIndicator dark />
    </div>
  );
}

Object.assign(window, { D1History, D4History, sampleReadings });
