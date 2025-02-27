--[[
Title: options
Author(s): LiXizhi
Date: 2013/12/14
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/game_options.lua");
local options = commonlib.gettable("MyCompany.Aries.Game.GameLogic.options")
-------------------------------------------------------
]]
local StereoVisionController = commonlib.gettable("MyCompany.Aries.Game.StereoVisionController")
local UserProfile = commonlib.gettable("MyCompany.Aries.Creator.Game.API.UserProfile");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Translation = commonlib.gettable("MyCompany.Aries.Game.Common.Translation")
local SentientGroupIDs = commonlib.gettable("MyCompany.Aries.Game.GameLogic.SentientGroupIDs");
local Screen = commonlib.gettable("System.Windows.Screen");

local options = commonlib.createtable("MyCompany.Aries.Game.GameLogic.options", {
	jump_up_speed = 5,
	jump_up_speed_big = 30,
	-- whether double click to fly
	double_click_flying = false,
	player_height = 1.67;
	Gravity = 9.81,
	BlockLightColor = {1.35, 1.15, 1.15},
	NormalDensity = 1.2,
	DefaultDensity = 1.2,
	DiveDensity = 1.2,
	picking_dist_flymode = 200,
	picking_dist_walkmode = 50,
	fog_start = 60,
	fog_end = 100,
	has_real_terrain = true,
	-- only used when EnableAutoUIScaling is true.
	max_screen_height = 600,
	-- whether to use UI scaling
	EnableAutoUIScaling = nil,
	-- whether to lock mouse_wheel to enable block toggle. 
	lock_mouse_wheel = true, 
	-- automatically change fog color if any. 
	auto_skycolor = true,
	-- -1 or nil to disable, camera movement 
	CharacterLookupBoneIndex = -1,
	-- whether to enable vibration
	enableVibration = nil,
	-- global music volume
	volume = nil,
	-- whether to enable camera view bobbing. 
	ViewBobbing = nil,
	-- related to amplitude of view bobbing
	ViewBobbingAmpScale = 0.015,
	-- we will smooth the camera movement on the y direction when the followed biped's y movement is smaller than this value. This is usually 1.2 or 0
	MaxAllowedYShift = 0,
	-- the camera roll back speed in meters per second. if this value is larger than INFINITY, there will be on smooth animations. 
	CameraRollbackSpeed = 6.0,
	-- setting this to non-zero, will force the player speed to change smoothly. 
	-- TODO: when shift key is down(sneak walk mode), we should set this back to 0. 
	WalkAccelerationDist = 0.25,
	-- whether allow double click W key to run. 
	AllowRunning = true,
	-- player walk speed scale
	WalkSpeedScale = 1,
	RunSpeedScale = 1.6,
	FlySpeedScale = 1.6,
	-- player picking distance
	player_picking_dist_sq = 7*7,
	-- field of view when walking
	normal_fov = 60/180*3.1415926, 
	-- fov when running 
	run_fov = 68/180*3.1415926,
	snipper_fov = 10/180*3.1415926,
	speed_fov = 200/180*3.1415926,
	slow_speed_fov = 20/180*3.1415926,
	-- when ` key is pressed
	inspector_fov = 28/180*3.1415926,

	-- 3.14 is max head turning angle per second. 
	head_turning_max_speed = 3.14,

	-- selection group index for highlighting
	highlight_group_id = 0, 
	-- selection group index for wireframe. 
	wire_frame_group_id = 1, 

	-- double click interval ticks
	double_click_ticks = 90,
	-- login position
	login_pos = {},
	-- world seed for generator
	world_seed = 19881112,
	-- max fps
	FPS = 60,
	render_distance = 96,
	default_render_dist = 96,
	-- headon display text color
	NPCHeadOnTextColor = "12 245 5",
	PlayerHeadOnTextColor = "255 255 255",
	-- whether to save light map to disk. default to false. 
	-- TODO: currently compression is not enabled, and there are lots of zero. Remove those zeros and only save light around the player. 
	-- this is usually not necessary since light is calculated in a separate thread and is usually very fast. 
	SaveLightMap = false,
	-- whether players can jump
	CanJump = true,
	-- whether players can jump when in air
	CanJumpInAir = true,
	-- whether players can jump when in water
	CanJumpInWater = true,
	fps_cursor = {file="Texture/blocks/Cursor/fps.png", hot_x=16, hot_y=16,},
	hand_cursor = {file="Texture/blocks/Cursor/interaction.tga", hot_x=16, hot_y=16,},
	-- picking distance
	PickingDist = 50,
	-- locking game mode
	LockedGameMode = nil,
	-- whether to enable left click to move in game mode. 
	leftClickToMove = false,
	ask_for_help_url = L"http://bbs.paraengine.com/forum.php?mod=forumdisplay&fid=51",
	bbs_home_url = L"https://times.keepwork.com/latest",
	--bbs_home_url = L"http://paracraft.keepwork.com/",
	--bbs_upload_url = L"http://bbs.paraengine.com/forum.php?mod=forumdisplay&fid=50",
	bbs_upload_url = L"https://tieba.baidu.com/f?kw=%E9%AD%94%E6%B3%95%E5%93%88%E5%A5%87",
	credits_url = L"https://github.com/LiXizhi/ParaCraftSDK/wiki/Credits",
	-- whether we are cheating on some of the functions
	is_cheating = false,
	-- we will prompt the user to save when it exit the world after editing for 10 seconds. Unit is ms seconds. 
	force_save_interval = 20000,
	-- whether to switch back from fly mode to walk mode, when player's feet is on ground.
	auto_disable_fly_when_on_ground = false,
	-- stereo mode value. 
	stereoMode = 0,
	-- 960*560 which is the minimum UI size allowed. 
	min_ui_height = 560,
	-- usually the left drag is enabled only in touch mode.
	isMouseLeftDragEnabled = false,
	-- the player asset path
	mainPlayerAssetPath = nil,
	-- lower movie frame rate, when actors are far from current camera, only affect those without camera actor
	isAutoMovieFPS = true,
});

-- load default setting on application start. 
function options:OneTimeInit()
	if(self.one_time_inited) then
		return;
	end
	self.one_time_inited = true;

	local key = "Paracraft_System_Sound_State";
	local sound_state = GameLogic.GetPlayerController():LoadLocalData(key,true,true);
	if(sound_state == true or sound_state == "true") then
		ParaAudio.SetVolume(1);
	else
		ParaAudio.SetVolume(0);
	end

	local key = "Paracraft_use_deferred_shading";
	local use_deferred_shading = GameLogic.GetPlayerController():LoadLocalData(key,false,true);
	if(use_deferred_shading and not GameLogic.GetShaderManager():IsDeferredShading()) then
		if(not GameLogic.GetShaderManager():SetShaders(use_deferred_shading and 2 or 1)) then
			GameLogic.GetPlayerController():SaveLocalData(key, false, true);
		end
	end

	self:SetMaintainMovieBlockAspectRatio();

	-- error log hook
	--[[
	if(System.options.mc and ParaWorldAnalytics) then
		ParaWorldAnalytics.SetNPLErrorCallback(function(errorMessage, stackInfo)
			GameLogic.OnCodeError(errorMessage, stackInfo)
		end)
	end
	]]
end

-- transient options can be modified by game rule and reset when loading a new world.
function options:LoadDefaultTransientOptions()
	self.CanJump = true;
	self.CanJumpInAir = true;
	self.CanJumpInWater = true;
	self.AllowRunning = true;
end

-- usually the left drag is enabled only in touch mode.
function options:SetEnableMouseLeftDrag(bEnabled)
	if(self.isMouseLeftDragEnabled~=bEnabled) then
		self.isMouseLeftDragEnabled = bEnabled;
		ParaCamera.GetAttributeObject():SetField("EnableMouseLeftDrag", bEnabled==true);
	end
end

function options:SetIsCheating(bIsCheatingOn)
	self.is_cheating = bIsCheatingOn;
end

function options:IsCheating()
	return self.is_cheating;
end

-- the unique login user name(id).
function options:GetPlayerName()
	return self.playername or "default";
end

-- the unique login user name(id).
function options:SetPlayerName(nid)
	self.playername = tostring(nid);
end

function options:SetCanJump(bValue)
	self.CanJump = bValue;
end

function options:SetCanJumpInAir(bValue)
	self.CanJumpInAir = bValue;
end

function options:SetCanJumpInWater(bValue)
	self.CanJumpInWater = bValue;
end

function options:SetClickToContinue(bEnabled)
	System.options.disable_click_to_continue = not bEnabled;
	local att = ParaEngine.GetAttributeObject();
	att:SetField("ToggleSoundWhenNotFocused", bEnabled);
end

-- @param value: if nil, it will set back to 50. 
function options:SetPickingDist(value)
	if(type(value) == "number") then
		self.PickingDist = value;
	else
		self.PickingDist = 50;
	end
end

function options:GetPickingDist()
	return self.PickingDist or 50;
end

-- get current revision number
function options:GetRevision()
	if(GameLogic.world_revision) then
		return GameLogic.world_revision:GetRevision() or 1;
	else
		return 1;
	end
end

-- keepwork project id
function options:GetProjectId()
	return WorldCommon.GetWorldTag("kpProjectId");
end

function options:GetNetworkInfo()
	local att = NPL.GetAttributeObject();
	return {TCP_HOST = att:GetField("HostIP"), TCP_PORT = att:GetField("HostPort"), UDP_HOST = att:GetField("UDPHostIP"), UDP_PORT = att:GetField("UDPHostPort")}
end

-- @param r,g,b: in [0,2] range
function options:SetTorchColor(r,g,b)
	if(r and g and b) then
		r = math.min(math.max(0,r), 2);
		g = math.min(math.max(0,g), 2);
		b = math.min(math.max(0,b), 2);
		ParaTerrain.GetBlockAttributeObject():SetField("BlockLightColor", {r,g,b});
	end
end

function options:GetCameraObjectDistance()
	local camera_dist = ParaCamera.GetAttributeObject():GetField("CameraObjectDistance", 8);
    if(camera_dist > 20) then
        camera_dist = 20;
    elseif(camera_dist < 1) then
        camera_dist = 1
    end
    return camera_dist;
end

function options:SetCameraObjectDistance(value)
	if(type(value)=="number" and value <= 20 and value>=1) then
		ParaCamera.GetAttributeObject():SetField("CameraObjectDistance", value);
	end
end

function options:IsShowMainPlayer()
	return ParaScene.GetAttributeObject():GetField("ShowMainPlayer", false);
end

function options:SetShowMainPlayer(bShow)
	return ParaScene.GetAttributeObject():SetField("ShowMainPlayer", bShow == true);
end

-- enable internel mesh level of details if any. 
function options:EnableLOD(bEnable)
	ParaScene.GetAttributeObject():SetField("IsLodEnabled", bEnable == true);
end

function options:IsLODEnabled()
	return ParaScene.GetAttributeObject():GetField("IsLodEnabled", true);
end

-- async load or download from url
function options:ApplyTexturePack()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/TextureModPage.lua");
	local TextureModPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TextureModPage");
	TextureModPage.OnApplyTexturePack();
end

function options:OnLoadWorld()
	self.userType = GameLogic.GetFilters():apply_filters('get_user_type');

	self:OneTimeInit();
	self:LoadDefaultTransientOptions();
	GameLogic.RunCommand("language");
	-- increased chunk limit
	GameLogic.RunCommand("/memlimit -v -s 500");
--	if(System.os.Is64BitsSystem()) then
--		GameLogic.RunCommand("/memlimit -v -s 500");
--	else
--		GameLogic.RunCommand("/memlimit -v -s 200");
--	end
	GameLogic.AddBBS("options", nil);
	self.isOfflineMode = System.options.loginmode == "local" or System.options.loginmode == "offline" or System.os.IsWindowsXP();

	local player = ParaScene.GetPlayer();
	self:ApplyTexturePack();

	-- load saved user settings
	ParaCamera.GetAttributeObject():SetField("TurnBipedWhenWalkBackward", true);	
	local profile = UserProfile.GetUser();
	self.LockedGameMode = nil;
	self.NormalDensity = self.DefaultDensity;
	self.AllowRunning = true;
	self.PickingDist = 50;
	self.isAutoMovieFPS = true;
	self:SetViewBobbing(nil);
	self:SetEnableVibration(nil);
	self:SetDisableShaderCommand(nil);
	-- fixed: mobile version's file operation is not thread safe, I need to change cocos code in order to re-enable this. 
	self:EnableAsyncAssetLoader(true);
	-- refresh sky
	GameLogic.GetSkyEntity():Refresh();
	self.remoteFolderName = nil;

	if(System.options.mc) then
		local mainAssetFilename = self:GetMainPlayerAssetName();
		if(mainAssetFilename) then
			EntityManager.GetPlayer():SetMainAssetPath(mainAssetFilename)
		end
		local mainSkins = self:GetMainPlayerSkins();
		if(mainSkins) then
			EntityManager.GetPlayer():SetSkin(mainSkins);
		end
		
		player:SetScale(1);
		self.jump_up_speed = 5*1.3;
		local att = ParaTerrain.GetBlockAttributeObject();
		att:SetField("BlockLightColor", self.BlockLightColor)
		att:SetField("SaveLightMap", self.SaveLightMap == true);

		local open_shadow = if_else(WorldCommon.GetWorldTag("shadow") ~= "false",true,false);
		att:SetField("UseSunlightShadowMap", open_shadow);
		
		local use_waterreflection = if_else(WorldCommon.GetWorldTag("waterreflection") ~= "false",true,false);
		att:SetField("UseWaterReflection", use_waterreflection);

		local rendermethod = tonumber(WorldCommon.GetWorldTag("rendermethod"));
		if(rendermethod) then
			local res = GameLogic.RunCommand("/shader "..rendermethod);
			if(res == "disabled") then
				GameLogic.AddBBS(nil, L"/shader命令被禁止, 请在设置中解禁");
			end
		end

		self.lock_mouse_wheel = true;
		player:SetField("Gravity", self.Gravity*2);
		
		self:SetWalkSpeedScale(0.92);

		self:SetVolume(nil);
		self:SetStereoEyeSeparationDist(nil);

		self:SetInvertMouse(nil);
		self:SetSensitivity(nil);

		self:SetMaxViewDist(nil);
		local dist = WorldCommon.GetWorldTag("renderdist");
		self:SetRenderDist(dist);
		
		if(self.EnableAutoUIScaling == nil) then
			--self.EnableAutoUIScaling = true;
		end

		if(self:IsShowTutorial()) then
			self:SetShowTutorial(false);
			_guihelper.MessageBox(L"是否观看在线教程(快捷键F1)?", function()
				GameLogic.RunCommand("menu", "help.actiontutorial");
			end)
		end

		-- close *.db
		ParaWorld.SetAttributeProvider("");
		ParaWorld.SetNpcDB("");
	else
		self.jump_up_speed = 5;
		self.lock_mouse_wheel = false;
		player:SetField("Gravity", self.Gravity);
		self:SetRenderDist(self.default_render_dist);
		self:SetWalkSpeedScale(0.7);
	end
	self:SetEnableAutoUIScaling();
	player:SetField("AccelerationDist", self.WalkAccelerationDist or 0);
	player:SetField("SkipPicking", true);
	
	-- MESH_USE_LIGHT = 0x1<<7: use block ambient and diffuse lighting for this model. 
	player:SetAttribute(128, true);

	if(self.FPS) then
		ParaEngine.GetAttributeObject():SetField("RefreshTimer", 1/self.FPS);
	end

	ParaEngine.GetAttributeObject():SetField("IsWindowClosingAllowed", false);

	self:SetLastSaveTime();
	self:ShowMenuPage();
	self:ShowTouchPad();
	self:ShowSkyBox();
	self:ResetWindowTitle();
	WorldCommon.SetModified(false);

	-- try pop world
	NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldStacks.lua");
	local WorldStacks = commonlib.gettable("MyCompany.Aries.Game.WorldStacks");
	WorldStacks:PopWorld();

	-- TODO: 2020.7.17. disabled IsVipWorld until server fixed
	if(false and self:IsVipWorld() and not self:IsVip() and 
		-- skip standalone app when noclientupdate is true
		ParaEngine.GetAppCommandLineByParam("noclientupdate", "")=="") then
		
		_guihelper.MessageBox(L"本世界只有登录的VIP用户可以访问。即将退出世界。")

		commonlib.TimerManager.SetTimeout(function()  
			GameLogic.RunCommand("/leaveworld")
		end, 3000)
	end

	local kpParentWorldId = WorldCommon.GetWorldTag("parentProjectId")
	if kpParentWorldId and tonumber(kpParentWorldId) > 0 then
		commonlib.TimerManager.SetTimeout(function()  
			GameLogic.RunCommand(string.format("/loadworld -s -force  -inplace %d | /sendevent globalGotoCreate",kpParentWorldId))
		end, 500)
	end

	GameLogic.RunCommand('/shader 1')
end

function options:ResetWindowTitle()
	if(System.options.WindowTitle) then
		local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
		local worldName = WorldCommon.GetWorldTag("name");
		if(worldName) then
			if(GameLogic.IsReadOnly()) then
				worldName = format("%s (%s)", worldName, L"只读")
			end
			local projectId = self:GetProjectId()
			if(projectId) then
				worldName = worldName .. " " .. format(L"项目ID:%s", tostring(projectId))
			end
			local windowTitle = format("%s  %s", worldName, System.options.WindowTitle)
			windowTitle = GameLogic.GetFilters():apply_filters('WorldName.ResetWindowTitle', windowTitle, System.options.WindowTitle)
			ParaEngine.SetWindowText(windowTitle);	
		end
	end
end

-- in mobile version, force using single sky box. 
function options:ShowSkyBox()
	if(System.options.IsMobilePlatform) then
		-- GameLogic.RunCommand("/sky -tex Texture/blocks/sky/sky1.png");
		GameLogic.RunCommand("/sky sim");
	end
end

-- @param bShow: if nil, it will automatically show if on mobile platform.
function options:ShowMenuPage()
	if(System.options.IsMobilePlatform) then
		NPL.load("(gl)script/mobile/paracraft/Areas/SystemMenuPage.lua");
		local SystemMenuPage = commonlib.gettable("ParaCraft.Mobile.Desktop.SystemMenuPage");
		SystemMenuPage.ShowPage();
	end
end


-- @param bShow: if nil, it will automatically show if on mobile platform.
function options:ShowTouchPad(bShow)
	-- on windows touch device, if the user has clicked with touch device before it enters a 3d world, we will show the touch controller. 
	local IsTouchDevice = self:HasTouchDevice()
	if(System.options.IsTouchDevice or IsTouchDevice) then
		local TouchMiniKeyboard = GameLogic.GetFilters():apply_filters("TouchMiniKeyboard");
		if(not TouchMiniKeyboard) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TouchMiniKeyboard.lua");
			TouchMiniKeyboard = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchMiniKeyboard");
		end

		TouchMiniKeyboard.CheckShow(true);

		-- enable touch mode
		self:SetEnableMouseLeftDrag(true);
	end
end

function options:SetLoginPosition(x, y, z)
	if(self.login_pos[1] == nil) then
		if(x and y and z) then
			GameLogic.GetFilters():apply_filters("PlayerHasLoginPosition", nil, x,y,z)	
		end
	end
	self.login_pos[1], self.login_pos[2], self.login_pos[3] = x, y, z;
end

function options:OnLeaveWorld()
	self.login_pos = {};
	-- this will stop any midi sound if any. 
	ParaAudio.PlayWaveFile("");
	-- stop background music
	NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/BackgroundMusic.lua");
	local BackgroundMusic = commonlib.gettable("MyCompany.Aries.Game.Sound.BackgroundMusic");
	BackgroundMusic:Stop();

	NPL.load("(gl)script/apps/Aries/Creator/Game/Materials/TexturePackage.lua");
	local TexturePackage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TexturePackage");
	block_types.restore_texture_pack();
	TexturePackage.CloseLastPackageZip();
end

function options:SetLastSaveTime()
	self.last_save_time = commonlib.TimerManager.GetCurrentTime();
end

function options:ShowBoundingBox(bShow)
	ParaScene.GetAttributeObject():SetField("ShowBoundingBox", bShow==true);
end

function options:ShowWireframe(bShow)
	ParaScene.GetAttributeObject():SetField("UseWireFrame", bShow==true);
end

-- get the number of ms seconds, that user is not saving. 
function options:GetElapsedUnSavedTime()
	local curTime = commonlib.TimerManager.GetCurrentTime();
	return (curTime - (self.last_save_time or 0));
end

function options:SetGravity(value)
	self.Gravity = value or 9.81;
	local player = EntityManager.GetFocus();
	if(player) then
		player:SetGravity(nil);
	end
end

function options:GetGravity()
	return self.Gravity;
end

-- set or toggle AllowRunning. 
function options:SetAllowRunning(AllowRunning)
	if(AllowRunning == nil) then
		self.AllowRunning = not self.AllowRunning;
	else
		self.AllowRunning = AllowRunning;
	end
	return self.AllowRunning;
end


-- @param mode: "editor" or "game" or nil
function options:SetLockedGameMode(mode)
	if(GameLogic.IsReadOnly()) then
		self.LockedGameMode = mode;	
	else
		self.LockedGameMode = nil;
	end
end

-- @param days: number or nil. if nil, we will read school mode. 
function options:SetSchoolMode(days)
	if(type(days) == "number") then
		System.options.isSchool = true;
		local expireTime = ParaGlobal.GetSysDateTime() + 86400*days;
		GameLogic.GetPlayerController():SaveLocalData("school_mode_expire_time", expireTime, true, true);
		LOG.std(nil, "info", "options", "school mode will expire after %d days", days);
	else
		if(System.options.isSchool == nil) then
			System.options.isSchool = false;
			local expireTime = GameLogic.GetPlayerController():LoadLocalData("school_mode_expire_time",true,true);
			if(type(expireTime) == "number") then
				if(ParaGlobal.GetSysDateTime() < expireTime) then
					System.options.isSchool = true;
				end
			end
		end
		LOG.std(nil, "info", "options", "school mode: %s ", System.options.isSchool and "on" or "off");
	end
end

function options:SetEnableAutoUIScaling(bEnable)
	if(bEnable ~= nil) then
		self.EnableAutoUIScaling = bEnable == true;
	end
	ParaUI.GetUIObject("root"):GetAttributeObject():SetField("UsePointTextureFiltering", self.EnableAutoUIScaling == true);
end

function options:GetRenderDist()
	return self.render_distance;
end

-- the preferred render dist, the actual one may still be limited by MaxViewDist().
function options:SetRenderDist(dist)
	dist = math.min(math.max(tonumber(dist) or self.default_render_dist, 0),1024);
	self.render_distance = dist;

	local actual_dist = math.min(self.render_distance, self:GetMaxViewDist());
	self.actual_render_distance = actual_dist;

	ParaTerrain.GetBlockAttributeObject():SetField("RenderDist", actual_dist);

	local block_dist = math.floor(actual_dist/16)+1;
	GameLogic.GetBlockGenerator():SetMaxGenRadius(block_dist);

	-- update fog as well
	self.fog_end = actual_dist;
	self.fog_start = math.max(self.fog_end*0.5, self.fog_end - 40);

	local att = ParaScene.GetAttributeObject();
	att:SetField("FogStart", self.fog_start);
	att:SetField("FogEnd", self.fog_end);

	att = ParaCamera.GetAttributeObject();
	att:SetField("FarPlane", self.fog_end+1);

	LOG.std(nil, "info", "options", "actual render dist is set to %d", actual_dist);
end

function options:SetFogStart(dist)
	if(self.fog_start ~= dist) then
		self.fog_start = dist;
		local att = ParaScene.GetAttributeObject();
		att:SetField("FogStart", self.fog_start);
		if(self.fog_start > self.fog_end) then
			self:SetFogEnd(self.fog_start + 32);
		end
	end
end

function options:GetFogStart()
	return self.fog_start;
end

function options:SetFogEnd(dist)
	if(self.fog_end ~= dist) then
		self.fog_end = dist;
		local att = ParaScene.GetAttributeObject();
		att:SetField("FogEnd", self.fog_end);
	end
end

function options:GetFogEnd()
	return self.fog_end;
end

-- set player base speed scale.
function options:SetWalkSpeedScale(speed_scale)
	speed_scale = speed_scale or 1;
	self.WalkSpeedScale = speed_scale;
	self.RunSpeedScale = speed_scale*1.3;
	self.FlySpeedScale = speed_scale*3;
	ParaScene.GetPlayer():ToCharacter():SetSpeedScale(self.WalkSpeedScale);
end

function options:GetWalkSpeedScale()
	return self.WalkSpeedScale;
end

-- this will affect how far and high a player can jump
function options:SetJumpUpSpeed(value)
	self.jump_up_speed = value or 6.5;
end

-- set density
function options:SetDensity(value)
	self.NormalDensity = value;
end

-- whether the device support touch event
-- whenever we receive a mouse down click, this function return false, whenever we receive a touch down event, it return true. 
-- call this function periodically to check if the most recent click is coming from click or touch. 
function options:HasTouchDevice()
	-- mobile platform or windows 2in1 devices have touch devices. 
	if(System.options.IsMobilePlatform) then
		return true;
	else
		local attr = ParaEngine.GetAttributeObject();
		return attr:GetField("IsTouchInputting", false);
	end
end

-- get the current npl runtime version
function options.GetBaseVersion()
	local baseVersion = ParaEngine.GetAppCommandLineByParam("base_version", "2.0.0")
	
	return baseVersion
end

-- the version file should contain a single line of text such as "1.0.0"
options.sVersionFileName = "version.txt";

-- get the current client version.
function options.GetClientVersion()
	if(not options.ClientVersion) then
		local bNeedUpdate = true;
		if( ParaIO.DoesFileExist(options.sVersionFileName)) then
			local file = ParaIO.open(options.sVersionFileName, "r");
			if(file:IsValid()) then
				local text = file:GetText();

				options.ClientVersion = string.match(text,"ver=([^\r\n]*)");
				local major, minor, sub_minor =string.match(text,"ver=(%d+)%.(%d+)%.(%d+)");
				commonlib.log("client version is %d.%d.%d\n", major, minor, sub_minor);

				file:close();
			end
		end
		if(not options.ClientVersion) then
			options.ClientVersion = "0.0.0";
		end
	end
	return options.ClientVersion;
end

-- set or toggle viewbobbing. 
-- @param noSave: if true, it means temporary set, do not save to disk options
function options:SetViewBobbing(value, noSave)
	local key = "Paracraft_System_View_Bobbing";
	if(value == nil) then
		self.ViewBobbing = GameLogic.GetPlayerController():LoadLocalData(key,true,true);
	elseif(self.ViewBobbing ~= value) then
		self.ViewBobbing = value;
		if(not noSave) then
			GameLogic.GetPlayerController():SaveLocalData(key, value, true, true);
		end
	end
end

function options:GetViewBobbing()
	return self.ViewBobbing;
end

function options:SetMainPlayerAssetName(value)
	local key = "Paracraft_System_MainPlayer_AssetName";
	if(value == nil) then
		-- Do nothing:
	elseif(self:GetMainPlayerAssetName() ~= value) then
		GameLogic.GetPlayerController():SaveRemoteData(key, value);
	end
end

function options:GetMainPlayerAssetName()
	return GameLogic.GetPlayerController():LoadRemoteData("Paracraft_System_MainPlayer_AssetName");
end

function options:SetMainPlayerSkins(value)
	local key = "Paracraft_System_MainPlayer_Skins";
	if(self:GetMainPlayerSkins() ~= value) then
		GameLogic.GetPlayerController():SaveRemoteData(key, value);
	end
end

function options:GetMainPlayerSkins(value)
	return GameLogic.GetPlayerController():LoadRemoteData("Paracraft_System_MainPlayer_Skins");
end

-- obsoleted: set view bobbing and save to disk
function options:ToggleViewBobbing(viewBobbing)
	if(viewBobbing == nil) then
		self:SetViewBobbing(not self:GetViewBobbing());
	else
		self:SetViewBobbing(viewBobbing);
	end
	return self:GetViewBobbing();
end

function options:GetSensitivity()
	return self.sensitivity or 0.3;
end

-- set the mouse sensitivity
-- @param value: [0,1], default to 0.3. the bigger, the more precision.
function options:SetSensitivity(value)
	local key = "Paracraft_System_Mouse_Sensitivity";
	if(value == nil) then
		if(self.sensitivity == nil) then
			self.sensitivity = GameLogic.GetPlayerController():LoadLocalData(key,self:GetSensitivity(),true);
		end
	elseif(self.sensitivity ~= value) then
		self.sensitivity = value;
		GameLogic.GetPlayerController():SaveLocalData(key, value, true, true);
	end
end

function options:GetInvertMouse()
	if(self.bMouseInverted~=nil) then
		return self.bMouseInverted;
	else
		return false;
	end
end

-- @param bInverted: if nil, setting is loaded from current file. 
function options:SetInvertMouse(bInverted)
	local key = "Paracraft_System_Mouse_Inverse";
	if(bInverted == nil) then
		if(self.bMouseInverted == nil) then
			self.bMouseInverted = GameLogic.GetPlayerController():LoadLocalData(key,false,true);
			ParaEngine.GetAttributeObject():SetField("IsMouseInverse", self.bMouseInverted);
		end
	elseif(self.bMouseInverted ~= bInverted) then
		self.bMouseInverted = bInverted;
		ParaEngine.GetAttributeObject():SetField("IsMouseInverse", bInverted);
		GameLogic.GetPlayerController():SaveLocalData(key, bInverted, true, true);
	end
end

-- save all queued settings to disk.
function options:Save()
	GameLogic.GetPlayerController():FlushLocalData();
end

function options:GetMaxViewDist()
	if(self.maxViewDist == nil) then
		return self:GetSavableMaxDist();
	else
		return self.maxViewDist;
	end
end

function options:GetSavableMaxDist()
	return 256;
end

-- @param bSaveToDisk: true to save to disk
-- @NOTE: max view dist are not saved to disk by default
function options:SetMaxViewDist(value, bSaveToDisk)
	local key = "Paracraft_System_maxViewDist";
	if(value == nil) then
		local maxViewDist
		if(System.os.IsMobilePlatform()) then
			-- shall we make it small in mobile platform ?
			-- maxViewDist = 64
			maxViewDist = GameLogic.GetPlayerController():LoadLocalData(key,self:GetMaxViewDist(),true);
		else
			maxViewDist = GameLogic.GetPlayerController():LoadLocalData(key,self:GetMaxViewDist(),true);
		end
			
		if(maxViewDist == self:GetSavableMaxDist()) then
			self.maxViewDist = maxViewDist;
		else
			self:SetMaxViewDist(maxViewDist);
		end
	elseif(self.maxViewDist ~= value) then
		LOG.std(nil, "info", "options", "max view dist is set to %d", value);
		if(bSaveToDisk and value <= self:GetSavableMaxDist()) then
			GameLogic.GetPlayerController():SaveLocalData(key, value, true, true);
		end
		self.maxViewDist = value;
		self:SetRenderDist(self:GetRenderDist());
	end
end


function options:SetEnableVibration(value)
	local key = "Paracraft_System_Mouse_EnableVibration";
	if(value == nil) then
		if(self.enableVibration == nil) then
			self.enableVibration = GameLogic.GetPlayerController():LoadLocalData(key,self:IsVibrationEnabled(),true);
		end
	elseif(self.enableVibration ~= value) then
		self.enableVibration = value;
		GameLogic.GetPlayerController():SaveLocalData(key, value, true, true);
	end
end

function options:IsVibrationEnabled()
	if(self.enableVibration == nil) then
		return true;
	else
		return self.enableVibration;
	end
end

function options:SetVolume(value)
	local key = "Paracraft_System_Sound_Volume";
	if(value == nil) then
		if(self.volume == nil) then
			self.volume = GameLogic.GetPlayerController():LoadLocalData(key,self:GetVolume(),true);
			ParaAudio.SetVolume(self.volume);
		end
	elseif(self.volume ~= value) then
		self.volume = value;
		ParaAudio.SetVolume(value);
		GameLogic.GetPlayerController():SaveLocalData(key, value, true, true);
	end
end

function options:GetVolume()
	if(self.volume == nil) then
		return 0.5;
	else
		return self.volume;
	end
end

function options:SetShowInfoWindow(value)
	if(self.bShowInfoWindow ~= value) then
		self.bShowInfoWindow = value;
		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/InfoWindow.lua");
		local InfoWindow = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.InfoWindow");
		InfoWindow.ShowPage(self.bShowInfoWindow);
	end
end

function options:IsShowInfoWindow()
	if(self.bShowInfoWindow == nil) then
		return false;
	else
		return self.bShowInfoWindow;
	end
end

function options:IsStereoMode()
	return self.stereoMode~=0;
end

function options:GetStereoMode()
	return self.stereoMode;
end

local MOVIE_CAPTURE_MODE = {
	MOVIE_CAPTURE_MODE_NORMAL = 0,
	MOVIE_CAPTURE_MODE_STEREO_LINE_INTERLACED = 1,
	MOVIE_CAPTURE_MODE_STEREO_LEFT_RIGHT = 2,
	MOVIE_CAPTURE_MODE_STEREO_ABOVE_BELOW = 3,
	MOVIE_CAPTURE_MODE_STEREO_FRAME_INTERLACED = 4,
	MOVIE_CAPTURE_MODE_STEREO_RED_BLUE = 5, 
};

-- @param value: 0 or false is disable, 2 or true is left/right, 5 is red/blue
function options:EnableStereoMode(value)
	if(value == true) then
		value = 2; -- default to left/right
	elseif(not value) then
		value = 0;
	end
	self.stereoMode = tonumber(value) or 0;
	if(ParaMovie and ParaMovie.GetAttributeObject) then
		local attr = ParaMovie.GetAttributeObject();
		if(self.stereoMode~=0) then
			attr:SetField("StereoCaptureMode", self.stereoMode);
		else
			attr:SetField("StereoCaptureMode", 0);
		end
		if(self.stereoMode == MOVIE_CAPTURE_MODE.MOVIE_CAPTURE_MODE_STEREO_RED_BLUE) then
			local effect = GameLogic.GetShaderManager():GetEffect("RedBlueStereo");
			if(effect) then
				effect:SetEnabled(true);
			end
		end
	end
end

function options:SetDisableShaderCommand(value)
	local key = "Paracraft_DisableShaderCommand";
	if(value == nil) then
		if(self.shaderCmdDisabled == nil) then
			self.shaderCmdDisabled = GameLogic.GetPlayerController():LoadLocalData(key,self:IsDisableShaderCommand(),true);
		end
	elseif(self.shaderCmdDisabled ~= value) then
		self.shaderCmdDisabled = value;
		GameLogic.GetPlayerController():SaveLocalData(key, value, true, true);
	end
end

function options:IsDisableShaderCommand()
	return self.shaderCmdDisabled == true;
end

function options:GetStereoEyeSeparationDist(value)
	if(ParaMovie and ParaMovie.GetAttributeObject) then
		local attr = ParaMovie.GetAttributeObject();
		return attr:GetField("StereoEyeSeparation", 0);
	else
		return 0;
	end
end

function options:SetStereoEyeSeparationDist(value)
	local key = "Paracraft_System_StereoEyeDist";
	local bSet;
	if(value == nil) then
		if(self.stereo_eye_dist == nil) then
			self.stereo_eye_dist = GameLogic.GetPlayerController():LoadLocalData(key,self:GetStereoEyeSeparationDist(),true);
			bSet = true;
		end
	elseif(self.stereo_eye_dist ~= value) then
		self.stereo_eye_dist = value;
		GameLogic.GetPlayerController():SaveLocalData(key, value, true, true);
		bSet = true;
	end

	if(bSet and self.stereo_eye_dist and math.abs(self.stereo_eye_dist)<1) then
		if(ParaMovie and ParaMovie.GetAttributeObject) then
			local attr = ParaMovie.GetAttributeObject();
			attr:SetField("StereoEyeSeparation", self.stereo_eye_dist);
		end
	end
end

function options:SetStereoControllerEnabled(value)
	return StereoVisionController:SetEnabled(value);
end

function options:IsStereoControllerEnabled()
	return StereoVisionController:IsEnabled();
end

-- @note: we can only set user UI scaling when there is no design resolution specified. 
-- @param value: if 0, the original unscaled scaling is used. If nil, it will load from setting file. 
-- value is usually [1,2].  where 1 means original size
function options:SetUIScaling(value)
	local designWidth, designHeight = Screen:GetDesignUIResolution()
	if(designWidth) then
		return 
	end

	local scaling = 1;
	local key = "Paracraft_System_SetUIScaling";
	if(value == nil) then
		value = GameLogic.GetPlayerController():LoadLocalData(key,self:GetUIScaling(),true);
	else
		GameLogic.GetPlayerController():SaveLocalData(key, value, true, true);
	end
	if(value and value~=0) then
		scaling = value
		local frame_width, frame_height = Screen:GetWindowSolution()
		if(frame_height < self.min_ui_height*scaling) then
			scaling = frame_height / self.min_ui_height;
		end
	end
	Screen:SetUserUIScaling(scaling)
end

function options:GetUIScaling()
	local scaling = Screen:GetUIScaling();
	return scaling[1]
end

-- async asset loader
function options:EnableAsyncAssetLoader(bEnable)
	ParaEngine.GetAttributeObject():GetChild("AssetManager"):SetField("AsyncLoading", bEnable);
end

function options:GetRainStrength()
	return GameLogic.GetSkyEntity():GetRainStrength();
end

-- @param cloud: [0,1] default to 0
function options:SetCloudThickness(cloud)
	cloud = cloud or 0.1;
	self.CloudThickness = cloud;
	local att = ParaScene.GetAttributeObjectSky();
	att:SetField("SimulatedSky", true);
	att:SetField("CloudThickness", cloud or 1);
end

function options:GetCloudThickness()
	if(not self.CloudThickness) then
		local att = ParaScene.GetAttributeObjectSky();
		self.CloudThickness = att:GetField("CloudThickness", 0.4);
	end
	return self.CloudThickness or 0;
end


-- whenever in movie output mode, we will cache all terrain and lighting information. Block chunks are loaded without delay.
-- this mode is only available on PC and turned on manually, since it may slow down rendering for slow PC. And may crash for big scenes running 32bits version due to memory limit.
function options:EnableMovieOutputMode(bEnable)
	ParaTerrain.GetBlockAttributeObject():SetField("MovieOutputMode", bEnable == true);
end

function options:IsMovieOutputMode()
	return ParaTerrain.GetBlockAttributeObject():GetField("MovieOutputMode", false);
end

-- whether to show tutorial when world is loaded. 
function options:SetShowTutorial(bShow)
	if(not System.options.IsMobilePlatform) then
		self.isShowTutorial = bShow;
	end
end

function options:IsShowTutorial()
	return self.isShowTutorial;
end

-- get translation table used in the current world
function options:GetTranslationTable()
	return self.transTable;
end

-- set translation table used in the current world
-- @param transTable: may be nil.
function options:SetTranslationTable(transTable)
	self.transTable = transTable;
end

-- get a translated text
function options:GetText(text)
	if(self.transTable and text) then
		return self.transTable[text] or text;
	else
		return text;
	end
end

-- enUS or zhCN
function options:GetCurrentLanguage()
	return Translation.GetCurrentLanguage();
end

-- set brightness factor (0-1) used in HDR shader 3, 4. default value is 0.5.
function options:GetEyeBrightness()
	local effect = GameLogic.GetShaderManager():GetEffect("Fancy");
	if(effect) then
		return effect:GetEyeBrightness();
	end
	return 0.2;
end

-- set brightness(exposure) factor (0-1) used in HDR shader 3, 4. default value is 0.2.
function options:SetEyeBrightness(factor)
	factor = factor or 0.2;

	if(factor > 0 and factor < 1) then
		local effect = GameLogic.GetShaderManager():GetEffect("Fancy");
	
		if(effect) then
			effect:SetEyeBrightness(factor);
		end
	end
end

-- set brightness(exposure) factor (0-1) used in HDR shader 3, 4. default value is 0.2.
function options:SetEyeContrast(factor)
	factor = factor or 0.5;

	if(factor > 0 and factor < 1) then
		local effect = GameLogic.GetShaderManager():GetEffect("Fancy");
	
		if(effect) then
			effect:SetEyeContrast(factor);
		end
	end
end

-- use multi-frame renderer to render remote blocks 
-- @param dist: if 0, it will disable super rendering
function options:SetSuperRenderDist(dist)
	if(dist and dist>=0 and dist <= 5000) then
		local attr = ParaTerrain.GetBlockAttributeObject():GetChild("CMultiFrameBlockWorldRenderer");
		attr:SetField("RenderDistance", dist);
		if(dist == 0) then
			attr:SetField("Enabled", false);
		else
			attr:SetField("Enabled", true);
			attr:SetField("Dirty", true);
		end
	end
end

-- @return 0 if super rendering is disabled. 
function options:GetSuperRenderDist()
	local attr = ParaTerrain.GetBlockAttributeObject():GetChild("CMultiFrameBlockWorldRenderer");
	if(attr:GetField("Enabled", false)) then
		return attr:GetField("RenderDistance", 0);
	else
		return 0;
	end
end

-- enabled by default. if enabled, we will ignore camera-block collision,
-- when both eye and the look-at point are in sunlight.
-- another way to set: `/property set -camera IgnoreEyeBlockCollisionInSunlight false`
function options:SetIgnoreEyeBlockCollisionInSunlight(bIgnored)
	ParaCamera.GetAttributeObject():GetField("IgnoreEyeBlockCollisionInSunlight", bIgnored == true);
end

function options:IsMaintainMovieBlockAspectRatio()
	return self.maintainMovieBlockAspectRatio;
end

function options:SetMaintainMovieBlockAspectRatio(value)
	local key = "Paracraft_maintainMovieBlockAspectRatio";
	if(value == nil) then
		if(self.maintainMovieBlockAspectRatio == nil) then
			self.maintainMovieBlockAspectRatio = GameLogic.GetPlayerController():LoadLocalData(key,self:IsMaintainMovieBlockAspectRatio(), true);
		end
	elseif(self.maintainMovieBlockAspectRatio ~= value) then
		self.maintainMovieBlockAspectRatio = value;
		GameLogic.GetPlayerController():SaveLocalData(key, value, true, false);
	end
end

function options:SetFullScreenMode(bFullScreen)
	ParaEngine.GetAttributeObject():SetField("IsFullScreenMode", bFullScreen == true);
	ParaEngine.GetAttributeObject():CallField("UpdateScreenMode");
end

function options:IsVipWorld()
	return WorldCommon.GetWorldTag("isVipWorld")
end

function options:SetVipWorld(isVipWorld)
	GameLogic.AddBBS(nil, format("vip world is %s", tostring(isVipWorld)))
	if(isVipWorld == false) then
		isVipWorld = nil;
	end
	WorldCommon.SetWorldTag("isVipWorld", isVipWorld);
end

function options:HasCopyright()
	return WorldCommon.GetWorldTag("hasCopyright")
end

function options:SetHasCopyright(bValue)
	if(bValue == false) then
		bValue = nil;
	end
	WorldCommon.SetWorldTag("hasCopyright", bValue);
end

function options:IsCommunityWorld()
	return GameLogic.GetFilters():apply_filters('service.local_service_world.is_community_world', false)
end

function options:SetCommunityWorld(bValue)
	GameLogic.GetFilters():apply_filters('service.local_service_world.set_community_world', bValue)
end

-- "teacher", "vip"
function options:GetUserType()
	return self.userType;
end

-- one can also use GameLogic.IsVip()
function options:IsVip()
	local userType = self:GetUserType()
	return userType == "vip" or userType == "teacher"
end

-- use command "/show tips" or "/hide tips"
-- like auto tips and others
function options:ShowSystemTips(bShow)
	NPL.load("(gl)script/kids/3DMapSystemApp/Assets/AsyncLoaderProgressBar.lua");
	local AsyncLoaderProgressBar = commonlib.gettable("Map3DSystem.App.Assets.AsyncLoaderProgressBar");
	if(AsyncLoaderProgressBar.GetDefaultAssetBar()) then
		AsyncLoaderProgressBar.GetDefaultAssetBar():Show(bShow)
	end

	if(bShow) then
		GameLogic.CreateGetAutoSaver():OnEnterWorld();
	else
		GameLogic.CreateGetAutoSaver():OnLeaveWorld();
	end
end

function options:SetMouseSettingList(list)
	self.moust_setting_list = list
end

function options:GetMouseSettingList(list)
	if self.moust_setting_list == nil then
		local mouse_select_list = Game.PlayerController:LoadRemoteData("SystemSettingsPage.mouse_select_list", nil)
		if mouse_select_list then
			self.moust_setting_list = {}
			for k, v in pairs(mouse_select_list) do
				self.moust_setting_list[v] = k
			end
			return self.moust_setting_list
		end

		self.moust_setting_list = {
			["left"] = "DeleteBlock",
			["right"] = "CreateBlock",
			["middle"] = "ChooseBlock",
		}
	end

	return self.moust_setting_list
end

function options:GetWorldOption(option)
	return WorldCommon.GetWorldTag(option)
end

function options:SetWorldOption(option, bValue)
	if(bValue == false) then
		bValue = nil;
	end
	WorldCommon.SetWorldTag(option, bValue);
end

-- such as "[username]/[worldname]/"
function options:GetRemoteWorldFolder()
	if(not self.remoteFolderName) then
		local currentEnterWorld = GameLogic.GetFilters():apply_filters('store_get', 'world/currentEnterWorld');
		if(currentEnterWorld and currentEnterWorld.user and currentEnterWorld.user.username and currentEnterWorld.foldername) then
			self.remoteFolderName = format("%s/%s/", currentEnterWorld.user.username, currentEnterWorld.foldername);
		else
			self.remoteFolderName = "/";
		end
	end
	return self.remoteFolderName;
end


-- lower movie frame rate, when actors are far from current camera, only affect those without camera actor
function options:SetAutoMovieFPS(isAutoMovieFPS)
	self.isAutoMovieFPS = isAutoMovieFPS
end

function options:IsAutoMovieFPS()
	return self.isAutoMovieFPS
end

-- @param fov: if nil, it defaults to GameLogic.options.normal_fov
function options:SetFieldOfView(fov)
	fov = fov or GameLogic.options.normal_fov;
	if(ParaCamera.GetAttributeObject():GetField("FieldOfView", fov) ~= fov) then
		ParaCamera.GetAttributeObject():SetField("FieldOfView", fov);
		return true;
	end
end

function options:IsOfflineMode()
	return self.isOfflineMode;
end