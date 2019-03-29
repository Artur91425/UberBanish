local _, playerClass = UnitClass("player")
if playerClass ~= "WARLOCK" then return end

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
	BanishButtonTooltip = true,
	BanishButtonPosition = {"CENTER", 0, 0}
}

UberBanish = CreateFrame("Frame", "UberBanish")
UberBanish.L = setmetatable({}, {__index = function(t, k)
	local v = tostring(k)
	rawset(t, k, v)
	return v
end})

function UberBanish:print(text, r, g, b, frame, delay)
	if not text then text = "nil" end
	(frame or DEFAULT_CHAT_FRAME):AddMessage("|cffffff78"..self:GetName()..":|r "..text, r, g, b, nil, delay or 5)
end

function UberBanish:debug(text, r, g, b, frame, delay)
	if not UberBanishDB.Debugging then return end
	if not text then text = " " end
	(frame or DEFAULT_CHAT_FRAME):AddMessage(format("[%s%4d] ".."|cff7fff7f(DEBUG) "..self:GetName()..":|r "..text, date("%H:%M:%S"), math.mod(GetTime(), 1) * 1000), r, g, b, nil, delay or 5)
end
