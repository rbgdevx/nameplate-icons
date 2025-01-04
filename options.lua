local AddonName, NS = ...

local tinsert = table.insert
local tsort = table.sort
local tconcat = table.concat

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
    general = {
      name = "General",
      type = "group",
      order = 1,
      args = {
        ignoreNameplateAlpha = {
          name = "Ignore nameplate alpha",
          type = "toggle",
          order = 1,
          width = "full",
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
          order = 2,
          width = "full",
          get = function(_)
            return NS.db.general.ignoreNameplateScale
          end,
          set = function(_, val)
            NS.db.general.ignoreNameplateScale = val
            NS.OnDbChanged()
          end,
        },
        spacer1 = {
          name = "",
          type = "description",
          order = 3,
          width = "full",
        },
        desc = {
          name = "The following settings may be affected by other addons.",
          fontSize = "small",
          type = "description",
          order = 4,
          width = "full",
        },
        selfClickThrough = {
          name = "Click Through Self Nameplate",
          type = "toggle",
          order = 5,
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
          order = 6,
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
          order = 7,
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
    icons = {
      name = "Icons",
      type = "group",
      childGroups = "tab",
      order = 2,
      args = {
        arena = {
          name = "Arena",
          type = "group",
          order = 1,
          args = {
            enable = {
              name = "Enable",
              type = "toggle",
              order = 1,
              width = 0.4,
              get = function(_)
                return NS.db.arena.enabled
              end,
              set = function(_, val)
                NS.db.arena.enabled = val
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
              type = "toggle",
              order = 3,
              width = 1.0,
              disabled = function(_)
                return not NS.db.arena.enabled
              end,
              get = function(_)
                return NS.db.arena.test
              end,
              set = function(_, val)
                NS.db.arena.test = val
                NS.OnDbChanged()
              end,
            },
            spacer2 = {
              name = "",
              type = "description",
              order = 4,
              width = "full",
            },
            showFriendly = {
              name = "Show Friendly",
              type = "toggle",
              order = 5,
              width = 1.1,
              disabled = function(_)
                return not NS.db.arena.enabled
              end,
              get = function(_)
                return NS.db.arena.showFriendly
              end,
              set = function(_, val)
                NS.db.arena.showFriendly = val
                NS.OnDbChanged()
              end,
            },
            showEnemy = {
              name = "Show Enemy",
              type = "toggle",
              order = 6,
              width = 1.1,
              disabled = function(_)
                return not NS.db.arena.enabled
              end,
              get = function(_)
                return NS.db.arena.showEnemy
              end,
              set = function(_, val)
                NS.db.arena.showEnemy = val
                NS.OnDbChanged()
              end,
            },
            spacer3 = {
              name = "",
              type = "description",
              order = 7,
              width = "full",
            },
            position = {
              name = "Position",
              type = "select",
              order = 8,
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
                return not NS.db.arena.enabled
              end,
              get = function(_)
                return NS.db.arena.position
              end,
              set = function(_, val)
                NS.db.arena.position = val
                NS.OnDbChanged()
              end,
            },
            spacer4 = {
              name = "",
              type = "description",
              order = 9,
              width = 0.1,
            },
            attachToHealthBar = {
              name = "Attach directly to the healthbar",
              type = "toggle",
              order = 10,
              width = 1.5,
              disabled = function(_)
                return not NS.db.arena.enabled
              end,
              get = function(_)
                return NS.db.arena.attachToHealthBar
              end,
              set = function(_, val)
                NS.db.arena.attachToHealthBar = val
                NS.OnDbChanged()
              end,
            },
            spacer5 = {
              name = "",
              type = "description",
              order = 11,
              width = "full",
            },
            offsetX = {
              name = "Offset X",
              type = "range",
              order = 12,
              width = 1.2,
              isPercent = false,
              min = -100,
              max = 100,
              step = 1,
              disabled = function(_)
                return not NS.db.arena.enabled
              end,
              get = function(_)
                return NS.db.arena.offsetX
              end,
              set = function(_, val)
                NS.db.arena.offsetX = val
                NS.OnDbChanged()
              end,
            },
            offsetY = {
              name = "Offset Y",
              type = "range",
              order = 13,
              width = 1.2,
              isPercent = false,
              min = -100,
              max = 100,
              step = 1,
              disabled = function(_)
                return not NS.db.arena.enabled
              end,
              get = function(_)
                return NS.db.arena.offsetY
              end,
              set = function(_, val)
                NS.db.arena.offsetY = val
                NS.OnDbChanged()
              end,
            },
            spacer6 = {
              name = "",
              type = "description",
              order = 14,
              width = "full",
            },
            scale = {
              name = "Scale",
              type = "range",
              order = 15,
              width = 1.75,
              isPercent = false,
              min = 0.5,
              max = 2,
              step = 0.01,
              disabled = function(_)
                return not NS.db.arena.enabled
              end,
              get = function(_)
                return NS.db.arena.scale
              end,
              set = function(_, val)
                NS.db.arena.scale = val
                NS.OnDbChanged()
              end,
            },
            replaceHealerIcon = {
              name = "Replace arena icon with healer icon for healers",
              type = "toggle",
              order = 16,
              width = "full",
              disabled = function(_)
                return not NS.db.arena.enabled
              end,
              get = function(_)
                return NS.db.arena.replaceHealerIcon
              end,
              set = function(_, val)
                NS.db.arena.replaceHealerIcon = val
                NS.OnDbChanged()
              end,
            },
            icon = {
              name = "Icon:",
              type = "select",
              order = 17,
              width = 1.0,
              values = {
                ["arrow"] = "Arrow",
                ["class"] = "Class",
              },
              sorting = {
                "arrow",
                "class",
              },
              disabled = function(_)
                return not NS.db.arena.enabled
              end,
              get = function(_)
                return NS.db.arena.icon
              end,
              set = function(_, val)
                NS.db.arena.icon = val
                NS.OnDbChanged()
              end,
            },
            desc1 = {
              name = "  (Scroll down for more options)",
              type = "description",
              order = 18,
              width = 1.0,
            },
            iconImage = {
              order = 19,
              type = "description",
              name = " ",
              image = function(info)
                local texture = ""
                if NS.db.arena.icon == "arrow" then
                  texture = "covenantsanctum-renown-doublearrow-depressedxatlas"
                else
                  texture = "covenantsanctum-renown-doublearrow-depressedxatlas"
                end
                return texture
              end,
              imageHeight = 70,
              imageWidth = 55,
            },
            spacer7 = {
              name = "",
              fontSize = "medium",
              type = "description",
              order = 20,
              width = "full",
            },
            desc2 = {
              name = "The following settings are only applied while inside arena.",
              fontSize = "medium",
              type = "description",
              order = 21,
              width = 1.2,
            },
            showOutside = {
              name = "Apply these settings outside arena",
              type = "toggle",
              order = 22,
              width = 1.5,
              disabled = function(_)
                return not NS.db.arena.enabled
              end,
              get = function(_)
                return NS.db.arena.showOutside
              end,
              set = function(_, val)
                NS.db.arena.showOutside = val
                NS.OnDbChanged()
              end,
            },
            friendly = {
              name = "Friendly Player Nameplate Settings",
              type = "group",
              inline = true,
              order = 23,
              disabled = function(_)
                return not NS.db.arena.enabled
              end,
              args = {
                healthBars = {
                  name = "Hide Friendly Player Healthbars",
                  type = "toggle",
                  width = 1.5,
                  order = 1,
                  get = function(_)
                    return NS.db.arena.healthBars.hideFriendly
                  end,
                  set = function(_, val)
                    NS.db.arena.healthBars.hideFriendly = val
                    NS.OnDbChanged()
                  end,
                },
                names = {
                  name = "Hide Friendly Player Names",
                  type = "toggle",
                  width = 1.5,
                  order = 2,
                  get = function(_)
                    return NS.db.arena.names.hideFriendly
                  end,
                  set = function(_, val)
                    NS.db.arena.names.hideFriendly = val
                    NS.OnDbChanged()
                  end,
                },
                castBars = {
                  name = "Hide Friendly Player Castbars",
                  type = "toggle",
                  width = 1.5,
                  order = 3,
                  get = function(_)
                    return NS.db.arena.castBars.hideFriendly
                  end,
                  set = function(_, val)
                    NS.db.arena.castBars.hideFriendly = val
                    NS.OnDbChanged()
                  end,
                },
                buffFrames = {
                  name = "Hide Friendly Player BuffFrames",
                  type = "toggle",
                  width = 1.5,
                  order = 4,
                  get = function(_)
                    return NS.db.arena.buffFrames.hideFriendly
                  end,
                  set = function(_, val)
                    NS.db.arena.buffFrames.hideFriendly = val
                    NS.OnDbChanged()
                  end,
                },
              },
            },
            enemy = {
              name = "Enemy Player Nameplate Settings",
              type = "group",
              inline = true,
              order = 24,
              disabled = function(_)
                return not NS.db.arena.enabled
              end,
              args = {
                healthBars = {
                  name = "Hide Enemy Player Healthbars",
                  type = "toggle",
                  width = 1.5,
                  order = 1,
                  get = function(_)
                    return NS.db.arena.healthBars.hideEnemy
                  end,
                  set = function(_, val)
                    NS.db.arena.healthBars.hideEnemy = val
                    NS.OnDbChanged()
                  end,
                },
                names = {
                  name = "Hide Enemy Player Names",
                  type = "toggle",
                  width = 1.5,
                  order = 2,
                  get = function(_)
                    return NS.db.arena.names.hideEnemy
                  end,
                  set = function(_, val)
                    NS.db.arena.names.hideEnemy = val
                    NS.OnDbChanged()
                  end,
                },
                castBars = {
                  name = "Hide Enemy Player Castbars",
                  type = "toggle",
                  width = 1.5,
                  order = 3,
                  get = function(_)
                    return NS.db.arena.castBars.hideEnemy
                  end,
                  set = function(_, val)
                    NS.db.arena.castBars.hideEnemy = val
                    NS.OnDbChanged()
                  end,
                },
                buffFrames = {
                  name = "Hide Enemy Player BuffFrames",
                  type = "toggle",
                  width = 1.5,
                  order = 4,
                  get = function(_)
                    return NS.db.arena.buffFrames.hideEnemy
                  end,
                  set = function(_, val)
                    NS.db.arena.buffFrames.hideEnemy = val
                    NS.OnDbChanged()
                  end,
                },
              },
            },
            npc = {
              name = "NPC Nameplate Settings",
              type = "group",
              inline = true,
              order = 25,
              args = {
                healthBars = {
                  name = "Hide NPC Healthbars",
                  type = "toggle",
                  width = 1.5,
                  order = 1,
                  get = function(_)
                    return NS.db.arena.healthBars.hideNPC
                  end,
                  set = function(_, val)
                    NS.db.arena.healthBars.hideNPC = val
                    NS.OnDbChanged()
                  end,
                },
                names = {
                  name = "Hide NPC Names",
                  type = "toggle",
                  width = 1.5,
                  order = 2,
                  get = function(_)
                    return NS.db.arena.names.hideNPC
                  end,
                  set = function(_, val)
                    NS.db.arena.names.hideNPC = val
                    NS.OnDbChanged()
                  end,
                },
                castBars = {
                  name = "Hide NPC Castbars",
                  type = "toggle",
                  width = 1.5,
                  order = 3,
                  get = function(_)
                    return NS.db.arena.castBars.hideNPC
                  end,
                  set = function(_, val)
                    NS.db.arena.castBars.hideNPC = val
                    NS.OnDbChanged()
                  end,
                },
                buffFrames = {
                  name = "Hide NPC BuffFrames",
                  type = "toggle",
                  width = 1.5,
                  order = 4,
                  get = function(_)
                    return NS.db.arena.buffFrames.hideNPC
                  end,
                  set = function(_, val)
                    NS.db.arena.buffFrames.hideNPC = val
                    NS.OnDbChanged()
                  end,
                },
              },
            },
          },
        },
        healer = {
          name = "Healer",
          type = "group",
          order = 2,
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
            showFriendly = {
              name = "Show Friendly",
              type = "toggle",
              order = 5,
              width = 1.1,
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
              name = "Show Enemy",
              type = "toggle",
              order = 6,
              width = 1.1,
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
              order = 7,
              width = "full",
            },
            groupOnly = {
              name = "Show Only in Groups",
              type = "toggle",
              order = 8,
              width = 1.1,
              disabled = function(_)
                return not NS.db.healer.enabled
              end,
              get = function(_)
                return NS.db.healer.groupOnly
              end,
              set = function(_, val)
                NS.db.healer.groupOnly = val
                NS.OnDbChanged()
              end,
            },
            instanceOnly = {
              name = "Show Only in Instances",
              type = "toggle",
              order = 9,
              width = 1.1,
              disabled = function(_)
                return not NS.db.healer.enabled
              end,
              get = function(_)
                return NS.db.healer.instanceOnly
              end,
              set = function(_, val)
                NS.db.healer.instanceOnly = val
                NS.OnDbChanged()
              end,
            },
            spacer4 = {
              name = "",
              type = "description",
              order = 10,
              width = "full",
            },
            position = {
              name = "Position",
              type = "select",
              order = 11,
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
              order = 12,
              width = 0.1,
            },
            attachToHealthBar = {
              name = "Attach directly to the healthbar",
              type = "toggle",
              order = 13,
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
              order = 14,
              width = "full",
            },
            scale = {
              name = "Scale",
              type = "range",
              width = 1.75,
              order = 15,
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
            spacer7 = {
              name = " ",
              type = "description",
              order = 16,
              width = "full",
            },
            iconDesc = {
              name = "Icon:",
              type = "description",
              order = 17,
              width = "full",
            },
            iconImage = {
              order = 18,
              type = "description",
              name = " ",
              image = function(info)
                return "roleicon-tiny-healerxatlas"
              end,
              imageHeight = 42,
              imageWidth = 42,
            },
          },
        },
        npc = {
          name = "NPC",
          type = "group",
          order = 3,
          args = {
            spacer1 = {
              name = "",
              type = "description",
              order = 1,
              width = "full",
            },
            desc = {
              name = 'The list of NPCs these settings affect can be found in the "NPC List" tab at the top.',
              fontSize = "medium",
              type = "description",
              order = 2,
              width = "full",
            },
            spacer2 = {
              name = "",
              type = "description",
              order = 3,
              width = "full",
            },
            enable = {
              name = "Enable",
              type = "toggle",
              order = 4,
              width = 0.4,
              get = function(_)
                return NS.db.npc.enabled
              end,
              set = function(_, val)
                NS.db.npc.enabled = val
                NS.OnDbChanged()
              end,
            },
            spacer3 = {
              name = "",
              type = "description",
              order = 5,
              width = 0.1,
            },
            test = {
              name = "Test Mode",
              type = "toggle",
              order = 6,
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
            spacer4 = {
              name = "",
              type = "description",
              order = 7,
              width = "full",
            },
            showFriendly = {
              name = "Show Friendly",
              type = "toggle",
              order = 8,
              width = 1.1,
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
              name = "Show Enemy",
              type = "toggle",
              order = 9,
              width = 1.1,
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
            spacer5 = {
              name = "",
              type = "description",
              order = 10,
              width = "full",
            },
            groupOnly = {
              name = "Show Only in Groups",
              type = "toggle",
              order = 11,
              width = 1.1,
              disabled = function(_)
                return not NS.db.npc.enabled
              end,
              get = function(_)
                return NS.db.npc.groupOnly
              end,
              set = function(_, val)
                NS.db.npc.groupOnly = val
                NS.OnDbChanged()
              end,
            },
            instanceOnly = {
              name = "Show Only in Instances",
              type = "toggle",
              order = 12,
              width = 1.1,
              disabled = function(_)
                return not NS.db.npc.enabled
              end,
              get = function(_)
                return NS.db.npc.instanceOnly
              end,
              set = function(_, val)
                NS.db.npc.instanceOnly = val
                NS.OnDbChanged()
              end,
            },
            spacer6 = {
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
            spacer7 = {
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
            spacer8 = {
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
            spacer9 = {
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
            spacer10 = {
              name = " ",
              type = "description",
              order = 22,
              width = "full",
            },
            desc2 = {
              name = "The following setting only works properly when the npcs nameplate is in view when cast.",
              fontSize = "small",
              type = "description",
              order = 23,
              width = 2.0,
            },
            spacer11 = {
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
                ["TOP"] = "Top",
                ["RIGHT"] = "Right",
              },
              sorting = {
                "LEFT",
                "TOP",
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
              order = 15,
              type = "description",
              name = " ",
              image = function(info)
                return "Crosshair_Quest_48xatlas"
              end,
              imageHeight = 42,
              imageWidth = 42,
            },
          },
        },
      },
    },
    npcs = {
      name = "NPC List",
      type = "group",
      childGroups = "tree",
      order = 3,
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
      type = "group",
      name = "Profiles",
      desc = "Manage Profiles",
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
          width = "default",
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
  },
}
NS.AceConfig = AceConfig

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
          return NS.db[info[1]][info[2]][info[3]]
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
          return NS.db[info[1]][info[2]][info[3]]
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
          return NS.db[info[1]][info[2]][info[3]]
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
          return NS.db[info[1]][info[2]][info[3]]
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
          return NS.db[info[1]][info[2]][info[3]][1],
            NS.db[info[1]][info[2]][info[3]][2],
            NS.db[info[1]][info[2]][info[3]][3],
            NS.db[info[1]][info[2]][info[3]][4]
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
  local buildList = {}
  for npcId, npcInfo in pairs(NS.db.npcs) do
    local npc = {
      [npcId] = npcInfo,
    }
    tinsert(buildList, npc)
  end
  tsort(buildList, NS.SortListByName)
  for i = 1, #buildList do
    local spell = buildList[i]
    if spell then
      local spellId, spellInfo = next(spell)
      NS.MakeOption(spellId, spellInfo, i)
    end
  end
end
