-- Tencent is pleased to support the open source community by making xLua available.
-- Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.
-- Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
-- http://opensource.org/licenses/MIT
-- Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

utils = require "LUtils"
require "LCollider"
-- local cs_coroutine = (require 'cs_coroutine')

-- ÿ����֡���� ִ���¼�
function LObject:runEvent()

	self.action = self.nextAction
	self.delayCounter = self.nextDelayCounter

	if self.delayCounter < self.database.animations[self.action].delay then
		local f = self.database.animations[self.action].eventQueue[self.delayCounter]
		-- self.delayCounter = self.delayCounter + 1
		self.nextDelayCounter = self.delayCounter + 1
		if f ~= nil then
			for i, v in ipairs(f) do
				self:invokeEvent("on" .. v.category, v)
			end
		end
	else
		-- self.delayCounter = 0
		self.nextDelayCounter = 0
	end
end

function LObject:new(parent, db, id, a, f, go, vx, vy, k)
	local self = {}
	setmetatable(self, LObject)
	self.eventQueue = {}
	self.eventManager = {}

    self.database = db
	self.id = id
	self.action = a
	self.nextAction = self.action
	self.frame = f
	self.delay = 0
	self.delayCounter = 0
	self.nextDelayCounter = self.delayCounter

	self.parent = self
	self.children = {}
	self.root = self
	self.animation = nil
	self.speed = 1
	self.timeLine = 0
	self.state = nil
	self.target = nil
	self.controller = nil

	for _i, _v in ipairs(self.database:getLines("vars")) do
		self[_v.name] = _v.default
		-- print(_v.name, self[_v.name])
	end

	-- self.functions = {}
	-- for _i, _v in ipairs(self.database:getLines("functions")) do
	-- 	self.functions[_v.name] = _v.value
	-- end

	self["parent"] = parent

	if k ~= 5 then
		self["story"] = self.database:getLines("story")
	end

	self.direction = CS.UnityEngine.Vector2(1, -1)
	self.directionBuff = CS.UnityEngine.Vector2(1, -1)

	self.velocity = CS.UnityEngine.Vector2(vx, vy)

	self.gameObject = go

	self.kind = k
	
	self.gameObject:AddComponent(typeof(CS.GameAnimation)).luaBehaviour = utils.LUABEHAVIOUR

	self.animation = self.gameObject:AddComponent(typeof(CS.UnityEngine.Animation))
	for _i, _v in pairs(self.database.animationClips) do
		
		self.animation:AddClip(_v, _v.name)
	end
	-- self.animation.animatePhysics = true

	self.audioSource = self.gameObject:AddComponent(typeof(CS.UnityEngine.AudioSource))
	self.audioSource.playOnAwake = false

	self.rigidbody = self.gameObject:AddComponent(typeof(CS.UnityEngine.Rigidbody2D))
	self.rigidbody.bodyType = CS.UnityEngine.RigidbodyType2D.Kinematic
	-- self.rigidbody.collisionDetectionMode = CS.UnityEngine.CollisionDetectionMode2D.Continuous
	-- self.rigidbody.sleepMode = CS.UnityEngine.RigidbodySleepMode2D.NeverSleep
	-- self.rigidbody.interpolation = CS.UnityEngine.RigidbodyInterpolation2D.Interpolate
	self.rigidbody.constraints = CS.UnityEngine.RigidbodyConstraints2D.FreezeRotation
	self.rigidbody.gravityScale = 0
	-- self.rigidbody.useAutoMass = true

	self.vvvX = nil
	self.vvvY = nil
	self.accvvvX = nil
	self.accvvvY = nil

	-- self:frameLoop() -- ��ִ��֡

	-- self.animation:Play(self.action)
	-- self.functions = CS.Tools.Instance:GetAnimationState(self.animation, self.action)

	self.oriPos = self.gameObject.transform.position
	return self
end

-- �����¼�
function LObject:addEvent(eventName, action)
	if not self.eventManager[eventName] then
		self.eventManager[eventName] = Delegate()
	end
	self.eventManager[eventName].add(action)
end

-- �Ƴ��¼�
function LObject:removeEvent(eventName, action)
	self.eventManager[eventName].delete(action)
end

-- �Ƴ������¼�
function LObject:removeAllEvent()
	self.eventManager = {}
end

-- �����¼�
function LObject:invokeEvent(eventName, ...)
	if self.eventManager[eventName] then
		self.eventManager[eventName].invoke(...)
	end
end

function LObject:getVar(n)
	return self[n]
end

-- ��ȡframe
function LObject:frameLoop()
end

-- ÿ����֡���� ��������
function LObject:runFrame()
	if self.directionBuff.x ~= self.direction.x then
		if self.direction.x == -1 then
			self.gameObject.transform.eulerAngles = CS.UnityEngine.Vector3(0, 180, 0)
		else
			self.gameObject.transform.eulerAngles = CS.UnityEngine.Vector3(0, 0, 0)
		end
		self.directionBuff.x = self.direction.x
	end
	
	if self.vvvX ~= nil then
		self.velocity.x = self.vvvX * self.direction.x
	end
	if self.vvvY ~= nil then
		self.velocity.y = self.vvvY * self.direction.y
	end

	if self.accvvvX ~= nil then
		self.velocity.x = self.velocity.x + self.accvvvX * self.direction.x
	end
	if self.accvvvY ~= nil then
		self.velocity.y = self.velocity.y + self.accvvvY * self.direction.y
	end
	self.accvvvX = nil
	self.accvvvY = nil

	self["velocityX"] = self.velocity.x
	self["velocityY"] = self.velocity.y

	self.rigidbody.position = self.rigidbody.position + self.velocity * CS.UnityEngine.Time.deltaTime
end

-- ��ʾ��Ϣ
function LObject:displayInfo()
end

function LObject:playAnimationEvent(clip, frame)
	local f = self.database.animations[clip].eventQueue[frame]
	if f ~= nil then
		for i, v in ipairs(f) do
			self:invokeEvent("on" .. v.category, v)
		end
	end

	-- if clip == "body_run_front" then
	-- 	self.rigidbody.position = self.rigidbody.position + CS.UnityEngine.Vector2(0.5, 0) * CS.UnityEngine.Time.deltaTime
	-- end
end

function LObject:runEvent2()
	
	-- if self.animation.isPlaying == true then

	-- 	-- if self.frame >= self.functions.time then
	-- 	-- 	self.delayCounter = self.delayCounter + 1
	-- 	-- end

	-- 	-- print(CS.Tools.Instance:GetAnimationState(self.animation, "body_run_front").time)
	-- 	-- self.frame = self.frame + CS.UnityEngine.Time.deltaTime * self.functions.speed

	-- 	if self.functions.time >= self.delayCounter * (1 / 60) then
	-- 		print(self.delayCounter)
	-- 		self.delayCounter = self.delayCounter + 1
	-- 	end
	-- end

	if self.action ~= nil then
		local c = self.database.animations[self.action].keyframes[self.delayCounter + 1]


		if c == nil then
			self.delayCounter = 0
			self.timeLine = 0
			c = self.database.animations[self.action].keyframes[self.delayCounter + 1]
		end

		if self.timeLine >= c * (1 / 60) then

			local f = self.database.animations[self.action].eventQueue[c]
			self.delayCounter = self.delayCounter + 1
			if f ~= nil then
				for i, v in ipairs(f) do
					self:invokeEvent("on" .. v.category, v)
				end
			end

		end
	end

	-- if c < self.database.animations[self.action].delay then
	self.timeLine = self.timeLine + CS.UnityEngine.Time.deltaTime * self.speed
	-- else
	-- 	self.delayCounter = 0
	-- 	self.timeLine = 0
	-- end

    -- local x = "timeLine + 5"
	-- local func = assert(load("return " .. x, "trigger", "t", self))

	-- local y = func()

	local gl = self.database.characters_state["global"]
	for i, v in ipairs(gl.state) do
		if v.trigger == nil or assert(load("return " .. v.trigger, "trigger", "t", self))() then
			if v.kind == "Command" then
				local cmd = utils.PLAYER.commands[v.command]
				if cmd.UIActive ~= nil then
					-- if self["HP"] > 0 and self["MP"] >= v.mp then
						self:changeState(v.stateChange)

						if cmd.UIActive == 1 then
							if self.direction.x == -1 then
								self.direction.x = 1
							end
						elseif cmd.UIActive == -1 then
							if self.direction.x == 1 then
								self.direction.x = -1
							end
						end

						-- self["MP"] = self["MP"] - v.mp
					-- end
				end
			end
		end
	end
	
	if self.state ~= nil then
		local st = self.database.characters_state[self.state]
		-- if st.animation ~= nil then
		-- 	self.action = st.animation
		-- 	self.delayCounter = 0
		-- 	self.timeLine = 0
		-- end
		for i, v in ipairs(st.state) do
			if v.trigger == nil or assert(load("return " .. v.trigger, "trigger", "t", self))() then
				if v.kind == "ChangeState" then
					self:changeState(v.stateChange)
				elseif v.kind == "ChangeAnimation" then
					self:changeAnimation(v.animationChange)
				elseif v.kind == "TurnRight" then
					self.direction.x = 1

					local ea = self.gameObject.transform.eulerAngles
					if self.direction.x == -1 then
						self.gameObject.transform.eulerAngles = CS.UnityEngine.Vector3(0, 180, ea.z)
					else
						self.gameObject.transform.eulerAngles = CS.UnityEngine.Vector3(0, 0, ea.z)
					end
				elseif v.kind == "TurnLeft" then
					self.direction.x = -1

					local ea = self.gameObject.transform.eulerAngles
					if self.direction.x == -1 then
						self.gameObject.transform.eulerAngles = CS.UnityEngine.Vector3(0, 180, ea.z)
					else
						self.gameObject.transform.eulerAngles = CS.UnityEngine.Vector3(0, 0, ea.z)
					end
				elseif v.kind == "Child" then
					local object = self.children[v.id]
					if object ~= nil then
						local z = v.layer / 100
						if self.root.direction.x == -1 then
							z = -z
						end
						object.gameObject.transform.localPosition = CS.UnityEngine.Vector3(v.x / 100, v.y / 100, z)
					end
				elseif v.kind == "TurnToTarget" then
					local pos = self.root.target.gameObject.transform.position
					local rad = CS.UnityEngine.Mathf.Atan2(self.gameObject.transform.position.y - pos.y, self.gameObject.transform.position.x - pos.x)
		
					local deg = rad * CS.UnityEngine.Mathf.Rad2Deg + 180
		
					local root = self.root
					if root ~= nil then
		
						if root.direction.x == -1 then
							deg = 360 - rad * CS.UnityEngine.Mathf.Rad2Deg
						end
						self.gameObject.transform.localEulerAngles = CS.UnityEngine.Vector3(0, 0, deg)
					end
				elseif v.kind == "Move" then
					if v.x2 ~= nil then
						self.velocity.x = v.x2
					end
					if v.y2 ~= nil then
						self.velocity.y = v.y2
					end
					-- self.rigidbody.position = self.rigidbody.position + CS.UnityEngine.Vector2(v.x, v.y) * CS.UnityEngine.Time.deltaTime
					-- self.gameObject.transform.position = self.gameObject.transform.position + CS.UnityEngine.Vector3(v.x, v.y, 0) * CS.UnityEngine.Time.deltaTime
				elseif v.kind == "Object" then
					local d = self.root.direction.x
					
					for i = 1, 10, 1 do

						local r = CS.Tools.Instance:RandomRangeInt(0, 31) - 30 / 2

						local rot = nil
						local velocity = nil
						if d == -1 then
							rot = CS.UnityEngine.Vector3(0, 180, self.gameObject.transform.eulerAngles.z + r)

							velocity = CS.UnityEngine.Quaternion.Euler(rot) * CS.UnityEngine.Vector3(v.x2 -  CS.Tools.Instance:RandomRangeInt(0, 16), v.y2, 0)
						elseif d == 1 then
							rot = CS.UnityEngine.Vector3(0, 0, self.gameObject.transform.eulerAngles.z + r)

							velocity = CS.UnityEngine.Quaternion.Euler(rot) * CS.UnityEngine.Vector3(v.x2 -  CS.Tools.Instance:RandomRangeInt(0, 16), v.y2, 0)
						end

						
						-- local velocity = CS.UnityEngine.Vector2(0, 0)

						local pos = self.gameObject.transform.rotation * CS.UnityEngine.Vector3(v.x / 100 * 2, -v.y / 100 * 2, 0)

						local object = utils.createObject(nil, tonumber(v.id), v.animationChange, 0, self.rigidbody.position.x + pos.x, self.rigidbody.position.y + pos.y, velocity.x, velocity.y, 0)
						local lr = object.gameObject:AddComponent(typeof(CS.UnityEngine.LineRenderer))
						lr.enabled = false
						lr.shadowCastingMode = CS.UnityEngine.Rendering.ShadowCastingMode.Off
						lr.startWidth = 0.02
						lr.endWidth = 0.01

						local rc = CS.Tools.Instance:RandomRangeInt(0, #v.colors) + 1
						local color = CS.Tools.Instance:ColorTryParseHtmlString("#" .. string.format("%X", v.colors[rc].color))

						lr.startColor = color
						lr.endColor = color
						lr.numCapVertices = 90
						lr.material = utils.LEGACYSHADERSPARTICLESALPHABLENDEDPREMULTIPLY

						object:changeState(v.stateChange)
						object.direction.x = d
						-- object.velocity.x = v.x2 * self.root.direction.x
						-- object.velocity.y = v.y2

						-- local ea = object.gameObject.transform.eulerAngles
						object.gameObject.transform.eulerAngles = rot
						-- local tr = object.gameObject:AddComponent(typeof(CS.UnityEngine.TrailRenderer))
						-- tr.startWidth = 0.04
						-- tr.endWidth = 0.01
						-- tr.shadowCastingMode = CS.UnityEngine.Rendering.ShadowCastingMode.Off
						-- tr.numCapVertices = 90
						-- tr.startColor = CS.UnityEngine.Color.yellow
						-- tr.endColor = CS.UnityEngine.Color(1, 0.92, 0.016, 0)

						-- tr.material =  CS.UnityEngine.Material(utils.getShader())
					end
				elseif v.kind == "Collison" then
					if self.frame == 1 then
						utils.destroyObject(self.gameObject:GetInstanceID())
					else
						-- local lr = self.gameObject:GetComponent(typeof(CS.UnityEngine.LineRenderer))
						local lr = self.gameObject:GetComponent(typeof(CS.UnityEngine.LineRenderer))
						

						local length = (self.gameObject.transform.position - self.oriPos).magnitude -- ���ߵĳ���
						local direction = self.gameObject.transform.position - self.oriPos -- ����
						-- RaycastHit2D[] hitinfo;
						local hitinfo = CS.UnityEngine.Physics2D.RaycastAll(CS.UnityEngine.Vector2(self.oriPos.x, self.oriPos.y), CS.UnityEngine.Vector2(direction.x, direction.y), length) -- ������λ��֮�䷢��һ�����ߣ�Ȼ��ͨ����������ȥ�����û�з�����ײ
						-- print(hitinfo.Length)
						for i = 0, hitinfo.Length - 1, 1 do

							lr:SetPosition(1, self.oriPos)
							lr:SetPosition(0, CS.UnityEngine.Vector3(hitinfo[i].point.x, hitinfo[i].point.y, 0))
							self.frame = 1

							-- print("destory! " .. i, hitinfo.Length, hitinfo[i].collider.name)
							-- utils.destroyObject(self.gameObject:GetInstanceID())

							-- CS.UnityEngine.GL.PushMatrix() -- ���浱ǰMatirx
							-- -- CS.UnityEngine.Material(utils.getShader()):SetPass(0) -- ˢ�µ�ǰ����
							-- CS.UnityEngine.GL.LoadPixelMatrix() -- ����pixelMatrix
							-- CS.UnityEngine.GL.Color(CS.UnityEngine.Color.yellow)
							-- CS.UnityEngine.GL.Begin(CS.UnityEngine.GL.LINES)
							-- CS.UnityEngine.GL.Vertex3(0, 0, 0)
							-- CS.UnityEngine.GL.Vertex3(CS.UnityEngine.Screen.width, CS.UnityEngine.Screen.height, 0)
							-- CS.UnityEngine.GL.End()
							-- CS.UnityEngine.GL.PopMatrix()

							break
						end
						if hitinfo.Length == 0 and self.oriPos.x ~= self.gameObject.transform.position.x and self.oriPos.y ~= self.gameObject.transform.position.y then
							lr.enabled = true
							lr:SetPosition(1, self.oriPos)
							lr:SetPosition(0, self.gameObject.transform.position)
						end
					end
				elseif v.kind == "Command" then
					local cmd = utils.PLAYER.commands[v.command]
					if cmd.UIActive ~= nil then
						-- if self["HP"] > 0 and self["MP"] >= v.mp then
							self:changeState(v.stateChange)
	
							if cmd.UIActive == 1 then
								if self.direction.x == -1 then
									self.direction.x = 1
								end
							elseif cmd.UIActive == -1 then
								if self.direction.x == 1 then
									self.direction.x = -1
								end
							end
	
							-- self["MP"] = self["MP"] - v.mp
						-- end
					end
				end
			end
		end

		-- if st.x ~= nil and st.y ~= nil then
		-- 	self.rigidbody.position = self.rigidbody.position + CS.UnityEngine.Vector2(st.x, st.y) * CS.UnityEngine.Time.deltaTime
		-- end
	end

	-- if self.state == "run" or self.state == "run2" then
	-- 	if self:targetDeg(0) >= 0 and self:targetDeg(0) <= 180 then
	-- 		self:changeState("run")
	-- 	elseif self:targetDeg(0) < 0 and self:targetDeg(0)  >= -180 then
	-- 		self:changeState("run2")
	-- 	end
	-- end

	-- if self.state == "run" or self.state == "run2" then
	-- 	self.rigidbody.position = self.rigidbody.position + CS.UnityEngine.Vector2(0.5, 0) * CS.UnityEngine.Time.deltaTime
	-- end
	self.oriPos = self.gameObject.transform.position
end

function LObject:changeState(state)
	if state ~= nil then
		self.state = state
	end
	local animation = self.database.characters_state[self.state].animation
	if animation ~= nil then
		self.action = animation
		self.delayCounter = 0
		self.timeLine = 0
	end
end

function LObject:changeAnimation(animation)
	if animation ~= nil then
		self.action = animation
		self.delayCounter = 0
		self.timeLine = 0
	end
end

function LObject:targetDeg(id)
	print(self.children, self.action, self.state, id)
	local object = self.children[tostring(id)]
	local pos = self.target.gameObject.transform.position
	-- object.gameObject.transform:LookAt(CS.UnityEngine.Vector3(pos.x, pos.y, object.gameObject.transform.position.z), CS.UnityEngine.Vector3(0, 0, 1))

	local rad = CS.UnityEngine.Mathf.Atan2(object.gameObject.transform.position.y - pos.y, object.gameObject.transform.position.x - pos.x)
	local deg = rad * CS.UnityEngine.Mathf.Rad2Deg

	return deg
end

function LObject:SetParentAndRoot(object)
	if self.gameObject.transform.parent == nil or self.gameObject.transform.parent ~= self.gameObject.transform then

		self.gameObject.transform:SetParent(object.gameObject.transform)
		self.parent = object
		if object.parent ~= nil then
			self.root = object.parent
		else
			self.root = object
		end
		self.gameObject.transform.localEulerAngles = CS.UnityEngine.Vector3(0, 0, 0)
	end
end
------------------------------------------------------------------------------

-- ��ȡframe
function LCharacterObject:frameLoop()
	self.delayCounter = 0
end

function LCharacterObject:new(parent, db, id, a, f, go, vx, vy, k)
	local self = {}
	self = LObject:new(parent, db, id, a, f, go, vx, vy, k)
	setmetatable(self, LCharacterObject)

	-- self.maxHP = self.database[self.id].char.maxHP
	-- self.maxMP = self.database[self.id].char.maxMP
	-- self.HP = self.maxHP
	-- self.MP = self.maxMP

	-- self.HPRR = self.database[self.id].char.HPRecoveryRate
	-- self.MPRR = self.database[self.id].char.MPRecoveryRate

	-- self.maxFalling = self.database[self.id].char.maxFalling
	-- self.maxDefencing = self.database[self.id].char.maxDefencing
	-- self.fallingRR = self.database[self.id].char.fallingRecoveryRate
	-- self.defencingRR = self.database[self.id].char.defencingRecoveryRate

	-- self.falling = 1
	-- self.defencing = 1

	-- self.weight = self.database[self.id].char.weight

	self.isWall = false
	self.isCeiling = false
	self.isOnGround = 1
	self.isElse = 1
	self.elseArray = {}

	self.attckArray = {}
	self.bodyArray = {}
	self.bodyArray_InstanceID = {}

	self.pic_object = CS.UnityEngine.GameObject("pic")
	self.pic_object.transform:SetParent(self.gameObject.transform)
	self.pic_object.transform.localPosition = CS.UnityEngine.Vector3.zero
	self.pic_object.transform.localScale = CS.UnityEngine.Vector3.one
	self.spriteRenderer = self.pic_object:AddComponent(typeof(CS.UnityEngine.SpriteRenderer))
	self.spriteRenderer.material = self.database.palettes[1]

	if self.kind == 3 then -- ���������ݶ�-20��
		self.spriteRenderer.sortingOrder = 20
	end

	self.audioSource = self.gameObject:AddComponent(typeof(CS.UnityEngine.AudioSource))
	self.audioSource.playOnAwake = false

	self.atk_object = CS.UnityEngine.GameObject("atk")
	self.atk_object.transform:SetParent(self.gameObject.transform)
	self.atk_object.transform.localPosition = CS.UnityEngine.Vector3.zero
	self.atk_object.transform.localScale = CS.UnityEngine.Vector3.one

	self.bdy_object = CS.UnityEngine.GameObject("bdy[16]")
	self.bdy_object.transform:SetParent(self.gameObject.transform)
	self.bdy_object.transform.localPosition = CS.UnityEngine.Vector3.zero
	self.bdy_object.transform.localScale = CS.UnityEngine.Vector3.one
	self.bdy_object.layer = 16 -- bdy��layer�ݶ�16

	self.AI = false
	self.target = nil

	self.catchedObjects = {}

	self.children = {}

	-- if self.kind ~= 3 and self.kind ~= 5 then
	-- 	self:addEvent("Flying", 0, 999999, nil)
	-- 	-- self:addEvent("Gravity", 0, 999999, nil)
	-- 	self:addEvent("HPMPFallingDefecing", 0, 999999, nil)
	-- 	self:addEvent("Friction", 0, 999999, nil)
	-- 	self:addEvent("FlipX", 0, 999999, nil)
	-- 	-- self:addEvent("Collision", 0, 999999, nil)

	-- 	self:addEvent("FindTarget", 0, 999999, nil) -- �ѵ�
	-- 	-- self:addEvent("Dead", 0, 999999, nil) -- �ѵ�
	-- end

	-- self:addEvent("UpdatePostion", 0, 999999, nil)

	self:addEvent("onSprite", function(value)
		-- print(value)
		self.spriteRenderer.sprite = self.database.sprites[value.sprite]
		self.pic_object.transform.localPosition = CS.UnityEngine.Vector3(value.x / 100, -value.y / 100, 0)
	end)

	self:addEvent("onSound", function(value)
		self.audioSource.clip = self.database.audioClips[value.sfx]
		-- local r = math.random() / 2.5
		-- self.audioSource.pitch = 1 + r - 0.2
		self.audioSource:Play()
	end)

	self:addEvent("onBody", function(value)
		if self.bodyArray[value.id] == nil and not (value.x == 0 or value.y == 0 or value.width == 0 or value.height == 0) then
			self.bodyArray[value.id] = LColliderBDY:new(self.bdy_object, value.id)
			self.bodyArray[value.id]:setCollider(value.direction, value.x, value.y, value.width, value.height, value.bodyFlags, value.layers)
			self.bodyArray_InstanceID[self.bodyArray[value.id].collider:GetInstanceID()] = self.bodyArray[value.id]
		else
			if self.bodyArray[value.id] ~= nil then
				if value.x == 0 or value.y == 0 or value.width == 0 or value.height == 0 then
					local IID = self.bodyArray[value.id].collider:GetInstanceID()
					self.bodyArray[value.id]:deleteCollider()
					self.bodyArray[value.id] = nil
					self.bodyArray_InstanceID[IID] = nil
				else
					self.bodyArray[value.id]:setCollider(value.direction, value.x, value.y, value.width, value.height, value.bodyFlags, value.layers)
				end
			end
		end
	end)
	self:addEvent("onAttack", function(value)
		if self.attckArray[value.id] == nil and not (value.x == 0 or value.y == 0 or value.width == 0 or value.height == 0) then
			self.attckArray[value.id] = LColliderATK:new(self.atk_object, value.id)
			self.attckArray[value.id]:setCollider(value.direction, value.x, value.y, value.width, value.height, value.attackFlags,
														value.damage, value.fall, value.defence, value.frequency, value.directionX, value.directionY, false, value.var,
														value.action, value.frame)
		else
			if self.attckArray[value.id] ~= nil then
				if value.x == 0 or value.y == 0 or value.width == 0 or value.height == 0 then
					self.attckArray[value.id]:deleteCollider()
					self.attckArray[value.id] = nil
				else
					self.attckArray[value.id]:setCollider(value.direction, value.x, value.y, value.width, value.height, value.attackFlags,
															value.damage, value.fall, value.defence, value.frequency, value.directionX, value.directionY, value.ignoreFlag, value.var,
															value.action, value.frame)
				end
			end
		end
	end)

	self:addEvent("onTrigger", function(value)
		local mousePos = CS.UnityEngine.Input.mousePosition
		-- mousePos.z = v3.z
		local worldPos = utils.CAMERA:ScreenToWorldPoint(mousePos)
        self.gameObject.transform.position = CS.UnityEngine.Vector3(worldPos.x, worldPos.y, 0)
	end)

	self:addEvent("onObject", function(value)
		if value.kind == 2 then

			if self.children[tostring(value.id)] ~= nil then

				local object = self.children[tostring(value.id)]

				if object.nextAction ~= value.clip then
					object.nextAction = value.clip
					-- object.frame = 0
					-- object:frameLoop()
				end

				if object.gameObject.transform.parent == nil or object.gameObject.transform.parent ~= self.gameObject.transform then
					
					print("setparent!")
					object.gameObject.transform:SetParent(self.gameObject.transform)
					object.parent = self
					if self.parent ~= nil then
						object.root = self.parent
					else
						object.root = self
					end
					object.gameObject.transform.localEulerAngles = CS.UnityEngine.Vector3(0, 0, 0)
				end
				-- object.rigidbody.position = CS.UnityEngine.Vector2(parent.rigidbody.position.x + v.x / 100 * 2, parent.rigidbody.position.y + v.y / 100 * 2)

				local z = value.layer / 100
				if object.root.direction.x == -1 then
					z = -z
				end
				object.gameObject.transform.localPosition = CS.UnityEngine.Vector3(value.x / 100, value.y / 100, z)

				-- object.gameObject.transform.localPosition = CS.UnityEngine.Vector3(value.x / 100, value.y / 100, 0)

				-- object.spriteRenderer.sortingOrder = -value.layer
			end
		end
	end)

	self:addEvent("onAct", function(value)

		if value.kind == 5 or value.kind == 6 then

			if self.children[tostring(value.id)] ~= nil then
				local object = self.children[tostring(value.id)]
				local pos = utils.CURSOR.gameObject.transform.position
				-- object.gameObject.transform:LookAt(CS.UnityEngine.Vector3(pos.x, pos.y, object.gameObject.transform.position.z), CS.UnityEngine.Vector3(0, 0, 1))

				local rad = CS.UnityEngine.Mathf.Atan2(object.gameObject.transform.position.y - pos.y, object.gameObject.transform.position.x - pos.x)
				local deg = rad * CS.UnityEngine.Mathf.Rad2Deg

				if value.kind == 5 and deg >= 0 and deg <= 180 then
					-- if self.nextAction ~= value.clip then
					-- 	self.nextAction = value.clip
					-- 	self.nextDelayCounter = value.frame
					-- end
				elseif value.kind == 6 and deg < 0 and deg >= -180 then
					-- if self.nextAction ~= value.clip then
					-- 	self.nextAction = value.clip
					-- 	self.nextDelayCounter = value.frame
					-- end
				end

				-- if object.gameObject.transform.position.x - pos.x < 0 then
				-- 	self.direction.x = 1
				-- else
				-- 	self.direction.x = -1
				-- end

				if self.gameObject.transform.position.x - pos.x < 0 then
					if self.direction.x ~= 1 then
						self.delayCounter = 0
						self.timeLine = 0
						self.direction.x = 1
					end
				else
					if self.direction.x ~= -1 then
						self.delayCounter = 0
						self.timeLine = 0
						self.direction.x = -1
					end
				end

				local ea = self.gameObject.transform.eulerAngles
				if self.direction.x == -1 then
					self.gameObject.transform.eulerAngles = CS.UnityEngine.Vector3(0, 180, ea.z)
				else
					self.gameObject.transform.eulerAngles = CS.UnityEngine.Vector3(0, 0, ea.z)
				end
			end
		elseif value.kind == 4 then
			local pos = utils.CURSOR.gameObject.transform.position
			local rad = CS.UnityEngine.Mathf.Atan2(self.gameObject.transform.position.y - pos.y, self.gameObject.transform.position.x - pos.x)

			local deg = rad * CS.UnityEngine.Mathf.Rad2Deg + 180

			local root = self.root
			if root ~= nil then

				if root.direction.x == -1 then
					deg = 360 - rad * CS.UnityEngine.Mathf.Rad2Deg
				end
				self.gameObject.transform.localEulerAngles = CS.UnityEngine.Vector3(0, 0, deg)
			end
		end
		
	end)

	-- self:frameLoop() -- ��ִ��֡
    return self
end

-- ÿ����֡���� ��������
function LCharacterObject:runFrame()
	

	-- 	self.velocity = self.velocity + 0.5 * CS.UnityEngine.Physics2D.gravity * CS.UnityEngine.Time.deltaTime
	
	-- 	self.rigidbody.position = self.rigidbody.position + self.velocity * CS.UnityEngine.Time.deltaTime
	
	-- 	self:frameLoop()

	-- if self.directionBuff.x ~= self.direction.x then
	-- 	if self.direction.x == -1 then
	-- 		self.gameObject.transform.eulerAngles = CS.UnityEngine.Vector3(0, 180, 0)
	-- 	else
	-- 		self.gameObject.transform.eulerAngles = CS.UnityEngine.Vector3(0, 0, 0)
	-- 	end
	-- 	self.directionBuff.x = self.direction.x
	-- end
	
	if self.vvvX ~= nil then
		self.velocity.x = self.vvvX * self.direction.x
	end
	if self.vvvY ~= nil then
		self.velocity.y = self.vvvY * self.direction.y
	end

	if self.accvvvX ~= nil then
		self.velocity.x = self.velocity.x + self.accvvvX * self.direction.x
	end
	if self.accvvvY ~= nil then
		self.velocity.y = self.velocity.y + self.accvvvY * self.direction.y
	end
	self.accvvvX = nil
	self.accvvvY = nil



	-- self["velocityX"] = self.velocity.x
	-- self["velocityY"] = self.velocity.y

	self.rigidbody.position = self.rigidbody.position + self.velocity * CS.UnityEngine.Time.deltaTime

	self.elseArray = {}
	-- ��ײ���
	local g = false
	for i, v in pairs(self.bodyArray) do
		local gg, cc, ww, ee, eeaa = v:BDYFixedUpdate(self.velocity, self:getVar("weight"))
		if gg ~= 1 then
			if g == false then
				self.isOnGround = gg
				self["isOnGround"] = self.isOnGround
				self.velocity.y = 0
				g = true
			end
		end
		self.isWall = ww
		if ww then
			self.velocity.x = 0
		end
		if cc then
			self.isCeiling = cc
			self.velocity.y = 0
		end
		self.isElse = ee

		for i2, v2 in pairs(eeaa) do
			if self.elseArray[i2] == nil then
				self.elseArray[i2] = {}
			end
			for i3, v3 in pairs(v2) do
				self.elseArray[i2][i3] = v3
			end
		end
	end
	if g == false then
		self.isOnGround = 1
		self["isOnGround"] = self.isOnGround
	end

	-- �������
	for i, v in pairs(self.attckArray) do
		v:ATKFixedUpdate(self.direction, self)
	end

	-- if self.isOnGround ~= 1 then
	-- 	self:invokeEvent("onGround", nil)
	-- else
	-- 	self:invokeEvent("onFlying", nil)
	-- end

	-- if self["HP"] > 0 then
	-- 	self:invokeEvent("onLive", nil)
	-- else
	-- 	-- self:invokeEvent("onDead", nil)
	-- end

	-- if self.isElse & (1 << 16) == 1 << 16 then
	-- 	if self["interact"] == nil then
	-- 		self:invokeEvent("onCommunicationEnter", nil)
	-- 	end
	-- else
	-- 	if self["interact"] ~= nil then
	-- 		self["interact"] = nil
	-- 		self:invokeEvent("onCommunicationExit", nil)
	-- 	end
	-- end
end

-- ��ʾ��Ϣ
function LCharacterObject:displayInfo()
	if self.kind ~= 3 and self.kind ~= 5 then
		local xy = CS.UnityEngine.Camera.main:WorldToScreenPoint(self.gameObject.transform.position)
		-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x, -xy.y + 300, 200, 100), "c: " .. #self.catchedObjects)
		-- if self["velocityX"] ~= nil and self["velocityY"] ~= nil then
		-- 	CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x, -xy.y + 300+ 20, 200, 100), "x: " .. math.floor(self["velocityX"] + 0.5) .. "y: " .. math.floor(self["velocityY"] + 0.5))
		-- end
		-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x, -xy.y + 300 + 20, 200, 100), "hp: " .. math.floor(self.HP + 0.5))
		-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x, -xy.y + 300 + 30, 200, 100), "mp: " .. math.floor(self.MP + 0.5))
		-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x, -xy.y + 300 + 40, 200, 100), "action: " .. self.action)
		-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x, -xy.y + 300 + 50, 200, 100), "frame: " .. self.frame)
		-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x, -xy.y + 300 + 60, 200, 100), "g: " .. tostring(self.isOnGround))
		-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x, -xy.y + 300 + 70, 200, 100), "w: " .. tostring(self.isWall))
		-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x, -xy.y + 300 + 80, 200, 100), "c: " .. tostring(self.isCeiling))
		-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x, -xy.y + 300 + 90, 200, 100), "e: " .. tostring(self.isElse))
		-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x, -xy.y + 300 + 100, 200, 100), "f: " .. math.floor(self.falling + 0.5))
		-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x, -xy.y + 300 + 110, 200, 100), "d: " .. math.floor(self.defencing + 0.5))
		-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x, -xy.y + 300 + 90, 200, 100), "i: " .. tostring(self["interact"])) -- "event: " .. #self.eventQueue

		-- local g = 0
		-- for i, v in pairs(self) do
		-- 	CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x, -xy.y + 300 + g * 10, 200, 100), i .. ": " .. tostring(v))
		-- 	g = g + 1
		-- end
		-- if self["kill"] > 1 then
			-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x - 13, -xy.y + 315 - 100 + 25, 200, 100), self["kill"] .. " kills")
		-- else
			-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x - 13, -xy.y + 315 - 100 + 25, 200, 100), self["kill"] .. " kill")

			-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x - 13, -xy.y + 315 - 120 + 25, 200, 100), self["HP"] .. " HP")
			-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x - 13, -xy.y + 315 - 140 + 25, 200, 100), self["MP"] .. " MP")
		-- end
		-- utils.drawHPMP(xy.x, -xy.y + 335 - 100 + 25, self["HP"] / self["maxHP"], self["MP"] / self["maxMP"], self["falling"] / self["maxFalling"], self["defencing"] / self["maxDefencing"])
	end
end

function LCharacterObject:SetParent()
end

function LCharacterObject:DetachChildren()
end

-- LObjectController = {database = nil, id = nil, action = nil, frame = nil, gameObject = nil, children = nil}
-- LObjectController.__index = LObjectController
-- function LObjectController:new(parent, id, a, f, x, y, dx, dy, k)
-- 	local self = {}
-- 	setmetatable(self, LObjectController)

-- 	self.database = utils.getIDData(id)
-- 	self.id = id
-- 	self.action = a
-- 	self.frame = f

-- 	self.children = {}

-- 	for i, v in ipairs(self.database.characters_state[self.action]) do
-- 		if self.children[v.object] == nil then
-- 			self.children[v.object] = utils.createObject(parent, id, v.animation, 0, x, y, dx, dy, k)
-- 		end
-- 	end

-- 	-- self:runState()

-- 	return self
-- end

-- function LObjectController:runState()

-- 	for i, v in ipairs(self.database.characters_state[self.action]) do
-- 		if v.kind2 == 1 then
-- 			local object = self.children[v.object]
-- 			local pos = utils.CURSOR.gameObject.transform.position
-- 			-- object.gameObject.transform:LookAt(CS.UnityEngine.Vector3(pos.x, pos.y, object.gameObject.transform.position.z), CS.UnityEngine.Vector3(0, 0, 1))

-- 			local rad = CS.UnityEngine.Mathf.Atan2(object.gameObject.transform.position.y - pos.y, object.gameObject.transform.position.x - pos.x)
-- 			local deg = rad * CS.UnityEngine.Mathf.Rad2Deg

-- 			local p = utils.split(self.action, "_")

-- 			if deg >= 0 and deg <= 180 then
-- 				self.action = self.database.FBcontorller[p[1]].front
-- 			elseif deg <= 0 and deg >= -180 then
-- 				self.action = self.database.FBcontorller[p[1]].back
-- 			end

-- 			local parent = nil
-- 			for i, v in ipairs(self.database.characters_state[self.action]) do
-- 				if v.parent ~= nil and v.parent ~= "" then
-- 					parent = self.children[v.parent]
-- 					break
-- 				end
-- 			end

-- 			if object.gameObject.transform.position.x - pos.x < 0 then
-- 				parent.direction.x = 1
-- 			else
-- 				parent.direction.x = -1
-- 			end

-- 			local ea = parent.gameObject.transform.eulerAngles
-- 			if parent.direction.x == -1 then
-- 				parent.gameObject.transform.eulerAngles = CS.UnityEngine.Vector3(0, 180, ea.z)
-- 			else
-- 				parent.gameObject.transform.eulerAngles = CS.UnityEngine.Vector3(0, 0, ea.z)
-- 			end
-- 			break
-- 		end
-- 	end

-- 	for i, v in ipairs(self.database.characters_state[self.action]) do
-- 		local object = self.children[v.object]
-- 		if object ~= nil then
-- 			if object.action ~= v.animation then
-- 				object.action = v.animation
-- 				object:frameLoop()
-- 			end



-- 			if v.parent ~= nil and v.parent ~= "" then
-- 				local parent = self.children[v.parent]
-- 				if parent ~= nil then
-- 					if object.gameObject.transform.parent == nil or object.gameObject.transform.parent ~= parent.gameObject.transform then
-- 						print("setparent!")
-- 						object.gameObject.transform:SetParent(parent.gameObject.transform)
-- 						object.gameObject.transform.localEulerAngles = CS.UnityEngine.Vector3(0, 0, 0)
-- 					end
-- 					-- object.rigidbody.position = CS.UnityEngine.Vector2(parent.rigidbody.position.x + v.x / 100 * 2, parent.rigidbody.position.y + v.y / 100 * 2)
					
-- 					local z = v.layer / 100
-- 					if parent.direction.x == -1 then
-- 						z = -z
-- 					end
-- 					object.gameObject.transform.localPosition = CS.UnityEngine.Vector3(v.x / 100, v.y / 100, z)

-- 					if v.kind == 1 then
-- 						local pos = utils.CURSOR.gameObject.transform.position
-- 						-- object.gameObject.transform:LookAt(CS.UnityEngine.Vector3(pos.x, pos.y, object.gameObject.transform.position.z), CS.UnityEngine.Vector3(0, 0, 1))
		
-- 						local rad = CS.UnityEngine.Mathf.Atan2(object.gameObject.transform.position.y - pos.y, object.gameObject.transform.position.x - pos.x)
		
-- 						local deg = rad * CS.UnityEngine.Mathf.Rad2Deg + 180
-- 						if parent.direction.x == -1 then
-- 							deg = 360 - rad * CS.UnityEngine.Mathf.Rad2Deg
-- 						end
-- 						object.gameObject.transform.localEulerAngles = CS.UnityEngine.Vector3(0, 0, deg)
-- 					end
-- 				end
-- 			else
-- 				-- object.rigidbody.position = CS.UnityEngine.Vector2(self.rigidbody.position.x + v.x / 100, self.rigidbody.position.y + v.y / 100)



-- 			end


-- 		end
-- 	end
-- end