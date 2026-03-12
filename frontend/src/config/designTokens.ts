export const designTokens = {
  colors: {
    wine: '#781E5A',
    wineSoft: '#9C476B',
    cream: '#F6F1EB',
    olive: '#6F7559',
    charcoal: '#282828',
    gold: '#C9A247',
    blush: '#C98B86',
    line: 'rgba(120, 30, 90, 0.14)',
    lineStrong: 'rgba(120, 30, 90, 0.22)'
  },
  typography: {
    display: 'Cormorant Garamond, Georgia, serif',
    body: 'Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif'
  },
  radius: {
    sm: '12px',
    md: '18px',
    lg: '24px',
    pill: '999px'
  },
  shadow: {
    soft: '0 14px 36px rgba(60, 38, 29, 0.08)',
    medium: '0 20px 48px rgba(60, 38, 29, 0.12)',
    glow: '0 20px 40px rgba(120, 30, 90, 0.18)'
  },
  spacing: {
    xs: '0.5rem',
    sm: '0.75rem',
    md: '1rem',
    lg: '1.5rem',
    xl: '2rem',
    xxl: '3rem'
  }
} as const;

export type DesignTokens = typeof designTokens;
