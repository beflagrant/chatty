module.exports = {
  darkMode: false, // or 'media' or 'class'
  theme: {
    extend: {
      colors: {
        'primary': '#D6D3D1',
        'sky': '#D9F1FF',
        'purple': '#F3E8FF',
        'beige': '#E7E5E4',
      },
      width: {
        'fit':'fit-content',
      },
    },
  },
  variants: {
    extend: {},
  },
  plugins: [
    // require('@tailwindcss/custom-forms')
  ],
}
