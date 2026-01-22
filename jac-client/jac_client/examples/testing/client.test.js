/**
 * Tests for client-side functions using Vitest.
 * Run with: npm test
 *
 * This tests the COMPILED JavaScript output from .cl.jac files.
 * The compiled code is in .jac/client/compiled/
 */
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import React from 'react';

// Import compiled functions from the .jac/client/compiled/ directory
// Note: You need to compile first with `jac start main.jac` before testing
import { filterTodos, formatDate } from './.jac/client/compiled/main.js';

describe('filterTodos', () => {
  const todos = [
    { _jac_id: '1', text: 'Buy milk', done: false },
    { _jac_id: '2', text: 'Walk dog', done: true },
    { _jac_id: '3', text: 'Read book', done: false }
  ];

  it('returns all todos when filter is "all"', () => {
    const result = filterTodos(todos, 'all');
    expect(result).toHaveLength(3);
  });

  it('returns only active todos when filter is "active"', () => {
    const result = filterTodos(todos, 'active');
    expect(result).toHaveLength(2);
    expect(result.every(t => !t.done)).toBe(true);
  });

  it('returns only completed todos when filter is "completed"', () => {
    const result = filterTodos(todos, 'completed');
    expect(result).toHaveLength(1);
    expect(result[0].text).toBe('Walk dog');
  });

  it('handles empty array', () => {
    const result = filterTodos([], 'all');
    expect(result).toHaveLength(0);
  });

  it('handles unknown filter by returning all', () => {
    const result = filterTodos(todos, 'unknown');
    expect(result).toHaveLength(3);
  });
});

describe('formatDate', () => {
  it('formats a Date object', () => {
    const date = new Date('2024-01-15');
    const result = formatDate(date);
    // Result depends on locale, just check it's not empty
    expect(result).toBeTruthy();
  });

  it('handles date string', () => {
    const result = formatDate('2024-01-15');
    expect(result).toBeTruthy();
  });

  it('returns empty string for null', () => {
    expect(formatDate(null)).toBe('');
  });

  it('returns empty string for undefined', () => {
    expect(formatDate(undefined)).toBe('');
  });
});

// Example: Testing walker mocks
describe('Walker integration tests', () => {
  beforeEach(() => {
    // Mock the __jacSpawn function
    global.__jacSpawn = vi.fn();
  });

  it('mocks create_todo walker', async () => {
    const mockTodo = { _jac_id: '123', text: 'Test todo', done: false };

    global.__jacSpawn.mockResolvedValue({
      reports: [[mockTodo]]
    });

    const result = await global.__jacSpawn('create_todo', '', { text: 'Test todo' });

    expect(global.__jacSpawn).toHaveBeenCalledWith('create_todo', '', { text: 'Test todo' });
    expect(result.reports[0][0]).toEqual(mockTodo);
  });

  it('mocks read_todos walker', async () => {
    const mockTodos = [
      { _jac_id: '1', text: 'Todo 1', done: false },
      { _jac_id: '2', text: 'Todo 2', done: true }
    ];

    global.__jacSpawn.mockResolvedValue({
      reports: mockTodos
    });

    const result = await global.__jacSpawn('read_todos', '', {});

    expect(result.reports).toEqual(mockTodos);
  });
});

// Example: Testing React components (requires compiled component)
describe('Component tests (example structure)', () => {
  it('demonstrates how to test a rendered component', () => {
    // To test React components:
    // 1. Import the compiled component from .jac/client/compiled/
    // 2. Render it with @testing-library/react
    // 3. Use screen queries to check output
    //
    // Example (uncomment after compilation):
    //
    // import { TodoApp } from './.jac/client/compiled/main.js';
    //
    // render(<TodoApp />);
    // expect(screen.getByText('Todo App')).toBeInTheDocument();
    // expect(screen.getByPlaceholderText('Add todo...')).toBeInTheDocument();

    expect(true).toBe(true); // Placeholder
  });
});
