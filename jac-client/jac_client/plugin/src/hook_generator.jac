"""React Query hook generator for walker decorators."""
import from pathlib { Path }
import from typing { Any }
import from jaclang.pycore.codeinfo { ClientManifest, WalkerQueryMetadata }

"""Generates React Query hooks from walker query/mutation metadata."""
class HookGenerator {
    def init(self: HookGenerator, output_dir: Path);
    def generate_hooks(self: HookGenerator, manifest: ClientManifest) -> str;
    def _generate_query_hook(
        self: HookGenerator, metadata: WalkerQueryMetadata, fields: list[str]
    ) -> str;
    def _generate_mutation_hook(
        self: HookGenerator, metadata: WalkerQueryMetadata, fields: list[str]
    ) -> str;
    def _to_hook_name(self: HookGenerator, walker_name: str) -> str;
    def write_hooks_file(self: HookGenerator, hooks_code: str) -> Path;
}
