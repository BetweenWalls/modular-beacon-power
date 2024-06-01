--- settings.lua

data:extend ({
    {
        type = "double-setting",
        name = "mbp-power-minimum",
        setting_type = "startup",
        minimum_value = 0.1,
        maximum_value = 1,
        default_value = 0.2,
        forced_value = 0.2, -- sets the minimum power consumption fraction which beacons can be reduced to
        hidden = true,
        order = "1"
    },
    {
        type = "bool-setting",
        name = "mbp-apply-efficiency",
        setting_type = "startup",
        default_value = true,
        forced_value = true, -- module bonuses are multiplied by the beacon's efficiency before affecting the beacon
        hidden = true,
        order = "2"
    },
    {
        type = "bool-setting",
        name = "mbp-skip-beacons",
        setting_type = "startup",
        default_value = true,
        forced_value = true, -- disables modular power functionality for specific "skipped" beacons listed in data-final-fixes.lua
        hidden = true,
        order = "3"
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
        default_value = true,
        order = "b"
    },
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