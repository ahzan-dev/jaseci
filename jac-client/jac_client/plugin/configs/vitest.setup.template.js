/**
 * Vitest setup file for jac-client projects.
 * This file runs before each test.
 */
import '@testing-library/jest-dom';

// Mock localStorage
const localStorageMock = {
  store: {},
  getItem(key) {
    return this.store[key] || null;
  },
  setItem(key, value) {
    this.store[key] = value.toString();
  },
  removeItem(key) {
    delete this.store[key];
  },
  clear() {
    this.store = {};
  }
};
global.localStorage = localStorageMock;

// Mock fetch for walker calls
global.fetch = vi.fn();

// Reset mocks between tests
beforeEach(() => {
  vi.clearAllMocks();
  localStorageMock.clear();
});

// Mock __jacSpawn for testing walkers
global.__jacSpawn = vi.fn().mockImplementation(async (walkerName, targetId, fields) => {
  // Default mock implementation - override in tests
  return { reports: [], data: null };
});

// Mock console methods for cleaner test output
global.console = {
  ...console,
  log: vi.fn(),
  warn: vi.fn(),
  error: vi.fn()
};
