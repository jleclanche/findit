------------
-- FindIt --
------------
-- Find achievements, spells and cached items
-- easily from chat commands.
-- Feedback, questions, jerome.leclanche+findit@gmail.com

-- FindIt is licensed under MIT
-- Please read the LICENSE file for details

FindIt = select(2, ...)
FindIt.NAME = select(1, ...)
FindIt.CNAME = "|cff33ff99" .. FindIt.NAME .. "|r"
FindIt.VERSION = "1.9.0"

local LibWeagleTooltip = LibStub("LibWeagleTooltip-2.1")

local VERSION, BUILD, COMPILED, TOC = GetBuildInfo()
BUILD, TOC = tonumber(BUILD), tonumber(TOC)

local PLAIN_LETTER = 8383 -- Plain Letter stationery item id, "always" cached (for enchants)
local DUROTAR_MAP = 4 -- Used as base map to reset it

function FindIt:Print(...)
	print(self.CNAME.. ":", ...)
end

function FindIt:Help()
	self:Print(
		"Find spells, achievements and cached items easily.\n",
		"* /finditem thunderfury - find by name (case insensitive)\n",
		"* /finditem 12345 - find by id\n",
		"* /finditem 123-987 - find by id range (swap ids for reverse search)\n",
		"Also works with /findspell, /findach, /findcreature, /findglyph, /findtalent, /finddungeon, /findenchant, /findinstance, /findcurrency and /findtitle\n"
	)
	self:Print("IMPORTANT: /finditem and /findcreature can only find cached items and NPCs (seen since last patch).")
	self:Print(self.NAME, self.VERSION, "by Adys.")
end

function FindIt:Register(type, func)
	local utype = type:upper()
	_G["SLASH_FIND" .. utype .. "1"] = "/find" .. type
	if not func then
		func = function(msg)
			FindIt:FindObject(type, msg)
		end
	end
	SlashCmdList["FIND" .. utype] = func
end


FindIt.achievement = {
	name = "Achievement",
	max = 10000,
	getInfo = function(self, id)
		if pcall(GetAchievementInfo, id) then
			local name = select(2, GetAchievementInfo(id))
			return name, GetAchievementLink(id)
		end
	end,
}
FindIt:Register("achievement")
SLASH_FINDACHIEVEMENT2 = "/findach"

FindIt.area = {
	name = "Area",
	max = 1000,
	getInfo = function(self, id)
		local name = GetMapNameByID(id)
		if name then
			return name, ("|cffffff00%s|r"):format(name)
		end
	end,
}
FindIt:Register("area")

FindIt.battlepetability = { -- BattlePetAbility.db2
	name = "Battle Pet Ability",
	max = 3000,
	getInfo = function(self, id)
		local id, name, icon = C_PetBattles.GetAbilityInfoByID(id)
		if name then
			-- Link format: battlePetAbil:<id>:<health>:<power>:<speed>
			local link = ("|cff4e96f7|HbattlePetAbil:%s:100:0:0|h[%s]|h|r"):format(id, name)
			return name, link
		end
	end,
}
FindIt:Register("battlepetability")
SLASH_FINDBATTLEPETABILITY2 = "/findbpa"

FindIt.creature = {
	name = "Creature",
	max = 60000,
	getInfo = function(self, id)
		id = tonumber(id)
		local guid = self.guidfmt:format(id)
		local name = LibWeagleTooltip:GetTooltipLine("unit:" .. guid, 1) -- FIXME we are calling a new tooltip.. this is slow
		if not name then return end
		local link = ("|cffffff00|Hunit:%s:%s|h[%s]|h|r"):format(guid, name, name)

		return name, link
	end,
	guidfmt = (function()
		if BUILD < 10522 then
			return "0xF13000%04X000000" -- TBC/WLK format
		elseif TOC < 40000 then
			return "0xF13000%04X000000" -- 3.3.x format
		end
		return "0xF130%04X00000000" -- cataclysm format
	end)(),
}
FindIt:Register("creature")

FindIt.currency = {
	name = "Currency",
	max = 1000,
	getInfo = function(self, id)
		local name = GetCurrencyInfo(id)
		local link = GetCurrencyLink(id)
		return name, link
	end,
}
FindIt:Register("currency")

FindIt.dungeon = {
	name = "Dungeon",
	max = 1000,
	getInfo = function(self, id)
		local name = GetLFGDungeonInfo(id)
		if name then
			return name, ("|cffffff00%s|r"):format(name)
		end
	end,
}
FindIt:Register("dungeon")

FindIt.enchant = {
	name = "Enchant",
	max = 10000,
	getInfo = function(self, id)
		local name = LibWeagleTooltip:GetTooltipLine(("item:%i:%i"):format(PLAIN_LETTER, id), 2)
		if name then
			return name, ("|cffffff00%s|r"):format(name)
		end
	end,
}
FindIt:Register("enchant")

FindIt.faction = {
	name = "Faction",
	max = 2000,
	getInfo = function(self, id)
		local name = GetFactionInfoByID(id)
		if name then
			return name, ("|cffffff00%s|r"):format(name)
		end
	end,
}
FindIt:Register("faction")

FindIt.glyph = {
	name = "Glyph",
	max = 3000,
	getInfo = function(self, id)
		local name, link
		if TOC > 50000 then
			link = GetGlyphLinkByID(id)
			if link == "" then return end
			name = link:match("%b[]"):sub(2, -2)
		else
			name = LibWeagleTooltip:GetTooltipLine("glyph:21:" .. id, 1) -- Always a Major Glyph
			if name == "Empty" then return end -- All invalid tooltips are shown as an empty glyph slot
			link = ("|cff66bbff|Hglyph:21:%i|h[%s]|h|r"):format(id, name)
		end
		return name, link
	end,
}
FindIt:Register("instance")

FindIt.instance = {
	name = "Instance",
	max = 1500,
	getInfo = function(self, id)
		local guid = UnitGUID("player"):sub(3) -- Remove 0x prefix
		local link = ("instancelock:%s:%i:0:0"):format(guid, id)
		local name = LibWeagleTooltip:GetTooltipLine(link, 1)
		if not name then return end

		local _, name = name:match("^" .. INSTANCE_LOCK_SS:gsub("%%s", "(.+)"))
		return name, ("|cffff8000|H%s|h[%s]|h|r"):format(link, name)
	end,
}

FindIt.item = {
	name = "Item",
	max = 75000,
	getInfo = function(self, id)
		local name, link = GetItemInfo(id)
		return name, link
	end,
}
FindIt:Register("item", function(msg)
	if not tonumber(msg) and TOC >= 40000 and TOC <= 50000 then
		return FindIt:Print("Non-ID lookups for items are disabled in the 4.x client due to a bug in the WoW API. Blame Blizzard.")
	end
	FindIt:FindObject("item", msg)
end)

FindIt.map = {
	name = "Map",
	max = 2000,
	getInfo = function(self, id)
		local name
		if GetMapNameByID then -- New in Mists of Pandaria
			name = GetMapNameByID(id)
			if name then
				return name, ("|cffffff00%s|r"):format(name)
			end
		else
			SetMapByID(DUROTAR_MAP) -- Reset the map to Durotar
			local durotar = GetMapInfo()
			SetMapByID(id)
			name = GetMapInfo()
			if id == 4 or name ~= durotar then
				return name, ("|cffffff00%s|r"):format(name)
			end
		end
	end,
}
FindIt:Register("map")

FindIt.quest = {
	name = "Quest",
	max = 50000,
	getInfo = function(self, id)
		local name = LibWeagleTooltip:GetTooltipLine("quest:" .. id, 1)
		if not name then return end
		local level = UnitLevel("player") -- FIXME impossible to get a quest level
		local link = ("|cffffff00|Hquest:%i:%i|h[%s]|h|r"):format(id, level, name)

		return name, link
	end,
}
FindIt:Register("quest", function(msg)
	if not tonumber(msg) then
		return FindIt:Print("Non-ID lookups for quests are disabled because they cause disconnects. Blame Blizzard.")
	end
	FindIt:FindObject("quest", msg)
end)

FindIt.spell = {
	name = "Spell",
	max = 150000,
	getInfo = function(self, id)
		local name = GetSpellInfo(id)
		if name then
			local link =  ("|cff71d5ff|Hspell:%i|h[%s]|h|r"):format(id, name)
			return name, link
		end
	end,
}
FindIt:Register("spell")

FindIt.talent = {
	name = "Talent",
	max = 20000,
	getInfo = function(self, id)
		local name, rank = LibWeagleTooltip:GetTooltipLine("talent:" .. id, 1)
		if not name or name == "Word of Recall (OLD)" then return end -- Invalid tooltips' names.. go figure.
		local link = ("|cff4e96f7|Htalent:%i:-1|h[%s]|h|r"):format(id, name)

		return name, link
	end,
}
FindIt:Register("talent")

FindIt.title = {
	name = "Title",
	max = GetNumTitles(),
	getInfo = function(self, id)
		local name = GetTitleName(id)
		if not name then return end
		local fullname, match = name:gsub("^ ", GetUnitName("player").." ")
		-- XXX commas get trimmed, there is no actual way to get the real full title.
		if match == 0 then
			fullname = name .. GetUnitName("player")
		end
		return name, ("|cffffff00%s|r"):format(fullname)
	end,
}
FindIt:Register("title")

local function findrange(obj, first, last)
	local ret = {}
	local name, link
	local id = first
	if first > last then
			local range = first - last
			for i = 0, range do
				name, link = obj:getInfo(id)
				if name then
					table.insert(ret, { id = id, link = link })
				end
				id = id - 1
			end
	else
		for id = first, last do
			name, link = obj:getInfo(id)
			if name then
				table.insert(ret, { id = id, link = link })
			end
		end
	end
	return ret
end

local function findname(obj, arg)
	local ret = {}
	local name, link
	arg = arg:lower()
	for id = 1, obj.max do
		name, link = obj:getInfo(id)
		name = (name or ""):lower()
		if name == arg then
			table.insert(ret, { id = id, link = link })
		elseif name:match(arg) then
			table.insert(ret, { id = id, link = link })
		end
	end
	return ret
end

function FindIt:FindObject(type, msg)
	if not msg or msg == "" then return self:Print("Usage: /find" .. type .. " (id|[min-max]|name) - /findit for help") end
	local obj = FindIt[type]
	found = {}

	if msg:match("%d+%-%d+") then
		local first, last = msg:match("(%d+)%-(%d+)")
		found = findrange(obj, first, last)
	elseif tonumber(msg) then
		local name, link = obj:getInfo(msg)
		if name then
			found = { { id = tonumber(msg), link = link } }
		end
	else
		found = findname(obj, msg)
	end

	for k, v in pairs(found) do
		self:Print(obj.name .. " #" .. v.id, v.link)
	end
	local amt = #found
	self:Print(amt .. " matches.")
end

SLASH_FINDIT1 = "/findit"
SlashCmdList["FINDIT"] = function()
	FindIt:Help()
end
