local cavebotMacro = nil
local config = nil

-- ui (always parent to Cave; async load can leave context.panel on Main)
local cavePanel = addTab("Cave")
setDefaultTab("Cave")
local configWidget = UI.Config(cavePanel)
local ui = UI.createWidget("CaveBotPanel", cavePanel)
if not ui or not ui.listPanel then
  error("CaveBotPanel UI failed to load. Check /cavebot/cavebot.otui was imported.")
end

local cavebotPositionLabel = setupUI([[
Label
  height: 18
  text: Pos: -
  color: #FFFF00
  font: verdana-11px-rounded
]])
cavebotPositionLabel:setParent(g_ui.getRootWidget())
cavebotPositionLabel:setPosition({x = 12, y = 42})
local lastMarkedTile = nil
local lastMarkedPos = nil
local markedAllPositions = {}

local function clearGotoMarker()
  if lastMarkedTile then
    pcall(function() lastMarkedTile:setText("") end)
    lastMarkedTile = nil
  end
  if CaveBot.gotoMarkerTile then
    pcall(function() CaveBot.gotoMarkerTile:setText("") end)
    CaveBot.gotoMarkerTile = nil
  end
  lastMarkedPos = nil
end

local function clearAllMarkers()
  for _, pos in pairs(markedAllPositions) do
    local tile = g_map.getTile(pos)
    if tile then
      pcall(function() tile:setText("") end)
    end
  end
  markedAllPositions = {}
  clearGotoMarker()
end

local function parseGotoPos(val)
  if not val or type(val) ~= "string" then return nil end
  local parts = string.split(val, ",")
  if parts and #parts >= 3 then
    local x = tonumber(parts[1]:trim())
    local y = tonumber(parts[2]:trim())
    local z = tonumber(parts[3]:trim())
    if x and y and z then
      return {x = x, y = y, z = z}
    end
  end
  local x, y, z = string.match(val, "%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
  if x and y and z then
    return {x = tonumber(x), y = tonumber(y), z = tonumber(z)}
  end
  return nil
end

local function getActionDisplayId(actionWidget)
  if not actionWidget then return 1 end
  if actionWidget.actionId then
    return actionWidget.actionId
  end
  local text = actionWidget:getText() or ""
  local idFromText = string.match(text, "^(%d+)%.")
  if idFromText then
    return tonumber(idFromText)
  end
  if ui and ui.list then
    return ui.list:getChildIndex(actionWidget) + 1
  end
  return 1
end

local function updateGotoMarker()
  if not g_game.isOnline() then
    clearAllMarkers()
    return
  end
  if not ui or not ui.list then return end

  local hudState = storage._cavebotHudState or 0

  -- State 0: OFF / Hidden
  if hudState == 0 then
    clearAllMarkers()
    if cavebotPositionLabel and cavebotPositionLabel:isVisible() then
      cavebotPositionLabel:hide()
    end
    return
  end

  -- States 1 and 2: HUD is visible
  if cavebotPositionLabel and not cavebotPositionLabel:isVisible() then
    cavebotPositionLabel:show()
  end

  local currentAction = ui.list:getFocusedChild()
  if not currentAction then
    currentAction = ui.list:getFirstChild()
  end

  if currentAction then
    local currentId = getActionDisplayId(currentAction)
    local actionText = currentAction:getText() or ""
    cavebotPositionLabel:setText("Pos: " .. currentId .. " | " .. actionText)
  else
    cavebotPositionLabel:setText("Pos: -")
  end

  local playerPos = player and player:getPosition()

  -- State 2: Show ALL waypoints on current floor
  if hudState == 2 then
    if lastMarkedTile or lastMarkedPos then
      clearGotoMarker()
    end
    local currentPositions = {}
    for _, child in ipairs(ui.list:getChildren()) do
      if child.action == "goto" then
        local targetPos = parseGotoPos(child.value)
        if targetPos and (not playerPos or playerPos.z == targetPos.z) then
          local key = targetPos.x .. "," .. targetPos.y .. "," .. targetPos.z
          currentPositions[key] = targetPos
          local tile = g_map.getTile(targetPos)
          if tile then
            local currentId = getActionDisplayId(child)
            local markerText = "@ POS: " .. currentId .. " (" .. targetPos.x .. ", " .. targetPos.y .. ", " .. targetPos.z .. ")"
            tile:setText(markerText, "#00FF00")
          end
        end
      end
    end

    for oldKey, oldPos in pairs(markedAllPositions) do
      if not currentPositions[oldKey] then
        local oldTile = g_map.getTile(oldPos)
        if oldTile then
          pcall(function() oldTile:setText("") end)
        end
      end
    end
    markedAllPositions = currentPositions
    return
  end

  -- State 1: Show only SELECTED waypoint
  for oldKey, oldPos in pairs(markedAllPositions) do
    local oldTile = g_map.getTile(oldPos)
    if oldTile then
      pcall(function() oldTile:setText("") end)
    end
  end
  markedAllPositions = {}

  if not currentAction or currentAction.action ~= "goto" then
    clearGotoMarker()
    return
  end

  local targetPos = parseGotoPos(currentAction.value)
  if not targetPos then
    clearGotoMarker()
    return
  end

  local currentId = getActionDisplayId(currentAction)

  if lastMarkedPos and (lastMarkedPos.x ~= targetPos.x or lastMarkedPos.y ~= targetPos.y or lastMarkedPos.z ~= targetPos.z) then
    clearGotoMarker()
  end

  if playerPos and playerPos.z ~= targetPos.z then
    clearGotoMarker()
    lastMarkedPos = targetPos
    return
  end

  local tile = g_map.getTile(targetPos)
  if tile then
    local markerText = "@ POS: " .. currentId .. " (" .. targetPos.x .. ", " .. targetPos.y .. ", " .. targetPos.z .. ")"
    tile:setText(markerText, "#00FF00")
    lastMarkedTile = tile
    CaveBot.gotoMarkerTile = tile
    lastMarkedPos = targetPos
  end
end

CaveBot.updateGotoMarker = updateGotoMarker
CaveBot.clearGotoMarker = clearGotoMarker
CaveBot.clearAllMarkers = clearAllMarkers

ui.list = ui.listPanel.list -- shortcut
CaveBot.actionList = ui.list

ui.list.onChildFocusChange = function(widget, newChild, oldChild)
  if (storage._cavebotHudState or 0) == 1 then
    clearGotoMarker()
  end
  updateGotoMarker()
end

-- Macro to keep marking the selected waypoint and updating HUD even when CaveBot is off
macro(100, function()
  updateGotoMarker()
end)

if CaveBot.Editor then
  CaveBot.Editor.setup()
end
if CaveBot.Config then
  CaveBot.Config.setup()
end
for extension, callbacks in pairs(CaveBot.Extensions) do
  if callbacks.setup then
    callbacks.setup()
  end
end

-- main loop, controlled by config
local actionRetries = 0
local prevActionResult = true
cavebotMacro = macro(20, function()
  if TargetBot and TargetBot.isActive() and not TargetBot.isCaveBotActionAllowed() then
    CaveBot.resetWalking()
    return -- target bot or looting is working, wait
  end

  if CaveBot.doWalking() then
    return -- executing walking3
  end

  local actions = ui.list:getChildCount()
  if actions == 0 then return end
  local currentAction = ui.list:getFocusedChild()
  if not currentAction then
    currentAction = ui.list:getFirstChild()
  end
  if currentAction then
    updateGotoMarker()
  else
    cavebotPositionLabel:setText("Pos: -")
    clearGotoMarker()
  end
  local action = CaveBot.Actions[currentAction.action]
  CaveBot.currentAction = currentAction
  local value = currentAction.value
  local retry = false
  if action then
    local status, result = pcall(function()
      CaveBot.resetWalking()
      return action.callback(value, actionRetries, prevActionResult)
    end)
    if status then
      if result == "retry" then
        actionRetries = actionRetries + 1
        retry = true
      elseif type(result) == 'boolean' then
        actionRetries = 0
        prevActionResult = result
      else
        warn("Invalid return from cavebot action (" .. currentAction.action .. "), should be \"retry\", false or true, is: " .. tostring(result))
      end
    else
      warn("warn while executing cavebot action (" .. currentAction.action .. "):\n" .. result)
    end
  else
    warn("Invalid cavebot action: " .. currentAction.action)
  end

  if retry then
    return
  end

  if currentAction ~= ui.list:getFocusedChild() then
    -- focused child can change durring action, get it again and reset state
    currentAction = ui.list:getFocusedChild() or ui.list:getFirstChild()
    actionRetries = 0
    prevActionResult = true
  end
  local nextAction = ui.list:getChildIndex(currentAction) + 1
  if nextAction > actions then
    nextAction = 1
  end
  ui.list:focusChild(ui.list:getChildByIndex(nextAction))
end)

-- config, its callback is called immediately, data can be nil
local lastConfig = ""
config = Config.setup("cavebot_configs", configWidget, "cfg", function(name, enabled, data)
  if enabled and CaveBot.Recorder.isOn() then
    CaveBot.Recorder.disable()
    CaveBot.setOff()
    return
  end

  local currentActionIndex = ui.list:getChildIndex(ui.list:getFocusedChild())
  ui.list:destroyChildren()
  clearAllMarkers()
  if not data then return cavebotMacro.setOff() end

  local cavebotConfig = nil
  for k,v in ipairs(data) do
    if type(v) == "table" and #v >= 2 then
      if v[1] == "config" then
        local status, result = pcall(function()
          return json.decode(v[2])
        end)
        if not status then
          warn("warn while parsing CaveBot extensions from config:\n" .. result)
        else
          cavebotConfig = result
        end
      elseif v[1] == "extensions" then
        local status, result = pcall(function()
          return json.decode(v[2])
        end)
        if not status then
          warn("warn while parsing CaveBot extensions from config:\n" .. result)
        else
          for extension, callbacks in pairs(CaveBot.Extensions) do
            if callbacks.onConfigChange then
              callbacks.onConfigChange(name, enabled, result[extension])
            end
          end
        end
      else
        CaveBot.addAction(v[1], v[2], false, v[3])
      end
    end
  end

  CaveBot.Config.onConfigChange(name, enabled, cavebotConfig)

  actionRetries = 0
  CaveBot.resetWalking()
  prevActionResult = true
  cavebotMacro.setOn(enabled)
  cavebotMacro.delay = nil
  if lastConfig == name then
    -- restore focused child on the action list
    ui.list:focusChild(ui.list:getChildByIndex(currentActionIndex))
  end
  lastConfig = name
end)

-- ui callbacks
ui.showEditor.onClick = function()
  if not CaveBot.Editor then return end
  if ui.showEditor:isOn() then
    CaveBot.Editor.hide()
    ui.showEditor:setOn(false)
  else
    CaveBot.Editor.show()
    ui.showEditor:setOn(true)
  end
end

ui.showConfig.onClick = function()
  if not CaveBot.Config then return end
  if ui.showConfig:isOn() then
    CaveBot.Config.hide()
    ui.showConfig:setOn(false)
  else
    CaveBot.Config.show()
    ui.showConfig:setOn(true)
  end
end

local function updateHudButtonText()
  if not ui or not ui.showHud then return end
  local state = storage._cavebotHudState or 1
  if state == 1 then
    ui.showHud:setText("Show HUD")
  elseif state == 2 then
    ui.showHud:setText("Show HUD (All)")
  else
    ui.showHud:setText("Hide HUD")
  end
end

if ui.showHud then
  if storage._cavebotHudState == nil then
    storage._cavebotHudState = 1
  end

  updateHudButtonText()

  if storage._cavebotHudState == 0 and cavebotPositionLabel then
    cavebotPositionLabel:hide()
  end

  ui.showHud.onClick = function()
    local currentState = storage._cavebotHudState or 1
    local nextState = 1
    if currentState == 1 then
      nextState = 2
    elseif currentState == 2 then
      nextState = 0
    else
      nextState = 1
    end
    storage._cavebotHudState = nextState
    updateHudButtonText()
    if nextState == 0 then
      clearAllMarkers()
      if cavebotPositionLabel then
        cavebotPositionLabel:hide()
      end
    else
      if cavebotPositionLabel then
        cavebotPositionLabel:show()
      end
      updateGotoMarker()
    end
  end
end

CaveBot.isHudOn = function()
  return (storage._cavebotHudState or 0) > 0
end

-- public function, you can use them in your scripts
CaveBot.isOn = function()
  return config.isOn()
end

CaveBot.isOff = function()
  return config.isOff()
end

CaveBot.setOn = function(val)
  if val == false then
    return CaveBot.setOff(true)
  end
  config.setOn()
end

CaveBot.setOff = function(val)
  if val == false then
    return CaveBot.setOn(true)
  end
  config.setOff()
  schedule(50, function()
    local selected = ui.list:getFocusedChild() or ui.list:getFirstChild()
    if selected then
      local gotoNumber = 0
      for _, child in ipairs(ui.list:getChildren()) do
        if child.action == "goto" then gotoNumber = gotoNumber + 1 end
        if child == selected then break end
      end
      updateGotoMarker(selected, gotoNumber)
    end
  end)
end

CaveBot.getCurrentProfile = function()
  return storage._configs.cavebot_configs.selected
end

CaveBot.lastReachedLabel = function()
  return vBot.lastLabel
end

CaveBot.gotoNextWaypointInRange = function()
  local currentAction = ui.list:getFocusedChild()
  local index = ui.list:getChildIndex(currentAction)
  local actions = ui.list:getChildren()

  local function parsePos(val)
    local re = regexMatch(val, [[([^,]+),([^,]+),([^,]+)]])
    if re and re[1] and re[1][2] and re[1][3] and re[1][4] then
      return {x = tonumber(re[1][2]), y = tonumber(re[1][3]), z = tonumber(re[1][4])}
    end
    return nil
  end

  -- start searching from current index
  for i, child in ipairs(actions) do
    if i > index then
      if child.action == "goto" then
        local pos = parsePos(child.value)
        if pos and posz() == pos.z then
          local maxDist = storage.extras.gotoMaxDistance
          if distanceFromPlayer(pos) <= maxDist then
            if findPath(player:getPosition(), pos, maxDist, { ignoreNonPathable = true }) then
              ui.list:focusChild(ui.list:getChildByIndex(i-1))
              return true
            end
          end
        end
      end
    end
  end

  -- if not found then damn go from start
  for i, child in ipairs(actions) do
    if i <= index then
      if child.action == "goto" then
        local pos = parsePos(child.value)
        if pos and posz() == pos.z then
          local maxDist = storage.extras.gotoMaxDistance
          if distanceFromPlayer(pos) <= maxDist then
            if findPath(player:getPosition(), pos, maxDist, { ignoreNonPathable = true }) then
              ui.list:focusChild(ui.list:getChildByIndex(i-1))
              return true
            end
          end
        end
      end
    end
  end

  -- not found
  return false
end

local function reverseTable(t, max)
  local reversedTable = {}
  local itemCount = max or #t
  for i, v in ipairs(t) do
      reversedTable[itemCount + 1 - i] = v
  end
  return reversedTable
end

function rpairs(t)
  test()
	return function(t, i)
		i = i - 1
		if i ~= 0 then
			return i, t[i]
		end
	end, t, #t + 1
end

CaveBot.gotoFirstPreviousReachableWaypoint = function()
  local currentAction = ui.list:getFocusedChild()
  local currentIndex = ui.list:getChildIndex(currentAction)
  local index = ui.list:getChildIndex(currentAction)

  local function parsePos(val)
    local re = regexMatch(val, [[([^,]+),([^,]+),([^,]+)]])
    if re and re[1] and re[1][2] and re[1][3] and re[1][4] then
      return {x = tonumber(re[1][2]), y = tonumber(re[1][3]), z = tonumber(re[1][4])}
    end
    return nil
  end

  -- check up to 100 childs
  for i=0,100 do
    index = index - i
    if index <= 0 or index > currentIndex or math.abs(index-currentIndex) > 100 then
      break
    end

    local child = ui.list:getChildByIndex(index)
    if child and child.action == "goto" then
      local pos = parsePos(child.value)
      if pos and posz() == pos.z then
        if distanceFromPlayer(pos) <= storage.extras.gotoMaxDistance/2 then
          print("found pos, going back "..currentIndex-index.. " waypoints.")
          return ui.list:focusChild(child)
        end
      end
    end
  end

  -- not found
  print("previous pos not found, proceeding")
  return false
end

CaveBot.getFirstWaypointBeforeLabel = function(label)
  label = label:lower()
  local actions = ui.list:getChildren()
  local index

  local function parsePos(val)
    local re = regexMatch(val, [[([^,]+),([^,]+),([^,]+)]])
    if re and re[1] and re[1][2] and re[1][3] and re[1][4] then
      return {x = tonumber(re[1][2]), y = tonumber(re[1][3]), z = tonumber(re[1][4])}
    end
    return nil
  end

  -- find index of label
  for i, child in pairs(actions) do
    if child.action == "label" and child.value:lower() == label then
      index = i
      break
    end
  end

  -- if there's no index then label was not found
  if not index then return false end

  for i=1,#actions do
    if index - 1 < 1 then
      -- did not found any waypoint in range before label
      return false
    end

    local child = ui.list:getChildByIndex(index-i)
    if child and child.action == "goto" then
      local pos = parsePos(child.value)
      if pos and posz() == pos.z then
        if distanceFromPlayer(pos) <= storage.extras.gotoMaxDistance/2 then
          return ui.list:focusChild(child)
        end
      end
    end
  end
end

CaveBot.getPreviousLabel = function()
  local actions = ui.list:getChildren()
  -- check if config is empty
  if #actions == 0 then return false end

  local currentAction = ui.list:getFocusedChild()
  --check we made any progress in waypoints, if no focused or first then no point checking
  if not currentAction or currentAction == ui.list:getFirstChild() then return false end

  local index = ui.list:getChildIndex(currentAction)

  -- if not index then something went wrong and there's no selected child
  if not index then return false end

  for i=1,#actions do
    if index - i < 1 then
      -- did not found any waypoint in range before label
      return false
    end

    local child = ui.list:getChildByIndex(index-i)
    if child then
      if child.action == "label" then
        return child.value
      end
    end
  end
end

CaveBot.getNextLabel = function()
  local actions = ui.list:getChildren()
  -- check if config is empty
  if #actions == 0 then return false end

  local currentAction = ui.list:getFocusedChild() or ui.list:getFirstChild()
  local index = ui.list:getChildIndex(currentAction)

  -- if not index then something went wrong
  if not index then return false end

  for i=1,#actions do
    if index + i > #actions then
      -- did not found any waypoint in range before label
      return false
    end

    local child = ui.list:getChildByIndex(index+i)
    if child then
      if child.action == "label" then
        return child.value
      end
    end
  end
end

local botConfigName = modules.game_bot.contentsPanel.config:getCurrentOption().text
CaveBot.setCurrentProfile = function(name)
  if not g_resources.fileExists("/bot/"..botConfigName.."/cavebot_configs/"..name..".cfg") then
    return warn("there is no cavebot profile with that name!")
  end
  CaveBot.setOff()
  storage._configs.cavebot_configs.selected = name
  CaveBot.setOn()
end

CaveBot.delay = function(value)
  cavebotMacro.delay = math.max(cavebotMacro.delay or 0, now + value)
end

CaveBot.gotoLabel = function(label)
  label = label:lower()
  for index, child in ipairs(ui.list:getChildren()) do
    if child.action == "label" and child.value:lower() == label then
      ui.list:focusChild(child)
      return true
    end
  end
  return false
end

CaveBot.save = function()
  local data = {}
  for index, child in ipairs(ui.list:getChildren()) do
    table.insert(data, {child.action, child.value, child.actionId})
  end

  if CaveBot.Config then
    table.insert(data, {"config", json.encode(CaveBot.Config.save())})
  end

  local extension_data = {}
  for extension, callbacks in pairs(CaveBot.Extensions) do
    if callbacks.onSave then
      local ext_data = callbacks.onSave()
      if type(ext_data) == "table" then
        extension_data[extension] = ext_data
      end
    end
  end
  table.insert(data, {"extensions", json.encode(extension_data, 2)})
  config.save(data)
end

CaveBotList = function()
  return ui.list
end
