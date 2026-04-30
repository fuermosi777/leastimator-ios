// Theme & shared data for Leastimator Direction 1 prototype
// Light + dark modes, accent swap, gauge-style swap, copy-tone swap

const ACCENTS = {
  lime: { main: '#c6ff3a', soft: 'rgba(198,255,58,0.18)', text: '#0a0a0c' },
  amber: { main: '#ffb545', soft: 'rgba(255,181,69,0.18)', text: '#1a120a' },
  cyan: { main: '#5de2ff', soft: 'rgba(93,226,255,0.18)', text: '#041218' },
  red: { main: '#ff4d6d', soft: 'rgba(255,77,109,0.18)', text: '#1a0a0e' },
};

const THEMES = {
  dark: {
    bg: '#060607',
    bgSoft: '#0c0c0e',
    panel: '#111114',
    panelHi: '#17171b',
    hairline: 'rgba(255,255,255,0.07)',
    hairlineStrong: 'rgba(255,255,255,0.12)',
    text: '#f4f4f6',
    dim: '#7a7a84',
    dimmer: '#4a4a52',
    warn: '#ffb545',
    danger: '#ff3a5e',
    dangerSoft: 'rgba(255,58,94,0.12)',
    dangerGlow: 'rgba(255,58,94,0.28)',
    pos: '#3dd980',
  },
  light: {
    bg: '#f5f5f3',
    bgSoft: '#ebebe8',
    panel: '#ffffff',
    panelHi: '#ffffff',
    hairline: 'rgba(10,10,12,0.08)',
    hairlineStrong: 'rgba(10,10,12,0.14)',
    text: '#0a0a0c',
    dim: '#7a7a84',
    dimmer: '#b0b0b6',
    warn: '#d48a00',
    danger: '#e0233f',
    dangerSoft: 'rgba(224,35,63,0.08)',
    dangerGlow: 'rgba(224,35,63,0.2)',
    pos: '#2a9458',
  },
};

const COPY = {
  coach: {
    onPace: { title: "Nice pace. You're on track.", sub: "Keep it up — plenty of headroom.", cta: "Add Reading" },
    overPace: { title: "Heads up — you're over pace.", sub: "Ease up a bit and you'll pull back in.", cta: "Add Reading" },
    todayPositive: (n) => `You can drive ~${n} mi today and stay on track.`,
    todayNegative: () => `Try not to drive today — you're already over.`,
  },
  neutral: {
    onPace: { title: "Under lease allowance", sub: "Projected to finish below limit.", cta: "Log reading" },
    overPace: { title: "Over lease allowance", sub: "Projected to exceed limit.", cta: "Log reading" },
    todayPositive: (n) => `${n} mi remaining for today.`,
    todayNegative: () => `Today's budget: 0 mi.`,
  },
  financial: {
    onPace: { title: "Saving at this rate.", sub: "Staying under avoids overage fees.", cta: "Add Reading" },
    overPace: { title: "+$1,313 projected overage.", sub: "Cut ~30 mi/day to break even.", cta: "Add Reading" },
    todayPositive: (n) => `${n} free miles today before fees kick in.`,
    todayNegative: () => `Every extra mile = $0.25 in fees.`,
  },
};

const MONO = '"JetBrains Mono", "SF Mono", ui-monospace, monospace';
const SANS = '"Inter", -apple-system, BlinkMacSystemFont, system-ui, sans-serif';

const SCREEN_W = 390;
const SCREEN_H = 844;

const vehiclesData = [
  {
    id: 'v1',
    name: 'Model 3',
    subtitle: 'Long Range · 2023',
    starting: 12,
    allowed: 36000,
    lengthOfLease: 36,
    startDate: 'Mar 14, 2024',
    endDate: 'Mar 14, 2027',
    currentOnPace: 11520,
    currentOverPace: 16850,
    fee: 0.25,
    color: '#dde4f0',
  },
  {
    id: 'v2',
    name: 'Mach-E',
    subtitle: 'Premium · 2024',
    starting: 8,
    allowed: 30000,
    lengthOfLease: 36,
    startDate: 'Aug 22, 2024',
    endDate: 'Aug 22, 2027',
    currentOnPace: 9400,
    currentOverPace: 13800,
    fee: 0.20,
    color: '#8fb2e8',
  },
];

// Sample history readings
const makeReadings = (starting, current, monthsSinceStart, seed = 1) => {
  const out = [];
  let last = starting;
  const targetTotal = current - starting;
  for (let i = 0; i < monthsSinceStart; i++) {
    const progress = (i + 1) / monthsSinceStart;
    const noise = (Math.sin(i * 1.3 + seed) * 0.15 + Math.cos(i * 0.7) * 0.1);
    last = starting + targetTotal * progress + targetTotal * noise * 0.15;
    out.push({
      month: i,
      value: Math.max(starting, Math.round(last)),
      date: new Date(2024, 2 + i, 14 + (i % 3)),
    });
  }
  out[out.length - 1].value = current;
  return out;
};

const fmt = (n) => new Intl.NumberFormat('en-US').format(Math.round(n));
const fmtSigned = (n) => (n >= 0 ? '+' : '−') + fmt(Math.abs(n));

Object.assign(window, {
  ACCENTS, THEMES, COPY, MONO, SANS,
  SCREEN_W, SCREEN_H,
  vehiclesData, makeReadings,
  fmt, fmtSigned,
});
