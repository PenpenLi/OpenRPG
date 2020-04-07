-- Tencent is pleased to support the open source community by making xLua available.
-- Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.
-- Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
-- http://opensource.org/licenses/MIT
-- Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

LCollider = {LObject = nil, gameObject = nil, id = nil, collider = nil, filter = nil, isDefence = nil, layers = nil}
LCollider.__index = LCollider
function LCollider:new(l, go, id)
	local self = {}
	setmetatable(self, LCollider)

	self.LObject = l
	self.gameObject = go
	self.id = id
	self.filter = nil

	self.collider = self.gameObject:AddComponent(typeof(CS.UnityEngine.BoxCollider))

	self.offset = nil
	self.size = nil

	self.isDefence = nil

	self.layers = nil

    return self
end

-- ����collider
function LCollider:setCollider(dir, x, y, width, height, flag, layers)
	self.offset = CS.UnityEngine.Vector3((x + width / 2) / 100, -(y + height / 2) / 100, 0)
	self.size = CS.UnityEngine.Vector3(width / 100, height / 100, width / 100)
	self.collider.center = self.offset-- * dir
	self.collider.size = self.size

	self.layers = layers

	self.filter = CS.UnityEngine.ContactFilter2D()
	self.filter.useLayerMask = true
	self.filter.useTriggers = true
	local lll = CS.UnityEngine.LayerMask()
	if flag & 1 == 1 then
		lll.value = lll.value | 65535 | 1 << 16

		if layers ~= nil then
			for s in string.gmatch(layers, "%d+") do
				lll.value = lll.value & ~(1 << tonumber(s))
			end
		end
	end
	if flag & 2 == 2 then
		self.collider.isTrigger = true
	else
		self.collider.isTrigger = false
	end
	if flag & 8 == 8 then
		self.isDefence = true
	else
		self.isDefence = false
	end
	self.filter.layerMask = lll
end

--~ function LCollider:reverseCollider(dir)
--~ 	self.offset = self.offset * dir
--~ 	self.collider.offset = self.offset
--~ end

function LCollider:deleteCollider()
	CS.UnityEngine.Object.Destroy(self.collider)
end

LColliderBDY = { bounciness = nil}
setmetatable(LColliderBDY, LCollider)
LColliderBDY.__index = LColliderBDY
function LColliderBDY:new(l, go)
	local self = {}
	self = LCollider:new(l, go)
	setmetatable(self, LColliderBDY)

	if self.LObject.kind == 99 then
		self.bounciness = 0.5
	else
		self.bounciness = 0
	end


	return self
end

-- �����ײ����������ײ�����λ��
function LColliderBDY:BDYFixedUpdate2D(velocity, weight)
	local isGround = 1
	local isCeiling = false
	local isWall = false
	local isElse = 1
	local elseArray = {}

	-- ����ʲô����2d��ײ��Χһ���ʵ��Ҫ����ΪAABBҪ��һ�㣬Ϊ�˾�ȷ��ײ����Ҫ�Լ�ʵ��
	local contactColliders = CS.Tools.Instance:Collider2DOverlapCollider(self.collider, self.filter) -- ���������ʵCollider2D.OverlapCollider�������ֶ������ײ�������Ϊlua��Ե�ʷ�װ��һ��

	local objectTable = {}

	-- ����λ������
	local finalOffset_x = 0
	local finalOffset_y = 0
	for p, k in pairs(contactColliders) do
		if self.collider.bounds:Intersects(k.bounds) then

			local up, down, left, right = false, false, false, false

			local go = k.attachedRigidbody.gameObject
			local object2 = utils.getObject(go:GetInstanceID())
			if go.name == "test" then -- ����ǵ�ͼ��
				local name = utils.split(k.name, ",")
				local num = tonumber(name[#name]) -- ��ͼ�����һ��������Ϊbit

				if num & 1 == 1 then --λ���������������鳯�ĸ����������ײ��һ����������ж����ײ�����ⲿ��������ƣ�ֻ��Ҫ��֪�����collider���ж�������layermaskʲô����
					up = true
				end
				if num & 2 == 2 then --λ����
					down = true
				end
				if num & 4 == 4 then --λ����
					left = true
				end
				if num & 8 == 8 then --λ����
					right = true
				end
			elseif go.name ~= "test" and object2 ~= nil and not object2["isCatched"] and self.collider.attachedRigidbody.gameObject ~= go then -- ����Ϸobject����ֻ�������ҽ�����ײ

				local LC = object2.bodyArray_InstanceID[k:GetInstanceID()]

				if not string.find(LC.layers, string.match(self.collider.name, "%[(%d+)%]")) then
					left = true
					right = true
				end
			else
				-- return 1, false, false, 1, elseArray
			end

			if up or down or left or right then

				local menseki = utils.getBoundsIntersectsArea(self.collider.bounds, k.bounds)
				if menseki.magnitude > 0 then -- ���Ӷ����������

					-- ��2��collider֮����룬��Ҫ��Ϊ�˷���
					local cd2d = self.collider:Distance(k)

	--~ 				local a =  CS.UnityEngine.Vector3(cd2d.pointA.x, cd2d.pointA.y, 0)
	--~ 				local b =  CS.UnityEngine.Vector3(cd2d.pointB.x, cd2d.pointB.y, 0)
					local normal =  -CS.UnityEngine.Vector3(cd2d.normal.x, cd2d.normal.y, 0)
	--~ 				CS.UnityEngine.Debug.DrawLine(a, a + normal, CS.UnityEngine.Color.red)
	--~ 				CS.UnityEngine.Debug.DrawLine(b, b + normal, CS.UnityEngine.Color.yellow)

					-- ����ײ�������н�����ĵ��
					-- local projection = CS.UnityEngine.Vector2.Dot(velocity.normalized, normal) -- û�õ�������Ҫ�����Լ��������

					local offset_x = 0
					local offset_y = 0

					-- ���ƣ�����
					if self.collider.bounds.center.x < k.bounds.center.x then
						if left and CS.UnityEngine.Vector2.Dot(velocity.normalized, CS.UnityEngine.Vector2(-1, 0)) <= 0 then -- �����ײ�������н������෴�������λ������
							offset_x = -menseki.x
						end
					else
						if right and CS.UnityEngine.Vector2.Dot(velocity.normalized, CS.UnityEngine.Vector2(1, 0)) <= 0 then
							offset_x = menseki.x
						end
					end
					-- ���ƣ�����
					if self.collider.bounds.center.y > k.bounds.center.y then
						if up and CS.UnityEngine.Vector2.Dot(velocity.normalized, CS.UnityEngine.Vector2(0, 1)) <= 0 then
							offset_y = menseki.y
						end
					else
						if down and CS.UnityEngine.Vector2.Dot(velocity.normalized, CS.UnityEngine.Vector2(0, -1)) <= 0 then
							offset_y = -menseki.y
						end
					end

					if (up or down) and (left or right) then -- ���ͬʱ�������º����ҷ���ͬʱ���ڵ�������������ײ������ɸѡ����һ�����λ��
						offset_x = offset_x * math.abs(normal.x)
						offset_y = offset_y * math.abs(normal.y)
					end

					-- ������Сλ������
					if velocity.x > 0 then
						if offset_x < finalOffset_x then
							finalOffset_x = offset_x
						end
					else
						if offset_x > finalOffset_x then
							finalOffset_x = offset_x
						end
					end

					if velocity.y > 0 then
						if offset_y < finalOffset_y then
							finalOffset_y = offset_y
						end
					else
						if offset_y > finalOffset_y then
							finalOffset_y = offset_y
						end
					end

					if velocity.x ~= 0 and object2 ~= nil and offset_x ~= 0 and object2.isWall == false then
						local rate = weight / object2["weight"] / 2
						if rate > 1 then
							rate = 1
						end
						local vOffset = (object2.velocity.x - velocity.x) * rate
	--~ 					object2.velocity.x = object2.velocity.x - vOffset
						-- print(object2)
						object2:invokeEvent("onForce", {velocity = CS.UnityEngine.Vector2(-vOffset, 0), compute = 1})
					end

					if go.name == "test" then -- �ж��ǲ���ײ�����棬����д���ã��Ժ����Ż�
						if finalOffset_x ~= 0 and (normal.x == -1 or normal.x == 1) then
							isWall = true
						end
						if finalOffset_y > 0 then
							local id = string.match(k.name, "%[(%d+)%]")

							if id then
								isGround = isGround | 1 << tonumber(id)
							end

						elseif finalOffset_y < 0 then
							isCeiling = true
						end
					end
				end
			else
				local id = string.match(k.name, "%[(%d+)%]")
				if id then
					isElse = isElse | 1 << tonumber(id)
				end
				if elseArray[id] == nil then
					elseArray[id] = {}
				end
				elseArray[id][k:GetInstanceID()] = k
			end
		end
	end

	-- ��������λ��
	self.collider.attachedRigidbody.position = self.collider.attachedRigidbody.position + CS.UnityEngine.Vector2(finalOffset_x, finalOffset_y)

	return isGround, isCeiling, isWall, isElse, elseArray
end

function LColliderBDY:BDYFixedUpdate()
	local isGround = -1
	local isWall_leftright = -1
	local isWall_updown = -1

	local velocity = self.LObject.velocity * CS.UnityEngine.Time.deltaTime
	

	local contactColliders = CS.UnityEngine.Physics.OverlapBox(self.collider.bounds.center + velocity, self.collider.bounds.extents, self.gameObject.transform.rotation, self.filter.layerMask.value)

	-- local contactColliders = CS.Tools.Instance:PhysicsOverlapBoxNonAlloc(self.collider.bounds.center + velocity, self.collider.bounds.extents, self.gameObject.transform.rotation, self.filter.layerMask.value)

	-- local contactColliders = CS.LuaUtil.PhysicsBoxCastNonAlloc(self.collider.bounds.center, self.collider.bounds.extents, velocity.normalized, self.gameObject.transform.rotation, velocity.magnitude, self.filter.layerMask.value)

	-- ����λ������
	local finalOffset_x = velocity.x
	local finalOffset_z = velocity.z
	local finalOffset_y = velocity.y
	for i = 0, contactColliders.Length - 1, 1 do
		local k = contactColliders[i]
		if k ~= nil and k.attachedRigidbody ~= self.collider.attachedRigidbody then
			-- print(k.name)
			local up, down, left, right, above, under = false, false, false, false, false, false

			local go = k.attachedRigidbody.gameObject
			-- local object2 = utils.getObject(go:GetInstanceID())
			if go.name == "test" then -- ����ǵ�ͼ��
				local name = utils.split(k.name, ",")
				local num = tonumber(name[#name]) -- ��ͼ�����һ��������Ϊbit


				if num & 1 == 1 then --λ���������������鳯�ĸ����������ײ��һ����������ж����ײ�����ⲿ��������ƣ�ֻ��Ҫ��֪�����collider���ж�������layermaskʲô����
					up = true
				end
				if num & 2 == 2 then --λ����
					down = true
				end
				if num & 4 == 4 then --λ����
					left = true
				end
				if num & 8 == 8 then --λ����
					right = true
				end
				if num & 16 == 16 then --λ����
					above = true
				end
				if num & 32 == 32 then --λ����
					under = true
				end
			-- elseif go.name ~= "test" and object2 ~= nil and not object2["isCatched"] and self.collider.attachedRigidbody.gameObject ~= go then -- ����Ϸobject����ֻ�������ҽ�����ײ

			-- 	local LC = object2.bodyArray_InstanceID[k:GetInstanceID()]

			-- 	if not string.find(LC.layers, string.match(self.collider.name, "%[(%d+)%]")) then
			-- 		up = true
			-- 		down = true
			-- 		left = true
			-- 		right = true
			-- 	end
				-- above = true
				-- under = true
			else
				-- return 1, false, false, 1, elseArray
			end

			if up or down or left or right or above or under then
					
				local m = utils.getBoundsIntersectsArea222(self.collider.bounds, velocity, k.bounds)
				if m.magnitude > 0 then
			
					local offset_x = nil
					local offset_z = nil
					local offset_y = nil

					if (left or right) and (up or down) then
						if m.x > m.z then
							m.x = 0
						else
							m.z = 0
						end
					end

					if velocity.x > 0 then
						offset_x = velocity.x - m.x
					else
						offset_x = velocity.x + m.x
					end
					if velocity.z > 0 then
						offset_z = velocity.z - m.z
					else
						offset_z = velocity.z + m.z
					end

					if velocity.y > 0 then
						offset_y = velocity.y - m.y
					else
						offset_y = velocity.y + m.y
					end


					-- ������Сλ������
					if left or right then
						if velocity.x > 0 then
							if offset_x < finalOffset_x then
								finalOffset_x = offset_x
							end
						else
							if offset_x > finalOffset_x then
								finalOffset_x = offset_x
							end
						end

						isWall_leftright = 1

					end

					if up or down then
						if velocity.z > 0 then
							if offset_z < finalOffset_z then
								finalOffset_z = offset_z
							end
						else
							if offset_z > finalOffset_z then
								finalOffset_z = offset_z
							end
						end

						isWall_updown = 1

					end

					if above or under then

						if velocity.y > 0 then
							if offset_y < finalOffset_y then
								finalOffset_y = offset_y
							end
						else
							if offset_y > finalOffset_y then
								finalOffset_y = offset_y
							end
						end

						if isGround == -1 and m.y > 0 then
							isGround = 1 << tonumber(0)
						end
					end
				end
			end
		end
	end
	-- ��������λ��
	-- self.collider.attachedRigidbody.position = self.collider.attachedRigidbody.position + CS.UnityEngine.Vector3(finalOffset_x, finalOffset_y, finalOffset_z)

	CS.LuaUtil.SetPos2(self.LObject.rigidbody_id, self.collider.attachedRigidbody.position.x + finalOffset_x, self.collider.attachedRigidbody.position.y + finalOffset_y, self.collider.attachedRigidbody.position.z + finalOffset_z)

	if isWall_leftright == 1 then
		self.LObject.velocity.x = -self.LObject.velocity.x * self.bounciness
	end
	if isWall_updown == 1 then
		self.LObject.velocity.z = -self.LObject.velocity.z * self.bounciness
	end
	if isGround == 1 then
		self.LObject.velocity.y = -self.LObject.velocity.y * self.bounciness
	end
	return isGround
end

function LColliderBDY:BDYFixedUpdate2D3D(velocity, weight)
	local isGround = nil
	local isCeiling = false
	local isWall = false
	local isElse = 1
	local elseArray = {}

	-- local contactColliders = CS.UnityEngine.Physics.OverlapBox(self.collider.bounds.center, self.collider.bounds.extents, self.gameObject.transform.rotation, self.filter.layerMask.value)

	-- -- ����λ������
	-- local finalOffset_y = 0
	-- for i = 0, contactColliders.Length - 1, 1 do
	-- 	local k = contactColliders[i]
	-- 	if k.attachedRigidbody ~= self.collider.attachedRigidbody then
	-- 		-- print(k.name)
	-- 		local above, under = false, false

	-- 		local go = k.attachedRigidbody.gameObject
	-- 		if go.name == "test" then -- ����ǵ�ͼ��
	-- 			local name = utils.split(k.name, ",")
	-- 			local num = tonumber(name[#name]) -- ��ͼ�����һ��������Ϊbit

	-- 			if num & 16 == 16 then --λ����
	-- 				above = true
	-- 			end
	-- 			if num & 32 == 32 then --λ����
	-- 				under = true
	-- 			end
	-- 		else
	-- 			-- return 1, false, false, 1, elseArray
	-- 		end

	-- 		if above or under then

	-- 			local menseki, normal = utils.getBoundsIntersectsArea3D(self.collider.bounds, k.bounds)
	-- 			if menseki.magnitude > 0 then -- ���Ӷ����������

	-- 				-- ��2��collider֮����룬��Ҫ��Ϊ�˷���
	-- 				-- local cd2d = self.collider:Distance(k)

	-- -- ~ 				local a =  CS.UnityEngine.Vector3(cd2d.pointA.x, cd2d.pointA.y, 0)
	-- -- ~ 				local b =  CS.UnityEngine.Vector3(cd2d.pointB.x, cd2d.pointB.y, 0)
	-- 				-- local a = self.collider.gameObject.transform.position
	-- 				-- local b = k.gameObject.transform.position
	-- 				-- local normal =  -CS.UnityEngine.Vector3(cd2d.normal.x, cd2d.normal.y, 0)
	-- 				-- local normal = -menseki.normalized
	-- 				-- local c = a +  normal
	-- 				-- local d = b +  normal
	--  				-- CS.UnityEngine.Debug.DrawLine(a, c, CS.UnityEngine.Color.red)
	-- 				-- CS.UnityEngine.Debug.DrawLine(b, d, CS.UnityEngine.Color.yellow)
	-- 				-- print(normal)

	-- 				-- ����ײ�������н�����ĵ��
	-- 				-- local projection = CS.UnityEngine.Vector2.Dot(velocity.normalized, normal) -- û�õ�������Ҫ�����Լ��������

	-- 				local offset_y = 0

	-- 				local velo_nor2 = CS.UnityEngine.Vector2(velocity.x, velocity.y).normalized

	-- 				if self.collider.bounds.center.y > k.bounds.center.y then
	-- 					if above and CS.UnityEngine.Vector2.Dot(velo_nor2, CS.UnityEngine.Vector2(0, 1)) <= 0 then
	-- 						offset_y = menseki.y
	-- 					end
	-- 				else
	-- 					if under and CS.UnityEngine.Vector2.Dot(velo_nor2, CS.UnityEngine.Vector2(0, -1)) <= 0 then
	-- 						offset_y = -menseki.y
	-- 					end
	-- 				end

	-- 				-- ������Сλ������

	-- 				if velocity.y > 0 then
	-- 					if offset_y < finalOffset_y then
	-- 						finalOffset_y = offset_y
	-- 					end
	-- 				else
	-- 					if offset_y > finalOffset_y then
	-- 						finalOffset_y = offset_y
	-- 					end
	-- 				end


	-- -- 				if velocity.x ~= 0 and object2 ~= nil and offset_x ~= 0 and object2.isWall == false then
	-- -- 					local rate = weight / object2["weight"] / 2
	-- -- 					if rate > 1 then
	-- -- 						rate = 1
	-- -- 					end
	-- -- 					local vOffset = (object2.velocity.x - velocity.x) * rate
	-- -- --~ 					object2.velocity.x = object2.velocity.x - vOffset
	-- -- 					-- print(object2)
	-- -- 					object2:invokeEvent("onForce", {velocity = CS.UnityEngine.Vector2(-vOffset, 0), compute = 1})
	-- -- 				end

	-- 				if go.name == "test" then -- �ж��ǲ���ײ�����棬����д���ã��Ժ����Ż�
	-- 					-- if finalOffset_x ~= 0 and (normal.x == -1 or normal.x == 1) then
	-- 					-- 	isWall = true
	-- 					-- end
	-- 					if finalOffset_y > 0 then
	-- 						local id = string.match(k.name, "%[(%d+)%]")

	-- 						if id then
	-- 							if isGround ~= nil then
	-- 								isGround = isGround | 1 << tonumber(id)
	-- 							else
	-- 								isGround = 1 << tonumber(id)
	-- 							end
	-- 						end

	-- 					-- elseif finalOffset_y < 0 then
	-- 					-- 	isCeiling = true
	-- 					end
	-- 				end
	-- 			end
	-- 		else
	-- 			local id = string.match(k.name, "%[(%d+)%]")
	-- 			if id then
	-- 				isElse = isElse | 1 << tonumber(id)
	-- 			end
	-- 			if elseArray[id] == nil then
	-- 				elseArray[id] = {}
	-- 			end
	-- 			elseArray[id][k:GetInstanceID()] = k
	-- 		end
	-- 	end
	-- end

	-- -- ��������λ��
	-- -- self.collider.attachedRigidbody.position = self.collider.attachedRigidbody.position + CS.UnityEngine.Vector3(0, finalOffset_y, 0)

	local contactColliders = CS.UnityEngine.Physics.OverlapBox(self.collider2.bounds.center, self.collider2.bounds.extents, self.gameObject.transform.rotation, self.filter.layerMask.value)

	-- ����λ������
	local finalOffset_x = 0
	local finalOffset_z = 0
	for i = 0, contactColliders.Length - 1, 1 do
		local k = contactColliders[i]
		if k.attachedRigidbody ~= self.collider2.attachedRigidbody then
			-- print(k.name)
			local up, down, left, right = false, false, false, false

			local go = k.attachedRigidbody.gameObject
			local object2 = utils.getObject(go:GetInstanceID())
			if go.name == "test" then -- ����ǵ�ͼ��
				local name = utils.split(k.transform.parent.name, ",")
				local num = tonumber(name[#name]) -- ��ͼ�����һ��������Ϊbit
				if num ~= nil then
					if num & 1 == 1 then --λ���������������鳯�ĸ����������ײ��һ����������ж����ײ�����ⲿ��������ƣ�ֻ��Ҫ��֪�����collider���ж�������layermaskʲô����
						up = true
					end
					if num & 2 == 2 then --λ����
						down = true
					end
					if num & 4 == 4 then --λ����
						left = true
					end
					if num & 8 == 8 then --λ����
						right = true
					end
				end
			-- elseif go.name ~= "test" and object2 ~= nil and not object2["isCatched"] and self.collider2.attachedRigidbody.gameObject ~= go then -- ����Ϸobject����ֻ�������ҽ�����ײ

			-- 	local LC = object2.bodyArray_InstanceID[k:GetInstanceID()]

			-- 	if not string.find(LC.layers, string.match(self.collider2.name, "%[(%d+)%]")) then
			-- 		up = true
			-- 		down = true
			-- 		left = true
			-- 		right = true
			-- 	end
			-- else
				-- return 1, false, false, 1, elseArray
			end

			if up or down or left or right then

				local menseki, normal = utils.getBoundsIntersectsArea3D(self.collider2.bounds, k.bounds)
				if menseki.magnitude > 0 then -- ���Ӷ����������

					-- ��2��collider֮����룬��Ҫ��Ϊ�˷���
					-- local cd2d = self.collider:Distance(k)

	-- ~ 				local a =  CS.UnityEngine.Vector3(cd2d.pointA.x, cd2d.pointA.y, 0)
	-- ~ 				local b =  CS.UnityEngine.Vector3(cd2d.pointB.x, cd2d.pointB.y, 0)
					-- local a = self.collider.gameObject.transform.position
					-- local b = k.gameObject.transform.position
					-- local normal =  -CS.UnityEngine.Vector3(cd2d.normal.x, cd2d.normal.y, 0)
					-- local normal = -menseki.normalized
					-- local c = a +  normal
					-- local d = b +  normal
	 				-- CS.UnityEngine.Debug.DrawLine(a, c, CS.UnityEngine.Color.red)
					-- CS.UnityEngine.Debug.DrawLine(b, d, CS.UnityEngine.Color.yellow)
					-- print(normal)

					-- ����ײ�������н�����ĵ��
					-- local projection = CS.UnityEngine.Vector2.Dot(velocity.normalized, normal) -- û�õ�������Ҫ�����Լ��������

					local offset_x = 0
					local offset_z = 0

					local velo_nor = CS.UnityEngine.Vector2(velocity.x, velocity.z).normalized

					-- ���ƣ�����
					if self.collider2.bounds.center.x < k.bounds.center.x then
						if left and CS.UnityEngine.Vector2.Dot(velo_nor, CS.UnityEngine.Vector2(-1, 0)) <= 0 then -- �����ײ�������н������෴�������λ������
							offset_x = -menseki.x
						end
					else
						if right and CS.UnityEngine.Vector2.Dot(velo_nor, CS.UnityEngine.Vector2(1, 0)) <= 0 then
							offset_x = menseki.x
						end
					end
					-- ���ƣ�����
					if self.collider2.bounds.center.y > k.bounds.center.y then
						if up and CS.UnityEngine.Vector2.Dot(velo_nor, CS.UnityEngine.Vector2(0, 1)) <= 0 then
							-- offset_z = menseki.y - (self.collider2.bounds.center.z - k.bounds.center.z)
							offset_z = menseki.y
						end
					else
						if down and CS.UnityEngine.Vector2.Dot(velo_nor, CS.UnityEngine.Vector2(0, -1)) <= 0 then
							-- offset_z = -(menseki.y + (self.collider2.bounds.center.z - k.bounds.center.z))
							offset_z = -menseki.y
						end
					end

					-- if (left or right) and (up or down) then
					-- 	local a_x = math.abs(normal.x)
					-- 	local a_z = math.abs(normal.y)
					-- 	if a_x > a_z then
					-- 		offset_x = 0
					-- 	else
					-- 		offset_z = 0
					-- 	end
					-- end

					if (left or right) and (up or down) then
						if menseki.x > menseki.y then
							offset_x = 0
						else
							offset_z = 0
						end
					end


					-- ������Сλ������
					if velocity.x > 0 then
						if offset_x < finalOffset_x then
							finalOffset_x = offset_x
						end
					else
						if offset_x > finalOffset_x then
							finalOffset_x = offset_x
						end
					end

					if velocity.z > 0 then
						if offset_z < finalOffset_z then
							finalOffset_z = offset_z
						end
					else
						if offset_z > finalOffset_z then
							finalOffset_z = offset_z
						end
					end

	-- 				if velocity.x ~= 0 and object2 ~= nil and offset_x ~= 0 and object2.isWall == false then
	-- 					local rate = weight / object2["weight"] / 2
	-- 					if rate > 1 then
	-- 						rate = 1
	-- 					end
	-- 					local vOffset = (object2.velocity.x - velocity.x) * rate
	-- --~ 					object2.velocity.x = object2.velocity.x - vOffset
	-- 					-- print(object2)
	-- 					object2:invokeEvent("onForce", {velocity = CS.UnityEngine.Vector2(-vOffset, 0), compute = 1})
	-- 				end

					-- if go.name == "test" then -- �ж��ǲ���ײ�����棬����д���ã��Ժ����Ż�
					-- 	-- if finalOffset_x ~= 0 and (normal.x == -1 or normal.x == 1) then
					-- 	-- 	isWall = true
					-- 	-- end
					-- 	if finalOffset_y > 0 then
					-- 		local id = string.match(k.name, "%[(%d+)%]")

					-- 		if id then
					-- 			if isGround ~= nil then
					-- 				isGround = isGround | 1 << tonumber(id)
					-- 			else
					-- 				isGround = 1 << tonumber(id)
					-- 			end
					-- 		end

					-- 	-- elseif finalOffset_y < 0 then
					-- 	-- 	isCeiling = true
					-- 	end
					-- end
				end
			else
				-- local id = string.match(k.name, "%[(%d+)%]")
				-- if id then
				-- 	isElse = isElse | 1 << tonumber(id)
				-- end
				-- if elseArray[id] == nil then
				-- 	elseArray[id] = {}
				-- end
				-- elseArray[id][k:GetInstanceID()] = k
			end
		end
	end

	
	-- -- ����ʲô����2d��ײ��Χһ���ʵ��Ҫ����ΪAABBҪ��һ�㣬Ϊ�˾�ȷ��ײ����Ҫ�Լ�ʵ��
	-- local contactColliders = CS.Tools.Instance:Collider2DOverlapCollider(self.collider2, self.filter) -- ���������ʵCollider2D.OverlapCollider�������ֶ������ײ�������Ϊlua��Ե�ʷ�װ��һ��

	-- -- ����λ������
	-- local finalOffset_x = 0
	-- local finalOffset_z = 0
	-- for p, k in pairs(contactColliders) do

	-- 	if self.collider2.bounds:Intersects(k.bounds) then

	-- 		local up, down, left, right = false, false, false, false

	-- 		-- local go = k.attachedRigidbody.gameObject
	-- 		local go = k.gameObject.transform.parent.gameObject
	-- 		local object2 = utils.getObject(go:GetInstanceID())
	-- 		-- if go.name == "test" then -- ����ǵ�ͼ��
	-- 		if string.find(go.name, "block") ~= nil then
	-- 			-- print(go.name)
	-- 			local name = utils.split(go.name, ",")
	-- 			local num = tonumber(name[#name]) -- ��ͼ�����һ��������Ϊbit


	-- 			if num & 1 == 1 then --λ���������������鳯�ĸ����������ײ��һ����������ж����ײ�����ⲿ��������ƣ�ֻ��Ҫ��֪�����collider���ж�������layermaskʲô����
	-- 				up = true
	-- 			end
	-- 			if num & 2 == 2 then --λ����
	-- 				down = true
	-- 			end
	-- 			if num & 4 == 4 then --λ����
	-- 				left = true
	-- 			end
	-- 			if num & 8 == 8 then --λ����
	-- 				right = true
	-- 			end
	-- 			-- print("aaa")
	-- 		elseif not string.find(go.name, "block") ~= nil and object2 ~= nil and not object2["isCatched"] and self.collider.attachedRigidbody.gameObject ~= go then -- ����Ϸobject����ֻ�������ҽ�����ײ

	-- 			-- local LC = object2.bodyArray_InstanceID[k:GetInstanceID()]

	-- 			-- print(LC.layers)
	-- 			-- if not string.find(LC.layers, string.match(self.collider2.name, "%[(%d+)%]")) then
	-- 				up = true
	-- 				down = true
	-- 				left = true
	-- 				right = true
	-- 			-- end

	-- 		else
	-- 			-- return 1, false, false, 1, elseArray
	-- 		end

	-- 		if up or down or left or right then


	-- 			local menseki, normal = utils.getBoundsIntersectsArea3D(self.collider2.bounds, k.bounds)
	-- 			if menseki.magnitude > 0 then -- ���Ӷ����������

	-- 				-- ��2��collider֮����룬��Ҫ��Ϊ�˷���
	-- 				-- local cd2d = self.collider2:Distance(k)

	-- --~ 				local a =  CS.UnityEngine.Vector3(cd2d.pointA.x, cd2d.pointA.y, 0)
	-- --~ 				local b =  CS.UnityEngine.Vector3(cd2d.pointB.x, cd2d.pointB.y, 0)
	-- 				-- local normal =  -CS.UnityEngine.Vector3(cd2d.normal.x, cd2d.normal.y, 0)
	-- --~ 				CS.UnityEngine.Debug.DrawLine(a, a + normal, CS.UnityEngine.Color.red)
	-- --~ 				CS.UnityEngine.Debug.DrawLine(b, b + normal, CS.UnityEngine.Color.yellow)

	-- 				-- ����ײ�������н�����ĵ��
	-- 				-- local projection = CS.UnityEngine.Vector2.Dot(velocity.normalized, normal) -- û�õ�������Ҫ�����Լ��������

	-- 				local offset_x = 0
	-- 				local offset_z = 0

	-- 				local velo_nor = CS.UnityEngine.Vector2(velocity.x, velocity.z).normalized

	-- 				-- ���ƣ�����
	-- 				if self.collider2.bounds.center.x < k.bounds.center.x then
	-- 					if left and CS.UnityEngine.Vector2.Dot(velo_nor, CS.UnityEngine.Vector2(-1, 0)) <= 0 then -- �����ײ�������н������෴�������λ������
	-- 						offset_x = -menseki.x
	-- 					end
	-- 				else
	-- 					if right and CS.UnityEngine.Vector2.Dot(velo_nor, CS.UnityEngine.Vector2(1, 0)) <= 0 then
	-- 						offset_x = menseki.x
	-- 					end
	-- 				end
	-- 				-- ���ƣ�����
	-- 				if self.collider2.bounds.center.y > k.bounds.center.y then
	-- 					if up and CS.UnityEngine.Vector2.Dot(velo_nor, CS.UnityEngine.Vector2(0, 1)) <= 0 then
	-- 						offset_z = menseki.y
	-- 					end
	-- 				else
	-- 					if down and CS.UnityEngine.Vector2.Dot(velo_nor, CS.UnityEngine.Vector2(0, -1)) <= 0 then
	-- 						offset_z = -menseki.y
	-- 					end
	-- 				end



	-- 				-- if (up or down) and (left or right) then -- ���ͬʱ�������º����ҷ���ͬʱ���ڵ�������������ײ������ɸѡ����һ�����λ��
	-- 				-- 	offset_x = offset_x * math.abs(normal.x)
	-- 				-- 	offset_z = offset_z * math.abs(normal.z)
	-- 				-- end

	-- 				if (left or right) and (up or down) then
	-- 					local a_x = math.abs(normal.x)
	-- 					local a_z = math.abs(normal.y)
	-- 					if a_x < a_z then
	-- 						offset_x = 0
	-- 					else
	-- 						offset_z = 0
	-- 					end
	-- 				end



	-- 				-- ������Сλ������
	-- 				if velocity.x > 0 then
	-- 					if offset_x < finalOffset_x then
	-- 						finalOffset_x = offset_x
	-- 					end
	-- 				else
	-- 					if offset_x > finalOffset_x then
	-- 						finalOffset_x = offset_x
	-- 					end
	-- 				end

	-- 				if velocity.z > 0 then
	-- 					if offset_z < finalOffset_z then
	-- 						finalOffset_z = offset_z
	-- 					end
	-- 				else
	-- 					if offset_z > finalOffset_z then
	-- 						finalOffset_z = offset_z
	-- 					end
	-- 				end

	-- 				-- print(finalOffset_x, finalOffset_z)

	-- -- 				if velocity.x ~= 0 and object2 ~= nil and offset_x ~= 0 and object2.isWall == false then
	-- -- 					local rate = weight / object2["weight"] / 2
	-- -- 					if rate > 1 then
	-- -- 						rate = 1
	-- -- 					end
	-- -- 					local vOffset = (object2.velocity.x - velocity.x) * rate
	-- -- --~ 					object2.velocity.x = object2.velocity.x - vOffset
	-- -- 					-- print(object2)
	-- -- 					object2:invokeEvent("onForce", {velocity = CS.UnityEngine.Vector2(-vOffset, 0), compute = 1})
	-- -- 				end
	-- 			end
	-- 		else
	-- 			-- local id = string.match(k.name, "%[(%d+)%]")
	-- 			-- if id then
	-- 			-- 	isElse = isElse | 1 << tonumber(id)
	-- 			-- end
	-- 			-- if elseArray[id] == nil then
	-- 			-- 	elseArray[id] = {}
	-- 			-- end
	-- 			-- elseArray[id][k:GetInstanceID()] = k
	-- 		end
	-- 	end
	-- end

	-- ��������λ��
	-- self.collider2.attachedRigidbody.position = self.collider2.attachedRigidbody.position + CS.UnityEngine.Vector3(finalOffset_x, 0, finalOffset_z)
	-- self.collider2.attachedRigidbody.position = self.collider2.attachedRigidbody.position + CS.UnityEngine.Vector3(finalOffset_x, 0, finalOffset_z)

	return isGround, isCeiling, isWall, isElse, elseArray, CS.UnityEngine.Vector3(finalOffset_x, 0, finalOffset_z)
end

LColliderATK = {damage = nil, frequency = nil, velocity = nil, fall = nil, defence = nil, ignoreObjects = nil, var = nil, isCatch = nil, action = nil, frame = nil}
setmetatable(LColliderATK, LCollider)
LColliderATK.__index = LColliderATK
function LColliderATK:new(go, id)
	local self = {}
	self = LCollider:new(go, id)
	setmetatable(self, LColliderATK)


	self.frequency = nil
	self.damage = nil
	self.velocity = nil

	self.fall = nil
	self.defence = nil
	self.ignoreObjects = {}
	
	self.var = nil

	self.isCatch = nil
	self.action = nil
	self.frame = nil

	return self
end

-- ����collider
function LColliderATK:setCollider(dir, x, y, width, height, flag, dmg, fal, def, f, dx, dy, ignoreFlag, v, action, frame)
	self.offset = CS.UnityEngine.Vector3((x + width / 2) / 100, -(y + height / 2) / 100, 0)
	self.size = CS.UnityEngine.Vector3(width / 100, height / 100, width / 100)
	self.collider.center = self.offset-- * dir
	self.collider.size = self.size

	self.filter = CS.UnityEngine.ContactFilter2D()
	self.filter.useLayerMask = true
	self.filter.useTriggers = true
	local lll = CS.UnityEngine.LayerMask()
	lll.value = lll.value | 1 << 16
	self.filter.layerMask = lll
	self.collider.isTrigger = true

	self.damage = dmg
	self.fall = fal
	self.defence = def
	self.frequency = f
	self.velocity = CS.UnityEngine.Vector2(dx, dy)

	if ignoreFlag then
		self.ignoreObjects = {}
	end

	self.var = v

	if flag then
		if flag & 1 == 1 then
			self.isDefence = true
		end
		if flag & 2 == 2 then
			self.isCatch = true
		end
	end
	self.action = action
	self.frame = frame
end

-- ��⹥��
function LColliderATK:ATKFixedUpdate(dir, myObj)
	local ishit = false

	if self.frequency > 0 then -- �������Ϊ0��ʱ��ֻ�Զ��󹥻�һ��
		for i, v in pairs(self.ignoreObjects) do
			v.count = v.count + 1
		end
	end

	local contactColliders = CS.Tools.Instance:Collider2DOverlapCollider(self.collider, self.filter)

	for p, k in pairs(contactColliders) do
		local iId = k.attachedRigidbody.gameObject:GetInstanceID()
		local object = utils.getObject(iId)
		if k.isTrigger and self.collider.bounds:Intersects(k.bounds) and object ~= myObj then -- ��trigger���ཻ�������Լ�
			if self.ignoreObjects[iId] == nil or self.ignoreObjects[iId].count >= self.frequency then -- ������ں����б��������Ѿ������������
				if object ~= nil then

					local s = false


					local cd2d = self.collider:Distance(k)
					local sparkPosition = CS.UnityEngine.Vector2(cd2d.pointA.x + cd2d.pointB.x, cd2d.pointA.y + cd2d.pointB.y) / 2

					local menseki = utils.getBoundsIntersectsArea(self.collider.bounds, k.bounds)

					local LC = object.bodyArray_InstanceID[k:GetInstanceID()]

					if LC.isDefence and object.direction.x ~= dir.x and not self.isDefence then -- �Է�����״̬�Ҳ��Ǵӱ��󹥻�����һ�����Ƿ������ɵõ�
						
						if object["defencing"] + self.defence >= 70 or object["HP"] - self.damage <= 0 then -- �����һ���Ʒ��˻��߶Է�����
							if self.isCatch then
								-- object.vars["isCatched"] = true

								-- object.vars["defencing"] = object.vars["defencing"] + self.defence
								-- if object.vars["defencing"] > object.vars["maxDefencing"] then
								-- 	object.vars["defencing"] = object.vars["maxDefencing"]
								-- end
								-- table.insert(myObj.catchedObjects, object)

								-- object:addEvent("Object", 0, 1, {isWorldPosition = true, x = sparkPosition.x + math.random() * menseki.x / 2 - menseki.x / 4, y = sparkPosition.y + math.random() * menseki.x / 2 - menseki.y / 4, action = "spark_4", frame = 0, kind = 3})

								-- myObj:addEvent("Attack", 0, 1, {id = self.id, x = 0, y = 0, width = 0, height = 0})
								
								-- myObj:addEvent("Warp", 0, 1, {action = self.action, frame = self.frame})
								-- s = true
							else
								if object["falling"] + self.fall >= 70 then
									object:invokeEvent("onObject", {isWorldPosition = true, x = sparkPosition.x + math.random() * menseki.x / 2 - menseki.x / 4, y = sparkPosition.y + math.random() * menseki.x / 2 - menseki.y / 4, action = "spark_b", frame = 0, kind = 3})
								else
									object:invokeEvent("onObject", {isWorldPosition = true, x = sparkPosition.x + math.random() * menseki.x / 2 - menseki.x / 4, y = sparkPosition.y + math.random() * menseki.x / 2 - menseki.y / 4, action = "spark", frame = 0, kind = 3})
								end
								object:invokeEvent("onHurt", {damage = self.damage, fall = self.fall, defence = self.defence, attacker = myObj, var = self.var})
								object:invokeEvent("onForce", {velocity = self.velocity * dir, compute = 0})
								object:invokeEvent("onInjured", {dir = dir.x})
							end
						else
							object:invokeEvent("onObject", {isWorldPosition = true, x = sparkPosition.x + math.random() * menseki.x / 2 - menseki.x / 2, y = sparkPosition.y + math.random() * menseki.x / 2 - menseki.y / 4, action = "spark_3", frame = 0, kind = 3})
							object:invokeEvent("onHurt", {damage = self.damage / 100, fall = 0, defence = self.defence, attacker = myObj, var = self.var})
							object:invokeEvent("onForce", {velocity = self.velocity * dir / 10, compute = 0})
						end
						
					else
						if self.isCatch then
							-- object.vars["isCatched"] = true

							-- table.insert(myObj.catchedObjects, object)

							-- object:addEvent("Object", 0, 1, {isWorldPosition = true, x = sparkPosition.x + math.random() * menseki.x / 2 - menseki.x / 4, y = sparkPosition.y + math.random() * menseki.x / 2 - menseki.y / 4, action = "spark_4", frame = 0, kind = 3})

							-- myObj:addEvent("Attack", 0, 1, {id = self.id, x = 0, y = 0, width = 0, height = 0})
							
							-- myObj:addEvent("Warp", 0, 1, {action = self.action, frame = self.frame})
							-- s = true
						else
							-- if object.vars["falling"] + self.fall >= 70 or object.vars["HP"] - self.damage <= 0 then
							-- 	object:addEvent("Object", 0, 1, {isWorldPosition = true, x = sparkPosition.x + math.random() * menseki.x / 2 - menseki.x / 4, y = sparkPosition.y + math.random() * menseki.x / 2 - menseki.y / 4, action = "spark_b", frame = 0, kind = 3})
							-- else
							-- 	object:addEvent("Object", 0, 1, {isWorldPosition = true, x = sparkPosition.x + math.random() * menseki.x / 2 - menseki.x / 4, y = sparkPosition.y + math.random() * menseki.x / 2 - menseki.y / 4, action = "spark", frame = 0, kind = 3})
							-- end

							-- object:addEvent("Hurt", 0, 1, {damage = self.damage, fall = self.fall, defence = 0, attacker = myObj, var = self.var})
							-- object:addEvent("Force", 0, 1, {velocity = self.velocity * dir, compute = 0})
							-- object:addEvent("Injured", 0, 1, {dir = dir.x})

							if object["falling"] + self.fall >= 70 or object["HP"] - self.damage <= 0 then
								object:invokeEvent("onObject", {isWorldPosition = true, x = sparkPosition.x + math.random() * menseki.x / 2 - menseki.x / 4, y = sparkPosition.y + math.random() * menseki.x / 2 - menseki.y / 4, action = "spark_b", frame = 0, kind = 3})
							else
								object:invokeEvent("onObject", {isWorldPosition = true, x = sparkPosition.x + math.random() * menseki.x / 2 - menseki.x / 4, y = sparkPosition.y + math.random() * menseki.x / 2 - menseki.y / 4, action = "spark", frame = 0, kind = 3})
							end

							object:invokeEvent("onHurt", {damage = self.damage, fall = self.fall, defence = 0, attacker = myObj, var = self.var})
							object:invokeEvent("onForce", {velocity = self.velocity * dir, compute = 0})
							object:invokeEvent("onInjured", {dir = dir.x})
						end
					end

					ishit = true

					if self.ignoreObjects[iId] == nil then
						self.ignoreObjects[iId] = {count = 0}
					else
						self.ignoreObjects[iId].count = 0
					end

					if s then
						break
					end
				end
			end
		end
	end


	return ishit
end


