# Testing in jac-client

This example demonstrates how to test jac-client applications with both Python (jac test) and JavaScript (Vitest).

## Testing Strategy

jac-client apps have two types of testable code:

| Code Type | Location | Test Framework | Command |
|-----------|----------|----------------|---------|
| Backend walkers & pure functions | Outside `cl` blocks | `jac test` (Python/pytest) | `jac test main.test.jac` |
| Client-side functions & components | Inside `cl` blocks | Vitest (JavaScript) | `npm test` |

## Quick Start

### 1. Test Python/Backend Code

```bash
# Run jac tests (Python-based)
jac test main.test.jac
```

This tests:
- Walkers (create_todo, read_todos)
- Pure functions outside `cl` blocks (validateCredentials, formatTodoCount)

### 2. Test Client-side JavaScript Code

```bash
# First, compile the jac code
jac start main.jac

# Setup test environment (first time only)
npm install vitest @testing-library/react @testing-library/jest-dom jsdom @vitejs/plugin-react --save-dev

# Run JavaScript tests
npm test
```

This tests:
- Functions inside `cl` blocks (filterTodos, formatDate)
- React components with mocked walkers

## Project Structure

```
testing/
├── main.jac           # Application with testable code
├── main.test.jac      # Python tests (jac test)
├── client.test.js     # JavaScript tests (Vitest)
├── vitest.config.js   # Vitest configuration
├── vitest.setup.js    # Test setup (mocks)
├── package.json       # With test scripts
└── jac.toml          # Jac project config
```

## Key Principle: Separate Pure Logic

For maximum testability, put pure functions **outside** the `cl` block:

```jac
# TESTABLE with jac test (Python)
def:pub validateCredentials(username: str, password: str) -> str {
    if len(username) < 3 {
        return "Username too short";
    }
    return "";
}

cl {
    # TESTABLE with Vitest (JavaScript)
    def:pub filterTodos(todos: list, filter: str) -> list {
        if filter == "active" {
            return todos.filter(lambda t: any -> bool { return not t.done; });
        }
        return todos;
    }

    # Components use pure functions - testing is easier
    def TodoList() -> any {
        [filter, setFilter] = useState("all");
        filtered = filterTodos(todos, filter);  # Pure function!
        return <ul>{...}</ul>;
    }
}
```

## Writing Tests

### Python Tests (main.test.jac)

```jac
import from main { validateCredentials, formatTodoCount }

test test_valid_credentials {
    result = validateCredentials("alice", "password123");
    assert result == "";
}

test test_invalid_username {
    result = validateCredentials("ab", "password");
    assert "Username" in result;
}
```

### JavaScript Tests (client.test.js)

```javascript
import { describe, it, expect, vi, beforeEach } from 'vitest';

// Import compiled functions from .jac/client/compiled/
import { filterTodos, formatDate } from './.jac/client/compiled/main.js';

describe('filterTodos', () => {
  const todos = [
    { _jac_id: '1', text: 'Buy milk', done: false },
    { _jac_id: '2', text: 'Walk dog', done: true },
  ];

  it('filters active todos', () => {
    const result = filterTodos(todos, 'active');
    expect(result).toHaveLength(1);
    expect(result[0].text).toBe('Buy milk');
  });

  it('filters completed todos', () => {
    const result = filterTodos(todos, 'completed');
    expect(result).toHaveLength(1);
    expect(result[0].text).toBe('Walk dog');
  });
});
```

### Testing Walker Calls

```javascript
describe('Walker integration tests', () => {
  beforeEach(() => {
    // Mock __jacSpawn globally
    global.__jacSpawn = vi.fn();
  });

  it('mocks create_todo walker', async () => {
    const mockTodo = { _jac_id: '123', text: 'Test', done: false };
    global.__jacSpawn.mockResolvedValue({ reports: [[mockTodo]] });

    const result = await global.__jacSpawn('create_todo', '', { text: 'Test' });

    expect(global.__jacSpawn).toHaveBeenCalledWith('create_todo', '', { text: 'Test' });
    expect(result.reports[0][0]).toEqual(mockTodo);
  });
});
```

## Configuration Files

### vitest.config.js

```javascript
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    setupFiles: ['./vitest.setup.js'],
    include: ['**/*.test.js', '.jac/client/compiled/**/*.test.js'],
    globals: true
  }
});
```

### vitest.setup.js

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

// Mock __jacSpawn
global.__jacSpawn = vi.fn().mockResolvedValue({ reports: [], data: null });

// Reset mocks between tests
beforeEach(() => {
  vi.clearAllMocks();
  localStorageMock.clear();
});
```

### package.json (test scripts)

```json
{
  "scripts": {
    "test": "vitest",
    "test:ui": "vitest --ui",
    "test:coverage": "vitest --coverage"
  }
}
```

## Testing React Components

```javascript
import { render, screen, fireEvent } from '@testing-library/react';
import React from 'react';
// Import after compilation
import { TodoApp } from './.jac/client/compiled/main.js';

describe('TodoApp Component', () => {
  it('renders the app title', () => {
    render(<TodoApp />);
    expect(screen.getByText('Todo App')).toBeInTheDocument();
  });

  it('handles input changes', () => {
    render(<TodoApp />);
    const input = screen.getByPlaceholderText('Add todo...');
    fireEvent.change(input, { target: { value: 'New todo' } });
    expect(input.value).toBe('New todo');
  });
});
```

## Running Tests

```bash
# Run all Python tests
jac test main.test.jac

# Run all JavaScript tests
npm test

# Run tests in watch mode
npm test -- --watch

# Run with coverage
npm test -- --coverage

# Run specific test file
npm test client.test.js
```

## Best Practices

1. **Separate concerns**: Put pure logic outside `cl` blocks when possible
2. **Mock walkers**: Use `vi.fn()` to mock `__jacSpawn` calls
3. **Test both layers**: Python for backend, JavaScript for frontend
4. **Test behavior, not implementation**: Focus on what functions return
5. **Keep tests fast**: Use mocks instead of real API calls
