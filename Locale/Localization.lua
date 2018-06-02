UB_BANISH									= "Banish"
UB_BANISH_RANK1						= "Banish(Rank 1)"
UB_MOB_BROKE_YOUR_BANISH	= "MOB BROKE YOUR BANISH!!!"
UB_HAS_BANISHED						= "%s has banished %s."
UB_BANISH_BREAKS_IN				= "Banish breaks in %s seconds..."
UB_MY_BANISH_EXPIRES			= "My Banish expires now!"
UB_HAS_DIED_WHILE_BANISHING	= "WARNING: %s has died while banishing!"

UB_LOADED = "Addon loaded."
UB_OPTION_CUR_SET = "%s is currently set to %s"
UB_OPTION_NOW_SET = "%s is now set to %s"
UB_INFO = "Info"
UB_ENABLE = "Enable"
UB_INFORMATION = "Information"
UB_DEBUGGING = "Debugging"
UB_STANDBY = "Standby"
UB_ON = "On"
UB_OFF = "Off"
UB_BB_HIDDEN = "BanishBitton is hidden."
UB_BB_SHOWN = "BanishBitton is shown."

UB_MB_TOOLTIP1 = {"Left-Click", "Toggle BanishFrame"}
UB_MB_TOOLTIP2 = {"Right-Click", "Open Configuration"}
UB_BB_TOOLTIP1 = {"Left-Click", "Cast Banish(Rank 2)"}
UB_BB_TOOLTIP2 = {"Right-Click", "Cast Banish(Rank 1)"}
UB_BB_TOOLTIP3 = {"Shift-Drag", "Move button"}

UB_CHECKBUTTON1_DESC = "Spam Banish Start."
UB_CHECKBUTTON2_DESC = "20 Second Warning."
UB_CHECKBUTTON3_DESC = "10 Second Warning."
UB_CHECKBUTTON4_DESC = "5 Second Warning."
UB_CHECKBUTTON5_DESC = "Spam Banish End."
UB_CHECKBUTTON6_DESC = "Notify other Warlocks on death."
UB_CHECKBUTTON7_DESC = "Spam the raid if a Banish breaks early."
UB_CHECKBUTTON7_TOOLTIP = "Works ONLY if the player is within 28-30 yards from the unit with the Banish!"
UB_CHECKBUTTON8_DESC = "Spam the raid when you die during Banish."
UB_CHECKBUTTON8_TOOLTIP = "up to 30 seconds since the last Banish."
UB_CHECKBUTTON9_DESC = "Speak aloud when solo."

UB_INFORMATION_TEXT = [[In the addon, there are two variants for detecting Banish:
	
	1. Correct. The timer is activated at the event CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE.
	
	2. Incorrect. If the above event does not work, then the timer is activated at the SPELLCAST_STOP event, which is
	not very reliable. In this case, the Banish button with the timer will be pulsed.
	
	
	Note: For reasons unknown to me, all events for a unit do not work if the unit on which event, is at a great distance
	(about 28-30 yards) from the player. In other words, if the player will cast Banish at the maximum available distance,
	then the events for the 1 detection variant may not work, but for 2 will work as SPELLCAST_STOP only works for the player.]]