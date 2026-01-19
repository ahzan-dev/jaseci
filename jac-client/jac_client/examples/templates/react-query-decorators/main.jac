"""
Todo App with Auto-Generated React Query Hooks.

This example demonstrates the @query and @mutation decorators that
automatically generate React Query hooks for walkers.

Instead of manually writing:
  - useQuery({ queryKey: ["todos"], queryFn: ... })
  - useMutation({ mutationFn: ..., onSuccess: invalidate("todos") })

You simply add decorators to your walkers:
  - @query(key=["todos"]) on read_todos
  - @mutation(invalidates=["todos"]) on create_todo, toggle_todo, delete_todo

The jac-client compiler generates the hooks automatically!
"""

import from jac_client.decorators { query, mutation }

# ============================================
# Data Model
# ============================================
node Todo {
    has text: str;
    has done: bool = False;
}

# ============================================
# Backend Walkers with React Query Decorators
# ============================================

@query(key=["todos"])
walker read_todos {
    """Fetch all todos - generates useReadTodos() hook."""
    can read with `root entry {
        visit [-->(`?Todo)];
    }

    can report_todos with Todo entry {
        report here;
    }
}

@mutation(invalidates=["todos"])
walker create_todo {
    """Create a new todo - generates useCreateTodo() hook."""
    has text: str;

    can create with `root entry {
        new_todo = here ++> Todo(text=self.text);
        report new_todo;
    }
}

@mutation(invalidates=["todos"], optimistic=True)
walker toggle_todo {
    """Toggle todo done state - generates useToggleTodo() hook with optimistic updates."""
    can toggle with Todo entry {
        here.done = not here.done;
        report here;
    }
}

@mutation(invalidates=["todos"])
walker delete_todo {
    """Delete a todo - generates useDeleteTodo() hook."""
    can remove with Todo entry {
        del here;
        report {"message": "Todo deleted"};
    }
}

# ============================================
# Frontend - Using Auto-Generated Hooks
# ============================================

cl import from react { useState }

# Import auto-generated hooks (created by jac-client from decorators)
cl import from "./generated_hooks" {
    useReadTodos,
    useCreateTodo,
    useToggleTodo,
    useDeleteTodo
}

cl {
    def TodoApp() -> any {
        [inputValue, setInputValue] = useState("");
        [filter, setFilter] = useState("all");

        # Use auto-generated hooks - no manual setup needed!
        todos = useReadTodos();
        createTodo = useCreateTodo();
        toggleTodo = useToggleTodo();
        deleteTodo = useDeleteTodo();

        if todos.isLoading {
            return <div className="loading">Loading todos...</div>;
        }

        if todos.error {
            return <div className="error">Error: {todos.error.message}</div>;
        }

        todoList = todos.data or [];

        def addTodo() -> None {
            if not inputValue.trim() {
                return;
            }
            createTodo.mutate({ "text": inputValue.trim() });
            setInputValue("");
        }

        def filteredTodos() -> list {
            if filter == "active" {
                return todoList.filter(lambda t: any -> bool { return not t.done; });
            } elif filter == "completed" {
                return todoList.filter(lambda t: any -> bool { return t.done; });
            }
            return todoList;
        }

        activeCount = todoList.filter(lambda t: any -> bool { return not t.done; }).length;

        return <div className="todo-container">
            <h1>Todo App</h1>
            <p className="subtitle">Using auto-generated React Query hooks</p>

            <div className="input-row">
                <input
                    type="text"
                    value={inputValue}
                    placeholder="What needs to be done?"
                    onChange={lambda e: any -> None { setInputValue(e.target.value); }}
                    onKeyDown={lambda e: any -> None {
                        if e.key == "Enter" { addTodo(); }
                    }}
                />
                <button onClick={addTodo} disabled={createTodo.isPending}>
                    {createTodo.isPending ? "Adding..." : "Add"}
                </button>
            </div>

            <div className="filters">
                <button
                    className={"active" if filter == "all" else ""}
                    onClick={lambda -> None { setFilter("all"); }}
                >All ({todoList.length})</button>
                <button
                    className={"active" if filter == "active" else ""}
                    onClick={lambda -> None { setFilter("active"); }}
                >Active ({activeCount})</button>
                <button
                    className={"active" if filter == "completed" else ""}
                    onClick={lambda -> None { setFilter("completed"); }}
                >Completed ({todoList.length - activeCount})</button>
            </div>

            <ul className="todo-list">
                {filteredTodos().map(lambda todo: any -> any {
                    return <li key={todo._jac_id} className={"done" if todo.done else ""}>
                        <input
                            type="checkbox"
                            checked={todo.done}
                            onChange={lambda -> None { toggleTodo.mutate(todo._jac_id); }}
                        />
                        <span>{todo.text}</span>
                        <button
                            className="delete"
                            onClick={lambda -> None { deleteTodo.mutate(todo._jac_id); }}
                        >x</button>
                    </li>;
                })}
            </ul>

            <div className="footer">
                {activeCount} items left
            </div>
        </div>;
    }

    def:pub app() -> any {
        return <JacQueryProvider>
            <TodoApp />
        </JacQueryProvider>;
    }
}
