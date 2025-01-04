local AddonName, NS = ...

---------------------------------------------------------------------------------------------------
-- Imported functions and constants
---------------------------------------------------------------------------------------------------

-- Lua APIs
local string, tonumber, pairs = string, tonumber, pairs

-- WoW APIs
local UnitName = UnitName
local UnitExists = UnitExists
local IsInRaid, IsInGroup, GetNumGroupMembers, GetNumSubgroupMembers =
  IsInRaid, IsInGroup, GetNumGroupMembers, GetNumSubgroupMembers
local wipe = wipe

local RequestLoadQuestByID = C_QuestLog.RequestLoadQuestByID
local GetQuestObjectives, GetQuestInfo = C_QuestLog.GetQuestObjectives, C_QuestLog.GetInfo
local GetLogIndexForQuestID, GetNumQuestLogEntries = C_QuestLog.GetLogIndexForQuestID, C_QuestLog.GetNumQuestLogEntries
local C_TooltipInfo_GetUnit = C_TooltipInfo and C_TooltipInfo.GetUnit

-- ThreatPlates APIs
local PlayerName = select(1, UnitName("player"))

---------------------------------------------------------------------------------------------------
-- Local variables
---------------------------------------------------------------------------------------------------
local QuestLogNotComplete = true
local UnitQuestLogChanged = false
local QuestByTitle, QuestByID, QuestsToUpdate = {}, {}, {}
local GroupMembers = {}

local Quest = {}
NS.Quest = Quest

local QuestFrame = CreateFrame("Frame", AddonName .. "QuestFrame")
QuestFrame:SetScript("OnEvent", function(_, event, ...)
  if Quest[event] then
    Quest[event](Quest, ...)
  end
end)
NS.Quest.frame = QuestFrame

-- Since patch 8.3, quest tooltips have a different format depending on the localization, it seems
-- at least for kill quests
-- In Shadowlands, it seems that the format is randomly changed, at least for German, so check for
-- everything as a backup
local QUEST_OBJECTIVE_PARSER_LEFT = function(text)
  local current, goal, objective_name = string.match(text, "^(%d+)/(%d+)( .*)$")

  if not objective_name then
    objective_name, current, goal = string.match(text, "^(.*: )(%d+)/(%d+)$")
  end

  return objective_name, current, goal
end

local QUEST_OBJECTIVE_PARSER_RIGHT = function(text)
  -- Quest objective: Versucht, zu kommunizieren: 0/1
  local objective_name, current, goal = string.match(text, "^(.*: )(%d+)/(%d+)$")

  if not objective_name then
    -- Quest objective: 0/1 Besucht die Halle der Kuriositäten
    current, goal, objective_name = string.match(text, "^(%d+)/(%d+)( .*)$")
  end

  return objective_name, current, goal
end

local STANDARD_QUEST_OBJECTIVE_PARSER = {
  -- x/y Objective
  enUS = QUEST_OBJECTIVE_PARSER_LEFT,
  -- enGB = enGB clients return enUS
  esMX = QUEST_OBJECTIVE_PARSER_LEFT,
  ptBR = QUEST_OBJECTIVE_PARSER_LEFT,
  itIT = QUEST_OBJECTIVE_PARSER_LEFT,
  koKR = QUEST_OBJECTIVE_PARSER_LEFT,
  zhTW = QUEST_OBJECTIVE_PARSER_LEFT,
  zhCN = QUEST_OBJECTIVE_PARSER_LEFT,

  -- Objective: x/y
  deDE = QUEST_OBJECTIVE_PARSER_RIGHT,
  frFR = QUEST_OBJECTIVE_PARSER_RIGHT,
  esES = QUEST_OBJECTIVE_PARSER_RIGHT,
  ruRU = QUEST_OBJECTIVE_PARSER_RIGHT,
}

local QuestObjectiveParser = STANDARD_QUEST_OBJECTIVE_PARSER[GetLocale()] or QUEST_OBJECTIVE_PARSER_LEFT

---------------------------------------------------------------------------------------------------
-- Quest Functions
---------------------------------------------------------------------------------------------------

NS.IsQuestUnit = function(unit)
  -- Tooltip data can be nil here as it seems - there was a bug with this when a player left a battleground
  local tooltip_data = C_TooltipInfo_GetUnit(unit)
  if not tooltip_data then
    return false
  end

  local quest_title
  local quest_progress_player = false

  for i = 3, #tooltip_data.lines do
    local line = tooltip_data.lines[i]

    local text = line.leftText
    local text_r, text_g, text_b = line.leftColor.r, line.leftColor.g, line.leftColor.b

    if text_r > 0.99 and text_g > 0.8 and text_b == 0 then
      -- A line with this color is either the quest title or a player name (if on a group quest, but always after the quest title)
      if text == PlayerName then
        quest_progress_player = true
      elseif not GroupMembers[text] then
        quest_progress_player = true
        quest_title = text
      else
        quest_progress_player = false
      end
    elseif quest_progress_player then
      local objective_name, current, goal
      local objective_type = "false"

      -- Check if area / progress quest
      if string.find(text, "%%") then
        objective_name, current, goal = string.match(text, "^(.*) %(?(%d+)%%%)?$")
        objective_type = "area"
      else
        -- Standard x/y /pe quest
        objective_name, current, goal = QuestObjectiveParser(text)
      end

      if objective_name then
        current = tonumber(current)

        if objective_type ~= "false" then
          goal = 100
        else
          goal = tonumber(goal)
        end

        -- Note: "progressbar" type quest (area quest) progress cannot get via the API, so for this tooltips
        -- must be used. That's also the reason why their progress is not cached.
        local quest = QuestByTitle[quest_title]
        local quest_objective
        if quest then
          quest_objective = quest.Objectives[objective_name]
        end

        -- A unit may be target of more than one quest, the quest indicator should be show if at least one quest is not completed.
        if current and goal then
          if current ~= goal then
            return true, 1, quest_objective or { numFulfilled = current, numRequired = goal, type = objective_type }
          end
        else
          -- Line after quest title with quest information, so we can stop here
          return false
        end
      end
    end
  end

  return false
end

NS.IsPlayerQuestUnit = function(unit)
  local show, questType = NS.IsQuestUnit(unit)
  return show and (questType == 1) -- don't show quest color for party members quest targets
end

local function CacheQuestObjectives(quest)
  quest.Objectives = quest.Objectives or {}

  local objectives = GetQuestObjectives(quest.questID)

  local objective
  for objIndex = 1, #objectives do
    objective = objectives[objIndex]

    -- Occasionally the game will return nil text, this happens when
    -- some world quests/bonus area quests finish (the objective no longer exists)
    -- Does not make sense to add "progressbar" type quests here as there progress is not
    -- updated via QUEST_WATCH_UPDATE
    if objective.text and objective.type ~= "progressbar" then
      local objective_name = string.gsub(objective.text, "(%d+)/(%d+)", "")
      -- Normally, the quest objective should come before the :, but while the QUEST_LOG_UPDATE events (after login/reload)

      -- It does seem that this is no longer necessary
      QuestLogNotComplete = QuestLogNotComplete or (objective_name == " : ")

      --only want to track quests in this format
      -- numRequired > 1 prevents quest like "...: 0/1" from being tracked - not sure why it was/is here
      if objective.numRequired and objective.numRequired >= 1 then
        quest.Objectives[objective_name] = objective
      end
    end
  end
end

local function CacheQuestByQuestLogIndex(questLogIndex, questId)
  if questLogIndex then
    local quest = GetQuestInfo(questLogIndex)
    if quest then
      -- Ignore certain quests that need not to be tracked
      -- quest_info.isOnMap => would need to scan quest log when entering new areas
      if quest.title and not quest.isHeader then
        QuestByID[quest.questID] = quest.title -- So it can be found by remove
        QuestByTitle[quest.title] = quest

        CacheQuestObjectives(quest)
      end
    else
      QuestByID[questId] = "UpdatePending"
    end
  end
end

local function CacheQuestByQuestID(questId)
  if questId then
    local questLogIndex = GetLogIndexForQuestID(questId)
    CacheQuestByQuestLogIndex(questLogIndex, questId)
  end
end

function Quest:GenerateQuestCache()
  QuestByTitle = {}
  QuestByID = {}

  for questLogIndex = 1, GetNumQuestLogEntries() do
    CacheQuestByQuestLogIndex(questLogIndex)
  end
end

---------------------------------------------------------------------------------------------------
-- Event Watcher Code for Quest Widget
---------------------------------------------------------------------------------------------------

function Quest:QUEST_ACCEPTED(questId)
  CacheQuestByQuestID(questId)
  if QuestByID[questId] == "UpdatePending" then
    RequestLoadQuestByID(questId)
  end
end

function Quest:QUEST_DATA_LOAD_RESULT(questID, success)
  if success and QuestByID[questID] == "UpdatePending" then
    CacheQuestByQuestID(questID)
  end
end

function Quest:QUEST_LOG_UPDATE()
  -- UnitQuestLogChanged being true means that UNIT_QUEST_LOG_CHANGED was fired (possibly several times)
  -- So there should be quest progress => update all plates with the current progress.
  if UnitQuestLogChanged then
    UnitQuestLogChanged = false

    -- Update the cached quest progress (for non-progressbar quests) after QUEST_WATCH_UPDATE
    for questID, title in pairs(QuestsToUpdate) do
      local quest = QuestByTitle[title]
      if quest then
        CacheQuestObjectives(quest)
      else
        -- For whatever reason it doesn't exist, so just add it
        CacheQuestByQuestID(questID)
      end

      QuestsToUpdate[questID] = nil
    end
  end

  -- It does seem that this is no longer necessary
  if QuestLogNotComplete then
    QuestLogNotComplete = false
    self:GenerateQuestCache()
  end
end

function Quest:QUEST_REMOVED(questID, _)
  -- Clean up cache
  local quest_title = QuestByID[questID]

  QuestByID[questID] = nil
  QuestsToUpdate[questID] = nil

  -- Plates only need to be updated if the quest was actually tracked
  if quest_title then
    QuestByTitle[quest_title] = nil
  end
end

function Quest:QUEST_WATCH_UPDATE(questID)
  local questLogIndex = GetLogIndexForQuestID(questID)
  if questLogIndex then
    local info = GetQuestInfo(questLogIndex)
    if info and info.title then
      QuestsToUpdate[questID] = info.title
    end
  end
end

function Quest:UNIT_QUEST_LOG_CHANGED(unitTarget)
  if unitTarget == "player" then
    UnitQuestLogChanged = true
  end
end

function Quest:GROUP_ROSTER_UPDATE()
  local group_size = (IsInRaid() and GetNumGroupMembers()) or (IsInGroup() and GetNumSubgroupMembers()) or 0

  wipe(GroupMembers)

  if group_size > 0 then
    local group_type = (IsInRaid() and "raid") or IsInGroup() and "party" or "solo"

    for i = 1, group_size do
      if UnitExists(group_type .. i) then
        GroupMembers[UnitName(group_type .. i)] = true
      end
    end
  end
end

function Quest:GROUP_LEFT()
  wipe(GroupMembers)
end

---------------------------------------------------------------------------------------------------
-- Widget functions for creation and update
---------------------------------------------------------------------------------------------------

function Quest:OnEnable()
  self:GenerateQuestCache()

  QuestFrame:RegisterEvent("QUEST_ACCEPTED")
  QuestFrame:RegisterEvent("QUEST_DATA_LOAD_RESULT")
  QuestFrame:RegisterEvent("QUEST_LOG_UPDATE")
  -- QUEST_REMOVED fires whenever the player turns in a quest, whether automatically with a Task-type quest
  -- (Bonus Objectives/World Quests), or by pressing the Complete button in a quest dialog window.
  -- also handles abandon quest
  QuestFrame:RegisterEvent("QUEST_REMOVED")
  QuestFrame:RegisterEvent("QUEST_WATCH_UPDATE")
  QuestFrame:RegisterUnitEvent("UNIT_QUEST_LOG_CHANGED", "player")

  -- To handle objectives correctly when quest objectives of group members are shown in the tooltip, we need to keep a
  -- list of all players in the group
  QuestFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
  QuestFrame:RegisterEvent("GROUP_LEFT")

  self:GROUP_ROSTER_UPDATE()
end
