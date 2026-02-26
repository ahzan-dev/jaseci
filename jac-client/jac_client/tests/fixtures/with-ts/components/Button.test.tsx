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

  it('applies the primary variant by default', () => {
    const { container } = render(<Button label="Primary" />);
    const btn = container.querySelector('button') as HTMLButtonElement;
    // default background is blue (#3b82f6)
    expect(btn.style.backgroundColor).toBe('rgb(59, 130, 246)');
  });

  it('applies the secondary variant styles', () => {
    const { container } = render(<Button label="Cancel" variant="secondary" />);
    const btn = container.querySelector('button') as HTMLButtonElement;
    // secondary background is grey (#6b7280)
    expect(btn.style.backgroundColor).toBe('rgb(107, 114, 128)');
  });

  it('shows a not-allowed cursor when disabled', () => {
    const { container } = render(<Button label="Off" disabled />);
    const btn = container.querySelector('button') as HTMLButtonElement;
    expect(btn.style.cursor).toBe('not-allowed');
  });

  it('matches snapshot', () => {
    const { container } = render(<Button label="Snap" />);
    expect(container.firstChild).toMatchSnapshot();
  });
});
