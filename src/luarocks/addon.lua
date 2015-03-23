--- Addons.
local addon = {}
package.loaded["luarocks.addon"] = addon

-- TODO Let type_check export this and use it
local string_1 = { _type = "string" }

addon.addons = {
   {
      name = "hello",
      types = { hello_target = string_1 },
      run = function(tbl)
         print("Hello "..(tbl.hello_target or "world").. "!")
      end
   },
   {
      name = "bye",
      types = { bye_target = string_1 },
      run = function(tbl)
         print("Bye "..(tbl.bye_target or "cruel world").. "!")
      end
   }
}

addon.addons_map = {}

for _, a in ipairs(addon.addons) do
   addon.addons_map[a.name] = a
end

function addon.augment_addon_types(typetbl, addons)
   local augmented_typetbl, origin = {}, {}
   for k, t in pairs(typetbl) do
      augmented_typetbl[k] = t
      origin[k] = "builtin fields"
   end
   for _, a in ipairs(addons) do
      for k, t in pairs(a.types) do
         if augmented_typetbl[k] ~= nil then
            return nil, "Field "..k.." in addon "..a.name.." conflicts with that from "..origin[k]
         end
         augmented_typetbl[k] = t
         origin[k] = "addon "..a.name
      end
   end
   return augmented_typetbl
end

function addon.run_addons(rockspec)
   if not rockspec.using then return end
   for _, name in ipairs(rockspec.using) do
      addon.addons_map[name].run(rockspec)
   end
end
