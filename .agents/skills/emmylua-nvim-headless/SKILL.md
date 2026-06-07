---
name: emmylua-nvim-headless
description: Use when adding, fixing, or validating EmmyLua annotations for Lua files with emmylua_ls through independent headless Neovim, or when batch-formatting Lua files through EmmyLua LSP. Covers callability annotations, partial classes, diagnostic reproduction, and LSP formatting via EmmyLuaCodeStyle/.editorconfig.
---

# EmmyLua Headless Neovim

Use Neovim as a clean LSP harness: start with `nvim --headless --clean`, attach `emmylua_ls` manually, and read diagnostics from `vim.diagnostic`. Do not require user config modules or assume their plugin manager has loaded LSP setup.

## Preconditions

- Require `nvim` and `emmylua_ls` in `PATH`, or replace `emmylua_ls` in commands with an absolute path.
- Prefer running from the project root so `.emmyrc.json`, `.luarc.json`, `.editorconfig`, and `.git` root behavior match the project.
- For formatting, use EmmyLua LSP formatting and EmmyLuaCodeStyle `.editorconfig`. Do not switch to `stylua` or another Lua formatter unless the repository explicitly asks for that.

## Diagnose Annotation Problems

Run a file through a clean headless LSP session before editing annotations, then run it again after each small annotation change.

```sh
file="path/to/file.lua"
nvim --headless --clean "$file" +'lua vim.bo.filetype = "lua"; local uv = vim.uv or vim.loop; local id = vim.lsp.start({ name = "emmylua_ls", cmd = { "emmylua_ls", "--log-level", "error" }, root_dir = uv.cwd() }); print("client_id=" .. tostring(id)); assert(vim.wait(5000, function() return #vim.lsp.get_clients({ bufnr = 0 }) > 0 end), "emmylua_ls did not attach"); vim.defer_fn(function() local names = {}; for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do names[#names + 1] = c.name end; print("clients=" .. table.concat(names, ",")); local diags = vim.diagnostic.get(0); print("diagnostics=" .. tostring(#diags)); for _, d in ipairs(diags) do local sev = vim.diagnostic.severity[d.severity] or tostring(d.severity); local msg = tostring(d.message):gsub("\n", " "); print(string.format("%d:%d:%s:%s:%s", d.lnum + 1, d.col + 1, sev, d.source or "", msg)) end; vim.cmd("quit") end, 5000)'
```

If diagnostics depend on another Lua file, open both the annotated module and at least one dependent file that calls it. Use placeholder paths in examples and replace them with the current project files.

```sh
files=(
	"path/to/annotated_module.lua"
	"path/to/dependent_module.lua"
)

for file in "${files[@]}"; do
	nvim --headless --clean "$file" +'lua vim.bo.filetype = "lua"; local uv = vim.uv or vim.loop; vim.lsp.start({ name = "emmylua_ls", cmd = { "emmylua_ls", "--log-level", "error" }, root_dir = uv.cwd() }); assert(vim.wait(5000, function() return #vim.lsp.get_clients({ bufnr = 0 }) > 0 end), "emmylua_ls did not attach"); vim.defer_fn(function() print("file=" .. vim.api.nvim_buf_get_name(0)); local diags = vim.diagnostic.get(0); print("diagnostics=" .. tostring(#diags)); for _, d in ipairs(diags) do local sev = vim.diagnostic.severity[d.severity] or tostring(d.severity); local msg = tostring(d.message):gsub("\n", " "); print(string.format("%d:%d:%s:%s:%s", d.lnum + 1, d.col + 1, sev, d.source or "", msg)) end; vim.cmd("quit") end, 5000)'
done
```

## Annotation Patterns

Use these patterns first when the diagnostics match the symptom.

Callable objects:

```lua
---@class CallableValue<T>
---@overload fun(): T
---@overload fun(value: T)
---@field value T
```

Prefer `---@overload fun(...)` for callable tables. Avoid `---@operator call(...)` when `emmylua_ls` reports `missing parameter: self` or `call-non-callable` on metatable-backed callables.

Repeated class declarations:

```lua
---@class (partial) RuntimeScope
---@field active RuntimeEffect?

---@class (partial) RuntimeScope
local Scope = {}
```

Use `---@class (partial) Name` for split declarations. Do not replace a prototype table with `---@type Name` unless it is an instance; that can make method injection look invalid.

Public callable value with richer internal state:

```lua
---@alias ComputedValue<T> fun(): T

---@class ComputedValueState<T>
---@field effect RuntimeEffect?
---@field value CallableValue<T>
```

Return the public callable alias from APIs consumed by components. Use the state class internally when the framework needs fields such as `effect`, `value`, or `stop`.

Callbacks that intentionally keep only the first return value:

```lua
---@generic T
---@param fn fun(): T, ...
---@return ComputedValue<T>
function M.make_computed(fn)
end
```

Use `fun(): T, ...` when the callback may return extra values but the implementation stores only the first value.

Nullable active context:

```lua
---@type RuntimeContext?
local active

function M.get_resource(name)
	---@cast active RuntimeContext
	local context = active
	return context.resources[name]
end
```

Use `---@cast active RuntimeContext` only at boundaries that already have runtime guarantees. Do not change runtime control flow just to satisfy the language server.

Dynamic table dispatch:

```lua
---@type fun(target: DispatchTarget, ...: any)
---@diagnostic disable-next-line: undefined-field
local handler = assert(target[event.name])
handler(target, table.unpack(args, 1, args.n))
```

Use a precise local function type for dynamic dispatch. If the dynamic key is expected and validated by project design, prefer a one-line diagnostic suppression over refactoring runtime code for the checker.

Module return casts:

```lua
---@class NativeModuleApi
---@field load fun(name: string): string?
---@field resolve fun(name: string): string?
---@type NativeModuleApi
---@diagnostic disable-next-line: assign-type-mismatch
local native = require "native.module"
```

Keep suppressions narrow and adjacent to the expression that the analyzer cannot model.

## Batch Format Lua Files

Use `emmylua_ls` formatting through clean headless Neovim. Run from the project root so EmmyLuaCodeStyle reads the nearest `.editorconfig`.

```sh
rg --files -g '*.lua' | while read -r file; do
	nvim --headless --clean "$file" +'lua vim.bo.filetype = "lua"; local uv = vim.uv or vim.loop; vim.lsp.start({ name = "emmylua_ls", cmd = { "emmylua_ls", "--log-level", "error" }, root_dir = uv.cwd() }); assert(vim.wait(5000, function() return #vim.lsp.get_clients({ bufnr = 0 }) > 0 end), "emmylua_ls did not attach"); vim.lsp.buf.format({ async = false, timeout_ms = 5000 }); vim.cmd("write"); vim.cmd("quit")'
done
```

Use an `.editorconfig` at the project root for formatter policy. A typical Lua section:

```ini
[*.lua]
max_line_length = 120
end_of_line = lf
indent_style = tab
indent_size = 4
quote_style = double
call_arg_parentheses = remove
auto_collapse_lines = false
```

For a targeted format pass, replace the `rg` command with an explicit file list. For large projects, add `rg -g` excludes for vendored, generated, or build-output directories. Before broad formatting, inspect `git status --short` and avoid mixing formatting churn with unrelated behavioral edits.

## Workflow

1. Reproduce diagnostics with `nvim --headless --clean`; verify the attached client is `emmylua_ls`.
2. Classify each diagnostic: annotation syntax mismatch, nullable context, dynamic dispatch, module return mismatch, or real code issue.
3. Fix annotation shape first. Avoid runtime code changes unless the user asked for behavior changes or the diagnostic exposes a real bug.
4. Re-run clean headless diagnostics on both provider and consumer files.
5. If formatting is requested, run the batch formatting command through EmmyLua LSP and review the diff.
