# Frontend Testing with jac-client

Complete guide to testing frontend code in Jac full-stack applications.

---

## Overview

Jac supports four complementary layers of frontend testing, each catching a different class of problem:

| Layer | Tool | Speed | What it catches |
|---|---|---|---|
| Component Unit | Vitest + React Testing Library | Fast | Logic, props, events |
| Snapshot | Vitest | Fast | Unintended render changes |
| API Integration | `JacTestClient` / `urllib` | Medium | Walker endpoints, data contracts |
| E2E (Browser) | Playwright | Slow | Full user flows, real browser behavior |

---

## 1. Component Unit Tests

Component unit tests render individual React/TSX components in a simulated browser (jsdom) and assert on their output. No server or build step is required.

### Install dependencies

```bash
npm install --save-dev vitest @testing-library/react @testing-library/jest-dom jsdom
```

### Configure Vitest

Create `vitest.config.ts` alongside your `vite.config.js`:

```typescript
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',  // simulate a real browser DOM
    globals: true,         // access describe/it/expect without imports
    setupFiles: ['./vitest.setup.ts'],
  },
});
```

Create a setup file to load the extended DOM matchers:

```typescript
// vitest.setup.ts
import '@testing-library/jest-dom';
```

### Writing component tests

Given a reusable `Button.tsx` component:

```typescript
// components/Button.tsx
import React from 'react';

interface ButtonProps {
  label: string;
  onClick?: () => void;
  variant?: 'primary' | 'secondary';
  disabled?: boolean;
}

export const Button: React.FC<ButtonProps> = ({
  label, onClick, variant = 'primary', disabled = false,
}) => (
  <button onClick={onClick} disabled={disabled} data-variant={variant}>
    {label}
  </button>
);
```

Write tests in a co-located `.test.tsx` file:

```typescript
// components/Button.test.tsx
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { Button } from './Button';

describe('Button', () => {
  it('renders the label', () => {
    render(<Button label="Click me" />);
    expect(screen.getByRole('button', { name: 'Click me' })).toBeInTheDocument();
  });

  it('fires onClick when clicked', () => {
    const onClick = vi.fn();
    render(<Button label="Submit" onClick={onClick} />);
    fireEvent.click(screen.getByRole('button'));
    expect(onClick).toHaveBeenCalledOnce();
  });

  it('does not fire onClick when disabled', () => {
    const onClick = vi.fn();
    render(<Button label="Submit" onClick={onClick} disabled />);
    fireEvent.click(screen.getByRole('button'));
    expect(onClick).not.toHaveBeenCalled();
  });

  it('marks the button as disabled', () => {
    render(<Button label="Submit" disabled />);
    expect(screen.getByRole('button')).toBeDisabled();
  });

  it('applies the secondary variant', () => {
    render(<Button label="Cancel" variant="secondary" />);
    expect(screen.getByRole('button')).toHaveAttribute('data-variant', 'secondary');
  });
});
```

### Run the tests

```bash
npx vitest run          # run once
npx vitest              # watch mode
npx vitest --coverage   # with coverage report
```

---

## 2. Snapshot Tests

Snapshot tests capture the rendered HTML of a component and fail if it changes unexpectedly. They are a quick safety net for refactoring.

```typescript
// components/Button.snapshot.test.tsx
import { describe, it, expect } from 'vitest';
import { render } from '@testing-library/react';
import { Button } from './Button';

describe('Button snapshots', () => {
  it('matches primary snapshot', () => {
    const { container } = render(<Button label="Primary" />);
    expect(container.firstChild).toMatchSnapshot();
  });

  it('matches disabled snapshot', () => {
    const { container } = render(<Button label="Disabled" disabled />);
    expect(container.firstChild).toMatchSnapshot();
  });
});
```

On the first run Vitest creates snapshot files (`.snap`). On subsequent runs it compares against them and fails if the output changed. Update snapshots intentionally with:

```bash
npx vitest --update-snapshots
```

---

## 3. API Integration Tests

Test your Jac walker endpoints from Python without starting a real HTTP server using `JacTestClient`.

```python
# tests/test_api.py
from jaclang.runtimelib.testing import JacTestClient

def test_get_items(tmp_path):
    client = JacTestClient.from_file("app.jac", base_path=str(tmp_path))
    client.register_user("tester", "password123")

    resp = client.post("/walker/GetItems")
    assert resp.ok
    assert isinstance(resp.data, list)
    client.close()

def test_create_item(tmp_path):
    client = JacTestClient.from_file("app.jac", base_path=str(tmp_path))
    client.register_user("tester", "password123")

    resp = client.post("/walker/CreateItem", json={"title": "My Item"})
    assert resp.status_code == 200

    resp = client.post("/walker/GetItems")
    assert len(resp.data) == 1
    assert resp.data[0]["title"] == "My Item"
    client.close()
```

Run with pytest:

```bash
pytest tests/test_api.py -v
```

See the [Testing Reference](../testing.md#jacTestClient) for the full `JacTestClient` API.

---

## 4. End-to-End (Browser) Tests

E2E tests launch your full application — `jac start` — and control a real browser through Playwright. They verify complete user flows.

### Install Playwright

```bash
pip install playwright
playwright install chromium
```

### Writing E2E tests

```jac
# tests/test_e2e.jac
import from playwright.sync_api { sync_playwright }
import from .helpers { start_server, stop_server }

test "unauthenticated user is redirected to login" {
    (server, url, tmp) = start_server();
    try {
        with sync_playwright() as p {
            browser = p.chromium.launch(headless=True);
            page = browser.new_page();
            page.goto(f"{url}/dashboard", wait_until="networkidle", timeout=30000);
            assert "/login" in page.url;
            browser.close();
        }
    } finally {
        stop_server(server, tmp);
    }
}

test "user can sign up and reach the dashboard" {
    (server, url, tmp) = start_server();
    try {
        with sync_playwright() as p {
            browser = p.chromium.launch(headless=True);
            page = browser.new_page();
            page.goto(f"{url}/signup", wait_until="networkidle", timeout=60000);
            page.locator('input[type="text"]').fill("alice");
            page.locator('input[type="password"]').fill("secret123");
            page.locator('button[type="submit"]').click();
            page.wait_for_timeout(2000);
            assert "/signup" not in page.url;
            browser.close();
        }
    } finally {
        stop_server(server, tmp);
    }
}
```

### Visual regression with Playwright screenshots

Add screenshot assertions inside any E2E test to catch visual regressions:

```jac
test "landing page appearance" {
    (server, url, tmp) = start_server();
    try {
        with sync_playwright() as p {
            browser = p.chromium.launch(headless=True);
            page = browser.new_page();
            page.set_viewport_size({"width": 1280, "height": 720});
            page.goto(url, wait_until="networkidle", timeout=30000);
            # Fails if the screenshot differs from the stored baseline
            page.screenshot(path="screenshots/landing.png");
            browser.close();
        }
    } finally {
        stop_server(server, tmp);
    }
}
```

Use `expect(page).to_have_screenshot()` (Playwright's built-in snapshot API) for automatic baseline management and pixel-level comparison.

### Run E2E tests

```bash
jac test tests/test_e2e.jac -v
```

---

## Choosing the Right Layer

```
Fast ◄─────────────────────────────────────────► Confident
  │                                                │
  ▼                                                ▼
Unit Tests          Snapshot Tests        E2E Tests
(Vitest)            (Vitest)             (Playwright)
                         │
                   API Integration
                   (JacTestClient)
```

| Scenario | Recommended approach |
|---|---|
| Testing a reusable UI component | Component unit test |
| Catching unintended HTML changes | Snapshot test |
| Verifying a walker returns the right shape | API integration test |
| Testing auth, routing, full user journeys | E2E test |
| Detecting layout / visual breakage | Visual regression (Playwright screenshots) |

---

## Project Layout

```
myapp/
├── jac.toml
├── app.jac
├── components/
│   ├── Button.tsx
│   ├── Button.test.tsx          ← component unit test
│   └── Button.snapshot.test.tsx ← snapshot test
├── vitest.config.ts             ← Vitest config
├── vitest.setup.ts              ← testing-library/jest-dom setup
└── tests/
    ├── test_api.py              ← JacTestClient integration tests
    └── test_e2e.jac             ← Playwright E2E tests
```

---

## Related Resources

- [Testing Reference](../testing.md) — Jac test syntax and `JacTestClient` docs
- [jac-client Reference](jac-client.md) — Full-stack plugin reference
- [Vitest docs](https://vitest.dev) — JavaScript unit test runner
- [React Testing Library](https://testing-library.com/docs/react-testing-library/intro/) — Component testing utilities
- [Playwright Python](https://playwright.dev/python/docs/intro) — Browser automation
