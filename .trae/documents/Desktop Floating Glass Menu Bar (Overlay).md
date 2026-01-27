## Constraints (Restated)
- Desktop-class only: macOS + Windows + iPad.
- Equivalent visual outcome + interaction model + spatial behavior across all desktop platforms.
- The bar is an **overlay surface**: content scrolls underneath with **no padding, no reserved space, no fixed footer**.
- Not a mobile bottom navigation pattern.

## Why Screenshot 2 Feels “Floating” (While a Naive Bottom Bar Feels “Covering”)
- **Floating** is a perception stack:
  - **Optical detachment**: the surface samples the scene (backdrop blur) + applies a subtle tint, so it reads as *material* rather than a painted rectangle.
  - **Depth cue**: soft shadow/ambient occlusion implies a higher z-layer, so your brain classifies it as *above* the canvas.
  - **No structural edge**: it avoids becoming the bottom “frame” of the window (not full-width, not flush to edges, no hard top edge).
  - **Continuity of canvas**: because content moves behind it (instead of stopping at it), the bar reads as a tool floating over a continuous space.
- **Covering** happens when the bar is treated as part of the layout:
  - Reserved space or reflow implies it is a permanent region.
  - Full-width + edge-flush implies it is a docked panel.
  - A divider/hard edge creates a “cut line” that visually separates regions.
  - Opacity-only tint reads as “dark overlay” rather than “glass material”.

## Apple UI Concepts (Correct Anchors)
- **Material**: a translucent surface that derives appearance from the environment (tinted + blurred background sampling).
- **Backdrop Blur**: blur is driven by the pixels behind the surface (scene-aware), not a static transparency.
- **Vibrancy (Related Concept)**: foreground content (icons/text) can feel embedded in the material via contrast treatment.
- **Overlay Surface**: composited above the primary content, not participating in layout flow.
- **Elevation / Z-Ordering**: depth cues (shadow + occlusion) communicate layering.
- **Edge-less Composition**: no hard separator; separation emerges from material + depth rather than borders/dividers.
- **Floating Toolbar / HUD-like Control**: functionally closer to a floating control cluster than a structural bar.
  - Optional Apple naming anchor (taste): **Conceptually closer to a floating toolbar / palette (macOS) than a navigation bar.**

## Single Canonical Layout Model (Works Across All Desktop Platforms)
- **Base layer**: scrollable main canvas (the “world”).
- **Overlay layer**: bottom-centered floating control surface composited above the canvas.
- **Critical loophole closure**: **The overlay is anchored visually near the bottom edge but is not anchored structurally to the window edge.** This prevents the common mistake of “bottomCenter alignment inside a layout container” instead of true overlay space.
- **Optical recipe (material object, not tinted rectangle)**:
  - Clip to a rounded capsule.
  - Apply **shape-clipped** backdrop blur (blur only inside the capsule).
  - Add low-alpha tint to set the material’s tone.
  - Add a subtle highlight stroke (specular edge) to enhance “glass”.
  - Add a soft shadow (ambient) to indicate elevation.
- **Interaction model**:
  - The overlay captures input only within its bounds; outside it, content remains directly scrollable and interactive.
  - Keyboard focus/hover behavior should match desktop toolbars (no mobile-style selection states).

## Common Implementation Mistakes (That Break the Floating Effect)
- Implementing it as a **footer region** (layout-reserved space, content reflow).
- Making it **full-width** and/or flush to the window edge (reads as docked panel).
- Using **opacity alone** (tinted rectangle) instead of backdrop sampling + blur.
- Adding a **hard top edge** (divider line) or sharp corners; using a rigid rectangle instead of a clipped, rounded silhouette.
- Applying **full-screen blur** or blurring the entire scene behind everything (destroys “material object” perception).
- Incorrect depth: no shadow, harsh shadow, or shadow that implies it’s behind content.
- Adding padding/safe-area compensation that **pushes content up** (violates overlay behavior).
- Styling it like mobile bottom navigation (persistent selection states, nav labeling patterns).

## Flutter Implementation Plan (When You Confirm)
1. Scan the current desktop shell to locate sidebar contextual actions and their triggers.
2. Define a desktop-only floating overlay bar component with a layout-agnostic internal control row.
3. Re-route the contextual actions from sidebar menus into the overlay bar (keep business logic shared).
4. Implement glass rendering via **shape-clipped** backdrop blur + tint + highlight stroke + soft shadow.
5. Integrate as a true overlay stacked above the scrollable content so the canvas scrolls underneath with no reserved space.
6. Desktop interaction pass: hover/focus, keyboard traversal, pointer hit-testing, and accessibility semantics.
7. Verify equivalent spatial behavior on macOS/Windows/iPad and validate performance.
8. Update CHANGELOG.md with an entry describing the UI change.

Proceed with the Flutter implementation now?