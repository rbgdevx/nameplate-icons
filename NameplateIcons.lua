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
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local next = next
local GetTime = GetTime
local UnitPvpClassification = UnitPvpClassification
local GetRaidTargetIndex = GetRaidTargetIndex
local unpack = unpack

local ssplit = string.split
local sfind = string.find
local smatch = string.match
local bband = bit.band
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

local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER

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
local HEALER_SPELL_EVENTS = {
  ["SPELL_HEAL"] = true,
  ["SPELL_AURA_APPLIED"] = true,
  ["SPELL_CAST_START"] = true,
  ["SPELL_CAST_SUCCESS"] = true,
  ["SPELL_EMPOWER_START"] = true,
  ["SPELL_EMPOWER_END"] = true,
  ["SPELL_PERIODIC_HEAL"] = true,
}
local HEALER_SPELLS = {
  -- Holy Priest
  [2060] = "PRIEST", -- Heal
  [14914] = "PRIEST", -- Holy Fire
  [596] = "PRIEST", -- Prayer of Healing
  [204883] = "PRIEST", -- Circle of Healing
  [289666] = "PRIEST", -- Greater Heal
  -- Discipline Priest
  [47540] = "PRIEST", -- Penance
  [194509] = "PRIEST", -- Power Word: Radiance
  [214621] = "PRIEST", -- Schism
  [129250] = "PRIEST", -- Power Word: Solace
  [204197] = "PRIEST", -- Purge of the Wicked
  [314867] = "PRIEST", -- Shadow Covenant
  -- Druid
  [102351] = "DRUID", -- Cenarion Ward
  [33763] = "DRUID", -- Nourish
  [81262] = "DRUID", -- Efflorescence
  [391888] = "DRUID", -- Adaptive Swarm -- Shared with Feral
  [392160] = "DRUID", -- Invigorate
  -- Shaman
  [61295] = "SHAMAN", -- Riptide
  [77472] = "SHAMAN", -- Healing Wave
  [73920] = "SHAMAN", -- Healing Rain
  [73685] = "SHAMAN", -- Unleash Life
  [207778] = "SHAMAN", -- Downpour
  -- Paladin
  [275773] = "PALADIN", -- Judgment
  [20473] = "PALADIN", -- Holy Shock
  [82326] = "PALADIN", -- Holy Light
  [85222] = "PALADIN", -- Light of Dawn
  [223306] = "PALADIN", -- Bestow Faith
  [214202] = "PALADIN", -- Rule of Law
  [210294] = "PALADIN", -- Divine Favor
  [114165] = "PALADIN", -- Holy Prism
  [148039] = "PALADIN", -- Barrier of Faith
  -- Monk
  [124682] = "MONK", -- Enveloping Mist
  [191837] = "MONK", -- Essence Font
  [115151] = "MONK", -- Renewing Mist
  [116680] = "MONK", -- Thunder Focus Tea
  [124081] = "MONK", -- Zen Pulse
  [209584] = "MONK", -- Zen Focus Tea
  [205234] = "MONK", -- Healing Sphere
  -- Evoker - Preservation
  [364343] = "EVOKER", -- Echo
  [382614] = "EVOKER", -- Dream Breath
  [366155] = "EVOKER", -- Reversion
  [382731] = "EVOKER", -- Spiritbloom
  [373861] = "EVOKER", -- Temporal Anomaly
}

local activeNPCs = {}

local function GetUnitFrame(nameplate)
  return nameplate.UnitFrame
end

local function GetHealthBarFrame(nameplate)
  local UnitFrame = GetUnitFrame(nameplate)
  return UnitFrame.HealthBarsContainer
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

  local isPlayer = UnitIsPlayer(unit)
  local isNPC = not isPlayer
  local isFriend = UnitIsFriend("player", unit)
  local isEnemy = UnitIsEnemy("player", unit)
  local isArena = NameplateIconsFrame.inArena
  local isBattleground = NameplateIconsFrame.inBattleground
  local isOutdoors = NameplateIconsFrame.isOutdoors

  local hideFriendly = NS.db.nameplate.buffFrames.hideFriendly and (isFriend and isPlayer)
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

  local isPlayer = UnitIsPlayer(unit)
  local isNPC = not isPlayer
  local isFriend = UnitIsFriend("player", unit)
  local isEnemy = UnitIsEnemy("player", unit)
  local isArena = NameplateIconsFrame.inArena
  local isBattleground = NameplateIconsFrame.inBattleground
  local isOutdoors = NameplateIconsFrame.isOutdoors

  local hideFriendly = NS.db.nameplate.castBars.hideFriendly and (isFriend and isPlayer)
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

  local isPlayer = UnitIsPlayer(unit)
  local isNPC = not isPlayer
  local isFriend = UnitIsFriend("player", unit)
  local isEnemy = UnitIsEnemy("player", unit)
  local isArena = NameplateIconsFrame.inArena
  local isBattleground = NameplateIconsFrame.inBattleground
  local isOutdoors = NameplateIconsFrame.isOutdoors

  local hideFriendly = NS.db.nameplate.healthBars.hideFriendly and (isFriend and isPlayer)
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
  local icon = CreateFrame("Frame", "ArenaIconFrame" .. texture, parent)
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
  local icon = CreateFrame("Frame", "ArenaIconFrame" .. texture, parent)
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
  local icon = CreateFrame("Frame", "ArenaIconFrame" .. texture, parent)
  local newIconSize = iconSize * NS.db.healer.scale
  icon:SetSize(newIconSize, newIconSize)
  icon:SetAllPoints(parent)
  icon:Hide()

  CreateHealerTexture(nameplate, icon)

  return icon
end

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
  local hideHealerIndicator = hideTestMode and (hideDead or hidePlayers or hideSelf or hideQuestUnits)

  if hideHealerIndicator then
    if nameplate.nphQuestIndicator ~= nil then
      nameplate.nphQuestIndicator:Hide()
    end
    return
  end

  if not nameplate.nphQuestIndicator then
    nameplate.nphQuestIndicator = CreateQuestIcon(nameplate, nameplate.rbgdAnchorFrame, "quest")
  end

  nameplate.nphQuestIndicator:SetIgnoreParentScale(NS.db.general.ignoreNameplateScale)
  nameplate.nphQuestIndicator:SetIgnoreParentAlpha(NS.db.general.ignoreNameplateAlpha)

  local newIconSize = iconSize * NS.db.quest.scale
  nameplate.nphQuestIndicator:SetSize(newIconSize, newIconSize)

  local offset = {
    x = NS.db.quest.offsetX,
    y = NS.db.quest.offsetY,
  }
  local horizontalPoint = NS.db.quest.position == "LEFT" and "RIGHT" or "LEFT"
  local point = NS.db.quest.position == "TOP" and "BOTTOM" or horizontalPoint
  local horizontalRelativePoint = NS.db.quest.position == "LEFT" and "LEFT" or "RIGHT"
  local relativePoint = NS.db.quest.position == "TOP" and "TOP" or horizontalRelativePoint
  local relativeTo = NS.db.quest.attachToHealthBar and GetHealthBarFrame(nameplate) or nameplate
  nameplate.nphQuestIndicator:ClearAllPoints()
  -- point, relativeTo, relativePoint, x, y
  nameplate.nphQuestIndicator:SetPoint(point, relativeTo, relativePoint, offset.x, offset.y)
  nameplate.nphQuestIndicator:Show()
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
    if nameplate.nphNPCIndicator then
      nameplate.nphNPCIndicator:Hide()
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

  if not nameplate.nphNPCIndicator then
    nameplate.nphNPCIndicator = CreateNPCIcon(nameplate, npcIcon)
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
  local relativeTo = NS.db.npc.attachToHealthBar and GetHealthBarFrame(nameplate) or nameplate
  nameplate.nphNPCIndicator:SetSize(newIconSize, newIconSize)
  nameplate.nphNPCIndicator:ClearAllPoints()
  -- point, relativeTo, relativePoint, x, y
  nameplate.nphNPCIndicator:SetPoint(point, relativeTo, relativePoint, offset.x, offset.y)
  nameplate.nphNPCIndicator:Show()

  do
    local showArenas = NS.db.nameplate.showArena and isArena
    local showBattlegrounds = NS.db.nameplate.showBattleground and isBattleground
    local showOutdoors = NS.db.nameplate.showOutdoors and isOutdoors

    nameplate.nphNPCIndicator.texture:SetIgnoreParentScale(NS.db.general.ignoreNameplateScale)
    -- NEED TO CHANGE THIS TO IGNORE ALPHA WHEN HIDING HEALTHBARS
    if showArenas or showBattlegrounds or showOutdoors then
      if isFriend and NS.db.nameplate.healthBars.hideFriendly then
        nameplate.nphNPCIndicator.texture:SetIgnoreParentAlpha(true)
      elseif isEnemy and NS.db.nameplate.healthBars.hideEnemy then
        nameplate.nphNPCIndicator.texture:SetIgnoreParentAlpha(true)
      else
        nameplate.nphNPCIndicator.texture:SetIgnoreParentAlpha(NS.db.general.ignoreNameplateAlpha)
      end
    else
      nameplate.nphNPCIndicator.texture:SetIgnoreParentAlpha(NS.db.general.ignoreNameplateAlpha)
    end

    nameplate.nphNPCIndicator.texture:SetSize(newIconSize, newIconSize)
    nameplate.nphNPCIndicator.texture:ClearAllPoints()
    nameplate.nphNPCIndicator.texture:SetAllPoints(nameplate.nphNPCIndicator)
    nameplate.nphNPCIndicator.texture:SetTexture(npcIcon)

    nameplate.nphNPCIndicator.glow:SetSize(newIconSize, newIconSize)
    nameplate.nphNPCIndicator.glow:ClearAllPoints()
    nameplate.nphNPCIndicator.glow:SetAllPoints(nameplate.nphNPCIndicator)
    if glowEnabled then
      nameplate.nphNPCIndicator.glow:Show()
    else
      nameplate.nphNPCIndicator.glow:Hide()
    end

    local offsetMultiplier = 0.45
    local widthOffset = newIconSize * offsetMultiplier
    local heightOffset = (newIconSize + 1) * offsetMultiplier

    nameplate.nphNPCIndicator.glowTexture:SetIgnoreParentScale(NS.db.general.ignoreNameplateScale)
    -- NEED TO CHANGE THIS TO IGNORE ALPHA WHEN HIDING HEALTHBARS
    if showArenas or showBattlegrounds or showOutdoors then
      if isFriend and NS.db.nameplate.healthBars.hideFriendly then
        nameplate.nphNPCIndicator.glowTexture:SetIgnoreParentAlpha(true)
      elseif isEnemy and NS.db.nameplate.healthBars.hideEnemy then
        nameplate.nphNPCIndicator.glowTexture:SetIgnoreParentAlpha(true)
      else
        nameplate.nphNPCIndicator.glowTexture:SetIgnoreParentAlpha(NS.db.general.ignoreNameplateAlpha)
      end
    else
      nameplate.nphNPCIndicator.glowTexture:SetIgnoreParentAlpha(NS.db.general.ignoreNameplateAlpha)
    end

    nameplate.nphNPCIndicator.glowTexture:SetVertexColor(npcGlow[1], npcGlow[2], npcGlow[3], npcGlow[4])
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
    nameplate.nphNPCIndicator.glowTexture:SetAlpha(glowEnabled and 1 or 0)
    nameplate.nphNPCIndicator.glowTexture:ClearAllPoints()
    nameplate.nphNPCIndicator.glowTexture:SetPoint(
      "TOPLEFT",
      nameplate.nphNPCIndicator.glow,
      "TOPLEFT",
      -widthOffset,
      widthOffset
    )
    nameplate.nphNPCIndicator.glowTexture:SetPoint(
      "BOTTOMRIGHT",
      nameplate.nphNPCIndicator.glow,
      "BOTTOMRIGHT",
      heightOffset,
      -heightOffset
    )

    -- local _horizontalPoint = NS.db.npc.position == "LEFT" and "RIGHT" or "LEFT"
    -- local _point = NS.db.npc.position == "TOP" and "BOTTOM" or _horizontalPoint
    -- local _horizontalRelativePoint = NS.db.npc.position == "LEFT" and "RIGHT" or "LEFT"
    -- local _relativePoint = NS.db.npc.position == "TOP" and "BOTTOM" or _horizontalRelativePoint

    nameplate.nphNPCIndicator.cooldown:SetSize(newIconSize, newIconSize)
    nameplate.nphNPCIndicator.cooldown:ClearAllPoints()
    nameplate.nphNPCIndicator.cooldown:SetAllPoints(nameplate.nphNPCIndicator)
    -- nameplate.nphNPCIndicator.cooldown:SetPoint(_point, nameplate.nphNPCIndicator, _relativePoint, 0, 1)

    local existingNPC = activeNPCs[guid]
    if existingNPC then
      -- Update the cooldown with the remaining time
      local currentTime = GetTime()
      local elapsed = currentTime - existingNPC.startTime
      local remaining = existingNPC.duration - elapsed
      if remaining > 0 then
        nameplate.nphNPCIndicator.cooldown:SetCooldown(currentTime - elapsed, existingNPC.duration)
      else
        -- Cooldown has expired
        -- if nameplate.nphNPCIndicator.glowTexture then
        --   nameplate.nphNPCIndicator.glowTexture:SetAlpha(0)
        -- end
        -- if nameplate.nphNPCIndicator.glow then
        --   nameplate.nphNPCIndicator.glow:SetHide(0)
        -- end
        -- nameplate.nphNPCIndicator:Hide()
        activeNPCs[guid] = nil
      end
    else
      -- Set new cooldown
      local startTime = GetTime()
      nameplate.nphNPCIndicator.cooldown:SetCooldown(startTime, npcDuration)
      nameplate.nphNPCIndicator.cooldown:SetReverse(true)
      nameplate.nphNPCIndicator.cooldown:SetDrawSwipe(true)
      nameplate.nphNPCIndicator.cooldown:SetDrawEdge(true)
      activeNPCs[guid] = { startTime = startTime, duration = npcDuration }
    end

    if countdownEnabled then
      nameplate.nphNPCIndicator.cooldown:Show()
    else
      nameplate.nphNPCIndicator.cooldown:Hide()
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
  local notTestMode = not NS.db.healer.test
  local hideHealerIndicator = notTestMode
    and (hideNPCs or hideDead or hideSelf or hideAllies or hideEnemies or hideHealers or hideLocation)

  if hideHealerIndicator then
    if nameplate.nphHealerIndicator ~= nil then
      nameplate.nphHealerIndicator:Hide()
    end
    return
  end

  if not nameplate.nphHealerIndicator then
    nameplate.nphHealerIndicator = CreateHealerIcon(nameplate, nameplate.rbgdAnchorFrame, "healer")
  end

  nameplate.nphHealerIndicator:SetIgnoreParentScale(NS.db.general.ignoreNameplateScale)
  nameplate.nphHealerIndicator:SetIgnoreParentAlpha(NS.db.general.ignoreNameplateAlpha)

  local newIconSize = iconSize * NS.db.healer.scale
  nameplate.nphHealerIndicator:SetSize(newIconSize, newIconSize)

  local hasObjective = not isSelf and UnitPvpClassification(unit)
  local hasRaidMarker = not isSelf and GetRaidTargetIndex(unit)
  -- local hasOneIcon = hasObjective or hasRaidMarker
  -- local hasTwoIcons = hasObjective and hasRaidMarker
  local raidMarketOffsetX = hasRaidMarker and (-30 + NS.db.healer.offsetX) or NS.db.healer.offsetX
  local objectiveOffsetX = hasObjective and (-5 + NS.db.healer.offsetX) or NS.db.healer.offsetX
  local offsetLeft = NS.db.healer.attachToHealthBar and NS.db.healer.offsetX or (raidMarketOffsetX or objectiveOffsetX)
  local offsetRight = NS.db.healer.offsetX
  local offset = {
    x = NS.db.healer.position == "LEFT" and offsetLeft or offsetRight,
    y = NS.db.healer.offsetY,
  }
  local point = NS.db.healer.position == "LEFT" and "RIGHT" or "LEFT"
  local relativePoint = NS.db.healer.position == "LEFT" and "LEFT" or "RIGHT"
  local relativeTo = NS.db.healer.attachToHealthBar and GetHealthBarFrame(nameplate) or nameplate
  nameplate.nphHealerIndicator:ClearAllPoints()
  -- point, relativeTo, relativePoint, x, y
  nameplate.nphHealerIndicator:SetPoint(point, relativeTo, relativePoint, offset.x, offset.y)
  nameplate.nphHealerIndicator:Show()
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

  local notTestMode = not NS.db.class.test
  local hideClassIndicator = notTestMode
    and (hideNPCs or hideSelf or hideDead or hideAllies or hideEnemies or hideLocation)

  if hideClassIndicator then
    if nameplate.nphClassIndicator then
      nameplate.nphClassIndicator:Hide()
    end
    return
  end

  if not nameplate.nphClassIndicator then
    nameplate.nphClassIndicator = CreateClassIcon(nameplate, nameplate.rbgdAnchorFrame, "class")
  end

  nameplate.nphClassIndicator.texture:SetIgnoreParentScale(NS.db.general.ignoreNameplateScale)
  -- NEED TO CHANGE THIS TO IGNORE ALPHA WHEN HIDING HEALTHBARS
  local showArenas = NS.db.nameplate.showArena and isArena
  local showBattlegrounds = NS.db.nameplate.showBattleground and isBattleground
  local showOutdoors = NS.db.nameplate.showOutdoors and isOutdoors
  if showArenas or showBattlegrounds or showOutdoors then
    if isFriend and NS.db.nameplate.healthBars.hideFriendly then
      nameplate.nphClassIndicator.texture:SetIgnoreParentAlpha(true)
    elseif isEnemy and NS.db.nameplate.healthBars.hideEnemy then
      nameplate.nphClassIndicator.texture:SetIgnoreParentAlpha(true)
    else
      nameplate.nphClassIndicator.texture:SetIgnoreParentAlpha(NS.db.general.ignoreNameplateAlpha)
    end
  else
    nameplate.nphClassIndicator.texture:SetIgnoreParentAlpha(NS.db.general.ignoreNameplateAlpha)
  end

  local newIconSize = iconSize * NS.db.class.scale
  nameplate.nphClassIndicator:SetSize(newIconSize, newIconSize)

  local texturePath = GetClassIcon(unit)
  nameplate.nphClassIndicator.texture:SetTexture(texturePath)

  -- local coords = GetClassCoords(unit)
  -- if coords then
  --   nameplate.nphClassIndicator.texture:SetTexCoord(unpack(coords))
  -- end

  local zoom = 0
  local textureWidth = 1 - 0.5 * zoom
  local ulx, uly, llx, lly, urx, ury, lrx, lry =
    GetTextureCoord(nameplate.nphClassIndicator.texture, textureWidth, 1, 0, 0)
  nameplate.nphClassIndicator.texture:SetTexCoord(ulx, uly, llx, lly, urx, ury, lrx, lry)

  local r, g, b, a = GetClassColor(nameplate, unit)
  if r and g and b and a then
    nameplate.nphClassIndicator.border:SetVertexColor(r, g, b, a)
  end

  -- nameplate.nphClassIndicator.border:SetAllPoints(nameplate.nphClassIndicator)
  local offsetMultiplier = 0 -- 0.25
  local widthOffset = newIconSize * offsetMultiplier
  local heightOffset = (newIconSize + 1) * offsetMultiplier
  nameplate.nphClassIndicator.border:SetPoint(
    "TOPLEFT",
    nameplate.nphClassIndicator,
    "TOPLEFT",
    -widthOffset,
    widthOffset
  )
  nameplate.nphClassIndicator.border:SetPoint(
    "BOTTOMRIGHT",
    nameplate.nphClassIndicator,
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
  local relativeTo = NS.db.class.attachToHealthBar and GetHealthBarFrame(nameplate) or nameplate
  nameplate.nphClassIndicator:ClearAllPoints()
  -- point, relativeTo, relativePoint, x, y
  nameplate.nphClassIndicator:SetPoint(point, relativeTo, relativePoint, offset.x, offset.y)
  nameplate.nphClassIndicator:Show()
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
  local notTestMode = not NS.db.arrow.test
  local hideArrowIndicator = notTestMode
    and (hideNPCs or hideSelf or hideDead or hideAllies or hideEnemies or hideLocation)

  if hideArrowIndicator then
    if nameplate.nphArrowIndicator then
      nameplate.nphArrowIndicator:Hide()
    end
    return
  end

  if not nameplate.nphArrowIndicator then
    nameplate.nphArrowIndicator = CreateArrowIcon(nameplate, nameplate.rbgdAnchorFrame, "arrow")
  end

  nameplate.nphArrowIndicator.texture:SetIgnoreParentScale(NS.db.general.ignoreNameplateScale)
  -- NEED TO CHANGE THIS TO IGNORE ALPHA WHEN HIDING HEALTHBARS
  local showArenas = NS.db.nameplate.showArena and isArena
  local showBattlegrounds = NS.db.nameplate.showBattleground and isBattleground
  local showOutdoors = NS.db.nameplate.showOutdoors and isOutdoors
  if showArenas or showBattlegrounds or showOutdoors then
    if isFriend and NS.db.nameplate.healthBars.hideFriendly then
      nameplate.nphArrowIndicator.texture:SetIgnoreParentAlpha(true)
    elseif isEnemy and NS.db.nameplate.healthBars.hideEnemy then
      nameplate.nphArrowIndicator.texture:SetIgnoreParentAlpha(true)
    else
      nameplate.nphArrowIndicator.texture:SetIgnoreParentAlpha(NS.db.general.ignoreNameplateAlpha)
    end
  else
    nameplate.nphArrowIndicator.texture:SetIgnoreParentAlpha(NS.db.general.ignoreNameplateAlpha)
  end

  local iconWidth = 55
  local iconHeight = 70
  local newIconWidth = iconWidth * NS.db.arrow.scale
  local newIconHeight = iconHeight * NS.db.arrow.scale
  nameplate.nphArrowIndicator:SetSize(newIconWidth, newIconHeight)

  local r, g, b, a = GetClassColor(nameplate, unit)
  if r and g and b and a then
    nameplate.nphArrowIndicator.texture:SetVertexColor(r, g, b, a)
  end

  local offset = {
    x = NS.db.arrow.offsetX,
    y = NS.db.arrow.offsetY,
  }
  local horizontalPoint = NS.db.arrow.position == "LEFT" and "RIGHT" or "LEFT"
  local point = NS.db.arrow.position == "TOP" and "BOTTOM" or horizontalPoint
  local horizontalRelativePoint = NS.db.arrow.position == "LEFT" and "LEFT" or "RIGHT"
  local relativePoint = NS.db.arrow.position == "TOP" and "TOP" or horizontalRelativePoint
  local relativeTo = NS.db.arrow.attachToHealthBar and GetHealthBarFrame(nameplate) or nameplate
  nameplate.nphArrowIndicator:ClearAllPoints()
  -- point, relativeTo, relativePoint, x, y
  nameplate.nphArrowIndicator:SetPoint(point, relativeTo, relativePoint, offset.x, offset.y)
  nameplate.nphArrowIndicator:Show()
end

function NameplateIcons:detachFromNameplate(nameplate)
  if nameplate.nphArrowIndicator ~= nil then
    nameplate.nphArrowIndicator:Hide()
  end
  if nameplate.nphClassIndicator ~= nil then
    nameplate.nphClassIndicator:Hide()
  end
  if nameplate.nphHealerIndicator ~= nil then
    nameplate.nphHealerIndicator:Hide()
  end
  if nameplate.nphNPCIndicator ~= nil then
    nameplate.nphNPCIndicator:Hide()
    if nameplate.UnitFrame then
      CompactUnitFrame_UpdateHealthColor(nameplate.UnitFrame)
      CompactUnitFrame_UpdateName(nameplate.UnitFrame)
    end
  end
  if nameplate.nphQuestIndicator ~= nil then
    nameplate.nphQuestIndicator:Hide()
  end
end

function NameplateIcons:attachToNameplate(nameplate, guid)
  if not nameplate.rbgdAnchorFrame then
    local attachmentFrame = GetHealthBarFrame(nameplate)
    nameplate.rbgdAnchorFrame = CreateFrame("Frame", nil, attachmentFrame)
    nameplate.rbgdAnchorFrame:SetFrameStrata("HIGH")
    nameplate.rbgdAnchorFrame:SetFrameLevel(attachmentFrame:GetFrameLevel() + 1)
  end

  checkIsHealer(nameplate, guid)
  hideHealthBars(nameplate, guid)
  hideNames(nameplate, guid)
  hideCastBars(nameplate, guid)
  hideBuffFrames(nameplate, guid)

  if NS.db.arrow.enabled then
    addArrowIndicator(nameplate, guid)
  else
    if nameplate.nphArrowIndicator ~= nil then
      nameplate.nphArrowIndicator:Hide()
    end
  end
  if NS.db.class.enabled then
    addClassIndicator(nameplate, guid)
  else
    if nameplate.nphClassIndicator ~= nil then
      nameplate.nphClassIndicator:Hide()
    end
  end
  if NS.db.healer.enabled then
    addHealerIndicator(nameplate, guid)
  else
    if nameplate.nphHealerIndicator ~= nil then
      nameplate.nphHealerIndicator:Hide()
    end
  end
  if NS.db.npc.enabled then
    addNPCIndicator(nameplate, guid)
  else
    if nameplate.nphNPCIndicator ~= nil then
      nameplate.nphNPCIndicator:Hide()
    end
  end
  if NS.db.quest.enabled then
    addQuestIndicator(nameplate, guid)
  else
    if nameplate.nphQuestIndicator ~= nil then
      nameplate.nphQuestIndicator:Hide()
    end
  end
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

--[[
1. timestamp: number
2. subevent: string
3. hideCaster: boolean
4. sourceGUID: string
5. sourceName: string
6. sourceFlags: number
7. sourceRaidFlags: number
8. destGUID: string
9. destName: string
10. destFlags: number
11. destRaidFlags: number
-- extra for certain subevent types
--]]
function NameplateIcons:COMBAT_LOG_EVENT_UNFILTERED()
  local _, subevent, _, sourceGUID, _, _, _, destGUID, _, destFlags = CombatLogGetCurrentEventInfo()
  if not (sourceGUID or destGUID) then
    return
  end
  local isMindControlled = false
  local isNotPetOrPlayer = false
  local isPlayer = bband(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0
  if not isPlayer then
    if sfind(destGUID, "Player-") then
      -- Players have same bitmask as player pets when they're mindcontrolled and MC aura breaks, so we need to distinguish these
      -- so we can ignore the player pets but not actual players
      isMindControlled = true
    end
    if not isMindControlled then
      return
    end
    if bband(destFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) <= 0 then -- is not player pet or is not MCed
      isNotPetOrPlayer = true
    end
  end
  local spellId = select(12, CombatLogGetCurrentEventInfo())
  if spellId then
    if HEALER_SPELL_EVENTS[subevent] and HEALER_SPELLS[spellId] then
      if not Healers[sourceGUID] then
        Healers[sourceGUID] = true
      end
    end
  end
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
  NameplateIconsFrame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")

  if IsInInstance() then
    NameplateIconsFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  else
    NameplateIconsFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  end
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
