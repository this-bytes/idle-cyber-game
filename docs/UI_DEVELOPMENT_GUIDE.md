# LUIS UI Development Guide

This guide outlines the process for creating new, themed UI scenes using the `base_scene_luis.lua` class. Following this pattern ensures consistency and rapid development.

## Core Concept

All new UI scenes should **inherit** from `src/scenes/base_scene_luis.lua`. This base class automatically handles:

- LUIS Layer creation and destruction.
- Setting a global UI theme for the scene.
- Providing clear "hooks" (`buildUI`, `onDraw`, `onUpdate`) for your scene's specific logic.

This means your scene file only needs to worry about *what* to display, not *how* to integrate with the LUIS system.

## Steps to Create a New Scene

Here is a complete example for a hypothetical `skill_tree.lua` scene.

### 1. Create the Scene File

Create your new file in `src/scenes/` (e.g., `src/scenes/skill_tree.lua`).

### 2. Set Up Inheritance

Add the following boilerplate to the top of your new file. This makes your scene a "child" of the base scene.

```lua
-- Require the base class
local BaseSceneLuis = require("src.scenes.base_scene_luis")

-- Standard Lua inheritance setup
local SkillTreeScene = {}
SkillTreeScene.__index = SkillTreeScene
setmetatable(SkillTreeScene, {__index = BaseSceneLuis})
```

### 3. Create the Constructor

Your `new()` function must call the parent constructor and set the theme.

```lua
function SkillTreeScene.new(eventBus, luis)
    -- 1. Call the parent constructor with a unique layer name
    local self = BaseSceneLuis.new(eventBus, luis, "skill_tree")
    setmetatable(self, SkillTreeScene)

    -- 2. Set the theme for the scene
    local myTheme = {
        -- theme data here...
    }
    self:setTheme(myTheme)

    -- 3. Load any assets needed for this scene (images, fonts, etc.)
    self.skillIcons = love.graphics.newImage("assets/icons/skills.png")

    return self
end
```

### 4. Implement the `buildUI` Hook

This is where you create your UI elements. They will automatically use the theme you set in the constructor.

```lua
function SkillTreeScene:buildUI()
    local button = self.luis.newButton("Unlock Skill", 20, 3, function() 
        -- onClick logic
    end, nil, 10, 10)
    
    self.luis.insertElement(self.layerName, button)
end
```

### 5. Implement `onDraw` and `onUpdate` (Optional)

Use these hooks for any custom drawing or animations that are not part of the LUIS UI itself.

```lua
function SkillTreeScene:onDraw()
    -- Draw backgrounds, custom text, particles, etc.
    love.graphics.draw(self.skillIcons, 100, 100)
end

function SkillTreeScene:onUpdate(dt)
    -- Animate your custom graphics
end
```

### 6. Return the Scene

Finally, add `return SkillTreeScene` at the end of your file.

## Theming

The `setTheme(themeTable)` function expects a table containing color and style information. The cyberpunk theme from `main_menu_luis.lua` can be used as a template for a consistent look and feel.

**IMPORTANT:** All color values in the theme table MUST be in the **0-1 range**, not 0-255 (e.g., `255` should be written as `1` or `255/255`).
