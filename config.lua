local AddonName, NS = ...

local CreateFrame = CreateFrame
local pairs = pairs
local next = next

local tsort = table.sort
local tinsert = table.insert

local NameplateIcons = {}
NS.NameplateIcons = NameplateIcons

local NameplateIconsFrame = CreateFrame("Frame", AddonName .. "Frame")
NameplateIconsFrame:SetScript("OnEvent", function(_, event, ...)
  if NameplateIcons[event] then
    NameplateIcons[event](NameplateIcons, ...)
  end
end)
NameplateIconsFrame.wasOnLoadingScreen = true
NameplateIconsFrame.inArena = false
NS.NameplateIcons.frame = NameplateIconsFrame

---@class GlowTable : table<1|2|3|4, number>

---@class NpcInfo : table
---@field name string
---@field icon number
---@field glow GlowTable
---@field spell boolean
---@field duration number

---@class MyNPCInfo : table
---@field name string
---@field enabled boolean
---@field icon number
---@field enableGlow boolean
---@field glow GlowTable
---@field spell number
---@field duration number
---@field healthColor boolean
---@field nameColor boolean

---@class VisibilityConfig : table
---@field hideFriendly boolean
---@field hideEnemy boolean
---@field hideNPC boolean

---@class GeneralConfig : table
---@field hideServerName boolean
---@field showRealmIndicator boolean
---@field ignoreNameplateAlpha boolean
---@field ignoreNameplateScale boolean
---@field selfClickThrough boolean
---@field friendlyClickThrough boolean
---@field enemyClickThrough boolean

---@class NameplateConfig : table
---@field showArena boolean
---@field showBattleground boolean
---@field showOutdoors boolean
---@field healthBars VisibilityConfig
---@field names VisibilityConfig
---@field castBars VisibilityConfig
---@field buffFrames VisibilityConfig

---@class ArrowConfig : table
---@field test boolean
---@field enabled boolean
---@field showFriendly boolean
---@field showEnemy boolean
---@field showArena boolean
---@field showBattleground boolean
---@field showOutdoors boolean
---@field scale number
---@field position "LEFT"|"TOP"|"RIGHT"
---@field attachToHealthBar boolean
---@field offsetX number
---@field offsetY number

---@class ClassConfig : table
---@field test boolean
---@field enabled boolean
---@field showFriendly boolean
---@field showEnemy boolean
---@field showArena boolean
---@field showBattleground boolean
---@field showOutdoors boolean
---@field scale number
---@field position "LEFT"|"TOP"|"RIGHT"
---@field attachToHealthBar boolean
---@field offsetX number
---@field offsetY number

---@class HealerConfig : table
---@field test boolean
---@field enabled boolean
---@field showFriendly boolean
---@field showEnemy boolean
---@field showArena boolean
---@field showBattleground boolean
---@field showOutdoors boolean
---@field scale number
---@field position "LEFT"|"RIGHT"
---@field attachToHealthBar boolean
---@field offsetX number
---@field offsetY number

---@class NPCConfig : table
---@field test boolean
---@field enabled boolean
---@field showFriendly boolean
---@field showEnemy boolean
---@field showArena boolean
---@field showBattleground boolean
---@field showOutdoors boolean
---@field scale number
---@field position "LEFT"|"TOP"|"RIGHT"
---@field attachToHealthBar boolean
---@field offsetX number
---@field offsetY number
---@field showCountdown boolean

---@class QuestConfig : table
---@field test boolean
---@field enabled boolean
---@field scale number
---@field position "LEFT"|"RIGHT"
---@field attachToHealthBar boolean
---@field offsetX number
---@field offsetY number

---@class Database : table
---@field general GeneralConfig
---@field nameplate NameplateConfig
---@field arrow ArrowConfig
---@field class ClassConfig
---@field healer HealerConfig
---@field npc NPCConfig
---@field quest QuestConfig
---@field npcs table<string, MyNPCInfo>

---@class NPC_DATA : table<string, NpcInfo>
NS.NPC_DATA = {
  ["101398"] = { -- PRIEST
    name = "Psyfiend",
    icon = 537021,
    glow = { 0.5843137502670288, 0.572549045085907, 1, 1 },
    spell = 211522,
    duration = 12,
  },
  ["119052"] = { -- WARRIOR
    name = "War Banner",
    icon = 603532,
    glow = { 1, 0.07450980693101883, 0.1372549086809158, 1 },
    spell = 236320,
    duration = 15,
  },
  ["27829"] = { -- DEATH KNIGHT
    name = "Gargoyle",
    icon = 458967,
    glow = { 0.4980392456054688, 0.4627451300621033, 0.6000000238418579, 1 },
    spell = 49206,
    duration = 25,
  },
  ["107100"] = { -- WARLOCK
    name = "Observer",
    icon = 538445,
    glow = { 0.294117659330368, 0.529411792755127, 0.6705882549285889, 1 },
    spell = 201996,
    duration = 20,
  },
  ["135002"] = { -- WARLOCK
    name = "Demonic Tyrant",
    icon = 2065628,
    glow = { 1, 0, 0.7764706611633301, 1 },
    spell = 265187,
    duration = 15,
  },
  ["225493"] = { -- WARLOCK
    name = "Doomguard",
    icon = 615103,
    glow = { 1, 0.4784314036369324, 0.2196078598499298, 1 },
    spell = 453590,
    duration = 10,
  },
  ["103673"] = { -- WARLOCK
    name = "Darkglare",
    icon = 1416161,
    glow = { 0.6705882549285889, 0.2470588386058807, 1, 1 },
    spell = 105180,
    duration = 20,
  },
  ["105451"] = { -- SHAMAN
    name = "Counterstrike Totem",
    icon = 511726,
    glow = { 0.1058823615312576, 0.3411764800548554, 1, 1 },
    spell = 204331,
    duration = 15,
  },
  ["5925"] = { -- SHAMAN
    name = "Grounding Totem",
    icon = 136039,
    glow = { 0.5882353186607361, 0.2039215862751007, 1, 1 },
    spell = 204336,
    duration = 3,
  },
  ["97369"] = { -- SHAMAN
    name = "Liquid Magma Totem",
    icon = 971079,
    glow = { 1, 0.2784313857555389, 0.1450980454683304, 1 },
    spell = 192222,
    duration = 6,
  },
  ["53006"] = { -- SHAMAN
    name = "Spirit Link Totem",
    icon = 237586,
    glow = { 0.2352941334247589, 0.9843137860298157, 1, 1 },
    spell = 98008,
    duration = 6,
  },
  ["5913"] = { -- SHAMAN
    name = "Tremor Totem",
    icon = 136108,
    glow = { 0.9019608497619629, 0.8588235974311829, 0.1607843190431595, 1 },
    spell = 8143,
    duration = 13,
  },
  ["179867"] = { -- SHAMAN
    name = "Static Field Totem",
    icon = 1020304,
    glow = { 0.2588235437870026, 0.658823549747467, 1, 1 },
    spell = 355580,
    duration = 6,
  },
  ["61245"] = { -- SHAMAN
    name = "Capacitor Totem",
    icon = 136013,
    glow = { 0.2901960909366608, 0.2235294282436371, 1, 1 },
    spell = 192058,
    duration = 3,
  },
  ["105427"] = { -- SHAMAN
    name = "Totem of Wrath",
    icon = 135829,
    glow = { 0.7803922295570374, 0.1450980454683304, 0.1215686351060867, 1 },
    spell = 460697,
    duration = 15,
  },
  ["104818"] = { -- SHAMAN
    name = "Ancestral Protection Totem",
    icon = 136080,
    glow = { 1, 0, 0.1607843190431595, 1 },
    spell = 207399,
    duration = 33,
  },
  ["59764"] = { -- SHAMAN
    name = "Healing Tide Totem",
    icon = 538569,
    glow = { 0.0784313753247261, 1, 0.9686275124549866, 1 },
    spell = 108280,
    duration = 10,
  },
  ["59712"] = { -- SHAMAN
    name = "Stone Bulwark Totem",
    icon = 538572,
    glow = { 0.7450980544090271, 0.9803922176361084, 0.3960784673690796, 1 },
    spell = 108270,
    duration = 30,
  },
  ["100943"] = { -- SHAMAN
    name = "Earthen Wall Totem",
    icon = 136098,
    glow = { 1, 0.2196078598499298, 0.9098039865493774, 1 },
    spell = 198838,
    duration = 18,
  },
  ["3527"] = { -- SHAMAN
    name = "Healing Stream Totem",
    icon = 135127,
    glow = { 0.9647059440612793, 1, 0.9843137860298157, 1 },
    spell = 5394,
    duration = 18,
  },
  ["78001"] = { -- SHAMAN
    name = "Cloudburst Totem",
    icon = 971076,
    glow = { 0.615686297416687, 0.9254902601242065, 1, 1 },
    spell = 157153,
    duration = 18,
  },
  ["2630"] = { -- SHAMAN
    name = "Earthbind Totem",
    icon = 136102,
    glow = { 0.4823529720306397, 0.6196078658103943, 1, 1 },
    spell = 2484,
    duration = 30,
  },
  ["60561"] = { -- SHAMAN
    name = "Earthgrab Totem",
    icon = 136100,
    glow = { 0.2000000178813934, 0.3607843220233917, 0.2470588386058807, 1 },
    spell = 51485,
    duration = 30,
  },
  ["5923"] = { -- SHAMAN
    name = "Poison Cleansing Totem",
    icon = 136070,
    glow = { 0.8549020290374756, 1, 0.4352941513061523, 1 },
    spell = 383013,
    duration = 9,
  },
  ["10467"] = { -- SHAMAN
    name = "Mana Tide Totem",
    icon = 4667424,
    glow = { 0.2588235437870026, 0.7725490927696228, 1, 1 },
    spell = 16191,
    duration = 8,
  },
  ["97285"] = { -- SHAMAN
    name = "Wind Rush Totem",
    icon = 538576,
    glow = { 0.5058823823928833, 1, 0.3098039329051971, 1 },
    spell = 192077,
    duration = 18,
  },
  ["225409"] = { -- SHAMAN
    name = "Surging Totem",
    icon = 5927655,
    glow = { 0.5490196347236633, 0.847058892250061, 1, 1 },
    spell = 444995,
    duration = 24,
  },
  ["166523"] = { -- SHAMAN
    name = "Vesper Totem",
    icon = 3565451,
    glow = { 0.4039216041564941, 1, 0.9686275124549866, 1 },
    spell = 324286,
    duration = 30,
  },
}

---@class NPC_SHOW_LIST : string[]
NS.NPC_SHOW_LIST = {}

---@param npcId string
---@param _ NpcInfo
for npcId, _ in pairs(NS.NPC_DATA) do
  tinsert(NS.NPC_SHOW_LIST, npcId)
end

---@class NPC_HIDE_LIST : string[]
NS.NPC_HIDE_LIST = {
  "89",
  "416",
  "417",
  "1860",
  "1863",
  "229798",
  "63508",
  "143622",
  "98035",
  "135816",
  "136402",
  "136399",
  "31216",
  "95072",
  "29264",
  "27829",
  "24207",
  "69791",
  "69792",
  "26125",
  "62821",
  "62822",
  "142666",
  "142668",
  "32641",
  "32642",
  "189988",
  "103822",
  "198489",
  "26125",
  "55659",
  "62982",
  "105419",
  "198757",
  "192337",
  "89715",
  "165189",
  "103268",
  "65282",
  "99541",
  "163366",
  "103320",
  "17252",
  "110063",
  "197280",
  "19668",
  "166949",
  "107024",
  "100820",
  "95061",
  "77942",
  "77936",
  "61056",
  "61029",
  "106988",
  "54983",
  "62005",
  "32638",
  "32639",
  "208441",
  "224466",
  "97022",
  "217429",
  "231086",
  "231085",
  "158259",
}

--- @type fun(a: { [string]: MyNPCInfo }?, b: { [string]: MyNPCInfo }?): boolean
NS.SortListByName = function(a, b)
  if a and b then
    local _, aNPCInfo = next(a)
    local _, bNPCInfo = next(b)
    local aName = aNPCInfo.name
    local bName = bNPCInfo.name
    if aName and bName then
      if aName ~= bName then
        return aName < bName
      end
    end
  end
  return false
end

--- @type Database
DefaultDatabase = {
  general = {
    hideServerName = false,
    showRealmIndicator = false,
    ignoreNameplateAlpha = false,
    ignoreNameplateScale = false,
    selfClickThrough = false,
    friendlyClickThrough = false,
    enemyClickThrough = false,
  },
  nameplate = {
    showArena = false,
    showBattleground = false,
    showOutdoors = false,
    healthBars = {
      hideFriendly = false,
      hideEnemy = false,
      hideNPC = false,
    },
    names = {
      hideFriendly = false,
      hideEnemy = false,
      hideNPC = false,
    },
    castBars = {
      hideFriendly = false,
      hideEnemy = false,
      hideNPC = false,
    },
    buffFrames = {
      hideFriendly = false,
      hideEnemy = false,
      hideNPC = false,
    },
  },
  arrow = {
    test = false,
    enabled = false,
    showFriendly = true,
    showEnemy = false,
    showArena = true,
    showBattleground = false,
    showOutdoors = false,
    scale = 1.0,
    position = "TOP", -- left/top/right
    attachToHealthBar = true,
    offsetX = 0,
    offsetY = 0,
  },
  class = {
    test = false,
    enabled = false,
    showFriendly = false,
    showEnemy = true,
    showArena = false,
    showBattleground = false,
    showOutdoors = true,
    scale = 2.0,
    position = "TOP", -- left/top/right
    attachToHealthBar = false,
    offsetX = 0,
    offsetY = 0,
  },
  healer = {
    test = false,
    enabled = true,
    showFriendly = true,
    showEnemy = true,
    showArena = true,
    showBattleground = true,
    showOutdoors = true,
    scale = 1.25,
    position = "LEFT", -- left/right
    attachToHealthBar = false,
    offsetX = 0,
    offsetY = 0,
  },
  npc = {
    test = false,
    enabled = true,
    showFriendly = true,
    showEnemy = true,
    showArena = true,
    showBattleground = true,
    showOutdoors = true,
    scale = 2.0,
    position = "TOP", -- left/top/right
    attachToHealthBar = false,
    offsetX = 0,
    offsetY = 0,
    showCountdown = true,
  },
  quest = {
    test = false,
    enabled = true,
    scale = 1.0,
    position = "RIGHT", -- left/right
    attachToHealthBar = true,
    offsetX = 0,
    offsetY = 0,
  },
  npcs = {},
}

--- @type { [string]: MyNPCInfo }[]
local npcList = {}

---@param npcId string
---@param npcData NpcInfo
for npcId, npcData in pairs(NS.NPC_DATA) do
  --- @type { [string]: NpcInfo }
  local npc = {
    [npcId] = {
      name = npcData.name,
      enabled = true,
      icon = npcData.icon,
      enableGlow = true,
      glow = npcData.glow,
      spell = npcData.spell,
      duration = npcData.duration,
      healthColor = true,
      nameColor = true,
    },
  }
  tinsert(npcList, npc)
end
tsort(npcList, NS.SortListByName)

for i = 1, #npcList do
  --- @type { [string]: NpcInfo }
  local npc = npcList[i]
  if npc then
    --- @type string, MyNPCInfo
    local npcId, npcInfo = next(npc)
    DefaultDatabase.npcs[npcId] = {
      name = npcInfo.name,
      enabled = npcInfo.enabled,
      icon = npcInfo.icon,
      enableGlow = npcInfo.enableGlow,
      glow = npcInfo.glow,
      spell = npcInfo.spell,
      duration = npcInfo.duration,
      healthColor = npcInfo.healthColor,
      nameColor = npcInfo.nameColor,
    }
  end
end
NS.DefaultDatabase = DefaultDatabase
