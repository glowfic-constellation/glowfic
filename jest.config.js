// Jest config for the app's vanilla/jQuery JavaScript.
// Files are transformed with SWC (fast, no Babel config) and run under jsdom
// so DOM-touching helpers and Testing Library work out of the box.
module.exports = {
  testEnvironment: 'jsdom',
  roots: ['<rootDir>/spec/javascript'],
  testMatch: ['**/*.test.js'],
  setupFiles: ['<rootDir>/spec/javascript/jest.setup.js'],
  transform: {
    '^.+\\.js$': ['@swc/jest'],
  },
};
