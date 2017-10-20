------------
-- FindIt --
------------
-- Find items, spells, achievements and several more
-- from the chat window.
-- Feedback, questions, jerome@leclan.ch

-- FindIt is licensed under MIT
-- Please read the LICENSE file for details

FindIt = select(2, ...)
FindIt.NAME = select(1, ...)
FindIt.CNAME = "|cff33ff99" .. FindIt.NAME .. "|r"
FindIt.VERSION = GetAddOnMetadata("FindIt", "Version")
FindIt.commands = {}
FindIt.MAXRESULTS = DEFAULT_CHAT_FRAME:GetMaxLines()

local LibWeagleTooltip = LibStub("LibWeagleTooltip-2.1")

local VERSION, BUILD, COMPILED, TOC = GetBuildInfo()
BUILD, TOC = tonumber(BUILD), tonumber(TOC)

local PLAIN_LETTER = 8383 -- Plain Letter stationery item id, "always" cached (for enchants)
local DUROTAR_MAP = 4 -- Used as base map to reset it

function FindIt:Print(...)
	print(self.CNAME .. ":", ...)
end

function FindIt:Help()
	self:Print(
		"Find items, spells, achievements and several more from the chat window.\n",
		"* /findspell frostbolt - find by name (case insensitive)\n",
		"* /findspell 1234 - find by id\n",
		"* /findspell 123-987 - find by id range (swap ids for reverse search)\n",
		"* /findspell . - list everything (match any string). Can be slow!\n",
		"Also works with /findspell, /findach and more. Type /findit list for a full list.\n"
	)
	self:Print("IMPORTANT: /finditem and /findcreature can only find cached items and NPCs (seen since last patch).")
	self:Print(self.NAME, self.VERSION, "by Adys.")
end

function FindIt:List()
	local cmd, cmd2
	for k, v in pairs(self.commands) do
		cmd = "/find" .. v
		cmd2 = _G["SLASH_FIND" .. v:upper() .. "2"]
		if cmd2 then
			cmd = ("%s, %s"):format(cmd, cmd2)
		end
		self:Print(cmd, ("(%s)"):format(self[v].file))
	end
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
	table.insert(self.commands, type)
end


FindIt.achievement = {
	name = "Achievement",
	file = "Achievement.dbc",
	max = 50000,
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
	file = "Area.dbc",
	max = 5000,
	getInfo = function(self, id)
		local name = GetMapNameByID(id)
		if name then
			return name, ("|cffffff00%s|r"):format(name)
		end
	end,
}
FindIt:Register("area")

FindIt.battlepet = {
	name = "Battle Pet",
	file = "BattlePetSpecies.db2",
	max = 10000,
	getInfo = function(self, id)
		local name, icon = C_PetJournal.GetPetInfoBySpeciesID(id)
		-- some entries, such as id #71 and #73, are empty
		-- and in 6.2 the ID is returned even if the result doesn't exist...
		if name and name ~= "" and type(name) == "string" then
			-- Link format: battlepet:<id>:<level>:<rarity>:<health>:<power>:<speed>:<guid>
			local link = ("|cffffd200|Hbattlepet:%s:1:-1:100|h[%s]|h|r"):format(id, name)
			return name, link
		end
	end,
}
FindIt:Register("battlepet")
SLASH_FINDBATTLEPET2 = "/findbp"

FindIt.battlepetability = {
	name = "Battle Pet Ability",
	file = "BattlePetAbility.db2",
	max = 10000,
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
	file = "creaturecache.wdb",
	max = 200000,
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
		elseif TOC < 60000 then
			return "0xF13%05X00000000" -- Cataclysm/MoP format
		else
			return "Creature:0:976:0:11:%i:0000000000" -- WoD format
		end
	end)(),
}
FindIt:Register("creature")

FindIt.currency = {
	name = "Currency",
	file = "Currency.dbc",
	max = 10000,
	getInfo = function(self, id)
		local name = GetCurrencyInfo(id)
		local link = GetCurrencyLink(id)
		return name, link
	end,
}
FindIt:Register("currency")

FindIt.dungeon = {
	name = "Dungeon",
	file = "LfgDungeons.dbc",
	max = 10000,
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
	file = "SpellItemEnchantment.dbc",
	max = 20000,
	getInfo = function(self, id)
		local name = LibWeagleTooltip:GetTooltipLine(("item:%i:%i"):format(PLAIN_LETTER, id), 2)
		-- TODO strip away ENCHANTED_TOOLTIP_LINE
		if name then
			return name, ("|cffffff00%s|r"):format(name)
		end
	end,
}
FindIt:Register("enchant")

FindIt.encounter = {
	name = "Encounter",
	file = "JournalEncounter.dbc",
	max = 20000,
	getInfo = function(self, id)
		local name, description, encounterID, rootSectionID, link = EJ_GetEncounterInfo(id)
		if name then
			return name, link
		end
	end,
}
FindIt:Register("encounter")

FindIt.faction = {
	name = "Faction",
	file = "Faction.dbc",
	max = 10000,
	getInfo = function(self, id)
		local name = GetFactionInfoByID(id)
		if name then
			return name, ("|cffffff00%s|r"):format(name)
		end
	end,
}
FindIt:Register("faction")

FindIt.garrbuilding = {
	name = "Garrison Building",
	file = "GarrBuilding.db2",
	max = 5000,
	getInfo = function(self, id)
		local _, name = C_Garrison.GetBuildingInfo(id)
		if name then
			return name, ("|cffffff00%s|r"):format(name)
		end
	end,
}
FindIt:Register("garrbuilding")

FindIt.garrfollower = {
	name = "Garrison Follower",
	file = "GarrFollower.db2",
	max = 10000,
	getInfo = function(self, id)
		local t = C_Garrison.GetFollowerInfo(id)
		if t then
			local link = C_Garrison.GetFollowerLinkByID(id)
			return t.name, link
		end
	end,
}
FindIt:Register("garrfollower")

FindIt.glyph = {
	name = "Glyph",
	file = "GlyphProperties.dbc",
	max = 10000,
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
FindIt:Register("glyph")

FindIt.instance = {
	name = "Instance",
	file = "Map.dbc",
	max = 10000,
	getInfo = function(self, id)
		local guid = UnitGUID("player"):sub(3) -- Remove 0x prefix
		local link = ("instancelock:%s:%i:0:0"):format(guid, id)
		local name = LibWeagleTooltip:GetTooltipLine(link, 1)
		if not name then return end

		local _, name = name:match("^" .. INSTANCE_LOCK_SS:gsub("%%s", "(.+)"))
		return name, ("|cffff8000|H%s|h[%s]|h|r"):format(link, name)
	end,
}
FindIt:Register("instance")

FindIt.item = {
	name = "Item",
	file = "itemcache.wdb, Item.dbc, Item.db2, Item.adb, Item-sparse.db2, Item-sparse.db2",
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
	file = "WorldMapArea.dbc",
	max = 20000,
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
	file = "questcache.wdb",
	max = 100000,
	getInfo = function(self, id)
		local name = LibWeagleTooltip:GetTooltipLine("quest:" .. id, 1)
		if not name then return end
		local level = UnitLevel("player") -- FIXME impossible to get a quest level
		local link = ("|cffffff00|Hquest:%i:%i|h[%s]|h|r"):format(id, level, name)

		return name, link
	end,
}
FindIt:Register("quest")

FindIt.spec = {
	name = "Spec",
	file = "SpecializationSpells.dbc",
	max = 1000,
	getInfo = function(self, id)
		local id, name, description, icon, type, class = GetSpecializationInfoByID(id)
		if id then
			return name, ("|cffffff00%s|r"):format(name)
		end
	end,
}
FindIt:Register("spec")

FindIt.spell = {
	name = "Spell",
	file = "Spell.dbc",
	max = 300000,
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
	file = "Talent.dbc",
	max = 100000,
	getInfo = function(self, id)
		local name, _
		if TOC < 60000 then
			name, _ = LibWeagleTooltip:GetTooltipLine("talent:" .. id, 1)
			if not name or name == "Word of Recall (OLD)" then return end -- Invalid tooltips' names.. go figure.
		else
			_, name, _ = GetTalentInfoByID(id)
			if not name then return end
		end

		return name, ("|cff4e96f7|Htalent:%i:-1|h[%s]|h|r"):format(id, name)
	end,
}
FindIt:Register("talent")

FindIt.archrace = {
	name = "Archaeology Race",
	file = "ResearchBranch.dbc",
	max = 10000,
	getInfo = function(self, id)
		local name, icon, _ = GetArchaeologyRaceInfoByID(id)
		if name == "UNKNOWN" then return end

		return name, ("|cffffff00%s|r"):format(name)
	end
}
FindIt:Register("archrace")

FindIt.title = {
	name = "Title",
	file = "CharTitles.dbc",
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
	local i = 1
	if first > last then
		i = -1
	end
	for id = first, last, i do
		name, link = obj:getInfo(id)
		if name then
			table.insert(ret, { id = id, link = link })
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

	local amt = #found
	for i = max(1, amt - self.MAXRESULTS), amt do
		self:Print(obj.name .. " #" .. found[i].id, found[i].link)
	end
	if amt > self.MAXRESULTS then
		self:Print(amt .. " matches (only displaying the last " .. self.MAXRESULTS .. " results).")
	else
		self:Print(amt .. " matches.")
	end
end

SLASH_FINDIT1 = "/findit"
SlashCmdList["FINDIT"] = function(msg)
	if msg == "list" then
		FindIt:List()
	else
		FindIt:Help()
	end
end
