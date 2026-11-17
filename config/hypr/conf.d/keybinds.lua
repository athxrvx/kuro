return function(apps)
    local mod = "SUPER" -- Physical Alt key after kuro's xkb swap.
    local barLayout = apps.barLayout

    hl.bind(mod .. " + Q",                 hl.dsp.window.close())
    hl.bind(mod .. " + SHIFT + Return",    hl.dsp.exec_cmd(apps.terminal))
    hl.bind(mod .. " + A",                 hl.dsp.exec_cmd("qs -c shell ipc call launcher toggle"))
    hl.bind(mod .. " + V",                 hl.dsp.exec_cmd("qs -c shell ipc call launcher enter sys-clipboard"))
    hl.bind(mod .. " + TAB",               hl.dsp.exec_cmd("qs -c shell ipc call overview toggle"))
    hl.bind(mod .. " + N",                 hl.dsp.exec_cmd("qs -c shell ipc call notifications toggle"))
    hl.bind(mod .. " + L",                 hl.dsp.exec_cmd("qs -c shell ipc call lock lock"))
    hl.bind(mod .. " + B",                 hl.dsp.exec_cmd(barLayout))
    hl.bind(mod .. " + SHIFT + B",         hl.dsp.exec_cmd(barLayout .. " next"))
    hl.bind(mod .. " + M",                 hl.dsp.exec_cmd("hyprctl dispatch exit"))
    hl.bind(mod .. " + E",                 hl.dsp.exec_cmd(apps.fileManager))
    hl.bind(mod .. " + F",                 hl.dsp.window.float({ action = "toggle" }))
    hl.bind(mod .. " + R",                 hl.dsp.exec_cmd(apps.menu))
    hl.bind(mod .. " + space",             hl.dsp.exec_cmd("qs -c shell ipc call launcher toggle"))
    hl.bind(mod .. " + P",                 hl.dsp.window.pseudo())
    hl.bind(mod .. " + J",                 hl.dsp.layout("togglesplit"))

    hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }))
    hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
    hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "up" }))
    hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "down" }))

    for i = 1, 10 do
        local key = i % 10
        hl.bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
        hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
    end

    hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
    hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
    hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
    hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
end
