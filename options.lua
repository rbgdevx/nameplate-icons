local AddonName, NS = ...

local pairs = pairs
local next = next
local tostring = tostring
local UnitFactionGroup = UnitFactionGroup

local tinsert = table.insert
local tsort = table.sort
local tconcat = table.concat

--- @type fun(info: table<1|2|3, string>, npcIcon: number, npcGlow: GlowTable): string
local function GenerateIconString(info, npcIcon, npcGlow)
  local NPC = NS.db[info[1]][info[2]]
  -- Check if the icon and glow data exist, and set defaults if not
  local icon = NPC and NPC.icon or npcIcon
  local glow = NPC and NPC.glow or npcGlow
  local glowEnabled = NPC and NPC.enableGlow or false
  -- Concatenate the icon and glow values into the desired string format
  return tostring(icon) .. "x" .. tconcat({ glow[1], glow[2], glow[3], glow[4] }, ",") .. "x" .. tostring(glowEnabled)
end

local AceConfig = {
  name = AddonName,
  type = "group",
  childGroups = "tab",
  args = {
    icons = {
      name = "Icons",
      type = "group",
      childGroups = "tab",
      order = 1,
      args = {
        arrow = {
          name = "Arrow",
          type = "group",
          order = 1,
          args = {
            enable = {
              name = "Enable",
              type = "toggle",
              order = 1,
              width = 0.4,
              get = function(_)
                return NS.db.arrow.enabled
              end,
              set = function(_, val)
                NS.db.arrow.enabled = val
                NS.OnDbChanged()
              end,
            },
            spacer1 = {
              name = "",
              type = "description",
              order = 2,
              width = 0.1,
            },
            test = {
              name = "Test Mode",
              desc = "Turn on to test settings immediately",
              type = "toggle",
              order = 3,
              width = 1.0,
              disabled = function(_)
                return not NS.db.arrow.enabled
              end,
              get = function(_)
                return NS.db.arrow.test
              end,
              set = function(_, val)
                NS.db.arrow.test = val
                NS.OnDbChanged()
              end,
            },
            spacer2 = {
              name = "",
              type = "description",
              order = 4,
              width = "full",
            },
            desc1 = {
              name = "Show for:",
              fontSize = "medium",
              type = "description",
              order = 5,
              width = 0.4,
            },
            showFriendly = {
              name = "Friendly",
              type = "toggle",
              order = 6,
              width = 0.5,
              disabled = function(_)
                return not NS.db.arrow.enabled
              end,
              get = function(_)
                return NS.db.arrow.showFriendly
              end,
              set = function(_, val)
                NS.db.arrow.showFriendly = val
                NS.OnDbChanged()
              end,
            },
            showEnemy = {
              name = "Enemy",
              type = "toggle",
              order = 7,
              width = 0.4,
              disabled = function(_)
                return not NS.db.arrow.enabled
              end,
              get = function(_)
                return NS.db.arrow.showEnemy
              end,
              set = function(_, val)
                NS.db.arrow.showEnemy = val
                NS.OnDbChanged()
              end,
            },
            spacer3 = {
              name = "",
              type = "description",
              order = 8,
              width = "full",
            },
            desc2 = {
              name = "Show in:",
              fontSize = "medium",
              type = "description",
              order = 9,
              width = 0.4,
            },
            showArena = {
              name = "Arena",
              type = "toggle",
              order = 10,
              width = 0.4,
              disabled = function(_)
                return not NS.db.arrow.enabled
              end,
              get = function(_)
                return NS.db.arrow.showArena
              end,
              set = function(_, val)
                NS.db.arrow.showArena = val
                NS.OnDbChanged()
              end,
            },
            showBattleground = {
              name = "Battleground",
              type = "toggle",
              order = 11,
              width = 0.7,
              disabled = function(_)
                return not NS.db.arrow.enabled
              end,
              get = function(_)
                return NS.db.arrow.showBattleground
              end,
              set = function(_, val)
                NS.db.arrow.showBattleground = val
                NS.OnDbChanged()
              end,
            },
            showOutdoors = {
              name = "Outdoors",
              type = "toggle",
              order = 12,
              width = 0.5,
              disabled = function(_)
                return not NS.db.arrow.enabled
              end,
              get = function(_)
                return NS.db.arrow.showOutdoors
              end,
              set = function(_, val)
                NS.db.arrow.showOutdoors = val
                NS.OnDbChanged()
              end,
            },
            spacer4 = {
              name = "",
              type = "description",
              order = 13,
              width = "full",
            },
            position = {
              name = "Position",
              type = "select",
              order = 14,
              width = 1.0,
              values = {
                ["LEFT"] = "Left",
                ["TOP"] = "Top",
                ["RIGHT"] = "Right",
              },
              sorting = {
                "LEFT",
                "TOP",
                "RIGHT",
              },
              disabled = function(_)
                return not NS.db.arrow.enabled
              end,
              get = function(_)
                return NS.db.arrow.position
              end,
              set = function(_, val)
                NS.db.arrow.position = val
                NS.OnDbChanged()
              end,
            },
            spacer5 = {
              name = "",
              type = "description",
              order = 15,
              width = 0.1,
            },
            attachToHealthBar = {
              name = "Attach directly to the healthbar",
              type = "toggle",
              order = 16,
              width = 1.5,
              disabled = function(_)
                return not NS.db.arrow.enabled
              end,
              get = function(_)
                return NS.db.arrow.attachToHealthBar
              end,
              set = function(_, val)
                NS.db.arrow.attachToHealthBar = val
                NS.OnDbChanged()
              end,
            },
            spacer6 = {
              name = "",
              type = "description",
              order = 17,
              width = "full",
            },
            offsetX = {
              name = "Offset X",
              type = "range",
              order = 18,
              width = 1.2,
              isPercent = false,
              min = -100,
              max = 100,
              step = 1,
              disabled = function(_)
                return not NS.db.arrow.enabled
              end,
              get = function(_)
                return NS.db.arrow.offsetX
              end,
              set = function(_, val)
                NS.db.arrow.offsetX = val
                NS.OnDbChanged()
              end,
            },
            offsetY = {
              name = "Offset Y",
              type = "range",
              order = 19,
              width = 1.2,
              isPercent = false,
              min = -100,
              max = 100,
              step = 1,
              disabled = function(_)
                return not NS.db.arrow.enabled
              end,
              get = function(_)
                return NS.db.arrow.offsetY
              end,
              set = function(_, val)
                NS.db.arrow.offsetY = val
                NS.OnDbChanged()
              end,
            },
            spacer7 = {
              name = "",
              type = "description",
              order = 20,
              width = "full",
            },
            scale = {
              name = "Scale",
              type = "range",
              order = 21,
              width = 1.75,
              isPercent = false,
              min = 0.5,
              max = 2,
              step = 0.01,
              disabled = function(_)
                return not NS.db.arrow.enabled
              end,
              get = function(_)
                return NS.db.arrow.scale
              end,
              set = function(_, val)
                NS.db.arrow.scale = val
                NS.OnDbChanged()
              end,
            },
            spacer8 = {
              name = " ",
              type = "description",
              order = 22,
              width = "full",
            },
            iconDesc = {
              name = "Icon:",
              type = "description",
              order = 23,
              width = "full",
            },
            iconImage = {
              name = " ",
              type = "description",
              order = 24,
              image = function(info)
                return "covenantsanctum-renown-doublearrow-depressedxatlas"
              end,
              imageHeight = 70,
              imageWidth = 55,
            },
          },
        },
        class = {
          name = "Class",
          type = "group",
          order = 2,
          args = {
            enable = {
              name = "Enable",
              type = "toggle",
              order = 1,
              width = 0.4,
              get = function(_)
                return NS.db.class.enabled
              end,
              set = function(_, val)
                NS.db.class.enabled = val
                NS.OnDbChanged()
              end,
            },
            spacer1 = {
              name = "",
              type = "description",
              order = 2,
              width = 0.1,
            },
            test = {
              name = "Test Mode",
              desc = "Turn on to test settings immediately",
              type = "toggle",
              order = 3,
              width = 1.0,
              disabled = function(_)
                return not NS.db.class.enabled
              end,
              get = function(_)
                return NS.db.class.test
              end,
              set = function(_, val)
                NS.db.class.test = val
                NS.OnDbChanged()
              end,
            },
            spacer2 = {
              name = "",
              type = "description",
              order = 4,
              width = "full",
            },
            desc1 = {
              name = "Show for:",
              fontSize = "medium",
              type = "description",
              order = 5,
              width = 0.4,
            },
            showFriendly = {
              name = "Friendly",
              type = "toggle",
              order = 6,
              width = 0.5,
              disabled = function(_)
                return not NS.db.class.enabled
              end,
              get = function(_)
                return NS.db.class.showFriendly
              end,
              set = function(_, val)
                NS.db.class.showFriendly = val
                NS.OnDbChanged()
              end,
            },
            showEnemy = {
              name = "Enemy",
              type = "toggle",
              order = 7,
              width = 0.4,
              disabled = function(_)
                return not NS.db.class.enabled
              end,
              get = function(_)
                return NS.db.class.showEnemy
              end,
              set = function(_, val)
                NS.db.class.showEnemy = val
                NS.OnDbChanged()
              end,
            },
            spacer3 = {
              name = "",
              type = "description",
              order = 8,
              width = "full",
            },
            desc2 = {
              name = "Show in:",
              fontSize = "medium",
              type = "description",
              order = 9,
              width = 0.4,
            },
            showArena = {
              name = "Arena",
              type = "toggle",
              order = 10,
              width = 0.4,
              disabled = function(_)
                return not NS.db.class.enabled
              end,
              get = function(_)
                return NS.db.class.showArena
              end,
              set = function(_, val)
                NS.db.class.showArena = val
                NS.OnDbChanged()
              end,
            },
            showBattleground = {
              name = "Battleground",
              type = "toggle",
              order = 11,
              width = 0.7,
              disabled = function(_)
                return not NS.db.class.enabled
              end,
              get = function(_)
                return NS.db.class.showBattleground
              end,
              set = function(_, val)
                NS.db.class.showBattleground = val
                NS.OnDbChanged()
              end,
            },
            showOutdoors = {
              name = "Outdoors",
              type = "toggle",
              order = 12,
              width = 0.5,
              disabled = function(_)
                return not NS.db.class.enabled
              end,
              get = function(_)
                return NS.db.class.showOutdoors
              end,
              set = function(_, val)
                NS.db.class.showOutdoors = val
                NS.OnDbChanged()
              end,
            },
            spacer4 = {
              name = "",
              type = "description",
              order = 13,
              width = "full",
            },
            position = {
              name = "Position",
              type = "select",
              order = 14,
              width = 1.0,
              values = {
                ["LEFT"] = "Left",
                ["TOP"] = "Top",
                ["RIGHT"] = "Right",
              },
              sorting = {
                "LEFT",
                "TOP",
                "RIGHT",
              },
              disabled = function(_)
                return not NS.db.class.enabled
              end,
              get = function(_)
                return NS.db.class.position
              end,
              set = function(_, val)
                NS.db.class.position = val
                NS.OnDbChanged()
              end,
            },
            spacer5 = {
              name = "",
              type = "description",
              order = 15,
              width = 0.1,
            },
            attachToHealthBar = {
              name = "Attach directly to the healthbar",
              type = "toggle",
              order = 16,
              width = 1.5,
              disabled = function(_)
                return not NS.db.class.enabled
              end,
              get = function(_)
                return NS.db.class.attachToHealthBar
              end,
              set = function(_, val)
                NS.db.class.attachToHealthBar = val
                NS.OnDbChanged()
              end,
            },
            spacer6 = {
              name = "",
              type = "description",
              order = 17,
              width = "full",
            },
            offsetX = {
              name = "Offset X",
              type = "range",
              order = 18,
              width = 1.2,
              isPercent = false,
              min = -100,
              max = 100,
              step = 1,
              disabled = function(_)
                return not NS.db.class.enabled
              end,
              get = function(_)
                return NS.db.class.offsetX
              end,
              set = function(_, val)
                NS.db.class.offsetX = val
                NS.OnDbChanged()
              end,
            },
            offsetY = {
              name = "Offset Y",
              type = "range",
              order = 19,
              width = 1.2,
              isPercent = false,
              min = -100,
              max = 100,
              step = 1,
              disabled = function(_)
                return not NS.db.class.enabled
              end,
              get = function(_)
                return NS.db.class.offsetY
              end,
              set = function(_, val)
                NS.db.class.offsetY = val
                NS.OnDbChanged()
              end,
            },
            spacer7 = {
              name = "",
              type = "description",
              order = 20,
              width = "full",
            },
            scale = {
              name = "Scale",
              type = "range",
              order = 21,
              width = 1.75,
              isPercent = false,
              min = 0.5,
              max = 2,
              step = 0.01,
              disabled = function(_)
                return not NS.db.class.enabled
              end,
              get = function(_)
                return NS.db.class.scale
              end,
              set = function(_, val)
                NS.db.class.scale = val
                NS.OnDbChanged()
              end,
            },
            spacer8 = {
              name = " ",
              type = "description",
              order = 22,
              width = "full",
            },
            iconDesc = {
              name = "Icon:",
              type = "description",
              order = 23,
              width = "full",
            },
            iconImage = {
              name = " ",
              type = "description",
              order = 24,
              image = function(info)
                return "class"
              end,
              imageHeight = 40,
              imageWidth = 40,
            },
          },
        },
        healer = {
          name = "Healer",
          type = "group",
          order = 3,
          args = {
            enable = {
              name = "Enable",
              type = "toggle",
              order = 1,
              width = 0.4,
              get = function(_)
                return NS.db.healer.enabled
              end,
              set = function(_, val)
                NS.db.healer.enabled = val
                NS.OnDbChanged()
              end,
            },
            spacer1 = {
              name = "",
              type = "description",
              order = 2,
              width = 0.1,
            },
            test = {
              name = "Test Mode",
              desc = "Turn on to test settings immediately",
              type = "toggle",
              order = 3,
              width = 1.0,
              disabled = function(_)
                return not NS.db.healer.enabled
              end,
              get = function(_)
                return NS.db.healer.test
              end,
              set = function(_, val)
                NS.db.healer.test = val
                NS.OnDbChanged()
              end,
            },
            spacer2 = {
              name = "",
              type = "description",
              order = 4,
              width = "full",
            },
            desc1 = {
              name = "Show for:",
              fontSize = "medium",
              type = "description",
              order = 5,
              width = 0.4,
            },
            showFriendly = {
              name = "Friendly",
              type = "toggle",
              order = 6,
              width = 0.5,
              disabled = function(_)
                return not NS.db.healer.enabled
              end,
              get = function(_)
                return NS.db.healer.showFriendly
              end,
              set = function(_, val)
                NS.db.healer.showFriendly = val
                NS.OnDbChanged()
              end,
            },
            showEnemy = {
              name = "Enemy",
              type = "toggle",
              order = 7,
              width = 0.4,
              disabled = function(_)
                return not NS.db.healer.enabled
              end,
              get = function(_)
                return NS.db.healer.showEnemy
              end,
              set = function(_, val)
                NS.db.healer.showEnemy = val
                NS.OnDbChanged()
              end,
            },
            spacer3 = {
              name = "",
              type = "description",
              order = 8,
              width = "full",
            },
            desc2 = {
              name = "Show in:",
              fontSize = "medium",
              type = "description",
              order = 9,
              width = 0.4,
            },
            showArena = {
              name = "Arena",
              type = "toggle",
              order = 10,
              width = 0.4,
              disabled = function(_)
                return not NS.db.healer.enabled
              end,
              get = function(_)
                return NS.db.healer.showArena
              end,
              set = function(_, val)
                NS.db.healer.showArena = val
                NS.OnDbChanged()
              end,
            },
            showBattleground = {
              name = "Battleground",
              type = "toggle",
              order = 11,
              width = 0.7,
              disabled = function(_)
                return not NS.db.healer.enabled
              end,
              get = function(_)
                return NS.db.healer.showBattleground
              end,
              set = function(_, val)
                NS.db.healer.showBattleground = val
                NS.OnDbChanged()
              end,
            },
            showOutdoors = {
              name = "Outdoors",
              type = "toggle",
              order = 12,
              width = 0.5,
              disabled = function(_)
                return not NS.db.healer.enabled
              end,
              get = function(_)
                return NS.db.healer.showOutdoors
              end,
              set = function(_, val)
                NS.db.healer.showOutdoors = val
                NS.OnDbChanged()
              end,
            },
            spacer4 = {
              name = "",
              type = "description",
              order = 13,
              width = "full",
            },
            position = {
              name = "Position",
              type = "select",
              order = 14,
              width = 1.0,
              values = {
                ["LEFT"] = "Left",
                ["RIGHT"] = "Right",
              },
              sorting = {
                "LEFT",
                "RIGHT",
              },
              disabled = function(_)
                return not NS.db.healer.enabled
              end,
              get = function(_)
                return NS.db.healer.position
              end,
              set = function(_, val)
                NS.db.healer.position = val
                NS.OnDbChanged()
              end,
            },
            spacer5 = {
              name = "",
              type = "description",
              order = 15,
              width = 0.1,
            },
            attachToHealthBar = {
              name = "Attach directly to the healthbar",
              type = "toggle",
              order = 16,
              width = 1.5,
              disabled = function(_)
                return not NS.db.healer.enabled
              end,
              get = function(_)
                return NS.db.healer.attachToHealthBar
              end,
              set = function(_, val)
                NS.db.healer.attachToHealthBar = val
                NS.OnDbChanged()
              end,
            },
            spacer6 = {
              name = "",
              type = "description",
              order = 17,
              width = "full",
            },
            offsetX = {
              name = "Offset X",
              type = "range",
              order = 18,
              width = 1.2,
              isPercent = false,
              min = -100,
              max = 100,
              step = 1,
              disabled = function(_)
                return not NS.db.healer.enabled
              end,
              get = function(_)
                return NS.db.healer.offsetX
              end,
              set = function(_, val)
                NS.db.healer.offsetX = val
                NS.OnDbChanged()
              end,
            },
            offsetY = {
              name = "Offset Y",
              type = "range",
              order = 19,
              width = 1.2,
              isPercent = false,
              min = -100,
              max = 100,
              step = 1,
              disabled = function(_)
                return not NS.db.healer.enabled
              end,
              get = function(_)
                return NS.db.healer.offsetY
              end,
              set = function(_, val)
                NS.db.healer.offsetY = val
                NS.OnDbChanged()
              end,
            },
            spacer7 = {
              name = "",
              type = "description",
              order = 20,
              width = "full",
            },
            scale = {
              name = "Scale",
              type = "range",
              order = 21,
              width = 1.75,
              isPercent = false,
              min = 0.5,
              max = 2,
              step = 0.01,
              disabled = function(_)
                return not NS.db.healer.enabled
              end,
              get = function(_)
                return NS.db.healer.scale
              end,
              set = function(_, val)
                NS.db.healer.scale = val
                NS.OnDbChanged()
              end,
            },
            spacer8 = {
              name = " ",
              type = "description",
              order = 22,
              width = "full",
            },
            iconDesc = {
              name = "Icon:",
              type = "description",
              order = 23,
              width = "full",
            },
            iconImage = {
              name = " ",
              type = "description",
              order = 24,
              image = function(info)
                return "roleicon-tiny-healerxatlas"
              end,
              imageHeight = 42,
              imageWidth = 42,
            },
          },
        },
        quest = {
          name = "Quest",
          type = "group",
          order = 4,
          args = {
            enable = {
              name = "Enable",
              type = "toggle",
              order = 1,
              width = 0.4,
              get = function(_)
                return NS.db.quest.enabled
              end,
              set = function(_, val)
                NS.db.quest.enabled = val
                NS.OnDbChanged()
              end,
            },
            spacer1 = {
              name = "",
              type = "description",
              order = 2,
              width = 0.1,
            },
            test = {
              name = "Test Mode",
              desc = "Turn on to test settings immediately",
              type = "toggle",
              order = 3,
              width = 1.0,
              disabled = function(_)
                return not NS.db.quest.enabled
              end,
              get = function(_)
                return NS.db.quest.test
              end,
              set = function(_, val)
                NS.db.quest.test = val
                NS.OnDbChanged()
              end,
            },
            spacer2 = {
              name = "",
              type = "description",
              order = 4,
              width = "full",
            },
            position = {
              name = "Position",
              type = "select",
              order = 5,
              width = 1.0,
              values = {
                ["LEFT"] = "Left",
                ["RIGHT"] = "Right",
              },
              sorting = {
                "LEFT",
                "RIGHT",
              },
              disabled = function(_)
                return not NS.db.quest.enabled
              end,
              get = function(_)
                return NS.db.quest.position
              end,
              set = function(_, val)
                NS.db.quest.position = val
                NS.OnDbChanged()
              end,
            },
            spacer3 = {
              name = "",
              type = "description",
              order = 6,
              width = 0.1,
            },
            attachToHealthBar = {
              name = "Attach directly to the healthbar",
              type = "toggle",
              order = 7,
              width = 1.5,
              disabled = function(_)
                return not NS.db.quest.enabled
              end,
              get = function(_)
                return NS.db.quest.attachToHealthBar
              end,
              set = function(_, val)
                NS.db.quest.attachToHealthBar = val
                NS.OnDbChanged()
              end,
            },
            spacer4 = {
              name = "",
              type = "description",
              order = 8,
              width = "full",
            },
            offsetX = {
              name = "Offset X",
              type = "range",
              order = 9,
              width = 1.2,
              isPercent = false,
              min = -100,
              max = 100,
              step = 1,
              disabled = function(_)
                return not NS.db.quest.enabled
              end,
              get = function(_)
                return NS.db.quest.offsetX
              end,
              set = function(_, val)
                NS.db.quest.offsetX = val
                NS.OnDbChanged()
              end,
            },
            offsetY = {
              name = "Offset Y",
              type = "range",
              order = 10,
              width = 1.2,
              isPercent = false,
              min = -100,
              max = 100,
              step = 1,
              disabled = function(_)
                return not NS.db.quest.enabled
              end,
              get = function(_)
                return NS.db.quest.offsetY
              end,
              set = function(_, val)
                NS.db.quest.offsetY = val
                NS.OnDbChanged()
              end,
            },
            spacer5 = {
              name = "",
              type = "description",
              order = 11,
              width = "full",
            },
            scale = {
              name = "Scale",
              type = "range",
              order = 12,
              width = 1.75,
              isPercent = false,
              min = 0.5,
              max = 2,
              step = 0.01,
              disabled = function(_)
                return not NS.db.quest.enabled
              end,
              get = function(_)
                return NS.db.quest.scale
              end,
              set = function(_, val)
                NS.db.quest.scale = val
                NS.OnDbChanged()
              end,
            },
            spacer6 = {
              name = " ",
              type = "description",
              order = 13,
              width = "full",
            },
            iconDesc = {
              name = "Icon:",
              type = "description",
              order = 14,
              width = "full",
            },
            iconImage = {
              name = " ",
              type = "description",
              order = 15,
              image = function(info)
                return "Crosshair_Quest_48xatlas"
              end,
              imageHeight = 48,
              imageWidth = 48,
            },
          },
        },
        marker = {
          name = "Marker",
          type = "group",
          order = 5,
          args = {
            enable = {
              name = "Enable",
              type = "toggle",
              order = 1,
              width = 0.4,
              get = function(_)
                return NS.db.marker.enabled
              end,
              set = function(_, val)
                NS.db.marker.enabled = val
                NS.OnDbChanged()
              end,
            },
            spacer1 = {
              name = "",
              type = "description",
              order = 2,
              width = 0.1,
            },
            test = {
              name = "Test Mode: Add a marker to anyones nameplate to test",
              desc = "",
              type = "description",
              order = 3,
              width = 2.1,
              fontSize = "medium",
              disabled = function(_)
                return not NS.db.marker.enabled
              end,
              get = function(_)
                return NS.db.marker.test
              end,
              set = function(_, val)
                NS.db.marker.test = val
                NS.OnDbChanged()
              end,
            },
            spacer2 = {
              name = "",
              type = "description",
              order = 4,
              width = "full",
            },
            override = {
              name = "Override & Replace other icons",
              desc = "Override and replace any existing icons for units with markers assigned",
              type = "toggle",
              order = 5,
              width = "full",
              disabled = function(_)
                return not NS.db.marker.enabled
              end,
              get = function(_)
                return NS.db.marker.override
              end,
              set = function(_, val)
                NS.db.marker.override = val
                NS.OnDbChanged()
              end,
            },
            spacer3 = {
              name = "",
              type = "description",
              order = 6,
              width = "full",
            },
            position = {
              name = "Position",
              type = "select",
              order = 7,
              width = 1.0,
              values = {
                ["LEFT"] = "Left",
                ["TOP"] = "Top",
                ["RIGHT"] = "Right",
              },
              sorting = {
                "LEFT",
                "TOP",
                "RIGHT",
              },
              disabled = function(_)
                return not NS.db.marker.enabled
              end,
              get = function(_)
                return NS.db.marker.position
              end,
              set = function(_, val)
                NS.db.marker.position = val
                NS.OnDbChanged()
              end,
            },
            spacer4 = {
              name = "",
              type = "description",
              order = 8,
              width = 0.1,
            },
            attachToHealthBar = {
              name = "Attach directly to the healthbar",
              type = "toggle",
              order = 9,
              width = 1.5,
              disabled = function(_)
                return not NS.db.marker.enabled
              end,
              get = function(_)
                return NS.db.marker.attachToHealthBar
              end,
              set = function(_, val)
                NS.db.marker.attachToHealthBar = val
                NS.OnDbChanged()
              end,
            },
            spacer5 = {
              name = "",
              type = "description",
              order = 108,
              width = "full",
            },
            offsetX = {
              name = "Offset X",
              type = "range",
              order = 11,
              width = 1.2,
              isPercent = false,
              min = -100,
              max = 100,
              step = 1,
              disabled = function(_)
                return not NS.db.marker.enabled
              end,
              get = function(_)
                return NS.db.marker.offsetX
              end,
              set = function(_, val)
                NS.db.marker.offsetX = val
                NS.OnDbChanged()
              end,
            },
            offsetY = {
              name = "Offset Y",
              type = "range",
              order = 12,
              width = 1.2,
              isPercent = false,
              min = -100,
              max = 100,
              step = 1,
              disabled = function(_)
                return not NS.db.marker.enabled
              end,
              get = function(_)
                return NS.db.marker.offsetY
              end,
              set = function(_, val)
                NS.db.marker.offsetY = val
                NS.OnDbChanged()
              end,
            },
            spacer6 = {
              name = "",
              type = "description",
              order = 13,
              width = "full",
            },
            scale = {
              name = "Scale",
              type = "range",
              order = 14,
              width = 1.75,
              isPercent = false,
              min = 0.5,
              max = 2,
              step = 0.01,
              disabled = function(_)
                return not NS.db.marker.enabled
              end,
              get = function(_)
                return NS.db.marker.scale
              end,
              set = function(_, val)
                NS.db.marker.scale = val
                NS.OnDbChanged()
              end,
            },
            spacer7 = {
              name = " ",
              type = "description",
              order = 15,
              width = "full",
            },
            iconDesc = {
              name = "Icon:",
              type = "description",
              order = 16,
              width = "full",
            },
            iconImage = {
              name = " ",
              type = "description",
              order = 17,
              image = function(info)
                return "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6xtecture"
              end,
              imageHeight = 52,
              imageWidth = 52,
            },
          },
        },
        -- objective = {
        -- 	name = "Objective",
        -- 	type = "group",
        -- 	order = 6,
        -- 	args = {
        -- 		enable = {
        -- 			name = "Enable",
        -- 			type = "toggle",
        -- 			order = 1,
        -- 			width = 0.4,
        -- 			get = function(_)
        -- 				return NS.db.objective.enabled
        -- 			end,
        -- 			set = function(_, val)
        -- 				NS.db.objective.enabled = val
        -- 				NS.OnDbChanged()
        -- 			end,
        -- 		},
        -- 		spacer1 = {
        -- 			name = "",
        -- 			type = "description",
        -- 			order = 2,
        -- 			width = 0.1,
        -- 		},
        -- 		test = {
        -- 			name = "Test Mode: Go to any elite, rare mob, or tanking dummy to test",
        -- 			desc = "",
        -- 			type = "description",
        -- 			order = 3,
        -- 			width = 2.4,
        -- 			fontSize = "medium",
        -- 			disabled = function(_)
        -- 				return not NS.db.objective.enabled
        -- 			end,
        -- 			get = function(_)
        -- 				return NS.db.objective.test
        -- 			end,
        -- 			set = function(_, val)
        -- 				NS.db.objective.test = val
        -- 				NS.OnDbChanged()
        -- 			end,
        -- 		},
        -- 		spacer2 = {
        -- 			name = "",
        -- 			type = "description",
        -- 			order = 4,
        -- 			width = "full",
        -- 		},
        -- 		override = {
        -- 			name = "Override & Replace other icons, even markers",
        -- 			desc = "Override and replace any and all existing icons for units with flags, orbs, or crystals assigned",
        -- 			type = "toggle",
        -- 			order = 5,
        -- 			width = "full",
        -- 			disabled = function(_)
        -- 				return not NS.db.objective.enabled
        -- 			end,
        -- 			get = function(_)
        -- 				return NS.db.objective.override
        -- 			end,
        -- 			set = function(_, val)
        -- 				NS.db.objective.override = val
        -- 				NS.OnDbChanged()
        -- 			end,
        -- 		},
        -- 		spacer3 = {
        -- 			name = "",
        -- 			type = "description",
        -- 			order = 6,
        -- 			width = "full",
        -- 		},
        -- 		position = {
        -- 			name = "Position",
        -- 			type = "select",
        -- 			order = 7,
        -- 			width = 1.0,
        -- 			values = {
        -- 				["LEFT"] = "Left",
        -- 				["TOP"] = "Top",
        -- 				["RIGHT"] = "Right",
        -- 			},
        -- 			sorting = {
        -- 				"LEFT",
        -- 				"TOP",
        -- 				"RIGHT",
        -- 			},
        -- 			disabled = function(_)
        -- 				return not NS.db.objective.enabled
        -- 			end,
        -- 			get = function(_)
        -- 				return NS.db.objective.position
        -- 			end,
        -- 			set = function(_, val)
        -- 				NS.db.objective.position = val
        -- 				NS.OnDbChanged()
        -- 			end,
        -- 		},
        -- 		spacer4 = {
        -- 			name = "",
        -- 			type = "description",
        -- 			order = 8,
        -- 			width = 0.1,
        -- 		},
        -- 		attachToHealthBar = {
        -- 			name = "Attach directly to the healthbar",
        -- 			type = "toggle",
        -- 			order = 9,
        -- 			width = 1.5,
        -- 			disabled = function(_)
        -- 				return not NS.db.objective.enabled
        -- 			end,
        -- 			get = function(_)
        -- 				return NS.db.objective.attachToHealthBar
        -- 			end,
        -- 			set = function(_, val)
        -- 				NS.db.objective.attachToHealthBar = val
        -- 				NS.OnDbChanged()
        -- 			end,
        -- 		},
        -- 		spacer5 = {
        -- 			name = "",
        -- 			type = "description",
        -- 			order = 108,
        -- 			width = "full",
        -- 		},
        -- 		offsetX = {
        -- 			name = "Offset X",
        -- 			type = "range",
        -- 			order = 11,
        -- 			width = 1.2,
        -- 			isPercent = false,
        -- 			min = -100,
        -- 			max = 100,
        -- 			step = 1,
        -- 			disabled = function(_)
        -- 				return not NS.db.objective.enabled
        -- 			end,
        -- 			get = function(_)
        -- 				return NS.db.objective.offsetX
        -- 			end,
        -- 			set = function(_, val)
        -- 				NS.db.objective.offsetX = val
        -- 				NS.OnDbChanged()
        -- 			end,
        -- 		},
        -- 		offsetY = {
        -- 			name = "Offset Y",
        -- 			type = "range",
        -- 			order = 12,
        -- 			width = 1.2,
        -- 			isPercent = false,
        -- 			min = -100,
        -- 			max = 100,
        -- 			step = 1,
        -- 			disabled = function(_)
        -- 				return not NS.db.objective.enabled
        -- 			end,
        -- 			get = function(_)
        -- 				return NS.db.objective.offsetY
        -- 			end,
        -- 			set = function(_, val)
        -- 				NS.db.objective.offsetY = val
        -- 				NS.OnDbChanged()
        -- 			end,
        -- 		},
        -- 		spacer6 = {
        -- 			name = "",
        -- 			type = "description",
        -- 			order = 13,
        -- 			width = "full",
        -- 		},
        -- 		scale = {
        -- 			name = "Scale",
        -- 			type = "range",
        -- 			order = 14,
        -- 			width = 1.75,
        -- 			isPercent = false,
        -- 			min = 0.5,
        -- 			max = 3,
        -- 			step = 0.01,
        -- 			disabled = function(_)
        -- 				return not NS.db.objective.enabled
        -- 			end,
        -- 			get = function(_)
        -- 				return NS.db.objective.scale
        -- 			end,
        -- 			set = function(_, val)
        -- 				NS.db.objective.scale = val
        -- 				NS.OnDbChanged()
        -- 			end,
        -- 		},
        -- 		spacer7 = {
        -- 			name = " ",
        -- 			type = "description",
        -- 			order = 15,
        -- 			width = "full",
        -- 		},
        -- 		iconDesc = {
        -- 			name = "Icon:",
        -- 			type = "description",
        -- 			order = 16,
        -- 			width = "full",
        -- 		},
        -- 		iconImage = {
        -- 			name = " ",
        -- 			type = "description",
        -- 			order = 17,
        -- 			image = function(info)
        -- 				return UnitFactionGroup("player") == "Alliance" and "ctf_flags-rightIcon1-state1xatlas"
        -- 					or "ctf_flags-leftIcon1-state1xatlas"
        -- 			end,
        -- 			imageHeight = 48,
        -- 			imageWidth = 48,
        -- 		},
        -- 	},
        -- },
        npc = {
          name = "Totems/Pets",
          type = "group",
          order = 7,
          args = {
            enable = {
              name = "Enable",
              type = "toggle",
              order = 1,
              width = 0.4,
              get = function(_)
                return NS.db.npc.enabled
              end,
              set = function(_, val)
                NS.db.npc.enabled = val
                NS.OnDbChanged()
              end,
            },
            spacer1 = {
              name = "",
              type = "description",
              order = 2,
              width = 0.1,
            },
            test = {
              name = "Test Mode",
              desc = "Turn on to test settings immediately",
              type = "toggle",
              order = 3,
              width = 1.0,
              disabled = function(_)
                return not NS.db.npc.enabled
              end,
              get = function(_)
                return NS.db.npc.test
              end,
              set = function(_, val)
                NS.db.npc.test = val
                NS.OnDbChanged()
              end,
            },
            spacer2 = {
              name = "",
              type = "description",
              order = 4,
              width = "full",
            },
            desc1 = {
              name = "Show for:",
              fontSize = "medium",
              type = "description",
              order = 5,
              width = 0.4,
            },
            showFriendly = {
              name = "Friendly",
              type = "toggle",
              order = 6,
              width = 0.5,
              disabled = function(_)
                return not NS.db.npc.enabled
              end,
              get = function(_)
                return NS.db.npc.showFriendly
              end,
              set = function(_, val)
                NS.db.npc.showFriendly = val
                NS.OnDbChanged()
              end,
            },
            showEnemy = {
              name = "Enemy",
              type = "toggle",
              order = 7,
              width = 0.4,
              disabled = function(_)
                return not NS.db.npc.enabled
              end,
              get = function(_)
                return NS.db.npc.showEnemy
              end,
              set = function(_, val)
                NS.db.npc.showEnemy = val
                NS.OnDbChanged()
              end,
            },
            spacer3 = {
              name = "",
              type = "description",
              order = 8,
              width = "full",
            },
            desc2 = {
              name = "Show in:",
              fontSize = "medium",
              type = "description",
              order = 9,
              width = 0.4,
            },
            showArena = {
              name = "Arena",
              type = "toggle",
              order = 10,
              width = 0.4,
              disabled = function(_)
                return not NS.db.npc.enabled
              end,
              get = function(_)
                return NS.db.npc.showArena
              end,
              set = function(_, val)
                NS.db.npc.showArena = val
                NS.OnDbChanged()
              end,
            },
            showBattleground = {
              name = "Battleground",
              type = "toggle",
              order = 11,
              width = 0.7,
              disabled = function(_)
                return not NS.db.npc.enabled
              end,
              get = function(_)
                return NS.db.npc.showBattleground
              end,
              set = function(_, val)
                NS.db.npc.showBattleground = val
                NS.OnDbChanged()
              end,
            },
            showOutdoors = {
              name = "Outdoors",
              type = "toggle",
              order = 12,
              width = 0.5,
              disabled = function(_)
                return not NS.db.npc.enabled
              end,
              get = function(_)
                return NS.db.npc.showOutdoors
              end,
              set = function(_, val)
                NS.db.npc.showOutdoors = val
                NS.OnDbChanged()
              end,
            },
            spacer4 = {
              name = "",
              type = "description",
              order = 13,
              width = "full",
            },
            position = {
              name = "Position",
              type = "select",
              order = 14,
              width = 1.0,
              values = {
                ["LEFT"] = "Left",
                ["TOP"] = "Top",
                ["RIGHT"] = "Right",
              },
              sorting = {
                "LEFT",
                "TOP",
                "RIGHT",
              },
              disabled = function(_)
                return not NS.db.npc.enabled
              end,
              get = function(_)
                return NS.db.npc.position
              end,
              set = function(_, val)
                NS.db.npc.position = val
                NS.OnDbChanged()
              end,
            },
            spacer5 = {
              name = "",
              type = "description",
              order = 15,
              width = 0.1,
            },
            attachToHealthBar = {
              name = "Attach directly to the healthbar",
              type = "toggle",
              order = 16,
              width = 1.5,
              disabled = function(_)
                return not NS.db.npc.enabled
              end,
              get = function(_)
                return NS.db.npc.attachToHealthBar
              end,
              set = function(_, val)
                NS.db.npc.attachToHealthBar = val
                NS.OnDbChanged()
              end,
            },
            spacer6 = {
              name = "",
              type = "description",
              order = 17,
              width = "full",
            },
            offsetX = {
              name = "Offset X",
              type = "range",
              order = 18,
              width = 1.2,
              isPercent = false,
              min = -100,
              max = 100,
              step = 1,
              disabled = function(_)
                return not NS.db.npc.enabled
              end,
              get = function(_)
                return NS.db.npc.offsetX
              end,
              set = function(_, val)
                NS.db.npc.offsetX = val
                NS.OnDbChanged()
              end,
            },
            offsetY = {
              name = "Offset Y",
              type = "range",
              order = 19,
              width = 1.2,
              isPercent = false,
              min = -100,
              max = 100,
              step = 1,
              disabled = function(_)
                return not NS.db.npc.enabled
              end,
              get = function(_)
                return NS.db.npc.offsetY
              end,
              set = function(_, val)
                NS.db.npc.offsetY = val
                NS.OnDbChanged()
              end,
            },
            spacer7 = {
              name = "",
              type = "description",
              order = 20,
              width = "full",
            },
            scale = {
              name = "Scale",
              type = "range",
              order = 21,
              width = 1.75,
              isPercent = false,
              min = 0.5,
              max = 4,
              step = 0.01,
              disabled = function(_)
                return not NS.db.npc.enabled
              end,
              get = function(_)
                return NS.db.npc.scale
              end,
              set = function(_, val)
                NS.db.npc.scale = val
                NS.OnDbChanged()
              end,
            },
            spacer8 = {
              name = " ",
              type = "description",
              order = 22,
              width = "full",
            },
            desc3 = {
              name = "The following setting only works properly when the npc nameplate is in view when cast.",
              fontSize = "small",
              type = "description",
              order = 23,
              width = 1.5,
            },
            spacer9 = {
              name = "",
              type = "description",
              order = 24,
              width = "full",
            },
            showCountdown = {
              name = "Show countdown duration on icon",
              type = "toggle",
              order = 25,
              width = "full",
              disabled = function(_)
                return not NS.db.npc.enabled
              end,
              get = function(_)
                return NS.db.npc.showCountdown
              end,
              set = function(_, val)
                NS.db.npc.showCountdown = val
                NS.OnDbChanged()
              end,
            },
            iconDesc = {
              name = "Icon:",
              type = "description",
              order = 26,
              width = "full",
            },
            desc4 = {
              name = 'The icon settings for NPCs can be found at the top in the "Totem/Pet List" tab.',
              fontSize = "medium",
              type = "description",
              order = 27,
              width = "full",
            },
          },
        },
      },
    },
    general = {
      name = "General",
      type = "group",
      order = 2,
      args = {
        hideServerName = {
          name = "Hide server name on player nameplates",
          type = "toggle",
          order = 1,
          width = 1.7,
          get = function(_)
            return NS.db.general.hideServerName
          end,
          set = function(_, val)
            NS.db.general.hideServerName = val
            NS.OnDbChanged()
          end,
        },
        showRealmIndicator = {
          name = "Show different realm indicator, (*)",
          type = "toggle",
          order = 2,
          width = 1.5,
          disabled = function(_)
            return not NS.db.general.hideServerName
          end,
          get = function(_)
            return NS.db.general.showRealmIndicator
          end,
          set = function(_, val)
            NS.db.general.showRealmIndicator = val
            NS.OnDbChanged()
          end,
        },
        spacer1 = {
          name = "",
          type = "description",
          order = 3,
          width = "full",
        },
        ignoreNameplateAlpha = {
          name = "Ignore nameplate alpha",
          type = "toggle",
          order = 4,
          width = 1.1,
          get = function(_)
            return NS.db.general.ignoreNameplateAlpha
          end,
          set = function(_, val)
            NS.db.general.ignoreNameplateAlpha = val
            NS.OnDbChanged()
          end,
        },
        ignoreNameplateScale = {
          name = "Ignore nameplate scale",
          type = "toggle",
          order = 5,
          width = 1.0,
          get = function(_)
            return NS.db.general.ignoreNameplateScale
          end,
          set = function(_, val)
            NS.db.general.ignoreNameplateScale = val
            NS.OnDbChanged()
          end,
        },
        spacer2 = {
          name = "",
          type = "description",
          order = 6,
          width = "full",
        },
        desc = {
          name = "The following settings may be affected by other addons.",
          fontSize = "small",
          type = "description",
          order = 7,
          width = "full",
        },
        selfClickThrough = {
          name = "Click Through Self Nameplate",
          type = "toggle",
          order = 8,
          width = "full",
          get = function(_)
            return NS.db.general.selfClickThrough
          end,
          set = function(_, val)
            NS.db.general.selfClickThrough = val
            NS.OnDbChanged()
          end,
        },
        friendlyClickThrough = {
          name = "Click Through Friendly Nameplates",
          type = "toggle",
          order = 9,
          width = "full",
          get = function(_)
            return NS.db.general.friendlyClickThrough
          end,
          set = function(_, val)
            NS.db.general.friendlyClickThrough = val
            NS.OnDbChanged()
          end,
        },
        enemyClickThrough = {
          name = "Click Through Enemy Nameplates",
          type = "toggle",
          order = 10,
          width = "full",
          get = function(_)
            return NS.db.general.enemyClickThrough
          end,
          set = function(_, val)
            NS.db.general.enemyClickThrough = val
            NS.OnDbChanged()
          end,
        },
      },
    },
    nameplate = {
      name = "Nameplates",
      type = "group",
      order = 3,
      args = {
        desc1 = {
          name = "Choose where to apply the following settings:",
          fontSize = "medium",
          type = "description",
          order = 1,
          width = "full",
        },
        showArena = {
          name = "Arena",
          type = "toggle",
          order = 2,
          width = 0.4,
          get = function(_)
            return NS.db.nameplate.showArena
          end,
          set = function(_, val)
            NS.db.nameplate.showArena = val
            NS.OnDbChanged()
          end,
        },
        showBattleground = {
          name = "Battleground",
          type = "toggle",
          order = 3,
          width = 0.7,
          get = function(_)
            return NS.db.nameplate.showBattleground
          end,
          set = function(_, val)
            NS.db.nameplate.showBattleground = val
            NS.OnDbChanged()
          end,
        },
        showOutdoors = {
          name = "Outdoors",
          type = "toggle",
          order = 4,
          width = 0.5,
          get = function(_)
            return NS.db.nameplate.showOutdoors
          end,
          set = function(_, val)
            NS.db.nameplate.showOutdoors = val
            NS.OnDbChanged()
          end,
        },
        friendly = {
          name = "Friendly Player Nameplate Settings",
          type = "group",
          inline = true,
          order = 5,
          disabled = function(_)
            return not NS.db.nameplate.showArena
              and not NS.db.nameplate.showBattleground
              and not NS.db.nameplate.showOutdoors
          end,
          args = {
            healthBars = {
              name = "Hide Friendly Player Healthbars",
              type = "toggle",
              width = 1.5,
              order = 1,
              get = function(_)
                return NS.db.nameplate.healthBars.hideFriendly
              end,
              set = function(_, val)
                NS.db.nameplate.healthBars.hideFriendly = val
                NS.OnDbChanged()
              end,
            },
            names = {
              name = "Hide Friendly Player Names",
              type = "toggle",
              width = 1.5,
              order = 2,
              get = function(_)
                return NS.db.nameplate.names.hideFriendly
              end,
              set = function(_, val)
                NS.db.nameplate.names.hideFriendly = val
                NS.OnDbChanged()
              end,
            },
            castBars = {
              name = "Hide Friendly Player Castbars",
              type = "toggle",
              width = 1.5,
              order = 3,
              get = function(_)
                return NS.db.nameplate.castBars.hideFriendly
              end,
              set = function(_, val)
                NS.db.nameplate.castBars.hideFriendly = val
                NS.OnDbChanged()
              end,
            },
            buffFrames = {
              name = "Hide Friendly Player BuffFrames",
              type = "toggle",
              width = 1.5,
              order = 4,
              get = function(_)
                return NS.db.nameplate.buffFrames.hideFriendly
              end,
              set = function(_, val)
                NS.db.nameplate.buffFrames.hideFriendly = val
                NS.OnDbChanged()
              end,
            },
          },
        },
        enemy = {
          name = "Enemy Player Nameplate Settings",
          type = "group",
          inline = true,
          order = 6,
          disabled = function(_)
            return not NS.db.nameplate.showArena
              and not NS.db.nameplate.showBattleground
              and not NS.db.nameplate.showOutdoors
          end,
          args = {
            healthBars = {
              name = "Hide Enemy Player Healthbars",
              type = "toggle",
              width = 1.5,
              order = 1,
              get = function(_)
                return NS.db.nameplate.healthBars.hideEnemy
              end,
              set = function(_, val)
                NS.db.nameplate.healthBars.hideEnemy = val
                NS.OnDbChanged()
              end,
            },
            names = {
              name = "Hide Enemy Player Names",
              type = "toggle",
              width = 1.5,
              order = 2,
              get = function(_)
                return NS.db.nameplate.names.hideEnemy
              end,
              set = function(_, val)
                NS.db.nameplate.names.hideEnemy = val
                NS.OnDbChanged()
              end,
            },
            castBars = {
              name = "Hide Enemy Player Castbars",
              type = "toggle",
              width = 1.5,
              order = 3,
              get = function(_)
                return NS.db.nameplate.castBars.hideEnemy
              end,
              set = function(_, val)
                NS.db.nameplate.castBars.hideEnemy = val
                NS.OnDbChanged()
              end,
            },
            buffFrames = {
              name = "Hide Enemy Player BuffFrames",
              type = "toggle",
              width = 1.5,
              order = 4,
              get = function(_)
                return NS.db.nameplate.buffFrames.hideEnemy
              end,
              set = function(_, val)
                NS.db.nameplate.buffFrames.hideEnemy = val
                NS.OnDbChanged()
              end,
            },
          },
        },
        npc = {
          name = "NPC Nameplate Settings",
          type = "group",
          inline = true,
          order = 7,
          disabled = function(_)
            return not NS.db.nameplate.showArena
              and not NS.db.nameplate.showBattleground
              and not NS.db.nameplate.showOutdoors
          end,
          args = {
            healthBars = {
              name = "Hide NPC Healthbars",
              type = "toggle",
              width = 1.5,
              order = 1,
              get = function(_)
                return NS.db.nameplate.healthBars.hideNPC
              end,
              set = function(_, val)
                NS.db.nameplate.healthBars.hideNPC = val
                NS.OnDbChanged()
              end,
            },
            names = {
              name = "Hide NPC Names",
              type = "toggle",
              width = 1.5,
              order = 2,
              get = function(_)
                return NS.db.nameplate.names.hideNPC
              end,
              set = function(_, val)
                NS.db.nameplate.names.hideNPC = val
                NS.OnDbChanged()
              end,
            },
            castBars = {
              name = "Hide NPC Castbars",
              type = "toggle",
              width = 1.5,
              order = 3,
              get = function(_)
                return NS.db.nameplate.castBars.hideNPC
              end,
              set = function(_, val)
                NS.db.nameplate.castBars.hideNPC = val
                NS.OnDbChanged()
              end,
            },
            buffFrames = {
              name = "Hide NPC BuffFrames",
              type = "toggle",
              width = 1.5,
              order = 4,
              get = function(_)
                return NS.db.nameplate.buffFrames.hideNPC
              end,
              set = function(_, val)
                NS.db.nameplate.buffFrames.hideNPC = val
                NS.OnDbChanged()
              end,
            },
          },
        },
        desc = {
          name = "These settings may be affected by other addons.",
          fontSize = "small",
          type = "description",
          order = 8,
          width = "full",
        },
      },
    },
    npcs = {
      name = "Totem/Pet List",
      type = "group",
      childGroups = "tree",
      order = 4,
      args = {
        title = {
          name = "If you want to add to this list message me on discord.",
          type = "description",
          order = 1,
          fontSize = "medium",
          width = "full",
        },
        discordDesc = {
          name = "Link:",
          type = "description",
          fontSize = "medium",
          order = 2,
          width = 0.2,
        },
        discord = {
          name = "",
          type = "input",
          order = 3,
          width = 1.2,
          get = function()
            return "https://discord.gg/A3g5qZqtdc"
          end,
        },
        spacer2 = {
          name = "",
          type = "description",
          order = 4,
          width = "full",
        },
      },
    },
    profiles = {
      name = "Profiles",
      type = "group",
      desc = "Manage Profiles",
      order = 5,
      args = {
        desc = {
          order = 1,
          type = "description",
          name = "You can change the active database profile, so you can have different settings for every character.\n",
        },
        descreset = {
          order = 9,
          type = "description",
          name = "Reset the current profile back to its default values, in case your configuration is broken, or you simply want to start over.",
        },
        reset = {
          order = 10,
          type = "execute",
          name = "Reset Profile",
          desc = "Reset the current profile to the default",
          func = "Reset",
        },
        current = {
          order = 11,
          type = "description",
          name = function(info)
            return "Current Profile:"
              .. " "
              .. NORMAL_FONT_COLOR_CODE
              .. info.handler:GetCurrentProfile()
              .. FONT_COLOR_CODE_CLOSE
          end,
          width = 2.0,
        },
        choosedesc = {
          order = 20,
          type = "description",
          name = "\nYou can either create a new profile by entering a name in the editbox, or choose one of the already existing profiles.",
        },
        new = {
          name = "New",
          desc = "Create a new empty profile.",
          type = "input",
          order = 30,
          get = false,
          set = "SetProfile",
        },
        choose = {
          name = "Existing Profiles",
          desc = "Select one of your currently available profiles.",
          type = "select",
          order = 40,
          get = "GetCurrentProfile",
          set = "SetProfile",
          values = "ListProfiles",
          arg = "common",
        },
        copydesc = {
          order = 50,
          type = "description",
          name = "\nCopy the settings from one existing profile into the currently active profile.",
        },
        copyfrom = {
          order = 60,
          type = "select",
          name = "Copy From",
          desc = "Copy the settings from one existing profile into the currently active profile.",
          get = false,
          set = "CopyProfile",
          values = "ListProfiles",
          disabled = "HasNoProfiles",
          arg = "nocurrent",
        },
        deldesc = {
          order = 70,
          type = "description",
          name = "\nDelete existing and unused profiles from the database to save space, and cleanup the SavedVariables file.",
        },
        delete = {
          order = 80,
          type = "select",
          name = "Delete a Profile",
          desc = "Deletes a profile from the database.",
          get = false,
          set = "DeleteProfile",
          values = "ListProfiles",
          disabled = "HasNoProfiles",
          arg = "nocurrent",
          confirm = true,
          confirmText = "Are you sure you want to delete the selected profile?",
        },
      },
    },
    share = {
      name = "Import/Export",
      type = "group",
      desc = "Import/Export Profiles",
      order = 6,
      args = {
        descimp = {
          name = "Import any valid export string created from someone elses NameplateIcons profile.\n",
          type = "description",
          order = 1,
        },
        descexp = {
          name = "Export any of your profiles to share with anyone for use in their NameplateIcons.",
          type = "description",
          order = 2,
        },
        export = {
          name = "Export Profile",
          desc = "Export the active profile into an importable string",
          type = "execute",
          order = 3,
          width = 1.0,
          func = function()
            NS:ShowExport()
          end,
        },
        current = {
          name = function(info)
            return "Current Profile:"
              .. " "
              .. NORMAL_FONT_COLOR_CODE
              .. NameplateIconsDB.profileKeys[NS.CHAR_NAME]
              .. FONT_COLOR_CODE_CLOSE
          end,
          type = "description",
          order = 4,
          width = 2.0,
        },
        spacer1 = {
          name = "",
          type = "description",
          order = 5,
          width = "full",
        },
        import = {
          name = "Import Profile",
          desc = "Import an exported NameplateIcons profile string",
          type = "execute",
          order = 6,
          width = 1.0,
          func = function()
            NS:ShowImport()
          end,
        },
      },
    },
  },
}
NS.AceConfig = AceConfig

--- @type fun(npcId: string, npcInfo: MyNPCInfo, index: integer)
NS.MakeOption = function(npcId, npcInfo, index)
  local npcName = npcInfo.name
  local npcIcon = npcInfo.icon
  local npcGlow = npcInfo.glow
  local NPC_ID = tostring(npcId)

  local color = ""
  if npcInfo.enabled then
    color = "|cFF00FF00" -- green
  elseif not npcInfo.enabled then
    color = "|cFFFF0000" -- red
  end

  NS.AceConfig.args.npcs.args[NPC_ID] = {
    name = color .. npcName,
    icon = npcIcon,
    desc = "",
    type = "group",
    order = 10 + index,
    args = {
      enabled = {
        name = "Enable NPC",
        type = "toggle",
        order = 1,
        width = "full",
        get = function(info)
          return NS.db[info[1]][info[2]] and NS.db[info[1]][info[2]][info[3]] or npcInfo.enabled
        end,
        set = function(info, value)
          if value then
            color = "|cFF00FF00" -- green
          else
            color = "|cFFFF0000" -- red
          end

          NS.db[info[1]][info[2]][info[3]] = value
          NS.AceConfig.args.npcs.args[NPC_ID].name = color .. npcName

          NS.OnDbChanged()
        end,
      },
      enableGlow = {
        name = "Enable Glow",
        type = "toggle",
        order = 2,
        width = "full",
        disabled = function(info)
          return not NS.db[info[1]][info[2]].enabled
        end,
        get = function(info)
          return NS.db[info[1]][info[2]] and NS.db[info[1]][info[2]][info[3]] or npcInfo.enableGlow
        end,
        set = function(info, value)
          NS.db[info[1]][info[2]][info[3]] = value

          local glowFrame = _G["EditGlowFrame" .. npcIcon]
          if glowFrame then
            if NS.db[info[1]][info[2]].enableGlow then
              glowFrame:Show()
              glowFrame.glowTexture:SetAlpha(1)
            else
              glowFrame.glowTexture:SetAlpha(0)
              glowFrame:Hide()
            end
          end

          NS.OnDbChanged()
        end,
      },
      healthColor = {
        name = "Change Healthbar color to match Glow color",
        type = "toggle",
        order = 3,
        width = "full",
        disabled = function(info)
          return not NS.db[info[1]][info[2]].enabled or not NS.db[info[1]][info[2]].enableGlow
        end,
        get = function(info)
          return NS.db[info[1]][info[2]] and NS.db[info[1]][info[2]][info[3]] or true
        end,
        set = function(info, value)
          NS.db[info[1]][info[2]][info[3]] = value
          NS.OnDbChanged()
        end,
      },
      nameColor = {
        name = "Change Name color to match Glow color",
        type = "toggle",
        order = 4,
        width = "full",
        disabled = function(info)
          return not NS.db[info[1]][info[2]].enabled or not NS.db[info[1]][info[2]].enableGlow
        end,
        get = function(info)
          return NS.db[info[1]][info[2]] and NS.db[info[1]][info[2]][info[3]] or true
        end,
        set = function(info, value)
          NS.db[info[1]][info[2]][info[3]] = value
          NS.OnDbChanged()
        end,
      },
      glow = {
        type = "color",
        name = " Change Glow color",
        order = 5,
        width = "full",
        hasAlpha = true,
        disabled = function(info)
          return not NS.db[info[1]][info[2]].enabled or not NS.db[info[1]][info[2]].enableGlow
        end,
        get = function(info)
          local glow = NS.db[info[1]][info[2]] and NS.db[info[1]][info[2]][info[3]] or npcGlow
          return glow[1], glow[2], glow[3], glow[4]
        end,
        set = function(info, val1, val2, val3, val4)
          NS.db[info[1]][info[2]][info[3]][1] = val1
          NS.db[info[1]][info[2]][info[3]][2] = val2
          NS.db[info[1]][info[2]][info[3]][3] = val3
          NS.db[info[1]][info[2]][info[3]][4] = val4

          local glowFrame = _G["EditGlowFrame" .. npcIcon]
          if glowFrame then
            glowFrame.glowTexture:SetVertexColor(val1, val2, val3, val4)
          end

          NS.OnDbChanged()
        end,
      },
      spacer2 = {
        type = "description",
        name = "",
        order = 6,
        width = "full",
      },
      iconDesc = {
        name = "Icon:",
        type = "description",
        order = 7,
        width = "full",
      },
      icon = {
        order = 8,
        type = "description",
        name = " ",
        image = function(info)
          return GenerateIconString(info, npcIcon, npcGlow)
        end,
        imageHeight = 64,
        imageWidth = 64,
      },
    },
  }
end

NS.BuildOptions = function()
  --- @type { [string]: MyNPCInfo }[]
  local buildList = {}
  ---@param npcId string
  ---@param npcInfo MyNPCInfo
  for npcId, npcInfo in pairs(NS.db.npcs) do
    --- @type { [string]: MyNPCInfo }
    local npc = {
      [npcId] = npcInfo,
    }
    tinsert(buildList, npc)
  end
  tsort(buildList, NS.SortListByName)
  for i = 1, #buildList do
    --- @type { [string]: MyNPCInfo }
    local spell = buildList[i]
    if spell then
      --- @type string, MyNPCInfo
      local spellId, spellInfo = next(spell)
      NS.MakeOption(spellId, spellInfo, i)
    end
  end
end
