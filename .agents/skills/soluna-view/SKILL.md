---
name: soluna-view
description: Use when modifying the Soluna Playground reactive view runtime or components under core/view.lua, view/, components_showcase.lua, or test view entries. Covers chunk components, render effects, refs, built-in interaction state, canvas drawing, transition/animation, statistics, and focused verification.
---

# Soluna Playground View

## Design Checklist

Before editing a view component or runtime behavior, identify:

- **Owner**: the component that owns state and derives visual state.
- **Role**: runtime primitive, reusable component, local showcase component, benchmark component, or external observer.
- **Built-ins**: use `view.clickable`, `view.hovered`, `view.pressed`, `view.ref`, `view.value`, `view.computed`, `view.animated`, and `view.transition` before adding APIs.
- **Render props**: read state during render and pass ordinary prop snapshots to children. Pass callable `ViewValue` objects only when the child intentionally participates in the same reactive state.
- **Event flow**: child components report interaction through callback props; owner components update their own state.
- **Geometry**: create refs inside the component that owns the geometry, then use `some_ref:rect()` for owner-local anchors and hit targets.
- **Drawing**: use layout components for ordinary structure. Use `view.canvas` plus `view.batch` when exact visual alignment or custom material drawing belongs to one owner.
- **Observation**: performance counters and debug HUDs should observe the view from outside the view tree with Soluna batch drawing.
- **API surface**: export only domain-level props or runtime methods needed by current components.

## Component Shape

Components are Lua chunks loaded by `core.view`. Keep this shape:

```lua
local view = require "core.view"

local args = ...
local selected = view.value(false)

return function()
	local active = selected()

	view.hbox({
		width = args.width,
		height = args.height,
		alignItems = "center",
	}, function()
		view.text(active and "Active" or "Idle", {
			width = "100%",
			height = "100%",
			align = "LV",
		})
	end)
end
```

Do not reintroduce a `return function(batch)` component model. Component render functions call `view.box`, `view.hbox`, `view.vbox`, `view.text`, `view.canvas`, and `view.mount` directly.

## State And Props

Owner state stays in the owner component:

```lua
local current = view.value("settings")

return function()
	local active = current()

	view.mount("view/nav_item", {
		id = "settings",
		active = active == "settings",
		on_select = function(id)
			current(id)
		end,
	})
end
```

Child components should normally receive plain values from the parent render. Use a shared `ViewValue` prop only for deliberate low-level cases such as a benchmark row or a component that is explicitly part of the same reactive state.

## Interaction Patterns

Use built-in state inside the component that owns the visual feedback:

```lua
local hovered = view.hovered()
local pressed = view.pressed()

view.clickable {
	enabled = args.enabled,
	on_click = args.on_click,
}

return function()
	local fill = args.background
	if pressed() then
		fill = args.pressed_background
	elseif hovered() then
		fill = args.hover_background
	end

	view.mount("view/surface", {
		fill = fill,
	})
end
```

Do not expose `is_hovered()` or similar child APIs just so a parent can poll internal interaction state. If the parent owns the behavior, use callback props.

## Layout And Render Effects

- Parent rerender does not remount children when `view.mount` chunk and key match.
- Props patched by the parent can trigger child render effects.
- The scheduler coalesces queued effects and orders parent-created effects before later children when they are flushed together.
- Render effect counts are available through `view:statistics().render_count`. Display them from outside the view tree, not with a component that depends on the same render system.

External HUD pattern:

```lua
function C.frame()
	view:update(1 / 60)
	view:draw(batch)
	local render_count = view:statistics().render_count
	-- Draw HUD text with soluna.material.text directly into batch.
end
```

## Refs And Coordinates

`view.ref()` is a component-owned geometry handle. Create refs while the owning component chunk is loading or rendering. `ref:rect()` returns the target rect in the coordinate space of the component that created the ref, matching pointer event local coordinates used by component callbacks.

Use refs for component behavior, such as local hit testing or anchoring visual elements inside the same component. Do not create refs from tests or app-level imperative code just to inspect view tree geometry from outside a component; test user-facing behavior through clicks, pointer movement, or component-owned reporting helpers.

## Canvas And Custom Drawing

Use `view.canvas` for owner-controlled drawing:

```lua
view.canvas({
	width = 120,
	height = 40,
}, function(width, height)
	view.batch:add(sprite, width * 0.5, height * 0.5)
end)
```

Keep custom materials outside `core/view.lua` unless the runtime itself needs a new primitive. Reusable custom drawing can live in `view/` as a component.

## Transitions And Animation

Use `view.animated` for numeric interpolation and `view.transition` for show/hide lifecycle:

```lua
local progress = view.animated(function()
	return args.open and 1 or 0
end, {
	duration = 0.14,
})

return function()
	local t = progress()
	view.mount("view/icon", {
		rotation = view.lerp(0, math.pi, t),
	})
end
```

Prefer animation that can be expressed as transform, opacity, color, or material parameters. Avoid adding runtime clipping or layout mutation APIs unless the view runtime truly needs them.

## Verification

Run focused checks after changes:

```sh
timeout --kill-after=1s 10s ./soluna/bin/linux/release/soluna test.dl
TEST_NAME=component_interaction timeout --kill-after=1s 10s ./soluna/bin/linux/release/soluna test.dl
TEST_NAME=animation timeout --kill-after=1s 10s ./soluna/bin/linux/release/soluna test.dl
TEST_KIND=feature TEST_NAME=showcase_interaction timeout --kill-after=1s 10s ./soluna/bin/linux/release/soluna test.dl
```

Run these manually when checking the visual showcase or live performance HUD:

```sh
TEST_NAME=components ./soluna/bin/linux/release/soluna test.dl
TEST_NAME=performance ./soluna/bin/linux/release/soluna test.dl
```

Use the repository `emmylua-nvim-headless` skill for diagnostics and formatting. Run diagnostics for changed non-test Lua files, and for test files when the change adds typed helpers or benchmark infrastructure.
