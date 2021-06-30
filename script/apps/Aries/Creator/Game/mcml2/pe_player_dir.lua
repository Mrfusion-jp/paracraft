--[[
Title: div element
Author(s): chenjinxian
Date: 2020/8/6
Desc: kp:usertag element
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml2/pe_player_dir.lua");
MyCompany.Aries.Game.mcml2.pe_player_dir:RegisterAs("pe:player_dir");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/mcml/PageElement.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml2/ItemPlayerDir.lua");
local PageElement = commonlib.gettable("System.Windows.mcml.PageElement");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ItemPlayerDir = commonlib.gettable("MyCompany.Aries.Game.mcml2.ItemPlayerDir");

local pe_player_dir = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("MyCompany.Aries.Game.mcml2.pe_player_dir"));
pe_player_dir:Property({"class_name", "pe:player_dir"});

function pe_player_dir:ctor()
end

function pe_player_dir:LoadComponent(parentElem, parentLayout, style)
	local _this = self.control;
	if (not _this) then
		_this = ItemPlayerDir:new():init(parentElem);
		self:SetControl(_this);
	else
		_this:SetParent(parentElem);
	end

	pe_player_dir._super.LoadComponent(self, _this, parentLayout, style);
end

function pe_player_dir:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
	local _this = self.control;
	if(_this) then
		local icon = self:GetAttributeWithCode("icon", nil, true)
        local iconSize = self:GetAttributeWithCode("iconSize", nil, true)
        local iconCenterX = self:GetAttributeWithCode("iconCenterX", nil, true)
        local iconCenterY = self:GetAttributeWithCode("iconCenterY", nil, true)
		--echo({iconSize,iconCenterX,iconCenterY})
        if icon then
            _this:SetPlayerIcon(icon)
        end
        if iconSize then
            _this:SetPlayerIconSize(tonumber(iconSize))
        end
        if iconCenterX then
            _this:SetPlayerIconCenterX(tonumber(iconCenterX))
        end
        if iconCenterY then
            _this:SetPlayerIconCenterY(tonumber(iconCenterY))
        end
	end

	pe_player_dir._super.OnLoadComponentBeforeChild(self, parentElem, parentLayout, css)	
end

function pe_player_dir:OnBeforeChildLayout(layout)
	if(#self ~= 0) then
		local myLayout = layout:new();
		local css = self:GetStyle();
		local width, height = layout:GetPreferredSize();
		local padding_left, padding_top = css:padding_left(),css:padding_top();
		myLayout:reset(padding_left,padding_top,width+padding_left, height+padding_top);
		self:UpdateChildLayout(myLayout);
		width, height = myLayout:GetUsedSize();
		width = width - padding_left;
		height = height - padding_top;
		layout:AddObject(width, height);
	end
	return true;
end

-- virtual function: 
-- after child node layout is updated
function pe_player_dir:OnAfterChildLayout(layout, left, top, right, bottom)
	if(self.control) then
		self.control:setGeometry(left, top, right-left, bottom-top);
	end
end
