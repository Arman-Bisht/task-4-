module.exports = {
  testEnvironment: 'node',
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/**/*.test.js',
    '!**/node_modules/**'
  ],
  coverageDirectory: 'coverage',
  coverageReporters: [
    'text',
    'lcov',
    'html'
  ],
  testMatch: [
    '**/tests/**/*.test.js',
    '**/__tests__/**/*.js',
    '**/?(*.)+(spec|test).js'
  ],
  verbose: true,
  collectCoverage: true,
  coverageThreshold: {
    global: {
      branches: 20,
      functions: 30,
      lines: 50,
      statements: 50
    }
  },
  forceExit: true,
  detectOpenHandles: true
};