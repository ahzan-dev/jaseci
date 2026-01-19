"""Client-side runtime for Jac JSX and walker interactions."""

import from 'react' { * as React }
import from 'react' { useState as reactUseState }
import from 'react-dom/client' { * as ReactDOM }
import from 'react-router-dom' {
    HashRouter as ReactRouterHashRouter,
    Routes as ReactRouterRoutes,
    Route as ReactRouterRoute,
    Link as ReactRouterLink,
    Navigate as ReactRouterNavigate,
    useNavigate as reactRouterUseNavigate,
    useLocation as reactRouterUseLocation,
    useParams as reactRouterUseParams
}
import from '@tanstack/react-query' {
    QueryClient as ReactQueryClient,
    QueryClientProvider as ReactQueryClientProvider,
    useQuery as reactQueryUseQuery,
    useMutation as reactQueryUseMutation,
    useQueryClient as reactQueryUseQueryClient
}

def:pub __jacJsx(tag: any, props: dict = {}, children: any = []) -> any;

# React Query client instance (singleton)
glob __queryClient = new ReactQueryClient({
    "defaultOptions": {
        "queries": {
            "staleTime": 60000,
            "refetchOnWindowFocus": False
        }
    }
});

# React hooks re-exported for auto-injection by `has` variables
glob:pub useState = reactUseState,
     Router = ReactRouterHashRouter,
     Routes = ReactRouterRoutes,
     Route = ReactRouterRoute,
     Link = ReactRouterLink,
     Navigate = ReactRouterNavigate,
     useNavigate = reactRouterUseNavigate,
     useLocation = reactRouterUseLocation,
     useParams = reactRouterUseParams,
     # React Query exports
     QueryClient = ReactQueryClient,
     QueryClientProvider = ReactQueryClientProvider,
     useQuery = reactQueryUseQuery,
     useMutation = reactQueryUseMutation,
     useQueryClient = reactQueryUseQueryClient;

def:pub useRouter -> dict;
def:pub navigate(path: str) -> None;
def:pub JacQueryProvider(props: dict) -> any;
async def:pub __jacSpawn(left: str, right: str = "", fields: dict = {}) -> any;
def:pub jacSpawn(left: str, right: str = "", fields: dict = {}) -> any;
async def:pub __jacCallFunction(function_name: str, args: dict = {}) -> any;
async def:pub jacSignup(username: str, password: str) -> dict;
async def:pub jacLogin(username: str, password: str) -> bool;
def:pub jacLogout -> None;
def:pub jacIsLoggedIn -> bool;
def:pub __getLocalStorage(key: str) -> str;
def:pub __setLocalStorage(key: str, value: str) -> None;
def:pub __removeLocalStorage(key: str) -> None;
# React Router components
