local AddonName, NS = ...

local type = type
local error = error
local pairs = pairs
local UnitName = UnitName
local GetRealmName = GetRealmName
local next = next
local rawget = rawget
local UnitClass = UnitClass

local AceGUI = LibStub("AceGUI-4.0")
local AceSerializer = LibStub("AceSerializer-4.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-4.0")

local ProfilesFrame = {}
ProfilesFrame.optionTables = ProfilesFrame.optionTables or {}
ProfilesFrame.handlers = ProfilesFrame.handlers or {}

local defaultProfiles
local tmpProfiles = {}
local DBObjectLib = {}

NS.REALM_NAME = GetRealmName()
NS.PLAYER_NAME = UnitName("player")
NS.CHAR_NAME = NS.PLAYER_NAME .. "-" .. NS.REALM_NAME

--- Copies a named profile into the current profile, overwriting any conflicting
-- settings.
-- @param name The name of the profile to be copied into the current profile
-- @param silent If true, do not raise an error when the profile does not exist
function DBObjectLib:CopyProfile(name, silent)
  if type(name) ~= "string" then
    error(("Usage: CopyProfile(name): 'name' - string expected, got %q."):format(type(name)), 2)
  end

  if name == NS.activeProfile then
    error(("Cannot have the same source and destination profiles (%q)."):format(name), 2)
  end

  if not rawget(NameplateIconsDB.profiles, name) and not silent then
    error(("Cannot copy profile %q as it does not exist."):format(name), 2)
  end

  local profile = NS.activeProfile
  local source = NameplateIconsDB.profiles[name]

  -- Reset the profile before copying
  NameplateIconsDB.profiles[profile] = nil -- delete all values no matter what
  NameplateIconsDB.profiles[profile] = NS.CopyTable(source)

  -- Copy any default settings if they don't exists in copied profile
  NS.CopyDefaults({
    [profile] = NS.DefaultDatabase,
  }, NameplateIconsDB.profiles)

  NS.db = NameplateIconsDB.profiles[profile]

  NS.OnDbChanged()
end

--- Resets the current profile to the default values (if specified).
-- @param noChildren if set to true, the reset will not be populated to the child namespaces of this DB object
-- @param noCallbacks if set to true, won't fire the OnProfileReset callback
function DBObjectLib:ResetProfile()
  local profile = NS.activeProfile

  for k, _ in pairs(profile) do
    profile[k] = nil
  end

  NameplateIconsDB.profiles[profile] = NS.CopyTable(NS.DefaultDatabase, NameplateIconsDB.profiles[profile])
  NS.db = NameplateIconsDB.profiles[profile]

  NS.OnDbChanged()
end

--- Deletes a named profile.  This profile must not be the active profile.
-- @param name The name of the profile to be deleted
-- @param silent If true, do not raise an error when the profile does not exist
function DBObjectLib:DeleteProfile(name, silent)
  if type(name) ~= "string" then
    error(("Usage: DeleteProfile(name): 'name' - string expected, got %q."):format(type(name)), 2)
  end

  if name == NS.activeProfile then
    error(("Cannot delete the active profile (%q)."):format(name), 2)
  end

  if not rawget(NameplateIconsDB.profiles, name) and not silent then
    error(("Cannot delete profile %q as it does not exist."):format(name), 2)
  end

  -- NameplateIconsDB.profileKeys[name] = nil
  NameplateIconsDB.profiles[name] = nil

  -- switch all characters that use this profile back to the default
  if NameplateIconsDB.profileKeys then
    for key, profile in pairs(NameplateIconsDB.profileKeys) do
      if profile == name then
        NameplateIconsDB.profileKeys[key] = nil
      end
    end
  end
end

--- Changes the profile of the database and all of it's namespaces to the
-- supplied named profile
-- @param name The name of the profile to set as the current profile
function DBObjectLib:SetProfile(name)
  if type(name) ~= "string" then
    error(("Usage: SetProfile(name): 'name' - string expected, got %q."):format(type(name)), 2)
  end

  -- changing to the same profile, don't do anything
  if name == NS.activeProfile then
    error(("That profile is already active."):format(name), 2)
    return
  end

  NameplateIconsDB.profileKeys[NS.CHAR_NAME] = name

  -- Copy any default settings if they don't exists in copied profile
  NS.CopyDefaults({
    [name] = NS.DefaultDatabase,
  }, NameplateIconsDB.profiles)

  NS.db = NameplateIconsDB.profiles[name]
  NS.activeProfile = name

  NS.OnDbChanged()
end

--- Returns a table with the names of the existing profiles in the database.
-- You can optionally supply a table to re-use for this purpose.
-- @param tbl A table to store the profile names in (optional)
function DBObjectLib:GetProfiles(tbl)
  if tbl and type(tbl) ~= "table" then
    error(("Usage: GetProfiles(tbl): 'tbl' - table or nil expected, got %q."):format(type(tbl)), 2)
  end

  -- Clear the container table
  if tbl then
    for k, _ in pairs(tbl) do
      tbl[k] = nil
    end
  else
    tbl = {}
  end

  local curProfile = NS.activeProfile

  local i = 0
  for profileKey in pairs(NameplateIconsDB.profiles) do
    i = i + 1
    tbl[i] = profileKey
    if curProfile and profileKey == curProfile then
      curProfile = nil
    end
  end

  -- Add the current profile, if it hasn't been created yet
  if curProfile then
    i = i + 1
    tbl[i] = curProfile
  end

  return tbl, i
end

--- Returns the current profile name used by the database
function DBObjectLib:GetCurrentProfile()
  return NameplateIconsDB.profileKeys[NS.CHAR_NAME]
end

-- Get a list of available profiles for the specified database.
-- You can specify which profiles to include/exclude in the list using the two boolean parameters listed below.
-- @param db The db object to retrieve the profiles from
-- @param common If true, getProfileList will add the default profiles to the return list, even if they have not been created yet
-- @param nocurrent If true, then getProfileList will not display the current profile in the list
-- @return Hashtable of all profiles with the internal name as keys and the display name as value.
local function getProfileList(_, common, nocurrent)
  local profiles = {}

  -- copy existing profiles into the table
  local currentProfile = DBObjectLib:GetCurrentProfile()
  for _, v in pairs(DBObjectLib:GetProfiles(tmpProfiles)) do
    if not (nocurrent and v == currentProfile) then
      profiles[v] = v
    end
  end

  -- add our default profiles to choose from ( or rename existing profiles)
  for k, v in pairs(defaultProfiles) do
    if (common or profiles[k]) and not (nocurrent and k == currentProfile) then
      profiles[k] = v
    end
  end

  return profiles
end

--[[
	OptionsHandlerPrototype
	prototype class for handling the options in a sane way
]]
local OptionsHandlerPrototype = {}

--[[ Reset the profile ]]
function OptionsHandlerPrototype:Reset()
  DBObjectLib:ResetProfile()
end

--[[ Set the profile to value ]]
function OptionsHandlerPrototype:SetProfile(info, value)
  DBObjectLib:SetProfile(value)
end

--[[ returns the currently active profile ]]
function OptionsHandlerPrototype:GetCurrentProfile()
  return DBObjectLib:GetCurrentProfile()
end

--[[
	List all active profiles
	you can control the output with the .arg variable
	currently four modes are supported
	(empty) - return all available profiles
	"nocurrent" - returns all available profiles except the currently active profile
	"common" - returns all available profiles + some commonly used profiles ("char - realm", "realm", "class", "Default")
	"both" - common except the active profile
]]
function OptionsHandlerPrototype:ListProfiles(info)
  local arg = info.arg
  local profiles
  if arg == "common" and not self.noDefaultProfiles then
    profiles = getProfileList(self.db, true, nil)
  elseif arg == "nocurrent" then
    profiles = getProfileList(self.db, nil, true)
  elseif arg == "both" then -- currently not used
    profiles = getProfileList(self.db, (not self.noDefaultProfiles) and true, true)
  else
    profiles = getProfileList(self.db)
  end
  return profiles
end

function OptionsHandlerPrototype:HasNoProfiles(info)
  local profiles = self:ListProfiles(info)
  return ((not next(profiles)) and true or false)
end

--[[ Copy a profile ]]
function OptionsHandlerPrototype:CopyProfile(info, value)
  DBObjectLib:CopyProfile(value)
end

--[[ Delete a profile from the db ]]
function OptionsHandlerPrototype:DeleteProfile(info, value)
  DBObjectLib:DeleteProfile(value)
end

--[[ fill defaultProfiles with some generic values ]]
local function generateDefaultProfiles()
  local realm = NS.REALM_NAME
  local char = NS.CHAR_NAME
  local _, class = UnitClass("player")
  defaultProfiles = {
    ["Default"] = "Default",
    [char] = char,
    [realm] = realm,
    [class] = class,
  }
end

--[[ create and return a handler object for the db, or upgrade it if it already existed ]]
NS.getOptionsHandler = function(db, noDefaultProfiles)
  if not defaultProfiles then
    generateDefaultProfiles()
  end

  local handler = ProfilesFrame.handlers[db] or { db = db, noDefaultProfiles = noDefaultProfiles }

  for k, v in pairs(OptionsHandlerPrototype) do
    handler[k] = v
  end

  ProfilesFrame.handlers[db] = handler

  return handler
end

-- Export
local export = AceGUI:Create("Frame")
export:SetWidth(550)
export:EnableResize(false)
export:SetStatusText("")
export:SetLayout("Flow")
export:SetTitle("Export")
export:SetStatusText("Copy this code to share the active NameplateIcons profile.")
export:Hide()

local exportEditBox = AceGUI:Create("MultiLineEditBox")
exportEditBox:SetLabel("")
exportEditBox:SetNumLines(29)
exportEditBox:SetText("")
exportEditBox:SetFullWidth(true)
exportEditBox:SetWidth(500)
exportEditBox.button:Hide()
exportEditBox.frame:SetClipsChildren(true)
export:AddChild(exportEditBox)
export.editBox = exportEditBox

NS.export = export

-- Import
local import = AceGUI:Create("Frame")
import:SetWidth(550)
import:EnableResize(false)
import:SetStatusText("")
import:SetLayout("Flow")
import:SetTitle("Import")
import:Hide()

local importEditBox = AceGUI:Create("MultiLineEditBox")
importEditBox:SetLabel("")
importEditBox:SetNumLines(25)
importEditBox:SetText("")
importEditBox:SetFullWidth(true)
importEditBox:SetWidth(500)
importEditBox.button:Hide()
importEditBox.frame:SetClipsChildren(true)
import:AddChild(importEditBox)
import.editBox = importEditBox

local importButton = AceGUI:Create("Button")
importButton:SetWidth(100)
importButton:SetText("Import")
importButton:SetCallback("OnClick", function()
  local data = import.data
  if not data then
    return
  end
  if NS.ImportProfile(data) then
    import:Hide()
  end
end)
import:AddChild(importButton)
import.button = importButton
importEditBox:SetCallback("OnTextChanged", function(widget)
  local data = NS.Decode(widget:GetText())
  if not data then
    return
  end
  import.statustext:SetTextColor(0, 1, 0)
  import:SetStatusText("Ready to import")
  importButton:SetDisabled(false)
  import.data = data
end)

NS.import = import

NS.ImportError = function(message)
  if (not message) or NS.import.editBox.editBox:GetNumLetters() == 0 then
    NS.import.statustext:SetTextColor(1, 0.82, 0)
    NS.import:SetStatusText("Paste a code to import an NameplateIcons profile.")
  else
    NS.import.statustext:SetTextColor(1, 0, 0)
    NS.import:SetStatusText(("Import failed (%s)"):format(message))
  end
  NS.import.button:SetDisabled(true)
end

NS.Decode = function(encoded)
  local LibDeflate = LibStub:GetLibrary("LibDeflate")
  local decoded = LibDeflate:DecodeForPrint(encoded)
  if not decoded then
    return NS.ImportError("DecodeForPrint")
  end
  local decompressed = LibDeflate:DecompressZlib(decoded)
  if not decompressed then
    return NS.ImportError("DecompressZlib")
  end
  local success, deserialized = AceSerializer:Deserialize(decompressed)
  if not success then
    return NS.ImportError("Deserialize")
  end
  return deserialized
end

NS.ExportProfile = function()
  local LibDeflate = LibStub:GetLibrary("LibDeflate")
  local data = {
    key = NS.activeProfile,
    profile = NameplateIconsDB.profiles[NS.activeProfile],
  }
  local serialized = AceSerializer:Serialize(data)
  if not serialized then
    return
  end
  local compressed = LibDeflate:CompressZlib(serialized)
  if not compressed then
    return
  end
  return LibDeflate:EncodeForPrint(compressed)
end

NS.ImportProfile = function(data)
  local profile = ("Imported (%s)"):format(data.key)

  NameplateIconsDB.profiles[profile] = data.profile
  DBObjectLib:SetProfile(profile)

  NS.OnDbChanged()
  AceConfigRegistry:NotifyChange(AddonName)

  return true
end

NS.ShowExport = function()
  NS.export.editBox:SetText(NS.ExportProfile())
  NS.export:Show()
  NS.export.editBox:SetFocus()
  NS.export.editBox:HighlightText()
  -- NS.export.editBox:HighlightText(0, NS.export.editBox.editBox:GetNumLetters())
end

NS.ShowImport = function()
  NS.import.editBox:SetText("")
  NS.ImportError()
  NS.import:Show()
  NS.import.button:SetDisabled(true)
  NS.import.editBox:SetFocus()
end
