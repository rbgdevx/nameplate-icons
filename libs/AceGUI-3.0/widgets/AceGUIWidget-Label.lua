--[[-----------------------------------------------------------------------------
Label Widget
Displays text and optionally an icon.
-------------------------------------------------------------------------------]]
local Type, Version = "Label", 28
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then
  return
end

-- Lua APIs
local max, select, pairs, ipairs, unpack = math.max, select, pairs, ipairs, unpack

-- WoW APIs
local CreateFrame, UIParent = CreateFrame, UIParent

--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]
---

local function GetClassIcon(unit)
  local _, classFilename = UnitClass(unit)
  local _, fallbackFilename = UnitClass("player")
  local start = "interface/icons/classicon_"
  local middle = classFilename and classFilename:lower() or fallbackFilename:lower()
  local ending = ".blp"
  return start .. middle .. ending
end

local function GetClassCoords(unit)
  local _, class = UnitClass(unit)
  local coords = CLASS_ICON_TCOORDS[class]
  return coords
end

local function GetClassColor(unit)
  local _, class = UnitClass(unit)
  local colors = RAID_CLASS_COLORS[class]
  if (UnitIsPlayer(unit) or UnitTreatAsPlayerForDisplay(unit)) and colors then
    return colors.r, colors.g, colors.b, 1.0
  else
    local resultR, resultG, resultB, resultA = UnitSelectionColor(unit, true)
    return resultR, resultG, resultB, resultA
  end
end

local function ParseTextureString(input)
  if input == "class" then
    return "class", false
  end

  local _texture, isTexture = input:match("([^x]+)x([^x]+)")
  if isTexture and isTexture == "tecture" then
    return _texture, "texture"
  end

  local _texture, isAtlas = input:match("([^x]+)x([^x]+)")
  if isAtlas and isAtlas == "atlas" then
    return _texture, "atlas"
  end

  -- Split the string into texture and RGBA parts
  local texture, rgba, glowEnabled = input:match("([^x]+)x([^x]+)x([^x]+)")
  if not texture or not rgba or not glowEnabled then
    return nil, nil, nil, nil, nil, nil
  end

  -- Convert RGBA values from the second part
  local r, g, b, a = rgba:match("(%d*%.?%d+),(%d*%.?%d+),(%d*%.?%d+),(%d*%.?%d+)")
  if not r or not g or not b or not a then
    return nil, nil, nil, nil, nil, nil
  end

  local showGlow = glowEnabled == "true" and true or false

  -- Return parsed values
  return tonumber(texture), tonumber(r), tonumber(g), tonumber(b), tonumber(a), showGlow
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

local function UpdateImageAnchor(self)
  if self.resizing then
    return
  end
  local frame = self.frame
  local width = frame.width or frame:GetWidth() or 0
  local image = self.image
  local label = self.label
  local height

  label:ClearAllPoints()
  image:ClearAllPoints()

  if self.imageshown then
    local imagewidth = image:GetWidth()
    if (width - imagewidth) < 200 or (label:GetText() or "") == "" then
      -- image goes on top centered when less than 200 width for the text, or if there is no text
      image:SetPoint("TOP")
      label:SetPoint("TOP", image, "BOTTOM")
      label:SetPoint("LEFT")
      label:SetWidth(width)
      height = image:GetHeight() + label:GetStringHeight()

      if self.icon then
        self.icon.glow:SetFrameStrata(self.frame:GetFrameStrata())
        self.icon.glow:SetFrameLevel(self.frame:GetFrameLevel() + 8)
        self.icon.glow:SetPoint("TOPLEFT", image, "TOPLEFT", 0, 0)
      end
    else
      local offset = {
        x = self.npc == true and 30 or 0,
        y = self.npc == true and -25 or 0,
      }
      -- image on the left
      image:SetPoint("TOPLEFT", frame, "TOPLEFT", offset.x, offset.y)
      if image:GetHeight() > label:GetStringHeight() then
        label:SetPoint("LEFT", image, "RIGHT", 4, 0)
      else
        label:SetPoint("TOPLEFT", image, "TOPRIGHT", 4, 0)
      end
      label:SetWidth(width - imagewidth - 4)
      height = max(image:GetHeight(), label:GetStringHeight())

      if self.icon then
        self.icon.glow:SetFrameStrata(self.frame:GetFrameStrata())
        self.icon.glow:SetFrameLevel(self.frame:GetFrameLevel() + 8)
        self.icon.glow:SetPoint("TOPLEFT", image, "TOPLEFT", 0, 0)
      end
    end
  else
    -- no image shown
    label:SetPoint("TOPLEFT")
    label:SetWidth(width)
    height = label:GetStringHeight()
  end

  -- avoid zero-height labels, since they can used as spacers
  if not height or height == 0 then
    height = 1
  end

  self.resizing = true
  frame:SetHeight(height)
  frame.height = height
  self.resizing = nil
end

local function CreateGlow(owner, texture)
  local icon = {}

  local iconSize = 64
  local offsetMultiplier = 0.45
  local widthOffset = iconSize * offsetMultiplier
  local heightOffset = (iconSize + 3) * offsetMultiplier

  local glowFrame = _G["EditGlowFrame" .. texture]

  icon.glow = glowFrame or CreateFrame("Frame", "EditGlowFrame" .. texture, owner.frame)
  icon.glow:SetSize(iconSize, iconSize)
  icon.glow:SetFrameStrata(owner.frame:GetFrameStrata())
  icon.glow:SetFrameLevel(owner.frame:GetFrameLevel() + 8)
  icon.glow:ClearAllPoints()
  icon.glow:SetPoint("TOPLEFT", owner.frame, "TOPLEFT", 30, -25)
  icon.glow:Hide()

  icon.glowTexture = owner.frame:CreateTexture(nil, "OVERLAY")
  icon.glowTexture:SetBlendMode("BLEND")
  icon.glowTexture:SetDesaturated(true)
  icon.glowTexture:ClearAllPoints()
  icon.glowTexture:SetPoint("TOPLEFT", icon.glow, "TOPLEFT", -widthOffset, widthOffset)
  icon.glowTexture:SetPoint("BOTTOMRIGHT", icon.glow, "BOTTOMRIGHT", heightOffset, -heightOffset)
  icon.glowTexture:SetAlpha(0)

  icon.glow.glowTexture = icon.glowTexture

  owner.icon = icon
end

local function CreateMask(owner)
  if not owner.mask then
    local iconSize = owner.image:GetWidth()
    local newIconSize = iconSize * 2

    local mask = owner.frame:CreateMaskTexture()
    mask:SetTexture("Interface/Masks/CircleMaskScalable")
    mask:SetSize(newIconSize, newIconSize)
    mask:SetAllPoints(owner.image)

    local border = owner.frame:CreateTexture(nil, "OVERLAY")
    border:SetAtlas("ui-frame-genericplayerchoice-portrait-border")
    border:SetBlendMode("BLEND")
    border:SetDesaturated(true)
    local offsetMultiplier = 0 -- 0.25
    local widthOffset = newIconSize * offsetMultiplier
    local heightOffset = (newIconSize + 1) * offsetMultiplier
    border:SetPoint("TOPLEFT", owner.frame, "TOPLEFT", -widthOffset, widthOffset)
    border:SetPoint("BOTTOMRIGHT", owner.frame, "BOTTOMRIGHT", heightOffset, -heightOffset)

    owner.mask = mask
    owner.border = border
  end
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
  ["OnAcquire"] = function(self)
    -- set the flag to stop constant size updates
    self.resizing = true
    -- height is set dynamically by the text and image size
    self:SetWidth(200)
    self:SetText()
    self:SetImage(nil)
    self:SetImageSize(16, 16)
    self:SetColor()
    self:SetFontObject()
    self:SetJustifyH("LEFT")
    self:SetJustifyV("TOP")

    -- reset the flag
    self.resizing = nil
    -- run the update explicitly
    UpdateImageAnchor(self)
  end,

  -- ["OnRelease"] = nil,

  ["OnWidthSet"] = function(self, width)
    UpdateImageAnchor(self)
  end,

  ["SetText"] = function(self, text)
    self.label:SetText(text)
    UpdateImageAnchor(self)
  end,

  ["SetColor"] = function(self, r, g, b)
    if not (r and g and b) then
      r, g, b = 1, 1, 1
    end
    self.label:SetVertexColor(r, g, b)
  end,

  ["SetImage"] = function(self, path, ...)
    local image = self.image

    if path then
      local texture, isAtlas = ParseTextureString(path)
      if texture then
        if isAtlas and isAtlas == "atlas" then
          image:SetAtlas(texture)
        elseif texture == "class" then
          -- image:SetTexture("Interface/GLUES/CHARACTERCREATE/UI-CHARACTERCREATE-CLASSES")
          local texturePath = GetClassIcon("player")
          image:SetTexture(texturePath)
        else
          image:SetTexture(texture)
        end
      end
    else
      image:SetTexture(path)
    end

    if image:GetTexture() then
      self.imageshown = true

      local texture, r, g, b, a, showGlow = ParseTextureString(path)

      self.isAtlas = r == "atlas"
      self.isTexture = r == "texture"

      CreateMask(self)

      if r ~= "atlas" and r ~= "texture" then
        image:SetDesaturated(false)

        local degrees = 0
        local radians = math.rad(degrees)
        image:SetRotation(radians)

        if texture == "class" then
          self.npc = false

          local zoom = 0
          local texWidth = 1 - 0.5 * zoom
          local ulx, uly, llx, lly, urx, ury, lrx, lry = GetTextureCoord(image, texWidth, 1, 0, 0)
          image:SetTexCoord(ulx, uly, llx, lly, urx, ury, lrx, lry)

          local count = image:GetNumMaskTextures()

          image:SetVertexColor(1, 1, 1, 1)

          if self.mask then
            if count == 0 then
              image:AddMaskTexture(self.mask)
            end
          end

          if self.border then
            local _r, _g, _b, _a = GetClassColor("player")
            if _r and _g and _b and _a then
              self.border:SetVertexColor(_r, _g, _b, _a)
            end
            self.border:SetAllPoints(image)
            self.border:SetAlpha(1)
          end
        else
          self.npc = true

          CreateGlow(self, texture)

          if self.mask then
            image:RemoveMaskTexture(self.mask)
          end
          if self.border then
            self.border:ClearAllPoints()
            self.border:SetVertexColor(1, 1, 1, 0)
            self.border:SetAlpha(0)
          end

          local zoom = 0.20
          local texWidth = 1 - 0.5 * zoom
          local ulx, uly, llx, lly, urx, ury, lrx, lry = GetTextureCoord(image, texWidth, 1, 0, 0)
          image:SetTexCoord(ulx, uly, llx, lly, urx, ury, lrx, lry)

          if self.icon then
            self.icon.glowTexture:SetAtlas("clickcast-highlight-spellbook")

            if r and g and b and a then
              self.icon.glowTexture:SetVertexColor(r, g, b, a)
            end

            self.icon.glowTexture:SetAlpha(showGlow and 1 or 0)

            if showGlow then
              self.icon.glow:Show()
            else
              self.icon.glow:Hide()
            end
          end
        end
      else
        self.npc = false

        if self.icon then
          self.icon.glow:Hide()
        end

        if self.mask then
          image:RemoveMaskTexture(self.mask)
        end

        if self.border then
          self.border:ClearAllPoints()
          self.border:SetVertexColor(1, 1, 1, 0)
          self.border:SetAlpha(0)
        end

        if texture == "covenantsanctum-renown-doublearrow-depressed" then
          image:SetBlendMode("BLEND")
          image:SetDesaturated(true)
          local _, class = UnitClass("player")
          local colors = RAID_CLASS_COLORS[class]
          image:SetVertexColor(colors.r, colors.g, colors.b)
          local degrees = 90
          local radians = math.rad(degrees)
          image:SetRotation(radians)
        else
          image:SetDesaturated(false)
          image:SetVertexColor(1, 1, 1, 1)
          local degrees = 0
          local radians = math.rad(degrees)
          image:SetRotation(radians)
        end

        local zoom = 0
        local texWidth = 1 - 0.5 * zoom
        local ulx, uly, llx, lly, urx, ury, lrx, lry = GetTextureCoord(image, texWidth, 1, 0, 0)
        image:SetTexCoord(ulx, uly, llx, lly, urx, ury, lrx, lry)
      end
    else
      self.imageshown = nil

      if self.icon then
        self.icon.glowTexture:SetAlpha(0)
        self.icon.glowTexture:SetTexture(nil)
        self.icon.glow:Hide()
      end
    end
    UpdateImageAnchor(self)
  end,

  ["SetFont"] = function(self, font, height, flags)
    if not self.fontObject then
      self.fontObject = CreateFont("AceGUI40LabelFont" .. AceGUI:GetNextWidgetNum(Type))
    end
    self.fontObject:SetFont(font, height, flags)
    self:SetFontObject(self.fontObject)
  end,

  ["SetFontObject"] = function(self, font)
    self.label:SetFontObject(font or GameFontHighlightSmall)
    UpdateImageAnchor(self)
  end,

  ["SetImageSize"] = function(self, width, height)
    self.image:SetWidth(width)
    self.image:SetHeight(height)
    UpdateImageAnchor(self)
  end,

  ["SetJustifyH"] = function(self, justifyH)
    self.label:SetJustifyH(justifyH)
  end,

  ["SetJustifyV"] = function(self, justifyV)
    self.label:SetJustifyV(justifyV)
  end,
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
  local frame = CreateFrame("Frame", nil, UIParent)
  frame:Hide()

  local label = frame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
  local image = frame:CreateTexture(nil, "BACKGROUND")

  -- create widget
  local widget = {
    label = label,
    image = image,
    frame = frame,
    type = Type,
  }
  for method, func in pairs(methods) do
    widget[method] = func
  end

  return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
