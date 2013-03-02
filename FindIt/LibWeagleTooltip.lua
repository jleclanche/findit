----------------------
-- LibWeagleTooltip --
----------------------
-- Easily scan and match a tooltip's lines
-- Feedback, questions, jerome.leclanche+weagle@gmail.com

-- LibWeagleTooltip is licensed under MIT
-- Please read the LICENSE file for details


local MAJOR = "LibWeagleTooltip-2.1"
local MINOR = 20

local LibWeagleTooltip, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if not LibWeagleTooltip then return end -- no upgrade needed

LibWeagleTooltip.tt = CreateFrame("GameTooltip", "LWTTooltip", UIParent, "GameTooltipTemplate")

LibWeagleTooltip.tt:SetOwner(UIParent, "ANCHOR_PRESERVE")
LibWeagleTooltip.tt:SetPoint("CENTER", "UIParent")
LibWeagleTooltip.tt:Hide()

function LibWeagleTooltip:Prepare(link)
	self.tt:SetOwner(UIParent, "ANCHOR_PRESERVE")
	self.tt:SetHyperlink("spell:1:LibWeagleTooltip")
	self.tt:Show()
	self.tt:SetHyperlink(link)
end

function LibWeagleTooltip:Hide()
	self.tt:SetOwner(UIParent, "ANCHOR_PRESERVE")
	self.tt:Hide()
end

function LibWeagleTooltip:ScanTooltip(link)
	self:Prepare(link)

	local lines = LWTTooltip:NumLines()
	local tooltiptxt = ""

	for i = 1, lines do
		local left = _G["LWTTooltipTextLeft" .. i]:GetText()
		local right = _G["LWTTooltipTextRight" .. i]:GetText()

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

	self:Hide()
	return tooltiptxt
end

function LibWeagleTooltip:GetTooltipLine(link, line, side)
	side = side or "Left"
	self:Prepare(link)

	local lines = LWTTooltip:NumLines()
	if line > lines then return self:Hide() end

	local text = _G["LWTTooltipText" .. side .. line]:GetText()

	self:Hide()
	return text
end

function LibWeagleTooltip:GetTooltipLines(link, ...)
	local lines = {}
	self:Prepare(link)

	for k,v in pairs({...}) do
		lines[#lines+1] = _G["LWTTooltipTextLeft" .. v]:GetText()
	end

	self:Hide()
	return unpack(lines)
end
