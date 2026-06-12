# Unified Yoga Tree Plan

## Goal

Refactor the playground view runtime so component render trees participate in one Yoga layout tree. A mounted component must not be an empty layout placeholder whose parent cannot see the component's rendered children.

The refactor should choose the most appropriate runtime model for the playground. It should not preserve old APIs or old execution paths just for compatibility, and it should not mechanically translate the old layout-island implementation.

The immediate regression this model must prevent:

- A parent `view.vbox` mounts a header component without explicit `height`.
- The header component renders a root host node with `height = 74`.
- The following sibling must be laid out after the header, not at the header's original y position.

## Layout-Island Problem

The layout-island implementation gives every component instance its own render root and runs Yoga layout per instance:

- Parent components see `view.mount(...)` as a component placeholder node.
- The placeholder receives only the layout props passed to `view.mount`.
- The child component's own root host node is in a separate Yoga tree.
- Parent layout cannot derive size from the child component's rendered host nodes.

This makes component sizing unlike normal frontend component usage. Internal component layout can draw correctly but still fail to reserve space in the parent.

## Target Model

Use one Yoga tree per mounted top-level view root.

- `view.mount` still creates a component instance, props table, render effect, lifecycle, refs, and interaction state.
- The mounted component owns a Yoga wrapper node in the parent tree as its insertion anchor.
- The component render function renders host nodes into that wrapper node.
- The wrapper node and all descendant host nodes are calculated by the same root `yoga.node_calc`.
- The wrapper is not an empty placeholder: if no explicit size is passed to `view.mount`, its size is derived from its rendered children.
- Top-level `view:mount` still uses the component's mount props as the root wrapper style, usually `width` and `height`.

This is not a compatibility layer for the old island model. The old model should be removed from playground once tests pass.

## Runtime Design

### Render Nodes

Keep two node roles:

- **Host nodes**: `box`, `text`, `canvas`, `transition` layout nodes that draw or contain draw nodes.
- **Component wrapper nodes**: Yoga nodes that anchor a component instance and contain that component's rendered host subtree.

Component wrapper nodes are part of the same Yoga tree as their parent. They may receive layout props from `view.mount`, but they also auto-size from children when no explicit size is provided.

### Render Effects

Each component instance keeps its own render effect.

When a component rerenders:

1. The render context parent is the component wrapper node.
2. Host children are patched under that wrapper.
3. Removed children detach from the same Yoga tree.
4. No per-component `yoga.node_calc` runs.
5. The top-level root is marked dirty for the next draw, hit test, or rect query.

`View:update(dt)` remains the place that flushes reactive effects and advances animations.

### Layout Calculation

Run Yoga calculation from the top-level component wrapper root.

- `View:draw`, `View:pointer`, `View:mouse_button`, and `ViewRef:rect()` must observe a calculated tree.
- The implementation can lazily calculate layout through `ensure_layout(view)` after effects are flushed.
- The root wrapper style comes from top-level mount props and view resize.

### Drawing

Drawing traverses the calculated unified tree.

- A node's local draw offset is still relative to its Yoga parent.
- Component wrapper nodes do not draw by themselves.
- Host nodes draw background, text, canvas commands, transforms, and children.
- Child component output naturally appears in the correct place because its wrapper is in the same tree.

### Hit Testing And Refs

Refs and hit testing should use Yoga coordinates from the unified tree.

- `ref:rect()` reads the target node rect relative to the component that created the ref.
- Component refs point to their wrapper node, but the exposed rect still uses the ref owner's local coordinate space.
- Pointer events target clickable component instances.
- Local pointer coordinates are relative to the target component wrapper.

### Destroy

Destroy must remove the component wrapper node from its Yoga parent and recursively dispose component instances, transitions, refs, animations, and render nodes.

The runtime should use `yoga.node_remove(parent, child)` before `yoga.node_free(child)` for nodes that are still attached.

## Tests

Add or keep focused tests for these cases:

1. **Intrinsic component height**
   - Parent `vbox` mounts a header component without mount `height`.
   - Header renders a host root with `height = 74`.
   - The next sibling starts at y = 74.

2. **Parent size propagation**
   - Parent slot or wrapper has a fixed size.
   - Child component uses `width = "100%"` and `height = "100%"`.
   - Child rect matches the parent container.

3. **Interaction after nested component layout**
   - Button, nav item, toggle, and select still receive clicks at their visual positions.

4. **Dropdown overlay geometry**
   - Select options drawn under the trigger must be hit-testable.
   - Opening the menu must not resize the trigger row unless the component deliberately does so.

5. **Animation and transition**
   - Existing animation and transition smoke tests continue to pass.

6. **Destroy detach**
   - Destroying a mounted component removes its Yoga contribution from parent layout.

## Implementation Phases

### Phase 1: Lock Current Expected Behavior

- Add intrinsic component layout tests.
- Add a parent-size test if missing.
- Run existing interaction and animation smoke tests.

### Phase 2: Remove Per-Instance Layout Islands

- Replace per-instance `render_root` layout calculation with a top-level unified layout calculation.
- Make component wrapper nodes contain the component render output.
- Remove fallback origin propagation that exists only for separate trees.
- Ensure top-level mount and resize update root wrapper styles.

### Phase 3: Rework Geometry

- Reimplement internal tree-space geometry for hit testing, while keeping `ref:rect()` owner-local against the unified Yoga tree.
- Keep refs on host nodes and component wrappers.
- Add tests for nested refs and nested click targets.

### Phase 4: Rework Draw Compilation

- Compile or traverse draw output from the unified calculated tree.
- Keep canvas command reuse.
- Ensure transforms apply to the node subtree.

### Phase 5: Diagnostics And Visual Validation

- Run focused `.dl` tests.
- Run `test_components.dl` manually to inspect the showcase.
- Run `test_view_performance.dl` manually to compare render and draw cost.
- Run EmmyLua diagnostics on changed non-test Lua files.

## Verification Commands

```sh
timeout --kill-after=1s 10s ./soluna/bin/linux/release/soluna test.dl
TEST_KIND=feature timeout --kill-after=1s 10s ./soluna/bin/linux/release/soluna test.dl
```

Run a single smoke or feature file with `TEST_NAME`:

```sh
TEST_NAME=layout timeout --kill-after=1s 10s ./soluna/bin/linux/release/soluna test.dl
TEST_KIND=feature TEST_NAME=showcase_interaction timeout --kill-after=1s 10s ./soluna/bin/linux/release/soluna test.dl
```
