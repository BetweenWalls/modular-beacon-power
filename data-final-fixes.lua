---- data-final-fixes.lua

local DELIMITER = "__MBP"
local POWER_MINIMUM = 0.2  -- beacons cannot be reduced below this amount of their original power consumption (vanilla uses 0.2 for other machines)
local UNIT_MULTIPLIERS = {
    [""] = 1,
    ["k"] = 1000,
    ["K"] = 1000,
    ["M"] = 1000000,
    ["G"] = 1000000000,
    ["T"] = 1000000000000,
    ["P"] = 1000000000000000,
    ["E"] = 1000000000000000000,
    ["Z"] = 1000000000000000000000,
    ["Y"] = 1000000000000000000000000
}
local BEACONS_TO_SKIP = { -- these currently don't work with modular power due to conflicting scripts
    "nullius-beacon-1", "nullius-beacon-1-1", "nullius-beacon-1-2", "nullius-beacon-1-3", "nullius-beacon-1-4",
    "nullius-beacon-2", "nullius-beacon-2-1", "nullius-beacon-2-2", "nullius-beacon-2-3", "nullius-beacon-2-4",
    "nullius-beacon-3", "nullius-beacon-3-1", "nullius-beacon-3-2", "nullius-beacon-3-3", "nullius-beacon-3-4",
    "nullius-large-beacon-1", "nullius-large-beacon-2",
    "beacon-AM1-FM1", "beacon-AM1-FM2", "beacon-AM1-FM3", "beacon-AM1-FM4", "beacon-AM1-FM5",
    "beacon-AM2-FM1", "beacon-AM2-FM2", "beacon-AM2-FM3", "beacon-AM2-FM4", "beacon-AM2-FM5",
    "beacon-AM3-FM1", "beacon-AM3-FM2", "beacon-AM3-FM3", "beacon-AM3-FM4", "beacon-AM3-FM5",
    "beacon-AM4-FM1", "beacon-AM4-FM2", "beacon-AM4-FM3", "beacon-AM4-FM4", "beacon-AM4-FM5",
    "beacon-AM5-FM1", "beacon-AM5-FM2", "beacon-AM5-FM3", "beacon-AM5-FM4", "beacon-AM5-FM5",
    "diet-beacon-AM1-FM1", "diet-beacon-AM1-FM2", "diet-beacon-AM1-FM3", "diet-beacon-AM1-FM4", "diet-beacon-AM1-FM5",
    "diet-beacon-AM2-FM1", "diet-beacon-AM2-FM2", "diet-beacon-AM2-FM3", "diet-beacon-AM2-FM4", "diet-beacon-AM2-FM5",
    "diet-beacon-AM3-FM1", "diet-beacon-AM3-FM2", "diet-beacon-AM3-FM3", "diet-beacon-AM3-FM4", "diet-beacon-AM3-FM5",
    "diet-beacon-AM4-FM1", "diet-beacon-AM4-FM2", "diet-beacon-AM4-FM3", "diet-beacon-AM4-FM4", "diet-beacon-AM4-FM5",
    "diet-beacon-AM5-FM1", "diet-beacon-AM5-FM2", "diet-beacon-AM5-FM3", "diet-beacon-AM5-FM4", "diet-beacon-AM5-FM5",
    "ei_copper-beacon", "ei_iron-beacon", "ei_alien-beacon",
    "el_ki_beacon_entity", "fi_ki_beacon_entity", "fu_ki_beacon_entity",
    "el_ki_core_slave_entity", "fi_ki_core_slave_entity", "fu_ki_core_slave_entity",
    "cube-beacon",
    "warptorio-beacon-1", "warptorio-beacon-2", "warptorio-beacon-3", "warptorio-beacon-4", "warptorio-beacon-5",
    "warptorio-beacon-6", "warptorio-beacon-7", "warptorio-beacon-8", "warptorio-beacon-9", "warptorio-beacon-10"
}
local startup = settings.startup
POWER_MINIMUM = tonumber(math.floor(math.ceil(startup["mbp-power-minimum"].value*1000)/50)/10)/2 or 0.2 -- rounded to nearest 5%
local apply_efficiency = startup["mbp-apply-efficiency"].value
local skip_beacons = startup["mbp-skip-beacons"].value
local positive_bonuses = startup["mbp-positive-bonuses"].value
local negative_bonuses = startup["mbp-negative-bonuses"].value

--- Convert an energy string to base unit value + suffix.
--- Returns `nil` if `energy_string` is incorrectly formatted.
--- @param energy_string string
--- @return number?
--- @return string?
function get_energy_value(energy_string)
    if type(energy_string) == "string" then
        local v, _, mult, unit = string.match(energy_string, "([%-+]?[0-9]*%.?[0-9]+)((%D*)([WJ]))")
        local value = tonumber(v)
        if value and mult and UNIT_MULTIPLIERS[mult] then
            value = value * UNIT_MULTIPLIERS[mult]
            return value, unit
        end
    end
    return nil
end

--- Returns the "ID" for a beacon name corresponding to the given power consumption value
--- @param value double
--- @param unlimited boolean?
--- @return string
function normalize(value, unlimited)
    if value < POWER_MINIMUM-1 and not unlimited then value = POWER_MINIMUM-1 end
    return tostring(math.floor(math.ceil(value*1000)/10)) -- decimal value is rounded to the nearest 1%
end

--- Convert an ordered table to a key-value table with values of "true"
--- @param input table
--- @return table
function key_list(input)
    local output = {}
    for _,v in ipairs(input) do
        output[v] = true
    end
    return output
end

--- Removes duplicate values from a table
--- @param input table
--- @return table
function remove_duplicates(input)
    local output = {}
    local hash = {}
    for _,v in ipairs(input) do
        if (not hash[v]) then
            output[#output+1] = v
            hash[v] = true
        end
    end
    return output
end

--- Returns true if the beacon should have modular power
--- @param beacon data.BeaconPrototype
--- @return boolean
function is_valid(beacon)
    if skip_beacons and BEACONS_TO_SKIP[beacon.name] then return false end
    if not beacon.minable then return false end
    local consumption = false
    if beacon.allowed_effects then
        for i=1,#beacon.allowed_effects do
            if beacon.allowed_effects[i] == "consumption" then consumption = true end
        end
    end
    if not consumption then return false end
    if get_energy_value(beacon.energy_usage) == 0 then return false end
    if beacon.module_slots == 0 then return false end
    -- TODO: selectable? some beacons have modules automatically inserted into them and cannot be changed, so their power requirements are likely balanced around their static effect
    return true
end

-- Setup general relevant values: maximum beacon module slots, minimum efficiency of any beacon, whether productivity modules are allowed
local max_slots = 0
local min_eff = 100
local include_prod_modules = false
for _, beacon in pairs(data.raw.beacon) do
    local slots = beacon.module_slots or 0
    if slots > max_slots then max_slots = slots end
    if beacon.distribution_effectivity < min_eff then min_eff = beacon.distribution_effectivity end
    if beacon.allowed_effects then
        local prod_consumption = 0
        for i=1,#beacon.allowed_effects do
            if beacon.allowed_effects[i] == "consumption" or beacon.allowed_effects[i] == "productivity" then prod_consumption = prod_consumption + 1 end
        end
        if prod_consumption == 2 then include_prod_modules = true end
    end
end
-- TODO: Add "tags" to values from prod modules, so that the combined values can have the same tags and only apply to beacons which can use prod modules? Same concept could apply to other module effects

-- Create list of unique power consumption values from individual modules
local module_powers = {}
for _, module in pairs(data.raw.module) do
    if module.effect.consumption and module.effect.consumption ~= 0 then
        if module.effect.productivity == nil or include_prod_modules then
            local bonus = module.effect.consumption
            if ((positive_bonuses or bonus < 0) and (negative_bonuses or bonus > 0)) then
                table.insert(module_powers, bonus)
            end
        end
    end
end
module_powers = remove_duplicates(module_powers)

-- Record unique power values for each number of module slots
local combos = {[1]=module_powers}
for slots=2,max_slots do
    combos[slots] = {}
    for _, value in pairs(combos[slots-1]) do
        table.insert(combos[slots], value)
        for i=1,#module_powers do
            local pvalue = value + module_powers[i]
            if pvalue * min_eff >= POWER_MINIMUM-1 then
                if pvalue % 1 ~= 0 then pvalue = (math.floor(math.ceil(pvalue*1000)/10))/100 end -- TODO: why are some values not integers, but extremely close to them instead?
                if pvalue ~= 0 then table.insert(combos[slots], pvalue) end
            end
        end
        combos[slots] = remove_duplicates(combos[slots])
    end
end

-- Compile list of beacon entities to create which correspond to all possible power consumption values
local new_beacons = {}
BEACONS_TO_SKIP = key_list(BEACONS_TO_SKIP)
for name, beacon in pairs(data.raw.beacon) do
    local slots = beacon.module_slots or 0
    if is_valid(beacon) and combos[slots] then
        local power = get_energy_value(beacon.energy_usage)
        local new_name = beacon.localised_name or {"entity-name."..name} or {"item-name."..name} or {"name."..name}
        local new_description = beacon.localised_description or {"entity-description."..name} or {"item-description."..name} or {"description."..name}
        for _, value in pairs(combos[slots]) do
            if apply_efficiency then value = value * beacon.distribution_effectivity end
            if value < POWER_MINIMUM-1 then value = POWER_MINIMUM-1 end
            local id = normalize(value)
            local new_power = power + power * value
            table.insert(new_beacons, {base=name, id=id, energy=new_power, name=new_name, description=new_description})
        end
        if beacon.fast_replaceable_group == nil then beacon.fast_replaceable_group = beacon.name end
    end
end
--new_beacon = table.sort(new_beacon)

-- Creates new beacons with adjusted power requirements
for _, info in pairs(new_beacons) do
    local new_beacon = table.deepcopy(data.raw.beacon[info.base])
    new_beacon.name = info.base..DELIMITER..info.id
    new_beacon.energy_usage = info.energy.."W"
    new_beacon.placeable_by = {item = new_beacon.minable.result or new_beacon.minable.results[1].name, count = 1}
    new_beacon.next_upgrade = nil
    new_beacon.hidden = true
    if info.name then new_beacon.localised_name = info.name end
    if info.description then new_beacon.localised_description = info.description end
    data:extend({new_beacon})
end
-- TODO: Set a limit for how many entities should be created? If other mods add many beacons and modules, the potential number of combinations can become so great that the game "hangs" when loading (due to insufficient memory, presumably)
