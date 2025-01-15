local _, NS = ...

local IsInRaid = IsInRaid
local IsInGroup = IsInGroup
local GetNumGroupMembers = GetNumGroupMembers
local GetNumSubgroupMembers = GetNumSubgroupMembers
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local type = type
local next = next
local pairs = pairs
local ipairs = ipairs

---@type fun(): boolean
NS.isInGroup = function()
  return IsInRaid() or IsInGroup()
end

---@type fun(unit: string): boolean
NS.isHealer = function(unit)
  return UnitGroupRolesAssigned(unit) == "HEALER"
end

-- Function to assist iterating group members whether in a party or raid.
--- @type fun(reversed: boolean?, forceParty: boolean?): function
NS.IterateGroupMembers = function(reversed, forceParty)
  local unit = (not forceParty and IsInRaid()) and "raid" or "party"
  local numGroupMembers = unit == "party" and GetNumSubgroupMembers() or GetNumGroupMembers()
  local i = reversed and numGroupMembers or (unit == "party" and 0 or 1)
  --- @type fun(): string
  return function()
    local ret
    if i == 0 and unit == "party" then
      ret = "player"
    elseif i <= numGroupMembers and i > 0 then
      ret = unit .. i
    end
    i = i + (reversed and -1 or 1)
    return ret
  end
end

--- @type fun(list: string[], npcID: string): boolean
NS.isNPCInList = function(list, npcID)
  for _, id in ipairs(list) do
    if id == npcID then
      return true
    end
  end
  return false
end

NS.CopyTable = function(src, dest)
  if type(dest) ~= "table" then
    dest = {}
  end
  if type(src) == "table" then
    for k, v in pairs(src) do
      if type(v) == "table" then
        v = NS.CopyTable(v, dest[k])
      end
      dest[k] = v
    end
  end
  return dest
end

-- Copies table values from src to dst if they don't exist in dst
NS.CopyDefaults = function(src, dst)
  if type(src) ~= "table" then
    return {}
  end

  if type(dst) ~= "table" then
    dst = {}
  end

  for k, v in pairs(src) do
    if type(v) == "table" then
      if k == "npcs" then
        if not dst[k] or next(dst[k]) == nil then
          dst[k] = NS.CopyDefaults(v, dst[k])
        end
      else
        dst[k] = NS.CopyDefaults(v, dst[k])
      end
    elseif type(v) ~= type(dst[k]) then
      dst[k] = v
    end
  end

  return dst
end

-- Cleanup savedvariables by removing table values in src that no longer
-- exists in table dst (default settings)
NS.CleanupDB = function(src, dst)
  for key, value in pairs(src) do
    if dst[key] == nil then
      -- HACK: offsetsXY are not set in DEFAULT_SETTINGS but sat on demand instead to save memory,
      -- which causes nil comparison to always be true here, so always ignore these for now
      if key ~= "version" then
        src[key] = nil
      end
    elseif type(value) == "table" then
      if key ~= "npcs" then -- also set on demand
        dst[key] = NS.CleanupDB(value, dst[key])
      end
    end
  end
  return dst
end
