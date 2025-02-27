--[[
Title: base actor class
Author(s): LiXizhi
Date: 2014/3/30
Desc: for recording and playing back
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/Actor.lua");
local actor = commonlib.gettable("MyCompany.Aries.Game.Movie.Actor");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TimeSeries.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieClipController.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MovieTimeSeriesEditingTask.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieClipTimeLine.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieManager.lua");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
local vector3d = commonlib.gettable("mathlib.vector3d");
local MovieClipTimeLine = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipTimeLine");
local MovieTimeSeriesEditing = commonlib.gettable("MyCompany.Aries.Game.Tasks.MovieTimeSeriesEditing");
local MovieClipController = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipController");
local TimeSeries = commonlib.gettable("MyCompany.Aries.Game.Common.TimeSeries");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local type = type;
local Actor = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Movie.Actor"));
Actor.class_name = "Actor";
Actor:Property("Name", "Actor");
Actor:Property({"isAgent", false, "IsAgent"});
-- whenever the current time is changed or any key is modified. 
Actor:Signal("valueChanged");
-- whenever any of the actor's key data is modified. 
Actor:Signal("keyChanged");
-- the current selected editable variable changed. 
Actor:Signal("currentEditVariableChanged");
-- the itemstack(TimeSeries) is changed, possibly during undo/redo operation. 
Actor:Signal("dataSourceChanged");
Actor:Signal("focusIn");
Actor:Signal("focusOut");

Actor.valueFields = commonlib.ArrayMap:new();

function Actor:ctor()
	self.TimeSeries = TimeSeries:new{name = "Actor",};
	self.valueFields = commonlib.ArrayMap:new();
	self.custom_vars = {};
end

function Actor:Init(itemStack, movieclipEntity, movieclip)
	self:SetItemStack(itemStack)
	self.movieclipEntity = movieclipEntity;
	self:SetMovieClip(movieclip or (self.movieclipEntity and self.movieclipEntity:GetMovieClip()))
	return self;
end

function Actor:SetInitParams(params)
	if(not self.initParams) then
		self.initParams = params;
	else
		commonlib.partialcompare(self.initParams, params);
	end
end

function Actor:GetInitParams()
	return self.initParams;
end

-- get custom user data in init params
function Actor:GetCustomUserData()
	return self.initParams and self.initParams.userData;
end

function Actor:SetInitParam(name, value)
	self.initParams = self.initParams or {};
	self.initParams[name] = value;
end

function Actor:GetInitParam(name)
	return self.initParams and self.initParams[name];
end

-- virtual:
function Actor:ApplyInitParams()
end

function Actor:SetCodeBlock(codeblock)
	self.codeblock = codeblock;
end

function Actor:GetCodeBlock()
	return self.codeblock;
end

function Actor:SetItemStack(itemStack)
	self.itemStack = itemStack;
	self:BindItemStackToTimeSeries();
end

function Actor:GetTimeSeries()
	return self.TimeSeries;
end

-- this is called right after all actors in movie clips have been created. 
function Actor:OnCreate()
end

-- find actor by its display name in containing movie entity
-- @return actor or nil.
function Actor:FindActor(name)
	local movieClip = self:GetMovieClip();
	if(movieClip) then
		return movieClip:FindActor(name);
	end
end

function Actor:GetRootActor()
	local parent = self:GetParentActor();
	if(not parent) then
		return self;
	else
		return parent:GetRootActor();
	end
end

function Actor:SetParentActor(actor)
	self.parentActor = actor;
end

function Actor:GetParentActor()
	return self.parentActor;
end

-- virtual function
function Actor:GetChildActor(name)
end

function Actor:GetCustomVariable(name)
	return self.custom_vars[name];
end

function Actor:SetCustomVariable(name, value)
	self.custom_vars[name] = value;
end

function Actor:BindItemStackToTimeSeries()
	-- needs to clear all multi variable, otherwise undo function will not work properly. 
	self.custom_vars = {};
	local timeseries = self.itemStack:GetDataField("timeseries");
	if(not timeseries) then
		timeseries = {};
		self.itemStack:SetDataField("timeseries", timeseries);
	end
	self.TimeSeries:LoadFromTable(timeseries);
	self:dataSourceChanged();
	self:SetModified();
end

function Actor:GetBoundRadius()
	local entity = self:GetEntity();
	if(entity) then
		return entity:GetBoundRadius();
	end
	return 0;
end

function Actor:IsAllowUserControl()
	local entity = self:GetEntity();
	if(entity) then
		return entity:HasFocus() and not self:IsPlayingMode() and self:IsPaused() and 
			not MovieClipController.IsActorsLocked() and
			not MovieClipTimeLine.IsDraggingTimeLine();
	end
end

-- user is using WASD key to control this actor now. 
function Actor:IsUserControlled()
	local entity = self:GetEntity();
	if(entity) then
		return entity:HasFocus() and not entity:IsControlledExternally();
	end
end

-- get the movie clip that contains this actor. 
function Actor:GetMovieClip()
	return self.movieclip;
end

function Actor:SetMovieClip(movieClip)
	self.movieclip = movieClip;
end

function Actor:GetMovieClipEntity()
	return self.movieclipEntity;
end

-- whether its persistent. 
function Actor:IsPersistent()
	return self.is_persistent;
end

-- whether the entity should be serialized to disk. 
function Actor:SetPersistent(bIsPersistent)
	self.is_persistent = bIsPersistent;
end


-- it is only in playing mode when activated by a circuit. 
-- any other way of triggering the movieclip is not playing mode(that is edit mode)
function Actor:IsPlayingMode()
	if(self.movieclip) then
		return self.movieclip:IsPlayingMode();
	end
end

function Actor:GetSelectionName()
	return self:GetDisplayName();
end

-- get display name
function Actor:GetDisplayName()
	if(self.itemStack) then
		return self.itemStack:GetDisplayName() or "";
	end
	return "";
end

function Actor:SetDisplayName(name)
	if(self.itemStack) then
		self.itemStack:SetDisplayName(name);
	end
end

-- @return the entity position if any
function Actor:GetPosition()
	if(self.entity) then
		return self.entity:GetPosition();
	end
end

-- @return the entity position if any
function Actor:GetRollPitchYaw()
	if(self:GetEntity()) then
		local obj = self:GetEntity():GetInnerObject();
		if(obj) then
			return obj:GetField("roll", 0), obj:GetField("pitch", 0), obj:GetField("yaw", 0);
		end
	end
	return 0,0,0;
end


function Actor:GetTime()
	local movieClip = self:GetMovieClip();
	if(movieClip) then
		return movieClip:GetTime();
	end
end

function Actor:SetTime(time)
	local movieClip = self:GetMovieClip();
	if(movieClip) then
		return movieClip:SetTime(time);
	end
end


function Actor:GetEntity()
	return self.entity;
end

-- use BeginUpdate() and EndUpdate() to avoid entity be refreshed. 
function Actor:SaveStaticAppearance()
	--self:BeginUpdate();
	-- save code here
	--self:EndUpdate();
end

function Actor:GetItemStack()
	return self.itemStack;
end

function Actor:OpenEditor()
	MovieClipController.SetFocusToItemStack(self.itemStack);
end

function Actor:GetVariable(keyname)
	return self.TimeSeries:GetVariable(keyname);
end

-- @param keypath: keyname or key local path. such as "x", "bones::root" 
function Actor:GetChildVariableByPath(keypath)
	if(keypath) then
		local subkey;
		keypath, subkey = keypath:match("^([^:]+):*(.*)"); 
		local var = self.TimeSeries:GetChild(keypath);
		if(var) then
			if(subkey and subkey~="" and var.GetChild) then
				return var:GetChild(subkey);
			end
		end
	end
	return;
end

-- virtual:
-- @return nil or a table of variable list. 
function Actor:GetEditableVariableList()
end

function Actor:GetEditableVariableByName(name)
	local list = self:GetEditableVariableList()
	if(list) then
		local var;
		for index, varName in ipairs(list) do
			if(varName == name) then
				var = self:GetEditableVariable(index)
				break;
			end
		end
		return var;
	end
end

-- virtual: 
-- get editable variable by index. only used by editor for recently selected variable. 
-- @param selected_index: nil if it means the current one. 
-- @return var, cur_index
function Actor:GetEditableVariable(selected_index)
	local varList = self:GetEditableVariableList();
	if(varList) then
		selected_index = selected_index or self:GetCurrentEditVariableIndex();
		return self.TimeSeries:GetVariable(varList[selected_index]);
	end
end

function Actor:GetCurrentEditVariableIndex()
	return self.curEditVariableIndex or 1;
end

-- whether we will also show  the command actor's variables on this actor's timeline. 
function Actor:CanShowCommandVariables()
	return false;
end

-- return index by name
-- @return index
function Actor:FindEditVariableByName(name)
	local varList = self:GetEditableVariableList();
	if(varList) then
		for index, var in ipairs(varList) do
			if(var == name) then
				return index;
			end
		end
	end
end

function Actor:SetCurrentEditVariableIndex(selected_index)
	if(self.curEditVariableIndex~=selected_index) then
		self.curEditVariableIndex = selected_index;
		self:currentEditVariableChanged(selected_index);
	end
end

-- @param bStartFromFirstKeyFrame: whether we will only value after the time of first key frame. default to false.
function Actor:GetValue(keyname, time, bStartFromFirstKeyFrame)
	local v = self:GetVariable(keyname);
	if(v and time) then
		if(not bStartFromFirstKeyFrame) then
			-- default to animId = 1
			return v:getValue(1, time);
		else
			local firstTime = v:GetFirstTime();
			if(firstTime and firstTime <= time) then
				return v:getValue(1, time);
			end
		end
	end
end

-- get last recorded time.
function Actor:GetLastTime(keyname)
	local v = self:GetVariable(keyname);
	if(v) then
		return v:GetLastTime() or 0;
	end
	return 0;
end

function Actor:IsSelected()
	return Game.SelectionManager:GetSelectedActor() == self;
end

-- select me: for further editing. 
function Actor:SelectMe()
	local entity = self:GetEntity();
	if(entity) then
		local obj = entity:GetInnerObject();
		if(obj) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectModelTask.lua");
			local task = MyCompany.Aries.Game.Tasks.SelectModel:new({obj=obj})
			task:Run();	
		end
	end
end

-- a pair of BeginModify and EndModify will allow undo/redo of the actor's timeline. 
function Actor:BeginModify()
	self.undo_task = MovieTimeSeriesEditing:new()
	self.undo_task:BeginModify(self:GetMovieClip(), self:GetItemStack());
end

function Actor:EndModify()
	if(self.undo_task) then
		self.undo_task:EndModify();
		self.undo_task = nil;
		self:SetModified();
	end
end

-- @return true if recording. 
function Actor:SetRecording(isRecording)
	if(self:IsKeyFrameOnly()) then
		return nil;
	else
		if(isRecording~=self.isRecording) then
			self.isRecording = isRecording;

			if(isRecording) then
				self:BeginModify();
			else
				self:EndModify();
			end

			if(isRecording) then
				--self:RemoveKeysInTimeRange(self:GetTime(), self:GetCurrentRecordingEndTime());
				self:ClearRecordToTime();
			end
			
			local movieClip = self:GetMovieClip();
			if(movieClip) then
				movieClip:SetActorRecording(self, isRecording);
			end
		end
		return self.isRecording;
	end
end

function Actor:IsRecording()
	return self.isRecording == true;
end


-- add new key at time, data. if there is already a key at the time, we will replace it. 
function Actor:AddKey(keyname, time, value)
	local v = self:GetVariable(keyname);
	if(v) then
		if(v:AddKey(time, value)) then
			self:SetModified();
			return true;
		end
	end
end

-- when a group of changes takes place, such as during recording, 
-- we can put change inside BeginUpdate() and EndUpdate() pairs, so that 
-- only one keyChanged() event will be emitted. 
function Actor:BeginUpdate()
	if(not self.isBeginAddKey) then
		self.isBeginAddKey = 0;
		self.isKeyChanged = false;
	else
		self.isBeginAddKey = self.isBeginAddKey + 1;
	end
end

function Actor:EndUpdate()
	if(self.isBeginAddKey) then
		if(self.isBeginAddKey <= 0) then
			self.isBeginAddKey = false;
			if(self.isKeyChanged) then
				self.isKeyChanged = false;
				self:SetModified();
			end
		else
			self.isBeginAddKey = self.isBeginAddKey - 1;
		end
	end
end

function Actor:SetModified()
	if(self.isBeginAddKey) then
		self.isKeyChanged = true;
	else
		self:valueChanged();
		self:keyChanged();
	end
end

-- add new key at time, data. if there is already a key at the time, we will replace it. 
-- it will not add key if previous and next key is same as current. 
-- this function is ideal for recording player actions. 
function Actor:AutoAddKey(keyname, time, value)
	local v = self:GetVariable(keyname);
	if(v) then
		local res;
		if(self.is_adding_key) then
			res = v:AddKey(time, value);
		else
			-- res = v:AutoAddKey(time, value);
			res = v:AutoAppendKey(time, value);
		end
		if(res) then
			self:SetModified();
		end
	end
end

-- clear all keys after time, and add the new key. 
function Actor:AutoAppendKey(keyname, time, value)
	local v = self:GetVariable(keyname);
	if(v) then
		local res;
		if(self.is_adding_key) then
			res = v:AddKey(time, value);
		else
			res = v:AutoAppendKey(time, value);
		end
		if(res) then
			self:SetModified();
		end
	end
end

-- record and add a key frame at the current position. 
function Actor:AddKeyFrame()
	self.is_adding_key = true;
	self:FrameMoveRecording(0);
	self:SetControllable(self:IsAllowUserControl() == true);
	self.is_adding_key = nil;
	GameLogic.GetFilters():apply_filters("SchoolCenter.AddEvent", "create.world.animation");
end

-- virtual function: display a UI to let the user to edit this keyframe's data. 
function Actor:EditKeyFrame(keyname, time)
	time = time or self:GetTime();
end

-- add a key frame at the specified position. 
-- @param time: if nil, it is current time. 
function Actor:AddKeyFrameByName(name, time, data)
	if(data~=nil) then
		self:BeginModify();
		self.is_adding_key = true;
		time = time or self:GetTime();
		self:AutoAddKey(name, time, data);
		self.is_adding_key = nil;
		self:EndModify();
		GameLogic.GetFilters():apply_filters("SchoolCenter.AddEvent", "create.world.animation");
	end
end


-- get current recording end time. 
function Actor:GetCurrentRecordingEndTime()
	return self:GetMaxLength();
end

function Actor:GetMaxLength()
	local movieClip = self:GetMovieClip();
	if(movieClip) then
		return movieClip:GetLength() or 10000;
	end
	return 10000;
end

-- shifting keyframes from shift_begin_time to end by the amount of offset_time. 
function Actor:ShiftKeyFrame(shift_begin_time, offset_time)
	self:BeginModify();
	local max_length = self:GetMaxLength();
	if((shift_begin_time+offset_time) > max_length) then
		offset_time = max_length - shift_begin_time;
	end
	self.TimeSeries:ShiftKeyFrame(shift_begin_time, offset_time);
	self:SetModified();
	self:EndModify();
end

-- remove the key frame at key_time if there is a key frame. 
function Actor:RemoveKeyFrame(keytime)
	self:BeginModify();
	self.TimeSeries:RemoveKeyFrame(keytime);
	self:SetModified();
	self:EndModify();
end

-- copy keyframe from from_keytime to keytime
function Actor:CopyKeyFrame(keytime, from_keytime)
	self:BeginModify();
	self.TimeSeries:CopyKeyFrame(keytime, from_keytime);
	self:SetModified();
	self:EndModify();
end

-- Update or insert (Upsert) a key frame at given time.
-- @param data: data is cloned before updating. 
function Actor:UpsertKeyFrame(key_time, data)
	self:BeginModify();
	self.TimeSeries:UpsertKeyFrame(key_time, data);
	self:SetModified();
	self:EndModify();
end

-- paste all key frames between [fromTime, toTime] to time
function Actor:PasteKeyFramesInRange(time, fromTime, toTime)
	self:BeginModify();
	self.TimeSeries:PasteKeyFramesInRange(time, fromTime, toTime);
	self:SetModified();
	self:EndModify();
end

-- move keyframe from from_keytime to keytime
function Actor:MoveKeyFrame(keytime, from_keytime)
	self:BeginModify();
	self.TimeSeries:MoveKeyFrame(keytime, from_keytime);
	self:SetModified();
	self:EndModify();
end



function Actor:Resume()
	local movieClip = self:GetMovieClip();
	if(movieClip) then
		movieClip:Resume();
	end
end

function Actor:Pause()
	local movieClip = self:GetMovieClip();
	if(movieClip) then
		movieClip:Pause();
	end
end

function Actor:IsPaused()
	local movieClip = self:GetMovieClip();
	if(movieClip) then
		return movieClip:IsPaused();
	end
end

function Actor:Stop()
	local movieClip = self:GetMovieClip();
	if(movieClip) then
		movieClip:Stop();
	end
end

function Actor:GotoBeginFrame()
	local movieClip = self:GetMovieClip();
	if(movieClip) then
		movieClip:GotoBeginFrame();
		movieClip:Pause();
	end
end

function Actor:GotoEndFrame()
	local movieClip = self:GetMovieClip();
	if(movieClip) then
		movieClip:GotoEndFrame();
		movieClip:Pause();
	end
end

function Actor:RestartRecording()
	self:Stop();
	self:SetRecording(true);
	self:Resume();
end

-- clear all record to a given time. if curTime is nil, it will use the current time. 
function Actor:ClearRecordToTime(curTime)
	-- trim all keys to current time
	local curTime = curTime or self:GetTime();
	if(curTime) then
		if(curTime <= 0) then
			self.TimeSeries:TrimEnd(curTime-1)
		else
			self.TimeSeries:TrimEnd(curTime);
		end	
		self:SetModified();
	end
end

-- remove all keys in the [fromTime, toTime]
-- @param fromTime: if fromTime is nil, it will use the current time. 
-- @param toTime: if nil, it will be max length. 
function Actor:RemoveKeysInTimeRange(fromTime, toTime)
	-- trim all keys to current time
	local fromTime = fromTime or self:GetTime();
	local toTime = toTime or self:GetMaxLength();
	if(fromTime and toTime) then
		self.TimeSeries:RemoveKeysInTimeRange(fromTime, toTime);
		self:SetModified();
	end
end

function Actor:SetControllable(bIsControllable)
end

-- whether the actor can create blocks. The camera actor can not create blocks
function Actor:CanCreateBlocks()
	return;
end

-- this function is called whenver the create block task is called. i.e. the user has just created some block
function Actor:OnCreateBlocks(blocks)
end

-- this function is called whenver the destroy block task is called. i.e. the user has just destroyed some blocks
function Actor:OnDestroyBlocks(blocks)
end

function Actor:SetFocus()
	local entity = self:GetEntity()
	if(entity) then
		self.lastTime = nil;
		entity:SetFocus();
	end
end

function Actor:HasFocus()
	local entity = self:GetEntity()
	if(entity) then
		return entity:HasFocus();
	end
end

function Actor:DestroyEntity()
	local entity = self:GetEntity()
	if(entity and not self:IsAgent()) then
		if(entity:HasFocus()) then
			EntityManager.SetFocus(EntityManager.GetPlayer());
		end
		entity:Destroy();
		self.entity = nil;
	end
end

-- remove the scene entity that representing this actor. 
function Actor:OnRemove()
	self:DestroyEntity();
end

function Actor:FrameMoveRecording(deltaTime)
end

function Actor:FrameMovePlaying(deltaTime)
end

-- only supporting key frames, not recording. 
function Actor:IsKeyFrameOnly()
	return false;
end

-- whether the actor is being selected in the editor
function Actor:FrameMove(deltaTime, bIsSelected)
	if(self:IsRecording())then
		self:FrameMoveRecording(deltaTime);
	else
		self:FrameMovePlaying(deltaTime, bIsSelected);
	end
	if(bIsSelected)  then
		local time = self:GetTime();
		if(self.lastTime ~= time) then
			self.lastTime = time;
			self:valueChanged();
		end
	end
end

-------------------------------------
-- reimplement attribute field 
-------------------------------------

-- @param getVar: get variable function. it is function that usually return the multivariable
-- @return attribute plug
function Actor:AddValue(name, getVar)
	self.valueFields:add(name, {name=name, getVar=getVar})
	return self:findPlug(name);
end

function Actor:GetFieldNum()
	return self.TimeSeries:GetVariableCount() + self.valueFields:size();
end

function Actor:GetFieldIndex(name)
	return self.TimeSeries:GetVariableIndex(name) 
		or ((self.valueFields:getIndex(sFieldname) or 0) + self.TimeSeries:GetVariableCount());
end

function Actor:GetFieldName(valueIndex)
	if(valueIndex <= self.TimeSeries:GetVariableCount()) then
		return self.TimeSeries:GetVariableName(valueIndex);
	else
		local field = self.valueFields:at(valueIndex - self.TimeSeries:GetVariableCount());
		if(field) then
			return field.name;
		end
	end
end

function Actor:GetFieldType(nIndex)
	return "";
end

function Actor:SetField(name, value)
	local oldValue = self:GetField(name);
	-- skip equal values
	if(type(oldValue)== "table") then
		if(commonlib.partialcompare(oldValue, value)) then
			return;
		end
	elseif(oldValue == value) then
		return;
	end

	local field = self.valueFields:get(name);
	if(field) then
		if(field.getVar(self):AddKey(self:GetTime(), value)) then
			self:SetModified();
		end
	else
		self:AddKey(name, self:GetTime(), value);	
	end
end

function Actor:GetField(name, defaultValue)
	local field = self.valueFields:get(name);
	if(field) then
		return field.getVar(self):getValue(1, self:GetTime());
	else
		return self:GetValue(name, self:GetTime()) or defaultValue;
	end
end

-- return the inner biped object
function Actor:GetInnerObject()
	local entity = self:GetEntity();
	if(entity) then
		return entity:GetInnerObject();
	end
end

-- return the animation instance. 
function Actor:GetAnimInstance()
	local entity = self:GetEntity();
	if(entity) then
		local obj = entity:GetInnerObject();
		if(obj) then
			local animInstance = obj:GetAttributeObject():GetChildAt(1,1);
			if(animInstance and animInstance:IsValid()) then
				return animInstance;
			end
		end
	end
end

-- if no camera position is found, the current actor's position is used. 
function Actor:RestoreLastFreeCameraPosition()
	local cameraEntity = GameLogic.GetFreeCamera();
	if(self.lastFreeCameraPos) then
		local dx, dy, dz = self.lastFreeCameraPos.dx, self.lastFreeCameraPos.dy, self.lastFreeCameraPos.dz;
		local ax, ay,az = self:GetPosition();
		cameraEntity:SetPosition(dx+ax, dy+ay, dz+az);
		ParaCamera.SetEyePos(self.lastFreeCameraPos.eye_dist, self.lastFreeCameraPos.eye_liftup, self.lastFreeCameraPos.eye_rot_y);
	else
		cameraEntity:SetPosition(self:GetPosition());
	end
end

-- @param bForceSave: if nil, we will only save if free camera has focus
function Actor:SaveFreeCameraPosition(bForceSave)
	local cameraEntity = GameLogic.GetFreeCamera();
	
	if(cameraEntity) then
		if(cameraEntity:HasFocus() or bForceSave) then
			if(not self.lastFreeCameraPos) then
				self.lastFreeCameraPos = {};
			end
			local x, y, z = cameraEntity:GetPosition();
			local ax, ay,az = self:GetPosition();
			self.lastFreeCameraPos.dx = x - ax;
			self.lastFreeCameraPos.dy = y - ay;
			self.lastFreeCameraPos.dz = z - az;
			self.lastFreeCameraPos.eye_dist, self.lastFreeCameraPos.eye_liftup, self.lastFreeCameraPos.eye_rot_y = ParaCamera.GetEyePos();
		end
	else
		self.lastFreeCameraPos = nil;
	end
end

function Actor:CanShowSelectManip()
	return true
end

function Actor:IsAgent()
	return self.isAgent;
end

-- taking control of the give entity. But it will not delete the entity when actor is removed.
function Actor:BecomeAgent(entity)
	if(entity) then --  and entity:isa(EntityManager.EntityMovable)
		local lastEntity = self:GetEntity();
		if(lastEntity ~= entity) then	
			self:DestroyEntity();
		end
		self.entity = entity;
		self.isAgent = true;
		MovieManager:AddActorName(entity.name or "");
	end
end

-- @param minInterval: default to 50
-- @param maxInterval: default to 200
-- @return between 50 to 200 FPS, the closer to main camera, the smaller the interval
function Actor:GetTickIntervalByCameraDist(minInterval, maxInterval)
	local eyePos = GameLogic.GetEyePosition()
	local entity = self:GetEntity();
	if(entity) then
		local dist =  math.sqrt(entity:GetDistanceSq(eyePos[1], eyePos[2], eyePos[3]) or 0);
		-- from [15,70] meters to [minInterval, maxInterval] ms. 
		if(dist < 15) then
			return minInterval or 50;
		else
			return math.min((minInterval or 50) + (dist-15) * 5, maxInterval or 200)
		end
	end
	return minInterval;
end
