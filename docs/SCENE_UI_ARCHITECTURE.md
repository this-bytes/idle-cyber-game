Scene & UI Architecture

Overview

This document describes the scene, overlay, and input routing model used by the game.

Core ideas

- SceneManager: single active scene at a time (registered by name). Scenes implement enter/exit/update/draw and input handlers.
- OverlayManager: stack-based manager for overlays (modals, debug panels, toasts that need input capture). Overlays live on top of scenes.
- SmartUIManager: component-driven UI renderer for game UI. It returns true/false on mouse events to indicate input consumption.

Input routing rules

1. love callbacks -> SOCGame handlers
2. SOCGame routes input to systems.inputSystem (global handlers like hotkeys)
3. SOCGame asks OverlayManager to dispatch input to overlays (top-down). If any overlay returns true, input stops.
4. If overlays do not consume the input, SOCGame forwards events to SceneManager which forwards to the active scene.
5. Scene's UI components (SmartUIManager, etc.) should return true when they consume input.

Overlay semantics

- Overlays are push/pop managed. The top overlay is considered focused. Input events are dispatched from top->bottom and stop at the first consumer.
- Overlays may be modal (consume all input while visible) or non-modal (return false in input handlers when they want passthrough).
- Overlays should implement optional callbacks: enter(params), exit(), update(dt), draw(), mousepressed(x,y,btn), mousereleased, mousemoved, wheelmoved, keypressed, keyreleased.

Example usage

- Debug overlay (StatsOverlay) is registered with OverlayManager at startup. It is hidden by default; toggling it via F3 sets visible flag. Because it consumes input when visible, scene won't receive input while it's open.
- ExampleModal demonstrates a small modal that closes on click or ESC.

Notes and future improvements

- Scene stack: currently only one scene is active. If you need layered scenes (ex: paused scene over gameplay), extend SceneManager to support a scene stack with similar routing rules.
- Focus API: add explicit focus/keyboard focus helpers so keyboard navigation is owned by a single component.
- Animation and transitions: SceneManager could support async transitions (enter/exit returning promises or callbacks). For now enter/exit are synchronous.
- Accessibility: expose navigation via keyboard and gamepad by implementing keypressed handlers in SmartUIManager components.

