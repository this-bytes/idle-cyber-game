-- Configuration for Smart UI Integration Demo
function love.conf(t)
    t.identity = "smart_ui_integration_demo"
    t.version = "11.5"
    t.console = false
    
    t.window.title = "Smart UI Framework Integration Demo"
    t.window.icon = nil
    t.window.width = 1280
    t.window.height = 800
    t.window.borderless = false
    t.window.resizable = true
    t.window.minwidth = 800
    t.window.minheight = 600
    t.window.fullscreen = false
    t.window.vsync = 1
    t.window.msaa = 0
    
    t.modules.audio = true
    t.modules.event = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = false
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.physics = false
    t.modules.sound = true
    t.modules.system = true
    t.modules.timer = true
    t.modules.touch = false
    t.modules.video = false
    t.modules.window = true
    t.modules.thread = true
end
