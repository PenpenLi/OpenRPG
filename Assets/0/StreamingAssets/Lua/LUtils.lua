-- Tencent is pleased to support the open source community by making xLua available.
-- Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.
-- Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
-- http://opensource.org/licenses/MIT
-- Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
local json = require "json"
local utils = {}

utils.platform = "PC"
utils.resourcePath = CS.UnityEngine.Application.dataPath .. "/0/StreamingAssets/Resource/"
utils.resourcePathDataPath = CS.UnityEngine.Application.dataPath .. "/0/StreamingAssets/Resource/data/"
utils.resourcePathFontPath = CS.UnityEngine.Application.dataPath .. "/0/StreamingAssets/Resource/font/"

-- utils.platform = "WebGL"
-- utils.resourcePath = string.gsub("https://r5r6ty.github.io/OpenACT/Assets/0/StreamingAssets/Lua/", "Lua", "Resource")
-- utils.resourcePathDataPath = string.gsub("https://r5r6ty.github.io/OpenACT/Assets/0/StreamingAssets/Lua/", "Lua", "Resource/data")

local luaPath = CS.GameLoader.Getluapath()
if string.find(luaPath, "http") then
	utils.platform = "WebGL"
	utils.resourcePath = string.gsub(luaPath, "Lua", "Resource")
	utils.resourcePathDataPath = string.gsub(luaPath, "Lua", "Resource/data")
	utils.resourcePathFontPath = string.gsub(luaPath, "Lua", "Resource/font")
end

utils.ZOOM = 1
local LCanvas = nil

local myFont = "msmincho"
local LFont = nil
local LFontTexture2D = nil
local LFontMaterial = nil

-- local LObjectShader = CS.UnityEngine.Shader.Find("Sprites/Beat/Diffuse-Shadow")
-- local LObjectShader = CS.UnityEngine.Shader.Find("Tutorial/007_Sprite")
local LObjectShader = CS.UnityEngine.Shader.Find("Shader Graphs/New Shader Graph")
-- local LObjectShader = CS.UnityEngine.Shader.Find("Shader Graphs/New Shader Graph 1")

local LDatas = {}
local objects = {}

utils.CAMERA = nil
utils.PLAYER = nil
utils.CURSOR = nil
utils.LUABEHAVIOUR = nil
utils.SPRITESDEFAULT = CS.UnityEngine.Material(CS.UnityEngine.Shader.Find("Sprites/Default"))
utils.LEGACYSHADERSPARTICLESALPHABLENDEDPREMULTIPLY = CS.UnityEngine.Material(CS.UnityEngine.Shader.Find("Legacy Shaders/Particles/Alpha Blended Premultiply"))
local LSystem = nil

local hp = nil
local mp = nil
local black = nil
local white = nil
local yellow = nil
local gray = nil

local idLoop

-- �Ȳ���webgl�ˣ��ɶ񣬸㲻�ã�
utils.download = coroutine.create(function(path)
	local www = CS.UnityEngine.Networking.UnityWebRequest.Get(path)
	print(www.isDone, www.downloadProgress)
	coroutine.yield(www:SendWebRequest())

	
	coroutine.yield(www)
end)

-- ���ļ���ȡ�ı�
function utils.openFileText(path)
	local str = nil
	if utils.platform == "PC" then
		local file = io.open(path, "r")
		if file == nil then
			return nil
		end
		io.input(file)
		str = io.read("*a")
		io.close(file)
	else
		local stat, mainre = coroutine.resume(utils.download, path)
		while (not mainre.isDone) or (not stat) do
			if mainre.isNetworkError then
				print(mainre.error)
				return nil
			end
		end
		print(mainre.isDone, stat, mainre.downloadProgress)
		str = mainre.downloadHandler.text


		-- local www = CS.UnityEngine.WWW(path)
		-- while not www.isDone do
		-- 	if www.error ~= nil and www.error ~= "" then
		-- 		print(www.error)
		-- 		return nil
		-- 	end
		-- end
		-- str = www.text
	end
	return str
end

-- ���ļ���ȡ����
function utils.openFileBytes(path)
	local bytes = nil
	if utils.platform == "PC" then
		local file = io.open(path, "rb")
		if file == nil then
			return nil
		end
		io.input(file)
		bytes = io.read("*a")
		io.close(file)
	else
		local stat, mainre = coroutine.resume(utils.download, path)
		while (not mainre.isDone) or (not stat) do
			if mainre.isNetworkError then
				print(mainre.error)
				return nil
			end
		end
		bytes = mainre.downloadHandler.data
		-- local www = CS.UnityEngine.WWW(path)
		-- while not www.isDone do
		-- 	if www.error ~= nil and www.error ~= "" then
		-- 		print(www.error)
		-- 		return nil
		-- 	end
		-- end
		-- bytes = www.bytes
	end
	return bytes
end

-- idѭ��
function idLoop(id, s)
	for i, v in pairs(s) do
		if id == v.id then
			return false
		end
		if idLoop(id, v.guiParts) == false then
			return false
		end
	end
	return true
end

-- ����id����
function utils.createid(stack)
	local id = 0
	while id < 65535 do
		local judge = idLoop(id, stack)

		if judge then
			return id
		end

		id = id + 1
	end
	return nil
end

-- ��ȡ���ڲ���
function utils.getObject(id, s)
	for i, v in pairs(s) do
		if id == v.id then
			return v
		end
		for i2, v2 in pairs(v.guiParts) do
			if id == v2.id then
				return v
			end
		end
	end
	return nil
end

-- �ַ����ָ�
function utils.split(str, reps)
    local resultStrList = {}
    string.gsub(str, '[^'..reps..']+' ,function (w)
        table.insert(resultStrList, w)
    end)
    return resultStrList
end

-- �Ƚ��ַ���a�Ƿ������b���棨����Ҫ��ȣ�
function utils.isStringAContainB(a, b)
	if #a ~= #b then
		return false
	end
	local c = 0
	for i = 1, #a, 1 do
		local f = string.find(b, string.sub(a, i, i))
		if f ~= nil then
			c = c + 1
		end
	end
	if c == #b then
		return true
	end
	return false
end

-- ��ȡ����
function utils.loadfont()
    local str = utils.openFileText(utils.resourcePath .. "font/" .. myFont .. ".json")

    local temp = {}

    local start = 2
    local a = string.find(str, "},{", start)
    while a do
        table.insert(temp, string.sub(str, start, a))
        start = a + 2
        a = string.find(str, "},{", start)
    end
    a = string.find(str, "}]", start)
    table.insert(temp, string.sub(str, start, a))

    local CIs = {}

    for i = 1, #temp, 1 do
        local data = json.decode(temp[i])

        local CI = CS.UnityEngine.CharacterInfo()
        CI.advance = data.advance
        CI.bearing = data.bearing
        CI.glyphHeight = data.glyphHeight
        CI.glyphWidth = data.glyphWidth
        CI.index = data.index
        CI.maxX = data.maxX
        CI.maxY = data.maxY
        CI.minX = data.minX
        CI.minY = data.minY
        -- CI.size = data.size
        -- CI.style = data.style
        CI.uvBottomLeft = CS.UnityEngine.Vector2(data.uvBottomLeft.x, data.uvBottomLeft.y)
        CI.uvBottomRight = CS.UnityEngine.Vector2(data.uvBottomRight.x, data.uvBottomRight.y)
        CI.uvTopLeft = CS.UnityEngine.Vector2(data.uvTopLeft.x, data.uvTopLeft.y)
        CI.uvTopRight = CS.UnityEngine.Vector2(data.uvTopRight.x, data.uvTopRight.y)

        table.insert(CIs, CI)
    end

    local t2d = CS.UnityEngine.Texture2D(0, 0)
    t2d:LoadImage(utils.openFileBytes(utils.resourcePath .. "font/" .. myFont .. ".png"))
    t2d:Apply()

    LFontTexture2D = CS.UnityEngine.Texture2D(t2d.width, t2d.height, CS.UnityEngine.TextureFormat.Alpha8, false)
    LFontTexture2D.filterMode = CS.UnityEngine.FilterMode.Point
    LFontTexture2D:SetPixels(t2d:GetPixels())
    LFontTexture2D:Apply()

    LFontMaterial = CS.UnityEngine.Material(CS.UnityEngine.Shader.Find("GUI/Text Shader"))
    LFontMaterial.mainTexture = LFontTexture2D

    LFont = CS.UnityEngine.Font(myFont)
    LFont.characterInfo = CIs
    LFont.material = LFontMaterial
end

-- ��ȡ����2
function utils.loadfont2()
	LFont = CS.UnityEngine.Resources.Load("Fonts/" .. myFont, typeof(CS.UnityEngine.Font))
	LFontMaterial = LFont.material
	LFontTexture2D = LFont.material.mainTexture
	LFontTexture2D.filterMode = CS.UnityEngine.FilterMode.Point
end

-- ��ȡ����
function utils.getFont()
	return LFont
end

function utils.getShader()
	return LObjectShader
end

function utils.setLCanvas(cvs)
	LCanvas = cvs
end

function utils.getLCanvas()
	return LCanvas
end

function utils.setLSystem(p)
	LSystem = p
end

function utils.getLSystem()
	return LSystem
end

function utils.intNumberToString(num)
	if num == nil then
		return nil
	end
	return utils.split(tostring(num), ".")[1]
end

function utils.stringToIntNumber(str)
	local num = tonumber(str)
	if str == nil or str == "" or num == nil then
		return 0
	end
	local a, b = math.modf(num)
	return a
end

function utils.getRangeAB(str)
	if str == "" or str == nil then
		return nil, nil
	end
	local rA, rB = string.match(str, "(%-?%d+)~(%-?%d+)")
	return tonumber(rA), tonumber(rB)
end

function utils.getFrame(str)
	local action, frame = string.match(str, "(.+)-(%d+)")
	return action, tonumber(frame)
end

function utils.GetLDatas()
	return LDatas
end

function utils.getIDData(id)
	return LDatas[id]
end

function utils.setIDData(id, data)
	LDatas[id] = data
end

-- parent == LObject
function utils.createObject(parent, id, a, f, x, y, dx, dy, k)
	local character = CS.UnityEngine.GameObject(id .. " kind " .. k)
	character.transform.localScale = CS.UnityEngine.Vector3(2, 2, 1)
	if parent ~= nil then
		-- character.transform:SetParent(parent.gameObject.transform)
		-- character.transform.localPosition = CS.UnityEngine.Vector3(x, y, 0)
	else
		character.transform.position = CS.UnityEngine.Vector3(x, y, 0)
	end
	
	local o = nil
	if k == 5 then
		o = LObjectUI:new(parent, LDatas[id], id, a, f, character, dx, dy, k)
	else
		o = LCharacterObject:new(parent, LDatas[id], id, a, f, character, dx, dy, k)
	end
	local IID = character:GetInstanceID()
	utils.addObject(IID, o)
	return o, IID
end

function utils.toMaxvalue(v, maxV, rate)
	local r = v
	-- if canMinus == false and r < 0 then
	-- 	r = 0
	-- end
	if r < maxV then
		if r + maxV * rate * CS.UnityEngine.Time.deltaTime > maxV then
			r = maxV
		else
			r = r + maxV * rate * CS.UnityEngine.Time.deltaTime
		end
	end
	return r
end

function utils.toOne(v, maxV, rate)
	local r = v
	if r > maxV then
		r = maxV
	end
	if r > 1 then
		if r - maxV * rate * CS.UnityEngine.Time.deltaTime < 1 then
			r = 1
		else
			r = r - maxV * rate * CS.UnityEngine.Time.deltaTime
		end
	end
	return r
end

function utils.setPalette(o, n)
	o.palette = n
	o.spriteRenderer.material = o.database.palettes[n]
end

-- ȡ������ϼ�
function utils.getObjects()
	return objects
end

-- ȡ������
function utils.getObject(id)
	return objects[id]
end

-- �������
function utils.addObject(id, o)
	objects[id] = o
end

-- ��������
function utils.destroyObject(id)
	local o = objects[id]
	if o ~= nil then
		if o.kind == 5 then
			for i, v in pairs(o.UIArray) do
				if v.gameObject ~= nil then
					CS.UnityEngine.GameObject.Destroy(v.gameObject)
				end
			end
		end
		CS.UnityEngine.GameObject.Destroy(o.gameObject)
		objects[id] = nil
	else
		print("utils.destroyObject(id) --- object is nil!")
	end
end

-- ����Ѫ������
function utils.createHPMP()

	hp = CS.UnityEngine.Texture2D(1, 1, CS.UnityEngine.TextureFormat.RGBA32, false, false)
	hp.filterMode = CS.UnityEngine.FilterMode.Point
	hp:SetPixel(0, 0, CS.UnityEngine.Color(1, 0, 0))
	hp:Apply()

	mp = CS.UnityEngine.Texture2D(1, 1, CS.UnityEngine.TextureFormat.RGBA32, false, false)
	mp.filterMode = CS.UnityEngine.FilterMode.Point
	mp:SetPixel(0, 0, CS.UnityEngine.Color(0, 0, 1))
	mp:Apply()

	black = CS.UnityEngine.Texture2D(1, 1, CS.UnityEngine.TextureFormat.RGBA32, false, false)
	black.filterMode = CS.UnityEngine.FilterMode.Point
	black:SetPixel(0, 0, CS.UnityEngine.Color(0, 0, 0))
	black:Apply()

	white = CS.UnityEngine.Texture2D(1, 1, CS.UnityEngine.TextureFormat.RGBA32, false, false)
	white.filterMode = CS.UnityEngine.FilterMode.Point
	white:SetPixel(0, 0, CS.UnityEngine.Color(1, 1, 1))
	white:Apply()

	yellow = CS.UnityEngine.Texture2D(1, 1, CS.UnityEngine.TextureFormat.RGBA32, false, false)
	yellow.filterMode = CS.UnityEngine.FilterMode.Point
	yellow:SetPixel(0, 0, CS.UnityEngine.Color(1, 1, 0))
	yellow:Apply()

	gray = CS.UnityEngine.Texture2D(1, 1, CS.UnityEngine.TextureFormat.RGBA32, false, false)
	gray.filterMode = CS.UnityEngine.FilterMode.Point
	gray:SetPixel(0, 0, CS.UnityEngine.Color(0.5, 0.5, 0.5))
	gray:Apply()
end

-- ����Ѫ������
function utils.drawHPMP(x, y, h, m, f, d)
	local width = 50
	local height = 3
	local offset = 0
	if h > 0 and h < 1 then
		CS.UnityEngine.GUI.DrawTexture(CS.UnityEngine.Rect(x - width / 2 - 1, y - 1, width + 2, height + 2), white)
		CS.UnityEngine.GUI.DrawTexture(CS.UnityEngine.Rect(x - width / 2, y, width, height), black)
		CS.UnityEngine.GUI.DrawTexture(CS.UnityEngine.Rect(x - width / 2, y, width * h, height), hp)

		offset = offset + 6
	end

	if h > 0 then
		if m > 0 and m < 1 then
			CS.UnityEngine.GUI.DrawTexture(CS.UnityEngine.Rect(x - width / 2 - 1, y - 1 + offset, width + 2, height + 2), white)
			CS.UnityEngine.GUI.DrawTexture(CS.UnityEngine.Rect(x - width / 2, y + offset, width, height), black)
			CS.UnityEngine.GUI.DrawTexture(CS.UnityEngine.Rect(x - width / 2, y + offset, width * m, height), mp)

			offset = offset + 6
		end

		if f > 0.01 then
			CS.UnityEngine.GUI.DrawTexture(CS.UnityEngine.Rect(x - width / 2 - 1, y - 1 + offset, width + 2, height + 2), white)
			CS.UnityEngine.GUI.DrawTexture(CS.UnityEngine.Rect(x - width / 2, y + offset, width, height), black)
			if f >= 0.7 then
				CS.UnityEngine.GUI.DrawTexture(CS.UnityEngine.Rect(x - width / 2, y + offset, width * f, height), hp)
			else
				CS.UnityEngine.GUI.DrawTexture(CS.UnityEngine.Rect(x - width / 2, y + offset, width * f, height), yellow)
			end

			offset = offset + 6
		end


		if d > 0.01 then
			CS.UnityEngine.GUI.DrawTexture(CS.UnityEngine.Rect(x - width / 2 - 1, y - 1 + offset, width + 2, height + 2), white)
			CS.UnityEngine.GUI.DrawTexture(CS.UnityEngine.Rect(x - width / 2, y + offset, width, height), black)

			if d >= 0.7 then
				CS.UnityEngine.GUI.DrawTexture(CS.UnityEngine.Rect(x - width / 2, y + offset, width * d, height), hp)
			else
				CS.UnityEngine.GUI.DrawTexture(CS.UnityEngine.Rect(x - width / 2, y + offset, width * d, height), gray)
			end
		end
	end

end

function utils.displayObjectsInfo()
    for i, v in pairs(objects) do
		v:displayInfo()
	end
end

function utils.runObjectsFrame()
	for i, v in pairs(objects) do
		-- v:runEvent()
		v:runFrame()
		-- if v.AI then
		-- 	v.database.AI:judgeAI(v)
		-- end
	end
end

function utils.runObjectsFrame2()
	for i, v in pairs(objects) do
		v:runEvent2()
		-- v:runFrame()
		-- if v.AI then
		-- 	v.database.AI:judgeAI(v)
		-- end
	end
end

function utils.display()
	local num = 0
	for i, v in pairs(objects) do
		num = num + 1
	end
	CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(10, CS.UnityEngine.Screen.height - 56, 200, 20), "Objects: " .. num)
end

-- ���ַ���ȡ���ʽ�Ĳ��ԣ�������
function utils.calcValue(o, v)
	local vs, es = nil
	if tonumber(v) == nil then
		vs, es = utils.superSplit(v, "%p")
	else
		return utils.getValue(o, v)
	end

	local result = 0
	if #es > 0 then
		for p, k in ipairs(es) do
			local v1 = nil
			if p == 1 then
				v1 = utils.getValue(o, vs[p])
			else
				v1 = result
			end
			local v2 = utils.getValue(o, vs[p + 1])
			if k == "*" then
				result = v1 * v2
			elseif k == "/" then
				result = v1 / v2
			end
		end
	else
		result = utils.getValue(o, v)
	end
	return result
end

function utils.getValue(v)
	local result = v
	if tonumber(result) == nil and result ~= nil then
		local r = string.match(result, "%%(.+)%%")
		if r == nil then
			return result
		end
		local value = utils.split(r, ".")
		result = o.vars[value[1]]
		if result == nil then
			return 0
		end
		for i = 2, #value, 1 do
			result = result.vars[value[i]]
			if result == nil then
				return 0
			end
		end
		-- if tonumber(result) == nil then
		-- 	result = 0
		-- end
	end
	return result
end

function utils.superSplit(str, reps)
	
	local temp = {}
	local temp2 = {}

	local start = 1
    local a = string.find(str, reps, start)
	while a do

		

		local v = string.sub(str, start, a - 1)
		if v == "" then
			temp2[#temp2] = temp2[#temp2] .. string.sub(str, a, a)
		else
			table.insert(temp, v)
			if string.sub(str, a, a) == "." then
				table.insert(temp, string.sub(str, a, a))
			else
				table.insert(temp2, string.sub(str, a, a))
			end
		end
		
		
        start = a + 1
        a = string.find(str, reps, start)
	end
	table.insert(temp, string.sub(str, start, #str))

	local max = #temp
	local count = 1
	while count <= max do
		if temp[count] == "." then
			temp[count] = temp[count - 1] .. temp[count] .. temp[count + 1]
			table.remove(temp, count - 1)
			table.remove(temp, count)

			count = count - 2
			max = max - 2
		end
		count = count + 1
	end


	return temp, temp2
end
-- ���ַ���ȡ���ʽ�Ĳ��ԣ������ã��꣩

-- byteתint
function utils.bytesToInt(bytes, offset)
	local value = 0
	for i = 0, 3, 1 do
		value = value | (bytes[offset + i] << (i * 8))
	end
	return value
end

-- bytesתfloat
function utils.bytesToFloat(firstByte, secondByte)
	local s = ((secondByte << 8) | firstByte) / 32768
	if s > 1 then
		return -(2 - s)
	else
		return s
	end
end

-- ��.img����ͼƬ����texture2D
function utils.loadImageToTexture2D(b64str)
	local temp = string.match(b64str, "data:image/png;base64,(.+)")
	local mod4 = #temp % 4
	if mod4 > 0 then
		for i = 1, 4 - mod4, 1 do
			temp = temp .. "="
		end
	end

	local bytes = CS.System.Convert.FromBase64String(temp)

	-- ����ͼƬ
	local texture = CS.UnityEngine.Texture2D(0, 0, CS.UnityEngine.TextureFormat.RGBA32, false, false)
	texture.filterMode = CS.UnityEngine.FilterMode.Point
	-- CS.UnityEngine.ImageConversion.LoadImage(texture, bytes) -- �����ô�����ˣ�
	texture:LoadImage(bytes) --- Texture2d  ��Ա�����޷�ʹ�ã�Ϊʲô��Ϊʲô����ʹ���ˣ�

	return texture
end

function utils.drawField(cx, cy, cw, ch, subColor)
 	-- local subColor = mainColor
 	-- subColor.a = subColor.a - 0.5
	local scale = 100
	local x = cx / scale
	local y = cy / scale
	local w = cw / scale
	local h = ch / scale
	CS.UnityEngine.GL.PushMatrix()
	-- CS.UnityEngine.GL.LoadOrtho()

	CS.UnityEngine.GL.Begin(CS.UnityEngine.GL.QUADS)
	CS.UnityEngine.GL.Color(subColor)

	CS.UnityEngine.GL.Vertex3(x, -y, 0)
	CS.UnityEngine.GL.Vertex3(x + w, -y, 0)
	CS.UnityEngine.GL.Vertex3(x + w, -(y + h), 0)
	CS.UnityEngine.GL.Vertex3(x, -(y + h), 0)
	-- CS.UnityEngine.GL.End()

	-- CS.UnityEngine.GL.Begin(CS.UnityEngine.GL.LINES)
	-- CS.UnityEngine.GL.Color(mainColor)

	-- CS.UnityEngine.GL.Vertex3(x, y, 0)
	-- CS.UnityEngine.GL.Vertex3(x + w, y, 0)

	-- CS.UnityEngine.GL.Vertex3(x + w, y, 0)
	-- CS.UnityEngine.GL.Vertex3(x + w, y + h, 0)

	-- CS.UnityEngine.GL.Vertex3(x + w, y + h, 0)
	-- CS.UnityEngine.GL.Vertex3(x, y + h, 0)

	-- CS.UnityEngine.GL.Vertex3(x, y + h, 0)
	-- CS.UnityEngine.GL.Vertex3(x, y, 0)

	CS.UnityEngine.GL.End()
	CS.UnityEngine.GL.PopMatrix()
end

-- ���ཻbounds���
function utils.getBoundsIntersectsArea(lhs, rhs)
	local c = lhs.center - rhs.center
	local r = lhs.extents + rhs.extents

	local xxx = r - CS.UnityEngine.Vector3(math.abs(c.x), math.abs(c.y), math.abs(c.z))
	return xxx
end

function utils.createUnityObject(p, name, x, y, width, height)
	--    local unityobject = CS.UnityEngine.GameObject.CreatePrimitive(CS.UnityEngine.PrimitiveType.Quad)
	local unityobject = CS.UnityEngine.GameObject(name)
	unityobject.transform.parent = p.transform
	unityobject.transform.position = CS.UnityEngine.Vector3(x / 100, y / 100, 0)
	--    unityobject.transform.localScale = CS.UnityEngine.Vector3(width / 100, height / 100, 0)
	--    unityobject:AddComponent(typeof(CS.UnityEngine.RectTransform))
	--    local image = unityobject:AddComponent(typeof(CS.UnityEngine.UI.Image))
	--    image.rectTransform.sizeDelta = CS.UnityEngine.Vector2(width, height)
	--    CS.UnityEngine.Object.Destroy(unityobject:GetComponent(typeof(CS.UnityEngine.MeshCollider)))
	for i_y = 0, height - 1, 1 do
		for i_x = 0, width - 1, 1 do
			local unityobject_child = CS.UnityEngine.GameObject(block)
			unityobject_child.transform.parent = unityobject.transform
			unityobject_child.transform.localPosition = CS.UnityEngine.Vector3(i_x * tile_size / 100, -i_y * tile_size / 100, 0)
			local sr = unityobject_child:AddComponent(typeof(CS.UnityEngine.SpriteRenderer))
			sr.sprite = tile_sprite
		end
	end
	local bc2d = unityobject:AddComponent(typeof(CS.UnityEngine.BoxCollider2D))
	bc2d.offset = CS.UnityEngine.Vector2(width * 4 / 100 / 2, -height * 4 / 100 / 2)
	bc2d.size = CS.UnityEngine.Vector2(width * 4 / 100, height * 4 / 100)
	--    bc2d.enabled = false
	local f = CS.UnityEngine.PhysicsMaterial2D("test");
	f.friction = 0;
	bc2d.sharedMaterial = f
	local rb2d = unityobject:AddComponent(typeof(CS.UnityEngine.Rigidbody2D))
	rb2d.freezeRotation = true
	rb2d.gravityScale = 0
	rb2d.angularDrag = 1
	rb2d.drag = 1
	rb2d.interpolation = CS.UnityEngine.RigidbodyInterpolation2D.Interpolate
	rb2d.useAutoMass = true

	local script = unityobject:AddComponent(typeof(CS.XLuaTest.LuaBehaviour))
	script.scriptEnv.map_size.w = width
	script.scriptEnv.map_size.h = height
	return script
end
	
-- ȡ������
function utils.getIntPart(x)
	if x <= 0 then
		return math.ceil(x);
	end

	if math.ceil(x) == x then
		x = math.ceil(x);
	else
		x = math.ceil(x) - 1;
	end
	return x;
end

-- ������������
function utils.createLineTexture(tile_size, width, height)
	local line_texture = CS.UnityEngine.Texture2D(tile_size * width, tile_size * height, CS.UnityEngine.TextureFormat.RGBA32, false, false)
	line_texture.filterMode = CS.UnityEngine.FilterMode.Point
	for y = 0, height * tile_size, 1 do
		for x = 0, width * tile_size, 1 do
			if (x % tile_size == 0 or y % tile_size == 0) or (x % tile_size == tile_size - 1 or y % tile_size == tile_size - 1)  then
				line_texture:SetPixel(x, y, CS.UnityEngine.Color.red)
			else
				line_texture:SetPixel(x, y, CS.UnityEngine.Color.black)
			end
		end
	end
	line_texture:Apply()

	local line_texture_sprite = CS.UnityEngine.Sprite.Create(line_texture, CS.UnityEngine.Rect(0, 0, tile_size * width, tile_size * height), CS.UnityEngine.Vector2(0, 1))
	return line_texture_sprite
end

-- ��csv��ȡ���ݷ���DataTable
function utils.LoadTilesFromCSV(path)
	local dt = CS.System.Data.DataTable("test")

	local count = 0
	local sr = CS.System.IO.File.OpenText(path)
	local line = sr:ReadLine()
	while line ~= nil do
		local data = utils.split(line, ',')
		if count == 0 then -- ��һ����Ϊ��ͷ
			for i, v in ipairs(data) do
				dt.Columns:Add(CS.System.Data.DataColumn(v, typeof(CS.System.String)))
			end
		else -- ������Ϊ����
			local dr = dt:NewRow()
			for i, v in ipairs(data) do
				dr[i - 1] = v
			end
			dt.Rows:Add(dr)
		end
		line = sr:ReadLine()
		count = count + 1
	end
	sr:Close();
	sr:Dispose();

	--    print(dt.Rows.Count, dt.Columns.Count)

	--    for k = 0, dt.Rows.Count - 1, 1 do
	--        for j = 0, dt.Columns.Count - 1, 1 do
	--            print(dt.Rows[k][j]);
	--        end
	--    end
	return dt
end

-- ��·������ͼƬ����texture2D
function utils.LoadImageToTexture2DByPath(path)
	local bytes = utils.openFileBytes(path)
	-- ����ͼƬ
	local texture = CS.UnityEngine.Texture2D(0, 0, CS.UnityEngine.TextureFormat.RGBA32, false, false)
	texture.filterMode = CS.UnityEngine.FilterMode.Point
	CS.UnityEngine.ImageConversion.LoadImage(texture, bytes) -- �����ô�����ˣ�
	-- texture:LoadImage(bytes) --- Texture2d  ��Ա�����޷�ʹ�ã�Ϊʲô��Ϊʲô����ʹ���ˣ�
	return texture
end

-- ��texture2D����sprite�������Σ�
function utils.CreateSprite(texture2D, x, y, size)
	local sprite = CS.UnityEngine.Sprite.Create(texture2D, CS.UnityEngine.Rect(x * size, texture2D.height - (y + 1) * size, size, size), CS.UnityEngine.Vector2(1 - 16 / 16, 16 / 16)) -- ����Ҫע����Щ����Ĳ�
	return sprite
end

-- base64����TileLayer
-- ���������ݣ�����Ϊ��ͼ�ĳ�*��*2
-- ż��λ*����λ��0��65535
-- ���鳤��Ӧ���ǵ�ͼ�ĳ�*��
function utils.Base64DecodeToArray_Ground(str)
	-- ��C#�Դ��Ľ���API
	local bytes = CS.System.Convert.FromBase64String(str)
	--    print(#bytes)
	local array = {}
	for i = 1, #bytes, 2 do
		array[(i + 1) / 2] = string.byte(string.sub(bytes, i, i)) + string.byte(string.sub(bytes, i + 1, i + 1)) * 256
	--        print(string.byte(string.sub(bytes, i, i)), string.byte(string.sub(bytes, i + 1, i + 1)), i, i + 1, math.floor(((i - 1) / 2) % 50), math.floor(((i - 1) / 2) / 50))
	--        print(string.byte(string.sub(bytes, i, i)), string.byte(string.sub(bytes, i + 1, i + 1)))
	end
	return array
end

-- base64����DataLayer
-- 0��255
-- ���������ݣ�����Ϊ��ͼ�ĳ�*��
function utils.Base64DecodeToArray_TileMode(str)
	-- ��C#�Դ��Ľ���API
	local bytes = CS.System.Convert.FromBase64String(str)
	--    print(#bytes)
	local array = {}
	-- ѭ�������ݴ������飬�±���ʼ��1
	for i = 1, #bytes, 1 do
		array[i] = string.byte(string.sub(bytes, i, i))
	--        print(string.byte(string.sub(bytes, i, i)), i, math.floor((i - 1) % 50), math.floor((i - 1) / 50))
	end
	return array
end

-- base64����ObjectMode
-- Object_Layer �����ݴ洢����Ϊ base64, 0xFFFF ������ͼ��Ϊ Object_Layer, ��������������:

-- X ѡ����λ��X, ��λΪ����
-- Y ѡ����λ��Y, ��λΪ����
-- ID Object�ı�ʶ��, ����ʾ�������λ�� tileset ��λ��
-- ����������ֵ������������ĸ�λ(bit set)������: �������ת����ڸ�λ�� X �� Y, �� flip ������ ID ��
-- sample: xѡ��   yѡ��   ID
--   data: 128 129   0   0   32   0
-- xѡ����yѡ���ұߵ���������11111111������ߵ�bitΪ��תbit���������ر�ʾ��Χ��0��(127*256+255=32767)
-- ID�ұߵ���������11111111������ߵ�bitΪˮƽ��תbit����Χͬ��
-- xѡ������תbit��yѡ������תbit��ϱ�ʾ�ĸ�����10��90�㣬11:180�㣬01:270�㣬00��0��

-- �ⶫ��̫�鷳�ˣ���ʱ�ò������ȿ���
function utils.Base64DecodeToArray_ObjectMode(str)
	-- ��C#�Դ��Ľ���API
	local bytes = CS.System.Convert.FromBase64String(str)
	--    print(#bytes)
	local array = {}
	--     print(getStr(bytes, 1), getStr(bytes, 2))
	-- ѭ�������ݴ������飬�±���ʼ��1
	print("length: " .. #bytes)

	-- �ӵ�3��byte��ʼ����Ϊǰ��2��byte��0xFFFF
	for i = 3, #bytes, 6 do
		print(string.byte(string.sub(bytes, i, i)))
	--        array[(i - 2 + 5) / 6] = string.byte(string.sub(bytes, i, i))
	--        print(getStr(bytes, i), getStr(bytes, i + 1), getStr(bytes, i + 2), getStr(bytes, i + 3), getStr(bytes, i + 4), getStr(bytes, i + 5))

		local cx = string.byte(string.sub(bytes, i, i)) + string.byte(string.sub(bytes, i + 1, i + 1)) * 256
		local cy = string.byte(string.sub(bytes, i + 2, i + 2)) + string.byte(string.sub(bytes, i + 3, i + 3)) * 256
		array[(i + 3) / 6] = {x = cx, y = cy}
		-- ����
		print(cx, cy)
	end
	return array
end

-- ǳ����
function utils.shallow_copy(object)
	local newObject
	if type(object) == "table" then
		newObject = {}
		for key, value in pairs(object) do
			newObject[key] = value
		end
	else
		newObject = object
	end
	return newObject
end

-- ���
function utils.deep_copy(object)
	local lookup = {}
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup[object] then
			return lookup[object]
		end
		local newObject = {}
		lookup[object] = newObject
		for key, value in pairs(object) do
			newObject[_copy(key)] = _copy(value)
		end
		return setmetatable(newObject, getmetatable(object))
	end
	return _copy(object)
end






return utils
