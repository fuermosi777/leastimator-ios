// Add Reading screen + Vehicle switcher + Add Vehicle + Settings + Empty state + Widget + Pro

function AddReading({ theme, accent, vehicle, onBack }) {
  const [value, setValue] = React.useState((vehicle.currentOnPace + 240).toString());
  const [date, setDate] = React.useState('Today · Apr 17');
  return (
    <div style={{ width: SCREEN_W, height: SCREEN_H, background: theme.bg, color: theme.text, fontFamily: SANS, position: 'relative', overflow: 'hidden' }}>
      <StatusBar theme={theme} />
      <NavBar theme={theme} title="Add Reading" onBack={onBack} />

      <div style={{ padding: '8px 24px 0' }}>
        <div style={{ fontSize: 11, color: theme.dim, letterSpacing: 1.5, textTransform: 'uppercase', marginBottom: 8 }}>Odometer</div>
        <div style={{
          background: theme.panel, border: `1px solid ${theme.hairline}`,
          borderRadius: 16, padding: '20px 18px',
        }}>
          <div style={{
            fontFamily: MONO, fontSize: 48, fontWeight: 500,
            letterSpacing: -1.5, color: theme.text,
            fontFeatureSettings: '"tnum"',
          }}>{fmt(parseInt(value) || 0)} <span style={{ fontSize: 18, color: theme.dim }}>mi</span></div>
          <div style={{ height: 1, background: theme.hairline, margin: '14px 0' }} />
          <div style={{ fontSize: 12, color: theme.dim }}>Last reading · <span style={{ fontFamily: MONO, color: theme.text }}>{fmt(vehicle.currentOnPace)} mi</span> · 3 days ago</div>
        </div>

        <div style={{ fontSize: 11, color: theme.dim, letterSpacing: 1.5, textTransform: 'uppercase', marginTop: 22, marginBottom: 8 }}>Date</div>
        <button style={{
          width: '100%', textAlign: 'left',
          background: theme.panel, border: `1px solid ${theme.hairline}`,
          borderRadius: 16, padding: '16px 18px',
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          color: theme.text, fontSize: 15, cursor: 'pointer',
        }}>
          <span>{date}</span>
          <Icon name="calendar" size={18} color={theme.dim} />
        </button>

        <div style={{
          marginTop: 22, padding: 16,
          background: accent.soft, borderRadius: 16,
          display: 'flex', gap: 12, alignItems: 'flex-start',
        }}>
          <Icon name="info" size={18} color={accent.main} />
          <div style={{ fontSize: 12, color: theme.text, lineHeight: 1.4 }}>
            <strong style={{ color: accent.main }}>+240 mi</strong> since last reading, 3 days ago. That's <strong>80 mi/day</strong> — a bit above your 42 avg.
          </div>
        </div>
      </div>

      {/* Number pad */}
      <div style={{ position: 'absolute', left: 0, right: 0, bottom: 88, padding: '0 18px' }}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
          {['1','2','3','4','5','6','7','8','9','.','0','⌫'].map((k) => (
            <button key={k} onClick={() => {
              if (k === '⌫') setValue(v => v.slice(0, -1));
              else if (k === '.') return;
              else setValue(v => v + k);
            }} style={{
              height: 48, background: theme.panel,
              border: `1px solid ${theme.hairline}`,
              borderRadius: 12,
              fontFamily: MONO, fontSize: 20, fontWeight: 500, color: theme.text,
              cursor: 'pointer',
            }}>{k}</button>
          ))}
        </div>
      </div>

      <div style={{ position: 'absolute', left: 20, right: 20, bottom: 34 }}>
        <button onClick={onBack} style={{
          width: '100%', height: 50,
          background: accent.main, color: accent.text,
          border: 'none', borderRadius: 25,
          fontSize: 15, fontWeight: 600, cursor: 'pointer',
        }}>Save Reading</button>
      </div>
      <HomeIndicator theme={theme} />
    </div>
  );
}

function VehicleSwitcher({ theme, accent, vehicles, currentId, onPick, onBack, onAdd }) {
  return (
    <div style={{ width: SCREEN_W, height: SCREEN_H, background: theme.bg, color: theme.text, fontFamily: SANS, position: 'relative', overflow: 'hidden' }}>
      <StatusBar theme={theme} />
      <NavBar theme={theme} title="Garage" onBack={onBack} />
      <div style={{ padding: '8px 20px 0' }}>
        <div style={{ fontSize: 11, color: theme.dim, letterSpacing: 1.5, textTransform: 'uppercase', marginBottom: 12 }}>Your vehicles ({vehicles.length})</div>
        {vehicles.map(v => (
          <button key={v.id} onClick={() => onPick(v.id)} style={{
            display: 'block', width: '100%', textAlign: 'left',
            background: v.id === currentId ? accent.soft : theme.panel,
            border: `1px solid ${v.id === currentId ? accent.main : theme.hairline}`,
            borderRadius: 18, padding: '16px 18px',
            marginBottom: 10, cursor: 'pointer', color: theme.text,
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ display: 'flex', gap: 14, alignItems: 'center' }}>
                <div style={{
                  width: 42, height: 42, borderRadius: 10,
                  background: v.id === currentId ? accent.main : theme.bg,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontFamily: MONO, fontSize: 12, fontWeight: 700,
                  color: v.id === currentId ? accent.text : theme.text,
                  border: `1px solid ${theme.hairline}`,
                }}>{v.name.split(' ').map(w => w[0]).join('').slice(0,2)}</div>
                <div>
                  <div style={{ fontSize: 15, fontWeight: 600 }}>{v.name}</div>
                  <div style={{ fontSize: 12, color: theme.dim, marginTop: 2 }}>{v.subtitle} · {fmt(v.allowed)} mi/{v.lengthOfLease}mo</div>
                </div>
              </div>
              {v.id === currentId && <Icon name="check" size={18} color={accent.main} />}
            </div>
          </button>
        ))}
        <button onClick={onAdd} style={{
          width: '100%', padding: '16px 18px',
          background: 'transparent',
          border: `1.5px dashed ${theme.hairlineStrong}`,
          borderRadius: 18, color: theme.text,
          fontSize: 14, fontWeight: 500, cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        }}>
          <Icon name="plus" size={16} color={theme.text} stroke={2} />
          Add another vehicle
        </button>
      </div>
      <HomeIndicator theme={theme} />
    </div>
  );
}

function AddVehicle({ theme, accent, onBack }) {
  const [name, setName] = React.useState('');
  const [allowed, setAllowed] = React.useState('36000');
  const [months, setMonths] = React.useState('36');
  return (
    <div style={{ width: SCREEN_W, height: SCREEN_H, background: theme.bg, color: theme.text, fontFamily: SANS, position: 'relative', overflow: 'hidden' }}>
      <StatusBar theme={theme} />
      <NavBar theme={theme} title="New Vehicle" onBack={onBack} />
      <div style={{ padding: '12px 24px 0', overflowY: 'auto' }}>
        <div style={{
          padding: '20px', background: theme.panel,
          border: `1px solid ${theme.hairline}`, borderRadius: 20,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          height: 130, marginBottom: 20,
        }}>
          <div style={{ textAlign: 'center' }}>
            <Icon name="car" size={40} color={theme.dim} />
            <div style={{ fontSize: 11, color: theme.dim, marginTop: 6, letterSpacing: 1, fontFamily: MONO }}>ADD PHOTO</div>
          </div>
        </div>
        <Field theme={theme} label="NAME" value={name} onChange={setName} placeholder="e.g. Model 3" />
        <Field theme={theme} label="MILEAGE ALLOWED" value={allowed} onChange={setAllowed} unit="mi" mono />
        <Field theme={theme} label="LEASE LENGTH" value={months} onChange={setMonths} unit="months" mono />
        <Field theme={theme} label="STARTING ODOMETER" value="12" unit="mi" mono disabled />
        <Field theme={theme} label="START DATE" value="Mar 14, 2024" disabled />
      </div>
      <div style={{ position: 'absolute', left: 20, right: 20, bottom: 34 }}>
        <button onClick={onBack} style={{
          width: '100%', height: 50,
          background: accent.main, color: accent.text,
          border: 'none', borderRadius: 25,
          fontSize: 15, fontWeight: 600, cursor: 'pointer',
        }}>Add Vehicle</button>
      </div>
      <HomeIndicator theme={theme} />
    </div>
  );
}

function Field({ theme, label, value, onChange, placeholder, unit, mono, disabled }) {
  return (
    <div style={{ marginBottom: 14 }}>
      <div style={{ fontSize: 10, color: theme.dim, letterSpacing: 1.5, marginBottom: 6 }}>{label}</div>
      <div style={{
        display: 'flex', alignItems: 'center',
        background: theme.panel, border: `1px solid ${theme.hairline}`,
        borderRadius: 14, padding: '12px 16px', gap: 8,
        opacity: disabled ? 0.6 : 1,
      }}>
        <input
          value={value}
          onChange={onChange ? (e) => onChange(e.target.value) : undefined}
          placeholder={placeholder}
          readOnly={disabled || !onChange}
          style={{
            flex: 1, background: 'transparent', border: 'none', outline: 'none',
            color: theme.text, fontSize: 15,
            fontFamily: mono ? MONO : SANS,
            fontFeatureSettings: mono ? '"tnum"' : 'normal',
          }}
        />
        {unit && <div style={{ fontSize: 12, color: theme.dim, fontFamily: MONO }}>{unit}</div>}
      </div>
    </div>
  );
}

function Settings({ theme, accent, onBack }) {
  return (
    <div style={{ width: SCREEN_W, height: SCREEN_H, background: theme.bg, color: theme.text, fontFamily: SANS, position: 'relative', overflow: 'hidden' }}>
      <StatusBar theme={theme} />
      <NavBar theme={theme} title="Settings" onBack={onBack} />
      <div style={{ padding: '8px 20px 0' }}>
        <SettingsGroup theme={theme} title="GENERAL" items={[
          { icon: 'sun', label: 'Appearance', value: 'System' },
          { icon: 'chart', label: 'Units', value: 'Miles' },
          { icon: 'calendar', label: 'Currency', value: 'USD' },
        ]} />
        <SettingsGroup theme={theme} title="NOTIFICATIONS" items={[
          { icon: 'alert', label: 'Weekly summary', toggle: true, on: true, accent },
          { icon: 'bolt', label: 'Over-pace alerts', toggle: true, on: true, accent },
        ]} />
        <SettingsGroup theme={theme} title="PRO" items={[
          { icon: 'trend-up', label: 'Upgrade to Pro', chev: true, highlight: true, accent },
        ]} />
        <div style={{
          padding: '20px 4px', fontSize: 11, color: theme.dim,
          textAlign: 'center', fontFamily: MONO, letterSpacing: 0.5,
        }}>Leastimator · v2.0 · 2026</div>
      </div>
      <HomeIndicator theme={theme} />
    </div>
  );
}

function SettingsGroup({ theme, title, items }) {
  return (
    <div style={{ marginBottom: 24 }}>
      <div style={{ fontSize: 10, color: theme.dim, letterSpacing: 1.5, marginBottom: 8, paddingLeft: 6 }}>{title}</div>
      <div style={{ background: theme.panel, border: `1px solid ${theme.hairline}`, borderRadius: 16, overflow: 'hidden' }}>
        {items.map((it, i) => (
          <div key={i} style={{
            display: 'flex', alignItems: 'center', padding: '14px 16px',
            borderBottom: i < items.length - 1 ? `1px solid ${theme.hairline}` : 'none',
            gap: 12,
          }}>
            <Icon name={it.icon} size={18} color={it.highlight ? it.accent.main : theme.dim} />
            <div style={{ flex: 1, fontSize: 14, color: it.highlight ? it.accent.main : theme.text, fontWeight: it.highlight ? 600 : 400 }}>{it.label}</div>
            {it.value && <div style={{ fontSize: 13, color: theme.dim, fontFamily: MONO }}>{it.value}</div>}
            {it.toggle && (
              <div style={{
                width: 40, height: 24, borderRadius: 12,
                background: it.on ? it.accent.main : theme.hairlineStrong,
                position: 'relative', transition: 'all 0.2s',
              }}>
                <div style={{
                  width: 20, height: 20, borderRadius: 10,
                  background: '#fff', position: 'absolute', top: 2,
                  left: it.on ? 18 : 2, transition: 'all 0.2s',
                }} />
              </div>
            )}
            {it.chev && <Icon name="chev-r" size={16} color={it.highlight ? it.accent.main : theme.dim} />}
          </div>
        ))}
      </div>
    </div>
  );
}

function EmptyState({ theme, accent, onAdd }) {
  return (
    <div style={{ width: SCREEN_W, height: SCREEN_H, background: theme.bg, color: theme.text, fontFamily: SANS, position: 'relative', overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
      <StatusBar theme={theme} />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '0 32px', textAlign: 'center' }}>
        <div style={{
          width: 160, height: 160, borderRadius: 80,
          background: `radial-gradient(circle at 50% 50%, ${accent.soft}, transparent 70%)`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          marginBottom: 28,
        }}>
          <div style={{
            width: 88, height: 88, borderRadius: 44,
            background: theme.panel, border: `1px solid ${theme.hairline}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name="car" size={44} color={accent.main} stroke={1.5} />
          </div>
        </div>
        <div style={{ fontSize: 24, fontWeight: 600, letterSpacing: -0.5, marginBottom: 8 }}>Track your first lease</div>
        <div style={{ fontSize: 14, color: theme.dim, lineHeight: 1.5, maxWidth: 280, marginBottom: 32 }}>
          Add your vehicle and a few odometer readings. We'll project your end-of-lease mileage and coach you to stay on track.
        </div>
        <button onClick={onAdd} style={{
          padding: '14px 28px',
          background: accent.main, color: accent.text,
          border: 'none', borderRadius: 25,
          fontSize: 15, fontWeight: 600, cursor: 'pointer',
          display: 'flex', alignItems: 'center', gap: 8,
          boxShadow: `0 0 30px ${accent.soft}`,
        }}>
          <Icon name="plus" size={16} color={accent.text} stroke={2.5} />
          Add a vehicle
        </button>
      </div>
      <HomeIndicator theme={theme} />
    </div>
  );
}

function Widget({ theme, accent, danger }) {
  const v = vehiclesData[0];
  const current = danger ? v.currentOverPace : v.currentOnPace;
  const mileagePerDay = (current - v.starting) / 399;
  const projected = Math.round(v.starting + 365 * 3 * mileagePerDay);
  const variance = projected - v.starting - v.allowed;
  const progress = (projected - v.starting) / v.allowed;
  const p = Math.min(progress, 1);
  const color = progress >= 1 ? theme.danger : accent.main;
  const stroke = 8, r = 32, c = 2 * Math.PI * r;

  return (
    <div style={{
      width: 170, height: 170,
      background: theme.bg,
      borderRadius: 22,
      border: `1px solid ${theme.hairline}`,
      padding: 14,
      fontFamily: SANS, color: theme.text,
      boxShadow: '0 10px 40px rgba(0,0,0,0.3)',
      display: 'flex', flexDirection: 'column',
      position: 'relative',
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div>
          <div style={{ fontSize: 9, color: theme.dim, letterSpacing: 1.5, textTransform: 'uppercase' }}>Projected</div>
          <div style={{ fontFamily: MONO, fontSize: 22, fontWeight: 500, letterSpacing: -0.5, fontFeatureSettings: '"tnum"' }}>{fmt(projected)}</div>
        </div>
        <svg width="74" height="74">
          <circle cx="37" cy="37" r={r} stroke={theme.hairline} strokeWidth={stroke} fill="none" />
          <circle cx="37" cy="37" r={r} stroke={color} strokeWidth={stroke} fill="none"
            strokeDasharray={`${c * p} ${c}`}
            transform="rotate(-90 37 37)" strokeLinecap="round" />
        </svg>
      </div>
      <div style={{ flex: 1 }} />
      <div>
        <div style={{ fontSize: 10, color: theme.dim, letterSpacing: 1, marginBottom: 2 }}>{v.name}</div>
        <div style={{
          fontFamily: MONO, fontSize: 12, fontWeight: 500,
          color: variance < 0 ? accent.main : theme.danger,
          fontFeatureSettings: '"tnum"',
        }}>{fmtSigned(variance)} mi vs limit</div>
      </div>
    </div>
  );
}

function ProScreen({ theme, accent, onBack }) {
  const features = [
    { icon: 'car', title: 'Unlimited vehicles', sub: 'Track every lease, no caps.' },
    { icon: 'trend-up', title: 'Advanced insights', sub: 'Seasonal patterns, budgets, forecasts.' },
    { icon: 'bolt', title: 'Tesla auto-sync', sub: 'Readings pull automatically.' },
    { icon: 'chart', title: 'Unlimited history', sub: 'Export to CSV, keep forever.' },
  ];
  return (
    <div style={{ width: SCREEN_W, height: SCREEN_H, background: theme.bg, color: theme.text, fontFamily: SANS, position: 'relative', overflow: 'hidden' }}>
      <StatusBar theme={theme} />
      <NavBar theme={theme} title="" onBack={onBack} right={<button style={{background: 'none', border: 'none', color: theme.dim, fontSize: 13, cursor: 'pointer'}}>Restore</button>} />
      <div style={{ padding: '0 28px 0' }}>
        <div style={{
          fontSize: 11, letterSpacing: 2, color: accent.main,
          fontFamily: MONO, fontWeight: 600, marginBottom: 10,
        }}>LEASTIMATOR · PRO</div>
        <div style={{ fontSize: 30, fontWeight: 600, letterSpacing: -0.8, lineHeight: 1.1, marginBottom: 24 }}>
          Stay ahead of every mile.
        </div>
        {features.map((f, i) => (
          <div key={i} style={{ display: 'flex', gap: 14, alignItems: 'flex-start', marginBottom: 16 }}>
            <div style={{
              width: 36, height: 36, borderRadius: 10,
              background: accent.soft,
              display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
            }}>
              <Icon name={f.icon} size={18} color={accent.main} />
            </div>
            <div>
              <div style={{ fontSize: 14, fontWeight: 600 }}>{f.title}</div>
              <div style={{ fontSize: 12, color: theme.dim, marginTop: 2 }}>{f.sub}</div>
            </div>
          </div>
        ))}
      </div>
      <div style={{ position: 'absolute', left: 20, right: 20, bottom: 34 }}>
        <div style={{
          padding: '14px 18px', background: theme.panel,
          border: `1px solid ${accent.main}`, borderRadius: 20,
          display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10,
        }}>
          <div>
            <div style={{ fontSize: 14, fontWeight: 600 }}>Annual</div>
            <div style={{ fontSize: 11, color: theme.dim, marginTop: 2 }}>$14.99/year · save 40%</div>
          </div>
          <div style={{ fontFamily: MONO, fontSize: 16, color: accent.main }}>$14.99</div>
        </div>
        <button onClick={onBack} style={{
          width: '100%', height: 52,
          background: accent.main, color: accent.text,
          border: 'none', borderRadius: 26,
          fontSize: 15, fontWeight: 600, cursor: 'pointer',
        }}>Start 7-day free trial</button>
      </div>
      <HomeIndicator theme={theme} />
    </div>
  );
}

Object.assign(window, { AddReading, VehicleSwitcher, AddVehicle, Settings, EmptyState, Widget, ProScreen });
