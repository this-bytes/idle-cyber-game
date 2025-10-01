-- UI Demo Configuration

function love.conf(t)
    t.title = "Smart UI Framework Demo - Idle Sec Ops"
    t.version = "11.4"
    t.window.width = 1024
    t.window.height = 768
    t.window.resizable = false
    t.window.vsync = 1
    t.window.minwidth = 1024
    t.window.minheight = 768
    
    t.modules.joystick = false
    t.modules.physics = false
end
