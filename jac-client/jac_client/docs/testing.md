# Testing jac-client Applications

This guide covers testing strategies for jac-client applications, including both Python-based backend tests and JavaScript-based client-side tests.

## Overview

jac-client applications have two testable layers:

| Layer | Framework | File Extension | Command |
|-------|-----------|----------------|---------|
| Backend (walkers, pure functions) | pytest via `jac test` | `.test.jac` | `jac test <file>` |
| Frontend (cl blocks, components) | Vitest | `.test.js` | `npm test` |

## Backend Testing with `jac test`

The `test` keyword in Jac compiles to Python unittest, so it can test:
- Walkers
- Nodes
- Pure functions defined **outside** `cl` blocks

### Basic Test Structure

```jac
# main.test.jac
import from main { validateCredentials, MyWalker }

test test_valid_input {
    result = validateCredentials("alice", "secret123");
    assert result == "";
}

test test_invalid_input {
    result = validateCredentials("", "");
    assert "fill in" in result;
}
```

Run with:
```bash
jac test main.test.jac
```

### Testing Walkers

```jac
# app.test.jac
test test_create_todo_walker {
    with entry {
        result = root spawn create_todo(text="Buy milk");
        assert len(result.reports) > 0;
        todo = result.reports[0];
        assert todo.text == "Buy milk";
        assert todo.done == False;
    }
}
```

## Client-side Testing with Vitest

Functions inside `cl` blocks compile to JavaScript and need JavaScript testing.

### Setup

1. **Install dependencies**:
```bash
npm install --save-dev vitest @testing-library/react @testing-library/jest-dom jsdom @vitejs/plugin-react
```

2. **Create vitest.config.js**:
```javascript
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    setupFiles: ['./vitest.setup.js'],
    include: ['**/*.test.js', '.jac/client/compiled/**/*.test.js'],
    globals: true
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, '.jac/client/compiled')
    }
  }
});
```

3. **Create vitest.setup.js**:
```javascript
import '@testing-library/jest-dom';

// Mock localStorage
const localStorageMock = {
  store: {},
  getItem(key) { return this.store[key] || null; },
  setItem(key, value) { this.store[key] = value.toString(); },
  removeItem(key) { delete this.store[key]; },
  clear() { this.store = {}; }
};
global.localStorage = localStorageMock;

// Mock __jacSpawn for walker calls
global.__jacSpawn = vi.fn().mockResolvedValue({ reports: [], data: null });

// Reset between tests
beforeEach(() => {
  vi.clearAllMocks();
  localStorageMock.clear();
});
```

4. **Add test script to package.json**:
```json
{
  "scripts": {
    "test": "vitest",
    "test:coverage": "vitest --coverage"
  }
}
```

### Testing Pure Client Functions

```javascript
// client.test.js
import { describe, it, expect } from 'vitest';
import { filterTodos, formatDate } from './.jac/client/compiled/main.js';

describe('filterTodos', () => {
  const todos = [
    { _jac_id: '1', text: 'Buy milk', done: false },
    { _jac_id: '2', text: 'Walk dog', done: true },
  ];

  it('returns all todos for "all" filter', () => {
    expect(filterTodos(todos, 'all')).toHaveLength(2);
  });

  it('returns active todos only', () => {
    const result = filterTodos(todos, 'active');
    expect(result).toHaveLength(1);
    expect(result[0].done).toBe(false);
  });

  it('returns completed todos only', () => {
    const result = filterTodos(todos, 'completed');
    expect(result).toHaveLength(1);
    expect(result[0].done).toBe(true);
  });
});
```

### Testing Components

```javascript
import { describe, it, expect } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import React from 'react';
import { TodoApp } from './.jac/client/compiled/main.js';

describe('TodoApp', () => {
  it('renders the title', () => {
    render(<TodoApp />);
    expect(screen.getByText('Todo App')).toBeInTheDocument();
  });

  it('allows entering a new todo', () => {
    render(<TodoApp />);
    const input = screen.getByPlaceholderText('Add todo...');
    fireEvent.change(input, { target: { value: 'New task' } });
    expect(input.value).toBe('New task');
  });
});
```

### Mocking Walker Calls

```javascript
import { describe, it, expect, vi, beforeEach } from 'vitest';

describe('Walker Integration', () => {
  beforeEach(() => {
    global.__jacSpawn = vi.fn();
  });

  it('calls create_todo walker', async () => {
    const mockTodo = { _jac_id: '123', text: 'Test', done: false };
    global.__jacSpawn.mockResolvedValue({ reports: [[mockTodo]] });

    const result = await global.__jacSpawn('create_todo', '', { text: 'Test' });

    expect(global.__jacSpawn).toHaveBeenCalledWith('create_todo', '', { text: 'Test' });
    expect(result.reports[0][0].text).toBe('Test');
  });

  it('handles walker errors', async () => {
    global.__jacSpawn.mockRejectedValue(new Error('Walker failed'));

    await expect(global.__jacSpawn('bad_walker', '', {})).rejects.toThrow('Walker failed');
  });
});
```

### Testing with React Query Hooks

```javascript
import { describe, it, expect, vi } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import React from 'react';

// Create wrapper with QueryClient
const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } }
  });
  return ({ children }) => (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  );
};

describe('useReadTodos hook', () => {
  it('fetches todos', async () => {
    const mockTodos = [{ _jac_id: '1', text: 'Test', done: false }];
    global.__jacSpawn.mockResolvedValue({ reports: mockTodos });

    // Import the generated hook
    const { useReadTodos } = await import('./.jac/client/compiled/generated_hooks.js');

    const { result } = renderHook(() => useReadTodos(), {
      wrapper: createWrapper()
    });

    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(result.current.data).toEqual(mockTodos);
  });
});
```

## Best Practices

### 1. Separate Pure Logic

Put testable logic outside `cl` blocks when possible:

```jac
# GOOD: Testable with jac test
def:pub validateEmail(email: str) -> bool {
    return "@" in email and "." in email;
}

cl {
    # Uses the pure function
    def SignupForm() -> any {
        [email, setEmail] = useState("");
        isValid = validateEmail(email);
        return <form>...</form>;
    }
}
```

### 2. Export Functions for Testing

Use `def:pub` to make functions exportable:

```jac
cl {
    def:pub filterTodos(todos: list, filter: str) -> list {
        # ...
    }
}
```

### 3. Mock External Dependencies

Always mock:
- `__jacSpawn` (walker calls)
- `localStorage`
- `fetch` (API calls)
- `window.location`

### 4. Test Behavior, Not Implementation

```javascript
// GOOD: Tests behavior
it('filters active todos', () => {
  const result = filterTodos(todos, 'active');
  expect(result.every(t => !t.done)).toBe(true);
});

// BAD: Tests implementation
it('uses array filter method', () => {
  // Don't test internal implementation details
});
```

### 5. Keep Tests Fast

```javascript
// Mock slow operations
beforeEach(() => {
  vi.useFakeTimers();
});

afterEach(() => {
  vi.useRealTimers();
});
```

## Running Tests

```bash
# Backend tests
jac test main.test.jac

# Client tests
npm test

# Watch mode
npm test -- --watch

# Coverage report
npm test -- --coverage

# Run specific test
npm test -- filterTodos
```

## Example Project Structure

```
my-app/
├── main.jac              # Application code
├── main.test.jac         # Python/backend tests
├── client.test.js        # JavaScript/client tests
├── vitest.config.js      # Vitest configuration
├── vitest.setup.js       # Test setup/mocks
├── package.json          # With test scripts
├── jac.toml             # Jac config
└── .jac/
    └── client/
        └── compiled/     # Compiled JS (import in tests)
            ├── main.js
            └── generated_hooks.js
```

## Troubleshooting

### "Cannot find module" errors
- Make sure you've compiled with `jac start main.jac` first
- Check the path to `.jac/client/compiled/`

### Tests don't see latest changes
- Recompile the jac code before running tests
- Clear Vitest cache: `npm test -- --clearCache`

### React hooks errors in tests
- Ensure `jsdom` environment is set in vitest.config.js
- Wrap components with necessary providers (QueryClientProvider, etc.)

### Mock not working
- Check that mocks are set up in `beforeEach`
- Verify mock is cleared between tests
