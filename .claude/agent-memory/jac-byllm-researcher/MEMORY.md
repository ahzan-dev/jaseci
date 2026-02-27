# jac-byllm Research Memory

## Project Identity
- **Name**: byLLM (jac-byllm) - "Prompt Less, Smile More!"
- **Version**: 0.5.1, published on PyPI as `byllm`
- **License**: MIT
- **Research**: OOPSLA 2025 paper on Meaning Typed Programming (MTP)
- **Core paradigm**: MTP - embeds prompt engineering into code semantics

## Key File Locations
- **Plugin entry**: `/jac-byllm/byllm/plugin.jac` - JacRuntime hooks (get_mtir, call_llm, by, by_operator, default_llm)
- **MTIR core**: `/jac-byllm/byllm/mtir.jac` + `impl/mtir.impl.jac` - Meaning Typed IR, ReAct loop setup
- **LLM abstraction**: `/jac-byllm/byllm/llm.jac` + `llm.impl/basellm.impl.jac` + `llm.impl/model.impl.jac`
- **Schema gen**: `/jac-byllm/byllm/schema.jac` + `impl/schema.impl.jac` - JSON schema from types
- **Types**: `/jac-byllm/byllm/types.jac` - Message, Tool, ToolCall, Media, Image, Video
- **Config**: `/jac-byllm/byllm/config_loader.jac` - jac.toml based config
- **MTP in core Jac**: `/jac/jaclang/jac0core/mtp.jac` - Info, ClassInfo, FunctionInfo, ParamInfo etc.
- **By operator (LLM routing)**: `/jac/jaclang/jac0core/runtime.jac` - JacByLLM.filter_visitable_by

## Architecture Patterns
- **`by llm()` syntax**: Functions declared with `by llm()` have bodies replaced by LLM calls
- **sem strings**: `sem X.field = "description"` enriches type semantics for LLM
- **ReAct loop**: BaseLLM.invoke() implements while-loop with tool calls until finish_tool
- **finish_tool**: Auto-generated tool that validates output type via Pydantic TypeAdapter
- **MTIR pipeline**: Compile-time extraction of semantic info -> runtime prompt assembly
- **LLM-guided graph traversal**: `visit [-->] by llm()` uses LLM to pick which nodes to visit
- **Plugin system**: hookimpl decorators, registered via pyproject.toml entry_points

## Agentic AI Examples
- **marketing_agency.jac**: Multi-agent (manager delegates to experts), hierarchical
- **task_manager.jac**: LLM-driven routing (plan_tasks -> route to specialized nodes)
- **math_poem_agents.jac**: `visit [-->] by llm()` for semantic node routing
- **fantasy_trading_game.jac**: Stateful agent with tools, conversation history
- **genius_lite.jac**: Walker traverses task graph, each node processes via LLM
- **wikipedia_react.jac**: Tool-using ReAct agent
- **debate_agent.jac**: Interactive agent with human-in-the-loop

## Key Capabilities for Agentic Systems
1. Tool calling with ReAct loop (max_react_iterations)
2. Typed structured outputs (dataclass/enum -> JSON schema)
3. Semantic strings (sem) for prompt-free LLM guidance
4. LLM-guided graph traversal (by operator)
5. Walker/node/edge data-spatial programming
6. Multi-model support via LiteLLM
7. Streaming support
8. Python library mode (@by decorator)
9. Multimodal (Image, Video)
10. Context injection (incl_info parameter)
