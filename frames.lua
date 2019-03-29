if not UberBanish then return end

local L = UberBanish.L
local MAP_ONOFF = { [false] = "|cffff0000"..L["Off"].."|r", [true] = "|cff00ff00"..L["On"].."|r" }

local config = CreateFrame("Frame", UberBanish:GetName().."ConfigFrame", UIParrent)
table.insert(UISpecialFrames, config:GetName()) -- provides close frame on escape pressed
config:SetClampedToScreen(true)
config:SetToplevel(true)
config:SetFrameStrata("DIALOG")
config:SetMovable(1)
config:EnableMouse(1)
config:Hide()
config:SetPoint("CENTER", 0, 0)
config:SetWidth(500)
config:SetHeight(260)
config:SetBackdrop({
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 32,
	insets = {left = 11, right = 12, top = 12, bottom = 11},
})
config:RegisterForDrag("LeftButton")
config:SetScript("OnDragStart", function() this:StartMoving() end)
config:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

config.header = config:CreateTexture("ARTWORK")
config.header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
config.header:SetPoint("TOP", 0, 14)
config.header:SetWidth(260)
config.header:SetHeight(64)
config.header.text = config:CreateFontString(config:GetName().."Title", "ARTWORK", "GameFontNormal")
config.header.text:SetPoint("TOP", 0, 0)
config.header.text:SetText("UberBanish "..GetAddOnMetadata("UberBanish", "version"))

UberBanish.buttonTable = {
	[1] = {"SpamBanishStart", L["Spam Banish Start."]},
	[2] = {"TwentySecWarning", L["20 Second Warning."]},
	[3] = {"TenSecWarning", L["10 Second Warning."]},
	[4] = {"FiveSecWarning", L["5 Second Warning."]},
	[5] = {"SpamBanishEnd", L["Spam Banish End."]},
	[6] = {"NotifyLocksOnDeath", L["Notify other Warlocks on death."]},
	[7] = {"SpamEarlyBreak", L["Spam the raid if a Banish breaks early."], L["Works ONLY if the player is within 28-30 yards from the unit with the Banish!"]},
	[8] = {"SpamDeath", L["Spam the raid when you die during Banish."], L["up to 30 seconds since the last Banish."]},
	[9] = {"SayWhenSolo", L["Speak aloud when solo."]}
}

config.checkbox = {}
local offsetX, buttonSize, buttonSpacing = 20, 30, 5
for k, v in pairs(UberBanish.buttonTable) do
	local name, text, tooltip = v[1], v[2], v[3]
	local i = k
	config.checkbox[k] = CreateFrame("CheckButton", config:GetName()..name.."CheckButton", config, "UICheckButtonTemplate")
	if k > 5 then offsetX, i = 240, k-5 end
	config.checkbox[k]:SetPoint("TOPLEFT", config, "TOPLEFT", offsetX, -(40 + i * (buttonSize + buttonSpacing)))
	config.checkbox[k].text = config.checkbox[k]:CreateFontString("Status", "LOW", "GameFontNormal")
	config.checkbox[k].text:SetFont(STANDARD_TEXT_FONT, 11)
	config.checkbox[k].text:SetPoint("LEFT", config.checkbox[k], "RIGHT", 0, 0)
	config.checkbox[k].text:SetText(text)
	config.checkbox[k]:RegisterForClicks('LeftButtonUp')
	config.checkbox[k]:SetScript("OnClick", function()
		if this:GetChecked() then
			UberBanishDB[name] = true
			else
			UberBanishDB[name] = false
		end
		UberBanish:print(format(L["%s is now set to %s"], "|cffffff7f"..name.."|r", "|cffffff7f[|r"..MAP_ONOFF[UberBanishDB[name] and true or false].."|cffffff7f]|r"))
	end)
	config.checkbox[k]:SetScript("OnEnter", function()
		if not tooltip then return end
		GameTooltip:SetOwner(this, ANCHOR_BOTTOM)
		GameTooltip:SetText(tooltip)
		GameTooltip:Show()
	end)
	config.checkbox[k]:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

config.enable = CreateFrame("CheckButton", config:GetName().."EnableCheckButton", config, "UICheckButtonTemplate")
config.enable:SetPoint("TOPLEFT", config, "TOPLEFT", 20, -30)
config.enable.text = config.enable:CreateFontString("Status", "LOW", "GameFontNormal")
config.enable.text:SetFont(STANDARD_TEXT_FONT, 11)
config.enable.text:SetPoint("LEFT", config.enable, "RIGHT", 0, 0)
config.enable.text:SetText(L["Enable"])
config.enable:RegisterForClicks('LeftButtonUp')
config.enable:SetScript("OnClick", function()
	local enable = this:GetChecked()
	if enable then
		UberBanishDB.Enabled = true
		UberBanish:OnEnable()
		else
		UberBanishDB.Enabled = false
		UberBanish:OnDisable()
	end
	for k in pairs(UberBanish.buttonTable) do
		if enable then
			config.checkbox[k]:Enable()
			config.checkbox[k].text:SetFontObject("GameFontNormal")
		else
			config.checkbox[k]:Disable()
			config.checkbox[k].text:SetFontObject("GameFontDisable")
		end
	end
	UberBanish:print(format(L["%s is now set to %s"], "|cffffff7f"..L["Standby"].."|r", "|cffffff7f[|r"..MAP_ONOFF[UberBanishDB.Enabled and true or false].."|cffffff7f]|r"))
end)

config.debug = CreateFrame("CheckButton", config:GetName().."DebugCheckButton", config, "UICheckButtonTemplate")
config.debug:SetPoint("TOPLEFT", config, "TOPLEFT", 240, -30)
config.debug.text = config.debug:CreateFontString("Status", "LOW", "GameFontNormal")
config.debug.text:SetFont(STANDARD_TEXT_FONT, 11)
config.debug.text:SetPoint("LEFT", config.debug, "RIGHT", 0, 0)
config.debug.text:SetText(L["Debugging"])
config.debug:SetScript("OnClick", function()
	if this:GetChecked() then
		UberBanishDB.Debugging = true
		else
		UberBanishDB.Debugging = false
	end
	UberBanish:print(format(L["%s is now set to %s"], "|cffffff7f"..L["Debugging"].."|r", "|cffffff7f[|r"..MAP_ONOFF[UberBanishDB.Debugging and true or false].."|cffffff7f]|r"))
end)

config.close = CreateFrame("Button", config:GetName().."CloseButton", config, "GameMenuButtonTemplate")
config.close:SetWidth(100)
config.close:SetHeight(22)
config.close:SetText(CLOSE)
config.close:SetPoint("BOTTOMRIGHT", config, "BOTTOMRIGHT", -15, 15)
config.close:RegisterForClicks('LeftButtonUp')
config.close:SetScript("OnClick", function() config:Hide() end)

config.info = CreateFrame("Button", config:GetName().."InfoButton", config, "GameMenuButtonTemplate")
config.info:SetWidth(100)
config.info:SetHeight(22)
config.info:SetText(L["Info"])
config.info:SetPoint("BOTTOMRIGHT", config.close, "BOTTOMLEFT", -5, 0)
config.info:RegisterForClicks('LeftButtonUp')
config.info:SetScript("OnClick", function() config.info_frame:Show() end)

config.info_frame = CreateFrame("Frame", UberBanish:GetName().."InfoFrame", UIParrent)
config.info_frame:SetClampedToScreen(true)
config.info_frame:SetToplevel(true)
config.info_frame:SetFrameStrata("DIALOG")
config.info_frame:SetMovable(1)
config.info_frame:EnableMouse(1)
config.info_frame:Hide()
config.info_frame:SetPoint("CENTER", 0, 0)
config.info_frame:SetWidth(750)
config.info_frame:SetHeight(200)
config.info_frame:SetBackdrop({
	bgFile = "Interface\\CharacterFrame\\UI-Party-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 32,
	insets = {left = 11, right = 12, top = 12, bottom = 11},
})

config.info_frame.header = config.info_frame:CreateTexture("ARTWORK")
config.info_frame.header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
config.info_frame.header:SetPoint("TOP", 0, 14)
config.info_frame.header:SetWidth(260)
config.info_frame.header:SetHeight(64)
config.info_frame.header.text = config.info_frame:CreateFontString(config.info_frame:GetName().."Title", "ARTWORK", "GameFontNormal")
config.info_frame.header.text:SetPoint("TOP", 0, 0)
config.info_frame.header.text:SetText(L["Information"])

config.info_frame.close = CreateFrame("Button", config.info_frame:GetName().."CloseButton", config.info_frame, "UIPanelCloseButton")
config.info_frame.close:SetPoint("TOPRIGHT", config.info_frame, "TOPRIGHT", -5, -5)
config.info_frame.close:RegisterForClicks('LeftButtonUp')
config.info_frame.close:SetScript("OnClick", function() config.info_frame:Hide() end)

config.info_frame.text = config.info_frame:CreateFontString(config.info_frame:GetName().."Text", "ARTWORK", "GameFontWhite")
config.info_frame.text:SetPoint("CENTER", 0, 0)
config.info_frame.text:SetText(L["info_text"])
config.info_frame:RegisterForDrag("LeftButton")
config.info_frame:SetScript("OnDragStart", function() this:StartMoving() end)
config.info_frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

local BanishButton = CreateFrame("CheckButton", UberBanish:GetName().."BanishButton", UIParrent)
BanishButton:SetFrameStrata("HIGH")
BanishButton:SetWidth(50)
BanishButton:SetHeight(50)
BanishButton:SetPoint(unpack(UberBanishDB.BanishButtonPosition))
BanishButton:SetMovable(1)
BanishButton:EnableMouse(1)
BanishButton:SetNormalTexture("Interface\\Icons\\Spell_Shadow_Cripple")
BanishButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
BanishButton:RegisterForDrag("LeftButton")
BanishButton:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
BanishButton.cd = CreateFrame("Model", BanishButton:GetName().."Cooldown", BanishButton, "CooldownFrameTemplate")
BanishButton.cd:SetAllPoints(BanishButton)
BanishButton.cd:SetScale(BanishButton:GetWidth()/36)
BanishButton.cd.text = BanishButton.cd:CreateFontString(BanishButton.cd:GetName().."Text", "OVERLAY")
BanishButton.cd.text:SetAllPoints(BanishButton)
BanishButton.cd.text:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
BanishButton:SetScript("OnDragStart", function()
	if IsShiftKeyDown() then
		this:StartMoving()
	end
end)
BanishButton:SetScript("OnDragStop", function()
	this:StopMovingOrSizing()
	local point, _, _, xofs, yofs = this:GetPoint()
	UberBanishDB.BanishButtonPosition = {point, xofs, yofs}
end)
BanishButton:SetScript("OnEnter", function()
	GameTooltip:SetOwner(this, ANCHOR_BOTTOMLEFT)
	GameTooltip:AddDoubleLine(L["Left-Click"], L["Cast Banish(Rank 2)"])
	GameTooltip:AddDoubleLine(L["Right-Click"], L["Cast Banish(Rank 1)"])
	GameTooltip:AddDoubleLine(L["Shift-Drag"], L["Move button"])
	GameTooltip:Show()
end)
BanishButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
BanishButton:SetScript("OnClick", function()
	local spell
	if arg1 == "LeftButton" then
		spell = L["Banish"]
	else
		spell = L["Banish(Rank 1)"]
	end
	CastSpellByName(spell)
end)

local BFMFrame = CreateFrame("Frame", UberBanish:GetName().."BFMFrame", UIParrent)
BFMFrame:Hide()
BFMFrame:SetWidth(360)
BFMFrame:SetHeight(50)
BFMFrame:SetPoint("CENTER", 0, 150)
BFMFrame:SetBackdrop({bgFile = "Interface\\TutorialFrame\\TutorialFrameBackground"})
BFMFrame.text = BFMFrame:CreateFontString(UberBanish:GetName().."BFMFrameText", "BACKGROUND", "GameFontNormalLarge")
BFMFrame.text:SetAllPoints(BFMFrame)
BFMFrame:SetScript("OnUpdate", function()
	if this:GetAlpha() == 0 then this:Hide() end
end)

local MinimapButton = CreateFrame('Button', UberBanish:GetName().."MinimapButton", Minimap)
MinimapButton:SetClampedToScreen(true)
MinimapButton:SetFrameStrata('LOW')
MinimapButton:EnableMouse(true)
MinimapButton:SetMovable(true)
MinimapButton:SetWidth(31)
MinimapButton:SetHeight(31)
MinimapButton:SetHighlightTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight')
MinimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)

MinimapButton.icon = MinimapButton:CreateTexture(nil, 'BACKGROUND')
MinimapButton.icon:SetWidth(20)
MinimapButton.icon:SetHeight(20)
MinimapButton.icon:SetTexture('Interface\\Icons\\Spell_Shadow_Cripple')
MinimapButton.icon:SetTexCoord(.05, .95, .05, .95)
MinimapButton.icon:SetPoint('CENTER', 1, 1)

MinimapButton.overlay = MinimapButton:CreateTexture(nil, 'OVERLAY')
MinimapButton.overlay:SetWidth(53)
MinimapButton.overlay:SetHeight(53)
MinimapButton.overlay:SetTexture('Interface\\Minimap\\MiniMap-TrackingBorder')
MinimapButton.overlay:SetPoint('TOPLEFT', 0,0)

MinimapButton:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
MinimapButton:RegisterForDrag('LeftButton')
MinimapButton:SetScript("OnDragStart", function() this:StartMoving() end)
MinimapButton:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
MinimapButton:SetScript("OnEnter", function()
	GameTooltip:SetOwner(this, ANCHOR_BOTTOMLEFT)
	GameTooltip:SetText("UberBanish "..GetAddOnMetadata("UberBanish", "version"))
	GameTooltip:AddDoubleLine(L["Left-Click"], L["Toggle BanishFrame"], 1, 1, 1, 1, 1, 1)
	GameTooltip:AddDoubleLine(L["Right-Click"], L["Open Configuration"], 1, 1, 1, 1, 1, 1)
	GameTooltip:Show()
end)
MinimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
MinimapButton:SetScript("OnClick", function()
	if UberBanishDB.Enabled then
		if arg1 == "RightButton" then
			if config:IsShown() then config:Hide() else config:Show() end
		else
			if BanishButton:IsShown() then
				BanishButton:Hide()
				UberBanish:print(L["BanishBitton is hidden."])
			else
				BanishButton:Show()
				UberBanish:print(L["BanishBitton is shown."])
			end
		end
	else
		if config:IsShown() then config:Hide() else config:Show() end
	end
end)
