
class('Coin').extends(playdate.graphics.sprite)

-- local references
local floor = math.floor
local dt = 0.05
local MAX_RUN_VELOCITY_COIN = 40
local speed = 0
-- class variables
local coinTimer = playdate.frameTimer.new(8,0,9)	-- Timer to control coin animations
coinTimer.reverses = true
coinTimer.repeats = true

local rotationTimer = playdate.frameTimer.new(20,-25,25)
rotationTimer.reverses = true
rotationTimer.repeats = true

local coinImagesTable = playdate.graphics.imagetable.new('img/mooncoin')
local coinImages = {}
for i = 1,#coinImagesTable do
	coinImages[i] = coinImagesTable[i]
end

function Coin:init(initialPosition)
	Coin.super.init(self)

	self:setImage(coinImages[1])
	self:setZIndex(800)
	self:setCenter(0, 0)
	self:setCollideRect(4,1,12,16)	-- coins are a bit more narrow than a regular tile
	self:moveTo(initialPosition)
	self.speed = speed
	self.direction = d
end

function collector()
	speed = 40
end

local setImage = playdate.graphics.sprite.setImage
local getImage = playdate.graphics.imagetable.getImage

function Coin:update()

	local velocityStep = self.speed * dt
	self.speed = self.speed - velocityStep
	if self.speed > MAX_RUN_VELOCITY_COIN then self.speed = MAX_RUN_VELOCITY_COIN
	elseif self.speed < -MAX_RUN_VELOCITY_COIN then self.speed = -MAX_RUN_VELOCITY_COIN
	end
	self:moveTo(self.x, self.y - self.speed)
	local frame = floor(coinTimer.value) +1 
	setImage(self, coinImages[frame])
	playdate.graphics.sprite.setRotation(self, rotationTimer.value)
end
