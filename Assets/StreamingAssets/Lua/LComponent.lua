local ecs = require "ecs"

-- 注册组件
ecs.registerComponent("Active", 0, nil, nil)

-- 注册组件
ecs.registerComponent("DataBase", 0, function(self, id)
    self.database = utils.getIDData(id)
    self.id = id

    -- self.root = self
    -- self.parent = self
    -- self.children = {}

    self.direction = {x = 1, y = -1, z = 1}

    self.runSpeed = {x = 1, y = 0, z = 1}

    self.HP = 250
    self.maxHP = 500
    self.MP = 250
    self.maxMP = 500
end, function (self)
    self.database = nil
    self.id = nil

    -- self.root = nil
    -- self.parent = nil
    -- self.children = nil

    self.direction = nil

    self.runSpeed = nil

    self.HP = nil
    self.maxHP = nil
    self.MP = nil
    self.maxMP = nil
end)

ecs.registerComponent("Sleep", ecs.allOf("Active"), function(self)
    self.sleep = false
end, function (self)
    self.sleep = nil
end)

ecs.registerComponent("SpriteRenderer", ecs.allOf("DataBase"), function(self)
    self.pic_offset_object = CS.UnityEngine.GameObject("pic_offset")
    self.pic_offset_object_id = self.pic_offset_object:GetInstanceID()
    CS.LuaUtil.AddGameObjectID(self.pic_offset_object_id, self.pic_offset_object)
    CS.LuaUtil.SetlocalScale(self.pic_offset_object_id, 2, 2, 2)

    self.pic_object = CS.UnityEngine.GameObject("pic")
    self.pic_object_id = self.pic_object:GetInstanceID()
    CS.LuaUtil.AddGameObjectID(self.pic_object_id, self.pic_object)
    self.pic_object.transform:SetParent(self.pic_offset_object.transform, false)
    self.spriteRenderer = self.pic_object:AddComponent(typeof(CS.UnityEngine.SpriteRenderer))
    self.spriteRenderer.material = self.database.palettes[1]

    self.spriteRenderer.shadowCastingMode = CS.UnityEngine.Rendering.ShadowCastingMode.On

    self.rotation = 0
    self.rotation_velocity = 0
end, function (self)
    CS.UnityEngine.GameObject.Destroy(self.pic_offset_object)
    self.pic_offset_object = nil
    CS.LuaUtil.RemoveGameObjectID(self.pic_offset_object_id)
    self.pic_offset_object_id = nil
    CS.UnityEngine.GameObject.Destroy(self.pic_object)
    self.pic_object = nil
    CS.LuaUtil.RemoveGameObjectID(self.pic_object_id)
    self.pic_object_id = nil
    self.spriteRenderer = nil

    self.rotation = nil
    self.rotation_velocity = nil
end)

ecs.registerComponent("SpineRenderer", ecs.allOf("DataBase"), function(self, name)
    self.spine_offset_object = CS.UnityEngine.GameObject("spine_offset")
    self.spine_offset_object_id = self.spine_offset_object:GetInstanceID()
    CS.LuaUtil.AddGameObjectID(self.spine_offset_object_id, self.spine_offset_object)
    CS.LuaUtil.SetlocalScale(self.spine_offset_object_id, 2, 2, 2)

    self.skeletonAnimation = CS.Spine.Unity.SkeletonAnimation.NewSkeletonAnimationGameObject(self.database.spines[name])

    if name == "girl" then
        self.bone = self.skeletonAnimation.Skeleton:FindBone("crosshair")

        -- print(self.bone.Data.Name, self.bone.ScaleX, self.bone.ScaleY)
    end

    self.skeletonAnimation.enabled = false
    -- Extra Stuff
    self.skeletonAnimation:Initialize(false)
    -- self.skeletonAnimation.Skeleton:SetSkin("base")
    self.skeletonAnimation.Skeleton:SetSlotsToSetupPose()
    if name == "girl" then
        self.skeletonAnimation.AnimationState:SetAnimation(0, "idle", true)
    end
    -- self.skeletonAnimation:GetComponent(typeof(CS.UnityEngine.MeshRenderer)).sortingOrder = 10
    -- self.skeletonAnimation.transform.Translate(Vector3.down * 2)

    self.pic_object = self.skeletonAnimation.gameObject
    self.pic_object.name = "spine"
    self.pic_object_id = self.pic_object:GetInstanceID()
    CS.LuaUtil.AddGameObjectID(self.pic_object_id, self.pic_object)
    self.pic_object.transform:SetParent(self.spine_offset_object.transform, false)

    self.meshRenderer = self.pic_object:GetComponent(typeof(CS.UnityEngine.MeshRenderer))
    -- self.meshRenderer.sortingOrder = 10

    self.requiresNewMesh = true
end, function (self)
    CS.UnityEngine.GameObject.Destroy(self.spine_offset_object)
    self.spine_offset_object = nil
    CS.LuaUtil.RemoveGameObjectID(self.spine_offset_object_id)
    self.spine_offset_object_id = nil
    CS.UnityEngine.GameObject.Destroy(self.pic_object)
    self.pic_object = nil
    CS.LuaUtil.RemoveGameObjectID(self.pic_object_id)
    self.pic_object_id = nil
    self.skeletonAnimation = nil

    self.meshRenderer = nil

    self.requiresNewMesh = nil
end)

ecs.registerComponent("SkeletonRenderSeparator", ecs.allOf("SpineRenderer"), function(self)

    -- self.skeletonRenderSeparator = CS.Spine.Unity.Modules.SkeletonRenderSeparator.AddToSkeletonRenderer(self.skeletonAnimation, 0, 0, 5, 5)

    self.skeletonRenderSeparator = self.pic_object:AddComponent(typeof(CS.Spine.Unity.Modules.SkeletonRenderSeparator))
    self.skeletonRenderSeparator.SkeletonRenderer  = self.skeletonAnimation

    local t = {}
    table.insert(t, "hand1")
    table.insert(t, "leg2")
    self.skeletonAnimation.separatorSlotNames = t

    self.skeletonAnimation.separatorSlots:Clear()
    for i = 1, self.skeletonAnimation.separatorSlotNames.Length, 1 do
        self.skeletonAnimation.separatorSlots:Add(self.skeletonAnimation.Skeleton:FindSlot(self.skeletonAnimation.separatorSlotNames[i - 1]))


        -- print(i, self.skeletonAnimation.separatorSlotNames[i - 1])
    end

    -- self.skeletonRenderSeparator = CS.Spine.Unity.Modules.SkeletonRenderSeparator.AddToSkeletonRenderer(self.skeletonAnimation, 0, 0, 5, 5)


    -- self.skeletonAnimation:Initialize(false)

    self.skeletonRenderSeparator:AddPartsRenderer(1)
    self.skeletonRenderSeparator:AddPartsRenderer(1)
    self.skeletonRenderSeparator:AddPartsRenderer(1)

    self.skeletonRenderSeparator.enabled = true


end, function (self)
    CS.UnityEngine.GameObject.Destroy(self.skeletonRenderSeparator)
    self.skeletonRenderSeparator = nil
end)

ecs.registerComponent("ShadowRenderer", ecs.allOf("SpriteRenderer"), function(self)
    self.shadow_offset_object = CS.UnityEngine.GameObject("shadow_offset")
    self.shadow_offset_object_id = self.shadow_offset_object:GetInstanceID()
    CS.LuaUtil.AddGameObjectID(self.shadow_offset_object_id, self.shadow_offset_object)
    CS.LuaUtil.SetlocalScale(self.shadow_offset_object_id, 2, 2, 2)

    self.shadow_object = CS.UnityEngine.GameObject("shadow")
    self.shadow_object_id = self.shadow_object:GetInstanceID()
    CS.LuaUtil.AddGameObjectID(self.shadow_object_id, self.shadow_object)
    self.shadow_object.transform:SetParent(self.shadow_offset_object.transform, false)
    self.shadowRenderer = self.shadow_object:AddComponent(typeof(CS.UnityEngine.SpriteRenderer))
    self.shadowRenderer.material = utils.getShadowMaterial()
end, function (self)
    CS.UnityEngine.GameObject.Destroy(self.shadow_offset_object)
    self.shadow_offset_object = nil
    CS.LuaUtil.RemoveGameObjectID(self.shadow_offset_object_id)
    self.shadow_offset_object_id = nil
    CS.UnityEngine.GameObject.Destroy(self.shadow_object)
    self.shadow_object = nil
    CS.LuaUtil.RemoveGameObjectID(self.shadow_object_id)
    self.shadow_object_id = nil

    self.shadowRenderer = nil
end)

ecs.registerComponent("PointLight", 0, function(self)

    -- self.pointLight_offset_object = CS.UnityEngine.GameObject("pointLight_offset")
    -- self.pointLight_offset_object_id = self.shadow_offset_object:GetInstanceID()
    -- CS.LuaUtil.AddGameObjectID(self.pointLight_offset_object_id, self.pointLight_offset_object)
    -- CS.LuaUtil.SetlocalScale(self.pointLight_offset_object_id, 2, 2, 2)

    self.pointLight = self.pic_object:AddComponent(typeof(CS.UnityEngine.Experimental.Rendering.Universal.Light2D))
    self.pointLight.lightType = CS.UnityEngine.Experimental.Rendering.Universal.Light2D.LightType.Point
    self.pointLight.pointLightInnerRadius = 1
    self.pointLight.pointLightOuterRadius = 1

    -- self.pointLight.alphaBlendOnOverlap = true

end, function (self)
    -- CS.UnityEngine.GameObject.Destroy(self.pointLight_offset_object)
    -- self.pointLight_offset_object = nil
    -- CS.LuaUtil.RemoveGameObjectID(self.pointLight_offset_object_id)
    -- self.pointLight_offset_object_id = nil
end)

ecs.registerComponent("TrailRenderer", ecs.allOf("SpriteRenderer"), function(self)
	self.trailRenderer = self.pic_offset_object:AddComponent(typeof(CS.UnityEngine.TrailRenderer))
    -- self.trailRenderer.enabled = false
    self.trailRenderer.time = 1 / 50 * 2
	self.trailRenderer.shadowCastingMode = CS.UnityEngine.Rendering.ShadowCastingMode.Off
	self.trailRenderer.startWidth = 0.02
	self.trailRenderer.endWidth = 0.01
	-- self.trailRenderer.startColor = color
	-- self.trailRenderer.endColor = color
	self.trailRenderer.numCapVertices = 90
    self.trailRenderer.material = utils.LEGACYSHADERSPARTICLESALPHABLENDEDPREMULTIPLY
end, function (self)
    CS.UnityEngine.GameObject.Destroy(self.trail_object)
    self.trailRenderer = nil
end)

ecs.registerComponent("Image", ecs.allOf("DataBase"), function(this, parent)
    this.image_object = CS.UnityEngine.GameObject("image")
    -- this.image_object.transform:SetParent(this.UI_object.transform)
    -- this.image_object.transform.localPosition = CS.UnityEngine.Vector3.zero
    -- this.image_object.transform.localScale = CS.UnityEngine.Vector3.one

    -- local rectTransform = this.image_object:AddComponent(typeof(CS.UnityEngine.RectTransform))
    -- -- rectTransform.anchoredPosition = CS.UnityEngine.Vector2(x, y)
    -- -- rectTransform.sizeDelta = CS.UnityEngine.Vector2(w, h)
    -- rectTransform.anchorMin = CS.UnityEngine.Vector2(0.5, 0.5)
    -- rectTransform.anchorMax = CS.UnityEngine.Vector2(0.5, 0.5)
    -- rectTransform.pivot = CS.UnityEngine.Vector2(0.5, 0.5)

    this.image = this.image_object:AddComponent(typeof(CS.UnityEngine.UI.Image))
    this.image.sprite = nil
    this.image.material = this.database.palettes_ui[1]

    this.image.raycastTarget = false

    this.UI_object = this.image_object
    
    if parent == nil then
        this.UI_object.transform:SetParent(utils.getLCanvas().transform, false)
    else
        -- this.UI_object.transform:SetParent(p.transform)
        this.UI_object.transform:SetParent(parent.rectTransform, false)

        this.team = parent.team
        if this.image ~= nil then
            this.image.material = parent.image.material
        end
    end

    this.rectTransform = this.UI_object:GetComponent(typeof(CS.UnityEngine.RectTransform))
    -- this.rectTransform.anchoredPosition = CS.UnityEngine.Vector2(x, y)
    -- this.rectTransform.sizeDelta = CS.UnityEngine.Vector2(0, 0)
    -- this.rectTransform.anchorMin = CS.UnityEngine.Vector2(0.5, 0.5)
    -- this.rectTransform.anchorMax = CS.UnityEngine.Vector2(0.5, 0.5)
    -- this.rectTransform.pivot = CS.UnityEngine.Vector2(0, 1)
end, nil)

-- ecs.registerComponent("Sound", ecs.allOf("SpriteRenderer"), function(self)
--     self.audioSource = self.pic_offset_object:AddComponent(typeof(CS.UnityEngine.AudioSource))
--     self.audioSource.playOnAwake = false
-- end, function (self)
--     self.audioSource = nil
-- end)

ecs.registerComponent("Sound", 0, function(self) -- ecs.allOf("SpineRenderer")
    self.audioSource = self.pic_object:AddComponent(typeof(CS.UnityEngine.AudioSource))
    self.audioSource.playOnAwake = false
end, function (self)
    self.audioSource = nil
end)

ecs.registerComponent("Animation", 0, function(self, a)
    self.action = a

    self.accumulatedTime = 0

    self.delayCounter = 0
    self.timeLine = 0
    self.localTimeLine = 0

    self.speed = 1
end, function(self)
    self.action = nil

    self.accumulatedTime = nil

    self.delayCounter = nil
    self.timeLine = nil
    self.localTimeLine = nil

    self.speed = nil
end)

ecs.registerComponent("State", 0, function(self, s)
    self.state = s
end, function(self)
    self.state = nil
end)

ecs.registerComponent("Physics", 0, function(self, x, y, z, vx, vy, vz, t)
    self.physics_object = CS.UnityEngine.GameObject("physics")
    self.physics_object_id = self.physics_object:GetInstanceID()
    CS.LuaUtil.AddGameObjectID(self.physics_object_id, self.physics_object)
    -- self.physics_object.transform:SetParent(self.gameObject.transform)
    CS.LuaUtil.SetlocalScale(self.physics_object_id, 2, 2, 2)
    CS.LuaUtil.SetPos(self.physics_object_id, x, y, z)
    -- self.physics_object.transform.localPosition = CS.UnityEngine.Vector3.zero
    -- self.physics_object.transform.localScale = CS.UnityEngine.Vector3.one

    self.rigidbody = self.physics_object:AddComponent(typeof(CS.UnityEngine.Rigidbody))
    self.rigidbody.useGravity = false
    self.rigidbody.isKinematic = true
    -- self.rigidbody.detectCollisions = false
    self.rigidbody.freezeRotation = true

    self.velocity = {x = vx, y = vy, z = vz}
    -- self.velocity = CS.UnityEngine.Vector3(vx, vy, vz)


    self.team = t

    self.isOnGround = -1

    self.oriPos = {}
    self.oriPos.x, self.oriPos.y, self.oriPos.z = CS.LuaUtil.RigidbodyGetPosition(self.rigidbody)


    utils.addObject(self.physics_object:GetInstanceID(), self)
    utils.addObject(self, self.physics_object:GetInstanceID())
end, function(self)

    utils.deleteObject(self.physics_object:GetInstanceID())
    utils.deleteObject(self)

    CS.UnityEngine.GameObject.Destroy(self.physics_object)
    self.physics_object = nil
    CS.LuaUtil.RemoveGameObjectID(self.physics_object_id)
    self.physics_object_id = nil

    CS.UnityEngine.GameObject.Destroy(self.rigidbody)
    self.rigidbody = nil
    self.velocity = nil
    self.team = nil

    self.isOnGround = nil

    self.oriPos = nil
end)

ecs.registerComponent("ATK", ecs.allOf("Physics"), function(self)
    self.attckArray = {}
    self.atk_object = CS.UnityEngine.GameObject("atk")
    self.atk_object.transform:SetParent(self.physics_object.transform, false)
end, function(self)
    self.attckArray = nil
    CS.UnityEngine.GameObject.Destroy(self.attckArray)
end)

ecs.registerComponent("BDY", ecs.allOf("Physics"), function(self)
    self.bodyArray = {}
    self.bodyArray_InstanceID = {}

    self.bdy_object = CS.UnityEngine.GameObject("bdy")
    self.bdy_object.transform:SetParent(self.physics_object.transform, false)
    -- self.bdy_object.layer = 16 -- bdy的layer暂定16
end, function(self)
    self.bodyArray = nil
    CS.UnityEngine.GameObject.Destroy(self.bdy_object)
end)

ecs.registerComponent("LineRenderer", ecs.allOf("Physics"), function(self)
    self.line_object = CS.UnityEngine.GameObject("line_offset")
	self.lineRenderer = self.line_object:AddComponent(typeof(CS.UnityEngine.LineRenderer))
	-- self.lineRenderer.enabled = false
	self.lineRenderer.shadowCastingMode = CS.UnityEngine.Rendering.ShadowCastingMode.Off
	self.lineRenderer.startWidth = 0.01
	self.lineRenderer.endWidth = 0.02
	-- self.lineRenderer.startColor = color
	-- self.lineRenderer.endColor = color
	self.lineRenderer.numCapVertices = 90
    self.lineRenderer.material = utils.LEGACYSHADERSPARTICLESALPHABLENDEDPREMULTIPLY
end, function (self)
    CS.UnityEngine.GameObject.Destroy(self.line_object)
    self.lineRenderer = nil
end)

ecs.registerComponent("Parent", ecs.allOf("Physics"), function(self, parent, id)
    self.root = self
    self.parent = self

    utils.SetParentAndRoot(self, parent, id)
end, function (self)
    self.root = nil
    self.parent = nil
end)

ecs.registerComponent("Children", 0, function(self)
    self.children = {}
end, function (self)
    self.children = nil
end)

ecs.registerComponent("Player", 0, function(self)
    self.controller = utils.PLAYER
    self.AI = false
end, nil)

ecs.registerComponent("AI", ecs.allOf("DataBase"), function(self)
    self.controller = self.database.AI
    self.AI = true
end, nil)

ecs.registerComponent("Target", 0, function(self, t)
    self.target = t
end, nil)

ecs.registerComponent("Gravity", 0, function(self)
    local x, y, z = CS.LuaUtil.GetPhysicsGravity()
    z = -y
    y = 0
    self.gravity = {x = x, y = y, z = z}
end, function(self)
    self.gravity = nil
end)