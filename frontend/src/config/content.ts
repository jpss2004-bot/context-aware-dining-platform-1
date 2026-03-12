export const brandContent = {
  productName: 'SAVR',
  tagline: 'Savor Every Experience',
  strapline: 'Context-aware dining, curated for the night you want.',
  nav: [
    { to: '/dashboard', label: 'Home', short: 'HM' },
    { to: '/onboarding', label: 'Taste Profile', short: 'TP' },
    { to: '/recommendations', label: 'Curated Matches', short: 'CM' },
    { to: '/restaurants', label: 'Venue Guide', short: 'VG' },
    { to: '/experiences', label: 'SAVR Log', short: 'SL' }
  ],
  routeMeta: {
    '/dashboard': {
      eyebrow: 'Home',
      title: 'Your SAVR command table',
      subtitle: 'See what is ready, refresh your taste profile, and launch curated matches without losing any existing workflows.'
    },
    '/onboarding': {
      eyebrow: 'Taste Profile',
      title: 'Teach SAVR your taste',
      subtitle: 'Capture cuisines, pace, atmosphere, and drink preferences so every curated match feels more intentional.'
    },
    '/recommendations': {
      eyebrow: 'Curated Matches',
      title: 'Build the night worth savoring',
      subtitle: 'Use guided blocks, natural language, or surprise mode to surface restaurants that fit the exact experience you want.'
    },
    '/restaurants': {
      eyebrow: 'Venue Guide',
      title: 'Browse the SAVR venue guide',
      subtitle: 'Compare restaurants, menu signals, atmosphere, and pace in one clear research surface.'
    },
    '/experiences': {
      eyebrow: 'SAVR Log',
      title: 'Save the meals that shaped your taste',
      subtitle: 'Log memorable outings so the platform can learn what felt right and what you want more of later.'
    }
  },
  microcopy: {
    loginTitle: 'Welcome back to SAVR',
    loginSubtitle: 'Sign in to reopen your taste profile, curated matches, venue guide, and saved nights.',
    registerTitle: 'Create your SAVR profile',
    registerSubtitle: 'Start a profile that remembers your preferences, your favorite venues, and the experiences you want to repeat.',
    authFeatures: ['Curated matches', 'Venue discovery', 'Saved dining memories'],
    emptyRecommendations: 'No curated matches yet. Refine the night and ask SAVR again.',
    saveExperienceSuccess: 'Your SAVR Log entry was saved.',
    onboardingSuccess: 'Your taste profile is updated and ready to guide new matches.'
  }
} as const;

export const productLanguageRows = [
  ['Dashboard', 'Home', 'Sidebar navigation'],
  ['Onboarding', 'Taste Profile', 'Sidebar navigation / page heading'],
  ['Recommendations', 'Curated Matches', 'Sidebar navigation / page heading'],
  ['Restaurants', 'Venue Guide', 'Sidebar navigation / page heading'],
  ['Experiences', 'SAVR Log', 'Sidebar navigation / page heading'],
  ['Dining experiences', 'SAVR Log', 'Experiences page'],
  ['Restaurant library', 'Venue Guide', 'Restaurants page'],
  ['Product overview', 'SAVR overview', 'Dashboard hero'],
  ['Open recommendation studio', 'Open Curated Matches', 'Dashboard CTA'],
  ['Update onboarding', 'Refine Taste Profile', 'Dashboard CTA'],
  ['Generate recommendations', 'Generate curated matches', 'Dashboard CTA'],
  ['Login', 'Enter SAVR', 'Login button'],
  ['Register', 'Create SAVR profile', 'Register button'],
  ['Experience saved successfully.', 'Your SAVR Log entry was saved.', 'Experience form success state'],
  ['Failed to load restaurants', 'We could not load the venue guide.', 'Restaurants error state']
] as const;
