// Tweaks panel — floats bottom-right when Tweaks mode is on.

function TweaksPanel({ visible, tweaks, onChange }) {
  if (!visible) return null;
  const Row = ({ label, children }) => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6, marginBottom: 12 }}>
      <div style={{ fontSize: 10, color: '#888', letterSpacing: 1.2, textTransform: 'uppercase', fontFamily: MONO }}>{label}</div>
      {children}
    </div>
  );
  const Pills = ({ options, value, onPick, renderOption }) => (
    <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
      {options.map(o => (
        <button key={o.id} onClick={() => onPick(o.id)} style={{
          padding: '6px 10px',
          background: o.id === value ? '#c6ff3a' : '#1a1a1e',
          color: o.id === value ? '#000' : '#eee',
          border: '1px solid ' + (o.id === value ? '#c6ff3a' : '#2a2a30'),
          borderRadius: 14, fontSize: 11, fontWeight: 500,
          fontFamily: SANS, cursor: 'pointer',
          display: 'flex', alignItems: 'center', gap: 5,
        }}>
          {renderOption ? renderOption(o) : o.label}
        </button>
      ))}
    </div>
  );
  return (
    <div style={{
      position: 'fixed', right: 20, bottom: 20,
      width: 280, padding: 16,
      background: '#0a0a0c', color: '#eee',
      border: '1px solid #2a2a30', borderRadius: 18,
      boxShadow: '0 20px 60px rgba(0,0,0,0.5)',
      fontFamily: SANS, zIndex: 1000,
    }}>
      <div style={{ fontSize: 12, fontWeight: 600, letterSpacing: 1, marginBottom: 14, fontFamily: MONO }}>TWEAKS</div>

      <Row label="Mode">
        <Pills options={[{id: false, label: 'On pace'}, {id: true, label: 'Over pace'}]}
          value={tweaks.danger} onPick={v => onChange({danger: v})} />
      </Row>
      <Row label="Theme">
        <Pills options={[{id: 'dark', label: 'Dark'}, {id: 'light', label: 'Light'}]}
          value={tweaks.theme} onPick={v => onChange({theme: v})} />
      </Row>
      <Row label="Accent">
        <Pills options={[
          {id: 'lime', label: 'Lime', color: '#c6ff3a'},
          {id: 'amber', label: 'Amber', color: '#ffb545'},
          {id: 'cyan', label: 'Cyan', color: '#5de2ff'},
          {id: 'red', label: 'Red', color: '#ff4d6d'},
        ]} value={tweaks.accent} onPick={v => onChange({accent: v})}
          renderOption={(o) => (<><span style={{width: 10, height: 10, borderRadius: 5, background: o.color, display: 'inline-block'}}/>{o.label}</>)} />
      </Row>
      <Row label="Gauge style">
        <Pills options={[{id: 'circular', label: 'Circular'}, {id: 'segmented', label: 'Segmented'}, {id: 'bar', label: 'Bar'}]}
          value={tweaks.gaugeStyle} onPick={v => onChange({gaugeStyle: v})} />
      </Row>
      <Row label="Copy tone">
        <Pills options={[{id: 'coach', label: 'Coach'}, {id: 'neutral', label: 'Neutral'}, {id: 'financial', label: 'Financial'}]}
          value={tweaks.copy} onPick={v => onChange({copy: v})} />
      </Row>
    </div>
  );
}

Object.assign(window, { TweaksPanel });
