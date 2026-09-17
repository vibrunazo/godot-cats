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

### Godot CLI & Script Execution - consider these recommendations to avoid scripts hanving forever:
- Include `--headless` and `--path .` on terminal commands to ensure the engine initializes the project directory without waiting on window servers.
- Pair standalone scripts (`-s`) with an engine frame budget like `--quit-after 300` as a fallback in case a runtime error or signal prevents `quit()` from executing.
- Standalone `-s` scripts need to inherit from `SceneTree` so Godot's main loop starts properly.
- Subprocess runners should use `shell=False` and argument lists so OS timeouts can terminate the process tree cleanly without leaving pipe handles open.
- For inspecting UI scenes or dialogs, prefer driving them through a runner script instead of targeting the UI component file directly with `-s`.

## 3. Tooling & Workflow Recommendations
- **UI Diagnostics**: For inspecting control positions, anchors, and bounding rects at runtime, consider using `tools/inspect_ui.py <scene.tscn> [--node <path>]` before making manual scene adjustments.
- **Engine Migration Checks**: When investigating UI layout or button issues in migrated projects, check for properties that changed between engine versions. For example, `TextureButton` properties like `expand` changed to `ignore_texture_size` (paired with `stretch_mode`), and resaving inherited scenes in newer editor versions can occasionally serialize `layout_mode = 0` overrides that disable intended anchor behaviors.
- **Cross-Platform Execution**: Environments may run natively or through WSL. If Linux utilities (such as bash pipelines or grep) are preferred, WSL can be utilized. When running subprocesses, argument lists with dynamic executable resolution help maintain compatibility across platforms.
- **Dedicated Scripts over Complex Shell Chains**: For non-trivial inspection, data parsing, or regex checks, writing a small helper script in `tools/` is typically cleaner and more reliable than complex one-liners with multi-layered quoting, which can behave differently across different host shells.
- **File Handling in Automation**: When generating or overwriting images and logs, ensuring open file handles or viewers are released helps prevent file lock issues across different operating systems.
- **Lean Visual Context**: Large ultra-wide or high-resolution images can stress connection limits and streaming buffers. Cropping screenshots to the specific region of interest before inspection helps maintain fast, uninterrupted turns.
- **Process Wait Timeouts**: Setting excessively long synchronous process wait times can leave streaming connections idle for extended intervals. Moderate synchronous wait times (e.g. 3–5 seconds), or transitioning long runs to background tasks, help prevent gateway connection timeouts.
- **Scoped Command Outputs**: Restricting command output volume using line limits, head/tail filters, or targeted diff flags (`-U1`, line ranges) helps avoid flooding communication channels with unbounded logs or thousands of lines of scene definitions.