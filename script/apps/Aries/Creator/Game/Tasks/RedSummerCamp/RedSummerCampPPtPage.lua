--[[
Title: RedSummerCampPPtPage
Author(s): yangguiyi
Date: 2021/9/16
Desc: 
Use Lib:
-------------------------------------------------------
local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
RedSummerCampPPtPage.Show();
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local RedSummerCampPPtPage = NPL.export();
local ParacraftLearningRoomDailyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.lua");
local RedSummerCampCourseScheduling = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCourseScheduling.lua") 
local RedSummerCampMainWorldPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampMainWorldPage.lua");
local RedSummerCampPPtFullPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtFullPage.lua");
local Lan
-- 存储所有课程数据
RedSummerCampPPtPage.LessonsPPtData = {}
RedSummerCampPPtPage.CourseTaskData = {}
RedSummerCampPPtPage.PPtCacheData = {}
-- RedSummerCampPPtPage.LessonFolderList = {{},{},{}}
local page
RedSummerCampPPtPage.DiskFolder = nil
RedSummerCampPPtPage.SplitKey = "_pptindex_"

local key_to_report_name = {
	["ppt_L1"] = "org",		-- 机构课L1
	["ppt_S1"] = "430",		-- 社团课S1
	["ppt_X1"] = "campus",	-- 校园课X1
}
function RedSummerCampPPtPage.OnInit()
	page = document:GetPageCtrl();
	page.OnCreate = RedSummerCampPPtPage.OnCreate
	page.OnClose = RedSummerCampPPtPage.OnClose
end

function RedSummerCampPPtPage.OnCreate()
	RedSummerCampPPtPage.StepNumKey = 0
end

function RedSummerCampPPtPage.OnClose()

	if not RedSummerCampPPtPage.IsSaveIndex then
		RedSummerCampPPtPage.IsOpenPage = false
		page = nil
	end

	RedSummerCampPPtPage.IsSaveIndex = nil
	RedSummerCampMainWorldPage.SetOpenFromCommandMenu(false)

	RedSummerCampPPtPage.UpdateTimer:Change()
	RedSummerCampPPtPage.UpdateTimer = nil	
end

function RedSummerCampPPtPage.Show(course_name, pptIndex)
	if not Lan then
		Lan = NPL.load("Mod/GeneralGameServerMod/Command/Lan/Lan.lua");
	end

	if course_name == nil and pptIndex == nil then
		course_name = RedSummerCampPPtPage.CurCourseName or "ppt_X1"
		pptIndex = RedSummerCampPPtPage.SelectLessonIndex or 1
	end
	RedSummerCampPPtPage.SetIsFullPage(false)
	course_name = course_name or "ppt_X1"
	RedSummerCampPPtPage.SelectLessonIndex = pptIndex or 1
	RedSummerCampPPtPage.StepValueToProjectId = {}
	RedSummerCampPPtPage.SaveWorldStepList = {}
	RedSummerCampPPtPage.SyncWorldStepValue = nil
	RedSummerCampPPtPage.CurCourseName = course_name
	RedSummerCampPPtPage.StepNumKey = 0
	RedSummerCampPPtPage.CurCourseKey = RedSummerCampPPtPage.CurCourseName .. RedSummerCampPPtPage.SplitKey .. RedSummerCampPPtPage.SelectLessonIndex
	RedSummerCampPPtPage.InitData()

	local enable_esc_key = false
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.html",
			name = "RedSummerCampPPtPage.Show", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = enable_esc_key,
			cancelShowAnimation = true,
			--app_key = 0, 
			directPosition = true,
				align = "_fi",
				x = 0,
				y = 0,
				width = 0,
				height = 0,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	RedSummerCampPPtPage.HandleErrorData()

	if not RedSummerCampPPtPage.BindFilter then
		RedSummerCampPPtPage.BindFilter = true
		GameLogic.GetFilters():add_filter("OnSaveWrold", RedSummerCampPPtPage.OnSaveWrold);
		GameLogic.GetFilters():add_filter("SyncWorldFinish", RedSummerCampPPtPage.OnSyncWorldFinish);
		GameLogic:Connect("WorldLoaded", RedSummerCampPPtPage, RedSummerCampPPtPage.OnWorldLoaded, "UniqueConnection");
	end
	
	if RedSummerCampPPtFullPage.IsInFullPage then
		RedSummerCampPPtFullPage.Show(RedSummerCampPPtPage.GetPPtStr());
	end

	if RedSummerCampPPtPage.UpdateTimer == nil then
		RedSummerCampPPtPage.UpdateTimer = commonlib.Timer:new({callbackFunc = function(timer)
			RedSummerCampPPtPage.UpdateStudentNum()
		end})
		RedSummerCampPPtPage.UpdateTimer:Change(0, 1000);	
	end
end

function RedSummerCampPPtPage.RefreshPage()
	if page then
		RedSummerCampPPtPage.StepNumKey = 0
		page:Refresh(0)
	end
end

function RedSummerCampPPtPage.SetStepNumKey(key)
	RedSummerCampPPtPage.StepNumKey = key
end

function RedSummerCampPPtPage.GetStepNumKey()
	return RedSummerCampPPtPage.StepNumKey
end

function RedSummerCampPPtPage.InitPPtConfig(course_name)
	local ppt_mark_down_file = string.format("config/Aries/creator/lesson_ppt/%s.md.xml", course_name)

	local file = ParaIO.open(ppt_mark_down_file, "r");
	if(file:IsValid() ~= true) then
		commonlib.log("error: failed loading card data list file: %s\n", course_name);
		return;
	end

	local strValue = file:readline();
	RedSummerCampPPtPage.PPtName = ""
	local ppt_data_list = {}
	local ppt_data = {}
	local is_div_str = false
	local div_num = 0
	local last_div_is_title = false
	local is_start_notes = false
	local is_start_knowledge_point = false
	local is_hide_div = false
	local profile = KeepWorkItemManager.GetProfile() or {}
	local has_power = profile.tLevel == 1 or GameLogic.IsVip()
	local function handle_div_str(ppt_data, strValue)
		if last_div_is_title then
			strValue = string.format([[<div style="margin-left: 50px;margin-top: 12px;color: #e17a15;font-weight: bold;">%s</div>]], strValue)
		end

		if string.find(strValue, '<step value="1">') then
			last_div_is_title = true
		else
			last_div_is_title = false
		end

		local is_end_hide = false
		local is_note_str;

		if string.find(strValue, "</step>") then
			strValue = strValue .. '<div style="height:16px;"></div>'
		end

		if string.find(strValue, "</notes") then
			is_start_notes = false
			is_note_str = true;
			is_start_knowledge_point = false
			if is_hide_div then
				strValue = ""
				is_hide_div = false
			end
		end

		if is_hide_div then
			strValue = ""
		end
		
		if is_start_notes then
			strValue = strValue .. "<br/>"

			if is_start_knowledge_point then
				if ppt_data.knowledge_point_desc == nil then
					ppt_data.knowledge_point_desc = ""
				end

				ppt_data.knowledge_point_desc = ppt_data.knowledge_point_desc .. strValue
			end

			if string.find(strValue, "知识点") then
				is_start_knowledge_point = true
			end
		end

		-- 处理
		
		if string.find(strValue, "<notes") then
			is_start_notes = true

			if string.match(strValue, 'display="(.+)"') == "teacher" and not has_power then
				is_hide_div = true
				strValue = ""
			end
		end
		if(is_note_str or is_start_notes) then
			ppt_data.notes_str = (ppt_data.notes_str or "") .. strValue;
		else
			ppt_data.div_str = (ppt_data.div_str or "") .. strValue
		end
	end

	-- this will merge multiple notes in ppt_data.notes_str into ppt_data.div_str
	local function formatNotesIntoPPT_()
		for _, ppt_data in ipairs(ppt_data_list) do
			if(ppt_data.notes_str) then
				ppt_data.div_str = (ppt_data.div_str or "") .. table.concat({
					[[<pe:gridview style="margin-left:0px;width:825px;height: 114px; " name="notes_gridview" CellPadding="0" VerticalScrollBarStep="36" VerticalScrollBarOffsetX="8" AllowPaging="false" ItemsPerLine="1" RememberScrollPos="true" DefaultNodeHeight = "36" DataSource='<%=NotesData %>'><Columns>]],
					ppt_data.notes_str,
					[[</Columns></pe:gridview>]]
				})
			end
		end
	end

	while(strValue)do
		local str;
		local item = {};

		if string.find(strValue, "### ") then
			if is_div_str then
				if ppt_data.div_str == nil then
					ppt_data.div_str = ""
				end
				local tab = commonlib.split(strValue,"###")
				strValue = tab[1]
				handle_div_str(ppt_data, "<b>"..strValue.."</b>")
			end

			last_div_is_title = false
		elseif string.find(strValue, "## ") then
			ppt_data = {}
			local tab = commonlib.split(strValue,"##")
			ppt_data.title = tab[1]
			ppt_data_list[#ppt_data_list + 1] = ppt_data
			is_div_str = true
			last_div_is_title = false
		elseif is_div_str then
			handle_div_str(ppt_data, strValue)
		elseif string.find(strValue, "# ") then
			local tab = commonlib.split(strValue,"#")
			RedSummerCampPPtPage.PPtName = tab[1];
			ppt_data_list.PPtName = tab[1]
			last_div_is_title = false
		end
	
		strValue = file:readline();
	end
	file:close();

	formatNotesIntoPPT_()

	RedSummerCampPPtPage.PPtCacheData[course_name] = ppt_data_list
end

function RedSummerCampPPtPage.InitData()
	if RedSummerCampPPtPage.PPtCacheData == nil or RedSummerCampPPtPage.PPtCacheData[RedSummerCampPPtPage.CurCourseName] == nil then
		RedSummerCampPPtPage.InitPPtConfig(RedSummerCampPPtPage.CurCourseName)
	end
	
	local ppt_data_list = RedSummerCampPPtPage.PPtCacheData[RedSummerCampPPtPage.CurCourseName]
	RedSummerCampPPtPage.LessonsPPtData = ppt_data_list
	RedSummerCampPPtPage.SelectPPtData = RedSummerCampPPtPage.LessonsPPtData[RedSummerCampPPtPage.SelectLessonIndex]
end

function RedSummerCampPPtPage.SelectLesson(index)
	if index == RedSummerCampPPtPage.SelectLessonIndex then
		return
	end

	RedSummerCampPPtPage.SelectLessonIndex = index
	RedSummerCampPPtPage.SelectPPtData = RedSummerCampPPtPage.LessonsPPtData[RedSummerCampPPtPage.SelectLessonIndex]
	RedSummerCampPPtPage.CurCourseKey = RedSummerCampPPtPage.CurCourseName .. RedSummerCampPPtPage.SplitKey .. RedSummerCampPPtPage.SelectLessonIndex
	RedSummerCampPPtPage.StepValueToProjectId = {}
	RedSummerCampPPtPage.SaveWorldStepList = {}
	RedSummerCampPPtPage.SyncWorldStepValue = nil
	-- 修复序号改动引发的数据不对的问题
	RedSummerCampPPtPage.HandleErrorData()
	RedSummerCampPPtPage.RefreshPage()
end

function RedSummerCampPPtPage.GetPPtStr()
	local ppt_data = RedSummerCampPPtPage.SelectPPtData
	if ppt_data == nil then
		return ""
	end

	return ppt_data.div_str
end

function RedSummerCampPPtPage.GetPPtTitle()
	local ppt_data = RedSummerCampPPtPage.SelectPPtData
	if ppt_data == nil then
		return ""
	end

	return ppt_data.title
end

function RedSummerCampPPtPage.GetCourseClientData()
	local clientData = KeepWorkItemManager.GetClientData(40007) or {};
	if clientData.CourseTaskData == nil then
		clientData.CourseTaskData = {}
	end
	return clientData.CourseTaskData
end
-- 获取某个步骤是否完成
function RedSummerCampPPtPage.GetStepIsComplete(step)
	local course_all_data = RedSummerCampPPtPage.GetCourseClientData()
	if course_all_data[RedSummerCampPPtPage.CurCourseKey] == nil then
		return false
	end

	local course_data = course_all_data[RedSummerCampPPtPage.CurCourseKey]
	if course_data and course_data[tostring(step)] then
		local value = course_data[tostring(step)]
		return tostring(value) == "1"
	end

	return false
end

function RedSummerCampPPtPage.SetCourseClientData(key, value)
	key = tostring(key)
	value = tostring(value)

	if RedSummerCampPPtPage.CurCourseKey == nil then
		return
	end

	local course_all_data = RedSummerCampPPtPage.GetCourseClientData()
	if course_all_data[RedSummerCampPPtPage.CurCourseKey] == nil then
		course_all_data[RedSummerCampPPtPage.CurCourseKey] = {}
	end

	local course_data = course_all_data[RedSummerCampPPtPage.CurCourseKey]

	if course_data[key] == value then
		return
	end
	course_data.is_fix = true
	course_data[key] = value

	local clientData = KeepWorkItemManager.GetClientData(40007) or {};
	clientData.CourseTaskData = course_all_data

    KeepWorkItemManager.SetClientData(40007, clientData, function()
        RedSummerCampPPtPage.RefreshPage()
    end);

	local ppt_title = RedSummerCampPPtPage.GetPPtTitle()
	local course_title = RedSummerCampPPtPage.CurPPtCourseTitle or ""

	local knowledge_point_desc = RedSummerCampPPtPage.SelectPPtData.knowledge_point_desc or course_title
	local content = string.format("%s <br/> 知识点：<br/>%s", ppt_title, knowledge_point_desc)
	RedSummerCampCourseScheduling.SetDayHistroy(RedSummerCampPPtPage.CurCourseName, content, RedSummerCampPPtPage.SelectLessonIndex)

	-- 上报ppt学习情况
	local lesson_type = key_to_report_name[RedSummerCampPPtPage.CurCourseName]
	local section = RedSummerCampPPtPage.SelectLessonIndex or 1

	if lesson_type then
		keepwork.tatfook.study_learn_records({
			lessonType = lesson_type,
			section = section,
			progress = tonumber(key) or 1,
		}, function(err, msg, data)
		end)
	end
end

function RedSummerCampPPtPage.SetStepValueToProjectId(step_value, projectid)
	if step_value == nil then
		return
	end

	RedSummerCampPPtPage.StepValueToProjectId[tostring(step_value)] = tostring(projectid)
end

function RedSummerCampPPtPage.SetSaveWorldStepValue(step_value)
	if step_value == nil then
		return
	end

	if RedSummerCampPPtPage.SaveWorldStepList == nil then
		RedSummerCampPPtPage.SaveWorldStepList = {}
	end

	RedSummerCampPPtPage.SaveWorldStepList[tostring(step_value)] = 1
end

function RedSummerCampPPtPage.SetSyncWorldStepValue(step_value)
	if step_value == nil then
		return
	end

	RedSummerCampPPtPage.SyncWorldStepValue = step_value
end

function RedSummerCampPPtPage.OnVisitWrold(projectid)
	if projectid and RedSummerCampPPtPage.StepValueToProjectId then
		projectid = tostring(projectid)
		local step_value
		for k, v in pairs(RedSummerCampPPtPage.StepValueToProjectId) do
			if v == projectid then
				step_value = k
				break
			end
		end
		if step_value then
			RedSummerCampPPtPage.SetCourseClientData(step_value, 1)
		end
	end
end

function RedSummerCampPPtPage.OnSaveWrold()
	if RedSummerCampPPtPage.SaveWorldStepList then
		for k, v in pairs(RedSummerCampPPtPage.SaveWorldStepList) do
			RedSummerCampPPtPage.SetCourseClientData(k, 1)
		end
	end
end

function RedSummerCampPPtPage.OnSyncWorldFinish()
	local step_value = RedSummerCampPPtPage.SyncWorldStepValue or "4"
	RedSummerCampPPtPage.SetCourseClientData(step_value, 1)
end

-- course_id 成长任务的天数
function RedSummerCampPPtPage.SetCurPPtCourseTitle(title)
	RedSummerCampPPtPage.CurPPtCourseTitle = title
end

function RedSummerCampPPtPage.SetIsReturnOpenPage(result)
	RedSummerCampPPtPage.IsOpenPage = result
end

function RedSummerCampPPtPage.GetIsReturnOpenPage()
	return RedSummerCampPPtPage.IsOpenPage
end

function RedSummerCampPPtPage.OnWorldLoaded()
	if page then
		-- body
		page:CloseWindow(true)
		page = nil

		RedSummerCampPPtPage.SetIsReturnOpenPage(true)
	end
end

function RedSummerCampPPtPage.SetIsFullPage(flag)
	RedSummerCampPPtPage.IsFullPage = flag
end

function RedSummerCampPPtPage.GetIsFullPage()
	return RedSummerCampPPtPage.IsFullPage
end

function RedSummerCampPPtPage.OpenFullPage()
	RedSummerCampPPtFullPage.Show(RedSummerCampPPtPage.GetPPtStr());
end

function RedSummerCampPPtPage.OpenLastPPtPage()
	if RedSummerCampPPtPage.GetIsReturnOpenPage() then
		RedSummerCampCourseScheduling.ShowView()
		RedSummerCampPPtPage.Show()
	end
end

function RedSummerCampPPtPage.ClosePPtAllPage()
	RedSummerCampPPtPage.IsSaveIndex = true
	if RedSummerCampMainWorldPage.GetOpenFromCommandMenu() then
		RedSummerCampPPtPage.IsOpenPage = true
	end
	
	if page then
		page:CloseWindow(true)
		page = nil
	end

	RedSummerCampCourseScheduling.ClosePage()

	RedSummerCampMainWorldPage.ClosePage()

	RedSummerCampPPtFullPage.ClosePage()
end

function RedSummerCampPPtPage.IsShowCloseAllPageBt()
	return true
end

function RedSummerCampPPtPage.GetContent(dataHistroy)
	local course_name, pptIndex = dataHistroy.key, dataHistroy.pptIndex
	if RedSummerCampPPtPage.PPtCacheData[course_name] == nil then
		RedSummerCampPPtPage.InitPPtConfig(course_name)
	end

	local ppt_data_list = RedSummerCampPPtPage.PPtCacheData[course_name]
	local ppt_data = ppt_data_list[pptIndex]
	if not ppt_data then
		return dataHistroy.content
	end
	
	local ppt_title = ppt_data.title or ""
	local knowledge_point_desc = ppt_data.knowledge_point_desc or ""
	local content = string.format("%s <br/> 知识点：<br/>%s", ppt_title, knowledge_point_desc)
	return content
end

function RedSummerCampPPtPage.HandleErrorData()
	local course_all_data = RedSummerCampPPtPage.GetCourseClientData()
	if course_all_data[RedSummerCampPPtPage.CurCourseKey] == nil then
		return
	end

	local course_data = course_all_data[RedSummerCampPPtPage.CurCourseKey]
	if course_data == nil then
		return
	end
	if not course_data.is_fix then
		if course_data["3"] and tostring(course_data["3"]) == "1" then
			course_data["4"] = 1
			--course_data["3"] = 0
		end

		if course_data["2.1"] and tostring(course_data["2.1"]) == "1" then
			course_data["3"] = 1
		end

		course_data.is_fix = true

		local clientData = KeepWorkItemManager.GetClientData(40007) or {};
		clientData.CourseTaskData = course_all_data
		KeepWorkItemManager.SetClientData(40007, clientData, function()
			-- RedSummerCampPPtPage.RefreshPage()
		end);
	end
end

-- local test_num = 0
function RedSummerCampPPtPage.UpdateStudentNum()
	if page then
		-- test_num = test_num + 1
		if Lan then
			local student_num_value = Lan:GetConnectionCount() or 0;
			-- student_num_value = test_num
			page:SetValue("student_num", string.format("学生(%s)", student_num_value))
		end
	end
end