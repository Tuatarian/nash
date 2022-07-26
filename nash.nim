import raylib, jnhex, zero_functional, sequtils, rayutils, tables, heapqueue, lenientops, sugar, algorithm, random, std/enumerate, sets, hashes

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

func pathToWall(b : Board, h : int, whiteMoves : bool) : (seq[int], seq[int]) =
    let hexList = b.hexes
    var path : Table[int, int] = {h : -1}.toTable
    var sFront : HeapQueue[LocPri]= [(h, 0.001f64)].toHeapQueue
    var costs : Table[int, int] = {h : 0}.toTable # (inx, cost) // cost == 1 if hex empty, cost == 0 if hex has correct color
    var c : int # current
    var done : (bool, bool)

    if whiteMoves:
        while sFront.len > 0:
            c = sFront.pop()[0]
            if hexList[c].pos.x == 0 and not done[0]:
                result[0] = getPath(path, c).reversed.filter(x => hexList[x].stone == NONE)
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
                if hexList[w].stone != BL and (w notin path.keys.toSeq or wSteps < costs[w]):
                    sFront.push (w, wSteps.float)
                    path[w] = c
                    costs[w] = costs[c] + int(hexList[w].stone == NONE)
    else:
        while sFront.len > 0:
            c = sFront.pop()[0]
            if hexList[c].pos.y == 0 and not done[0]:
                result[0] = getPath(path, c).reversed.filter(x => hexList[x].stone == NONE)
                done[0] = true
                if done[1]:
                    return result
            elif hexList[c].pos.y == 12 and not done[1]:
                result[1] = getPath(path, c).reversed.filter(x => hexList[x].stone == NONE)
                done[1] = true
                if done[0]:
                    return result

            for w in getAdj(c, b):
                 let wSteps = costs[c] + int(hexList[w].stone == NONE)
                 if hexList[w].stone != WH and (w notin path.keys.toSeq or wSteps < costs[w]):
                     sFront.push (w, wSteps.float)
                     path[w] = c
                     costs[w] = costs[c] + int(hexList[w].stone == NONE)

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
    debugEcho b.hFen
    let hexList = b.hexes
    let (wStones, bStones) = (hexList.filter(x => x.stone == WH).map(x => x.pos.posToInd()), hexList.filter(x => x.stone == BL).map(x => x.pos.posToInd))
    var mpW, mpB = 500
    for w in wStones:
        let wPwLen = pwLen(b, w, true)
        if wPwLen < mpW:
            debugEcho pathToWall(b, w, true)[1].map(x => b.hexes[x].pos)
            mpW = wPwLen
            debugEcho b.hexes[w].pos, "W"
    for w in bStones:
        let bPwLen = pwLen(b, w, false)
        if bPwLen < mpB:
            debugEcho pathToWall(b, w, false)[0].map(x => b.hexes[x].pos)
            debugEcho pathTowall(b, w, false)[1].map(x => b.hexes[x].pos)
            mpB = bPwLen
            debugEcho b.hexes[w].pos, "b"
    debugEcho mpB, mpW
    return float mpW - mpB


func getMoves(b : Board, whiteMoves : bool) : seq[int] =
    for i in 0..<b.hexes.len:
        if b.hexes[i].stone == NONE:
            result.add i

func hash(h : Hex) : Hash = hash(h.pos)

let str = "32w22w1w22b13b13b10b"
let board = str.loadHFen
echo evald0 board
