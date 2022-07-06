import raylib, rayutils, math, rlgl, sugar, sequtils, strformat, zero_functional

type Stone = enum
    BL, WH, NONE

type Hex = object
    pos : Vector2
    inrad : float
    circumrad : float
    stone : Stone

type Board = object
    hexes : seq[Hex]

const
    screenWidth = 1920
    screenHeight = 1080
    screenCenter = makevec2(screenWidth / 2, screenHeight / 2)

InitWindow screenWidth, screenHeight, "John Nash's Hex"
InitAudioDevice()
SetMasterVolume 1
SetTargetFPS 60

var 
    board : Board
    iBoard : Board
    turn : int
    ongoing = true
    showVicText = true
    framesWon : int
    moves : seq[int]
    tbTimer : int
let
    stoneClick = LoadSound("assets/audio/stonePlace.mp3")
    awinnerisyou = LoadSound("assets/audio/awinnerisyou.mp3")
for i in 0..12:
    for j in 0..12:
        board.hexes.add Hex(pos : makevec2(i, j), inrad : 35, circumrad : (35 * 2) / sqrt(3f), stone : None)
iBoard = board

proc stone(c : Color) : Stone = 
    if c.r == 255:
        return Bl
    if c.a == 0:
        return NONE
    return WH

proc col(s : Stone) : Color =
    if s == WH:
        return WHITE
    if s == BL:
        return BLACK
    return CLEAR

proc col(h : Hex) : Color = return col h.stone

func center(h : Hex) : Vector2 = makevec2(230, screenHeight div 2) + (makevec2(2 * h.pos.x.int * 35, 0).rotateVec(PI/6)) + (makevec2(2 * h.pos.y.int * 35, 0).rotateVec(-PI/6))

func getClosestHex(pos : Vector2, hexList : seq[Hex]) : int =
    let dist = hexList.mapIt(abs(pos - it.center).mag)
    result = minIndex dist
    if dist[result] > hexlist[0].circumrad + 1:
        return -1

proc drawHex(hex : Hex) =
    let col = makecolor "fafafa"
    let lCol = makecolor "c2c2c2"
    var points : array[6, Vector2]
    for i in 0..5:
        points[i] = hex.center + (makevec2(hex.circumrad, 0) * getRotMat(PI/3 * i.float))

    rlSetLineWidth 2
    rlEnableSmoothLines()
    for i in 0..5:      
        rlBegin RL_TRIANGLES
        rlColor4ub col.r, col.g, col.b, col.a
        rlVertex2f hex.center.x, hex.center.y
        rlVertex2f points[i].x, points[i].y 
        rlVertex2f points[(i + 1) mod points.len].x, points[(i + 1) mod points.len].y
        rlEnd()
        rlDrawRenderBatchActive()

        rlBegin RL_LINES
        rlColor4ub lCol.r, lCol.g, lCol.b, lCol.a
        rlVertex2f points[i].x, points[i].y
        rlVertex2f points[(i + 1) mod points.len].x, points[(i + 1) mod points.len].y
        rlEnd()
        rlDrawRenderBatchActive()
    rlSetLineWidth 1
    if hex.stone != NONE:
        DrawCircleV hex.center, 30, BLACK
        DrawCircleV hex.center, 26, hex.col
    rlDisableSmoothLines()

proc drawBoard(board : Board) =
    let corners : seq[Hex] = toSeq(board.hexes.filter(x => x.pos in [makevec2(0, 0), makevec2(0, 12), makevec2(12, 0), makevec2(12, 12)]))
    let points = [corners[0].center - makevec2(2.35 * corners[0].circumrad, 0),
                    corners[0].center - makevec2(0.7 * corners[0].circumrad, 0),
                    corners[1].center + makevec2(0, 0.5 * corners[0].inrad),
                    corners[1].center + makevec2(0, 1.6 * corners[0].inrad)]
    let points2 = [corners[3].center + makevec2(2.35 * corners[3].circumrad, 0),
                    corners[3].center,
                    corners[2].center,
                    corners[2].center - makevec2(0, 1.6 * corners[0].inrad)]
    let points3 = [corners[0].center - makevec2(2.35 * corners[0].circumrad, 0),
                    corners[0].center,
                    corners[2].center,
                    corners[2].center - makevec2(0, 1.6 * corners[0].inrad)]
    let points4 = [corners[3].center + makevec2(2.35 * corners[3].circumrad, 0),
                    corners[3].center,
                    corners[1].center,
                    corners[1].center + makevec2(0, 1.6 * corners[0].inrad)]


    drawPolygon(points, WHITE)
    drawPolygon(points4, BLACK)
    drawPolygon(points3, BLACK)
    drawPolygon(points2, WHITE)

    for i in 0..3:
        rlBegin RL_LINES
        rlColor3f 0, 0, 0
        rlVertex2f points[i].x, points[i].y
        rlVertex2f points[(i + 1) mod points.len].x, points[(i + 1) mod points.len].y
        rlEnd()
        
        rlBegin RL_LINES
        rlColor3f 0, 0, 0
        rlVertex2f points2[i].x, points2[i].y
        rlVertex2f points2[(i + 1) mod points2.len].x, points2[(i + 1) mod points2.len].y
        rlEnd()

        rlBegin RL_LINES
        rlColor3f 0, 0, 0
        rlVertex2f points3[i].x, points3[i].y
        rlVertex2f points3[(i + 1) mod points3.len].x, points3[(i + 1) mod points3.len].y
        rlEnd()

        rlBegin RL_LINES
        rlColor3f 0, 0, 0
        rlVertex2f points4[i].x, points4[i].y
        rlVertex2f points4[(i + 1) mod points4.len].x, points4[(i + 1) mod points4.len].y
        rlEnd()
        rlDrawRenderBatchActive()

    for i in board.hexes:
        drawHex(i)

func posToInd(v : Vector2) : int = int(v.x * 13 + v.y)

proc `[]`(s : openArray[Hex], v : Vector2) : Hex = s[posToInd v]

proc `[]=`(s : var openArray[Hex], v : Vector2, h : Hex) = s[v] = h

func getAdj(ind : int, board : Board) : seq[int] = 
    let origin = board.hexes[ind]
    let opos = origin.pos
    return @[opos + makevec2(1, -1),
             opos + makevec2(0, -1),
             opos + makevec2(-1, 0),
             opos + makevec2(-1, 1),
             opos + makevec2(0, 1),
             opos + makevec2(1, 0)
            ].filter(v => v in makerect(makevec2(0, 0), makevec2(12, 12))).map(x => posToInd x)

func checkVictory(b : Board, ind : int) : bool =
    var traversed = @[ind]
    var branches = @[ind]
    var nextBranches : seq[int]
    let col = b.hexes[ind].col
    var res : (bool, bool)
    if col == WHITE:
        while branches.len > 0:
            traversed &= branches
            for i in 0..<branches.len:
                let pos = b.hexes[branches[i]].pos
                if pos.x == 0:
                    res[0] = true
                    if res[1]: return true
                if pos.x == 12:
                    res[1] = true
                    if res[0]:
                        return true
            for i in 0..<branches.len:
                nextBranches &= branches[i].getAdj(b).filter(y => y notin traversed and b.hexes[y].col == col)
            branches = nextBranches
            nextBranches = @[]
    else:
        while branches.len > 0:
            traversed &= branches
            for i in 0..<branches.len:
                let pos = b.hexes[branches[i]].pos
                if pos.y == 0:
                    res[0] = true
                    if res[1]: return true
                if pos.y == 12:
                    res[1] = true
                    if res[0]:
                        return true
            for i in 0..<branches.len:
                nextBranches &= branches[i].getAdj(b).filter(y => y notin traversed and b.hexes[y].col == col)
            branches = nextBranches
            nextBranches = @[]

while not WindowShouldClose():
    ClearBackground WHITE
    # DrawTexturePro bgTex, makerect(0, 0, bgTex.width, bgTex.height), makerect(0, 0, screenWidth, screenHeight), makevec2(0, 0), 0, WHITE

    let mpos = GetMousePosition()
    let mHex = mpos.getClosestHex(board.hexes)

    if ongoing:
        if IsMouseButtonPressed(MOUSE_BUTTON_LEFT) and mHex >= 0 and board.hexes[mHex].col == CLEAR:
            PlaySound stoneClick
            moves.add mHex
            if turn mod 2 == 0:
                board.hexes[mHex].stone = BL

            else:
                board.hexes[mHex].stone = WH
            if checkVictory(board, mHex):
                PlaySound awinnerisyou
                ongoing = false
                showVicText = true
            turn += 1
    else:
        framesWon += 1
        if IsKeyPressed KEY_R:
            board = iBoard
            ongoing = true
            turn = 0

    BeginDrawing()

    board.drawBoard

    if not ongoing:
        if showVicText:
            drawTextCentered("A Winner is You!", screenCenter.x.int, screenCenter.y.int, 140, colorArr[(framesWon div 10) mod colorArr.len])
            if framesWon > 120:
                drawTextCenteredX("Press R to restart", screenCenter.x.int, screenCenter.y.int - 160, 70, colorArr[((framesWon - 120) div 10) mod colorArr.len])
            if framesWon > 130:
                drawTextCenteredX("Press SPACEBAR to make this text disappear", screenCenter.x.int, screenCenter.y.int + 160, 70, colorArr[((framesWon - 130) div 10) mod colorArr.len])
        if IsKeyPressed KEY_SPACE:
            showVicText = not showVicText

    drawTextCenteredX(&"Turn {turn}", 200, 100, 40, BLACK)
    if turn == 1:
        let btn = makerect(makevec2(screenWidth - 280, 85), makevec2(screenWidth - 280 + 160, 85 + 65))
        if mpos in btn:
            drawTextCenteredX("SWAP", screenWidth - 200, 100, 40, GREY)
            DrawRectangleLinesEx btn, 3, GREY
            if IsMouseButtonPressed MOUSE_LEFT_BUTTON:
                for i in 0..<board.hexes.len:
                    if board.hexes[i].stone == BL:
                        let other = board.hexes[i].pos.invert.posToInd
                        board.hexes[other].stone = WH
                        board.hexes[i].stone = NONE
                        turn += 1
                        moves[0] = other
                        break
        else:
            drawTextCenteredX("SWAP", screenWidth - 200, 100, 40, BLACK)
            DrawRectangleLinesEx btn, 3, BLACK
    
    let tSize = MeasureTextEx(GetFontDefault(), "TAKEBACK", 40, max(20 , 40) / 20) / 2
    let tBtn = makerect(makevec2(160 - tSize.x, screenHeight - 155), makevec2(200 + tSize.x + 40, screenHeight - 140 + tSize.y + 25))
    if (showVicText or not ongoing) and turn > 0:
        if mpos in tBtn:
            if tbTimer != 0:
                if IsMouseButtonDown MOUSE_LEFT_BUTTON:
                    if tbTimer > 45:
                        tbTimer = 0
                        board.hexes[moves[^1]].stone = NONE
                        if turn == 2:
                            if moves.len == 1:
                                turn += -1
                        turn += -1
                        ongoing = true
                        framesWon = 0
                        showVicText = true
                        moves.delete moves.len - 1
                    else:
                        let greenArea = makerect(tBtn.x, tBtn.y, tBtn.width*(tBTimer/45), tBtn.height)
                        tbTimer += 1
                        DrawRectangleRec(greenArea, GREEN)
                else:
                    tBTimer = 0
            else:
                if IsMouseButtonPressed MOUSE_LEFT_BUTTON:
                    tbTimer += 1
            drawTextCenteredX("TAKEBACK", 200, screenHeight - 140, 40, GREY)
            DrawRectangleLinesEx tBtn, 3, GREY
        else:
            tbTimer = 0
            drawTextCenteredX("TAKEBACK", 200, screenHeight - 140, 40, BLACK)
            DrawRectangleLinesEx tBtn, 3, BLACK
    

    EndDrawing()
CloseWindow()