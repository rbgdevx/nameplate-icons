local AddonName, NS = ...

local CreateFrame = CreateFrame
local issecure = issecure
local IsInInstance = IsInInstance
local UnitIsUnit = UnitIsUnit
local UnitIsPlayer = UnitIsPlayer
local UnitIsFriend = UnitIsFriend
local UnitIsEnemy = UnitIsEnemy
-- local UnitCanAttack = UnitCanAttack
-- local UnitHealth = UnitHealth
local UnitClass = UnitClass
-- local UnitReaction = UnitReaction
-- local UnitExists = UnitExists
local pairs = pairs
local UnitAffectingCombat = UnitAffectingCombat
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitTreatAsPlayerForDisplay = UnitTreatAsPlayerForDisplay
local UnitSelectionColor = UnitSelectionColor
local UnitTokenFromGUID = UnitTokenFromGUID
local hooksecurefunc = hooksecurefunc
local UnitGUID = UnitGUID
local select = select
local ipairs = ipairs
local LibStub = LibStub
local next = next
local GetTime = GetTime
-- local UnitPvpClassification = UnitPvpClassification
local GetRaidTargetIndex = GetRaidTargetIndex
local GetUnitName = GetUnitName
local unpack = unpack

local ssplit = string.split
local smatch = string.match
local mrad = math.rad

local IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
local GetNamePlates = C_NamePlate.GetNamePlates
local After = C_Timer.After
local GetUnitTooltip = C_TooltipInfo.GetUnit
-- local GUIDIsPlayer = C_PlayerInfo.GUIDIsPlayer
local SetNamePlateSelfClickThrough = C_NamePlate.SetNamePlateSelfClickThrough
local SetNamePlateFriendlyClickThrough = C_NamePlate.SetNamePlateFriendlyClickThrough
local SetNamePlateEnemyClickThrough = C_NamePlate.SetNamePlateEnemyClickThrough
local SetCVar = C_CVar.SetCVar

local AceConfig = LibStub("AceConfig-4.0")
local AceConfigDialog = LibStub("AceConfigDialog-4.0")

local NameplateIcons = NS.NameplateIcons
local NameplateIconsFrame = NS.NameplateIcons.frame
NameplateIconsFrame.isArena = false
NameplateIconsFrame.inBattleground = false
NameplateIconsFrame.isOutdoors = false
local Quest = NS.Quest

local Healers = {}
local HEALER_CLASS_IDS = {
  [2] = true,
  [5] = true,
  [7] = true,
  [10] = true,
  [11] = true,
  [13] = true,
}
local HEALER_SPECS = {
  ["Restoration Druid"] = 105,
  ["Restoration Shaman"] = 264,
  ["Mistweaver Monk"] = 270,
  ["Holy Priest"] = 257,
  ["Holy Paladin"] = 65,
  ["Discipline Priest"] = 256,
  ["Preservation Evoker"] = 1468,
}

local activeNPCs = {}

local function GetAnchorFrame(nameplate)
  if nameplate.unitFrame then
    if nameplate.unitFrame then
      -- works as Plater internal nameplate.unitFramePlater
      return nameplate.unitFrame.healthBar
    end
  elseif nameplate.UnitFrame then
    if IsAddOnLoaded("TidyPlates_ThreatPlates") then
      local tFrame = nameplate.TPFrame
      if tFrame then
        return tFrame
      end
    elseif IsAddOnLoaded("Kui_Nameplates") then
      local kFrame = nameplate.kui
      if kFrame then
        return kFrame
      end
    elseif IsAddOnLoaded("TidyPlates") then
      local tFrame = nameplate.extended
      if tFrame then
        return tFrame
      end
    elseif IsAddOnLoaded("NeatPlates") then
      local nFrame = nameplate.extended
      if nFrame then
        return nFrame
      end
    elseif nameplate.UnitFrame.HealthBarsContainer then
      -- does not work as NeatPlates internal nameplate.extended
      return nameplate.UnitFrame.HealthBarsContainer
    elseif nameplate.UnitFrame.healthBar then
      -- does not work as NeatPlates internal nameplate.extended
      return nameplate.UnitFrame.healthBar
    else
      -- works as NeatPlates internal nameplate.extended
      -- does not work as TidyPlates internal nameplate.extended
      -- does not work as Kui_Nameplates internal nameplate.kui
      -- does not work as TidyPlates_ThreatPlates internal nameplate.TPFrame
      return nameplate.UnitFrame
    end
  else
    return nameplate
  end
end

local function GetTextureCoord(region, texWidth, aspectRatio, xOffset, yOffset)
  region.currentCoord = region.currentCoord or {}

  local usesMasque = false
  if not usesMasque then
    region.currentCoord[1], region.currentCoord[2], region.currentCoord[3], region.currentCoord[4], region.currentCoord[5], region.currentCoord[6], region.currentCoord[7], region.currentCoord[8] =
      0, 0, 0, 1, 1, 0, 1, 1
  end

  local xRatio = aspectRatio < 1 and aspectRatio or 1
  local yRatio = aspectRatio > 1 and 1 / aspectRatio or 1
  for i, coord in ipairs(region.currentCoord) do
    if i % 2 == 1 then
      region.currentCoord[i] = (coord - 0.5) * texWidth * xRatio + 0.5 - xOffset
    else
      region.currentCoord[i] = (coord - 0.5) * texWidth * yRatio + 0.5 - yOffset
    end
  end

  return unpack(region.currentCoord)
end

local function checkIsHealer(nameplate, guid)
  local unit = nameplate.namePlateUnitToken

  local isPlayer = UnitIsPlayer(unit)
  local _, _, classId = UnitClass(unit)
  local canBeHealer = classId ~= nil and HEALER_CLASS_IDS[classId] == true

  if not isPlayer or not canBeHealer or Healers[guid] == true then
    return
  end

  local tooltipData = GetUnitTooltip(unit)
  if tooltipData then
    if
      tooltipData.guid
      and tooltipData.lines
      and #tooltipData.lines >= 3
      and tooltipData.type == Enum.TooltipDataType.Unit
    then
      for _, line in ipairs(tooltipData.lines) do
        if line and line.type == Enum.TooltipDataLineType.None then
          if line.leftText and line.leftText ~= "" then
            if Healers[tooltipData.guid] and HEALER_SPECS[line.leftText] then
              break
            end
            if Healers[tooltipData.guid] and not HEALER_SPECS[line.leftText] then
              Healers[tooltipData.guid] = nil
              break
            end
            if not Healers[tooltipData.guid] and HEALER_SPECS[line.leftText] then
              Healers[tooltipData.guid] = true
              break
            end
          end
        end
      end
    end
  end
end

local function instanceCheck()
  local inInstance, instanceType = IsInInstance()
  NameplateIconsFrame.inArena = inInstance and (instanceType == "arena")
  NameplateIconsFrame.inBattleground = inInstance and (instanceType == "pvp")
  NameplateIconsFrame.isOutdoors = not inInstance and (instanceType == "none")
end

local function hideBuffFrames(nameplate, guid)
  if not nameplate.UnitFrame.BuffFrame then
    return
  end

  local unit = nameplate.namePlateUnitToken

  local isMe = UnitIsUnit(unit, "player")
  local isPlayer = UnitIsPlayer(unit)
  local isNPC = not isPlayer
  local isFriend = UnitIsFriend("player", unit)
  local isEnemy = UnitIsEnemy("player", unit)
  local isArena = NameplateIconsFrame.inArena
  local isBattleground = NameplateIconsFrame.inBattleground
  local isOutdoors = NameplateIconsFrame.isOutdoors

  local hideFriendly = NS.db.nameplate.buffFrames.hideFriendly and (isFriend and isPlayer and not isMe)
  local hideEnemy = NS.db.nameplate.buffFrames.hideEnemy and (isEnemy and isPlayer)
  local hideNPC = NS.db.nameplate.buffFrames.hideNPC and isNPC
  local hideBuffFrame = hideFriendly or hideEnemy or hideNPC
  local hideOutsideArena = not NS.db.nameplate.showArena and isArena
  local hideOutsideBattleground = not NS.db.nameplate.showBattleground and isBattleground
  local hideOutside = not NS.db.nameplate.showOutdoors and isOutdoors
  local hideLocation = true
  if isArena then
    hideLocation = hideOutsideArena
  elseif isBattleground then
    hideLocation = hideOutsideBattleground
  elseif isOutdoors then
    hideLocation = hideOutside
  end

  if hideLocation then
    nameplate.UnitFrame.BuffFrame:SetAlpha(1)
    return
  end

  if hideBuffFrame then
    nameplate.UnitFrame.BuffFrame:SetAlpha(0)
  else
    nameplate.UnitFrame.BuffFrame:SetAlpha(1)
  end
end

local function hideCastBars(nameplate, guid)
  if not nameplate.UnitFrame.castBar then
    return
  end

  local unit = nameplate.namePlateUnitToken

  local isMe = UnitIsUnit(unit, "player")
  local isPlayer = UnitIsPlayer(unit)
  local isNPC = not isPlayer
  local isFriend = UnitIsFriend("player", unit)
  local isEnemy = UnitIsEnemy("player", unit)
  local isArena = NameplateIconsFrame.inArena
  local isBattleground = NameplateIconsFrame.inBattleground
  local isOutdoors = NameplateIconsFrame.isOutdoors

  local hideFriendly = NS.db.nameplate.castBars.hideFriendly and (isFriend and isPlayer and not isMe)
  local hideEnemy = NS.db.nameplate.castBars.hideEnemy and (isEnemy and isPlayer)
  local hideNPC = NS.db.nameplate.castBars.hideNPC and isNPC
  local hideCastBar = hideFriendly or hideEnemy or hideNPC
  local hideOutsideArena = not NS.db.nameplate.showArena and isArena
  local hideOutsideBattleground = not NS.db.nameplate.showBattleground and isBattleground
  local hideOutside = not NS.db.nameplate.showOutdoors and isOutdoors
  local hideLocation = true
  if isArena then
    hideLocation = hideOutsideArena
  elseif isBattleground then
    hideLocation = hideOutsideBattleground
  elseif isOutdoors then
    hideLocation = hideOutside
  end

  if hideLocation then
    -- nameplate.UnitFrame.castBar:Show()
    return
  end

  if hideCastBar then
    nameplate.UnitFrame.castBar:Hide()
    -- else
    --   nameplate.UnitFrame.castBar:Show()
  end
end

local function hideServers(nameplate, guid)
  if not nameplate.UnitFrame.name then
    return
  end

  local unit = nameplate.namePlateUnitToken

  local isPlayer = UnitIsPlayer(unit)
  local isArena = NameplateIconsFrame.inArena
  local isBattleground = NameplateIconsFrame.inBattleground
  local isOutdoors = NameplateIconsFrame.isOutdoors

  local hideServerName = NS.db.general.hideServerName and isPlayer
  local hideOutsideArena = not NS.db.nameplate.showArena and isArena
  local hideOutsideBattleground = not NS.db.nameplate.showBattleground and isBattleground
  local hideOutside = not NS.db.nameplate.showOutdoors and isOutdoors
  local hideLocation = true
  if isArena then
    hideLocation = hideOutsideArena
  elseif isBattleground then
    hideLocation = hideOutsideBattleground
  elseif isOutdoors then
    hideLocation = hideOutside
  end

  local nameWithServer = GetUnitName(unit, true)

  if not nameWithServer then
    return
  end

  -- Don't Show Different Realm Indicator (*)
  local nameWithoutIndicator = nameWithServer:match("[^-]+")
  -- Show Different Realm Indicator (*)
  local nameWithIndicator = GetUnitName(unit, false)

  if hideLocation then
    nameplate.UnitFrame.name:SetText(nameWithServer)
    return
  end

  if hideServerName then
    nameplate.UnitFrame.name:SetText(NS.db.general.showRealmIndicator and nameWithIndicator or nameWithoutIndicator)
  else
    nameplate.UnitFrame.name:SetText(nameWithServer)
  end
end

local function hideNames(nameplate, guid)
  if not nameplate.UnitFrame.name then
    return
  end

  local unit = nameplate.namePlateUnitToken

  local isPlayer = UnitIsPlayer(unit)
  local isNPC = not isPlayer
  local isFriend = UnitIsFriend("player", unit)
  local isEnemy = UnitIsEnemy("player", unit)
  local isArena = NameplateIconsFrame.inArena
  local isBattleground = NameplateIconsFrame.inBattleground
  local isOutdoors = NameplateIconsFrame.isOutdoors

  local isMe = UnitIsUnit(unit, "player")
  local hideFriendly = NS.db.nameplate.names.hideFriendly and (isFriend and isPlayer and not isMe)
  local hideEnemy = NS.db.nameplate.names.hideEnemy and (isEnemy and isPlayer)
  local hideNPC = NS.db.nameplate.names.hideNPC and isNPC
  local hideName = hideFriendly or hideEnemy or hideNPC
  local hideOutsideArena = not NS.db.nameplate.showArena and isArena
  local hideOutsideBattleground = not NS.db.nameplate.showBattleground and isBattleground
  local hideOutside = not NS.db.nameplate.showOutdoors and isOutdoors
  local hideLocation = true
  if isArena then
    hideLocation = hideOutsideArena
  elseif isBattleground then
    hideLocation = hideOutsideBattleground
  elseif isOutdoors then
    hideLocation = hideOutside
  end

  if hideLocation then
    nameplate.UnitFrame.name:SetAlpha(1)
    return
  end

  if hideName then
    nameplate.UnitFrame.name:SetAlpha(0)
  else
    nameplate.UnitFrame.name:SetAlpha(1)
  end
end

local function hideHealthBars(nameplate, guid)
  if not nameplate.UnitFrame.HealthBarsContainer then
    return
  end

  local unit = nameplate.namePlateUnitToken

  local isMe = UnitIsUnit(unit, "player")
  local isPlayer = UnitIsPlayer(unit)
  local isNPC = not isPlayer
  local isFriend = UnitIsFriend("player", unit)
  local isEnemy = UnitIsEnemy("player", unit)
  local isArena = NameplateIconsFrame.inArena
  local isBattleground = NameplateIconsFrame.inBattleground
  local isOutdoors = NameplateIconsFrame.isOutdoors

  local hideFriendly = NS.db.nameplate.healthBars.hideFriendly and (isFriend and isPlayer and not isMe)
  local hideEnemy = NS.db.nameplate.healthBars.hideEnemy and (isEnemy and isPlayer)
  local hideNPC = NS.db.nameplate.healthBars.hideNPC and isNPC
  local hideHealthBar = hideFriendly or hideEnemy or hideNPC
  local hideOutsideArena = not NS.db.nameplate.showArena and isArena
  local hideOutsideBattleground = not NS.db.nameplate.showBattleground and isBattleground
  local hideOutside = not NS.db.nameplate.showOutdoors and isOutdoors
  local hideLocation = true
  if isArena then
    hideLocation = hideOutsideArena
  elseif isBattleground then
    hideLocation = hideOutsideBattleground
  elseif isOutdoors then
    hideLocation = hideOutside
  end

  if hideLocation then
    nameplate.UnitFrame.HealthBarsContainer:SetAlpha(1)
    nameplate.UnitFrame.selectionHighlight:SetAlpha(0.25)
    return
  end

  if hideHealthBar then
    nameplate.UnitFrame.HealthBarsContainer:SetAlpha(0)
    nameplate.UnitFrame.selectionHighlight:SetAlpha(0)
  else
    nameplate.UnitFrame.HealthBarsContainer:SetAlpha(1)
    nameplate.UnitFrame.selectionHighlight:SetAlpha(0.25)
  end
end

local function GetClassIcon(unit)
  local _, classFilename = UnitClass(unit)
  local _, fallbackFilename = UnitClass("player")
  local start = "interface/icons/classicon_"
  local middle = classFilename and classFilename:lower() or fallbackFilename:lower()
  local ending = ".blp"
  return start .. middle .. ending
end

-- local function GetClassCoords(unit)
--   local _, class = UnitClass(unit)
--   local coords = CLASS_ICON_TCOORDS[class]
--   return coords
-- end

local function GetClassColor(nameplate, unit)
  local _, class = UnitClass(unit)
  local colors = RAID_CLASS_COLORS[class]
  if (UnitIsPlayer(unit) or UnitTreatAsPlayerForDisplay(unit)) and colors then
    return colors.r, colors.g, colors.b, 1.0
  elseif CompactUnitFrame_IsTapDenied(nameplate.UnitFrame) then
    return 0.9, 0.9, 0.9, 1.0
  elseif CompactUnitFrame_IsOnThreatListWithPlayer(unit) and not UnitIsFriend("player", unit) then
    return 1.0, 0.0, 0.0, 1.0
  elseif UnitIsPlayer(unit) and UnitIsFriend("player", unit) then
    return 0.66, 0.66, 1.0, 1.0
  else
    local resultR, resultG, resultB, resultA = UnitSelectionColor(unit, true)
    return resultR, resultG, resultB, resultA
  end
end

local iconSize = 16

local function CreateNPCCooldown(parent, texture)
  local cooldown = CreateFrame("Cooldown", "NPCCooldownFrame" .. texture, parent, "CooldownFrameTemplate")
  local newIconSize = iconSize * NS.db.npc.scale
  cooldown:SetSize(newIconSize, newIconSize)
  cooldown:SetAllPoints(parent)
  cooldown:SetFrameStrata(parent:GetFrameStrata())
  cooldown:SetFrameLevel(parent:GetFrameLevel())
  cooldown:SetReverse(true)
  cooldown:SetDrawSwipe(true)
  cooldown:SetDrawEdge(true)
  cooldown:Hide()

  local loadedOrLoading, loaded = IsAddOnLoaded("OmniCC")
  if not loaded and not loadedOrLoading then
    cooldown:SetHideCountdownNumbers(false)
  else
    cooldown:SetHideCountdownNumbers(true)
  end

  parent.cooldown = cooldown
end

local function CreateNPCGlow(parent, texture)
  local glow = CreateFrame("Frame", "NPCGlowFrame" .. texture, parent)
  local newIconSize = iconSize * NS.db.npc.scale
  glow:SetSize(newIconSize, newIconSize)
  glow:SetAllPoints(parent)
  glow:SetFrameStrata(parent:GetFrameStrata())
  glow:SetFrameLevel(parent:GetFrameLevel() + 8)
  glow:Hide()

  local glowTexture = parent:CreateTexture(nil, "OVERLAY")
  glowTexture:SetBlendMode("BLEND")
  glowTexture:SetDesaturated(true)
  glowTexture:SetAtlas("clickcast-highlight-spellbook")

  local offsetMultiplier = 0.45
  local widthOffset = newIconSize * offsetMultiplier
  local heightOffset = (newIconSize + 1) * offsetMultiplier

  glowTexture:ClearAllPoints()
  glowTexture:SetPoint("TOPLEFT", glow, "TOPLEFT", -widthOffset, widthOffset)
  glowTexture:SetPoint("BOTTOMRIGHT", glow, "BOTTOMRIGHT", heightOffset, -heightOffset)
  glowTexture:SetAlpha(0)

  parent.glow = glow
  parent.glowTexture = glowTexture
end

local function CreateNPCTexture(parent, _texture)
  local texture = parent:CreateTexture(nil, "BACKGROUND")
  local newIconSize = iconSize * NS.db.npc.scale
  texture:SetSize(newIconSize, newIconSize)
  texture:SetAllPoints(parent)
  texture:SetTexture(_texture)

  local zoom = 0.20
  local textureWidth = 1 - 0.5 * zoom
  local ulx, uly, llx, lly, urx, ury, lrx, lry = GetTextureCoord(texture, textureWidth, 1, 0, 0)
  texture:SetTexCoord(ulx, uly, llx, lly, urx, ury, lrx, lry)

  parent.texture = texture
end

local function CreateNPCIcon(parent, texture)
  local icon = CreateFrame("Frame", "NPCIconFrame" .. texture, parent)
  local newIconSize = iconSize * NS.db.npc.scale
  icon:SetSize(newIconSize, newIconSize)

  CreateNPCTexture(icon, texture)
  CreateNPCGlow(icon, texture)
  CreateNPCCooldown(icon, texture)

  return icon
end

local function CreateClassBorder(nameplate, parent)
  local border = parent:CreateTexture(nil, "OVERLAY")
  border:SetAtlas("ui-frame-genericplayerchoice-portrait-border")
  -- border:SetAtlas("auctionhouse-itemicon-border-account")
  local offsetMultiplier = 0 -- 0.25
  local newIconSize = iconSize * NS.db.class.scale
  local widthOffset = newIconSize * offsetMultiplier
  local heightOffset = (newIconSize + 1) * offsetMultiplier
  border:SetPoint("TOPLEFT", parent, "TOPLEFT", -widthOffset, widthOffset)
  border:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", heightOffset, -heightOffset)
  border:SetBlendMode("BLEND")
  border:SetDesaturated(true)

  local r, g, b, a = GetClassColor(nameplate, nameplate.namePlateUnitToken)
  if r and g and b and a then
    border:SetVertexColor(r, g, b, a)
  end

  parent.border = border
end

local function CreateClassMask(parent)
  local mask = parent:CreateMaskTexture()
  local newIconSize = iconSize * NS.db.class.scale
  mask:SetTexture("Interface/Masks/CircleMaskScalable")
  mask:SetSize(newIconSize, newIconSize)
  mask:SetAllPoints(parent.texture)

  parent.texture:AddMaskTexture(mask)
  parent.mask = mask
end

local function CreateClassTexture(nameplate, parent)
  local texture = parent:CreateTexture(nil, "BORDER")
  local newIconSize = iconSize * NS.db.class.scale
  texture:SetSize(newIconSize, newIconSize)
  texture:SetAllPoints(parent)
  -- texture:SetTexture("Interface/GLUES/CHARACTERCREATE/UI-CHARACTERCREATE-CLASSES")
  local texturePath = GetClassIcon(nameplate.namePlateUnitToken)
  texture:SetTexture(texturePath)

  -- local coords = GetClassCoords(nameplate.namePlateUnitToken)
  -- if coords then
  --   texture:SetTexCoord(unpack(coords))
  -- end

  local zoom = 0
  local textureWidth = 1 - 0.5 * zoom
  local ulx, uly, llx, lly, urx, ury, lrx, lry = GetTextureCoord(texture, textureWidth, 1, 0, 0)
  texture:SetTexCoord(ulx, uly, llx, lly, urx, ury, lrx, lry)

  parent.texture = texture
end

local function CreateClassIcon(nameplate, parent, texture)
  local icon = CreateFrame("Frame", "ClassIconFrame" .. texture, parent)
  local newIconSize = iconSize * NS.db.class.scale
  icon:SetSize(newIconSize, newIconSize)
  icon:SetAllPoints(parent)
  icon:Hide()

  CreateClassTexture(nameplate, icon)
  CreateClassMask(icon)
  CreateClassBorder(nameplate, icon)

  return icon
end

local function CreateArrowTexture(nameplate, parent)
  local texture = parent:CreateTexture(nil, "OVERLAY")
  local iconWidth = 55
  local iconHeight = 70
  local newIconWidth = iconWidth * NS.db.arrow.scale
  local newIconHeight = iconHeight * NS.db.arrow.scale
  texture:SetSize(newIconWidth, newIconHeight)
  texture:SetAllPoints(parent)
  texture:SetAtlas("covenantsanctum-renown-doublearrow-depressed")
  texture:SetDesaturated(true)
  texture:SetBlendMode("BLEND")

  local r, g, b, a = GetClassColor(nameplate, nameplate.namePlateUnitToken)
  if r and g and b and a then
    texture:SetVertexColor(r, g, b, a)
  end

  local degrees = 90
  local radians = mrad(degrees)
  texture:SetRotation(radians)

  parent.texture = texture
end

local function CreateArrowIcon(nameplate, parent, texture)
  local icon = CreateFrame("Frame", "ArrowIconFrame" .. texture, parent)
  local iconWidth = 55
  local iconHeight = 70
  local newIconWidth = iconWidth * NS.db.arrow.scale
  local newIconHeight = iconHeight * NS.db.arrow.scale
  icon:SetSize(newIconWidth, newIconHeight)
  icon:SetAllPoints(parent)
  icon:Hide()

  CreateArrowTexture(nameplate, icon)

  return icon
end

local function CreateHealerTexture(nameplate, parent)
  local texture = parent:CreateTexture(nil, "OVERLAY")
  local newIconSize = iconSize * NS.db.healer.scale
  texture:SetSize(newIconSize, newIconSize)
  texture:SetAllPoints(parent)
  texture:SetAtlas("roleicon-tiny-healer")
  texture:SetDesaturated(false)

  parent.texture = texture
end

local function CreateHealerIcon(nameplate, parent, texture)
  local icon = CreateFrame("Frame", "HealerIconFrame" .. texture, parent)
  local newIconSize = iconSize * NS.db.healer.scale
  icon:SetSize(newIconSize, newIconSize)
  icon:SetAllPoints(parent)
  icon:Hide()

  CreateHealerTexture(nameplate, icon)

  return icon
end

-- local objectiveAtlas = {
-- 	[-1] = "Warlock-ReadyShard", -- deephaul crystal - 17x22
-- 	[0] = "ColumnIcon-FlagCapture1", -- horde flag - 32
-- 	[1] = "ColumnIcon-FlagCapture0", -- alliance flag - 32
-- 	[2] = "ColumnIcon-FlagCapture2", -- eots flag - 32
-- 	[3] = "nameplates-icon-cart-horde", -- horde cart - 32
-- 	[4] = "nameplates-icon-cart-alliance", -- alliance cart - 32
-- 	[5] = "nameplates-icon-bounty-horde", -- horde assassin - 21x20
-- 	[6] = "nameplates-icon-bounty-alliance", -- alliance assassin - 21x20
-- 	[7] = "nameplates-icon-orb-blue", -- blue orb - 26
-- 	[8] = "nameplates-icon-orb-green", -- green orb - 26
-- 	[9] = "nameplates-icon-orb-orange", -- orange orb - 26
-- 	[10] = "nameplates-icon-orb-purple", -- purple orb - 26
-- }
-- local objectiveSize = {
-- 	[-1] = { 17, 22 },
-- 	[0] = { 32, 32 },
-- 	[1] = { 32, 32 },
-- 	[2] = { 32, 32 },
-- 	[3] = { 32, 32 },
-- 	[4] = { 32, 32 },
-- 	[5] = { 21, 20 },
-- 	[6] = { 21, 20 },
-- 	[7] = { 26, 26 },
-- 	[8] = { 26, 26 },
-- 	[9] = { 26, 26 },
-- 	[10] = { 26, 26 },
-- }

-- local function CreateObjectiveTexture(nameplate, parent)
-- 	local texture = parent:CreateTexture(nil, "OVERLAY")
-- 	local objective = UnitPvpClassification(nameplate.namePlateUnitToken)
-- 	local realObjective = C_Map.GetBestMapForUnit("player") == 2345 and -1 or objective
-- 	local newIconSize = objectiveSize[realObjective]
-- 	local newIconWidth = newIconSize[1] * NS.db.objective.scale
-- 	local newIconHeight = newIconSize[2] * NS.db.objective.scale
-- 	local atlas = objectiveAtlas[realObjective]
-- 	texture:SetSize(newIconWidth, newIconHeight)
-- 	texture:SetAllPoints(parent)
-- 	texture:SetAtlas(atlas)
-- 	texture:SetDesaturated(realObjective == 2)

-- 	parent.texture = texture
-- end

-- local function CreateObjectiveIcon(nameplate, parent, texture)
-- 	local icon = CreateFrame("Frame", "ObjectiveIconFrame" .. texture, parent)
-- 	local newIconSize = iconSize * NS.db.objective.scale
-- 	icon:SetSize(newIconSize, newIconSize)
-- 	icon:SetAllPoints(parent)
-- 	icon:Hide()

-- 	CreateObjectiveTexture(nameplate, icon)

-- 	return icon
-- end

local function CreateQuestTexture(nameplate, parent)
  local texture = parent:CreateTexture(nil, "OVERLAY")
  local newIconSize = iconSize * NS.db.quest.scale
  texture:SetSize(newIconSize, newIconSize)
  texture:SetAllPoints(parent)
  texture:SetAtlas("Crosshair_Quest_48")
  texture:SetDesaturated(false)

  parent.texture = texture
end

local function CreateQuestIcon(nameplate, parent, texture)
  local icon = CreateFrame("Frame", "ArenaIconFrame" .. texture, parent)
  local newIconSize = iconSize * NS.db.quest.scale
  icon:SetSize(newIconSize, newIconSize)
  icon:SetAllPoints(parent)
  icon:Hide()

  CreateQuestTexture(nameplate, icon)

  return icon
end

local markerIconSize = 22
local markerCoords = {
  [1] = { 0, 0, 0, 0.25, 0.25, 0, 0.25, 0.25 }, -- star
  [2] = { 0.25, 0, 0.25, 0.25, 0.5, 0, 0.5, 0.25 }, -- circle
  [3] = { 0.5, 0, 0.5, 0.25, 0.75, 0, 0.75, 0.25 }, -- diamond
  [4] = { 0.75, 0, 0.75, 0.25, 1, 0, 1, 0.25 }, -- triangle
  [5] = { 0, 0.25, 0, 0.5, 0.25, 0.25, 0.25, 0.5 }, -- moon
  [6] = { 0.25, 0.25, 0.25, 0.5, 0.5, 0.25, 0.5, 0.5 }, -- square
  [7] = { 0.5, 0.25, 0.5, 0.5, 0.75, 0.25, 0.75, 0.5 }, -- cross
  [8] = { 0.75, 0.25, 0.75, 0.5, 1, 0.25, 1, 0.5 }, -- skull
}

local function CreateMarkerTexture(nameplate, parent, markerIndex)
  local texture = parent:CreateTexture(nil, "OVERLAY")
  local newIconSize = markerIconSize * NS.db.marker.scale

  if not markerCoords[markerIndex] then
    return
  end

  texture:SetSize(newIconSize, newIconSize)
  texture:SetAllPoints(parent)
  texture:SetTexture("137009")
  texture:SetTexCoord(unpack(markerCoords[markerIndex]))
  texture:SetDesaturated(false)

  parent.texture = texture
end

local function CreateMarkerIcon(nameplate, parent, name, markerIndex)
  local icon = CreateFrame("Frame", "ArenaIconFrame" .. name, parent)
  local newIconSize = markerIconSize * NS.db.marker.scale
  icon:SetSize(newIconSize, newIconSize)
  icon:SetAllPoints(parent)
  icon:Hide()

  CreateMarkerTexture(nameplate, icon, markerIndex)

  return icon
end

local function addQuestIndicator(nameplate, guid)
  local unit = nameplate.namePlateUnitToken

  local isPlayer = UnitIsPlayer(unit)
  local isSelf = UnitIsUnit(unit, "player")
  local isDeadOrGhost = UnitIsDeadOrGhost(unit)

  local hideDead = isDeadOrGhost
  local hidePlayers = isPlayer
  local hideSelf = isSelf
  local hideQuestUnits = not NS.IsPlayerQuestUnit(unit)
  local hideTestMode = not NS.db.quest.test
  local hideQuestIndicator = hideTestMode and (hideDead or hidePlayers or hideSelf or hideQuestUnits)

  if hideQuestIndicator then
    if nameplate.npiQuestIndicator ~= nil then
      nameplate.npiQuestIndicator:Hide()
    end
    return
  end

  if not nameplate.npiQuestIndicator then
    nameplate.npiQuestIndicator = CreateQuestIcon(nameplate, nameplate.rbgdAnchorFrame, "quest")
  end

  nameplate.npiQuestIndicator:SetIgnoreParentScale(NS.db.general.ignoreNameplateScale)
  nameplate.npiQuestIndicator:SetIgnoreParentAlpha(NS.db.general.ignoreNameplateAlpha)

  local newIconSize = iconSize * NS.db.quest.scale
  nameplate.npiQuestIndicator:SetSize(newIconSize, newIconSize)

  local offset = {
    x = NS.db.quest.offsetX,
    y = NS.db.quest.offsetY,
  }
  local horizontalPoint = NS.db.quest.position == "LEFT" and "RIGHT" or "LEFT"
  local point = NS.db.quest.position == "TOP" and "BOTTOM" or horizontalPoint
  local horizontalRelativePoint = NS.db.quest.position == "LEFT" and "LEFT" or "RIGHT"
  local relativePoint = NS.db.quest.position == "TOP" and "TOP" or horizontalRelativePoint
  local relativeTo = NS.db.quest.attachToHealthBar and GetAnchorFrame(nameplate) or nameplate
  nameplate.npiQuestIndicator:ClearAllPoints()
  -- point, relativeTo, relativePoint, x, y
  nameplate.npiQuestIndicator:SetPoint(point, relativeTo, relativePoint, offset.x, offset.y)
  nameplate.npiQuestIndicator:Show()
end

local function addNPCIndicator(nameplate, guid)
  local unit = nameplate.namePlateUnitToken

  local isPlayer = UnitIsPlayer(unit)
  -- local isNPC = not isPlayer
  local isSelf = UnitIsUnit(unit, "player")
  local isFriend = UnitIsFriend("player", unit)
  local isEnemy = UnitIsEnemy("player", unit)
  local isDeadOrGhost = UnitIsDeadOrGhost(unit)
  local isArena = NameplateIconsFrame.inArena
  local isBattleground = NameplateIconsFrame.inBattleground
  local isOutdoors = NameplateIconsFrame.isOutdoors

  local npcID = select(6, ssplit("-", guid))
  local hideDead = isDeadOrGhost
  local hideSelf = isSelf
  local hidePlayers = isPlayer
  local hideFriendly = NS.db.npc.showFriendly == false and isFriend
  local hideEnemy = NS.db.npc.showEnemy == false and isEnemy
  local hideNotInList = NS.isNPCInList(NS.NPC_SHOW_LIST, npcID) ~= true
  local hideNotEnabled = not NS.db.npcs[npcID] or NS.db.npcs[npcID].enabled ~= true
  local hideOutsideArena = not NS.db.npc.showArena and isArena
  local hideOutsideBattleground = not NS.db.npc.showBattleground and isBattleground
  local hideOutside = not NS.db.npc.showOutdoors and isOutdoors
  local hideLocation = true
  if isArena then
    hideLocation = hideOutsideArena
  elseif isBattleground then
    hideLocation = hideOutsideBattleground
  elseif isOutdoors then
    hideLocation = hideOutside
  end
  local notTestMode = not NS.db.npc.test
  local hideNPCIndicator = notTestMode
    and (
      hideNotInList
      or hideNotEnabled
      or hideDead
      or hideSelf
      or hidePlayers
      or hideFriendly
      or hideEnemy
      or hideLocation
    )

  if hideNPCIndicator then
    if nameplate.npiNPCIndicator then
      nameplate.npiNPCIndicator:Hide()
    end
    return
  end

  local npcId = NS.db.npc.test and "104818" or npcID
  local npcIcon = NS.db.npcs[npcId].icon
  local npcGlow = NS.db.npcs[npcId].glow
  local glowEnabled = NS.db.npcs[npcId].enableGlow == true
  local countdownEnabled = NS.db.npc.showCountdown == true
  local changeHealthbarColor = NS.db.npcs[npcId].healthColor == true
  local changeNameColor = NS.db.npcs[npcId].nameColor == true
  local npcDuration = NS.db.npcs[npcId].duration

  if not nameplate.npiNPCIndicator then
    nameplate.npiNPCIndicator = CreateNPCIcon(nameplate, npcIcon)
  end

  local offset = {
    x = NS.db.npc.offsetX,
    y = NS.db.npc.offsetY,
  }
  local newIconSize = iconSize * NS.db.npc.scale
  local horizontalPoint = NS.db.npc.position == "LEFT" and "RIGHT" or "LEFT"
  local point = NS.db.npc.position == "TOP" and "BOTTOM" or horizontalPoint
  local horizontalRelativePoint = NS.db.npc.position == "LEFT" and "LEFT" or "RIGHT"
  local relativePoint = NS.db.npc.position == "TOP" and "TOP" or horizontalRelativePoint
  local relativeTo = NS.db.npc.attachToHealthBar and GetAnchorFrame(nameplate) or nameplate
  nameplate.npiNPCIndicator:SetSize(newIconSize, newIconSize)
  nameplate.npiNPCIndicator:ClearAllPoints()
  -- point, relativeTo, relativePoint, x, y
  nameplate.npiNPCIndicator:SetPoint(point, relativeTo, relativePoint, offset.x, offset.y)
  nameplate.npiNPCIndicator:Show()

  do
    local showArenas = NS.db.nameplate.showArena and isArena
    local showBattlegrounds = NS.db.nameplate.showBattleground and isBattleground
    local showOutdoors = NS.db.nameplate.showOutdoors and isOutdoors

    nameplate.npiNPCIndicator.texture:SetIgnoreParentScale(NS.db.general.ignoreNameplateScale)
    -- NEED TO CHANGE THIS TO IGNORE ALPHA WHEN HIDING HEALTHBARS
    if showArenas or showBattlegrounds or showOutdoors then
      if isFriend and NS.db.nameplate.healthBars.hideFriendly then
        nameplate.npiNPCIndicator.texture:SetIgnoreParentAlpha(true)
      elseif isEnemy and NS.db.nameplate.healthBars.hideEnemy then
        nameplate.npiNPCIndicator.texture:SetIgnoreParentAlpha(true)
      else
        nameplate.npiNPCIndicator.texture:SetIgnoreParentAlpha(NS.db.general.ignoreNameplateAlpha)
      end
    else
      nameplate.npiNPCIndicator.texture:SetIgnoreParentAlpha(NS.db.general.ignoreNameplateAlpha)
    end

    nameplate.npiNPCIndicator.texture:SetSize(newIconSize, newIconSize)
    nameplate.npiNPCIndicator.texture:ClearAllPoints()
    nameplate.npiNPCIndicator.texture:SetAllPoints(nameplate.npiNPCIndicator)
    nameplate.npiNPCIndicator.texture:SetTexture(npcIcon)

    nameplate.npiNPCIndicator.glow:SetSize(newIconSize, newIconSize)
    nameplate.npiNPCIndicator.glow:ClearAllPoints()
    nameplate.npiNPCIndicator.glow:SetAllPoints(nameplate.npiNPCIndicator)
    if glowEnabled then
      nameplate.npiNPCIndicator.glow:Show()
    else
      nameplate.npiNPCIndicator.glow:Hide()
    end

    local offsetMultiplier = 0.45
    local widthOffset = newIconSize * offsetMultiplier
    local heightOffset = (newIconSize + 1) * offsetMultiplier

    nameplate.npiNPCIndicator.glowTexture:SetIgnoreParentScale(NS.db.general.ignoreNameplateScale)
    -- NEED TO CHANGE THIS TO IGNORE ALPHA WHEN HIDING HEALTHBARS
    if showArenas or showBattlegrounds or showOutdoors then
      if isFriend and NS.db.nameplate.healthBars.hideFriendly then
        nameplate.npiNPCIndicator.glowTexture:SetIgnoreParentAlpha(true)
      elseif isEnemy and NS.db.nameplate.healthBars.hideEnemy then
        nameplate.npiNPCIndicator.glowTexture:SetIgnoreParentAlpha(true)
      else
        nameplate.npiNPCIndicator.glowTexture:SetIgnoreParentAlpha(NS.db.general.ignoreNameplateAlpha)
      end
    else
      nameplate.npiNPCIndicator.glowTexture:SetIgnoreParentAlpha(NS.db.general.ignoreNameplateAlpha)
    end

    nameplate.npiNPCIndicator.glowTexture:SetVertexColor(npcGlow[1], npcGlow[2], npcGlow[3], npcGlow[4])
    if changeHealthbarColor then
      nameplate.UnitFrame.HealthBarsContainer.healthBar:SetStatusBarColor(
        npcGlow[1],
        npcGlow[2],
        npcGlow[3],
        npcGlow[4]
      )
    else
      CompactUnitFrame_UpdateHealthColor(nameplate.UnitFrame)
    end
    if changeNameColor then
      nameplate.UnitFrame.name:SetVertexColor(npcGlow[1], npcGlow[2], npcGlow[3], npcGlow[4])
    else
      CompactUnitFrame_UpdateName(nameplate.UnitFrame)
    end
    nameplate.npiNPCIndicator.glowTexture:SetAlpha(glowEnabled and 1 or 0)
    nameplate.npiNPCIndicator.glowTexture:ClearAllPoints()
    nameplate.npiNPCIndicator.glowTexture:SetPoint(
      "TOPLEFT",
      nameplate.npiNPCIndicator.glow,
      "TOPLEFT",
      -widthOffset,
      widthOffset
    )
    nameplate.npiNPCIndicator.glowTexture:SetPoint(
      "BOTTOMRIGHT",
      nameplate.npiNPCIndicator.glow,
      "BOTTOMRIGHT",
      heightOffset,
      -heightOffset
    )

    -- local _horizontalPoint = NS.db.npc.position == "LEFT" and "RIGHT" or "LEFT"
    -- local _point = NS.db.npc.position == "TOP" and "BOTTOM" or _horizontalPoint
    -- local _horizontalRelativePoint = NS.db.npc.position == "LEFT" and "RIGHT" or "LEFT"
    -- local _relativePoint = NS.db.npc.position == "TOP" and "BOTTOM" or _horizontalRelativePoint

    nameplate.npiNPCIndicator.cooldown:SetSize(newIconSize, newIconSize)
    nameplate.npiNPCIndicator.cooldown:ClearAllPoints()
    nameplate.npiNPCIndicator.cooldown:SetAllPoints(nameplate.npiNPCIndicator)
    -- nameplate.npiNPCIndicator.cooldown:SetPoint(_point, nameplate.npiNPCIndicator, _relativePoint, 0, 1)

    local existingNPC = activeNPCs[guid]
    if existingNPC then
      -- Update the cooldown with the remaining time
      local currentTime = GetTime()
      local elapsed = currentTime - existingNPC.startTime
      local remaining = existingNPC.duration - elapsed
      if remaining > 0 then
        nameplate.npiNPCIndicator.cooldown:SetCooldown(currentTime - elapsed, existingNPC.duration)
      else
        -- Cooldown has expired
        -- if nameplate.npiNPCIndicator.glowTexture then
        --   nameplate.npiNPCIndicator.glowTexture:SetAlpha(0)
        -- end
        -- if nameplate.npiNPCIndicator.glow then
        --   nameplate.npiNPCIndicator.glow:SetHide(0)
        -- end
        -- nameplate.npiNPCIndicator:Hide()
        activeNPCs[guid] = nil
      end
    else
      -- Set new cooldown
      local startTime = GetTime()
      nameplate.npiNPCIndicator.cooldown:SetCooldown(startTime, npcDuration)
      nameplate.npiNPCIndicator.cooldown:SetReverse(true)
      nameplate.npiNPCIndicator.cooldown:SetDrawSwipe(true)
      nameplate.npiNPCIndicator.cooldown:SetDrawEdge(true)
      activeNPCs[guid] = { startTime = startTime, duration = npcDuration }
    end

    if countdownEnabled then
      nameplate.npiNPCIndicator.cooldown:Show()
    else
      nameplate.npiNPCIndicator.cooldown:Hide()
    end
  end
end

local function addHealerIndicator(nameplate, guid)
  local unit = nameplate.namePlateUnitToken

  local isPlayer = UnitIsPlayer(unit)
  local isSelf = UnitIsUnit(unit, "player")
  local isFriend = UnitIsFriend("player", unit)
  local isEnemy = UnitIsEnemy("player", unit)
  local isHealer = (NS.isHealer("player") or Healers[guid]) and true or false
  local isDeadOrGhost = UnitIsDeadOrGhost(unit)
  local isArena = NameplateIconsFrame.inArena
  local isBattleground = NameplateIconsFrame.inBattleground
  local isOutdoors = NameplateIconsFrame.isOutdoors

  local hideDead = isDeadOrGhost
  local hideNPCs = not isPlayer
  local hideSelf = isSelf
  local hideAllies = not NS.db.healer.showFriendly and (isFriend and isPlayer)
  local hideEnemies = not NS.db.healer.showEnemy and (isEnemy and isPlayer)
  local hideHealers = not isHealer
  local hideOutsideArena = not NS.db.healer.showArena and isArena
  local hideOutsideBattleground = not NS.db.healer.showBattleground and isBattleground
  local hideOutside = not NS.db.healer.showOutdoors and isOutdoors
  local hideLocation = true
  if isArena then
    hideLocation = hideOutsideArena
  elseif isBattleground then
    hideLocation = hideOutsideBattleground
  elseif isOutdoors then
    hideLocation = hideOutside
  end
  local hasObjective = not isSelf and type(UnitPvpClassification(unit)) == "string"
  local hasRaidMarker = not isSelf and type(GetRaidTargetIndex(unit)) == "number"
  local hasOverride = (NS.db.marker.override and hasRaidMarker) -- or (NS.db.objective.override and hasObjective)
  local notTestMode = not NS.db.healer.test or hasOverride
  local hideHealerIndicator = notTestMode
    and (hideNPCs or hideDead or hideSelf or hideAllies or hideEnemies or hideHealers or hideLocation or hasOverride)

  if hideHealerIndicator then
    if nameplate.npiHealerIndicator ~= nil then
      nameplate.npiHealerIndicator:Hide()
    end
    return
  end

  if not nameplate.npiHealerIndicator then
    nameplate.npiHealerIndicator = CreateHealerIcon(nameplate, nameplate.rbgdAnchorFrame, "healer")
  end

  nameplate.npiHealerIndicator:SetIgnoreParentScale(NS.db.general.ignoreNameplateScale)
  nameplate.npiHealerIndicator:SetIgnoreParentAlpha(NS.db.general.ignoreNameplateAlpha)

  local newIconSize = iconSize * NS.db.healer.scale
  nameplate.npiHealerIndicator:SetSize(newIconSize, newIconSize)

  local raidMarkerIsLeft = NS.db.marker.enabled and NS.db.marker.position == "LEFT" or NS.db.marker.enabled == false
  -- local hasOneIcon = hasObjective or hasRaidMarker
  -- local hasTwoIcons = hasObjective and hasRaidMarker
  local raidMarketOffsetX = (hasRaidMarker and raidMarkerIsLeft) and (-30 + NS.db.healer.offsetX)
    or NS.db.healer.offsetX
  local objectiveOffsetX = hasObjective and (-5 + NS.db.healer.offsetX) or NS.db.healer.offsetX
  local offsetLeft = NS.db.healer.attachToHealthBar and NS.db.healer.offsetX or (raidMarketOffsetX or objectiveOffsetX)
  local offsetRight = NS.db.healer.offsetX
  local offset = {
    x = NS.db.healer.position == "LEFT" and offsetLeft or offsetRight,
    y = NS.db.healer.offsetY,
  }
  local point = NS.db.healer.position == "LEFT" and "RIGHT" or "LEFT"
  local relativePoint = NS.db.healer.position == "LEFT" and "LEFT" or "RIGHT"
  local relativeTo = NS.db.healer.attachToHealthBar and GetAnchorFrame(nameplate) or nameplate
  nameplate.npiHealerIndicator:ClearAllPoints()
  -- point, relativeTo, relativePoint, x, y
  nameplate.npiHealerIndicator:SetPoint(point, relativeTo, relativePoint, offset.x, offset.y)
  nameplate.npiHealerIndicator:Show()
end

local function addClassIndicator(nameplate, guid)
  local unit = nameplate.namePlateUnitToken

  local isPlayer = UnitIsPlayer(unit)
  local isSelf = UnitIsUnit(unit, "player")
  local isFriend = UnitIsFriend("player", unit)
  local isEnemy = UnitIsEnemy("player", unit)
  local isDeadOrGhost = UnitIsDeadOrGhost(unit)
  local isArena = NameplateIconsFrame.inArena
  local isBattleground = NameplateIconsFrame.inBattleground
  local isOutdoors = NameplateIconsFrame.isOutdoors
  local hideDead = isDeadOrGhost
  local hideNPCs = not isPlayer
  local hideSelf = isSelf
  local hideAllies = not NS.db.class.showFriendly and (isFriend and isPlayer)
  local hideEnemies = not NS.db.class.showEnemy and (isEnemy and isPlayer)
  local hideOutsideArena = not NS.db.class.showArena and isArena
  local hideOutsideBattleground = not NS.db.class.showBattleground and isBattleground
  local hideOutside = not NS.db.class.showOutdoors and isOutdoors
  local hideLocation = true
  if isArena then
    hideLocation = hideOutsideArena
  elseif isBattleground then
    hideLocation = hideOutsideBattleground
  elseif isOutdoors then
    hideLocation = hideOutside
  end
  -- local hasObjective = not isSelf and UnitPvpClassification(unit)
  local hasRaidMarker = not isSelf and type(GetRaidTargetIndex(unit)) == "number"
  local hasOverride = (NS.db.marker.override and hasRaidMarker) -- or (NS.db.objective.override and hasObjective)
  local notTestMode = not NS.db.class.test or hasOverride
  local hideClassIndicator = notTestMode
    and (hideNPCs or hideSelf or hideDead or hideAllies or hideEnemies or hideLocation or hasOverride)

  if hideClassIndicator then
    if nameplate.npiClassIndicator then
      nameplate.npiClassIndicator:Hide()
    end
    return
  end

  if not nameplate.npiClassIndicator then
    nameplate.npiClassIndicator = CreateClassIcon(nameplate, nameplate.rbgdAnchorFrame, "class")
  end

  nameplate.npiClassIndicator.texture:SetIgnoreParentScale(NS.db.general.ignoreNameplateScale)
  -- NEED TO CHANGE THIS TO IGNORE ALPHA WHEN HIDING HEALTHBARS
  local showArenas = NS.db.nameplate.showArena and isArena
  local showBattlegrounds = NS.db.nameplate.showBattleground and isBattleground
  local showOutdoors = NS.db.nameplate.showOutdoors and isOutdoors
  if showArenas or showBattlegrounds or showOutdoors then
    if isFriend and NS.db.nameplate.healthBars.hideFriendly then
      nameplate.npiClassIndicator.texture:SetIgnoreParentAlpha(true)
    elseif isEnemy and NS.db.nameplate.healthBars.hideEnemy then
      nameplate.npiClassIndicator.texture:SetIgnoreParentAlpha(true)
    else
      nameplate.npiClassIndicator.texture:SetIgnoreParentAlpha(NS.db.general.ignoreNameplateAlpha)
    end
  else
    nameplate.npiClassIndicator.texture:SetIgnoreParentAlpha(NS.db.general.ignoreNameplateAlpha)
  end

  local newIconSize = iconSize * NS.db.class.scale
  nameplate.npiClassIndicator:SetSize(newIconSize, newIconSize)

  local texturePath = GetClassIcon(unit)
  nameplate.npiClassIndicator.texture:SetTexture(texturePath)

  -- local coords = GetClassCoords(unit)
  -- if coords then
  --   nameplate.npiClassIndicator.texture:SetTexCoord(unpack(coords))
  -- end

  local zoom = 0
  local textureWidth = 1 - 0.5 * zoom
  local ulx, uly, llx, lly, urx, ury, lrx, lry =
    GetTextureCoord(nameplate.npiClassIndicator.texture, textureWidth, 1, 0, 0)
  nameplate.npiClassIndicator.texture:SetTexCoord(ulx, uly, llx, lly, urx, ury, lrx, lry)

  local r, g, b, a = GetClassColor(nameplate, unit)
  if r and g and b and a then
    nameplate.npiClassIndicator.border:SetVertexColor(r, g, b, a)
  end

  -- nameplate.npiClassIndicator.border:SetAllPoints(nameplate.npiClassIndicator)
  local offsetMultiplier = 0 -- 0.25
  local widthOffset = newIconSize * offsetMultiplier
  local heightOffset = (newIconSize + 1) * offsetMultiplier
  nameplate.npiClassIndicator.border:SetPoint(
    "TOPLEFT",
    nameplate.npiClassIndicator,
    "TOPLEFT",
    -widthOffset,
    widthOffset
  )
  nameplate.npiClassIndicator.border:SetPoint(
    "BOTTOMRIGHT",
    nameplate.npiClassIndicator,
    "BOTTOMRIGHT",
    heightOffset,
    -heightOffset
  )

  local offset = {
    x = NS.db.class.offsetX,
    y = NS.db.class.offsetY,
  }
  local horizontalPoint = NS.db.class.position == "LEFT" and "RIGHT" or "LEFT"
  local point = NS.db.class.position == "TOP" and "BOTTOM" or horizontalPoint
  local horizontalRelativePoint = NS.db.class.position == "LEFT" and "LEFT" or "RIGHT"
  local relativePoint = NS.db.class.position == "TOP" and "TOP" or horizontalRelativePoint
  local relativeTo = NS.db.class.attachToHealthBar and GetAnchorFrame(nameplate) or nameplate
  nameplate.npiClassIndicator:ClearAllPoints()
  -- point, relativeTo, relativePoint, x, y
  nameplate.npiClassIndicator:SetPoint(point, relativeTo, relativePoint, offset.x, offset.y)
  nameplate.npiClassIndicator:Show()
end

local function addArrowIndicator(nameplate, guid)
  local unit = nameplate.namePlateUnitToken

  local isPlayer = UnitIsPlayer(unit)
  local isSelf = UnitIsUnit(unit, "player")
  local isFriend = UnitIsFriend("player", unit)
  local isEnemy = UnitIsEnemy("player", unit)
  local isDeadOrGhost = UnitIsDeadOrGhost(unit)
  local isArena = NameplateIconsFrame.inArena
  local isBattleground = NameplateIconsFrame.inBattleground
  local isOutdoors = NameplateIconsFrame.isOutdoors

  local hideDead = isDeadOrGhost
  local hideNPCs = not isPlayer
  local hideSelf = isSelf
  local hideAllies = not NS.db.arrow.showFriendly and (isFriend and isPlayer)
  local hideEnemies = not NS.db.arrow.showEnemy and (isEnemy and isPlayer)
  local hideOutsideArena = not NS.db.arrow.showArena and isArena
  local hideOutsideBattleground = not NS.db.arrow.showBattleground and isBattleground
  local hideOutside = not NS.db.arrow.showOutdoors and isOutdoors
  local hideLocation = true
  if isArena then
    hideLocation = hideOutsideArena
  elseif isBattleground then
    hideLocation = hideOutsideBattleground
  elseif isOutdoors then
    hideLocation = hideOutside
  end
  -- local hasObjective = not isSelf and UnitPvpClassification(unit)
  local hasRaidMarker = not isSelf and type(GetRaidTargetIndex(unit)) == "number"
  local hasOverride = (NS.db.marker.override and hasRaidMarker) -- or (NS.db.objective.override and hasObjective)
  local notTestMode = not NS.db.arrow.test or hasOverride
  local hideArrowIndicator = notTestMode
    and (hideNPCs or hideSelf or hideDead or hideAllies or hideEnemies or hideLocation or hasOverride)

  if hideArrowIndicator then
    if nameplate.npiArrowIndicator then
      nameplate.npiArrowIndicator:Hide()
    end
    return
  end

  if not nameplate.npiArrowIndicator then
    nameplate.npiArrowIndicator = CreateArrowIcon(nameplate, nameplate.rbgdAnchorFrame, "arrow")
  end

  nameplate.npiArrowIndicator.texture:SetIgnoreParentScale(NS.db.general.ignoreNameplateScale)
  -- NEED TO CHANGE THIS TO IGNORE ALPHA WHEN HIDING HEALTHBARS
  local showArenas = NS.db.nameplate.showArena and isArena
  local showBattlegrounds = NS.db.nameplate.showBattleground and isBattleground
  local showOutdoors = NS.db.nameplate.showOutdoors and isOutdoors
  if showArenas or showBattlegrounds or showOutdoors then
    if isFriend and NS.db.nameplate.healthBars.hideFriendly then
      nameplate.npiArrowIndicator.texture:SetIgnoreParentAlpha(true)
    elseif isEnemy and NS.db.nameplate.healthBars.hideEnemy then
      nameplate.npiArrowIndicator.texture:SetIgnoreParentAlpha(true)
    else
      nameplate.npiArrowIndicator.texture:SetIgnoreParentAlpha(NS.db.general.ignoreNameplateAlpha)
    end
  else
    nameplate.npiArrowIndicator.texture:SetIgnoreParentAlpha(NS.db.general.ignoreNameplateAlpha)
  end

  local iconWidth = 55
  local iconHeight = 70
  local newIconWidth = iconWidth * NS.db.arrow.scale
  local newIconHeight = iconHeight * NS.db.arrow.scale
  nameplate.npiArrowIndicator:SetSize(newIconWidth, newIconHeight)

  local r, g, b, a = GetClassColor(nameplate, unit)
  if r and g and b and a then
    nameplate.npiArrowIndicator.texture:SetVertexColor(r, g, b, a)
  end

  local offset = {
    x = NS.db.arrow.offsetX,
    y = NS.db.arrow.offsetY,
  }
  local horizontalPoint = NS.db.arrow.position == "LEFT" and "RIGHT" or "LEFT"
  local point = NS.db.arrow.position == "TOP" and "BOTTOM" or horizontalPoint
  local horizontalRelativePoint = NS.db.arrow.position == "LEFT" and "LEFT" or "RIGHT"
  local relativePoint = NS.db.arrow.position == "TOP" and "TOP" or horizontalRelativePoint
  local relativeTo = NS.db.arrow.attachToHealthBar and GetAnchorFrame(nameplate) or nameplate
  nameplate.npiArrowIndicator:ClearAllPoints()
  -- point, relativeTo, relativePoint, x, y
  nameplate.npiArrowIndicator:SetPoint(point, relativeTo, relativePoint, offset.x, offset.y)
  nameplate.npiArrowIndicator:Show()
end

-- skull = atlas - GM-raidMarker1 - index - 8
-- cross = atlas - GM-raidMarker2 - index - 7
-- square = atlas - GM-raidMarker3 - index - 6
-- moon = atlas - GM-raidMarker4 - index - 5
-- triangle = atlas - GM-raidMarker5 - index - 4
-- diamond = atlas - GM-raidMarker6 - index - 3
-- circle = atlas - GM-raidMarker7 - index - 2
-- star = atlas - GM-raidMarker8 - index - 1
local function addRaidMarkers(nameplate)
  local unit = nameplate.namePlateUnitToken

  local raidMarker = GetRaidTargetIndex(unit)

  if
    not nameplate.UnitFrame.ClassificationFrame
    or not nameplate.UnitFrame.ClassificationFrame.classificationIndicator
    or not nameplate.UnitFrame.RaidTargetFrame
    or not nameplate.UnitFrame.RaidTargetFrame.RaidTargetIcon
    or not raidMarker
  then
    if nameplate.npiMarkerIndicator ~= nil then
      nameplate.npiMarkerIndicator:Hide()
    end
    return
  end

  nameplate.UnitFrame.RaidTargetFrame:SetAlpha(0)

  if not nameplate.npiMarkerIndicator then
    nameplate.npiMarkerIndicator = CreateMarkerIcon(nameplate, nameplate.rbgdAnchorFrame, "marker", raidMarker)
  end

  nameplate.npiMarkerIndicator:SetIgnoreParentScale(NS.db.general.ignoreNameplateScale)
  nameplate.npiMarkerIndicator:SetIgnoreParentAlpha(NS.db.general.ignoreNameplateAlpha)

  local newIconSize = markerIconSize * NS.db.marker.scale
  nameplate.npiMarkerIndicator:SetSize(newIconSize, newIconSize)

  if nameplate.npiMarkerIndicator.texture then
    nameplate.npiMarkerIndicator.texture:SetTexCoord(unpack(markerCoords[raidMarker]))
  end

  local offset = {
    x = NS.db.marker.offsetX,
    y = NS.db.marker.offsetY,
  }
  local horizontalPoint = NS.db.marker.position == "LEFT" and "RIGHT" or "LEFT"
  local point = NS.db.marker.position == "TOP" and "BOTTOM" or horizontalPoint
  local horizontalRelativePoint = NS.db.marker.position == "LEFT" and "LEFT" or "RIGHT"
  local relativePoint = NS.db.marker.position == "TOP" and "TOP" or horizontalRelativePoint
  local relativeTo = NS.db.marker.attachToHealthBar and GetAnchorFrame(nameplate) or nameplate
  nameplate.npiMarkerIndicator:ClearAllPoints()
  -- point, relativeTo, relativePoint, x, y
  nameplate.npiMarkerIndicator:SetPoint(point, relativeTo, relativePoint, offset.x, offset.y)
  nameplate.npiMarkerIndicator:Show()
end

-- new atlas icons can be 32 (flags), 26 (orbs), 32 (cart)
-- for deephaul, C_Map.GetBestMapForUnit("player"), so we can change the icon from horde flag to custom crystal icon
-- deephaul crystal = nameplates-icon-flag-horde - atlas - FlagCarrierHorde - 0 -- maybe try atlas Warlock-ReadyShard - width 17 x height 22 - or UF-SoulShard-Inc9 w23xh29 - or UF-SoulShard-Inc9 w14xh11
-- horde flag = nameplates-icon-flag-horde - atlas - FlagCarrierHorde - 0
-- alliance flag = nameplates-icon-flag-alliance - atlas - FlagCarrierAlliance - 1
-- eots flag = nameplates-icon-flag-neutral - atlas - FlagCarrierNeutral -- 2
-- horde cart = nameplates-icon-cart-horde - atlas - CartRunnerHorde -- 3
-- alliance cart = nameplates-icon-cart-alliance - atlas - CartRunnerAlliance -- 4
-- blue orb = nameplates-icon-orb-blue - atlas -- OrbCarrierBlue - 7
-- green orb = nameplates-icon-orb-green - atlas -- OrbCarrierGreen - 8
-- orange orb = nameplates-icon-orb-orange - atlas -- OrbCarrierOrange - 9
-- purple orb = nameplates-icon-orb-purple - atlas -- OrbCarrierPurple - 10
-- local function addObjectives(nameplate, revert)
-- 	-- if nameplate.UnitFrame.ClassificationFrame.classificationIndicator then
-- 	-- 	local unit = nameplate.namePlateUnitToken
-- 	-- 	local name = UnitName(unit)
-- 	-- 	local hasObjective = UnitPvpClassification(unit)
-- 	-- 	if hasObjective then
-- 	-- 		print("objective map", C_Map.GetBestMapForUnit("player"))
-- 	-- 		print("objective hasObjective", name, hasObjective)
-- 	-- 		print("objective atlas", nameplate.UnitFrame.ClassificationFrame.classificationIndicator:GetAtlas())
-- 	-- 		print("objective texture", nameplate.UnitFrame.ClassificationFrame.classificationIndicator:GetTexture())
-- 	-- 		print(
-- 	-- 			"objective texture coord",
-- 	-- 			nameplate.UnitFrame.ClassificationFrame.classificationIndicator:GetTexCoord()
-- 	-- 		)
-- 	-- 		print("objective texture size", nameplate.UnitFrame.ClassificationFrame.classificationIndicator:GetSize())
-- 	-- 	end
-- 	-- end

-- 	local unit = nameplate.namePlateUnitToken

-- 	local isPlayer = UnitIsPlayer(unit)
-- 	local isSelf = UnitIsUnit(unit, "player")
-- 	local isDeadOrGhost = UnitIsDeadOrGhost(unit)

-- 	local hideDead = isDeadOrGhost
-- 	local hidePlayers = not isPlayer
-- 	local hideSelf = isSelf
-- 	local hideObjectiveUnits = not UnitPvpClassification(unit)
-- 	local hideTestMode = not NS.db.objective.test
-- 	local hideObjectiveIndicator = hideTestMode and (hideDead or hidePlayers or hideSelf or hideObjectiveUnits)

-- 	if hideObjectiveIndicator then
-- 		if nameplate.npiObjectiveIndicator ~= nil then
-- 			nameplate.npiObjectiveIndicator:Hide()
-- 		end
-- 		return
-- 	end

-- 	if not nameplate.npiObjectiveIndicator then
-- 		nameplate.npiObjectiveIndicator = CreateObjectiveIcon(nameplate, nameplate.rbgdAnchorFrame, "objective")
-- 	end

-- 	nameplate.npiObjectiveIndicator:SetIgnoreParentScale(NS.db.general.ignoreNameplateScale)
-- 	nameplate.npiObjectiveIndicator:SetIgnoreParentAlpha(NS.db.general.ignoreNameplateAlpha)

-- 	local newIconSize = iconSize * NS.db.objective.scale
-- 	nameplate.npiObjectiveIndicator:SetSize(newIconSize, newIconSize)

-- 	local offset = {
-- 		x = NS.db.objective.offsetX,
-- 		y = NS.db.objective.offsetY,
-- 	}
-- 	local horizontalPoint = NS.db.objective.position == "LEFT" and "RIGHT" or "LEFT"
-- 	local point = NS.db.objective.position == "TOP" and "BOTTOM" or horizontalPoint
-- 	local horizontalRelativePoint = NS.db.objective.position == "LEFT" and "LEFT" or "RIGHT"
-- 	local relativePoint = NS.db.objective.position == "TOP" and "TOP" or horizontalRelativePoint
-- 	local relativeTo = NS.db.objective.attachToHealthBar and GetAnchorFrame(nameplate) or nameplate
-- 	nameplate.npiObjectiveIndicator:ClearAllPoints()
-- 	-- point, relativeTo, relativePoint, x, y
-- 	nameplate.npiObjectiveIndicator:SetPoint(point, relativeTo, relativePoint, offset.x, offset.y)
-- 	nameplate.npiObjectiveIndicator:Show()
-- end

function NameplateIcons:detachFromNameplate(nameplate)
  if nameplate.npiArrowIndicator ~= nil then
    nameplate.npiArrowIndicator:Hide()
  end
  if nameplate.npiClassIndicator ~= nil then
    nameplate.npiClassIndicator:Hide()
  end
  if nameplate.npiHealerIndicator ~= nil then
    nameplate.npiHealerIndicator:Hide()
  end
  if nameplate.npiNPCIndicator ~= nil then
    nameplate.npiNPCIndicator:Hide()

    if nameplate.UnitFrame then
      CompactUnitFrame_UpdateHealthColor(nameplate.UnitFrame)
      CompactUnitFrame_UpdateName(nameplate.UnitFrame)
    end
  end
  if nameplate.npiQuestIndicator ~= nil then
    nameplate.npiQuestIndicator:Hide()
  end
  if nameplate.npiMarkerIndicator ~= nil then
    nameplate.npiMarkerIndicator:Hide()

    if
      nameplate.UnitFrame
      and nameplate.namePlateUnitToken
      and nameplate.UnitFrame.ClassificationFrame
      and nameplate.UnitFrame.ClassificationFrame.classificationIndicator
      and nameplate.UnitFrame.RaidTargetFrame
      and nameplate.UnitFrame.RaidTargetFrame.RaidTargetIcon
      and GetRaidTargetIndex(nameplate.namePlateUnitToken)
    then
      nameplate.UnitFrame.RaidTargetFrame:SetAlpha(1)
    end
  end
  -- if nameplate.npiObjectiveIndicator ~= nil then
  -- 	nameplate.npiObjectiveIndicator:Hide()

  -- 	if
  -- 		nameplate.UnitFrame
  -- 		and nameplate.namePlateUnitToken
  -- 		and nameplate.UnitFrame.ClassificationFrame
  -- 		and nameplate.UnitFrame.ClassificationFrame.classificationIndicator
  -- 		and UnitPvpClassification(nameplate.namePlateUnitToken)
  -- 	then
  -- 		nameplate.UnitFrame.ClassificationFrame.classificationIndicatore:SetAlpha(1)
  -- 	end
  -- end
end

function NameplateIcons:attachToNameplate(nameplate, guid)
  if not nameplate.rbgdAnchorFrame then
    local attachmentFrame = GetAnchorFrame(nameplate)
    nameplate.rbgdAnchorFrame = CreateFrame("Frame", nil, attachmentFrame)
    nameplate.rbgdAnchorFrame:SetFrameStrata("HIGH")
    nameplate.rbgdAnchorFrame:SetFrameLevel(attachmentFrame:GetFrameLevel() + 1)
  end

  checkIsHealer(nameplate, guid)
  hideHealthBars(nameplate, guid)
  hideNames(nameplate, guid)
  hideServers(nameplate, guid)
  hideCastBars(nameplate, guid)
  hideBuffFrames(nameplate, guid)

  if NS.db.arrow.enabled then
    addArrowIndicator(nameplate, guid)
  else
    if nameplate.npiArrowIndicator ~= nil then
      nameplate.npiArrowIndicator:Hide()
    end
  end
  if NS.db.class.enabled then
    addClassIndicator(nameplate, guid)
  else
    if nameplate.npiClassIndicator ~= nil then
      nameplate.npiClassIndicator:Hide()
    end
  end
  if NS.db.healer.enabled then
    addHealerIndicator(nameplate, guid)
  else
    if nameplate.npiHealerIndicator ~= nil then
      nameplate.npiHealerIndicator:Hide()
    end
  end
  if NS.db.npc.enabled then
    addNPCIndicator(nameplate, guid)
  else
    if nameplate.npiNPCIndicator ~= nil then
      nameplate.npiNPCIndicator:Hide()
    end
  end
  if NS.db.quest.enabled then
    addQuestIndicator(nameplate, guid)
  else
    if nameplate.npiQuestIndicator ~= nil then
      nameplate.npiQuestIndicator:Hide()
    end
  end
  if NS.db.marker.enabled then
    addRaidMarkers(nameplate)
  else
    if nameplate.npiMarkerIndicator ~= nil then
      nameplate.npiMarkerIndicator:Hide()

      if
        nameplate.UnitFrame
        and nameplate.namePlateUnitToken
        and nameplate.UnitFrame.ClassificationFrame
        and nameplate.UnitFrame.ClassificationFrame.classificationIndicator
        and nameplate.UnitFrame.RaidTargetFrame
        and nameplate.UnitFrame.RaidTargetFrame.RaidTargetIcon
        and GetRaidTargetIndex(nameplate.namePlateUnitToken)
      then
        nameplate.UnitFrame.RaidTargetFrame:SetAlpha(1)
      end
    end
  end
  -- if NS.db.objective.enabled then
  -- 	addObjectives(nameplate)
  -- else
  -- 	if nameplate.npiObjectiveIndicator ~= nil then
  -- 		nameplate.npiObjectiveIndicator:Hide()

  -- 		if
  -- 			nameplate.UnitFrame
  -- 			and nameplate.namePlateUnitToken
  -- 			and nameplate.UnitFrame.ClassificationFrame
  -- 			and nameplate.UnitFrame.ClassificationFrame.classificationIndicator
  -- 			and UnitPvpClassification(nameplate.namePlateUnitToken)
  -- 		then
  -- 			nameplate.UnitFrame.ClassificationFrame.classificationIndicatore:SetAlpha(1)
  -- 		end
  -- 	end
  -- end
end

local function refreshNameplates(override)
  if not override and NameplateIconsFrame.wasOnLoadingScreen then
    return
  end

  for _, nameplate in pairs(GetNamePlates(issecure())) do
    if nameplate then
      local guid = UnitGUID(nameplate.namePlateUnitToken)
      if guid then
        NameplateIcons:attachToNameplate(nameplate, guid)
      end
    end
  end
end

function NameplateIcons:NAME_PLATE_UNIT_REMOVED(unitToken)
  local nameplate = GetNamePlateForUnit(unitToken, issecure())

  if nameplate then
    self:detachFromNameplate(nameplate)
  end
end

function NameplateIcons:NAME_PLATE_UNIT_ADDED(unitToken)
  local nameplate = GetNamePlateForUnit(unitToken, issecure())
  local guid = UnitGUID(unitToken)

  if nameplate and guid then
    self:attachToNameplate(nameplate, guid)
  end
end

function NameplateIcons:UNIT_QUEST_LOG_CHANGED(unitToken)
  refreshNameplates()
end

local ShuffleFrame = CreateFrame("Frame")
ShuffleFrame.eventRegistered = false

function NameplateIcons:PLAYER_REGEN_ENABLED()
  NameplateIconsFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
  ShuffleFrame.eventRegistered = false

  if NS.isInGroup() then
    for unit in NS.IterateGroupMembers() do
      local guid = UnitGUID(unit)
      if unit and guid then
        if NS.isHealer(unit) and not Healers[guid] then
          Healers[guid] = true
        end
        if not NS.isHealer(unit) and Healers[guid] then
          Healers[guid] = nil
        end
      end
    end
  else
    local guid = UnitGUID("player")
    if guid then
      if NS.isHealer("player") and not Healers[guid] then
        Healers[guid] = true
      end
    end
  end

  refreshNameplates()
end

function NameplateIcons:GROUP_ROSTER_UPDATE()
  if not NameplateIconsFrame.inArena then
    return
  end

  local name = AuraUtil.FindAuraByName("Arena Preparation", "player", "HELPFUL")
  if not name then
    return
  end

  if UnitAffectingCombat("player") then
    if not ShuffleFrame.eventRegistered then
      NameplateIconsFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
      ShuffleFrame.eventRegistered = true
    end
  else
    if NS.isInGroup() then
      for unit in NS.IterateGroupMembers() do
        local guid = UnitGUID(unit)
        if unit and guid then
          if NS.isHealer(unit) and not Healers[guid] then
            Healers[guid] = true
          end
          if not NS.isHealer(unit) and Healers[guid] then
            Healers[guid] = nil
          end
        end
      end
    else
      local guid = UnitGUID("player")
      if guid then
        if NS.isHealer("player") and not Healers[guid] then
          Healers[guid] = true
        end
      end
    end

    refreshNameplates()
  end
end

function NameplateIcons:ARENA_OPPONENT_UPDATE()
  if not NameplateIconsFrame.inArena then
    return
  end

  local name = AuraUtil.FindAuraByName("Arena Preparation", "player", "HELPFUL")
  if not name then
    return
  end

  if UnitAffectingCombat("player") then
    if not ShuffleFrame.eventRegistered then
      NameplateIconsFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
      ShuffleFrame.eventRegistered = true
    end
  else
    if NS.isInGroup() then
      for unit in NS.IterateGroupMembers() do
        local guid = UnitGUID(unit)
        if unit and guid then
          if NS.isHealer(unit) and not Healers[guid] then
            Healers[guid] = true
          end
          if not NS.isHealer(unit) and Healers[guid] then
            Healers[guid] = nil
          end
        end
      end
    else
      local guid = UnitGUID("player")
      if guid then
        if NS.isHealer("player") and not Healers[guid] then
          Healers[guid] = true
        end
      end
    end

    refreshNameplates()
  end
end

-- can run before a nameplate is fetched so needs updated info
hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
  if not frame then
    return
  end
  if frame:IsForbidden() then
    return
  end
  if not frame.unit then
    return
  end
  if not smatch(frame.unit, "nameplate") then
    return
  end

  local guid = UnitGUID(frame.unit)
  if guid then
    local unit = frame.unit

    local isPlayer = UnitIsPlayer(unit)
    -- local isNPC = not isPlayer
    local isSelf = UnitIsUnit(unit, "player")
    local isFriend = UnitIsFriend("player", unit)
    local isEnemy = UnitIsEnemy("player", unit)
    local isDeadOrGhost = UnitIsDeadOrGhost(unit)
    local isArena = NameplateIconsFrame.inArena
    local isBattleground = NameplateIconsFrame.inBattleground
    local isOutdoors = NameplateIconsFrame.isOutdoors

    local npcID = select(6, ssplit("-", guid))
    local hideDead = isDeadOrGhost
    local hideSelf = isSelf
    local hidePlayers = isPlayer
    local hideFriendly = NS.db.npc.showFriendly == false and isFriend
    local hideEnemy = NS.db.npc.showEnemy == false and isEnemy
    local hideNotInList = NS.isNPCInList(NS.NPC_SHOW_LIST, npcID) ~= true
    local hideNotEnabled = not NS.db.npcs[npcID] or NS.db.npcs[npcID].enabled ~= true
    local hideOutsideArena = not NS.db.npc.showArena and isArena
    local hideOutsideBattleground = not NS.db.npc.showBattleground and isBattleground
    local hideOutside = not NS.db.npc.showOutdoors and isOutdoors
    local hideLocation = true
    if isArena then
      hideLocation = hideOutsideArena
    elseif isBattleground then
      hideLocation = hideOutsideBattleground
    elseif isOutdoors then
      hideLocation = hideOutside
    end
    local notTestMode = not NS.db.npc.test
    local hideNPCIndicator = notTestMode
      and (
        hideNotInList
        or hideNotEnabled
        or hideDead
        or hideSelf
        or hidePlayers
        or hideFriendly
        or hideEnemy
        or hideLocation
      )

    if not hideNPCIndicator then
      local npcGlow = NS.db.npcs[npcID].glow
      local changeHealthbarColor = NS.db.npcs[npcID].healthColor == true
      if changeHealthbarColor then
        frame.healthBar:SetStatusBarColor(npcGlow[1], npcGlow[2], npcGlow[3], npcGlow[4])
      end
    end
  end
end)

hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
  if not frame then
    return
  end
  if frame:IsForbidden() then
    return
  end
  if not frame.unit then
    return
  end
  if not frame.name then
    return
  end
  if not ShouldShowName(frame) then
    return
  end
  if not smatch(frame.unit, "nameplate") then
    return
  end

  local guid = UnitGUID(frame.unit)
  if guid then
    local unit = frame.unit

    local isPlayer = UnitIsPlayer(unit)
    local isNPC = not isPlayer
    local isSelf = UnitIsUnit(unit, "player")
    local isFriend = UnitIsFriend("player", unit)
    local isEnemy = UnitIsEnemy("player", unit)
    local isDeadOrGhost = UnitIsDeadOrGhost(unit)
    local isArena = NameplateIconsFrame.inArena
    local isBattleground = NameplateIconsFrame.inBattleground
    local isOutdoors = NameplateIconsFrame.isOutdoors

    do
      local npcID = select(6, ssplit("-", guid))
      local hideDead = isDeadOrGhost
      local hideSelf = isSelf
      local hidePlayers = isPlayer
      local hideFriendly = NS.db.npc.showFriendly == false and isFriend
      local hideEnemy = NS.db.npc.showEnemy == false and isEnemy
      local hideNotInList = NS.isNPCInList(NS.NPC_SHOW_LIST, npcID) ~= true
      local hideNotEnabled = not NS.db.npcs[npcID] or NS.db.npcs[npcID].enabled ~= true
      local hideOutsideArena = not NS.db.npc.showArena and isArena
      local hideOutsideBattleground = not NS.db.npc.showBattleground and isBattleground
      local hideOutside = not NS.db.npc.showOutdoors and isOutdoors
      local hideLocation = true
      if isArena then
        hideLocation = hideOutsideArena
      elseif isBattleground then
        hideLocation = hideOutsideBattleground
      elseif isOutdoors then
        hideLocation = hideOutside
      end
      local notTestMode = not NS.db.npc.test
      local hideNPCIndicator = notTestMode
        and (
          hideNotInList
          or hideNotEnabled
          or hideDead
          or hideSelf
          or hidePlayers
          or hideFriendly
          or hideEnemy
          or hideLocation
        )

      if not hideNPCIndicator then
        local npcGlow = NS.db.npcs[npcID].glow
        local changeNameColor = NS.db.npcs[npcID].nameColor == true
        if changeNameColor then
          frame.name:SetVertexColor(npcGlow[1], npcGlow[2], npcGlow[3], npcGlow[4])
        end
      end
    end

    local hideFriendly = NS.db.nameplate.names.hideFriendly and (isFriend and isPlayer)
    local hideEnemy = NS.db.nameplate.names.hideEnemy and (isEnemy and isPlayer)
    local hideNPC = NS.db.nameplate.names.hideNPC and isNPC
    local hideName = hideFriendly or hideEnemy or hideNPC
    local hideOutsideArena = not NS.db.nameplate.showArena and isArena
    local hideOutsideBattleground = not NS.db.nameplate.showBattleground and isBattleground
    local hideOutside = not NS.db.nameplate.showOutdoors and isOutdoors
    local hideLocation = true
    if isArena then
      hideLocation = hideOutsideArena
    elseif isBattleground then
      hideLocation = hideOutsideBattleground
    elseif isOutdoors then
      hideLocation = hideOutside
    end

    if hideLocation then
      frame.name:SetAlpha(1)
      return
    end

    if hideName then
      frame.name:SetAlpha(0)
    else
      frame.name:SetAlpha(1)
    end
  end
end)

hooksecurefunc(CastingBarMixin, "OnEvent", function(originalFrame)
  if not originalFrame then
    return
  end

  local nameplate = GetNamePlateForUnit(originalFrame.unit, issecure())
  local guid = UnitGUID(originalFrame.unit)

  if nameplate and guid then
    hideCastBars(nameplate, guid)
  end
end)

hooksecurefunc(NamePlateDriverFrame, "OnUnitFactionChanged", function(_, unit)
  if not unit then
    return
  end

  After(0.2, function()
    local nameplate = GetNamePlateForUnit(unit, issecure())
    local guid = UnitGUID(unit)

    if nameplate and guid then
      hideHealthBars(nameplate, guid)
      hideNames(nameplate, guid)
      hideServers(nameplate, guid)
      hideCastBars(nameplate, guid)
      hideBuffFrames(nameplate, guid)
    end
  end)
end)

-- hooksecurefunc(NamePlateDriverFrame, "OnSoftTargetUpdate", function(self, unit)
--   local iconSize = tonumber(GetCVar("SoftTargetNameplateSize"))
--   local doEnemyIcon = GetCVarBool("SoftTargetIconEnemy")
--   local doFriendIcon = GetCVarBool("SoftTargetIconFriend")
--   local doInteractIcon = GetCVarBool("SoftTargetIconInteract")
--   for _, frame in pairs(C_NamePlate.GetNamePlates(issecure())) do
--     local icon = frame.UnitFrame.SoftTargetFrame.Icon
--     local hasCursorTexture = false
--     if iconSize > 0 then
--       if
--         (doEnemyIcon and UnitIsUnit(frame.namePlateUnitToken, "softenemy"))
--         or (doFriendIcon and UnitIsUnit(frame.namePlateUnitToken, "softfriend"))
--         or (doInteractIcon and UnitIsUnit(frame.namePlateUnitToken, "softinteract"))
--       then
--         hasCursorTexture = SetUnitCursorTexture(icon, frame.namePlateUnitToken)
--       end
--       if hasCursorTexture and (doInteractIcon and UnitIsUnit(frame.namePlateUnitToken, "softinteract")) then
--         if UnitGUID(frame.namePlateUnitToken) then
--           hideHealthBars(frame, UnitGUID(frame.namePlateUnitToken), true)
--         end
--       end
--     end

--     if hasCursorTexture then
--       icon:Show()
--     else
--       icon:Hide()
--     end
--   end
-- end)

-- hooksecurefunc(NamePlateDriverFrame, "OnRaidTargetUpdate", function(self, unit)
--   for _, frame in pairs(C_NamePlate.GetNamePlates(issecure())) do
--     local icon = frame.UnitFrame.RaidTargetFrame.RaidTargetIcon
--     local index = GetRaidTargetIndex(frame.namePlateUnitToken)
--     if index and not UnitIsUnit("player", frame.namePlateUnitToken) then
--       SetRaidTargetIconTexture(icon, index)
--       icon:Show()
--     else
--       icon:Hide()
--     end
--   end
-- end)

function NameplateIcons:RAID_TARGET_UPDATE()
  refreshNameplates(true)
end

function NameplateIcons:PLAYER_SPECIALIZATION_CHANGED()
  local guid = UnitGUID("player")
  if guid then
    if NS.isHealer("player") and not Healers[guid] then
      Healers[guid] = true
    end
  end
end

function NameplateIcons:PLAYER_LEAVING_WORLD()
  After(2, function()
    NameplateIconsFrame.wasOnLoadingScreen = false
  end)
end

function NameplateIcons:LOADING_SCREEN_DISABLED()
  After(2, function()
    NameplateIconsFrame.wasOnLoadingScreen = false
  end)
end

function NameplateIcons:LOADING_SCREEN_ENABLED()
  NameplateIconsFrame.wasOnLoadingScreen = true
end

function NameplateIcons:PLAYER_ENTERING_WORLD(isInitialLogin, _)
  NameplateIconsFrame.wasOnLoadingScreen = true

  if NS.isInGroup() then
    for unit in NS.IterateGroupMembers() do
      local guid = UnitGUID(unit)
      if unit and guid then
        if NS.isHealer(unit) and not Healers[guid] then
          Healers[guid] = true
        end
        if not NS.isHealer(unit) and Healers[guid] then
          Healers[guid] = nil
        end
      end
    end
  else
    local guid = UnitGUID("player")
    if guid then
      if NS.isHealer("player") and not Healers[guid] then
        Healers[guid] = true
      end
    end
  end

  instanceCheck()

  if isInitialLogin then
    -- this code only runs when you hover over a player
    local function OnTooltipSetItem(tooltip, tooltipData)
      if tooltip == GameTooltip then
        if tooltipData then
          if
            tooltipData.guid
            and tooltipData.lines
            and #tooltipData.lines >= 3
            and tooltipData.type == Enum.TooltipDataType.Unit
          then
            local unitToken = UnitTokenFromGUID(tooltipData.guid)
            if not unitToken then
              return
            end
            local isPlayer = UnitIsPlayer(unitToken)
            local _, _, classId = UnitClass(unitToken)
            local canBeHealer = classId ~= nil and HEALER_CLASS_IDS[classId] == true
            if not isPlayer or not canBeHealer or Healers[tooltipData.guid] == true then
              return
            end
            for _, line in ipairs(tooltipData.lines) do
              if line and line.type == Enum.TooltipDataLineType.None then
                if line.leftText and line.leftText ~= "" then
                  if Healers[tooltipData.guid] and HEALER_SPECS[line.leftText] then
                    break
                  end
                  if Healers[tooltipData.guid] and not HEALER_SPECS[line.leftText] then
                    Healers[tooltipData.guid] = nil
                    break
                  end
                  if not Healers[tooltipData.guid] and HEALER_SPECS[line.leftText] then
                    Healers[tooltipData.guid] = true
                    break
                  end
                end
              end
            end
          end
        end
      end
    end
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipSetItem)

    Quest:OnEnable()
  end

  Quest:OnEnable()

  NameplateIconsFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
  NameplateIconsFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
  NameplateIconsFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
  NameplateIconsFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
  NameplateIconsFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
  NameplateIconsFrame:RegisterEvent("RAID_TARGET_UPDATE")
  NameplateIconsFrame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
end

function NameplateIcons:PLAYER_LOGIN()
  NameplateIconsFrame:UnregisterEvent("PLAYER_LOGIN")

  SetNamePlateSelfClickThrough(NS.db.general.selfClickThrough)
  SetNamePlateFriendlyClickThrough(NS.db.general.friendlyClickThrough)
  SetNamePlateEnemyClickThrough(NS.db.general.enemyClickThrough)

  local loadedOrLoading, loaded = IsAddOnLoaded("OmniCC")
  if not loaded and not loadedOrLoading then
    SetCVar("countdownForCooldowns", "1")
  else
    SetCVar("countdownForCooldowns", "0")
  end

  NameplateIconsFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  NameplateIconsFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
  NameplateIconsFrame:RegisterEvent("LOADING_SCREEN_ENABLED")
  NameplateIconsFrame:RegisterEvent("LOADING_SCREEN_DISABLED")
end
NameplateIconsFrame:RegisterEvent("PLAYER_LOGIN")

function NS.OnDbChanged()
  SetNamePlateSelfClickThrough(NS.db.general.selfClickThrough)
  SetNamePlateFriendlyClickThrough(NS.db.general.friendlyClickThrough)
  SetNamePlateEnemyClickThrough(NS.db.general.enemyClickThrough)

  refreshNameplates(true)
end

function NS.Options_SlashCommands(_)
  AceConfigDialog:Open(AddonName)
end

function NS.Options_Setup()
  NS.AceConfig.args.profiles.handler = NS.getOptionsHandler(NS.db, false)

  AceConfig:RegisterOptionsTable(AddonName, NS.AceConfig)
  AceConfigDialog:AddToBlizOptions(AddonName, AddonName)

  SLASH_NPI1 = "/nameplateicons"
  SLASH_NPI2 = "/npi"

  function SlashCmdList.NPI(message)
    NS.Options_SlashCommands(message)
  end
end

function NameplateIcons:ADDON_LOADED(addon)
  if addon == AddonName then
    NameplateIconsFrame:UnregisterEvent("ADDON_LOADED")

    NameplateIconsDB = NameplateIconsDB and next(NameplateIconsDB) ~= nil and NameplateIconsDB
      or {
        profileKeys = {},
        profiles = {},
      }

    local profile = NameplateIconsDB.profileKeys[NS.CHAR_NAME]

    if not profile or not NameplateIconsDB.profiles[profile] then
      -- Profile doesn't exist or is deleted, reset to default
      NameplateIconsDB.profileKeys[NS.CHAR_NAME] = "Default"
      profile = "Default"
    end

    -- Copy any settings from default if they don't exist in current profile
    NS.CopyDefaults({
      [profile] = NS.DefaultDatabase,
    }, NameplateIconsDB.profiles)

    -- Reference to active db profile
    -- Always use this directly or reference will be invalid
    -- after changing profile
    NS.db = NameplateIconsDB.profiles[profile]
    NS.activeProfile = profile

    -- Remove table values no longer found in default settings
    NS.CleanupDB(NameplateIconsDB.profiles[profile], NS.DefaultDatabase)

    NS.BuildOptions()

    NS.Options_Setup()
  end
end
NameplateIconsFrame:RegisterEvent("ADDON_LOADED")

--[[
-- Warlock-ReadyShard

-- Vehicle-SilvershardMines-MineCartBlue
-- Vehicle-SilvershardMines-MineCartRed

-- Vehicle-TempleofKotmogu-CyanBall
-- Vehicle-TempleofKotmogu-GreenBall
-- Vehicle-TempleofKotmogu-OrangeBall
-- Vehicle-TempleofKotmogu-PurpleBall

-- nameplates-icon-orb-green
-- nameplates-icon-orb-orange
-- nameplates-icon-orb-purple
-- nameplates-icon-orb-purple

-- nameplates-icon-cart-alliance
-- nameplates-icon-cart-horde

-- nameplates-icon-flag-alliance
-- nameplates-icon-flag-horde
-- nameplates-icon-flag-neutral

-- orbs-leftIcon1-state1
-- orbs-leftIcon2-state1
-- orbs-leftIcon3-state1
-- orbs-leftIcon4-state1
-- orbs-rightIcon1-state1
-- orbs-rightIcon2-state1
-- orbs-rightIcon3-state1
-- orbs-rightIcon4-state1

-- ctf_flags-leftIcon1-state1
-- ctf_flags-leftIcon2-state1
-- ctf_flags-leftIcon3-state1
-- ctf_flags-leftIcon4-state1
-- ctf_flags-leftIcon5-state1
-- ctf_flags-rightIcon1-state1
-- ctf_flags-rightIcon2-state1
-- ctf_flags-rightIcon3-state1
-- ctf_flags-rightIcon4-state1
-- ctf_flags-rightIcon5-state1

-- ColumnIcon-FlagCapture0
-- ColumnIcon-FlagCapture1
-- ColumnIcon-FlagCapture2
-- ColumnIcon-FlagReturn0
-- ColumnIcon-FlagReturn1

-- jailerstower-score-disabled-gem-icon
-- jailerstower-score-gem-icon
-- jailerstower-score-gem-tooltipicon
-- jailerstower-score-gem-anim-flash

-- alliance_icon_and_flag-dynamicIcon
-- alliance_icon_horde_flag-dynamicIcon
-- horde_icon_alliance_flag-dynamicIcon
-- horde_icon_and_flag-dynamicIcon

-- poi-bountyplayer-alliance
-- poi-bountyplayer-horde

-- Adventures-Target-Indicator
-- Adventures-Target-Indicator-desat
-- Azerite-PointingArrow
-- CovenantSanctum-Renown-DoubleArrow-Depressed

-- MiniMap-DeadArrow
-- MiniMap-QuestArrow
-- MiniMap-VignetteArrow
-- plunderstorm-icon-upgrade -- up arrow
-- plunderstorm-icon-utility -- lightning bolt
-- plunderstorm-glues-logoarrow -- down arrow

-- UI-HUD-UnitFrame-Player-Portrait-ClassIcon-DemonHunter
-- classicon-demonhunter
-- groupfinder-icon-class-deathknight
-- groupfinder-icon-class-demonhunter
-- groupfinder-icon-class-druid
-- groupfinder-icon-class-hunter
-- groupfinder-icon-class-mage
-- groupfinder-icon-class-monk
-- groupfinder-icon-class-paladin
-- groupfinder-icon-class-priest
-- groupfinder-icon-class-rogue
-- groupfinder-icon-class-shaman
-- groupfinder-icon-class-warlock
-- groupfinder-icon-class-warrior

-- XMarksTheSpot -- X
-- UpgradeItem-32x32 -- sword
-- Ping_Map_Whole_Assist -- flag

-- leader
-- plunderstorm-glues-icon-leader
-- UI-LFG-RoleIcon-Leader

-- roleicon-tiny-healer
-- healer
-- Adventure-heal-indicator
-- ui_adv_health
-- Adventures-Healer
-- bags-icon-addslots
-- Bags-icon-AddAuthenticator
-- UI-LFG-RoleIcon-Healer
-- groupfinder-icon-role-large-heal
-- GreenCross
-- runecarving-icon-power-empty
-- Icon-Healer
-- HealerBadge

-- local isLeader = UnitIsGroupLeader(unit)
]]
