import raylib, rayutils, math, sugar, sequtils, zero_functional, strutils

type Stone* = enum
    BL = "b", WH = "w", NONE = "n"

const stArr* = [false : BL,true :  WH]

type Hex* = object
    pos* : Vector2
    inrad* : float
    circumrad* : float
    stone* : Stone

type Board* = object
    hexes* : seq[Hex]
var
    board : Board

func getEmptyBoard*() : Board =
    for i in 0..12:
        for j in 0..12:
            result.hexes.add Hex(pos : makevec2(i, j), inrad : 35, circumrad : (35 * 2) / sqrt(3f), stone : None)
board = getEmptyBoard()

func hFen*(b : Board) : string =
    let hexList = b.hexes
    var count : int
    for i in 0..<hexList.len:
        if hexList[i].stone == NONE:
            count += 1
        else:
            result &= $count & $hexList[i].stone
            count = 0

func loadHFen*(inp : string) : Board =
    result = getEmptyBoard()
    var shift : string
    var cInx : int
    for c in inp:
        if c in '0'..'9':
            shift &= c
        else:
            cInx += shift.parseInt + 1
            if c == 'w':
                result.hexes[cInx - 1].stone = WH
            else:
                result.hexes[cInx - 1].stone = BL
            shift = ""

proc col(s : Stone) : Color =
    if s == WH:
        return WHITE
    if s == BL:
        return BLACK
    return CLEAR

proc col(h : Hex) : Color = return col h.stone

func posToInd*(v : Vector2) : int = int(v.x * 13 + v.y)

proc `[]`*(s : openArray[Hex], v : Vector2) : Hex = s[posToInd v]

proc `[]=`*(s : var openArray[Hex], v : Vector2, h : Hex) = s[v] = h

proc getAdj*(ind : int, b : Board = board) : seq[int] =
    let opos = b.hexes[ind].pos
    return @[opos + makevec2(1, -1),
             opos + makevec2(0, -1),
             opos + makevec2(-1, 0),
             opos + makevec2(-1, 1),
             opos + makevec2(0, 1),
             opos + makevec2(1, 0)
            ].filter(v => v in makerect(makevec2(0, 0), makevec2(12, 12))).map(x => posToInd x)

func ind*(h : Hex) : int = return h.pos.posToInd

proc checkVictory*(b : Board, ind : int) : bool =
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
                nextBranches &= branches[i].getAdj.filter(y => y notin traversed and b.hexes[y].col == col)
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
