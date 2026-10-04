-- Mini Boat: a car-based vehicle that only exists on water.

local MOD = "__mini-boat__"
local NAME = "mini-boat"

---------------------------------------------------------------------------
-- Collision: the boat collides with land (ground tiles), not with water.
-- We start from the vanilla car mask so everything else (player, objects,
-- other vehicles...) keeps working, then swap water <-> land.
---------------------------------------------------------------------------
local function layer_exists(layer)
  local layers = data.raw["collision-layer"]
  return layers ~= nil and layers[layer] ~= nil
end

local function boat_collision_mask()
  local layers = {}
  local constants = data.raw["utility-constants"] and data.raw["utility-constants"]["default"]
  local default = constants and constants.default_collision_masks and constants.default_collision_masks["car"]
  if default and default.layers then
    for layer, enabled in pairs(default.layers) do
      layers[layer] = enabled
    end
  end

  -- Water tiles carry these layers (water_tile, player, item, resource,
  -- doodad, floor). The vanilla car only stays out of water because of
  -- "player", so every one of them has to go or the boat can't touch water.
  for _, layer in pairs({ "water_tile", "player", "item", "resource", "doodad", "floor" }) do
    layers[layer] = nil
  end

  -- keep the layers that make it a normal vehicle, even if defaults change
  layers.car = true
  layers.train = true
  layers.is_object = true

  if layer_exists("ground_tile") then layers.ground_tile = true end  -- collide with land
  if layer_exists("lava_tile") then layers.lava_tile = true end      -- ...and lava

  -- no consider_tile_transitions: the whole hull must be over water
  return { layers = layers }
end

---------------------------------------------------------------------------
-- Entity (copied from the vanilla car so sounds, sizes, remnants etc. are valid)
---------------------------------------------------------------------------
local boat = table.deepcopy(data.raw["car"]["car"])

boat.name = NAME
boat.icon = MOD .. "/graphics/icon.png"
boat.icon_size = 64
boat.icons = nil
boat.minable = { mining_time = 0.5, result = NAME }
boat.max_health = 450
boat.inventory_size = 40

-- no turret, no equipment grid, no headlights
boat.guns = nil
boat.turret_animation = nil
boat.equipment_grid = nil
boat.light = nil
boat.light_animation = nil
boat.water_reflection = nil

-- size: sprite is ~1.9 x 5.6 tiles
boat.collision_box = { { -0.85, -2.6 }, { 0.85, 2.6 } }
boat.selection_box = { { -0.95, -2.85 }, { 0.95, 2.85 } }
boat.collision_mask = boat_collision_mask()

-- handling: heavier and slower than the car, wide turning circle
boat.consumption = "220kW"
boat.effectivity = 0.6
boat.weight = 2500
boat.braking_force = 120
boat.friction_force = 0.004
boat.rotation_speed = 0.0022

-- fuel: chemical (coal, wood, solid fuel...) and nuclear fuel
local smoke = boat.energy_source and boat.energy_source.smoke and boat.energy_source.smoke[1]
if smoke then
  smoke = table.deepcopy(smoke)
  smoke.position = { 0.4, 0.3 }               -- near the smokestack (not rotated with the hull)
  smoke.deviation = { 0.15, 0.15 }
  smoke.frequency = 60
  smoke.starting_vertical_speed = 0.06
  smoke.starting_frame_deviation = 60
end

boat.energy_source = {
  type = "burner",
  fuel_categories = { "chemical", "nuclear" },
  effectivity = 1,
  fuel_inventory_size = 3,
  burnt_inventory_size = 3,                   -- spent nuclear fuel cells go here
  emissions_per_minute = { pollution = 6 },
  smoke = smoke and { smoke } or nil,
}

-- graphics: 64 rotations, 8 per row, sheet 3072x3072, drawn at scale 0.5
local function rotated_layer(file, extra)
  local layer = {
    filename = MOD .. "/graphics/" .. file,
    priority = "low",
    width = 384,
    height = 384,
    frame_count = 1,
    direction_count = 64,
    line_length = 8,
    scale = 0.5,
  }
  for k, v in pairs(extra or {}) do layer[k] = v end
  return layer
end

boat.animation = {
  layers = {
    rotated_layer("boat.png"),
    rotated_layer("boat-shadow.png", { draw_as_shadow = true, shift = { 0.3, 0.22 } }),
  },
}

---------------------------------------------------------------------------
-- Item, recipe, technology
---------------------------------------------------------------------------
local item = {
  type = "item",
  name = NAME,
  icon = MOD .. "/graphics/icon.png",
  icon_size = 64,
  subgroup = "transport",
  order = "b[personal-transport]-a[car]-b[mini-boat]",
  place_result = NAME,
  stack_size = 1,
}

local recipe = {
  type = "recipe",
  name = NAME,
  enabled = false,
  energy_required = 10,
  ingredients = {
    { type = "item", name = "engine-unit", amount = 12 },
    { type = "item", name = "steel-plate", amount = 20 },
    { type = "item", name = "iron-gear-wheel", amount = 10 },
    { type = "item", name = "iron-plate", amount = 40 },
  },
  results = { { type = "item", name = NAME, amount = 1 } },
}

local technology = {
  type = "technology",
  name = NAME,
  icon = MOD .. "/graphics/technology.png",
  icon_size = 256,
  effects = { { type = "unlock-recipe", recipe = NAME } },
  prerequisites = { "automobilism" },
  unit = {
    count = 100,
    ingredients = {
      { "automation-science-pack", 1 },
      { "logistic-science-pack", 1 },
    },
    time = 30,
  },
  order = "e-c-a-b",
}

data:extend({ boat, item, recipe, technology })
