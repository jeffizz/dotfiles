-- ============================================================================
-- main.lua | SHAPE MARKER PLUGIN
-- ============================================================================
local GLOBAL_RADIUS = 22

local lastDrawnRefs = {}
local lastDrawnPage = nil
local lastDrawnLayer = nil
local lastDrawTime = 0
local currentShapeIndex = 1

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

	local stroke = createStroke(px, py, 0xFF0000, 0)
	renderAndSelect({ stroke })
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

	local stroke = createStroke(px, py, 0xFF0000, 178)
	renderAndSelect({ stroke })
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

	local stroke = createStroke(px, py, 0xE74C3C, 178)
	renderAndSelect({ stroke })
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
		{
			-11 * s,
			-3 * s,
		},
	}
	for _, pt in ipairs(pts) do
		table.insert(px, cx + pt[1])
		table.insert(py, cy + pt[2])
	end
	table.insert(px, cx + pts[1][1])
	table.insert(py, cy + pts[1][2])
	local strokeCheck = createStroke(px, py, greenColor, 255)

	renderAndSelect({ strokeCircle, strokeCheck })
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
	local strokeTop = createStroke(topX, topY, orangeColor, 255)

	local dotX, dotY = {}, {}
	local r_dot = 5 * s
	for i = 0, 360, 20 do
		table.insert(dotX, cx + r_dot * math.cos(math.rad(i)))
		table.insert(dotY, cy + 22 * s + r_dot * math.sin(math.rad(i)))
	end
	table.insert(dotX, dotX[1])
	table.insert(dotY, dotY[1])
	local strokeDot = createStroke(dotX, dotY, orangeColor, 255)

	renderAndSelect({ strokeCircle, strokeTop, strokeDot })
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
	local strokeBar1 = createStroke(bar1X, bar1Y, redColor, 255)

	local bar2X, bar2Y = {}, {}
	local b2Pts = { { 20 * s, -14 * s }, { 14 * s, -20 * s }, { -20 * s, 14 * s }, { -14 * s, 20 * s } }
	for _, pt in ipairs(b2Pts) do
		table.insert(bar2X, cx + pt[1])
		table.insert(bar2Y, cy + pt[2])
	end
	table.insert(bar2X, bar2X[1])
	table.insert(bar2Y, bar2Y[1])
	local strokeBar2 = createStroke(bar2X, bar2Y, redColor, 255)

	renderAndSelect({ strokeCircle, strokeBar1, strokeBar2 })
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
	local strokeTop = createStroke(topX, topY, color, 255)

	local dotX, dotY = {}, {}
	local r_dot = 4.5 * s
	for i = 0, 360, 20 do
		table.insert(dotX, cx + r_dot * math.cos(math.rad(i)))
		table.insert(dotY, cy + 23 * s + r_dot * math.sin(math.rad(i)))
	end
	table.insert(dotX, dotX[1])
	table.insert(dotY, dotY[1])
	local strokeDot = createStroke(dotX, dotY, color, 255)

	renderAndSelect({ strokeCircle, strokeTop, strokeDot })
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

function initUi()
	app.registerUi({ menu = "Cycle Shapes", callback = "cycleShapes", accelerator = "<Alt>s" })
end
