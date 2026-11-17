return function()
    hl.layer_rule({
        name  = "quickshell-overview",
        match = { namespace = "^quickshell-overview$" },
        blur  = true,
        ignore_alpha = 0.0,
    })

    hl.layer_rule({
        name  = "quickshell-notifications",
        match = { namespace = "^quickshell-notifications$" },
        blur  = true,
        ignore_alpha = 0.0,
    })

    hl.window_rule({
        name   = "launcher-tui",
        match  = { class = "^omarchy-launcher-tui$" },
        float  = true,
        center = true,
        size   = { 900, 620 },
    })

    hl.window_rule({
        name  = "fix-xwayland-drags",
        match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
        no_focus = true,
    })
end
