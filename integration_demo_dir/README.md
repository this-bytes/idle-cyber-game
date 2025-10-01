# Smart UI Framework Integration Demo

This demo showcases the Smart UI Framework integrated into the Idle Sec Ops game.

## Features Demonstrated

### 1. Main Menu View
- Component-based main menu with cyberpunk styling
- Responsive buttons with hover effects
- Clean layout with proper spacing
- Scene transition handling

### 2. SOC View Demo
- Complete game interface with header, sidebar, and main panel
- Resource display (money, reputation, XP)
- Panel navigation buttons
- Threat monitoring interface
- Toast notifications for user feedback

### 3. Components Gallery
- Different panel styles (square, rounded, cut)
- Various button types with toast notifications
- Grid layout for data tables
- Typography and text rendering

## Running the Demo

```bash
# From the repository root
love integration_demo_dir

# Or if you have the repo cloned elsewhere
cd /path/to/idle-cyber-game
love integration_demo_dir
```

## Controls

- **Click buttons** - Interact with UI elements
- **Mouse wheel** - Scroll viewport if content exceeds screen
- **F12** - Take a screenshot
- **ESC** - Quit the demo

## Architecture

The demo uses the complete Smart UI Framework stack:

- **ScrollContainer** - Viewport management with automatic scrolling
- **Box** - Flexbox-like layout for responsive designs
- **Panel** - Styled containers with titles and effects
- **Text** - Smart text rendering with wrapping
- **Button** - Interactive buttons with state management
- **Grid** - Table layouts for structured data
- **ToastManager** - Notification system with animations

## Integration with Game

This demo shows exactly how the Smart UI components are integrated into:
- Main menu scene (`src/scenes/smart_main_menu.lua`)
- SOC view scene (`src/scenes/smart_soc_view.lua`)
- Toast notification system (`src/ui/toast_manager.lua`)

All interactions use the event-driven architecture and proper component lifecycle management.

## Visual Features

- **Cyberpunk Aesthetic** - Neon colors, glows, and cut corners
- **Smooth Animations** - Toast notifications slide in and fade out
- **Responsive Layout** - Adapts to window resizing
- **No Off-Screen Rendering** - ScrollContainer prevents UI overflow
- **Interactive Feedback** - Hover states and click responses

## Technical Details

- Built with LÖVE 2D 11.5
- Pure Lua implementation
- No external dependencies beyond LÖVE
- Component-based architecture
- Automatic layout calculations
- Event-driven interactions
