// History/Chart detail

function LineChart({ readings, allowed, starting, theme, accent, width = 330, height = 180 }) {
  const padding = { top: 20, bottom: 24, left: 36, right: 12 };
  const W = width - padding.left - padding.right;
  const H = height - padding.top - padding.bottom;
  const maxVal = Math.max(allowed + starting, readings[readings.length - 1].value) * 1.08;
  const scaleX = (i) => padding.left + (i / (readings.length - 1)) * W;
  const scaleY = (v) => padding.top + H - (v / maxVal) * H;

  const targetEndY = scaleY(starting + allowed);
  const points = readings.map((r, i) => `${scaleX(i)},${scaleY(r.value)}`).join(' ');
  const areaPoints = `${scaleX(0)},${padding.top + H} ${readings.map((r, i) => `${scaleX(i)},${scaleY(r.value)}`).join(' ')} ${scaleX(readings.length - 1)},${padding.top + H}`;

  return (
    <svg width={width} height={height}>
      <defs>
        <linearGradient id="histarea" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor={accent.main} stopOpacity="0.25" />
          <stop offset="100%" stopColor={accent.main} stopOpacity="0" />
        </linearGradient>
      </defs>
      {[0, 0.25, 0.5, 0.75, 1].map((g, i) => {
        const y = padding.top + H * g;
        const val = Math.round(maxVal * (1 - g) / 1000) + 'k';
        return (
          <g key={i}>
            <line x1={padding.left} x2={padding.left + W} y1={y} y2={y}
              stroke={theme.hairline} strokeOpacity="0.6" />
            <text x={padding.left - 6} y={y + 3} fill={theme.dim} fontSize="9" fontFamily={MONO} textAnchor="end">{val}</text>
          </g>
        );
      })}
      {/* target diagonal */}
      <line x1={scaleX(0)} y1={scaleY(starting)} x2={scaleX(readings.length - 1)} y2={targetEndY}
        stroke={theme.warn} strokeOpacity="0.6" strokeWidth="1.2" strokeDasharray="4 4" />
      {/* area */}
      <polygon points={areaPoints} fill="url(#histarea)" />
      {/* line */}
      <polyline points={points} fill="none"
        stroke={accent.main} strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
      {readings.map((r, i) => (
        <circle key={i} cx={scaleX(i)} cy={scaleY(r.value)}
          r={i === readings.length - 1 ? 4 : 2}
          fill={accent.main} stroke={theme.panel}
          strokeWidth={i === readings.length - 1 ? 2 : 0} />
      ))}
    </svg>
  );
}

function History({ theme, accent, vehicle, danger, onBack }) {
  const current = danger ? vehicle.currentOverPace : vehicle.currentOnPace;
  const readings = React.useMemo(() => makeReadings(vehicle.starting, current, 13, 1), [vehicle, danger]);
  const totalDriven = current - vehicle.starting;
  const ranges = ['1M', '3M', '6M', '1Y', 'ALL'];
  const [range, setRange] = React.useState(3);

  return (
    <div style={{ width: SCREEN_W, height: SCREEN_H, background: theme.bg, color: theme.text, fontFamily: SANS, position: 'relative', overflow: 'hidden' }}>
      <StatusBar theme={theme} />
      <NavBar theme={theme} title="History" onBack={onBack} />

      <div style={{ margin: '0 20px 14px', padding: 4, background: theme.panel, border: `1px solid ${theme.hairline}`, borderRadius: 100, display: 'flex' }}>
        {ranges.map((r, i) => (
          <button key={r} onClick={() => setRange(i)} style={{
            flex: 1, border: 'none', cursor: 'pointer',
            padding: '8px 0', borderRadius: 100,
            fontFamily: MONO, fontSize: 11, fontWeight: 500, letterSpacing: 1,
            background: i === range ? accent.main : 'transparent',
            color: i === range ? accent.text : theme.dim,
          }}>{r}</button>
        ))}
      </div>

      <div style={{ padding: '0 24px 12px' }}>
        <div style={{ fontSize: 10, color: theme.dim, letterSpacing: 1.5, marginBottom: 4 }}>DRIVEN · 13 MO</div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 10 }}>
          <div style={{ fontFamily: MONO, fontSize: 38, fontWeight: 500, letterSpacing: -1.5, fontFeatureSettings: '"tnum"' }}>{fmt(totalDriven)}</div>
          <div style={{ fontSize: 12, color: theme.dim }}>mi</div>
          <div style={{
            marginLeft: 'auto',
            fontFamily: MONO, fontSize: 12, color: danger ? theme.danger : accent.main,
            background: danger ? theme.dangerSoft : accent.soft,
            padding: '4px 10px', borderRadius: 12,
          }}>{danger ? '+12% over' : '−12% under'}</div>
        </div>
      </div>

      <div style={{ margin: '0 20px', padding: '10px 4px 10px', background: theme.panel, border: `1px solid ${theme.hairline}`, borderRadius: 20 }}>
        <LineChart readings={readings} allowed={vehicle.allowed} starting={vehicle.starting} theme={theme} accent={accent} width={318} height={180} />
        <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0 20px', fontFamily: MONO, fontSize: 9, color: theme.dim, letterSpacing: 1 }}>
          <span>APR'24</span><span>AUG</span><span>DEC</span><span>APR'25</span>
        </div>
        <div style={{ display: 'flex', gap: 14, padding: '12px 20px 0', marginTop: 8, borderTop: `1px solid ${theme.hairline}` }}>
          <Legend color={accent.main} label="Actual" theme={theme} />
          <Legend color={theme.warn} label="Target" theme={theme} dashed />
        </div>
      </div>

      <div style={{ padding: '20px 24px 0' }}>
        <div style={{ fontSize: 10, color: theme.dim, letterSpacing: 1.5, marginBottom: 10, display: 'flex', justifyContent: 'space-between' }}>
          <span>RECENT READINGS</span>
          <span style={{ color: accent.main, cursor: 'pointer' }}>All →</span>
        </div>
        {readings.slice(-3).reverse().map((r, i, arr) => {
          const prev = readings[readings.length - arr.length - i - 1 + arr.length - 1] || readings[readings.length - arr.length - 1];
          const idx = readings.indexOf(r);
          const prevReading = readings[idx - 1];
          const diff = prevReading ? r.value - prevReading.value : 0;
          return (
            <div key={i} style={{
              display: 'flex', justifyContent: 'space-between', alignItems: 'center',
              padding: '12px 0',
              borderBottom: i < 2 ? `1px solid ${theme.hairline}` : 'none',
            }}>
              <div>
                <div style={{ fontFamily: MONO, fontSize: 15, fontWeight: 500, fontFeatureSettings: '"tnum"' }}>{fmt(r.value)} mi</div>
                <div style={{ fontSize: 11, color: theme.dim, marginTop: 2 }}>
                  {r.date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
                </div>
              </div>
              {prevReading && (
                <div style={{
                  fontFamily: MONO, fontSize: 12, color: accent.main,
                  background: accent.soft, padding: '4px 8px', borderRadius: 4,
                }}>+{fmt(diff)}</div>
              )}
            </div>
          );
        })}
      </div>

      <HomeIndicator theme={theme} />
    </div>
  );
}

function Legend({ color, label, theme, dashed }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 10, color: theme.dim, fontFamily: SANS }}>
      <div style={{
        width: 14, height: 2,
        background: dashed ? 'transparent' : color,
        borderTop: dashed ? `2px dashed ${color}` : 'none',
      }} />
      {label}
    </div>
  );
}

Object.assign(window, { History });
