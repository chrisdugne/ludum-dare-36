--------------------------------------------------------------------------------

Score = {}

--------------------------------------------------------------------------------

function Score:new()
    local object = {}
    setmetatable(object, { __index = Score })
    return object
end

--------------------------------------------------------------------------------
--- METRICS
--------------------------------------------------------------------------------

function Score:reset()
    self.current = {
        straight = 0,
        points = 0
    }

    self.enhancement = nil
    self.latest      = nil
end

function Score:worst()
    return {
        points = 0
    }
end

function Score:enhance(previousScore)
    self.merge = {
        points = math.max(self.current.points, previousScore.points)
    }

    self.enhancement = {
        points = self.current.points > previousScore.points
    }

    return self.merge
end

--------------------------------------------------------------------------------
--- MINI BAR
--------------------------------------------------------------------------------

function Score:createBar()
    if(self.bar) then
        display.remove(self.bar)
    end

    self.barHeight = display.contentHeight*0.07

    self.bar   = display.newGroup()
    self.bar.x = display.contentWidth*0.5
    self.bar.y = -self.barHeight*0.5
    self.bar.anchorX = 0

    App.hud:insert(self.bar)

    self.barBG = display.newRect(
        self.bar,
        0, 0,
        display.contentWidth,
        self.barHeight
    )

    self.barBG.alpha = 0
    self.barBG:setFillColor(0)

    self:displayTitle()
    self:refreshLevel()
    self:refreshPoints()
    self:resetStraight()
    self:showBar()
end

--------------------------------------------------------------------------------

function Score:displayButtons()
    local back = Button:icon({
        parent = self.bar,
        type   = 'close',
        x      = display.contentWidth*0.5 - 50,
        y      = 0,
        scale  = 0.7,
        action = function ()
            App.game:stop(true)
            Router:open(Router.HOME)
        end
    })
end

--------------------------------------------------------------------------------

function Score:displayTitle()
    if(not App.game.title) then return end

    local text = display.newText(
        self.bar,
        App.game.title,
        display.contentWidth*0.5 - 95, 0,
        FONT, 35
    )

    text.anchorX = 1
    text.alpha = 0

    transition.to(text, {
        alpha = 1,
        time  = 2000,
        delay = 4000
    })
end

--------------------------------------------------------------------------------

function Score:increment(bird)
    self.current.points = self.current.points + App.user.level
    self.current.straight = self.current.straight + 1
    self:refreshPoints()
    self:refreshStraight(bird)

    local level = App.game:currentLevel()
    local toReach = level and level.reach
    local reached = level and self.current.straight == toReach

    if(reached) then
        local newLevel = App.user:growLevel()
        self:resetStraight()
        self:refreshLevel()
        Sound:nextStep()
    end
end

--------------------------------------------------------------------------------
-- LEVEL
--------------------------------------------------------------------------------

function Score:refreshLevel()
     if(self.level) then
        display.remove(self.level)
    end

    self.level = utils.text({
        parent   = self.bar,
        value    = 'Level ' .. App.user.level,
        x        = display.contentWidth*0.5 - 395,
        y        = 0,
        font     = FONT,
        fontSize = 55
    })

    utils.grow(self.level)

    self.level.anchorX = 0
end

--------------------------------------------------------------------------------
-- POINTS
--------------------------------------------------------------------------------

function Score:refreshPoints()
    if(self.count) then
        display.remove(self.count)
    end

    self.count = utils.text({
        parent   = self.bar,
        value    = self.current.points,
        x        = 30 - display.contentWidth * 0.5,
        y        = 0,
        font     = FONT,
        fontSize = 55
    })

    utils.grow(self.count)

    self.count.anchorX = 0
end

--------------------------------------------------------------------------------
-- STRAIGHT
--------------------------------------------------------------------------------

function Score:birdPosition(i)
    local marginLeft = display.contentWidth * 0.085
    local gap = display.contentWidth * 0.03
    return i * gap + marginLeft
end

function Score:refreshStraight(bird)
    local itemX = self:birdPosition(self.current.straight) - display.contentWidth * 0.5
    local birdItem = display.newImage(
        self.straight,
        'assets/images/game/item/gem.png',
        itemX, 0
    );

    utils.grow(birdItem)
end

function Score:resetStraight()
    self.current.straight = 0
    utils.tprint(GLOBALS.levels)
    local level = GLOBALS.levels[App.user.level]
    local reach = level.reach

    utils.tprint(level)

    if(self.straight) then
        utils.destroyFromDisplay(self.straight)
    end

    self.straight = display.newGroup()
    self.bar:insert(self.straight)

    for i = 1, reach do
        local bird = display.newImage(
            self.straight,
            'assets/images/game/item/gem.png',
            self:birdPosition(i) - display.contentWidth * 0.5, 0
        );

        bird.fill.effect = 'filter.desaturate'
        bird.fill.effect.intensity = 0.65
    end

    utils.grow(self.straight)
end

--------------------------------------------------------------------------------

function Score:showBar()
    transition.to( self.bar, {
        time  = 800,
        y     = self.barHeight*0.5
    })

    transition.to( self.barBG, {
        time  = 800,
        alpha = 0.6
    })
end

function Score:hideBar()
    transition.to( self.bar, {
        time  = 800,
        alpha = 0
    })
end

--------------------------------------------------------------------------------

function Score:calculate(chapter, level)
end

--------------------------------------------------------------------------------
--- RESULT BOARD
--------------------------------------------------------------------------------

function Score:display()
    self:hideBar()

    local board = display.newGroup()
    board.x = display.contentWidth  * 0.5
    board.y = display.contentHeight * 0.5
    App.hud:insert(board)

    local bg = Panel:vertical({
        parent = board,
        width  = display.contentWidth * 0.4,
        height = display.contentHeight * 0.35,
        x      = 0,
        y      = 0
    })

    local title = 'Game Over'

    Banner:large({
        parent   = board,
        text     = title,
        fontSize = 44,
        width    = display.contentWidth*0.25,
        height   = display.contentHeight*0.13,
        x        = 0,
        y        = -bg.height*0.49
    })

    self:addBoardButtons(board)

    self.boardGems = {}
    for i = 1,3 do
        self.boardGems[i] = self:boardGem({
            parent = board,
            num    = i,
            caught = false
        })
    end

    if(self.current.points > 0) then
        self:bounceWonGem(board, 1)
    end

    utils.easeDisplay(board)
end

function Score:bounceWonGem(board, num)
    timer.performWithDelay(350, function()
        local gem = self:boardGem({
            parent = board,
            num    = num,
            caught = true
        })

        self.boardGems[num].alpha = 0
        utils.easeDisplay(gem)
        if(self.current.gems > num) then
            self:bounceWonGem(board, num+1)
        end
    end)
end

function Score:boardGem(options)
    local board = options.parent
    local gem = display.newImage(
        board,
        'assets/images/gui/items/gem.icon.png'
    );

    local x,y,rotation,scale

    if(options.num == 1) then
        x        = -board.width*0.25
        y        = board.height*0.03
        rotation = -35

    elseif(options.num == 2) then
        x        = 0
        y        = - board.height*0.05
        rotation = 0

    elseif(options.num == 3) then
        x        = board.width*0.25
        y        = board.height*0.03
        rotation = 35

    end

    gem.rotation = rotation
    gem.x        = x
    gem.y        = y

    if(not options.caught) then
        gem.fill.effect = 'filter.desaturate'
        gem.fill.effect.intensity = 1
    else
        Sound:playFinalGem(options.num)
    end

    return gem
end

--------------------------------------------------------------------------------

function Score:addBoardButtons(board)
    Button:icon({
        parent = board,
        type   = 'restart',
        x      = -board.width * 0.25,
        y      = board.height * 0.45,
        bounce = true,
        action = function()
            App.game:stop(true)
            ---- analytics
            analytics.event('score-screen', 'restart')
            --------------
            Router:open(Router.PLAYGROUND)
        end
    })

    Button:icon({
        parent = board,
        type   = 'chapters',
        x      = 0,
        y      = board.height * 0.45,
        bounce = true,
        action = function()
            ---- analytics
            analytics.event('score-screen', 'level-selection')
            --------------
            Router:open(Router.LEVEL_SELECTION)
        end
    })

    Button:icon({
        parent = board,
        type   = 'play',
        x      = board.width * 0.25,
        y      = board.height * 0.45,
        bounce = true,
        action = function()
            if(User:justFinishedTutorial()) then
                ---- analytics
                analytics.event('score-screen', 'next', 'after-tutorial')
                --------------
                Router:open(Router.LEVEL_SELECTION)
            else
                Router:open(Router.HOME)
            end
        end
    })
end

--------------------------------------------------------------------------------

return Score
