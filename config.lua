local AddonName, NS = ...

local CreateFrame = CreateFrame
local pairs = pairs
local next = next
local tostring = tostring

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

NS.NPC_DATA = {
  ["101398"] = { -- PRIEST -- valid
    name = "Psyfiend",
    icon = 537021,
    glow = { 0.5843137502670288, 0.572549045085907, 1, 1 },
    spell = 211522,
    duration = 12,
  },
  ["119052"] = { -- WARRIOR -- valid
    name = "War Banner",
    icon = 603532,
    glow = { 1, 0.07450980693101883, 0.1372549086809158, 1 },
    spell = 236320,
    duration = 15,
  },
  ["27829"] = { -- DEATH KNIGHT -- valid
    name = "Gargoyle",
    icon = 458967,
    glow = { 0.4980392456054688, 0.4627451300621033, 0.6000000238418579, 1 },
    spell = 49206,
    duration = 25,
  },
  ["107100"] = { -- WARLOCK -- valid
    name = "Observer",
    icon = 538445,
    glow = { 0.294117659330368, 0.529411792755127, 0.6705882549285889, 1 },
    spell = 201996,
    duration = 20,
  },
  ["135002"] = { -- WARLOCK -- valid
    name = "Demonic Tyrant",
    icon = 2065628,
    glow = { 1, 0, 0.7764706611633301, 1 },
    spell = 265187,
    duration = 15,
  },
  ["225493"] = { -- WARLOCK -- valid
    name = "Doomguard",
    icon = 615103,
    glow = { 1, 0.4784314036369324, 0.2196078598499298, 1 },
    spell = 453590,
    duration = 20,
  },
  ["103673"] = { -- WARLOCK -- valid
    name = "Darkglare",
    icon = 1416161,
    glow = { 0.6705882549285889, 0.2470588386058807, 1, 1 },
    spell = 105180,
    duration = 20,
  },
  ["105451"] = { -- SHAMAN -- valid
    name = "Counterstrike Totem",
    icon = 511726,
    glow = { 0.1058823615312576, 0.3411764800548554, 1, 1 },
    spell = 204331,
    duration = 15,
  },
  ["5925"] = { -- SHAMAN -- valid
    name = "Grounding Totem",
    icon = 136039,
    glow = { 0.5882353186607361, 0.2039215862751007, 1, 1 },
    spell = 204336,
    duration = 3,
  },
  ["97369"] = { -- SHAMAN -- valid
    name = "Liquid Magma Totem",
    icon = 971079,
    glow = { 1, 0.2784313857555389, 0.1450980454683304, 1 },
    spell = 192222,
    duration = 6,
  },
  ["53006"] = { -- SHAMAN -- valid
    name = "Spirit Link Totem",
    icon = 237586,
    glow = { 0.2352941334247589, 0.9843137860298157, 1, 1 },
    spell = 98008,
    duration = 6,
  },
  ["5913"] = { -- SHAMAN -- valid
    name = "Tremor Totem",
    icon = 136108,
    glow = { 0.9019608497619629, 0.8588235974311829, 0.1607843190431595, 1 },
    spell = 8143,
    duration = 13,
  },
  ["179867"] = { -- SHAMAN -- valid
    name = "Static Field Totem",
    icon = 1020304,
    glow = { 0.2588235437870026, 0.658823549747467, 1, 1 },
    spell = 355580,
    duration = 6,
  },
  ["61245"] = { -- SHAMAN -- valid
    name = "Capacitor Totem",
    icon = 136013,
    glow = { 0.2901960909366608, 0.2235294282436371, 1, 1 },
    spell = 192058,
    duration = 3,
  },
  ["105427"] = { -- SHAMAN -- valid
    name = "Totem of Wrath",
    icon = 135829,
    glow = { 0.7803922295570374, 0.1450980454683304, 0.1215686351060867, 1 },
    spell = 460697,
    duration = 15,
  },
  ["104818"] = { -- SHAMAN -- valid
    name = "Ancestral Protection Totem",
    icon = 136080,
    glow = { 1, 0, 0.1607843190431595, 1 },
    spell = 207399,
    duration = 33,
  },
  ["59764"] = { -- SHAMAN -- valid
    name = "Healing Tide Totem",
    icon = 538569,
    glow = { 0.0784313753247261, 1, 0.9686275124549866, 1 },
    spell = 108280,
    duration = 10,
  },
  ["59712"] = { -- SHAMAN -- valid
    name = "Stone Bulwark Totem",
    icon = 538572,
    glow = { 0.7450980544090271, 0.9803922176361084, 0.3960784673690796, 1 },
    spell = 108270,
    duration = 30,
  },
  ["100943"] = { -- SHAMAN -- valid
    name = "Earthen Wall Totem",
    icon = 136098,
    glow = { 1, 0.2196078598499298, 0.9098039865493774, 1 },
    spell = 198838,
    duration = 18,
  },
  ["3527"] = { -- SHAMAN -- valid
    name = "Healing Stream Totem",
    icon = 135127,
    glow = { 0.9647059440612793, 1, 0.9843137860298157, 1 },
    spell = 5394,
    duration = 18,
  },
  ["78001"] = { -- SHAMAN -- valid
    name = "Cloudburst Totem",
    icon = 971076,
    glow = { 0.615686297416687, 0.9254902601242065, 1, 1 },
    spell = 157153,
    duration = 18,
  },
  ["2630"] = { -- SHAMAN -- valid
    name = "Earthbind Totem",
    icon = 136102,
    glow = { 0.4823529720306397, 0.6196078658103943, 1, 1 },
    spell = 2484,
    duration = 30,
  },
  ["60561"] = { -- SHAMAN -- valid
    name = "Earthgrab Totem",
    icon = 136100,
    glow = { 0.2000000178813934, 0.3607843220233917, 0.2470588386058807, 1 },
    spell = 51485,
    duration = 30,
  },
  ["5923"] = { -- SHAMAN -- valid
    name = "Poison Cleansing Totem",
    icon = 136070,
    glow = { 0.8549020290374756, 1, 0.4352941513061523, 1 },
    spell = 383013,
    duration = 9,
  },
  ["10467"] = { -- SHAMAN -- valid
    name = "Mana Tide Totem",
    icon = 4667424,
    glow = { 0.2588235437870026, 0.7725490927696228, 1, 1 },
    spell = 16191,
    duration = 8,
  },
  ["97285"] = { -- SHAMAN -- valid
    name = "Wind Rush Totem",
    icon = 538576,
    glow = { 0.5058823823928833, 1, 0.3098039329051971, 1 },
    spell = 192077,
    duration = 18,
  },
  ["225409"] = { -- SHAMAN -- valid
    name = "Surging Totem",
    icon = 5927655,
    glow = { 0.5490196347236633, 0.847058892250061, 1, 1 },
    spell = 444995,
    duration = 24,
  },
  ["166523"] = { -- SHAMAN -- valid
    name = "Vesper Totem",
    icon = 3565451,
    glow = { 0.4039216041564941, 1, 0.9686275124549866, 1 },
    spell = 324286,
    duration = 30,
  },
}

NS.NPC_SHOW_LIST = {}

for npcId, _ in pairs(NS.NPC_DATA) do
  tinsert(NS.NPC_SHOW_LIST, npcId)
end

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
end

DefaultDatabase = {
  general = {
    ignoreNameplateAlpha = false,
    ignoreNameplateScale = false,
    selfClickThrough = true,
    friendlyClickThrough = false,
    enemyClickThrough = false,
  },
  arena = {
    test = false,
    enabled = false,
    showFriendly = true,
    showEnemy = false,
    scale = 1.0,
    position = "TOP", -- left/top/right
    attachToHealthBar = true,
    offsetX = 0,
    offsetY = 0,
    showOutside = false,
    replaceHealerIcon = true,
    icon = "arrow",
    healthBars = {
      hideFriendly = true,
      hideEnemy = false,
      hideNPC = false,
    },
    names = {
      hideFriendly = true,
      hideEnemy = false,
      hideNPC = false,
    },
    castBars = {
      hideFriendly = true,
      hideEnemy = false,
      hideNPC = false,
    },
    buffFrames = {
      hideFriendly = true,
      hideEnemy = false,
      hideNPC = false,
    },
  },
  healer = {
    test = false,
    enabled = false,
    showFriendly = true,
    showEnemy = true,
    groupOnly = false,
    instanceOnly = false,
    scale = 1.25,
    position = "LEFT", -- left/right
    attachToHealthBar = false,
  },
  npc = {
    test = false,
    enabled = false,
    showFriendly = true,
    showEnemy = true,
    groupOnly = false,
    instanceOnly = false,
    scale = 2.0,
    position = "TOP", -- left/top/right
    attachToHealthBar = false,
    offsetX = 0,
    offsetY = 0,
    showCountdown = true,
  },
  quest = {
    test = false,
    enabled = false,
    scale = 1.0,
    position = "RIGHT", -- left/top/right
    attachToHealthBar = true,
    offsetX = 0,
    offsetY = 0,
  },
  npcs = {},
}
local npcList = {}
for npcId, npcData in pairs(NS.NPC_DATA) do
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
  local npc = npcList[i]
  if npc then
    local npcId, npcInfo = next(npc)
    local NPC_ID = tostring(npcId)
    DefaultDatabase.npcs[NPC_ID] = {
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
