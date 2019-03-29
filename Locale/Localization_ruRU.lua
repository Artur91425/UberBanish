if not UberBanish then return end

if GetLocale() == "ruRU" then
	local L = UberBanish.L
	
	L["Banish"] = "Изгнание"
	L["Banish(Rank 1)"] = "Изгнание(Уровень 1)"
	L["MOB BROKE YOUR BANISH!!!"]	= "MOB BROKE YOUR BANISH!!!"
	L["%s has banished %s."] = "%s накладывает 'Изгнание' на %s."
	L["Banish breaks in %s seconds..."]				= "'Изгнание' истекает через %s секунд..."
	L["My Banish expires now!"]			= "Моё 'Изгнание' истекает сейчас!"
	L["WARNING: %s has died while banishing!"]	= "ВНИМАНИЕ: %s умер при изгнании!"
	
	L["Addon loaded."] = "Аддон загружен."
	L["%s is currently set to %s"] = "%s в настоящее время установлен на %s"
	L["%s is now set to %s"] = "%s теперь установлен на %s"
	L["Info"] = "Инфо"
	L["Enable"] = "Включить"
	L["Information"] = "Информация"
	L["Debugging"] = "Отладка"
	L["Standby"] = "Состояние"
	L["On"] = "Вкл."
	L["Off"] = "Выкл."
	L["BanishBitton is hidden."] = "Кнопка Изгнания скрыта."
	L["BanishBitton is shown."] = "Кнопка Изгнания показана."
	
	L["Left-Click"] = "Левая кнопка мыши"
	L["Right-Click"] = "Правая кнопка мыши"
	L["Shift-Drag"] = "Shift + перемещение"
	L["Toggle BanishFrame"] = "Показать/Скрыть кнопку Изгнания"
	L["Open Configuration"] = "Открыть настройки"
	L["Cast Banish(Rank 2)"] = "Произнесение 'Изгнание(Уровень 2)'"
	L["Cast Banish(Rank 1)"] = "Произнесение 'Изгнание(Уровень 1)'"
	L["Move button"] = "Перемещение кнопки"
	
	L["Spam Banish Start."] = "Сообщать о начале Изгнания."
	L["20 Second Warning."] = "Сообщать на 20 секундах."
	L["10 Second Warning."] = "Сообщать на 10 секундах."
	L["5 Second Warning."] = "Сообщать на 5 секундах."
	L["Spam Banish End."] = "Сообщать о завершении Изгнания."
	L["Notify other Warlocks on death."] = "Оповещать других чернокнижников\nо Вашей смерти."
	L["Spam the raid if a Banish breaks early."] = "Сообщать в рейд, если Изгнание\nпрервалось раньше."
	L["Works ONLY if the player is within 28-30 yards from the unit with the Banish!"] = "Работает ТОЛЬКО если игрок находится в пределах ДО 28-30 метров от моба с Изгнанием!"
	L["Spam the raid when you die during Banish."] = "Сообщать в рейд, если Вы умерли\nво время Изгнания."
	L["up to 30 seconds since the last Banish."] = "до 30 секунд с момента последнего Изгнания."
	L["Speak aloud when solo."] = "Сообщать, когда вне группы."

	L["info_text"] = [[В аддоне есть два варианта обнаружения Изгнания:
		
		1. Корректное. Таймер активируется на событии CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE.
		
		2. Некорректное. Если вышеуказанное событие не сработало, то таймер активируется на событии SPELLCAST_STOP,
		что является не очень достоверным. В таком случае кнопка Изгнания с таймером будет пульсировать.
		
		
		Примечание: По неизвестным мне причинам, все события для юнита не срабатывают, если юнит, на котором
		происходят события, находится на большом расстоянии (примерно 28-30 метров) от игрока. Иными словами,
		если игрок будет применять Игнание на максимально доступном расстоянии, то события для 1 варианта обнаружения
		могут не сработать, но для 2 сработают так как SPELLCAST_STOP срабатывает только для игрока.]]
end