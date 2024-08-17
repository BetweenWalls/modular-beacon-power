--- settings.lua

data:extend ({
    {
        type = "double-setting",
        name = "mbp-power-minimum",
        setting_type = "startup",
        minimum_value = 0.1,
        maximum_value = 1,
        default_value = 0.2,
        forced_value = 0.2, -- sets the minimum power consumption fraction which beacons can be reduced to (vanilla uses 0.2 for other machines)
        hidden = true,
        order = "1"
    },
    {
        type = "bool-setting",
        name = "mbp-skip-beacons",
        setting_type = "startup",
        default_value = true,
        forced_value = true, -- disables modular power functionality for specific "skipped" beacons listed in data-final-fixes.lua
        hidden = true,
        order = "2"
    },
    {
        type = "bool-setting",
        name = "mbp-negative-bonuses",
        setting_type = "startup",
        default_value = true,
        order = "a"
    },
    {
        type = "bool-setting",
        name = "mbp-positive-bonuses",
        setting_type = "startup",
        default_value = false,
        order = "b"
    },
    {
        type = "bool-setting",
        name = "mbp-apply-efficiency",
        setting_type = "startup",
        default_value = false,
        order = "c"
    },
    -- TODO: Add setting which changes negative bonuses (eg. from efficiency modules) to be multiplicative instead of additive?
    -- TODO: Add setting which multiplies negative bonuses by the beacon's total module power? (i.e. beacons with more slots will have more effective efficiency modules)
    {
        type = "int-setting",
        name = "mbp-update-rate",
        setting_type = "runtime-global",
        default_value = 6,
        minimum_value = 1,
        maximum_value = 300,
        order = "x"
    },
    {
        type = "bool-setting",
        name = "mbp-active-mod",
        setting_type = "runtime-global",
        default_value = true,
        order = "y"
    },
})