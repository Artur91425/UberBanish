if UB_playerClass ~= "WARLOCK" then return end
local _G = getfenv()

local ConfigFrame, MinimapButton, checkButton, buttonTable
local MAP_ONOFF = { [false] = "|cffff0000"..UB_OFF.."|r", [true] = "|cff00ff00"..UB_ON.."|r" }

function UberBanish:LoadOptions()
	MinimapButton = CreateFrame('Button', self:GetName().."MinimapButton", Minimap)
	MinimapButton:SetClampedToScreen(true)
	MinimapButton:SetMovable(true)
	MinimapButton:EnableMouse(true)
	MinimapButton:SetFrameStrata('LOW')
	MinimapButton:SetWidth(31)
	MinimapButton:SetHeight(31)
	MinimapButton:SetFrameLevel(9)
	MinimapButton:SetHighlightTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight')
	MinimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
	MinimapButton:RegisterForDrag('LeftButton')
	MinimapButton:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
	MinimapButton:SetScript("OnDragStart", function() this:StartMoving() end)
	MinimapButton:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
	MinimapButton:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, ANCHOR_BOTTOMLEFT)
		GameTooltip:SetText(UB_TITLE_VERSION)
		GameTooltip:AddDoubleLine(UB_MB_TOOLTIP1[1], UB_MB_TOOLTIP1[2], 1, 1, 1, 1, 1, 1)
		GameTooltip:AddDoubleLine(UB_MB_TOOLTIP2[1], UB_MB_TOOLTIP2[2], 1, 1, 1, 1, 1, 1)
		GameTooltip:Show()
	end)
	MinimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
	MinimapButton:SetScript("OnClick", function()
		if UberBanishDB.Enabled then
			if arg1 == "RightButton" then
				if ConfigFrame:IsShown() then ConfigFrame:Hide() else ConfigFrame:Show() end
			else
				local frame = _G[self:GetName().."BanishButton"]
				if frame:IsShown() then
					frame:Hide()
					self:print(UB_BB_HIDDEN)
				else
					frame:Show()
					self:print(UB_BB_SHOWN)
				end
			end
		else
			if ConfigFrame:IsShown() then ConfigFrame:Hide() else ConfigFrame:Show() end
		end
	end)
	
	MinimapButton.overlay = MinimapButton:CreateTexture('OVERLAY')
	MinimapButton.overlay:SetWidth(53)
	MinimapButton.overlay:SetHeight(53)
	MinimapButton.overlay:SetTexture('Interface\\Minimap\\MiniMap-TrackingBorder')
	MinimapButton.overlay:SetPoint('TOPLEFT', 0,0)
	
	MinimapButton.icon = MinimapButton:CreateTexture('BACKGROUND')
	MinimapButton.icon:SetWidth(20)
	MinimapButton.icon:SetHeight(20)
	MinimapButton.icon:SetTexture('Interface\\Icons\\Spell_Shadow_Cripple')
	MinimapButton.icon:SetTexCoord(.05, .95, .05, .95)
	MinimapButton.icon:SetPoint('CENTER', 1, 1)
	
	ConfigFrame = CreateFrame("Frame", self:GetName().."ConfigFrame", UIParrent)
	table.insert(UISpecialFrames, ConfigFrame:GetName()) -- provides close frame on escape pressed
	ConfigFrame:SetClampedToScreen(true)
	ConfigFrame:SetToplevel(true)
	ConfigFrame:SetFrameStrata("DIALOG")
	ConfigFrame:SetMovable(1)
	ConfigFrame:EnableMouse(1)
	ConfigFrame:Hide()
	ConfigFrame:SetPoint("CENTER", -200, 200)
	ConfigFrame:SetWidth(500)
	ConfigFrame:SetHeight(260)
	ConfigFrame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", tile = true, tileSize = 32,
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 32,
		insets = {left = 11, right = 12, top = 12, bottom = 11},
	})
	ConfigFrame:RegisterForDrag("LeftButton")
	ConfigFrame:SetScript("OnShow", function() self:UpdateButtonsState() end)
	ConfigFrame:SetScript("OnDragStart", function() this:StartMoving() end)
	ConfigFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
	
	ConfigFrame.header = ConfigFrame:CreateTexture("ARTWORK")
	ConfigFrame.header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	ConfigFrame.header:SetPoint("TOP", 0, 14)
	ConfigFrame.header:SetWidth(260)
	ConfigFrame.header:SetHeight(64)
	ConfigFrame.header.text = ConfigFrame:CreateFontString(ConfigFrame:GetName().."Title", "ARTWORK", "GameFontNormal")
	ConfigFrame.header.text:SetPoint("TOP", 0, 0)
	ConfigFrame.header.text:SetText(UB_TITLE_VERSION)
	
	buttonTable = {
		[1] = {"SpamBanishStart", UB_CHECKBUTTON1_DESC},
		[2] = {"TwentySecWarning", UB_CHECKBUTTON2_DESC},
		[3] = {"TenSecWarning", UB_CHECKBUTTON3_DESC},
		[4] = {"FiveSecWarning", UB_CHECKBUTTON4_DESC},
		[5] = {"SpamBanishEnd", UB_CHECKBUTTON5_DESC},
		[6] = {"NotifyLocksOnDeath", UB_CHECKBUTTON6_DESC},
		[7] = {"SpamEarlyBreak", UB_CHECKBUTTON7_DESC, UB_CHECKBUTTON7_TOOLTIP},
		[8] = {"SpamDeath", UB_CHECKBUTTON8_DESC, UB_CHECKBUTTON8_TOOLTIP},
		[9] = {"SayWhenSolo", UB_CHECKBUTTON9_DESC}
	}
	
	local buttonSize, buttonSpacing = 30, 5
	for k, v in pairs(buttonTable) do
		local buttonName, buttonText, buttonTooltip = v[1], v[2], v[3]
		checkButton = CreateFrame("CheckButton", "ConfigFrame"..buttonName.."CheckButton", ConfigFrame, "UICheckButtonTemplate")
		local offsetX, i = 20, k
		if k > 5 then offsetX, i = 240, k-5 end
		checkButton:SetPoint("TOPLEFT", ConfigFrame, "TOPLEFT", offsetX, -(40 + i * (buttonSize + buttonSpacing)))
		checkButton.text = checkButton:CreateFontString("Status", "LOW", "GameFontNormal")
		checkButton.text:SetFont(STANDARD_TEXT_FONT, 11)
		checkButton.text:SetPoint("LEFT", checkButton, "RIGHT", 0, 0)
		checkButton.text:SetText(buttonText)
		checkButton:RegisterForClicks('LeftButtonUp')
		checkButton:SetScript("OnClick", function()
			if this:GetChecked() then
				UberBanishDB[buttonName] = true
				else
				UberBanishDB[buttonName] = false
			end
			self:print(format(UB_OPTION_NOW_SET, "|cffffff7f"..buttonName.."|r", "|cffffff7f[|r"..MAP_ONOFF[UberBanishDB[buttonName] and true or false].."|cffffff7f]|r"))
		end)
		checkButton:SetScript("OnEnter", function()
			if not buttonTooltip then return end
			GameTooltip:SetOwner(this, ANCHOR_BOTTOM)
			GameTooltip:SetText(buttonTooltip)
			GameTooltip:Show()
		end)
		checkButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
	end
	
	ConfigFrame.closeButton = CreateFrame("Button", ConfigFrame:GetName().."CloseButton", ConfigFrame, "GameMenuButtonTemplate")
	ConfigFrame.closeButton:SetWidth(100)
	ConfigFrame.closeButton:SetHeight(22)
	ConfigFrame.closeButton:SetText(CLOSE)
	ConfigFrame.closeButton:SetPoint("BOTTOMRIGHT", ConfigFrame, "BOTTOMRIGHT", -15, 15)
	ConfigFrame.closeButton:RegisterForClicks('LeftButtonUp')
	ConfigFrame.closeButton:SetScript("OnClick", function() ConfigFrame:Hide() end)

	ConfigFrame.infoButton = CreateFrame("Button", ConfigFrame:GetName().."InfoButton", ConfigFrame, "GameMenuButtonTemplate")
	ConfigFrame.infoButton:SetWidth(100)
	ConfigFrame.infoButton:SetHeight(22)
	ConfigFrame.infoButton:SetText(UB_INFO)
	ConfigFrame.infoButton:SetPoint("BOTTOMRIGHT", ConfigFrame.closeButton, "BOTTOMLEFT", -5, 0)
	ConfigFrame.infoButton:RegisterForClicks('LeftButtonUp')
	ConfigFrame.infoButton:SetScript("OnClick", function() InfoFrame:Show() end)
	
	ConfigFrame.enableButton = CreateFrame("CheckButton", "ConfigFrameEnableCheckButton", ConfigFrame, "UICheckButtonTemplate")
	ConfigFrame.enableButton:SetPoint("TOPLEFT", ConfigFrame, "TOPLEFT", 20, -30)
	ConfigFrame.enableButton.text = ConfigFrame.enableButton:CreateFontString("Status", "LOW", "GameFontNormal")
	ConfigFrame.enableButton.text:SetFont(STANDARD_TEXT_FONT, 11)
	ConfigFrame.enableButton.text:SetPoint("LEFT", ConfigFrame.enableButton, "RIGHT", 0, 0)
	ConfigFrame.enableButton.text:SetText(UB_ENABLE)
	ConfigFrame.enableButton:RegisterForClicks('LeftButtonUp')
	ConfigFrame.enableButton:SetScript("OnShow", function() this:SetChecked(UberBanishDB.Enabled) end)
	ConfigFrame.enableButton:SetScript("OnClick", function()
		if this:GetChecked() then
			UberBanishDB.Enabled = true
			self:OnEnable()
			else
			UberBanishDB.Enabled = false
			self:OnDisable()
		end
		self:print(format(UB_OPTION_NOW_SET, "|cffffff7f"..UB_STANDBY.."|r", "|cffffff7f[|r"..MAP_ONOFF[UberBanishDB.Enabled and true or false].."|cffffff7f]|r"))
		self:UpdateButtonsState()
	end)
	
	
	ConfigFrame.debugButton = CreateFrame("CheckButton", "ConfigFrameDebugCheckButton", ConfigFrame, "UICheckButtonTemplate")
	ConfigFrame.debugButton:SetPoint("TOPLEFT", ConfigFrame, "TOPLEFT", 240, -30)
	ConfigFrame.debugButton.text = ConfigFrame.debugButton:CreateFontString("Status", "LOW", "GameFontNormal")
	ConfigFrame.debugButton.text:SetFont(STANDARD_TEXT_FONT, 11)
	ConfigFrame.debugButton.text:SetPoint("LEFT", ConfigFrame.debugButton, "RIGHT", 0, 0)
	ConfigFrame.debugButton.text:SetText(UB_DEBUGGING)
	ConfigFrame.debugButton:SetScript("OnShow", function() this:SetChecked(UberBanishDB.Debugging) end)
	ConfigFrame.debugButton:SetScript("OnClick", function()
		if this:GetChecked() then
			UberBanishDB.Debugging = true
			else
			UberBanishDB.Debugging = false
		end
		self:print(format(UB_OPTION_NOW_SET, "|cffffff7f"..UB_DEBUGGING.."|r", "|cffffff7f[|r"..MAP_ONOFF[UberBanishDB.Debugging and true or false].."|cffffff7f]|r"))
	end)
	
	InfoFrame = CreateFrame("Frame", self:GetName().."InfoFrame", UIParrent)
	InfoFrame:SetClampedToScreen(true)
	InfoFrame:SetToplevel(true)
	InfoFrame:SetFrameStrata("DIALOG")
	InfoFrame:SetMovable(1)
	InfoFrame:EnableMouse(1)
	InfoFrame:Hide()
	InfoFrame:SetPoint("CENTER", -200, 200)
	InfoFrame:SetWidth(750)
	InfoFrame:SetHeight(200)
	InfoFrame:SetBackdrop({
		bgFile = "Interface\\CharacterFrame\\UI-Party-Background", tile = true, tileSize = 32,
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 32,
		insets = {left = 11, right = 12, top = 12, bottom = 11},
	})
	InfoFrame.text = InfoFrame:CreateFontString(InfoFrame:GetName().."Text", "ARTWORK", "GameFontWhite")
	InfoFrame.text:SetPoint("CENTER", 0, 0)
	InfoFrame.text:SetText(UB_INFORMATION_TEXT)
	InfoFrame:RegisterForDrag("LeftButton")
	InfoFrame:SetScript("OnDragStart", function() this:StartMoving() end)
	InfoFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
	
	InfoFrame.header = InfoFrame:CreateTexture("ARTWORK")
	InfoFrame.header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	InfoFrame.header:SetPoint("TOP", 0, 14)
	InfoFrame.header:SetWidth(260)
	InfoFrame.header:SetHeight(64)
	InfoFrame.header.text = InfoFrame:CreateFontString(InfoFrame:GetName().."Title", "ARTWORK", "GameFontNormal")
	InfoFrame.header.text:SetPoint("TOP", 0, 0)
	InfoFrame.header.text:SetText(UB_INFORMATION)
	
	InfoFrame.closeButton = CreateFrame("Button", InfoFrame:GetName().."CloseButton", InfoFrame, "GameMenuButtonTemplate")
	InfoFrame.closeButton:SetWidth(18)
	InfoFrame.closeButton:SetHeight(18)
	InfoFrame.closeButton:SetText("x")
	InfoFrame.closeButton:SetPoint("TOPRIGHT", InfoFrame, "TOPRIGHT", -15, -15)
	InfoFrame.closeButton:RegisterForClicks('LeftButtonUp')
	InfoFrame.closeButton:SetScript("OnClick", function() InfoFrame:Hide() end)
end

function UberBanish:UpdateButtonsState()
	local enable = ConfigFrame.enableButton:GetChecked()
	local button
	for _, v in pairs(buttonTable) do
		button = _G["ConfigFrame"..v[1].."CheckButton"]
		button:SetChecked(UberBanishDB[v[1]])
		if enable then
			button:Enable()
			button:SetNormalTexture(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
			else
			button:Disable()
			button:SetDisabledTexture(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
		end
	end
end