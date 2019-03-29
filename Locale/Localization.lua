if not UberBanish then return end

local L = UberBanish.L

L["Banish"] = nil
L["Banish(Rank 1)"] = nil
L["MOB BROKE YOUR BANISH!!!"] = nil
L["%s has banished %s."] = nil
L["Banish breaks in %s seconds..."] = nil
L["My Banish expires now!"] = nil
L["WARNING: %s has died while banishing!"] = nil

L["Addon loaded."] = nil
L["%s is currently set to %s"] = nil
L["%s is now set to %s"] = nil
L["Info"] = nil
L["Enable"] = nil
L["Information"] = nil
L["Debugging"] = nil
L["Standby"] = nil
L["On"] = nil
L["Off"] = nil
L["BanishBitton is hidden."] = nil
L["BanishBitton is shown."] = nil

L["Left-Click"] = nil
L["Right-Click"] = nil
L["Shift-Drag"] = nil
L["Toggle BanishFrame"] = nil
L["Open Configuration"] = nil
L["Cast Banish(Rank 2)"] = nil
L["Cast Banish(Rank 1)"] = nil
L["Move button"] = nil

L["Spam Banish Start."] = nil
L["20 Second Warning."] = nil
L["10 Second Warning."] = nil
L["5 Second Warning."] = nil
L["Spam Banish End."] = nil
L["Notify other Warlocks on death."] = nil
L["Spam the raid if a Banish breaks early."] = nil
L["Works ONLY if the player is within 28-30 yards from the unit with the Banish!"] = nil
L["Spam the raid when you die during Banish."] = nil
L["up to 30 seconds since the last Banish."] = nil
L["Speak aloud when solo."] = nil

L["info_text"] = [[In the addon, there are two variants for detecting Banish:
	
	1. Correct. The timer is activated at the event CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE.
	
	2. Incorrect. If the above event does not work, then the timer is activated at the SPELLCAST_STOP event, which is
	not very reliable. In this case, the Banish button with the timer will be pulsed.
	
	
	Note: For reasons unknown to me, all events for a unit do not work if the unit on which event, is at a great distance
	(about 28-30 yards) from the player. In other words, if the player will cast Banish at the maximum available distance,
	then the events for the 1 detection variant may not work, but for 2 will work as SPELLCAST_STOP only works for the player.]]