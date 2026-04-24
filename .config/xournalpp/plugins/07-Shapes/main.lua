local GLOBAL_RADIUS = 22

local lastDrawnRefs = {}
local lastDrawnPage = nil
local lastDrawnLayer = nil
local lastDrawTime = 0
local currentShapeIndex = 1

local seqRefs = {}
local seqLastTime = 0
local seqNum = 1
local seqLastShapeType = 0

local function getCenter()
	local doc = app.getDocumentStructure()
	local pageNo = doc.currentPage
	local page = doc.pages[pageNo]
	local w = page.pageWidth or 595
	local h = page.pageHeight or 842
	return w / 2, h / 2
end

local function createStroke(px, py, color, fillValue)
	local pres = {}
	for i = 1, #px do
		table.insert(pres, 1.0)
	end
	return {
		x = px,
		y = py,
		pressure = pres,
		tool = "pen",
		width = 2.0,
		color = color,
		fill = fillValue,
		lineStyle = "solid",
	}
end

local function renderAndSelect(strokesTable)
	app.addStrokes({ strokes = strokesTable })
	app.refreshPage()

	local doc = app.getDocumentStructure()
	lastDrawnPage = doc.currentPage
	lastDrawnLayer = doc.pages[lastDrawnPage].currentLayer

	local allStrokes = app.getStrokes("layer")
	lastDrawnRefs = {}
	if allStrokes then
		for i = #allStrokes, #allStrokes - #strokesTable + 1, -1 do
			if allStrokes[i] and allStrokes[i].ref then
				table.insert(lastDrawnRefs, allStrokes[i].ref)
			end
		end
		if #lastDrawnRefs > 0 then
			app.addToSelection(lastDrawnRefs)
		end
	end
end

local function insertHollowStar()
	local cx, cy = getCenter()
	local p = {}
	for i = 0, 4 do
		local angle = math.rad(-90 + i * 72)
		table.insert(p, { x = cx + GLOBAL_RADIUS * math.cos(angle), y = cy + GLOBAL_RADIUS * math.sin(angle) })
	end
	local px, py = {}, {}
	local order = { 1, 3, 5, 2, 4, 1 }
	for _, idx in ipairs(order) do
		table.insert(px, p[idx].x)
		table.insert(py, p[idx].y)
	end
	renderAndSelect({ createStroke(px, py, 0xFF0000, 0) })
end

local function insertSolidStar()
	local cx, cy = getCenter()
	local r = GLOBAL_RADIUS * 0.382
	local px, py = {}, {}
	for i = 0, 10 do
		local angle = math.rad(-90 + i * 36)
		local radius = (i % 2 == 0) and GLOBAL_RADIUS or r
		table.insert(px, cx + radius * math.cos(angle))
		table.insert(py, cy + radius * math.sin(angle))
	end
	renderAndSelect({ createStroke(px, py, 0xFF0000, 178) })
end

local function insertHeart()
	local cx, cy = getCenter()
	local px, py = {}, {}
	local scale = GLOBAL_RADIUS / 17.0
	for i = 0, 360, 5 do
		local t = math.rad(i)
		local x = 16 * math.sin(t) ^ 3
		local y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
		table.insert(px, cx + x * scale)
		table.insert(py, cy - y * scale)
	end
	table.insert(px, px[1])
	table.insert(py, py[1])
	renderAndSelect({ createStroke(px, py, 0xE74C3C, 178) })
end

local function insertCheckmark()
	local cx, cy = getCenter()
	local greenColor = 0x27AE60
	local s = GLOBAL_RADIUS / 35.0
	local circleX, circleY = {}, {}
	for i = 0, 360, 10 do
		table.insert(circleX, cx + GLOBAL_RADIUS * math.cos(math.rad(i)))
		table.insert(circleY, cy + GLOBAL_RADIUS * math.sin(math.rad(i)))
	end
	table.insert(circleX, circleX[1])
	table.insert(circleY, circleY[1])
	local strokeCircle = createStroke(circleX, circleY, greenColor, 60)

	local px, py = {}, {}
	local pts = {
		{ -16 * s, 5 * s },
		{ -5 * s, 16 * s },
		{ 22 * s, -16 * s },
		{ 13 * s, -22 * s },
		{ -5 * s, 2 * s },
		{ -11 * s, -3 * s },
	}
	for _, pt in ipairs(pts) do
		table.insert(px, cx + pt[1])
		table.insert(py, cy + pt[2])
	end
	table.insert(px, cx + pts[1][1])
	table.insert(py, cy + pts[1][2])

	renderAndSelect({ strokeCircle, createStroke(px, py, greenColor, 255) })
end

local function insertExclamation()
	local cx, cy = getCenter()
	local orangeColor = 0xF39C12
	local s = GLOBAL_RADIUS / 35.0
	local circleX, circleY = {}, {}
	for i = 0, 360, 10 do
		table.insert(circleX, cx + GLOBAL_RADIUS * math.cos(math.rad(i)))
		table.insert(circleY, cy + GLOBAL_RADIUS * math.sin(math.rad(i)))
	end
	table.insert(circleX, circleX[1])
	table.insert(circleY, circleY[1])
	local strokeCircle = createStroke(circleX, circleY, orangeColor, 60)

	local topX, topY = {}, {}
	local topPts = { { -5 * s, -27 * s }, { 5 * s, -27 * s }, { 3 * s, 10 * s }, { -3 * s, 10 * s } }
	for _, pt in ipairs(topPts) do
		table.insert(topX, cx + pt[1])
		table.insert(topY, cy + pt[2])
	end
	table.insert(topX, topX[1])
	table.insert(topY, topY[1])

	local dotX, dotY = {}, {}
	local r_dot = 5 * s
	for i = 0, 360, 20 do
		table.insert(dotX, cx + r_dot * math.cos(math.rad(i)))
		table.insert(dotY, cy + 22 * s + r_dot * math.sin(math.rad(i)))
	end
	table.insert(dotX, dotX[1])
	table.insert(dotY, dotY[1])

	renderAndSelect({
		strokeCircle,
		createStroke(topX, topY, orangeColor, 255),
		createStroke(dotX, dotY, orangeColor, 255),
	})
end

local function insertCross()
	local cx, cy = getCenter()
	local redColor = 0xE74C3C
	local s = GLOBAL_RADIUS / 35.0
	local circleX, circleY = {}, {}
	for i = 0, 360, 10 do
		table.insert(circleX, cx + GLOBAL_RADIUS * math.cos(math.rad(i)))
		table.insert(circleY, cy + GLOBAL_RADIUS * math.sin(math.rad(i)))
	end
	table.insert(circleX, circleX[1])
	table.insert(circleY, circleY[1])
	local strokeCircle = createStroke(circleX, circleY, redColor, 60)

	local bar1X, bar1Y = {}, {}
	local b1Pts = { { -14 * s, -20 * s }, { -20 * s, -14 * s }, { 14 * s, 20 * s }, { 20 * s, 14 * s } }
	for _, pt in ipairs(b1Pts) do
		table.insert(bar1X, cx + pt[1])
		table.insert(bar1Y, cy + pt[2])
	end
	table.insert(bar1X, bar1X[1])
	table.insert(bar1Y, bar1Y[1])

	local bar2X, bar2Y = {}, {}
	local b2Pts = { { 20 * s, -14 * s }, { 14 * s, -20 * s }, { -20 * s, 14 * s }, { -14 * s, 20 * s } }
	for _, pt in ipairs(b2Pts) do
		table.insert(bar2X, cx + pt[1])
		table.insert(bar2Y, cy + pt[2])
	end
	table.insert(bar2X, bar2X[1])
	table.insert(bar2Y, bar2Y[1])

	renderAndSelect({
		strokeCircle,
		createStroke(bar1X, bar1Y, redColor, 255),
		createStroke(bar2X, bar2Y, redColor, 255),
	})
end

local function insertQuestion()
	local cx, cy = getCenter()
	local color = 0xE5A50A
	local s = GLOBAL_RADIUS / 35.0
	local circleX, circleY = {}, {}
	for i = 0, 360, 10 do
		table.insert(circleX, cx + GLOBAL_RADIUS * math.cos(math.rad(i)))
		table.insert(circleY, cy + GLOBAL_RADIUS * math.sin(math.rad(i)))
	end
	table.insert(circleX, circleX[1])
	table.insert(circleY, circleY[1])
	local strokeCircle = createStroke(circleX, circleY, color, 60)

	local topX, topY = {}, {}
	for a = 140, 400, 10 do
		table.insert(topX, cx + 13 * s * math.cos(math.rad(a)))
		table.insert(topY, cy - 8 * s + 13 * s * math.sin(math.rad(a)))
	end
	table.insert(topX, cx + 4 * s)
	table.insert(topY, cy + 8 * s)
	table.insert(topX, cx + 4 * s)
	table.insert(topY, cy + 15 * s)
	table.insert(topX, cx - 4 * s)
	table.insert(topY, cy + 15 * s)
	table.insert(topX, cx - 4 * s)
	table.insert(topY, cy + 8 * s)
	for a = 400, 140, -10 do
		table.insert(topX, cx + 5 * s * math.cos(math.rad(a)))
		table.insert(topY, cy - 8 * s + 5 * s * math.sin(math.rad(a)))
	end
	table.insert(topX, topX[1])
	table.insert(topY, topY[1])

	local dotX, dotY = {}, {}
	local r_dot = 4.5 * s
	for i = 0, 360, 20 do
		table.insert(dotX, cx + r_dot * math.cos(math.rad(i)))
		table.insert(dotY, cy + 23 * s + r_dot * math.sin(math.rad(i)))
	end
	table.insert(dotX, dotX[1])
	table.insert(dotY, dotY[1])

	renderAndSelect({ strokeCircle, createStroke(topX, topY, color, 255), createStroke(dotX, dotY, color, 255) })
end

function drawHollowStar()
	insertHollowStar()
end
function drawSolidStar()
	insertSolidStar()
end
function drawSolidHeart()
	insertHeart()
end
function drawSolidCheckmark()
	insertCheckmark()
end
function drawSolidExclamation()
	insertExclamation()
end
function drawSolidCross()
	insertCross()
end
function drawSolidQuestion()
	insertQuestion()
end

function cycleShapes()
	local doc = app.getDocumentStructure()
	local pageNo = doc.currentPage
	local layerNo = doc.pages[pageNo].currentLayer
	local now = os.time()

	if (now - lastDrawTime > 3) or (lastDrawnPage ~= pageNo) or (lastDrawnLayer ~= layerNo) then
		lastDrawnRefs = {}
		currentShapeIndex = 1
	end

	if #lastDrawnRefs > 0 then
		app.addToSelection(lastDrawnRefs)
		app.activateAction("delete")
		app.refreshPage()
	end

	lastDrawnRefs = {}
	lastDrawTime = os.time()
	lastDrawnPage = pageNo
	lastDrawnLayer = layerNo

	local shapeFunctions = {
		insertHollowStar,
		insertSolidStar,
		insertHeart,
		insertCheckmark,
		insertExclamation,
		insertQuestion,
		insertCross,
	}

	app.changeActionState("select-tool", app.C.Tool_pen)
	shapeFunctions[currentShapeIndex]()

	currentShapeIndex = currentShapeIndex + 1
	if currentShapeIndex > #shapeFunctions then
		currentShapeIndex = 1
	end
end

local function insertSequenceMarker(shapeType)
	local doc = app.getDocumentStructure()
	local pageNo = doc.currentPage
	local layerNo = doc.pages[pageNo].currentLayer
	local now = os.time()

	if
		(now - seqLastTime > 3)
		or (lastDrawnPage ~= pageNo)
		or (lastDrawnLayer ~= layerNo)
		or (seqLastShapeType ~= shapeType)
	then
		seqNum = 1
		seqRefs = {}
		seqLastShapeType = shapeType
	else
		seqNum = seqNum + 1
	end

	if #seqRefs > 0 then
		app.addToSelection(seqRefs)
		app.activateAction("delete")
		app.refreshPage()
	end

	seqRefs = {}
	seqLastTime = os.time()
	lastDrawnPage = pageNo
	lastDrawnLayer = layerNo

	local cx, cy = getCenter()
	local redColor = 0xE74C3C
	local r = 8.5

	local s = 1.0 -- scale
	if shapeType == 1 then
		s = (seqNum < 10) and 2.5 or 1.85
	else
		s = (seqNum < 10) and 1.6 or 1.3
	end

	local strokes = {}

	if shapeType == 1 then
		local circleX, circleY = {}, {}
		for i = 0, 360, 15 do
			table.insert(circleX, cx + r * math.cos(math.rad(i)))
			table.insert(circleY, cy + r * math.sin(math.rad(i)))
		end
		table.insert(circleX, circleX[1])
		table.insert(circleY, circleY[1])
		table.insert(strokes, createStroke(circleX, circleY, redColor, 20))
	else
		local triX, triY = {}, {}
		local pts = { { 0, -9.5 }, { 9, 5 }, { -9, 5 } }
		for _, pt in ipairs(pts) do
			table.insert(triX, cx + pt[1])
			table.insert(triY, cy + pt[2])
		end
		table.insert(triX, triX[1])
		table.insert(triY, triY[1])
		table.insert(strokes, createStroke(triX, triY, redColor, 20))
	end

	local function getDigitPath(char)
		local pts = {}
		local function addLine(x, y)
			table.insert(pts, { x, y })
		end
		local function addArc(acx, acy, rx, ry, a1, a2, steps)
			for i = 0, steps do
				local a = math.rad(a1 + (a2 - a1) * (i / steps))
				addLine(acx + rx * math.cos(a), acy + ry * math.sin(a))
			end
		end

		if char == "0" then
			addArc(0, 0, 0.8, 1.8, 0, 360, 24)
		elseif char == "1" then
			addLine(-0.4, -1)
			addLine(0.2, -2)
			addLine(0.2, 2)
		elseif char == "2" then
			addArc(0, -1, 0.9, 1, 150, 360, 14)
			addLine(-1, 2)
			addLine(1, 2)
		elseif char == "3" then
			addArc(0, -1, 0.9, 1, 160, 450, 14)
			addArc(0, 1, 0.9, 1, 270, 520, 14)
		elseif char == "4" then
			addLine(0.6, 2)
			addLine(0.6, -2)
			addLine(-1.2, 0.5)
			addLine(1.2, 0.5)
		elseif char == "5" then
			addLine(0.8, -2)
			addLine(-0.8, -2)
			addLine(-0.8, -0.2)
			addArc(0, 0.8, 0.9, 1.2, 230, 500, 16)
		elseif char == "6" then
			addArc(0, 1, 0.9, 1, 180, 180 + 360, 20)
			addLine(0.8, -1.8)
		elseif char == "7" then
			addLine(-1, -2)
			addLine(1, -2)
			addLine(-0.3, 2)
		elseif char == "8" then
			addArc(0, -1, 0.8, 1, 90, 90 + 360, 16)
			addArc(0, 1, 0.9, 1, 270, 270 + 360, 16)
		elseif char == "9" then
			addArc(0, -1, 0.9, 1, 0, 360, 20)
			addLine(0.6, 2)
		end
		return pts
	end

	local numStr = tostring(seqNum)
	local len = #numStr
	local charWidth = 2.2
	local startOffset = -(len - 1) * charWidth / 2

	for i = 1, len do
		local char = numStr:sub(i, i)
		local path = getDigitPath(char)
		if path and #path > 0 then
			local px, py = {}, {}
			local offsetX = startOffset + (i - 1) * charWidth
			for _, pt in ipairs(path) do
				table.insert(px, cx + (pt[1] + offsetX) * s)
				table.insert(py, cy + pt[2] * s)
			end
			table.insert(strokes, createStroke(px, py, redColor, 0))
		end
	end

	app.changeActionState("select-tool", app.C.Tool_pen)

	app.addStrokes({ strokes = strokes })
	app.refreshPage()

	local allStrokes = app.getStrokes("layer")
	if allStrokes then
		for i = #allStrokes, #allStrokes - #strokes + 1, -1 do
			if allStrokes[i] and allStrokes[i].ref then
				table.insert(seqRefs, allStrokes[i].ref)
			end
		end
		if #seqRefs > 0 then
			app.addToSelection(seqRefs)
		end
	end
end

function drawSeqCircle()
	insertSequenceMarker(1)
end
function drawSeqTriangle()
	insertSequenceMarker(2)
end

function initUi()
	app.registerUi({ menu = "Cycle Shapes", callback = "cycleShapes", accelerator = "<Alt>s" })

	app.registerUi({
		menu = "Shape: Seq Circle",
		callback = "drawSeqCircle",
		accelerator = "<Alt>c",
	})

	app.registerUi({
		menu = "Shape: Seq Triangle",
		callback = "drawSeqTriangle",
		accelerator = "<Alt>v",
	})
end
