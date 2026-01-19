# React Query Decorators Example

This example demonstrates the **automatic React Query hook generation** feature in jac-client using walker decorators.

## The Magic: Decorators

Instead of manually writing React Query hooks, you simply add decorators to your walkers:

```jac
import from jac_client.decorators { query, mutation }

# This generates: useReadTodos() hook
@query(key=["todos"])
walker read_todos { ... }

# This generates: useCreateTodo() hook that auto-invalidates "todos"
@mutation(invalidates=["todos"])
walker create_todo { ... }

# This generates: useToggleTodo() hook with optimistic updates
@mutation(invalidates=["todos"], optimistic=True)
walker toggle_todo { ... }
```

## Generated Hooks

The compiler automatically generates React Query hooks in `generated_hooks.js`:

| Walker | Decorator | Generated Hook |
|--------|-----------|----------------|
| `read_todos` | `@query(key=["todos"])` | `useReadTodos()` |
| `create_todo` | `@mutation(invalidates=["todos"])` | `useCreateTodo()` |
| `toggle_todo` | `@mutation(invalidates=["todos"], optimistic=True)` | `useToggleTodo()` |
| `delete_todo` | `@mutation(invalidates=["todos"])` | `useDeleteTodo()` |

## Usage in Frontend

```jac
cl import from "./generated_hooks" {
    useReadTodos,
    useCreateTodo,
    useToggleTodo
}

cl {
    def TodoApp() -> any {
        # Use generated hooks - no manual setup!
        todos = useReadTodos();
        createTodo = useCreateTodo();
        toggleTodo = useToggleTodo();

        if todos.isLoading {
            return <div>Loading...</div>;
        }

        return <div>
            {todos.data.map(lambda t -> {
                return <div key={t._jac_id}>
                    <input
                        type="checkbox"
                        checked={t.done}
                        onChange={lambda -> { toggleTodo.mutate(t._jac_id); }}
                    />
                    {t.text}
                </div>;
            })}
        </div>;
    }
}
```

## Decorator Options

### @query
```jac
@query(
    key=["todos"],           # Query cache key (default: [walker_name])
    staleTime=60000,         # Time in ms before data is stale (optional)
    refetchInterval=5000     # Auto-refetch interval in ms (optional)
)
```

### @mutation
```jac
@mutation(
    invalidates=["todos"],   # Query keys to invalidate on success
    optimistic=True          # Enable optimistic updates (default: False)
)
```

## Running the Example

```bash
cd jac_client/examples/templates/react-query-decorators
jac start main.jac
```

## Comparison: Before vs After

### Before (Manual)
```jac
cl {
    async def getTodos() -> any {
        result = root spawn read_todos();
        return result.reports || [];
    }

    def useTodos() -> dict {
        qc = useQueryClient();
        return useQuery({
            "queryKey": ["todos"],
            "queryFn": getTodos
        });
    }

    def useCreateTodo() -> dict {
        qc = useQueryClient();
        return useMutation({
            "mutationFn": lambda text -> { root spawn create_todo(text=text); },
            "onSuccess": lambda -> { qc.invalidateQueries({"queryKey": ["todos"]}); }
        });
    }
}
```

### After (With Decorators)
```jac
import from jac_client.decorators { query, mutation }

@query(key=["todos"])
walker read_todos { ... }

@mutation(invalidates=["todos"])
walker create_todo { ... }

# Frontend: just import and use!
cl import from "./generated_hooks" { useReadTodos, useCreateTodo }
```

## Benefits

1. **Less Boilerplate**: No manual hook setup
2. **Type Safety**: Hook names and parameters derived from walker definitions
3. **Auto Cache Management**: Invalidation handled automatically
4. **Optimistic Updates**: Built-in support with rollback
5. **Consistent Patterns**: Same approach across all walkers
