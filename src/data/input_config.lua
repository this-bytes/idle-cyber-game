-- Input Configuration - Action Mappings for Idle Sec Ops
-- Defines how keyboard keys and mouse regions map to game actions
-- Supports accessibility and multiple input methods

local inputConfig = {}

-- Action mappings: action_name -> {keys = {...}, mouseRegions = {...}}
inputConfig.actions = {
    -- Manual income generation
    manual_income = {
        keys = {"space", "m"},
        mouseRegions = {"money_counter", "manual_income_button"}
    },

    -- UI Navigation
    navigate_next = {
        keys = {"tab", "right"},
        mouseRegions = {}
    },
    navigate_back = {
        keys = {"escape", "left"},
        mouseRegions = {}
    },

    -- Quick actions (for future use)
    quick_action_1 = {
        keys = {"1"},
        mouseRegions = {}
    },
    quick_action_2 = {
        keys = {"2"},
        mouseRegions = {}
    },
    quick_action_3 = {
        keys = {"3"},
        mouseRegions = {}
    },

    -- Menu shortcuts
    open_upgrades = {
        keys = {"u"},
        mouseRegions = {}
    },
    open_contracts = {
        keys = {"c"},
        mouseRegions = {}
    },
    open_specialists = {
        keys = {"s"},
        mouseRegions = {}
    }
}

-- Click regions: region_name -> {x, y, width, height}
inputConfig.clickRegions = {
    -- Money counter area (approximate coordinates based on SOC view layout)
    money_counter = {
        x = 20,
        y = 80,
        width = 280,
        height = 40
    },

    -- Future regions for UI elements
    upgrade_button = {
        x = 300,
        y = 200,
        width = 100,
        height = 30
    },
    manual_income_button = {
        x = 320,
        y = 80,
        width = 120,
        height = 40
    },
    contract_button = {
        x = 300,
        y = 240,
        width = 100,
        height = 30
    }
}

return inputConfig