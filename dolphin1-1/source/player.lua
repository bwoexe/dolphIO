import 'CoreLibs/frameTimer'
import 'bubble'

class('Player').extends(playdate.graphics.sprite)


-- local references
local Point = playdate.geometry.point
local Rect = playdate.geometry.rect
local vector2D = playdate.geometry.vector2D
local affineTransform = playdate.geometry.affineTransform
local min, max, abs, floor = math.min, math.max, math.abs, math.floor

-- constants
local dt = 0.05					-- time between frames at 20fps

local MAX_VELOCITY = 600
local GRAVITY_CONSTANT = 1680
local GRAVITY_STEP = vector2D.new(0, GRAVITY_CONSTANT * dt)
local JUMP_VELOCITY = 400
local SUPERJUMP_VELOCITY = 440

local MAX_JUMP_VELOCITY = 420
local MAX_FALL_VELOCITY = 280

local GROUND_FRICTION = 0.8			-- could be increased for different types of terrain
local SKID_FRICTION = 0.7			-- stop more quickly if the player is trying to change directions
local RUN_VELOCITY = 14 			-- velocity change for running
local AIR_RUN_VELOCITY = 15.5 			-- velocity change for moving in the air
local SPEED_OF_RUNNING = 50			-- thea velocity at which we decide the player is running rather than walking



local LEFT, RIGHT = 1, 2
local STAND, RUN1, RUN2, RUN3, TURN, JUMP, CROUCH = 1, 2, 3, 4, 5, 12, 7
local jump = 12
local crouching = 18
local shoot = 37
local shootTimer = playdate.frameTimer.new(12.5,0,7)
shootTimer:pause()
shootTimer.discardOnCompletion = false
local coolDown = false
local bubTimer = playdate.frameTimer.new(12.5,0,8)
bubTimer:pause()
bubTimer.discardOnCompletion = false
local bounce = 32
local bounceTimer = playdate.frameTimer.new(5,0,7)
bounceTimer:pause()
bounceTimer.discardOnCompletion = false
local crouchinginit = 18
-- timer used for player jumps
local jumpTimer = playdate.frameTimer.new(5, 45, 45, playdate.easingFunctions.outQuad)
jumpTimer:pause()
jumpTimer.discardOnCompletion = false


-- local variables - these are "class local" but since we only have one player this isn't a problem
local minXPosition = 8
local maxXPosition = 0 -- real value set in level.lua importTilemapsFromTiledJSON()
local minYPosition = 8
local maxYPosition = 0

playerStates = {}
local spriteHeight = 32
local onGround = true		-- true if player's feet are on the ground
local skidding = false		-- true if player is moving one way but the player is trying to move the opposite direction
local crouch = false
local shooting = false
--local bouncing = false
local facing = RIGHT
local MAX_RUN_VELOCITY = 130
local runImageIndex = 1


function Player:init()
	
	Player.super.init(self)

	self.playerImages = playdate.graphics.imagetable.new('img/player')
	self:setImage(self.playerImages:getImage(1))
	self:setZIndex(1000)
	self:setCenter(0.5, 1)	-- set center point to center bottom middle
	self:moveTo(102, 210)
	self:setCollideRect(12,12,24,20)
	
	self.position = Point.new(102, 210)
	self.velocity = vector2D.new(0,0)

	self.bouncing = false
end


function Player:reset()
	self.position = Point.new(102, 108)
	self.velocity = vector2D.new(0,0)
end


-- and other.crushed == true
function Player:collisionResponse(other)
	if other:isa(Coin) or (other:isa(Bubble)) then
		return "overlap"
	end
	
	return "slide"
end

function coolDownReset()
	if coolDown == true then
		coolDown = false
	end
	
end
function Player:bounce()
	bounceTimer:reset()
	bounceTimer:start()
	self.bouncing = true
end
-- called every frame, handles new input and does simple physics simulation
function Player:update()
	
	
	if playdate.buttonIsPressed("down") and onGround then
		
		self:setCrouching(true)

		
	else
		
		if onGround then
			self:setCrouching(false)
		else
			self:setCrouching(false)

		end
		
		if playdate.buttonIsPressed("left") then
			if onGround then
				self:runLeft()
			else
				self:airRunLeft()	-- can still move left and right in the air, but not as quickly
			end
			
			if playdate.buttonJustPressed("left") then
				if self.velocity.x > SPEED_OF_RUNNING then	-- skid if Player moving fast enough and now is trying to go the other way
					skidding = true
				else
					skidding = false
				end
			end
			
		elseif playdate.buttonIsPressed("right") then
			if onGround then
				self:runRight()
			else
				self:airRunRight()
			end
			
			if playdate.buttonJustPressed("right") then
				if self.velocity.x < -SPEED_OF_RUNNING then
					skidding = true
				else
					skidding = false
				end
			end
		end
	end
	
	--if playdate.buttonJustPressed("B") and onGround then 
	

	if onGround and (skidding == true or crouch == true or (playdate.buttonIsPressed("left") == false and playdate.buttonIsPressed("right") == false)) then
		
		if skidding == true then
			self.velocity.x = self.velocity.x * SKID_FRICTION
		else
			self.velocity.x = self.velocity.x * GROUND_FRICTION
		end
	end
	
	
	
	-- no longer skidding if we've slowed down this much
	if abs(self.velocity.x) < 10 then
		skidding = false
	end
	
	if playdate.buttonJustPressed("A") then
		self:jump()
	elseif playdate.buttonIsPressed("A") then
		self:continueJump()
	end
	
	
	if playdate.buttonJustPressed("B") then
		
		if coolDown == true then
		elseif facing == LEFT then
			Bubble(self.position.x - 32, self.y, 0)
		else
			Bubble(self.position.x + 32, self.y, 1)	
		end
		
		coolDown = true
		
			
		if shooting == false then
		shootTimer:reset()
		shootTimer:start()
		shooting = true
		end
		

	end
	if coolDown == true then
		bubTimer:start()
		if bubTimer.value > 7 then
			coolDown = false
		end
	else bubTimer:reset()

	end

	if playdate.buttonIsPressed("B") then
		MAX_RUN_VELOCITY = 180
	else
		MAX_RUN_VELOCITY = 120
	end
		

	-- gravity
	self.velocity = self.velocity + GRAVITY_STEP

	-- don't accellerate past max velocity
	if self.velocity.x > MAX_RUN_VELOCITY then self.velocity.x = MAX_RUN_VELOCITY
	elseif self.velocity.x < -MAX_RUN_VELOCITY then self.velocity.x = -MAX_RUN_VELOCITY
	end

	if self.velocity.y > MAX_FALL_VELOCITY then self.velocity.y = MAX_FALL_VELOCITY 
	elseif self.velocity.y < -MAX_JUMP_VELOCITY then self.velocity.y = -MAX_JUMP_VELOCITY
	end
	
	-- update the index used to control which frame of the run animation Player is in. Switch frames faster when running quickly.
	if abs(self.velocity.x) < 10 then
		self.velocity.x = 0

		-- TOM EDIT
		-- when idle run from frames 1 through 6...
		-- runImageIndex = 1 -- <= old code
		
		if runImageIndex > 6 then
			runImageIndex = 1
		else
			runImageIndex = runImageIndex + 0.5
		end

	elseif abs(self.velocity.x) < 140 then
		runImageIndex = runImageIndex + 0.5
	else
		runImageIndex = runImageIndex + 1
	end
	
	if runImageIndex > 11.5 then runImageIndex = 6 end
		
	
	-- update Player position based on current velocity
	local velocityStep = self.velocity * dt
	self.position = self.position + velocityStep
	
	-- don't move outside the walls of the game
	if self.position.x < minXPosition then
		self.velocity.x = 0
		self.position.x = minXPosition
	elseif self.position.x > maxXPosition then
		self.velocity.x = 0
		self.position.x = maxXPosition
	end
	
	self:updateImage()

end


-- sets the appropriate sprite image for Player based on the current conditions
function Player:updateImage()
	

	if crouch then
		
		self:setCollideRect(8,20,32,12)

		if crouching > 28 then
				crouching = 28
		else 
			
			if crouching then
				crouching = crouching + 2
			end
		end
		if facing == LEFT then
			self:setImage(self.playerImages:getImage(floor(crouching)), "flipX")
		else
			self:setImage(self.playerImages:getImage(floor(crouching)))
		end
	
		
	elseif shooting == true then
		if shootTimer.value > 6 then
			 shooting = false
		else
		
		if facing == LEFT then
			self:setImage(self.playerImages:getImage(floor(shoot + shootTimer.value)), "flipX")
		else
			self:setImage(self.playerImages:getImage(floor(shoot + shootTimer.value)))
		end
	end
	
	elseif onGround then
		
		self:setCollideRect(12,12,24,20)
		
		if crouching > 18 then 
			crouching = crouching - 2
		else
		crouching = 18 
		end
		if facing == LEFT then
		self:setImage(self.playerImages:getImage(floor(crouching)), "flipX")
		else
		self:setImage(self.playerImages:getImage(floor(crouching)))
		end
		if facing == LEFT then
			if skidding then
				self:setImage(self.playerImages:getImage(TURN), "flipX")
			elseif self.velocity.x == 0 then
				-- TOM EDIT
				-- changed STAND to whatever the current runImageIndex is...
				-- self:setImage(self.playerImages:getImage(STAND), "flipX")
				self:setImage(self.playerImages:getImage(floor(runImageIndex)), "flipX")
			else
				self:setImage(self.playerImages:getImage(floor(runImageIndex+1)), "flipX")
			end
		else
			if skidding then
				self:setImage(self.playerImages:getImage(TURN))
			elseif self.velocity.x == 0 then
				-- TOM EDIT
				-- changed STAND to whatever the current runImageIndex is...
				-- self:setImage(self.playerImages:getImage(STAND))
				self:setImage(self.playerImages:getImage(floor(runImageIndex)))
			else
				self:setImage(self.playerImages:getImage(floor(runImageIndex+1)))
			end
		end
	
		
		
	else		
		if jump then
			if jump > 17 then
				jump = 13 
			else
			if jump then
				jump = jump + .5
			end
			crouching = 18
		end
		
	
		if facing == LEFT then
			self:setImage(self.playerImages:getImage(floor(jump)), "flipX")
		else
			self:setImage(self.playerImages:getImage(floor(jump)))
		end
	
	end
	
	 if self.bouncing then
	if bounceTimer.value > 6 then
		self.bouncing = false
		else
			if facing == LEFT then
				self:setImage(self.playerImages:getImage(floor(bounce + bounceTimer.value)), "flipX")
			else
				self:setImage(self.playerImages:getImage(floor(bounce + bounceTimer.value)))
			end
	end	
	end
	end
end


-- function Player:updateImage()

-- if self.bouncing then
-- 	if bounceTimer.value > 6 then
-- 		self.bouncing = false
-- 		else
-- 			if facing == LEFT then
-- 				self:setImage(self.playerImages:getImage(floor(bounce + bounceTimer.value)), "flipX")
-- 			else
-- 				self:setImage(self.playerImages:getImage(floor(bounce + bounceTimer.value)))
-- 			end
-- 	end	
-- end
-- end

function Player:setMaxX(x)
	maxXPosition = x
end
function Player:setMaxY(y)
	maxYPosition = y
end
function Player:setOnGround(flag)
	onGround = flag
end


function Player:setCrouching(flag)
	crouch = flag
	
	if crouch then
		spriteHeight = 24
	else
		spriteHeight = 32
	end
end


function Player:isCrouching()
	return crouch
end


function Player:runLeft()
	facing = LEFT
	self.velocity.x = max(self.velocity.x - RUN_VELOCITY, -MAX_VELOCITY)
end


function Player:runRight()
	facing = RIGHT
	self.velocity.x = min(self.velocity.x + RUN_VELOCITY, MAX_VELOCITY)
	
end


function Player:airRunLeft()
	facing = LEFT
	self.velocity.x = self.velocity.x - AIR_RUN_VELOCITY
	if self.velocity.y < -MAX_VELOCITY then self.velocity.x = -MAX_VELOCITY end
end


function Player:airRunRight()
	facing = RIGHT
	self.velocity.x = self.velocity.x + AIR_RUN_VELOCITY
	if self.velocity.x > MAX_VELOCITY then self.velocity.x = MAX_VELOCITY end
end


function Player:jump()
	
	-- if feet on ground
	if onGround then
		
		if playdate.buttonIsPressed("A") and abs(self.velocity.x) > SPEED_OF_RUNNING then -- super jump
			self.velocity.y = -SUPERJUMP_VELOCITY
		else -- regular jump
			self.velocity.y = -JUMP_VELOCITY
		end
		
		jumpTimer:reset()
		jumpTimer:start()		
		
		skidding = false
		crouch = false
		SoundManager:playSound(SoundManager.kSoundJump)
	end
	
end


function Player:continueJump()
	self.velocity.y = self.velocity.y - jumpTimer.value
end

