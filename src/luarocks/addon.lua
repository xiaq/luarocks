--- Addons.
local addon = {}
package.loaded["luarocks.addon"] = addon

local util = require("luarocks.util")

local addons = {}

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

function addon.run_addons(rockspec)
   -- NOTE We assume that this rockspec has been type-checked and hence all
   -- relevant addons have been loaded.
   local using = rockspec.using
   if not using then return end
   for _, name in ipairs(using) do
      addons[name].run(rockspec)
   end
end
