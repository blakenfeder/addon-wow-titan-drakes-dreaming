--[[
  TitanDrakesDreamingCrest: A simple Display of current Drakes's Dreaming Crest value
  Author: Blakenfeder
--]]

-- Define addon base object
local TitanDrakesDreamingCrest = {
  Const = {
    Id = "DrakesDreamingCrest",
    Name = "TitanDrakesDreamingCrest",
    DisplayName = "Titan Panel [Drakes's Dreaming Crest]",
    Version = "",
    Author = "",
  },
  CurrencyConst = {
    Id = 2707,
    Icon = "Interface\\Icons\\inv_10_gearupgrade_drakesdreamingcrest",
    Name = "",
    Description = "",
    Color = "|cffffffff",
  },
  IsInitialized = false,
}
function TitanDrakesDreamingCrest.GetCurrencyInfo()
  return C_CurrencyInfo.GetCurrencyInfo(TitanDrakesDreamingCrest.CurrencyConst.Id)
end
function TitanDrakesDreamingCrest.InitCurrencyConst()
  local info = TitanDrakesDreamingCrest.GetCurrencyInfo()
  if (info) then
    TitanDrakesDreamingCrest.CurrencyConst.Name = info.name
    TitanDrakesDreamingCrest.CurrencyConst.Description = info.description
    
    local r, g, b, hex = GetItemQualityColor(info.quality)
    if (hex) then
      TitanDrakesDreamingCrest.CurrencyConst.Color = '|c' .. hex
    end
  end
end
function TitanDrakesDreamingCrest.Util_GetFormattedNumber(number)
  if number >= 1000 then
    return string.format("%d,%03d", number / 1000, number % 1000)
  else
    return string.format ("%d", number)
  end
end
function TitanDrakesDreamingCrest.Util_WrapSingleLineOfText(text, lineLength)
  local wrappedText = ""
  local currentLine = ""
  for word in string.gmatch(text, "[^%s]+") do
      if string.len(currentLine) + string.len(word) > lineLength then
          wrappedText = wrappedText .. currentLine .. "\n"
          currentLine = word .. " "
      else
          currentLine = currentLine .. word .. " "
      end
  end
  wrappedText = wrappedText .. currentLine

  -- Return trimmed wrapped text
  return wrappedText:match("^%s*(.-)%s*$")
end
function TitanDrakesDreamingCrest.Util_WrapText(text, lineLength)
  -- Variable to be returned
  local wrappedText = ""

  -- Wrap the text for each individual paragraph
  for paragraph in text:gmatch("[^\n]+") do
    wrappedText = wrappedText .. "\n" .. TitanDrakesDreamingCrest.Util_WrapSingleLineOfText(paragraph, lineLength)
  end

  -- Return trimmed wrapped text
  return wrappedText:match("^%s*(.-)%s*$")
end

-- Load metadata
TitanDrakesDreamingCrest.Const.Version = GetAddOnMetadata(TitanDrakesDreamingCrest.Const.Name, "Version")
TitanDrakesDreamingCrest.Const.Author = GetAddOnMetadata(TitanDrakesDreamingCrest.Const.Name, "Author")

-- Text colors (AARRGGBB)
local BKFD_C_BURGUNDY = "|cff993300"
local BKFD_C_GRAY = "|cff999999"
local BKFD_C_GREEN = "|cff00ff00"
local BKFD_C_ORANGE = "|cffff8000"
local BKFD_C_RED = "|cffff0000"
local BKFD_C_WHITE = "|cffffffff"
local BKFD_C_YELLOW = "|cffffcc00"

-- Load Library references
local LT = LibStub("AceLocale-3.0"):GetLocale("Titan", true)
local L = LibStub("AceLocale-3.0"):GetLocale(TitanDrakesDreamingCrest.Const.Id, true)

-- Currency update variables
local updateFrequency = 0.0
local currencyCount = 0.0
local currencyMaximum
local wasMaximumReached = false
local seasonalCount = 0.0
local isSeasonal = false
local currencyDiscovered = false

function TitanPanelDrakesDreamingCrestButton_OnLoad(self)
  TitanDrakesDreamingCrest.InitCurrencyConst()

  self.registry = {
    id = TitanDrakesDreamingCrest.Const.Id,
    category = "Information",
    version = TitanDrakesDreamingCrest.Const.Version,
    menuText = TitanDrakesDreamingCrest.CurrencyConst.Name,
    buttonTextFunction = "TitanPanelDrakesDreamingCrestButton_GetButtonText",
    tooltipTitle = TitanDrakesDreamingCrest.CurrencyConst.Color .. TitanDrakesDreamingCrest.CurrencyConst.Name,
    tooltipTextFunction = "TitanPanelDrakesDreamingCrestButton_GetTooltipText",
    icon = TitanDrakesDreamingCrest.CurrencyConst.Icon,
    iconWidth = 16,
    controlVariables = {
      ShowIcon = true,
      ShowLabelText = true,
    },
    savedVariables = {
      ShowIcon = 1,
      ShowLabelText = false,
      ShowColoredText = false,
    },
  };


  self:RegisterEvent("PLAYER_ENTERING_WORLD");
  self:RegisterEvent("PLAYER_LOGOUT");
end

function TitanPanelDrakesDreamingCrestButton_GetButtonText(id)
  local currencyCountText
  if not currencyCount then
    currencyCountText = "0"
  else  
    currencyCountText = TitanDrakesDreamingCrest.Util_GetFormattedNumber(currencyCount)
  end

  if (wasMaximumReached) then
    currencyCountText = BKFD_C_RED .. currencyCountText
  end

  return TitanDrakesDreamingCrest.CurrencyConst.Name .. ": ", TitanUtils_GetHighlightText(currencyCountText)
end

function TitanPanelDrakesDreamingCrestButton_GetTooltipText()
  local currencyDescription = TitanDrakesDreamingCrest.Util_WrapText(TitanDrakesDreamingCrest.CurrencyConst.Description, 36)


  if (not currencyDiscovered) then
    return
      currencyDescription .. "\r" ..
      " \r" ..
      TitanUtils_GetHighlightText(L["BKFD_TITAN_TOOLTIP_NOT_YET_DISCOVERED"])
  end

  -- Set which total value will be displayed
  local tooltipCurrencyCount = currencyCount
  local tooltipCurrencyCurrentCount = 0
  if (isSeasonal) then
    tooltipCurrencyCurrentCount = tooltipCurrencyCount
    tooltipCurrencyCount = seasonalCount
  end

  -- Set how the total value will be displayed
  local totalValue = string.format(
    "%s/%s",
    TitanDrakesDreamingCrest.Util_GetFormattedNumber(tooltipCurrencyCount),
    TitanDrakesDreamingCrest.Util_GetFormattedNumber(currencyMaximum)
  )
  if (not currencyMaximum or currencyMaximum == 0) then
    totalValue = string.format(
      "%s",
      TitanDrakesDreamingCrest.Util_GetFormattedNumber(tooltipCurrencyCount)
    )
  elseif (wasMaximumReached) then
    totalValue = BKFD_C_RED .. totalValue
  end
  local seasonCurrentValue = TitanDrakesDreamingCrest.Util_GetFormattedNumber(tooltipCurrencyCurrentCount)
  
  local totalLabel = L["BKFD_TITAN_TOOLTIP_COUNT_LABEL_TOTAL_MAXIMUM"]
  if (isSeasonal) then
    totalLabel = L["BKFD_TITAN_TOOLTIP_COUNT_LABEL_TOTAL_SEASONAL"]
  elseif (not currencyMaximum or currencyMaximum == 0) then
    totalLabel = L["BKFD_TITAN_TOOLTIP_COUNT_LABEL_TOTAL"]
  end

  if (isSeasonal and currencyMaximum and currencyMaximum > 0) then
    return
      currencyDescription .. "\r" ..
      " \r" ..
      L["BKFD_TITAN_TOOLTIP_COUNT_LABEL_TOTAL"]..TitanUtils_GetHighlightText(seasonCurrentValue) .. "\r" ..
      L["BKFD_TITAN_TOOLTIP_COUNT_LABEL_TOTAL_SEASONAL_MAXIMUM"] .. TitanUtils_GetHighlightText(totalValue)
  else
    return
      currencyDescription .. "\r" ..
      " \r" ..
      totalLabel .. TitanUtils_GetHighlightText(totalValue)
  end
end

function TitanPanelDrakesDreamingCrestButton_OnUpdate(self, elapsed)
  updateFrequency = updateFrequency - elapsed;

  if updateFrequency <= 0 then
    updateFrequency = 1;

    local info = TitanDrakesDreamingCrest.GetCurrencyInfo(TitanDrakesDreamingCrest.CurrencyConst.Id)
    if (info) then
      currencyDiscovered = info.discovered
      currencyCount = tonumber(info.quantity)
      currencyMaximum = tonumber(info.maxQuantity)
      seasonalCount = tonumber(info.totalEarned)
      isSeasonal = info.useTotalEarnedForMaxQty

      wasMaximumReached =
          currencyMaximum and not(currencyMaximum == 0)
          and isSeasonal and seasonalCount
          and seasonalCount >= currencyMaximum
        or
          currencyMaximum and not(currencyMaximum == 0)
          and not isSeasonal and currencyCount
          and currencyCount >= currencyMaximum
    end

    TitanPanelButton_UpdateButton(TitanDrakesDreamingCrest.Const.Id)
  end
end

function TitanPanelDrakesDreamingCrestButton_OnEvent(self, event, ...)
  if (event == "PLAYER_ENTERING_WORLD") then
    if (not TitanDrakesDreamingCrest.IsInitialized and DEFAULT_CHAT_FRAME) then
      DEFAULT_CHAT_FRAME:AddMessage(
        BKFD_C_YELLOW .. TitanDrakesDreamingCrest.Const.DisplayName .. " " ..
        BKFD_C_GREEN .. TitanDrakesDreamingCrest.Const.Version ..
        BKFD_C_YELLOW .. " by "..
        BKFD_C_ORANGE .. TitanDrakesDreamingCrest.Const.Author)
      TitanPanelButton_UpdateButton(TitanDrakesDreamingCrest.Const.Id)
      TitanDrakesDreamingCrest.IsInitialized = true
    end
    return;
  end  
  if (event == "PLAYER_LOGOUT") then
    TitanDrakesDreamingCrest.IsInitialized = false;
    return;
  end
end

function TitanPanelRightClickMenu_PrepareDrakesDreamingCrestMenu()
  local id = TitanDrakesDreamingCrest.Const.Id;

  TitanPanelRightClickMenu_AddTitle(TitanPlugins[id].menuText)
  
  TitanPanelRightClickMenu_AddToggleIcon(id)
  TitanPanelRightClickMenu_AddToggleLabelText(id)
  TitanPanelRightClickMenu_AddSpacer()
  TitanPanelRightClickMenu_AddCommand(LT["TITAN_PANEL_MENU_HIDE"], id, TITAN_PANEL_MENU_FUNC_HIDE)
end