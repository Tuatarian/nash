import raylib, jnhex, zero_functional, sequtils, rayutils, tables, heapqueue, lenientops, sugar, algorithm, random, std/enumerate, hashes, math

randomize()

func `in`(i : int, i2 : (int, int)) : bool =
    return i == i2[0] or i == i2[1]

type LocPri = (int, float64)

func `<`(l : LocPri, l1 : LocPri) : bool = l[1] < l1[1]

func hexDist(v, v1 : Vector2) : int =
    return (abs(v.x - v1.x) +
            abs(v.x + v.y - v1.x - v1.y) +
            abs(v.y - v1.y)).int div 2

func getPath(t : Table[int, int], c : int) : seq[int] = ## This is to backtrack after finding the relevant path
    var c = c
    result.add c
    let keys : seq[int] = t.keys.toSeq
    while c in keys:
        if t[c] == -1: return result
        result.add t[c]
        c = t[c]

func astar(b : Board, h, g : int) : seq[int] =
    let hexList = b.hexes
    var path : Table[int, int] = {h : -1}.toTable
    var sFront : HeapQueue[LocPri] = [(h, 0.001f64)].toHeapQueue
    var cSteps : Table[int, int] = {h : 0}.toTable
    var c : int # current

    while sFront.len != 0:
        c = sFront.pop()[0]
        if c == g:
            return getPath(path, c).reversed

        for w in getAdj(c, b):
            let wSteps = cSteps[c] + 1
            if hexList[w].stone == NONE and (w notin cSteps.keys.toSeq or wSteps < cSteps[w]):
                sFront.push (w, (wSteps + hexDist(hexList[w].pos, hexList[g].pos).float))
                cSteps[w] = wSteps
                path[w] = c

func pathToWall(b : Board, h : int, whiteMoves : bool) : (seq[int], seq[int]) =
    let hexList = b.hexes
    var path : Table[int, int] = {h : -1}.toTable
    var pkeys : seq[int] = path.keys.toSeq
    var sFront : seq[LocPri]= @[(h, 0.001f64)]
    var costs : Table[int, int] = {h : 0}.toTable # (inx, cost) // cost == 1 if hex empty, cost == 0 if hex has correct color
    var c : int # current
    var done : (bool, bool)

    if whiteMoves:
        while sFront.len > 0:
            let minx = minIndex sFront
            c = sFront[minx][0]
            sFront.del minx
            if hexList[c].pos.x == 0 and not done[0]:
                result[0] = getPath(path, c).filter(x => hexList[x].stone == NONE)
                done[0] = true
                if done[1]:
                    return result
            elif hexList[c].pos.x == 12 and not done[1]:
                result[1] = getPath(path, c).reversed.filter(x => hexList[x].stone == NONE)
                done[1] = true
                if done[0]:
                    return result

            for w in getAdj(c, b):
                let wSteps = costs[c] + int(hexList[w].stone == NONE)
                if hexList[w].stone != BL and (w notin pkeys or wSteps < costs[w]):
                    sFront.add (w, wSteps.float)
                    path[w] = c
                    pkeys.add w
                    costs[w] = wSteps
    else:
        while sFront.len > 0:
            let minx = minIndex sFront
            c = sFront[minx][0]
            sFront.del minx
            if hexList[c].pos.y == 0 and not done[0]:
                result[0] = getPath(path, c).filter(x => hexList[x].stone == NONE)
                done[0] = true
                if done[1]:
                    return result
            elif hexList[c].pos.y == 12 and not done[1]:
                result[1] = getPath(path, c).filter(x => hexList[x].stone == NONE)
                done[1] = true
                if done[0]:
                    return result

            for w in getAdj(c, b):
                 let wSteps = costs[c] + int(hexList[w].stone == NONE)
                 if hexList[w].stone != WH and (w notin pkeys or wSteps < costs[w]):
                     sFront.add (w, wSteps.float)
                     path[w] = c
                     pkeys.add w
                     costs[w] = wSteps

func pwLen(b : Board, h : int, whiteMoves : bool) : int =
     let res = b.pathToWall(h, whiteMoves)
     return res[0].len + res[1].len

func pathToWall1(b : Board, h : int, whiteMoves : bool) : seq[int] =
    let hexList = b.hexes
    var path : Table[int, int] = {h : -1}.toTable
    var sFront = @[h]
    var costs : Table[int, int] = {h : 0}.toTable # (inx, cost) // cost == 1 if hex empty, cost == 0 if hex has correct color
    var c : int # current

    if whiteMoves:
        while sFront.len > 0:
            c = sFront.pop()
            if hexList[c].pos.x == 12:
                return getPath(path, c).reversed.filter(x => hexList[x].stone == NONE)

            for w in getAdj(c, b):
                if hexList[w].stone != BL and (w notin path.keys.toSeq or costs[c] + int(hexList[w].stone == NONE) < costs[w]):
                    sFront.add w
                    path[w] = c
                    costs[w] = costs[c] + int(hexList[w].stone == NONE)
    else:
        while sFront.len > 0:
            c = sFront.pop()
            if hexList[c].pos.y == 12:
                return getPath(path, c).reversed.filter(x => hexList[x].stone == NONE)

            for w in getAdj(c, b):
                if w notin path.keys.toSeq and hexList[w].stone != WH:
                    sFront.add w
                    path[w] = c

func pseudoLocs(h : int, b : Board) : seq[int] =
    let pos = b.hexes[h].pos
    return @[
        pos + makevec2(2, -1),
        pos - makevec2(2, -1),
        pos + makevec2(1, -2),
        pos - makevec2(1, -2),
        pos + makevec2(1, 1),
        pos - makevec2(1, 1)].filter(x => x in makerect(makevec2(0, 0), makevec2(12, 12))).map(x => posToInd x)

func checkPseudo(h, h1 : int, b : Board) : bool =
    let hexList = b.hexes
    let (iAdj, jAdj) = (getAdj(h, b), getAdj(h1, b))
    result = iAdj.filter(x => x in jAdj and hexList[x].stone == NONE).len == 2

func findPseudos(b : Board) : seq[(int, int)] =
    let hexList = b.hexes
    let wStones = hexList.filter(x => x.stone == WH).map(x => x.pos.posToInd)
    let bStones = hexList.filter(x => x.stone == BL).map(x => x.pos.posToInd)
    for i in 0..<wStones.len - 1:
        let iPseu = pseudoLocs(wStones[i], b)
        for j in (i + 1)..<wStones.len:
            if wStones[j] in iPseu:
                let (wI, wJ) = (wStones[i], wStones[j])
                if checkPseudo(wI, wJ, b):
                    result.add (wI, wJ)
    for i in 0..<bStones.len - 1:
        let iPseu = pseudoLocs(bStones[i], b)
        for j in i + 1..<bStones.len:
            if bStones[j] in iPseu:
                let (bI, bJ) = (bStones[i], bStones[j])
                if checkPseudo(bI, bJ, b):
                    result.add (bI, bJ)

func remove3cycPseudos(r : seq[(int, int)], b : Board) : seq[(int, int)] =
    result = r
    var markedForDel : set[uint8]
    for i in 0..<result.len - 1:
        let (p1, p2) = (result[i][0], result[i][1])
        for j in i+1..<result.len:
            if p1 in result[j] or p2 in result[j]:
                let (r1, r2) = (result[j][0], result[j][1])
                if p1 == r1:
                    if p2.checkPseudo(r2, b):
                        markedForDel.incl uint8 j
                        markedForDel.incl uint8 i
                elif p2 == r2:
                    if p1.checkPseudo(r1, b):
                        markedForDel.incl uint8 j
                        markedForDel.incl uint8 i
    for inx, d in enumerate(markedForDel):
        result.delete(d.int - inx)

func fillPseudos(pseudos : seq[(int, int)], b : Board) : Board =
    let hexList = b.hexes
    result = b
    for i in 0..<pseudos.len:
        let l1 = pseudos[i][0]
        let l2 = pseudos[i][1]
        let l1Adj = getAdj(l1, b)
        result.hexes[getAdj(l2, b).filter(x => x in l1Adj)[0]].stone = hexList[l1].stone

func evald0(b : Board) : float =
    var b = b.findPseudos.remove3cycPseudos(b).fillPseudos(b)
    let hexList = b.hexes
    let (wStones, bStones) = (hexList.filter(x => x.stone == WH).map(x => x.pos.posToInd()), hexList.filter(x => x.stone == BL).map(x => x.pos.posToInd))
    var mpW, mpB = 500
    for w in wStones:
        let wPwLen = pwLen(b, w, true)
        if wPwLen < mpW:
            mpW = wPwLen
    for w in bStones:
        let bPwLen = pwLen(b, w, false)
        if bPwLen < mpB:
            mpB = bPwLen
    if mpB == 0:
        return float.high
    elif mpW == 0:
        return float.low
    return float mpW - mpB


func getMoves(b : Board) : seq[int] =
    for i in 0..<b.hexes.len:
        if b.hexes[i].stone == NONE:
            result.add i

func hash(h : Hex) : Hash = hash(h.pos)

let str = "32w22w1w22b13b13b10b"
let board = str.loadHFen
echo evald0 board

var depth : int
var turn = 0

func miniMax(d : int, b : Board, whiteMoves : bool, e1, e2 : float) : (float, int) = ## this has a-b pruning, but branching factor of Hex is just too high for it to be usable
    var b = b
    var (e1, e2) = (e1, e2)
    if d == 0:
        return (evald0(b), -1)
    for i in b.getMoves:
        if i mod 100 == 0: debugEcho i
        b.hexes[i].stone = stArr[whiteMoves]
        let z = miniMax(d - 1, b, not whiteMoves, e2, e1)
        b.hexes[i].stone = NONE
        if z[0] >= e2 == whiteMoves or z[0] == e2:
            debugEcho "snip"
            return (e2, -1)
        if z[0] < e1 == whiteMoves:
            e1 = z[0]
            result = (z[0], i)

depth = 2

# MCTS

type McNode = ref object
    board : Board
    kids : seq[McNode]
    parentalUnit : McNode
    wins, visits : int
    whiteMoves : bool
    move : int # Move made to reach state


func getBoards(n : McNode, b : Board, whiteMoves : bool) : seq[Board] =
    var b = b
    for i in 0..<b.hexes.len:
        if b.hexes[i].stone == NONE:
            b.hexes[i].stone = stArr[whiteMoves]
            result.add b
            b.hexes[i].stone = NONE

func getMcBoards(n : McNode, whiteMoves : bool) : seq[McNode] =
    var b = n.board
    for i in 0..<b.hexes.len:
        if b.hexes[i].stone == NONE:
            b.hexes[i].stone = stArr[whiteMoves]
            result.add McNode(board : b, parentalUnit : n, whiteMoves : not whiteMoves)
            b.hexes[i].stone = NONE

func mcPick(n : McNode) : McNode =
    var bestKid : (float, McNode) = (float.low, n.kids[0])
    for kid in n.kids:
        let score = kid.wins/kid.visits + sqrt(4f*n.visits)/kid.visits
        if score > bestKid[0]:
            bestKid = (score, kid)
    return bestKid[1]

func mcWalk(rt : McNode) : McNode =  ## walk to a leaf/terminal node
     result = rt
     var tMoves : int
     for z in result.board.hexes:
         if z.stone == NONE: tMoves += 1
     while result.kids.len == tMoves:
         result = mcPick result

proc mcGrow(n : McNode) : McNode =
    let mv = getMcBoards(n, n.whiteMoves).filter(x => x notin n.kids).sample
    n.kids.add mv
    return n.kids[^1]

func mcCheckVic(b : Board) : int = # 1 for Black, -1 for white, 0 for neutral
    let hexList = b.hexes
    var sFront : seq[LocPri]
    for i in 0..12:
        if hexList[i].stone == BL:
            sFront.add (i, 12f64)
    var seen : set[uint8]
    var c : int # current

    while sFront.len > 0:
        let minx = minIndex sFront
        c = sFront[minx][0]
        sFront.del minx
        if hexList[c].pos.y == 12: return 1

        for w in getAdj(c, b):
            if hexList[w].stone != BL and w.uint8 notin seen:
                sFront.add (w, float64(12f64 - hexList[w].pos.y))
                seen.incl w.uint8

    sFront = @[]
    for i in 0..12:
      let ind = makevec2(0, i).posToInd
      if hexList[ind].stone == WH:
          sFront.add (makevec2(0, i).posToInd, 12f64)
    seen = {}

    while sFront.len > 0:
        let minx = minIndex sFront
        c = sFront[minx][0]
        sFront.del minx
        if hexList[c].pos.x == 12: return -1

        for w in getAdj(c, b):
            if hexList[w].stone != BL and w.uint8 notin seen:
                sFront.add (w, float64(12- hexList[w].pos.x))
                seen.incl w.uint8

# proc mcRollout(n : McNode) : int =
#     let results = [false : 1, true : 0]
#     var b = n.board
#     var whiteMoves = n.whiteMoves
#     var wStones, bStones : seq[int]
#     result = mcVicCheck(b)
#     if result != 0: return result

#     while true:
#         var c = b.getMoves.sample
#         b.hexes[c].stone = stArr[whiteMoves]
#         if pwLen(b, c, whiteMoves) == 0: return results[whiteMoves]
#         whiteMoves = not whiteMoves

proc mcRollout(n : McNode) : int =
    var b = n.board
    var movesLeft : set[uint8]
    for i in 0..<b.hexes.len:
        if b.hexes[i].stone == NONE:
            movesLeft.incl uint8 i
    # var whiteMoves = n.whiteMoves # Not using tMoves mod 2 since I want to support impossible positions where one side has more stones
    var r : int
    let tMoves = movesLeft.len
    let movesP1 = int grEqCeil(tMoves/2)
    for i in movesLeft:
        r = rand(0..<tMoves)
        b.hexes[i].stone = stArr[r <= movesP1 == n.whiteMoves]
    return mcCheckVic b

func mcWalkBack(n : McNode, res : int) =
    if n.parentalUnit.visits == -1:
        return
    var res = res
    if n.whiteMoves: n.wins += 1 - res
    else: n.wins += res
    n.visits += 1
    mcWalkBack(n.parentalUnit, res)

proc mcMonte(rt : McNode) =
    var leaf = rt.mcWalk
    var tNode = leaf.mcGrow
    var res = tNode.mcRollout
    tNode.mcWalkBack(res)

var mcRoot = McNode(board : board, parentalUnit : McNode(visits : -1))
for o in 0..100000:
    if o mod 5000 == 0: echo o
    mcRoot.mcMonte()
echo mcRoot.mcPick.board.hexes.filter(x => x notin mcRoot.board.hexes)[0].pos
echo mcRoot.mcPick.board.hFen, " <- ", mcRoot.board.hFen

