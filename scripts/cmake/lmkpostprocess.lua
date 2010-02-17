require "lmkbuild"
local abs_path = lmkbuild.abs_path
local append = lmkbuild.append_global
local get_var = lmkbuild.get_var
local io = io
local ipairs = ipairs
local pairs = pairs
local print = print
local resolve = lmkbuild.resolve

module (...)

function main ()
   local BuildType = resolve ("$(type)")
   local addType = nil
   if BuildType == "exe" then
      addType = resolve ("add_executable($(name)\n")
   elseif BuildType == "plugin" then
      addType = resolve ("add_library($(name) MODULE\n")
   elseif BuildType == "shared" then
      addType = resolve ("add_library($(name) SHARED\n")
   end
   if addType then
      local fileName = resolve ("$(localCMakeDir)CMakeLists.txt")
      local file = io.open (fileName, "w")
      if file then
         local includes = get_var ("localIncludes")
         if includes then
            file:write ("include_directories(BEFORE\n") 
            for _, val in ipairs (includes) do
               local path = abs_path (resolve (val))
               if path then file:write (path .. "\n") end
            end
            file:write (")\n")
         end
         local defines = get_var ("localDefines")
         if defines then
            file:write ("add_definitions(\n") 
            for _, val in ipairs (defines) do
               file:write (resolve (val) .. "\n")
            end
            file:write (")\n")
         end
         file:write (addType)
         local src = get_var ("cmake_src")
         if src then
            for _, dep in ipairs (src) do file:write (dep .. "\n") end
         end
         file:write (")\n")
         local libs = get_var ("libs")
         if libs then
            file:write (resolve ("target_link_libraries($(name)\n"))
            for _, val in ipairs (libs) do
               file:write (val .. "\n")
            end
            file:write (")\n")
         end
         libs = get_var ("localLibs")
         if libs then
            file:write (resolve ("target_link_libraries($(name)\n"))
            for _, val in ipairs (libs) do
               file:write ('"' .. resolve (val) ..  '"' .. "\n")
            end
            file:write (")\n")
         end
         libs = get_var ("localLibPaths")
         if libs then
            file:write (resolve ("set_target_properties($(name)\n"))
            for _, val in ipairs (libs) do
               file:write ('PROPERTIES LINK_FLAGS "' .. resolve (val) ..  '"' .. "\n")
            end
            file:write (")\n")
         end
         file:write (resolve ("set_target_properties($(name) " ..
            "PROPERTIES LIBRARY_OUTPUT_DIRECTORY $(lmk.libDir))\n"))
         file:write (resolve ("set_target_properties($(name) " ..
            "PROPERTIES RUNTIME_OUTPUT_DIRECTORY $(lmk.binDir))\n"))

         file:close ()
         file = nil
         append ("lmk.nameList", resolve ("$(name)"))
      end
   end
end
