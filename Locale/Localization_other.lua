if not UberBanish then return end

local L = UberBanish.L

if GetLocale() == "deDE" then
	L["Banish"] = "Verbannen"
	L["Banish(Rank 1)"] = "Verbannen(Rang 1)"
elseif GetLocale() == "frFR" then
	L["Banish"] = "Bannir"
	L["Banish(Rank 1)"] = "Bannir(Rang 1)"
elseif GetLocale() == "zhCN" then
	L["Banish"] = "放逐术"
	L["Banish(Rank 1)"] = "放逐术(等级 1)"
elseif GetLocale() == "zhTW" then
	L["Banish"] = "放逐術"
	L["Banish(Rank 1)"] = "放逐術(等級 1)"
elseif GetLocale() == "koKR" then
	L["Banish"] = "추방"
	L["Banish(Rank 1)"] = "추방(1 레벨)"
elseif GetLocale() == "esES" then
	L["Banish"] = "Desterrar"
	L["Banish(Rank 1)"] = "Desterrar(Rango 1)"
end