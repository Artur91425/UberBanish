--[[
	
	---===:::{{{ A U L E ' S    U B E R B A N I S H }}}:::===---
	
	Author		: Lichery
	Version		: 2.1
	Release Date	: Mar 29, 2019
	
	Based on original version 1.2b

	OVERVIEW:
	---------
	UberBanish is a Banish enhancement with the following main features:
	
	- Informs the party/raid of how much time is left in your Banishes.
	- If a Warlock's Banish breaks early, the group is informed and the
  Warlock gets a Big Fat Message and a sound indicating the break.
  Clicking on this message will rebanish the current target.
	- Informs the other warlocks in the party/raid if you die while on
  Banish duty (that is to say within 1 minute of casting a Banish).
	- If a warlock dies while on Banish duty, all other Warlocks in the 
  group will be informed with a Big Fat Message above their toon.
  Clicking on this message will select the dead Warlock's target.
	
	UberBanish primarily responds to spellcasting events and manages a 
	single, static timer which is reset on each new Banish.
	
	
	DEVELOPERS:
	-----------
	- BFM = Big Fat Message.
	- A "broadcast message" is a whisper sent to other Warlocks that 
	will result in a BFM being displayed to them.	
	
	--[[ old informations
	Author		: joeh@foldingrain.com
	Version		: 1.2b
	Release Date	: Oct 1, 2006
	Main			: Aule [Warlock]
	Server		: Dunemaul
	Guild		: NoX (Best Guild Ever)
	Testers		: Tiamat, Janadine, Rhyana, Ampz, Kaed, Houseofm
	
	
	Copyright (c)2006.  All Rights Reserved.
	All players of World of Warcraft have permission to copy, reproduce, 
	distribute and modify this computer code in any way they wish with no 
	permission from the author or any corporation or organization.  The
	author respectfully requests he be credited for the original inception.
	
	CREDITS:
	--------
	Thanks to Scrum and Justin Milligan for their work on CountDoom,
	which taught me just about everything I needed to know about
	dealing with curses in an AddOn.
	
	Thanks also to Andreas Broecking for the SheepWatch Mage mod which
	gave me some great ideas for tracking banish breaks when the target
	is not selected.
	--]]
	
--]]

if not UberBanish then return end

local _G = getfenv()
local L = UberBanish.L

UberBanish:RegisterEvent("ADDON_LOADED")
UberBanish:RegisterEvent("VARIABLES_LOADED")
local config = _G[UberBanish:GetName().."ConfigFrame"]
local BanishButton = _G[UberBanish:GetName().."BanishButton"]
local BFMFrame = _G[UberBanish:GetName().."BFMFrame"]

local last_update = GetTime()
local PlayerName = UnitName("player")
local BANISH_DURATION = {20, 30}
local gTimeSinceLastBanish = 0 -- If the warlock dies, and this timer is less than 30, other warlocks in the raid will be notified.
local gBanishTimerScheduled
local gAlreadyBanishFlag -- Indicates there is already a banish active when another begins casting.
local gBanishPendingFlag -- Indicates a banish was started but has not yet completed.
local BadBanishCastFlag
local gWarlockList -- List of the number of warlocks in the party/raid.
local gCurrentBanishTarget -- The name of the mob that is currently banished.
local gBanishStartTime -- The simulation time at which a banish was started (successfully cast).
local gBanishTimer -- Timer that starts up after a banish is successfully cast.
local gCurrentBanishRank
local gAnnounceChannel -- The current channel to announce messages on.  Currently one of "SAY", "PARTY", or "RAID".

function UberBanish:OnInitialize()
	if UberBanishDB.Enabled then
		self:OnEnable()
	else
		self:print(format(L["%s is currently set to %s"], "|cffffff7f"..L["Standby"].."|r", "|cffffff7f[|r|cffff0000"..L["Off"].."|r|cffffff7f]|r"))
		self:OnDisable()
	end
end

function UberBanish:OnEnable()
	self:RegisterEvent("SPELLCAST_STOP") -- inaccurate banish detection (if the event CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE did not work)
	self:RegisterEvent("SPELLCAST_INTERRUPTED")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE") -- accurate banish detection
	self:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE") -- if the banish spell was unsuccessfully cast
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER") -- detection of the end of banish or early broke
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	
	self:RegisterEvent("PLAYER_DEAD")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")
	self:RegisterEvent("RAID_ROSTER_UPDATE")
	self:RegisterEvent("CHAT_MSG_WHISPER")
	
	self:UpdateAnnounceChannel()
	self:UpdateWarlockList()
	BanishButton:Show()
end

function UberBanish:OnDisable()
	BanishButton:Hide()
	self:UnregisterAllEvents()
	if gAlreadyBanishFlag then self:KillTimer() end
end

UberBanish:SetScript("OnEvent", function()
	this:debug("|cff32CD32Got An Event:|r "..event)
	
	if event == "ADDON_LOADED" and arg1 == this:GetName() then
		this:OnInitialize()
	elseif event == "VARIABLES_LOADED" then
		config.enable:SetChecked(UberBanishDB.Enabled)
		config.debug:SetChecked(UberBanishDB.Debugging)
		for k, v in pairs(UberBanish.buttonTable) do
			config.checkbox[k]:SetChecked(UberBanishDB[v[1]])
		end
	elseif event == "SPELLCAST_STOP" then
		if not gBanishPendingFlag then return end
		
		gBanishTimerScheduled = GetTime()
	elseif event == "SPELLCAST_INTERRUPTED" then
		if not gBanishPendingFlag then return end
		
		if gAlreadyBanishFlag then
			this:debug("There is another active Banish up...not killing timer.")
		else
			BadBanishCastFlag = true
		end
		gBanishTimerScheduled = nil
	elseif event == "CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE" then
		if not (this:CheckBanish(arg1) and gBanishPendingFlag)then return end
		
		if gAlreadyBanishFlag then
			this:debug("Existing timer was deleted!")
			gBanishTimerScheduled = nil
			this:KillTimer()
		end
		this:debug("BANISH WAS SUCCESSFULLY CAST!")
		this:StartTimer()
	elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
		if not this:CheckBanish(arg1) then return end
		
		if gAlreadyBanishFlag then
			this:debug("There is another active Banish up...not killing timer.")
		else
			BadBanishCastFlag = true
		end
	elseif event == "CHAT_MSG_SPELL_AURA_GONE_OTHER" then
		if not (this:CheckBanish(arg1) and gBanishTimer) then return end
		
		if gBanishTimer > 1 then -- if the timer did not end, then the banish was broken, report it!
			this:debug("Banish broke early!")
			PlaySound("igQuestLogAbandonQuest")
			this:BFMPrint(L["MOB BROKE YOUR BANISH!!!"])
			if UberBanishDB.SpamEarlyBreak then
				this:Report("WARNING: My banish broke early!")
			end
		end
		this:KillTimer()
	elseif event == "PLAYER_REGEN_ENABLED" then
		if gAlreadyBanishFlag then this:KillTimer() end
	elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
		this:UpdateWarlockList()
		this:UpdateAnnounceChannel()
	elseif event == "PLAYER_DEAD" then
		if not UberBanishDB.NotifyLocksOnDeath then return end
		local time = floor(GetTime() - gTimeSinceLastBanish)
		if time > 30 then return end
		
		this:debug("Player dead and time since last banish: "..time.." seconds.")
		if gAlreadyBanishFlag then this:KillTimer() end
		this:SpamWarlocks(format(L["WARNING: %s has died while banishing!"], PlayerName))
		if UberBanishDB.SpamDeath then
			this:Report(format(L["WARNING: %s has died while banishing!"], PlayerName))
		end
	elseif event == "CHAT_MSG_WHISPER" then
		local _, _, content = string.find(arg1, '<'..this:GetName()..'BC> (.*)')
		if not content then return end
		
		PlaySound("igQuestLogAbandonQuest")
		this:BFMPrint(content)
	end
end)

UberBanish:SetScript("OnUpdate", function()
	if not (UberBanishDB.Enabled and UnitAffectingCombat("player")) or GetTime() - last_update < .1 then return end
	last_update = GetTime()
	if BadBanishCastFlag then return end
	
	if not gAlreadyBanishFlag and gBanishTimerScheduled then
		local timeSinceSchedule = last_update - gBanishTimerScheduled
		if timeSinceSchedule < 1 then return end -- Give half a second for the failure event to occur
		this:debug("BANISH WAS SUCCESSFULLY CAST!")
		this:StartTimer("inaccurate", timeSinceSchedule)
	end
	if not gAlreadyBanishFlag then return end
	
	local remaining = gBanishDuration - (last_update - gBanishStartTime)
	BanishButton.cd.text:SetText(this:round(remaining, 1))
	
	local intSnap
	if remaining < gBanishTimer then intSnap = true end
	gBanishTimer = floor(remaining)
	
	if intSnap then -- Report timer only at the integers
		this:debug("Banish Timer: "..gBanishTimer)
		if gBanishTimer == 5 then
			UIFrameFlash(BanishButton, .8, .8, 5, 1)
		end
		if (gBanishTimer == 20 and UberBanishDB.TwentySecWarning)
			or (gBanishTimer == 10 and UberBanishDB.TenSecWarning)
			or (gBanishTimer == 5 and UberBanishDB.FiveSecWarning) then
			this:Report(format(L["Banish breaks in %s seconds..."], gBanishTimer))
		elseif gBanishTimer == 1 and UberBanishDB.SpamBanishEnd then
			this:Report(L["My Banish expires now!"])
		end
	end
	if remaining < 0 and gAlreadyBanishFlag then -- If the event CHAT_MSG_SPELL_AURA_GONE_OTHER did not work 
		this:KillTimer()
	end
end)

function UberBanish:CheckBanish(msg)
	return string.find(msg, L["Banish"]) and true
end

function UberBanish:UpdateCastSpellInfo(spell, rank)
	local spellIsBanish = self:CheckBanish(arg1)
	if not spellIsBanish then
		gBanishPendingFlag = nil
		return
	end
	
	if type(rank) ~= "number" then rank = tonumber(rank) end
	if not rank then rank = 2 end
	self:debug(format("Player has started a %s(Rank %s)!", spellIsBanish, rank))
	gCurrentBanishTarget = UnitName("target")
	gCurrentBanishRank = rank
	gBanishPendingFlag = true
	BadBanishCastFlag = nil
	gBanishTimerScheduled = nil
end

function UberBanish:StartTimer(status, delay)
	if status == "inaccurate" then
		self:debug("Starting |cffFF0000INACCURATE|r timer...")
		gBanishDuration = floor(BANISH_DURATION[gCurrentBanishRank] - delay)
		SetButtonPulse(BanishButton, gBanishDuration, .5)
	else
		self:debug("Starting timer...")
		gBanishDuration = BANISH_DURATION[gCurrentBanishRank]
	end
	if UberBanishDB.SpamBanishStart then
		self:Report(format(L["%s has banished %s."], PlayerName, gCurrentBanishTarget))
	end
	gBanishTimerScheduled = nil
	gAlreadyBanishFlag = true
	gBanishPendingFlag = nil
	gBanishTimer = gBanishDuration
	gBanishStartTime = GetTime()
	gTimeSinceLastBanish = gBanishStartTime
	CooldownFrame_SetTimer(BanishButton.cd, gBanishStartTime, gBanishDuration, 1)
end

function UberBanish:KillTimer()
	self:debug("Killing the timer...")
	gAlreadyBanishFlag = nil
	gBanishStartTime = nil
	gBanishDuration = nil
	gBanishTimer = nil
	CooldownFrame_SetTimer(BanishButton.cd, 0, 0, 0)
	UIFrameFlashStop(BanishButton)
	BanishButton:Show() -- needed because UIFrameFlashStop hides frame
	ButtonPulse_StopPulse(BanishButton)
end

function UberBanish:BFMPrint(msg)
	BFMFrame.text:SetText(msg)
	UIFrameFadeOut(BFMFrame, 4)
end

function UberBanish:Report(msg)
	if gAnnounceChannel == "SAY" and not UberBanishDB.SayWhenSolo then return end
	SendChatMessage(msg, gAnnounceChannel)
end

function UberBanish:UpdateAnnounceChannel()
	if UnitInRaid("player") then
		gAnnounceChannel = "RAID"
	elseif UnitExists("party1") then -- UnitInParty("player") can NOT be used, see "Details": http://vanilla-wow.wikia.com/wiki/API_UnitInParty
		gAnnounceChannel = "PARTY"
	else
		gAnnounceChannel = "SAY"
	end
	self:debug("The new channel is: "..gAnnounceChannel)
end

function UberBanish:UpdateWarlockList()
	self:debug("UpdateWarlock: Refreshing Warlock List")
	gWarlockList = {}
	
	if not UnitExists("party1") then
		table.insert(gWarlockList, PlayerName) -- ТОЛЬКО ДЛЯ ТЕСТОВ, ПОТОМ УДАЛИТЬ!
		return self:debug("Not in a group! Bailing...")	
	end
	
	local name, class
	if UnitInRaid("player") then
		for i = 1, GetNumRaidMembers() do
			name, _, _, _, _, class = GetRaidRosterInfo(i)
			if class and class == "WARLOCK" and name ~= PlayerName then
				self:debug("UpdateWarlock: "..name.." is a Warlock!")
				table.insert(gWarlockList, name)
			end
		end
	else
		for i = 1, GetNumPartyMembers() do
			name = UnitName("party"..i)
			_, class = UnitClass("party"..i)
			if class == "WARLOCK" then
				self:debug("UpdateWarlock: "..name.." is a Warlock!")
				table.insert(gWarlockList, name)
			end
		end
	end
end

-- Sends a message to all the other warlocks in the raid.
function UberBanish:SpamWarlocks(msg)
	for _, name in pairs(gWarlockList) do
		SendChatMessage("<"..self:GetName().."BC> "..msg, "WHISPER", nil, name)
	end
end

function UberBanish:round(num, idp)
	return tonumber(format("%."..(idp or 0).."f", num))
end

------------------
-- Hook functions
------------------
local BlizzardCastSpellByName = CastSpellByName
function CastSpellByName(spell)
	BlizzardCastSpellByName(spell)
	local _, _, spellRank = string.find(spell, "(%d+)")
	UberBanish:debug("|cff87CEEBCastSpellByName|r: "..spell)
	UberBanish:UpdateCastSpellInfo(spell, spellRank)
end

local BlizzardCastSpell = CastSpell
function CastSpell(spellId, bookType)
	BlizzardCastSpell(spellId, bookType)	
	local spellName, spellRank = GetSpellName(spellId, bookType)
	_, _, spellRank = string.find(spellRank, "(%d+)")
	if spellRank then
		UberBanish:debug(format("|cff87CEEBCastSpell|r: %s; Rank: %s", spellName, spellRank))
	else
		UberBanish:debug(format("|cff87CEEBCastSpell|r: %s", spellName))	
	end
	UberBanish:UpdateCastSpellInfo(spellName, spellRank)
end

local UberBanishSpellTooltip = CreateFrame("GameTooltip", "UberBanishSpellTooltip", UIParent, "GameTooltipTemplate")
UberBanishSpellTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
local BlizzardUseAction = UseAction
function UseAction(slot, checkCursor, onSelf)
	BlizzardUseAction(slot, checkCursor, onSelf)
	if not (UberBanishDB.Enabled and HasAction(slot)) then return end
	
	UberBanishSpellTooltip:Hide()
	UberBanishSpellTooltip:SetAction(slot)
	
	local spellName = UberBanishSpellTooltipTextLeft1:GetText()
	if not spellName then return end -- macros don't have spellName
	local spellRank = UberBanishSpellTooltipTextRight1:GetText()
	if spellRank then
		_, _, spellRank = string.find(spellRank, "(%d+)")
	end
	UberBanish:debug(format("|cff87CEEBUseAction|r: slotID: %s; spellName: %s; spellRank: %s", slot, spellName, tostring(spellRank)))
	UberBanish:UpdateCastSpellInfo(spellName, spellRank)
end
------------------
