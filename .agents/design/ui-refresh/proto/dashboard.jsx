// Main dashboard screen

function Dashboard({ theme, accent, copy, gaugeStyle, danger, vehicle, onOpenScreen, onCycleVehicle }) {
  const current = danger ? vehicle.currentOverPace : vehicle.currentOnPace;
  const used = current - vehicle.starting;
  const usedDays = danger ? 399 : 399;
  const mileagePerDay = used / usedDays;
  const totalDays = vehicle.lengthOfLease / 12 * 365;
  const projected = Math.round(vehicle.starting + totalDays * mileagePerDay);
  const variance = projected - vehicle.starting - vehicle.allowed;
  const progress = (projected - vehicle.starting) / vehicle.allowed;
  const positive = variance < 0;
  const allowedPerDay = vehicle.allowed / totalDays;
  const maxDriveToday = Math.max(0, Math.round((vehicle.starting + allowedPerDay * usedDays) - current));
  const monthlyAvg = Math.round(used / Math.max(1, Math.round(usedDays / 30)));
  const leaseLeft = Math.max(0, vehicle.lengthOfLease - Math.round(usedDays / 30));

  const msg = danger ? copy.overPace : copy.onPace;

  return (
    <div style={{
      width: SCREEN_W, height: SCREEN_H,
      background: theme.bg,
      position: 'relative',
      fontFamily: SANS, color: theme.text,
      overflow: 'hidden',
    }}>
      {/* Danger vignette */}
      {danger && (
        <div style={{
          position: 'absolute', inset: 0,
          background: `radial-gradient(ellipse at 50% 30%, ${theme.dangerGlow}, transparent 60%)`,
          pointerEvents: 'none',
        }} />
      )}
      <StatusBar theme={theme} />

      {/* Top bar */}
      <div style={{
        padding: '6px 20px 14px',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        position: 'relative',
      }}>
        <button onClick={onCycleVehicle} style={{
          display: 'flex', alignItems: 'center', gap: 10,
          padding: '8px 14px 8px 10px',
          background: theme.panel,
          border: `1px solid ${theme.hairline}`,
          borderRadius: 100,
          cursor: 'pointer',
        }}>
          <div style={{
            width: 22, height: 22, borderRadius: 11,
            background: accent.main,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontFamily: MONO, fontSize: 10, fontWeight: 700,
            color: accent.text,
          }}>{vehicle.name.split(' ').map(w => w[0]).join('').toUpperCase().slice(0,2)}</div>
          <div style={{ fontSize: 14, fontWeight: 500, color: theme.text }}>{vehicle.name}</div>
          <Icon name="chev-d" size={12} color={theme.dim} stroke={1.5}/>
        </button>
        <button onClick={() => onOpenScreen('settings')} style={{
          width: 40, height: 40, borderRadius: 20,
          background: theme.panel,
          border: `1px solid ${theme.hairline}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          cursor: 'pointer',
        }}>
          <Icon name="settings" size={18} color={theme.text} stroke={1.6} />
        </button>
      </div>

      {/* Coach line */}
      <div style={{ padding: '0 24px 4px', display: 'flex', alignItems: 'center', gap: 8 }}>
        <div style={{
          width: 6, height: 6, borderRadius: 3,
          background: danger ? theme.danger : accent.main,
          boxShadow: `0 0 10px ${danger ? theme.danger : accent.main}`,
        }} />
        <div style={{ fontSize: 13, color: danger ? theme.danger : theme.dim, letterSpacing: 0.2, fontWeight: 500 }}>
          {msg.title}
        </div>
      </div>
      <div style={{ padding: '0 24px 8px', fontSize: 12, color: theme.dim }}>
        {msg.sub}
      </div>

      {/* Hero gauge */}
      <div style={{ display: 'flex', justifyContent: 'center', padding: '16px 0 8px' }}>
        <HeroGauge progress={progress} projected={projected} variance={variance}
          accent={accent} theme={theme} gaugeStyle={gaugeStyle} />
      </div>

      {/* Today banner */}
      <div style={{
        margin: '4px 20px 0',
        padding: '14px 16px',
        background: theme.panel,
        border: `1px solid ${theme.hairline}`,
        borderRadius: 16,
        display: 'flex', alignItems: 'center', gap: 12,
      }}>
        <div style={{
          width: 36, height: 36, borderRadius: 10,
          background: positive ? accent.soft : theme.dangerSoft,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          flexShrink: 0,
        }}>
          <Icon name={positive ? "bolt" : "alert"} size={18} color={positive ? accent.main : theme.danger} />
        </div>
        <div style={{ flex: 1, fontSize: 13, lineHeight: 1.3, color: theme.text }}>
          {positive ? copy.todayPositive(maxDriveToday) : copy.todayNegative()}
        </div>
      </div>

      {/* Mini stats — 3 cells */}
      <div style={{ padding: '12px 20px 0' }}>
        <div style={{
          display: 'grid', gridTemplateColumns: '1fr 1fr 1fr',
          gap: 1, background: theme.hairline,
          border: `1px solid ${theme.hairline}`, borderRadius: 16, overflow: 'hidden',
        }}>
          <StatCell label="DAILY AVG" value={mileagePerDay.toFixed(0)} unit="mi" theme={theme} />
          <StatCell label="ODOMETER" value={current} unit="mi" theme={theme} small />
          <StatCell label="LEASE LEFT" value={leaseLeft} unit="mo" theme={theme} />
        </div>
      </div>

      {/* Bottom actions */}
      <div style={{
        position: 'absolute', left: 20, right: 20, bottom: 34,
        display: 'flex', gap: 12,
      }}>
        <button onClick={() => onOpenScreen('addReading')} style={{
          flex: 1, height: 54,
          background: danger ? theme.danger : accent.main,
          color: danger ? '#fff' : accent.text,
          border: 'none', borderRadius: 27,
          fontFamily: SANS, fontSize: 15, fontWeight: 600,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          gap: 8, cursor: 'pointer',
          boxShadow: `0 0 30px ${danger ? theme.dangerGlow : accent.soft}`,
        }}>
          <Icon name="plus" size={18} color={danger ? '#fff' : accent.text} stroke={2.5} />
          {msg.cta}
        </button>
        <button onClick={() => onOpenScreen('history')} style={{
          width: 54, height: 54,
          background: theme.panel,
          border: `1px solid ${theme.hairline}`,
          borderRadius: 27,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          cursor: 'pointer',
        }}>
          <Icon name="chart" size={18} color={theme.text} />
        </button>
      </div>
      <HomeIndicator theme={theme} />
    </div>
  );
}

function StatCell({ label, value, unit, theme, small }) {
  return (
    <div style={{
      background: theme.bg,
      padding: '14px 12px',
      display: 'flex', flexDirection: 'column', gap: 8,
    }}>
      <div style={{
        fontSize: 9, letterSpacing: 1.3, color: theme.dim,
        fontFamily: SANS, fontWeight: 500,
      }}>{label}</div>
      <div style={{
        display: 'flex', alignItems: 'baseline', gap: 3,
        fontFamily: MONO, fontFeatureSettings: '"tnum"',
      }}>
        <div style={{
          fontSize: small ? 20 : 24, fontWeight: 500,
          color: theme.text, letterSpacing: -0.5,
        }}>{fmt(value)}</div>
        <div style={{ fontSize: 10, color: theme.dim, letterSpacing: 1 }}>{unit}</div>
      </div>
    </div>
  );
}

Object.assign(window, { Dashboard });
