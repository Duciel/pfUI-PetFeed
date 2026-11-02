-- pfUI-PetFeed: shows a button while your pet is not fully happy (fed).
-- Clicking it feeds the pet with matching food from your bags.

pfUI:RegisterModule("petfeed", "vanilla", function()
  local MAX_HAPPINESS = 3
  local FEED_ICON = "Interface\\Icons\\Ability_Hunter_BeastTraining"

  -- localized GetPetFoodTypes() names -> internal diet keys
  local diets = {
    -- enUS
    ["Meat"] = "meat", ["Fish"] = "fish", ["Bread"] = "bread",
    ["Cheese"] = "cheese", ["Fruit"] = "fruit", ["Fungus"] = "fungus",
    -- frFR
    ["Viande"] = "meat", ["Poisson"] = "fish", ["Pain"] = "bread",
    ["Fromage"] = "cheese", ["Champignon"] = "fungus",
    -- deDE
    ["Fleisch"] = "meat", ["Fisch"] = "fish", ["Brot"] = "bread",
    ["Käse"] = "cheese", ["Obst"] = "fruit", ["Pilz"] = "fungus",
  }

  local happiness = { "|cffff3333Unhappy|r", "|cffffff33Content|r", "|cff33ff33Happy|r" }
  local colors = { { 1, .3, .3 }, { 1, 1, .3 } }

  local function PetIsEating()
    for i = 1, 16 do
      local texture = UnitBuff("pet", i)
      if not texture then return false end
      if texture == FEED_ICON then return true end
    end
    return false
  end

  -- returns bag, slot, link of the best matching food (plain food before buff food)
  local function FindFood()
    local wanted = {}
    local types = { GetPetFoodTypes() }
    for _, name in pairs(types) do
      local key = diets[name] or string.lower(name)
      if pfPetFeedFoods[key] then wanted[key] = true end
    end

    local best, bestScore
    for bag = 0, 4 do
      for slot = 1, GetContainerNumSlots(bag) do
        local link = GetContainerItemLink(bag, slot)
        if link then
          local _, _, id = string.find(link, "item:(%d+)")
          id = tonumber(id)
          if id then
            for key in pairs(wanted) do
              if pfPetFeedFoods[key][id] then
                local _, count = GetContainerItemInfo(bag, slot)
                -- avoid "well fed" foods, then prefer the smallest stack
                local score = (pfPetFeedFoods.bonus[id] and 1000 or 0) + (count or 1)
                if not bestScore or score < bestScore then
                  best, bestScore = { bag, slot, link }, score
                end
                break
              end
            end
          end
        end
      end
    end

    if best then return best[1], best[2], best[3] end
  end

  local button = CreateFrame("Button", "pfPetFeedButton", UIParent)
  button:SetWidth(36)
  button:SetHeight(36)
  button:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
  button:SetFrameStrata("MEDIUM")
  button:RegisterForClicks("LeftButtonUp")
  CreateBackdrop(button)
  UpdateMovable(button)

  button.icon = button:CreateTexture(nil, "ARTWORK")
  button.icon:SetTexture(FEED_ICON)
  button.icon:SetTexCoord(.08, .92, .08, .92)
  button.icon:SetAllPoints(button)

  button.text = button:CreateFontString(nil, "OVERLAY")
  button.text:SetFont(pfUI.font_default, (C.global.font_size or 12) + 2, "OUTLINE")
  button.text:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 2)

  button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
  button:GetHighlightTexture():SetBlendMode("ADD")
  button:Hide()

  local function Update()
    -- keep the button visible while pfUI's unlock mode is active
    if pfUI.unlock and pfUI.unlock:IsShown() then
      button:Show()
      return
    end

    local level = UnitExists("pet") and not UnitIsDead("pet") and GetPetHappiness()
    if not level or level >= MAX_HAPPINESS or PetIsEating() then
      button:Hide()
      return
    end

    local bag, slot, link = FindFood()
    if not bag then
      button:Hide()
      return
    end

    button.bag, button.slot, button.link = bag, slot, link
    -- tint the button by mood: red = unhappy, yellow = content
    button.text:SetText("")
    if button.backdrop and colors[level] then
      button.backdrop:SetBackdropBorderColor(colors[level][1], colors[level][2], colors[level][3], 1)
    end
    button:Show()
  end

  button:SetScript("OnClick", function()
    if not this.bag or CursorHasItem() then return end
    if UnitAffectingCombat("pet") then
      UIErrorsFrame:AddMessage("Your pet is in combat.", 1, .3, .3)
      return
    end

    -- picking food up and dropping it on the pet feeds it (Feed Pet must be trained)
    PickupContainerItem(this.bag, this.slot)
    if CursorHasItem() then DropItemOnUnit("pet") end
    -- put the item back if the pet refused it
    if CursorHasItem() then PickupContainerItem(this.bag, this.slot) end
  end)

  button:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:AddLine("Feed Pet")
    GameTooltip:AddLine(GetPetLoyalty() or "", 1, 1, 1)
    local h = GetPetHappiness()
    if h and happiness[h] then GameTooltip:AddLine(happiness[h]) end
    if this.link then GameTooltip:AddLine("Click to feed: " .. this.link, 1, 1, 1) end
    GameTooltip:Show()
  end)

  button:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  local events = CreateFrame("Frame")
  events:RegisterEvent("PLAYER_ENTERING_WORLD")
  events:RegisterEvent("UNIT_PET")
  events:RegisterEvent("UNIT_HAPPINESS")
  events:RegisterEvent("UNIT_AURA")
  events:RegisterEvent("PET_UI_UPDATE")
  events:RegisterEvent("BAG_UPDATE")
  events:SetScript("OnEvent", function()
    if (event == "UNIT_AURA" or event == "UNIT_HAPPINESS") and arg1 ~= "pet" then return end
    Update()
  end)

  -- safety net in case an event is missed, re-check every few seconds
  local elapsed = 0
  events:SetScript("OnUpdate", function()
    elapsed = elapsed + arg1
    if elapsed < 3 then return end
    elapsed = 0
    Update()
  end)
end)
