------------
-- FindIt --
------------
-- Easily scan and match a tooltip's lines
-- Feedback, questions, adys@mmo-champion.com

-- LibWeagleTooltip is licensed under BSD
-- Please read the LICENSE file for details

local WeagleLibTooltip = CreateFrame("GameTooltip", "WeagleLibTooltip", UIParent, "GameTooltipTemplate")
WeagleLibTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
WeagleLibTooltip:SetPoint("CENTER", "UIParent")
WeagleLibTooltip:Hide()

local function settooltiphack(link) -- XXX
	WeagleLibTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
	WeagleLibTooltip:SetHyperlink("spell:1")
	WeagleLibTooltip:Show()
	WeagleLibTooltip:SetHyperlink(link)
end

local function unsettooltiphack() -- XXX
	WeagleLibTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
	WeagleLibTooltip:Hide()
end

function ScanTooltip(link)
	settooltiphack(link)
	
	local lines = WeagleLibTooltip:NumLines()
	local tooltiptxt = ""
	
	for i = 1, lines do
		local left = _G["WeagleLibTooltipTextLeft"..i]:GetText()
		local right = _G["WeagleLibTooltipTextRight"..i]:GetText()
		
		if left then
			tooltiptxt = tooltiptxt .. left
			if right then
				tooltiptxt = tooltiptxt .. "\t" .. right .. "\n"
			else
				tooltiptxt = tooltiptxt .. "\n"
			end
		elseif right then
			tooltiptxt = tooltiptxt .. right .. "\n"
		end
	end
	
	unsettooltiphack()
	return tooltiptxt
end

function GetTooltipLine(link, line, side)
	side = side or "Left"
	settooltiphack(link)
	
	local lines = WeagleLibTooltip:NumLines()
	if line > lines then return unsettooltiphack() end
	
	local text = _G["WeagleLibTooltipText"..side..line]:GetText()
	
	unsettooltiphack()
	return text
end

function GetTooltipLines(link, ...)
	local lines = {}
	settooltiphack(link)
	
	for k,v in pairs({...}) do
		lines[#lines+1] = _G["WeagleLibTooltipTextLeft"..v]:GetText()
	end
	
	unsettooltiphack()
	return unpack(lines)
end
