import raylib, rayutils, math, sugar, sequtils, zero_functional, strutils, lenientops

type Stone* = enum
    BL = "b", WH = "w", NONE = "n"

const stArr* = [false : BL,true :  WH]
const bSize* : uint8 = 169 # 13^2 = 169

type u8* = uint8

type Hex* = object
    pos* : Vector2
    stone* : Stone

type Board* = object
    wStones* : set[uint8]
    bStones* : set[uint8]

var
    board : Board

func stonesOfCol(b : Board, whiteMoves : bool) : set[u8] =
    if whiteMoves:
        return b.wStones
    return b.bStones

func contains*[T; V : not T](x : set[T], y : V) : bool {.inline.} =
    assert y.T is typeof T
    contains(x, T y)

func contains*(b : Board, i : SomeInteger) : bool = return i in b.wStones or i in b.bStones

proc incl*[T; V : not T](x : var set[T], y : V) {.inline.} = x.incl y.T

# func getEmptyBoard*() : Board =
#     for i in 0..12:
#         for j in 0..12:
#             result.hexes.add Hex(pos : makevec2(i, j), stone : None)
# board = getEmptyBoard()

func hFen*(b : Board) : string =
    var shift : string
    var count : int
    for i in 0'u8..<bSize:
        if i in b.wStones:
            result &= $count & 'w'
            count = 0
        elif i in b.bStones:
            result &= $count & 'b'
            count = 0
        count += 1

func loadHFen*(inp : string) : Board =
    var shift : string
    var cInx : int
    for c in inp:
        if c in '0'..'9':
            shift &= c
        else:
            cInx += shift.parseInt + 1
            if c == 'w':
                result.wStones.incl cInx - 1
            else:
                result.bStones.incl cInx - 1
            shift = ""

proc col(s : Stone) : Color =
    if s == WH:
        return WHITE
    if s == BL:
        return BLACK
    return CLEAR

func pos*(ind : uint8) : Vector2 = return makevec2(ind div 13, ind mod 13)

proc col(h : Hex) : Color = return col h.stone

func posToInd*(v : Vector2) : uint8 = uint8(v.x * 13 + v.y)

proc `[]`*(s : openArray[Hex], v : Vector2) : Hex = s[posToInd v]

proc `[]=`*(s : var openArray[Hex], v : Vector2, h : Hex) = s[v] = h

proc getAdj*(ind : uint8) : seq[uint8] =
    let opos = ind.pos
    return @[opos + makevec2(1, -1),
             opos + makevec2(0, -1),
             opos + makevec2(-1, 0),
             opos + makevec2(-1, 1),
             opos + makevec2(0, 1),
             opos + makevec2(1, 0)
            ].filter(v => v in makerect(makevec2(0, 0), makevec2(12, 12))).map(x => posToInd x)

# proc checkVictory*(b : Board, ind : int) : bool =
#     var traversed = @[ind]
#     var branches = @[ind]
#     var nextBranches : seq[int]
#     let col = b.hexes[ind].col
#     var res : (bool, bool)
#     if col == WHITE:
#         while branches.len > 0:
#             traversed &= branches
#             for i in 0..<branches.len:
#                 let pos = b.hexes[branches[i]].pos
#                 if pos.x == 0:
#                     res[0] = true
#                     if res[1]: return true
#                 if pos.x == 12:
#                     res[1] = true
#                     if res[0]:
#                         return true
#             for i in 0..<branches.len:
#                 nextBranches &= branches[i].getAdj.filter(y => y notin traversed and b.hexes[y].col == col)
#             branches = nextBranches
#             nextBranches = @[]
#     else:
#         while branches.len > 0:
#             traversed &= branches
#             for i in 0..<branches.len:
#                 let pos = b.hexes[branches[i]].pos
#                 if pos.y == 0:
#                     res[0] = true
#                     if res[1]: return true
#                 if pos.y == 12:
#                     res[1] = true
#                     if res[0]:
#                         return true
#             for i in 0..<branches.len:
#                 nextBranches &= branches[i].getAdj(b).filter(y => y notin traversed and b.hexes[y].col == col)
#             branches = nextBranches
#             nextBranches = @[]

func makeMove*(b : Board, i : u8, whiteMoves : bool) : Board =
    result = b
    if whiteMoves:
        result.wStones.incl i
    else:
        result.bStones.incl i

func varMakeMove*(b : var Board, i : u8, whiteMoves : bool) =
    if whiteMoves:
        b.wStones.incl i
    else:
        b.bStones.incl i

func diff*(b, b1 : Board) : set[u8] =
    var b1Ret = b1
    for i in b.wStones:
        if i notin b1.wStones:
            result.incl i
        b1Ret.wStones.excl i
    for i in b.bStones:
        if i notin b1.bStones:
            result.incl i
        b1Ret.bStones.excl i
    result = result + b1Ret.wStones + b1Ret.bStones
