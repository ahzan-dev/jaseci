"""
Testing Example - Shows how to write testable jac-client code.

KEY PRINCIPLE: Separate pure logic from UI components!

TESTABLE (pure functions):
- validateCredentials() - pure logic, no side effects
- formatTodoCount() - pure logic, returns strings
- filterTodos() - pure logic, filters arrays

NOT DIRECTLY TESTABLE (with simple mocks):
- Components with hooks (useState, useEffect)
- Components that call __jacSpawn
"""

# ============================================
# Backend - Nodes and Walkers (tested via jac test)
# ============================================
node Todo {
    has text: str;
    has done: bool = False;
}

walker create_todo {
    has text: str;

    can create with `root entry {
        new_todo = here ++> Todo(text=self.text);
        report new_todo;
    }
}

walker read_todos {
    can read with `root entry {
        visit [-->(`?Todo)];
    }
    can collect with Todo entry {
        report here;
    }
}

# ============================================
# Pure Logic Functions (TESTABLE!)
# Put these OUTSIDE cl block for Python testing
# ============================================

"""Validate user credentials - returns error message or empty string."""
def:pub validateCredentials(username: str, password: str) -> str {
    if not username or not password {
        return "Please fill in all fields";
    }
    if len(username) < 3 {
        return "Username must be at least 3 characters";
    }
    if len(password) < 6 {
        return "Password must be at least 6 characters";
    }
    return "";
}

"""Format the todo count message."""
def:pub formatTodoCount(count: int) -> str {
    if count == 0 {
        return "No items left";
    } elif count == 1 {
        return "1 item left";
    } else {
        return f"{count} items left";
    }
}

"""Determine which view to show based on login state."""
def:pub getViewForAuthState(isLoggedIn: bool) -> str {
    return "todos" if isLoggedIn else "login";
}

# ============================================
# Frontend Components
# ============================================

cl import from react { useState }

cl {
    # Client-side pure functions (for JS testing)
    def:pub filterTodos(todos: list, filter: str) -> list {
        if filter == "active" {
            return todos.filter(lambda t: any -> bool { return not t.done; });
        } elif filter == "completed" {
            return todos.filter(lambda t: any -> bool { return t.done; });
        }
        return todos;
    }

    def:pub formatDate(date: any) -> str {
        if not date {
            return "";
        }
        d = date if isinstance(date, Date) else Date(date);
        return d.toLocaleDateString();
    }

    def TodoApp() -> any {
        [todos, setTodos] = useState([]);
        [input, setInput] = useState("");
        [filter, setFilter] = useState("all");

        async def loadTodos() -> None {
            result = root spawn read_todos();
            setTodos(result.reports or []);
        }

        async def addTodo() -> None {
            if not input.trim() {
                return;
            }
            result = root spawn create_todo(text=input.trim());
            setTodos(todos.concat([result.reports[0]]));
            setInput("");
        }

        activeCount = todos.filter(lambda t: any -> bool { return not t.done; }).length;

        return <div>
            <h1>Todo App</h1>
            <input
                value={input}
                onChange={lambda e: any -> None { setInput(e.target.value); }}
                placeholder="Add todo..."
            />
            <button onClick={addTodo}>Add</button>

            <ul>
                {filterTodos(todos, filter).map(lambda t: any -> any {
                    return <li key={t._jac_id}>{t.text}</li>;
                })}
            </ul>

            <p>{formatTodoCount(activeCount)}</p>
        </div>;
    }

    def:pub app() -> any {
        return <TodoApp />;
    }
}
