## 1. Project Overview
- **Engine**: Godot 4.7.2 stable official (Windows, Android).
- **Genre**: 2D Top-Down tower defense game.

## 2. Mandatory Coding Guidelines
1. **Strict GDScript Typing**:
   - `warnings/untyped_declaration=1` is enforced in `project.godot`.
   - Every variable, parameter, and function return type must be explicitly typed (e.g. `var x: float = 0.0`, `func foo(bar: int) -> void:`).
2. **Documentation Integrity**:
   - Preserve and maintain all docstrings (`## ...`) and comments on classes, exported variables, and functions.
3. **Git Commits**:
   - The user manages git commits. **Never run `git commit` or `git push` unless explicitly told so by the user**.

Wrap headless Godot invocations in an external process runner (such as Python) configured with a hard timeout parameter to avoid hanging when scripts hit compilation issues, cyclic preloads, or runtime exceptions.  

Prefer running subprocesses with shell=False and argument lists so timeout signals terminate the engine directly rather than leaving orphaned background processes holding open I/O pipes.  

Resolve the engine binary dynamically (such as via shutil.which("godot")) to maintain portability across native terminals, containers, and WSL environments.  

For standalone diagnostic scripts executed with the -s flag, inherit from SceneTree and call quit() explicitly to ensure the main loop initializes and shuts down cleanly.  Confine temporary scripts to an isolated directory containing a .gdignore file to prevent the editor from scanning, importing, or locking disposable assets. 

If you find a helper python script could be helpful, write them to tools/ and keep it there for future features and future agents.

We have screenshot and recording tools at tools/capture/ if you need to take screenshots of record movies of gameplay for debugging, consider using those tools. If those tools are not sufficient for your use case, consider adding or improving these tools to help future agents with similar needs.

Tests should focus on generalized mechanics and not hardcoded values. Consider that designers might change game balance. Good test: if damage is X then was final health after taking damage the expected value?  Bad test: is damage set to 4?