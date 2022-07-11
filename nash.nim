import raylib, jnhex, zero_functional, sequtils, rayutils, tables, heapqueue, lenientops, sugar, algorithm, random

randomize()

type LocPri = (int, float)

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

func pathToWall(b : Board, h : int, whiteMoves : bool) : seq[int] =
    let hexList = b.hexes
    var path : Table[int, int] = {h : -1}.toTable
    var sFront = @[h]
    var c : int # current

    if whiteMoves:
        while sFront.len > 0:
            c = sFront.pop()
            if hexList[c].pos.x == 0 or hexList[c].pos.x == 12:
                return getPath(path, c).reversed

            for w in getAdj(c, b):
                if w notin path.keys.toSeq and hexList[w].stone == NONE:
                    sFront.add w
                    path[w] = c
    else:
        while sFront.len > 0:
            c = sFront.pop()
            if hexList[c].pos.y == 0 or hexList[c].pos.y == 12:
                return getPath(path, c).reversed

            for w in getAdj(c, b):
                if w notin path.keys.toSeq and hexList[w].stone == NONE:
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

func findStrongPseudos(b : Board) : seq[(int, int)] =
    let hexList = b.hexes
    let wStones = hexList.filter(x => x.stone == WH).map(x => x.pos)
    let bStones = hexList.filter(x => x.stone == BL).map(x => x.pos)
    for i in 0..<wStones.len - 1:
        let iPseu = pseudoLocs(i, b)
        for j in (i + 1)..<wStones.len:
            if j in iPseu:
                let iAdj = getAdj(i, b)
                let jAdj = getAdj(j, b)
                if iAdj.filter(x => x in jAdj and hexList[x].stone == NONE).len == 2:
                    result.add (i, j)
    for i in 0..<bStones.len - 1:
        let iPseu = pseudoLocs(i, b)
        for j in i + 1..<bStones.len:
            if j in iPseu:
                let iAdj = getAdj(i, b)
                let jAdj = getAdj(j, b)
                if iAdj.filter(x => x in jAdj and hexList[x].stone == NONE).len == 2:
                    result.add (i, j)


func evald0(b : Board) : float =
    let hexList = b.hexes
    var mpW, mpB = 500
    let (wStones, bStones) = (hexList.filter(x => x.stone == WH).map(x => x.pos.posToInd()), hexList.filter(x => x.stone == BL).map(x => x.pos.posToInd))
    for i in 0..<wStones.len:
        let pwLen = pathToWall(b, i, true).len
        if pwLen < mpW:
            mpW = pwLen
    for i in 0..<bStones.len:
        let pwLen = pathToWall(b, i, false).len
        if pwLen < mpB:
            mpB = pwLen
    return float(mpB - mpW)


let board = getEmptyBoard()
echo pathToWall(board, posToInd makevec2(6, 7), true).map(x => board.hexes[x].pos)
