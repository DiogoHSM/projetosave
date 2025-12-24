import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        // Cores principais do design system SAVE
        save: {
          blue: {
            DEFAULT: '#2563eb', // Seguir - início, chamado, base, confiança
            light: '#3b82f6',
            dark: '#1e40af',
          },
          orange: {
            DEFAULT: '#f97316', // Aprender - crescimento, conhecimento, atenção
            light: '#fb923c',
            dark: '#ea580c',
          },
          green: {
            DEFAULT: '#22c55e', // Viver - prática, vida cristã, amadurecimento
            light: '#4ade80',
            dark: '#16a34a',
          },
          purple: {
            DEFAULT: '#a855f7', // Ensinar - liderança, maturidade, multiplicação
            light: '#c084fc',
            dark: '#9333ea',
          },
        },
        // Cor primária do sistema (usar uma das cores acima como primária)
        primary: {
          DEFAULT: '#2563eb', // Azul como padrão
          light: '#3b82f6',
          dark: '#1e40af',
        },
      },
      fontFamily: {
        sans: ['var(--font-inter)', 'system-ui', 'sans-serif'],
      },
      spacing: {
        '18': '4.5rem',
        '88': '22rem',
      },
    },
  },
  plugins: [],
}
export default config

