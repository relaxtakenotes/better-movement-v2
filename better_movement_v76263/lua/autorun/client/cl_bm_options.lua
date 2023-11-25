hook.Add("PopulateToolMenu", "bm_settings_populate", function()
    spawnmenu.AddToolMenuOption("Options", "bm_8841_tool", "bm_8841_main", "Main", nil, nil, function(panel)
        panel:ClearControls()

        panel:CheckBox("Enabled", bm_vars.enabled:GetName())

        panel:CheckBox("Inside Checks", bm_vars.inside_checks_enabled:GetName())
        panel:NumSlider("Inside Checks Time", bm_vars.inside_checks_period:GetName(), 0, 10, 2)

        panel:CheckBox("Force Slow Footsteps", bm_vars.slow_footsteps:GetName())
        panel:ControlHelp("Pretty experimental. Expect issues. Restart the game if changed!")

        panel:CheckBox("Anim-Based Footsteps", bm_vars.animevent_footsteps:GetName())
        panel:ControlHelp("Pretty experimental. Expect issues. Enable it together with slow foosteps.")

        panel:NumSlider("Interp Mult", bm_vars.interpolation_multiplier:GetName(), 0, 5, 2)
        panel:NumSlider("Interp Type", bm_vars.interpolation_type:GetName(), 0, 1, 0)
    end)

    spawnmenu.AddToolMenuOption("Options", "bm_8841_tool", "bm_8841_speed", "Speed", nil, nil, function(panel)
        panel:ClearControls()

        panel:NumSlider("Run", bm_vars.speed.run:GetName(), 0, 1000, 0)
        panel:NumSlider("Walk", bm_vars.speed.walk:GetName(), 0, 1000, 0)
        panel:NumSlider("Slow Walk", bm_vars.speed.slowwalk:GetName(), 0, 1000, 0)
        panel:NumSlider("Inside Mult", bm_vars.speed.inside_multiplier:GetName(), 0, 1, 2)
        panel:NumSlider("Crouched Mult", bm_vars.speed.crouch:GetName(), 0, 1, 2)
        panel:NumSlider("Duck", bm_vars.speed.duck:GetName(), 0, 1, 2)
        panel:NumSlider("Unduck", bm_vars.speed.unduck:GetName(), 0, 1, 2)
    end)

    spawnmenu.AddToolMenuOption("Options", "bm_8841_tool", "bm_8841_slowdown", "Slowdown", nil, nil, function(panel)
        panel:ClearControls()

        panel:CheckBox("On Landing", bm_vars.slowdown.landing:GetName())
        panel:CheckBox("After Jumping", bm_vars.slowdown.after_jump:GetName())
        panel:CheckBox("No Air Strafe", bm_vars.slowdown.in_air:GetName())

        panel:CheckBox("Non Forward", bm_vars.slowdown.non_forward:GetName())
        panel:NumSlider("Non Forward Mult", bm_vars.slowdown.non_forward_multiplier:GetName(), 0, 1, 2)

        panel:CheckBox("Slope", bm_vars.slowdown.angle_enabled:GetName())
        panel:NumSlider("Slope Mult", bm_vars.slowdown.angle_multiplier:GetName(), 0, 1, 2)

        panel:CheckBox("On Turn", bm_vars.slowdown.turn_enabled:GetName())
        panel:NumSlider("On Turn Mult", bm_vars.slowdown.turn_multiplier:GetName(), 0, 1, 2)

        panel:CheckBox("Weakness", bm_vars.slowdown.weakness_enabled:GetName())
        panel:NumSlider("Weakness Mult", bm_vars.slowdown.weakness_multiplier:GetName(), 0, 1, 2)
        panel:NumSlider("Weakness Rest Mult", bm_vars.slowdown.weakness_rest_multiplier:GetName(), 0, 1, 2)
    end) 

    spawnmenu.AddToolMenuOption("Options", "bm_8841_tool", "bm_8841_spawndeathfx", "Steptime", nil, nil, function(panel)
        panel:ClearControls()

        panel:NumSlider("Exponent", bm_vars.steptime.exponent:GetName(), 0.1, 2, 2)
        panel:NumSlider("Multiplier", bm_vars.steptime.multiplier:GetName(), 0, 10000, 0)
        panel:NumSlider("Offset", bm_vars.steptime.offset:GetName(), 0, 1000, 0)
        panel:NumSlider("Max", bm_vars.steptime.max:GetName(), 0, 1000, 0)
        panel:NumSlider("Min", bm_vars.steptime.min:GetName(), 0, 1000, 0)
    end)
end)

hook.Add("AddToolMenuCategories", "bm_add_category", function() 
    spawnmenu.AddToolCategory("Options", "bm_8841_tool", "Better Movement")
end)