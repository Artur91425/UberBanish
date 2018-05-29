--[[
	
	---===:::{{{ A U L E ' S    U B E R B A N I S H }}}:::===---
	
	
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
	
	CREDITS:
	--------
	Thanks to Scrum and Justin Milligan for their work on CountDoom,
	which taught me just about everything I needed to know about
	dealing with curses in an AddOn.
	
	Thanks also to Andreas Broecking for the SheepWatch Mage mod which
	gave me some great ideas for tracking banish breaks when the target
	is not selected.
--]]

_, UB_playerClass = UnitClass("player")
if UB_playerClass ~= "WARLOCK" then return end

UB_TITLE_VERSION = "UberBanish "..GetAddOnMetadata("UberBanish", "version")
UberBanishDB = {
	Enabled = true,
	Debugging = false,
	SpamBanishStart = true,
	SpamBanishEnd = true,
	TwentySecWarning = true,
	TenSecWarning = true,
	FiveSecWarning = true,
	SpamEarlyBreak = true,
	SpamDeath = true,
	SayWhenSolo = false,
	NotifyLocksOnDeath = true,
}
local ColorTable = {
	["red"] = "FF0000",
}
local flags = {
	TargetDirty = false, 		-- Indicates whether the player switched targets after beginning a banish.
	SuccessfullyBanishCast = false,
	BanishTimer = false, 				-- Indicates there is a banish timer up.
	AlreadyBanish = false, 	-- Indicates there is already a banish active when another begins casting.
	BanishPending = false 	-- Indicates a banish was started but has not yet completed.
}

local last_update = GetTime()
local PlayerName = UnitName("player")
local gWarlockList -- List of the number of warlocks in the party/raid.

--[[ Timer used to determine if this lock is on "banish duty".  If a lock dies
	and this timer sits at under 60, this lock is considered on duty and the
other locks in the raid are notified.]]
local gTimeSinceLastBanish = 0
--[[ Counts the time since a Banish spellcast stopped. The reason for a
	stop is unknown at the time it is received, and may be followed by
	a failure event.  We have to wait until we check for that event
	before we can declare the spell cast successful.
A value of -1 means no banish is scheduled.]]
local gBanishTimerScheduled = -1
local gCurrentBanishTarget -- The name of the mob that is currently banished.
local gBanishStartTime -- The simulation time at which a banish was started (successfully cast).
local gBanishTimer -- Timer that starts up after a banish is successfully cast.
local gAnnounceChannel -- The current channel to announce messages on.  Currently one of "SAY", "PARTY", or "RAID".
local gTargetHasBanishDebuff = false		-- Indicates that the current mob has the banish debuff to the best of our knowledge.
local gPreviousBanishRank = -1 -- Indicates which rank of Banish is currently being cast.
local gCurrentBanishRank = 2
local gWarlockOnDeck -- The warlock who is on deck for some kind of action (like they have died and their target will be selected) when a BFM is clicked.
local gCommandOnDeck -- The command that is on deck when a BFM is clicked.
local COMMAND_BANISH = "COMMAND_BANISH"
local COMMAND_TARGET = "COMMAND_TARGET"


UberBanish = CreateFrame("Frame", "UberBanish")
UberBanish:RegisterEvent("ADDON_LOADED")

function UberBanish:OnInitialize()
	self:LoadOptions()
	self:LoadBFMFrame()
	self:LoadBanishFrame()
	self:ParseAllPatterns()
	self:RegisterChatCommands()
	
	self:Print(UB_TITLE_VERSION.." loaded.")
	self:Print("Type /ub for help.")
	
	if UberBanishDB.Enabled then
		self:OnEnable()
		else
		self:Print("Addon DISABLED.")
		self:OnDisable()
	end
end

function UberBanish:OnEnable()
	self:RegisterEvent("SPELLCAST_STOP")
	self:RegisterEvent("SPELLCAST_FAILED")
	self:RegisterEvent("SPELLCAST_INTERRUPTED")
	self:RegisterEvent("CHAT_MSG_SPELL_FAILED_LOCALPLAYER")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE")
	self:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	
	self:RegisterEvent("PLAYER_DEAD")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")
	self:RegisterEvent("RAID_ROSTER_UPDATE")
	self:RegisterEvent("CHAT_MSG_WHISPER")
	
	self:UpdateAnnounceChannel()
	self:UpdateWarlockList()
	getglobal(self:GetName().."BanishButton"):Show()
end

function UberBanish:OnDisable()
	getglobal(self:GetName().."BanishButton"):Hide()
	self:UnregisterAllEvents()
	self:KillTimer()
end

UberBanish:SetScript("OnEvent", function()
	this:Debug("|cff32CD32Got An Event:|r "..event)
	local spellIsBanish
	
	if event == "ADDON_LOADED" and arg1 == this:GetName() then
		this:OnInitialize()
		elseif event == "SPELLCAST_FAILED" or event == "SPELLCAST_INTERRUPTED" or event == "CHAT_MSG_SPELL_FAILED_LOCALPLAYER" then
		this:Debug("Pending: "..tostring(flags.BanishPending).."  already: "..tostring(flags.AlreadyBanish).."  banish: "..tostring(flags.BanishTimer))
		local _, _, spellIsBanish = string.find(arg1, "("..UB_BANISH..")")
		-- If a pending banish failed AND there is not another banish up, then kill the timer.
		if spellIsBanish then
			flags.SuccessfullyBanishCast = false
			if flags.BanishPending then
				this:KillTimer()
				gBanishTimerScheduled = -1
			end
		end
		elseif event == "CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE" then
		--	this:SpamWarlocks("WARLOCKS: "..format(UB_HAS_DIED_WHILE_BANISHING, PlayerName))
		_, _, spellIsBanish = string.find(arg1, "("..UB_BANISH..")")
		if spellIsBanish then
			flags.SuccessfullyBanishCast = true
		end
		elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
		_, _, spellIsBanish = string.find(arg1, "("..UB_BANISH..")")
		if not spellIsBanish then return end
		
		if flags.AlreadyBanish then
			this:Debug("There is another active Banish up...not killing timer.")
			else
			this:Debug("Banish casting was unsuccessful!", red)
			gBanishTimerScheduled = -1
			this:KillTimer()
		end
		elseif event == "SPELLCAST_STOP" then
		-- Banish may have been cast properly, or may have been interrupted.
		-- Start up the timers anyway, but don't start reporting until we
		-- give the SPELLCAST_INTERRUPTED event a chance to come in.
		if flags.BanishPending then
			local existingBanishThreshold = 28
			if gPreviousBanishRank == 1 then
				existingBanishThreshold = 18
			end
			-- If there's already an active Banish and the target hasn't switched, 
			-- we know this one will fail due to immunity.  In this case we don't want to
			-- clobber the exiting timer because that Banish will still
			-- play out.
			if flags.BanishTimer and not flags.TargetDirty and gTimeSinceLastBanish <= existingBanishThreshold then
				this:Debug("There is already another Banish up.  Flagging...")
				flags.AlreadyBanish = true
				else
				flags.AlreadyBanish = false
				-- This is possibly a new, successful banish.  If an interrupt or resist or 
				-- failure does not come next, then it is definitely a successful banish.
				-- The timer start actually occurs in OnUpdate().
				gBanishTimerScheduled = GetTime()
			end
		end	
		elseif event == "PLAYER_TARGET_CHANGED" then
		-- If we switch to a target that is NOT Banished, then targeting is
		-- considered "dirty".  There may still be a valid banish up but we 
		-- cannot make guesses about it's status, so we continue counting it
		-- down.  If we switch to a target that IS banished, we consider that
		-- a re-acquire and the dirty flag is cleared.  This will result in 
		-- a problem if the warlock selects another warlock's banished mob.
		local currentTarget = UnitName("target")
		if this:IsTargetBanished() and gCurrentBanishTarget == currentTarget then
			this:Debug("Banish target reacquired!")
			flags.TargetDirty = false
			else
			flags.TargetDirty = true
		end	
		elseif event == "CHAT_MSG_SPELL_AURA_GONE_OTHER" then
		this:Debug("Banish may have broken early.  Checking...")
		local banishBroke = false
		
		-- If there is a banish pending we want to skip this event.
		--[[
			if flags.BanishPending then
			this:Debug("There is a banish pending...skipping break check.")
			return
			end
		--]]
		
		-- If there is no banish up, we want to skip this event.
		if not flags.BanishTimer then
			return this:Debug("There is no banish...skipping break check.")
		end
		
		-- If we are within the first 2 seconds of a Banish, the debuff might
		-- not be posted yet due to lag, so skip this check.
		local breakThreshold = 28
		if gCurrentBanishRank == 1 then
			breakThreshold = 18
		end
		if gBanishTimer >= breakThreshold then
			return this:Debug("We are in the first 2 seconds of a banish...skipping break check.")
		end
		
		-- First try a hard check.  If our target hasn't changed, then it's
		-- simply a matter of checking the current target for the Banish debuff.
		if not flags.TargetDirty then
			this:Debug("Hard break check...")
			banishBroke = this:CheckBanishBroke()
			
			-- Otherwise try a soft check.  If our target has changed, we'll analyze
			-- the break message and see if the spell Banish faded off a mob with
			-- the same name as ours.
			else
			this:Debug("Soft break check...")
			-- arg1 "Banish fades from Felguard Elite "
			local _, _, spellName, mobName = string.find(arg1, UB_SPELLEVADEDSELFOTHER)
			if spellName == UB_BANISH and mobName == gCurrentBanishTarget then
				banishBroke = true
			end
		end
		
		-- If the banish was broken, report it!
		if banishBroke then
			this:KillTimer()
			this:Debug("Banish broke early!!")
			gWarlockOnDeck = nil				-- Select THIS Warlock
			gCommandOnDeck = COMMAND_BANISH	-- Banish THIS Warlock's target.
			this:BFMPrint(UB_MOB_BROKE_YOUR_BANISH)
			PlaySound("igQuestLogAbandonQuest")
			if UberBanishDB.SpamEarlyBreak then
				this:Say("WARNING!! My banish broke early!!")
			end
		end
		elseif event == "PLAYER_REGEN_ENABLED" then
		if flags.BanishTimer then
			this:KillTimer()
		end
		elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
		this:UpdateWarlockList()
		this:UpdateAnnounceChannel()
		elseif event == "PLAYER_DEAD" then
		this:Debug("Player dead and time since last banish: "..gTimeSinceLastBanish)
		if gTimeSinceLastBanish > 60 and not UberBanishDB.NotifyLocksOnDeath then return end
		
		this:KillTimer()
		this:SpamWarlocks("WARLOCKS: "..format(UB_HAS_DIED_WHILE_BANISHING, PlayerName))
		if UberBanishDB.SpamDeath then
			this:Say(format(UB_HAS_DIED_WHILE_BANISHING, PlayerName))
		end
		elseif event == "CHAT_MSG_WHISPER" then
		local _, _, content = string.find(arg1, '<'..this:GetName()..'BC> (.*)')
		if not content then return end
		
		PlaySound("igQuestLogAbandonQuest")
		this:ExtractPlayerFromContent(content)
		this:BFMPrint(content)
	end
end)

local function round(num, idp)
	return tonumber(format("%."..(idp or 0).."f", num))
end

UberBanish:SetScript("OnUpdate", function()
	gTimeSinceLastBanish = gTimeSinceLastBanish + arg1
	if not UberBanishDB.Enabled or GetTime() - last_update < .1 then return end
	last_update = GetTime()
	
	-- Do we have a successful Banish?
	if gBanishTimerScheduled >= 0 then	
		-- Yes!!   A Banish was cast and landed successfully.
		local timeSinceSchedule = last_update - gBanishTimerScheduled
		-- Give half a second for the failure event to occur
		if timeSinceSchedule > 1 then 
			gTargetHasBanishDebuff = this:IsTargetBanished()
			if gTargetHasBanishDebuff then
				this:Debug("BANISH WAS SUCCESSFULLY CAST!!!")
				gBanishTimerScheduled = -1
				this:KillTimer()
				this:StartTimer()
			end
			else
			--this:Debug("There is a banish scheduled, but waiting for possible failure...")
		end
	end
	
	if not flags.BanishTimer then return end
	
  local remaining = round(this:GetBanishDuration() - (last_update - gBanishStartTime), 1)
	
	local rawDelta = last_update - gBanishStartTime
	local duration = this:GetBanishDuration()
	local tmp = duration - floor(rawDelta)
	local intSnap
	-- Report timer only at the integers
	if tmp < gBanishTimer then intSnap = true end
	gBanishTimer = tmp
	
	getglobal(this:GetName().."BanishButtonCooldownText"):SetText(remaining)
	
	-- First check to see if the banish is still up.  We can't always rely on
	-- the CHAT_MSG_SPELL_AURA_GONE_OTHER event being thrown.
	-- Also, if the player has switched targets during the banish, we don't
	-- want to make this check.
	-- We check only after 2 seconds have passed to allow lag time for the 
	-- Banish to appear on the MOB.
	if rawDelta >= 2 and not flags.TargetDirty then
		local banishBroke = this:CheckBanishBroke()
		if banishBroke and intSnap then
			this:Debug("this:UpdateBanishTimer decided that Banish broke early!!")
			gWarlockOnDeck = nil				-- Select THIS Warlock
			gCommandOnDeck = COMMAND_BANISH	-- Banish THIS Warlock's target.
			this:KillTimer()
			this:BFMPrint(UB_MOB_BROKE_YOUR_BANISH)
			PlaySound("igQuestLogAbandonQuest")
			if UberBanishDB.SpamEarlyBreak then
				this:Say("WARNING!! My banish broke early!!")
			end
		end
	end
	
	-- We wait 2 seconds to report in case the spell is interrupted or 
	-- resisted because we need to allow time for the other events to come in.
	local reportThreshold = 27
	if gCurrentBanishRank == 1 then
		reportThreshold = 17
	end
	if gBanishTimer == reportThreshold and intSnap then
		gTargetHasBanishDebuff = this:IsTargetBanished()
		if gTargetHasBanishDebuff and UberBanishDB.SpamBanishStart then
			this:Say(format(UB_HAS_BANISHED, PlayerName, gCurrentBanishTarget))
		end
	end
	
	if gBanishTimer < 0 then this:KillTimer() return end
	-- Only report updates to the group at user designated intervals.
	if intSnap then
		this:Debug("Banish Timer: "..tmp)
		if (gBanishTimer == 20 and UberBanishDB.TwentySecWarning)
			or (gBanishTimer == 10 and UberBanishDB.TenSecWarning)
			or (gBanishTimer == 5 and UberBanishDB.FiveSecWarning) then
			this:Say(format(UB_BANISH_BREAKS_IN, gBanishTimer))
			elseif gBanishTimer == 1 and UberBanishDB.SpamBanishEnd then
			this:Say(UB_MY_BANISH_EXPIRES)
		end
	end
end)

------------------
-- Hook functions
------------------
BlizzardCastSpellByName = CastSpellByName
function CastSpellByName(spell)
	BlizzardCastSpellByName(spell)
	local _, _, spellRank = string.find(spell, "(%d+)")
	UberBanish:Debug("CastSpellByName: "..spell)
	UberBanish:UpdateCastSpellInfo(spell, spellRank)
end

BlizzardCastSpell = CastSpell
function CastSpell(spellId, bookType)
	BlizzardCastSpell(spellId, bookType)	
	local spellName, spellRank = GetSpellName(spellId, bookType)
	_, _, spellRank = string.find(spellRank, "(%d+)")
	UberBanish:Debug(format("CastSpell: %s; Rank: %s", spellName, spellRank))
	UberBanish:UpdateCastSpellInfo(spellName, spellRank)
end

local UberBanishSpellTooltip = CreateFrame("GameTooltip", "UberBanishSpellTooltip", UIParent, "GameTooltipTemplate")
BlizzardUseAction = UseAction
function UseAction(slot, checkCursor, onSelf)
	BlizzardUseAction(slot, checkCursor, onSelf)
	if not UberBanishDB.Enabled or flags.BanishPending then return end
	if flags.BanishPending then return end -- return if the macro /CastSpellByName or /CastSpell was used
	
	UberBanishSpellTooltip:Hide()
	UberBanishSpellTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
	UberBanishSpellTooltip:SetAction(slot)
	
	local spellName = UberBanishSpellTooltipTextLeft1:GetText()
	local spellRank
	if UberBanishSpellTooltipTextRight1:GetText() then
		_, _, spellRank = string.find(UberBanishSpellTooltipTextRight1:GetText(), "(%d+)")
	end
	UberBanish:Debug(format("UseAction: slotID: %s; spellName: %s; spellRank: %s", slot, spellName, tostring(spellRank)))
	UberBanish:UpdateCastSpellInfo(spellName, spellRank)
end
------------------

function UberBanish:UpdateCastSpellInfo(spell, rank)
	local _, _, spellIsBanish = string.find(spell, "("..UB_BANISH..")")
	
	if spellIsBanish then
		if type(rank) ~= "number" then rank = tonumber(rank) end
		if not rank then rank = 2 end
		self:Debug(format("Player has started a %s(Rank %s)!", spell, rank))
		gCurrentBanishTarget = UnitName("target")
		gPreviousBanishRank = gCurrentBanishRank
		gCurrentBanishRank = rank
		flags.BanishPending = true
		-- Early Dismissal of Notice Banner
		else
		flags.BanishPending = false
	end
end

function UberBanish:StartTimer()
	self:Debug("Starting timer...")
	flags.TargetDirty = false
	flags.BanishPending = false
	flags.BanishTimer = true
	gBanishTimer = self:GetBanishDuration()
	gBanishStartTime = GetTime()
	CooldownFrame_SetTimer(getglobal(self:GetName().."BanishButtonCooldown"), gBanishStartTime, gBanishTimer, 1)
	gTimeSinceLastBanish = 0
end

function UberBanish:KillTimer()
	self:Debug("Killing the timer...")
	gTargetHasBanishDebuff = false
	flags.BanishTimer = false
	flags.AlreadyBanish = false
	gBanishTimer = self:GetBanishDuration()
	CooldownFrame_SetTimer(getglobal(self:GetName().."BanishButtonCooldown"), 0, 0, 0)
end

function UberBanish:GetBanishDuration()
	if type(gCurrentBanishRank) ~= "number" then gCurrentBanishRank = tonumber(gCurrentBanishRank) end
	local BANISH_DURATION = {18, 28}
	return BANISH_DURATION[gCurrentBanishRank]
end

-- Scans the current target for the Banish debuff.
function UberBanish:IsTargetBanished()
	-- Iterate through all debuffs on the current target and look for banish.
	for i = 1, MAX_TARGET_DEBUFFS do
		local texture = UnitDebuff("target", i)
		if texture == "Interface\\Icons\\Spell_Shadow_Cripple" then
			--self:Debug("I think this creature is still banished...")
			return true
		end
	end
	return
end

--[[ Looks for the banish debuff on the current target.  If there is not and there
	is currently a banish timer up, we consider this an early break situation and
return true.]]
function UberBanish:CheckBanishBroke()
	gTargetHasBanishDebuff = self:IsTargetBanished()
	
	--self:Debug("CheckBanishBroke:")
	--self:Debug("gTargetHasBanishDebuff: "..tostring(gTargetHasBanishDebuff))
	--self:Debug("flags.BanishTimer: "..tostring(flags.BanishTimer))
	--self:Debug("gBanishTimer: "..gBanishTimer)
	
	--[[ If the banish flag was up AND there isn't a Banish about to land AND we 
	did not find the banish debuff AND the timer is valid, then the banish is considered broken.]]
	if flags.BanishTimer and not (flags.BanishPending or gTargetHasBanishDebuff) and gBanishTimer > 0 then
		self:KillTimer()
		return true
	end
	return
end

function UberBanish:BFMPrint(msg)
	getglobal(self:GetName().."BFMText"):SetText(msg)
	UIFrameFadeOut(getglobal(self:GetName().."BFMFrame"), 4)
end

function UberBanish:Print(msg)
	ChatFrame1:AddMessage("|cffffff7f"..self:GetName()..":|r "..msg)
end

function UberBanish:Debug(msg, color)
	if not UberBanishDB.Debugging then return	end
	if color then msg = "cff"..ColorTable[color]..msg end
	ChatFrame1:AddMessage("|cffffff7f"..self:GetName().." |cffF08080(DEBUG)|cffffff7f:|r "..msg)
end

function UberBanish:Say(msg)
	if gAnnounceChannel == "SAY" and not UberBanishDB.SayWhenSolo then return end
	SendChatMessage(msg, gAnnounceChannel)
end

function UberBanish:RegisterChatCommands()
	SLASH_UBERBANISH1 = "/uberbanish"
	SLASH_UBERBANISH2 = "/ub"
	SlashCmdList["UBERBANISH"] = function(msg)		
		msg = string.lower(msg)
		local _, _, cmd = string.find(msg, "(%w+)")
		if not cmd or cmd == "" then
			self:Print(GetAddOnMetadata(self:GetName(), "Notes"))
			ChatFrame1:AddMessage("|cffffff7fUsage:|r /ub {config | about}")
			ChatFrame1:AddMessage("|cffffff7f- config:|r Open configuration panel.")
			ChatFrame1:AddMessage("|cffffff7f- about:|r Print information about addon.")
			elseif cmd == "about" then
			ChatFrame1:AddMessage("|cffffff7f"..GetAddOnMetadata(self:GetName(), "Title").." - "..GetAddOnMetadata(self:GetName(), "Version").."|r - "..GetAddOnMetadata(self:GetName(), "Notes"))
			ChatFrame1:AddMessage("|cffffff7f- Author:|r "..GetAddOnMetadata(self:GetName(), "Author"))
			ChatFrame1:AddMessage("|cffffff7f- Credits:|r "..GetAddOnMetadata(self:GetName(), "X-Credits"))
			ChatFrame1:AddMessage("|cffffff7f- Date:|r "..GetAddOnMetadata(self:GetName(), "X-Date"))
			ChatFrame1:AddMessage("|cffffff7f- Category:|r "..GetAddOnMetadata(self:GetName(), "X-Category"))
			ChatFrame1:AddMessage("|cffffff7f- Website:|r "..GetAddOnMetadata(self:GetName(), "X-Website"))
			ChatFrame1:AddMessage("|cffffff7f- Commands:|r "..GetAddOnMetadata(self:GetName(), "X-Commands"))
			elseif cmd == "config" then
			getglobal(self:GetName().."ConfigFrame"):Show()
		end
	end
end

function UberBanish:UpdateAnnounceChannel()
	if UnitInRaid("player") then
		gAnnounceChannel = "RAID"
		elseif GetNumPartyMembers() > 0 then -- UnitInParty("player") can NOT be used, see "Details": http://vanilla-wow.wikia.com/wiki/API_UnitInParty
		gAnnounceChannel = "PARTY"
		else
		gAnnounceChannel = "SAY"
	end
	self:Debug("The new channel is: "..gAnnounceChannel)
end

function UberBanish:UpdateWarlockList()
	self:Debug("UpdateWarlock: Refreshing Warlock List")
	gWarlockList = {}
	
	if GetNumPartyMembers() == 0 then
		table.insert(gWarlockList, PlayerName) -- ТОЛЬКО ДЛЯ ТЕСТОВ, ПОТОМ УДАЛИТЬ!
		return self:Debug("Not in a group!  Bailing...")	
	end
	
	local name, class
	if UnitInRaid("player") then
		for i = 1, GetNumRaidMembers() do
			name, _, _, _, _, class = GetRaidRosterInfo(i)
			if class and class == UB_playerClass and name ~= PlayerName then
				self:Debug("UpdateWarlock: "..name.." is a Warlock!!")
				table.insert(gWarlockList, name)
			end
		end
		else
		for i = 1, GetNumPartyMembers() do
			name = UnitName("party"..i)
			_, class = UnitClass("party"..i)
			self:Debug("UpdateWarlock: Checking party member "..i..": "..name.." -> "..class)
			if class == UB_playerClass then
				self:Debug("UpdateWarlock: "..name.." is a Warlock!!")
				table.insert(gWarlockList, name)
			end
		end
	end
end

-- Sends a message to all the other warlocks in the raid.
function UberBanish:SpamWarlocks(msg)
	for _, name in ipairs(gWarlockList) do
		SendChatMessage("<"..self:GetName().."BC> "..msg, "WHISPER", nil, name)
	end
end

--[[ When an UberBanish broadcast message is sent that is intended to identify a specific warlock, it will be of the form:
	WARLOCKS: Foo has ....
This function grabs the Warlock name from these messages and places it on deck.]]
function UberBanish:ExtractPlayerFromContent(content)
	local _, _, name = string.find(content, 'WARLOCKS: (%w*)')
	if not name then return end
	
	-- Place the warlock's name on deck so that if this warlock clicks the BFM, that warlock will be affected.
	gWarlockOnDeck = name
	gCommandOnDeck = COMMAND_TARGET
end

function UberBanish:LoadBanishFrame()
	local BanishButton = CreateFrame("Button", "UberBanishBanishButton", UIParrent)
	BanishButton:SetWidth(50)
	BanishButton:SetHeight(50)
	BanishButton:SetPoint("CENTER", 0, 0)
	BanishButton:SetMovable(1)
	BanishButton:EnableMouse(1)
	BanishButton:SetNormalTexture("")
	BanishButton:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
	BanishButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
	BanishButton:RegisterForDrag("LeftButton")
	BanishButton:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
	BanishButton.icon = BanishButton:CreateTexture(self:GetName().."BanishButtonIcon", "BORDER")
	BanishButton.icon:SetAllPoints(BanishButton)
	BanishButton.icon:SetTexture("Interface\\Icons\\Spell_Shadow_Cripple")
	BanishButton.cd = CreateFrame("Model", BanishButton:GetName().."Cooldown", BanishButton, "CooldownFrameTemplate")
	BanishButton.cd:SetAllPoints(BanishButton)
	BanishButton.cd:SetScale(BanishButton:GetWidth()/36)
	BanishButton.cd.text = BanishButton.cd:CreateFontString(BanishButton.cd:GetName().."Text", "OVERLAY")
	BanishButton.cd.text:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
	BanishButton.cd.text:SetPoint("CENTER", BanishButton.cd, "CENTER", 0, 0)
	BanishButton:SetScript("OnShow", function() self:Print("BanishBitton is shown") end)
	BanishButton:SetScript("OnHide", function() self:Print("BanishBitton is hidden") end)
	BanishButton:SetScript("OnDragStart", function()
		if IsShiftKeyDown() then
			this:StartMoving()
		end
	end)
	BanishButton:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
	BanishButton:SetScript("OnClick", function()
		local spell
		if arg1 == "LeftButton" then
			spell = UB_BANISH
			else
			spell = UB_BANISH_RANK1
		end
		CastSpellByName(spell)
	end)
end

function UberBanish:LoadBFMFrame()
	local BFMFrame = CreateFrame("Frame", self:GetName().."BFMFrame", UIParrent)
	BFMFrame:Hide()
	BFMFrame:SetFrameStrata("FULLSCREEN")
	BFMFrame:SetToplevel(true)
	BFMFrame:SetWidth(360)
	BFMFrame:SetHeight(50)
	BFMFrame:SetPoint("CENTER", 0, 50)
	BFMFrame:SetBackdrop({
		bgFile = "Interface\\TutorialFrame\\TutorialFrameBackground", tile = true,
		insets = {left = 5, right = 5, top = 5, bottom = 5},
	})
	BFMFrame.text = BFMFrame:CreateFontString(self:GetName().."BFMText", "BACKGROUND", "GameFontNormalLarge")
	BFMFrame.text:SetAllPoints(BFMFrame)
	BFMFrame:SetScript("OnMouseUp", function()
		-- A warlock has died...select his target
		if gWarlockOnDeck and gCommandOnDeck == COMMAND_TARGET then
			AssistByName(gWarlockOnDeck)
			-- This warlock's banish broke. Rebanish.
			elseif not gWarlockOnDeck and gCommandOnDeck == COMMAND_BANISH then
			CastSpellByName(UB_BANISH)
		end
	end)
end

local function ParsePattern(in_pattern)
	local pattern = in_pattern
	pattern = string.gsub(pattern,"%.$","") -- strip trailing .
	pattern = string.gsub(pattern,"%%s","(.+)") -- %s to (.+)
	pattern = string.gsub(pattern,"%%d","(%%d+)") -- %d to (%d+)
	if string.find(pattern,"%$") then
		-- entries need reordered, ie: SPELLMISSOTHEROTHER = "%2$s von %1$s verfehlt %3$s."
		pattern = string.gsub(pattern,"%%%d%$s","(.+)")
		pattern = string.gsub(pattern,"%%%d%$d","(%%d+)")
	end
  return pattern
end

function UberBanish:ParseAllPatterns()
	UB_AURAADDEDOTHERHARMFUL = ParsePattern(AURAADDEDOTHERHARMFUL)    -- %s is afflicted by %s.
	UB_SPELLRESISTSELFOTHER = ParsePattern(SPELLRESISTSELFOTHER)      -- Your %s was resisted by %s.
	UB_SPELLIMMUNESELFOTHER = ParsePattern(SPELLIMMUNESELFOTHER)      -- Your %s failed. %s is immune.
	UB_SPELLEVADEDSELFOTHER = ParsePattern(SPELLEVADEDSELFOTHER)      -- Your %s was evaded by %s.
	UB_AURAREMOVEDOTHER = ParsePattern(AURAREMOVEDOTHER)              -- %s fades from %s.
	UB_SPELLCASTOTHERSTART = ParsePattern(SPELLCASTOTHERSTART)        -- %s begins to cast %s.
	UB_UNITDIESOTHER = ParsePattern(UNITDIESOTHER)                    -- %s dies.
end