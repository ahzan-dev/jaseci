"""
Tests for pure logic functions using jac test.
Run with: jac test main.test.jac

These tests run in Python and test functions defined OUTSIDE cl blocks.
"""

import from main {
    validateCredentials,
    formatTodoCount,
    getViewForAuthState
}

# ============================================
# validateCredentials Tests
# ============================================

test test_empty_credentials_rejected {
    result = validateCredentials("", "");
    assert result == "Please fill in all fields";
}

test test_none_username_rejected {
    result = validateCredentials(None, "password");
    assert result == "Please fill in all fields";
}

test test_none_password_rejected {
    result = validateCredentials("username", None);
    assert result == "Please fill in all fields";
}

test test_short_username_rejected {
    result = validateCredentials("ab", "password123");
    assert "Username must be at least 3 characters" in result;
}

test test_short_password_rejected {
    result = validateCredentials("alice", "123");
    assert "Password must be at least 6 characters" in result;
}

test test_valid_credentials_accepted {
    result = validateCredentials("alice", "password123");
    assert result == "";
}

test test_minimum_valid_credentials {
    # Exactly 3 char username and 6 char password
    result = validateCredentials("abc", "123456");
    assert result == "";
}

# ============================================
# formatTodoCount Tests
# ============================================

test test_format_zero_items {
    result = formatTodoCount(0);
    assert result == "No items left";
}

test test_format_one_item {
    result = formatTodoCount(1);
    assert result == "1 item left";
}

test test_format_multiple_items {
    result = formatTodoCount(5);
    assert result == "5 items left";
}

test test_format_large_number {
    result = formatTodoCount(100);
    assert result == "100 items left";
}

# ============================================
# getViewForAuthState Tests
# ============================================

test test_logged_in_shows_todos {
    result = getViewForAuthState(True);
    assert result == "todos";
}

test test_logged_out_shows_login {
    result = getViewForAuthState(False);
    assert result == "login";
}
