--- Addons.
local addon = {}
package.loaded["luarocks.addon"] = addon

local util = require("luarocks.util")

local addons = {}

--- Load a list of addons.
-- An addon "$u" is simply the Lua module "luarocks.addon.$u". It is supposed
-- to contain at least two fields - types, used for type-checking and run, a
-- function to be called with the rockspec table.
local function load_addons(using)
   util.platform_overrides(using)
   for _, u in ipairs(using) do
      local pkg = "luarocks.addon."..u
      local status, err = pcall(require, pkg)
      if not status then return err end
      addons[u] = package.loaded[pkg]
      -- TODO Type-check loaded addon.
   end
end

--- Augment the type table with relevant type tables from required addons.
function addon.augment_addon_types(typetbl, rockspec)
   local using = rockspec.using
   if not using then return typetbl end

   -- TODO Type-check rockspec.using.
   local err = load_addons(using)
   if err then return nil, err end

   local augmented_typetbl, origin = {}, {}
   for k, t in pairs(typetbl) do
      augmented_typetbl[k] = t
      origin[k] = "builtin fields"
   end

   for _, u in ipairs(using) do
      for k, t in pairs(addons[u].types) do
         if augmented_typetbl[k] ~= nil then
            return nil, "Field "..k.." in addon "..a.name.." conflicts with that from "..origin[k]
         end
         augmented_typetbl[k] = t
         origin[k] = "addon "..u
      end
   end
   return augmented_typetbl
end

--- Run addons found in rockspec.using.
function addon.run_addons(rockspec)
   -- NOTE We assume that this rockspec has been type-checked and hence all
   -- relevant addons have been loaded.
   local using = rockspec.using
   if not using then return end
   for _, name in ipairs(using) do
      addons[name].run(rockspec)
   end
end
