------------
-- FindIt --
------------
-- Find achievements, spells and cached items
-- easily from chat commands.
-- Feedback, questions, adys.wh+findit@gmail.com

-- FindIt is licensed under MIT
-- Please read the LICENSE file for details

FindIt = select(2, ...)
FindIt.NAME = select(1, ...)
FindIt.CNAME = "|cff33ff99" .. FindIt.NAME .. "|r"
FindIt.VERSION = "1.6.0"

local VERSION, BUILD, COMPILED, TOC = GetBuildInfo()
BUILD, TOC = tonumber(BUILD), tonumber(TOC)

local PLAIN_LETTER = 8383 -- Plain Letter stationery item id, "always" cached (for enchants)

function FindIt:Print(...)
	print(self.CNAME.. ":", ...)
end

function FindIt:Help()
	self:Print(
		"Find spells, achievements and cached items easily.\n",
		"* /finditem thunderfury - find by name (case insensitive)\n",
		"* /finditem 12345 - find by id\n",
		"* /finditem 123-987 - find by id range (swap ids for reverse search)\n",
		"Also works with /findspell, /findach, /findcreature, /findglyph, /findtalent, /finddungeon, /findenchant, /findinstance and /findtitle\n"
	)
	self:Print("IMPORTANT: /finditem and /findcreature can only find cached items and NPCs (seen since last patch).")
	self:Print(self.NAME, self.VERSION, "by Adys.")
end

local function GetSpellRealLink(id) -- GetSpellLink is broken
	local name = GetSpellInfo(id)
	if not name then return end
	local link = GetSpellLink(id)
	
	if not link then -- Spell exists but is unlinkable
		link = "|cff71d5ff|Hspell:" .. id .. "|h[" .. name .. "]|h|r"
	end
	return link
end

local function GetGUIDFormat()
	if BUILD < 10522 then
		return "0xF13000%04X000000" -- TBC/WLK format
	elseif TOC >= 40000 then
		return "0xF130%04X00000000" -- cataclysm format
	else
		return "0xF13000%04X000000" -- 3.3.x format
	end
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

FindIt.creature = {
	name = "Creature",
	max = 60000,
	getInfo = function(self, id)
		id = tonumber(id)
		local guid = GetGUIDFormat():format(id)
		local name = LibWeagleTooltip:GetTooltipLine("unit:" .. guid, 1) -- FIXME we are calling a new tooltip.. this is slow
		if not name then return end
		local link = ("|cffffff00|Hunit:%s:%s|h[%s]|h|r"):format(guid, name, name)
		
		return name, link
	end,
}

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

FindIt.glyph = {
	name = "Glyph",
	max = 3000,
	getInfo = function(self, id)
		local name = LibWeagleTooltip:GetTooltipLine("glyph:21:" .. id, 1) -- Always a Major Glyph
		if name == "Empty" then return end -- All invalid tooltips are shown as an empty glyph slot
		local link = ("|cff66bbff|Hglyph:21:%i|h[%s]|h|r"):format(id, name)
		
		return name, link
	end,
}

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

FindIt.quest = {
	name = "Quest",
	max = 35000,
	getInfo = function(self, id)
		local name = LibWeagleTooltip:GetTooltipLine("quest:" .. id, 1)
		if not name then return end
		local level = UnitLevel("player") -- FIXME impossible to get a quest level
		local link = ("|cffffff00|Hquest:%i:%i|h[%s]|h|r"):format(id, level, name)
		
		return name, link
	end,
}

FindIt.spell = {
	name = "Spell",
	max = 100000,
	getInfo = function(self, id)
		local name = GetSpellInfo(id)
		return name, GetSpellRealLink(id)
	end,
}

FindIt.talent = {
	name = "Talent",
	max = 20000,
	getInfo = function(self, id)
		local name, rank = LibWeagleTooltip:GetTooltipLine("talent:" .. id, 1)
		if name == "Word of Recall (OLD)" then return end -- Invalid tooltips' names.. go figure.
		local link = ("|cff4e96f7|Htalent:%i:-1|h[%s]|h|r"):format(id, name)
		
		return name, link
	end,
}

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

function FindIt:FindObject(ftype, msg)
	if not msg or msg == "" then return self:Print("Usage: /find"..ftype.." (id|[min-max]|name) - /findit for help" ) end
	local obj = FindIt[ftype]
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

SLASH_FINDACH1, SLASH_FINDACH2 = "/findach", "/findachievement"
SlashCmdList["FINDACH"] = function(msg)
	FindIt:FindObject("achievement", msg)
end

SLASH_FINDCREATURE1 = "/findcreature"
SlashCmdList["FINDCREATURE"] = function(msg)
	FindIt:FindObject("creature", msg)
end

SLASH_FINDDUNGEON1 = "/finddungeon"
SlashCmdList["FINDDUNGEON"] = function(msg)
	FindIt:FindObject("dungeon", msg)
end

SLASH_FINDENCHANT1 = "/findenchant"
SlashCmdList["FINDENCHANT"] = function(msg)
	FindIt:FindObject("enchant", msg)
end

SLASH_FINDFACTION1 = "/findfaction"
SlashCmdList["FINDFACTION"] = function(msg)
	FindIt:FindObject("faction", msg)
end

SLASH_FINDGLYPH1 = "/findglyph"
SlashCmdList["FINDGLYPH"] = function(msg)
	FindIt:FindObject("glyph", msg)
end

SLASH_FINDINSTANCE1 = "/findinstance"
SlashCmdList["FINDINSTANCE"] = function(msg)
	FindIt:FindObject("instance", msg)
end

SLASH_FINDITEM1 = "/finditem"
SlashCmdList["FINDITEM"] = function(msg)
	if not tonumber(msg) and TOC >= 40000 then
		return FindIt:Print("Non-ID lookups for items are disabled in the 4.x client due to a bug in the WoW API. Blame Blizzard.")
	end
	FindIt:FindObject("item", msg)
end

SLASH_FINDQUEST1 = "/findquest"
SlashCmdList["FINDQUEST"] = function(msg)
	if not tonumber(msg) then
		return FindIt:Print("Non-ID lookups for quests are disabled because they cause disconnects. Blame Blizzard.")
	end
	FindIt:FindObject("quest", msg)
end

SLASH_FINDSPELL1 = "/findspell"
SlashCmdList["FINDSPELL"] = function(msg)
	FindIt:FindObject("spell", msg)
end

SLASH_FINDTALENT1 = "/findtalent"
SlashCmdList["FINDTALENT"] = function(msg)
	FindIt:FindObject("talent", msg)
end

SLASH_FINDTITLE1 = "/findtitle"
SlashCmdList["FINDTITLE"] = function(msg)
	FindIt:FindObject("title", msg)
end
