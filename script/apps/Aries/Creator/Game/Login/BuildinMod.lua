--[[
Title: buildin paracraft mod
Author(s):  LiXizhi
Date: 2017.4.23
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/BuildinMod.lua");
local BuildinMod = commonlib.gettable("MyCompany.Aries.Game.MainLogin.BuildinMod");
BuildinMod.AddBuildinMods();
------------------------------------------------------------
]]
-- create class
local BuildinMod = commonlib.gettable("MyCompany.Aries.Game.MainLogin.BuildinMod");

-- package_path can be the same, so the same package zip can contain multiple mods
BuildinMod.buildin_mods = {
	{
		name = "ParaXExporter", 
		-- package_path = "npl_packages/BMaxToParaXExporter/", 
		package_path = "npl_packages/ParacraftBuildinMod/", 
		displayName = L"ParaX 3D模型导出", 
		text=L"系统内置插件",
		version = "1.2",
		homepage = "https://github.com/tatfook/BMaxToParaXExporter",
	},
	{
		name = "NPLCAD", 
		--package_path = "npl_packages/NPLCAD/", 
		package_path = "npl_packages/ParacraftBuildinMod/", 
		displayName = L"NPL CAD", 
		text=L"系统内置插件",
		version = "1.4.6",
		homepage = "https://github.com/tatfook/NPLCAD",
	},
    {
		name = "NplCad2", 
		package_path = "npl_packages/ParacraftBuildinMod/", 
		displayName = L"NplCad 2", 
		text=L"系统内置插件",
		version = "1.0.0",
		homepage = "https://github.com/tatfook/NplCad2",
	},
    {
		name = "NplBrowser", 
		package_path = "npl_packages/ParacraftBuildinMod/", 
		displayName = L"NplBrowser", 
		text=L"系统内置插件",
		version = "0.0.12",
		homepage = "https://github.com/NPLPackages/NplBrowserScript",
	},
	{
		name = "STLExporter", 
		-- package_path = "npl_packages/STLExporter/", 
		package_path = "npl_packages/ParacraftBuildinMod/",  
		displayName = L"STL 3D打印模型导出", 
		text=L"系统内置插件",
		version = "1.1",
		homepage = "https://github.com/LiXizhi/stlexporter",
	},
	{
		name = "WorldShare", 
		-- package_path = "npl_packages/WorldShare/", 
		package_path = "npl_packages/ParacraftBuildinMod/", 
		displayName = L"KeepWork世界分享", 
		text=L"系统内置插件",
		version = "1.3",
		homepage = "https://github.com/tatfook/WorldShare",
	},
	{
		name = "ExplorerApp", 
		-- package_path = "tatfook/ExplorerApp/", 
		package_path = "npl_packages/ParacraftBuildinMod/", 
		displayName = L"探索APP", 
		text=L"系统内置插件",
		version = "0.9",
		homepage = "https://github.com/tatfook/ExplorerApp",
	},
	{
		name = "EMapMod", 
		-- package_path = "npl_packages/EMapMod/", 
		package_path = "npl_packages/ParacraftBuildinMod/", 
		displayName = L"3D地图GIS", 
		text=L"系统内置插件",
		version = "0.1",
		homepage = "https://github.com/tatfook/EMapMod",
	},
	{
		name = "CodeBlockEditor", 
		-- package_path = "npl_packages/CodeBlockEditor/", 
		package_path = "npl_packages/ParacraftBuildinMod/", 
		displayName = L"代码方块Web编辑器", 
		text=L"系统内置插件",
		version = "1.0",
		homepage = "https://github.com/tatfook/CodeBlockEditor",
	},
	{
		name = "LogitowMonitor", 
		-- package_path = "npl_packages/LogitowMonitor/", 
		package_path = "npl_packages/ParacraftBuildinMod/", 
		displayName = L"蓝牙智能积木监控", 
		text=L"系统内置插件",
		version = "0.1",
		homepage = "https://github.com/NPLPackages/PluginBlueTooth",
	},
	{
		name = "PluginBlueTooth", 
		-- package_path = "npl_packages/PluginBlueTooth/", 
		package_path = "npl_packages/ParacraftBuildinMod/", 
		displayName = L"蓝牙模块", 
		text=L"系统内置插件",
		version = "0.1",
		homepage = "https://github.com/NPLPackages/PluginBlueTooth",
		-- load this module when the package is loaded
		loadOnStartup = true, 
	},
	-- TODO: add more preinstalled paracraft mod package here
};

-- called at the very beginning before plugins are loaded.
function BuildinMod.AddBuildinMods()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Mod/ModManager.lua");
	local ModManager = commonlib.gettable("Mod.ModManager");
	local pluginloader = ModManager:GetLoader();

	-- ensure that the same package_path are only loaded once.
	local loaded_packages = {};
	for _, mod in ipairs(BuildinMod.buildin_mods) do
		if(loaded_packages[mod.package_path]~=false) then
			if(loaded_packages[mod.package_path] == nil) then
				loaded_packages[mod.package_path] = NPL.load(mod.package_path)~=false;
			end
			if(loaded_packages[mod.package_path]) then
				pluginloader:AddSystemModule(mod.name or mod.package_path, mod);
				if(mod.loadOnStartup) then
					pluginloader:LoadPlugin(mod.name);
				end
			else
				LOG.std(nil, "error", "BuildinMod", "failed to open package %s", mod.package_path);
			end
		end
	end
end
function BuildinMod.GetModByName(name)
    if(not name)then
        return
    end
    for __,mod in ipairs(BuildinMod.buildin_mods) do
        if(mod.name == name)then
            return mod;
        end
    end
end