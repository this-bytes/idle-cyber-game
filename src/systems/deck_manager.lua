-- Deck Manager System - Card-based deck building and hand management
-- Handles card collections, drawing, playing, and deck manipulation
-- Core system for roguelike card gameplay

local DeckManager = {}
DeckManager.__index = DeckManager

-- System metadata for automatic registration
DeckManager.metadata = {
    priority = 50,
    dependencies = {"DataManager"},
    systemName = "DeckManager"
}

-- Card types
local CARD_TYPES = {
    SPECIALIST = "specialist",
    TOOL = "tool",
    THREAT = "threat"
}

-- Card rarities
local CARD_RARITIES = {
    COMMON = "common",
    UNCOMMON = "uncommon",
    RARE = "rare",
    LEGENDARY = "legendary"
}

function DeckManager.new(eventBus, dataManager)
    local self = setmetatable({}, DeckManager)
    self.eventBus = eventBus
    self.dataManager = dataManager
    
    -- Card collections
    self.availableCards = {}        -- All unlocked cards
    self.currentDeck = {}           -- Selected deck for this run
    self.drawPile = {}              -- Cards to draw from
    self.hand = {}                  -- Current hand (max 5)
    self.discardPile = {}           -- Discarded cards
    self.exhaustPile = {}           -- Removed cards (don't shuffle back)
    
    -- Hand size
    self.maxHandSize = 5
    
    return self
end

function DeckManager:initialize()
    -- Load card definitions from data manager
    self:loadAvailableCards()
    
    -- Subscribe to deck events
    if self.eventBus then
        self.eventBus:subscribe("run_started", function()
            self:initializeStarterDeck()
        end)
        
        self.eventBus:subscribe("draw_cards", function(data)
            self:drawCards(data.count or 1)
        end)
    end
    
    print("🃏 DeckManager initialized")
end

-- Load available cards from data manager
function DeckManager:loadAvailableCards()
    self.availableCards = {}
    
    -- Create starter cards
    table.insert(self.availableCards, self:createCard("junior_analyst", CARD_TYPES.SPECIALIST, {
        name = "Junior Analyst",
        effect = "Deal 2 damage to target threat",
        damage = 2,
        cost = 0,
        rarity = CARD_RARITIES.COMMON
    }))
    
    table.insert(self.availableCards, self:createCard("firewall", CARD_TYPES.TOOL, {
        name = "Firewall",
        effect = "Block 3 damage from network threats",
        block = 3,
        cost = 0,
        rarity = CARD_RARITIES.COMMON
    }))
    
    table.insert(self.availableCards, self:createCard("senior_analyst", CARD_TYPES.SPECIALIST, {
        name = "Senior Analyst",
        effect = "Deal 4 damage to target threat",
        damage = 4,
        cost = 0,
        rarity = CARD_RARITIES.UNCOMMON
    }))
    
    table.insert(self.availableCards, self:createCard("threat_hunter", CARD_TYPES.SPECIALIST, {
        name = "Threat Hunter",
        effect = "Deal 3 damage to target and 1 to adjacent threats",
        damage = 3,
        splash = 1,
        cost = 0,
        rarity = CARD_RARITIES.UNCOMMON
    }))
    
    table.insert(self.availableCards, self:createCard("edr_platform", CARD_TYPES.TOOL, {
        name = "EDR Platform",
        effect = "Deal 2 damage to all threats",
        aoe = 2,
        cost = 0,
        rarity = CARD_RARITIES.RARE
    }))
    
    print(string.format("📚 Loaded %d available cards", #self.availableCards))
end

-- Create card object
function DeckManager:createCard(id, cardType, properties)
    return {
        id = id,
        type = cardType,
        name = properties.name or id,
        effect = properties.effect or "",
        damage = properties.damage or 0,
        block = properties.block or 0,
        splash = properties.splash or 0,
        aoe = properties.aoe or 0,
        cost = properties.cost or 0,
        rarity = properties.rarity or CARD_RARITIES.COMMON
    }
end

-- Initialize starter deck for a new run
function DeckManager:initializeStarterDeck()
    self.currentDeck = {}
    self.drawPile = {}
    self.hand = {}
    self.discardPile = {}
    self.exhaustPile = {}
    
    -- Starter deck: 3x Junior Analyst, 2x Firewall
    for i = 1, 3 do
        self:addCardToDeck("junior_analyst")
    end
    
    for i = 1, 2 do
        self:addCardToDeck("firewall")
    end
    
    -- Shuffle into draw pile
    self:shuffleDeck()
    
    -- Draw opening hand
    self:drawCards(5)
    
    print(string.format("🎴 Starter deck initialized: %d cards in draw pile", #self.drawPile))
end

-- Add card to current deck
function DeckManager:addCardToDeck(cardId)
    -- Find card in available cards
    local cardTemplate = nil
    for _, card in ipairs(self.availableCards) do
        if card.id == cardId then
            cardTemplate = card
            break
        end
    end
    
    if not cardTemplate then
        print(string.format("⚠️ Card not found: %s", cardId))
        return false
    end
    
    -- Create new instance (deep copy)
    local newCard = {}
    for k, v in pairs(cardTemplate) do
        newCard[k] = v
    end
    
    table.insert(self.currentDeck, newCard)
    table.insert(self.drawPile, newCard)
    
    return true
end

-- Shuffle discard pile back into draw pile
function DeckManager:shuffleDeck()
    -- Move all discard to draw pile
    for _, card in ipairs(self.discardPile) do
        table.insert(self.drawPile, card)
    end
    self.discardPile = {}
    
    -- Fisher-Yates shuffle
    for i = #self.drawPile, 2, -1 do
        local j = math.random(i)
        self.drawPile[i], self.drawPile[j] = self.drawPile[j], self.drawPile[i]
    end
    
    print(string.format("🔀 Deck shuffled: %d cards", #self.drawPile))
end

-- Draw cards from deck to hand
function DeckManager:drawCards(count)
    count = count or 1
    local drawnCards = {}
    
    for i = 1, count do
        -- Check if hand is full
        if #self.hand >= self.maxHandSize then
            print("✋ Hand is full!")
            break
        end
        
        -- Check if draw pile is empty
        if #self.drawPile == 0 then
            -- Shuffle discard pile back in
            if #self.discardPile > 0 then
                self:shuffleDeck()
            else
                print("📭 No more cards to draw!")
                break
            end
        end
        
        -- Draw card
        local card = table.remove(self.drawPile, 1)
        table.insert(self.hand, card)
        table.insert(drawnCards, card)
    end
    
    if #drawnCards > 0 then
        print(string.format("🎴 Drew %d card(s)", #drawnCards))
        
        if self.eventBus then
            self.eventBus:publish("cards_drawn", {
                cards = drawnCards,
                handSize = #self.hand
            })
        end
    end
    
    return drawnCards
end

-- Play card from hand
function DeckManager:playCard(handIndex, target)
    if handIndex < 1 or handIndex > #self.hand then
        print("⚠️ Invalid hand index")
        return nil
    end
    
    local card = self.hand[handIndex]
    
    -- Remove from hand
    table.remove(self.hand, handIndex)
    
    -- Add to discard pile (unless it exhausts)
    table.insert(self.discardPile, card)
    
    -- Resolve card effect
    local result = self:resolveCardEffect(card, target)
    
    print(string.format("🎯 Played: %s", card.name))
    
    if self.eventBus then
        self.eventBus:publish("card_played", {
            card = card,
            target = target,
            result = result
        })
    end
    
    return result
end

-- Resolve card effects
function DeckManager:resolveCardEffect(card, target)
    local result = {
        damage = 0,
        block = 0,
        targets = {}
    }
    
    -- Deal damage
    if card.damage > 0 and target then
        result.damage = card.damage
        table.insert(result.targets, target)
        
        -- Splash damage
        if card.splash > 0 then
            result.splash = card.splash
        end
    end
    
    -- AOE damage
    if card.aoe > 0 then
        result.aoe = card.aoe
        result.damage = card.aoe
    end
    
    -- Block
    if card.block > 0 then
        result.block = card.block
    end
    
    return result
end

-- Discard card from hand
function DeckManager:discardCard(handIndex)
    if handIndex < 1 or handIndex > #self.hand then
        print("⚠️ Invalid hand index")
        return false
    end
    
    local card = table.remove(self.hand, handIndex)
    table.insert(self.discardPile, card)
    
    print(string.format("🗑️ Discarded: %s", card.name))
    return true
end

-- Exhaust card (remove from run)
function DeckManager:exhaustCard(handIndex)
    if handIndex < 1 or handIndex > #self.hand then
        print("⚠️ Invalid hand index")
        return false
    end
    
    local card = table.remove(self.hand, handIndex)
    table.insert(self.exhaustPile, card)
    
    print(string.format("💀 Exhausted: %s", card.name))
    return true
end

-- End turn: discard hand and draw new hand
function DeckManager:endTurn()
    -- Discard remaining hand
    for _, card in ipairs(self.hand) do
        table.insert(self.discardPile, card)
    end
    self.hand = {}
    
    -- Draw new hand
    self:drawCards(5)
end

-- Getters
function DeckManager:getHand()
    return self.hand
end

function DeckManager:getHandSize()
    return #self.hand
end

function DeckManager:getDeckSize()
    return #self.drawPile
end

function DeckManager:getDiscardSize()
    return #self.discardPile
end

function DeckManager:getCurrentDeck()
    return self.currentDeck
end

function DeckManager:getAvailableCards()
    return self.availableCards
end

-- State management for GameStateEngine
function DeckManager:getState()
    return {
        currentDeck = self.currentDeck,
        drawPile = self.drawPile,
        hand = self.hand,
        discardPile = self.discardPile,
        exhaustPile = self.exhaustPile
    }
end

function DeckManager:loadState(state)
    if not state then return end
    
    self.currentDeck = state.currentDeck or {}
    self.drawPile = state.drawPile or {}
    self.hand = state.hand or {}
    self.discardPile = state.discardPile or {}
    self.exhaustPile = state.exhaustPile or {}
end

return DeckManager
