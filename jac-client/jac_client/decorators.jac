"""
Walker decorators for React Query integration.

These decorators mark walkers for automatic React Query hook generation:
- @query: Generates useQuery hooks for data fetching
- @mutation: Generates useMutation hooks for data modification

Example usage:
```jac
import from jac_client.decorators { query, mutation }

@query(key=["todos"])
walker read_todos {
    can read with `root entry {
        visit [-->(`?Todo)];
    }
}

@mutation(invalidates=["todos"])
walker create_todo {
    has text: str;
    can create with `root entry {
        new_todo = here ++> Todo(text=self.text);
        report new_todo;
    }
}
```

The compiler reads these decorators and generates React Query hooks automatically.
"""

"""
Mark a walker as a query for React Query useQuery hook generation.

Args:
    key: Query key array for caching (default: [walker_name])
    staleTime: Time in ms before data is considered stale
    refetchInterval: Auto-refetch interval in ms

Example:
    @query(key=["todos"], staleTime=60000)
    walker read_todos { ... }
"""
def:pub query(
    key: list[str] = [],
    staleTime: int = None,
    refetchInterval: int = None
) -> any {
    # This is a marker decorator - the actual work is done by the compiler
    # when it extracts decorator metadata from the AST
    def decorator(func: any) -> any {
        return func;
    }
    return decorator;
}

"""
Mark a walker as a mutation for React Query useMutation hook generation.

Args:
    invalidates: Query keys to invalidate on success
    optimistic: Enable optimistic updates with rollback on error

Example:
    @mutation(invalidates=["todos"], optimistic=True)
    walker create_todo { ... }
"""
def:pub mutation(
    invalidates: list[str] = [],
    optimistic: bool = False
) -> any {
    # This is a marker decorator - the actual work is done by the compiler
    # when it extracts decorator metadata from the AST
    def decorator(func: any) -> any {
        return func;
    }
    return decorator;
}
