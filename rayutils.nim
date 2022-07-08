import raylib, math, hashes, sugar, macros, strutils, lenientops, algorithm, random, os, sequtils

randomize()

template BGREY*() : auto = makecolor("111111", 255)
template AGREY*() : auto = makecolor("222222", 255)
template OFFWHITE*() : auto = makecolor(235, 235, 235)
template LEMMIRED*() : auto = makecolor("F32A2A")
template WHITEE*() : auto = makecolor("EEEEEE", 255)
template WHITED*() : auto = makecolor("DDDDDD", 255)
template CLEAR*() : auto = makecolor(0, 0, 0, 0)
template GREY*() : auto = GRAY

type Triangle* = object
    v1* : Vector2
    v2* : Vector2
    v3* : Vector2

type Circle* = object
    rad : float
    center : Vector2

func makevec2*(x, y: SomeInteger | SomeFloat) : Vector2 {.inline.} =  ## Easy vec2 constructor
    Vector2(x : float x, y : float y)

func makevec2*[T](a : openArray[T]) : Vector2 =
    assert a.len == 2
    return makevec2(a[0], a[1])

func makecolor*(f, d, l : int | float | uint8, o : uint8 = 255) : Color = ## Easy color constructor
    return Color(r : uint8 f, g : uint8 d, b : uint8 l, a : uint8 o)

func makecolor*(s : string, alp : uint8 = 255) : Color =
    return makecolor(fromHex[uint8]($s[0..1]), fromHex[uint8]($s[2..3]), fromHex[uint8]($s[4..5]), alp)

func colHex*(c : Color) : string =
    c.r.toHex & c.g.toHex & c.b.toHex

const colorArr* : array[27, Color] = [LIGHTGRAY, GRAY, DARKGRAY, YELLOW, GOLD, ORANGE, PINK, RED, MAROON, GREEN, LIME, DARKGREEN, SKYBLUE, BLUE, DARKBLUE, PURPLE, VIOLET, DARKPURPLE, BEIGE, BROWN, DARKBROWN, WHITE, BGREY, MAGENTA, RAYWHITE, BGREY, OFFWHITE] ## Array of all rl colours

func maketri*(v1, v2, v3  : Vector2) : Triangle = Triangle(v1 : v1, v2 : v2, v3 : v3)

func sigmoid*(x : int | float, a : int | float = 1, b : int | float = E, h : int | float = 1, k : int | float = 0, z : int | float = 0) : float = ## Sigmoid in the form a(1/1 + e^(hx + z)) + k
    return a * 1/(1 + pow(b, h * x + z)) + k

template iterIt*(s, op : untyped) : untyped =
    for i in low(s)..high(s):
        let it {.inject.} = s[i]
        op

func `+`*(v, v2 : Vector2) : Vector2 =
    result.x = v.x + v2.x
    result.y = v.y + v2.y

func `-`*(v, v2 : Vector2) : Vector2 =
    result.x = v.x - v2.x
    result.y = v.y - v2.y

func `-`*[T](v : Vector2, n : T) : Vector2 =
    result.x = v.x - n
    result.y = v.y - n

func `-`*[T](n : T, v : Vector2) : Vector2 =
    result.x = v.x - n
    result.y = v.y - n

func `+`*[T](v : Vector2, n : T) : Vector2 =
    result.x = v.x + n
    result.y = v.y + n

func `+`*[T](n : T, v : Vector2) : Vector2 =
    result.x = v.x + n
    result.y = v.y + n

func `+=`*[T](v : var Vector2, t : T) = 
    v = v + t

func `*=`*[T](v : var Vector2, t : T) =
    v = v * t

func `/`*(v, v2 : Vector2) : Vector2 =
    result.x = v.x / v2.x
    result.y = v.y / v2.y

func `/`*(v, : Vector2, f : float) : Vector2 =
    result.x = v.x / f
    result.y = v.y / f

func `/`*(v, : Vector2, i : int) : Vector2 =
    result.x = v.x / float i
    result.y = v.y / float i

func `/=`*[T](v : var Vector2, t : T) =
    v = v / t

func mag*(v : Vector2) : float =
    sqrt(v.x^2 + v.y^2)

func `div`*(v : Vector2, f : float) : Vector2 =
    result.x = ceil(v.x / f)
    result.y = ceil(v.y / f)

func `div`*(v, v2 : Vector2) : Vector2 =
    result.x = ceil(v.x / v2.x)
    result.y = ceil(v.y / v2.y)

func `div`*(v, : Vector2, i : int) : Vector2 =
    result.x = float v.x.int div i
    result.y = float v.y.int div i

func `mod`*(v, v2 : Vector2) : Vector2 =
    return makevec2(v.x mod v2.x, v.y mod v2.y)

func `*`*(v, v2 : Vector2) : Vector2 =
    result.x = v.x * v2.x
    result.y = v.y * v2.y

func `*`*(v : Vector2, i : int | float | float32) : Vector2 =
    return makevec2(v.x * float32 i, v.y * float32 i)

func `*`*(i : int | float | float32, v : Vector2) : Vector2 =
    return makevec2(v.x * float32 i, v.y * float32 i)

func `dot`*(v, v2 : Vector2) : float = ## Dot product of 2 vecs
    return (v.x * v2.x) + (v.y * v2.y)

func `*`*(v : Vector2, mat : seq[int] | seq[float]) : Vector2 = ## Requires 2x2 matrix atm
    let
        x = v.x
        y = v.y
        a = mat[0]
        b = mat[1]
        c = mat[2]
        d = mat[3]
    return makevec2((x * a) + (y * c), (x * b) + (y * d))

func getRotMat*(th : int | float | float32) : seq[int] | seq[float] = ## Get Rotation Matrix, Radians, [[a, b],[c,d]] -> [a, b, c, d]
    return @[cos th, -sin th, sin th, cos th]

func det(mat : openArray[int | SomeFloat]) : int | SomeFloat = ## 2x2 matrix required, column order ie [a, c, b, d]
    assert mat.len == 4
    mat[0]*mat[3] - mat[2]*mat[1] 

func rotateVec*(v : Vector2, th : int | float | float32) : Vector2 = ## About the origin
    return makevec2(v.x * cos(th) + v.y * sin(th), -v.x * sin(th) + v.y * cos(th))

func rotateVecAbout*(v : Vector2, th : int | float | float32, c : Vector2) : Vector2 = (v - c).rotateVec(th) + c

proc rotateVecSeq*(s : seq[Vector2], th : int | float | float32, c : Vector2) : seq[Vector2] = s.mapIt rotateVecAbout(it, th, c)

func `<|`*(v : Vector2, n : float32 | int | float) : bool = ## True if either x or y < x2 or y2
    return v.x < n or v.y < n

func `<|`*(v, v2 : Vector2) : bool = ## True if either x or y < x2 or y2
    return v.x < v2.x or v.y < v2.y

func `|>`*(v : Vector2, n : float32 | int | float) : bool = ## True if either x or y > x2 or y2
    return v.x > n or v.y > n

func `|>`*(v, v2 : Vector2) : bool = ## True if either x or y > x2 or y2
    return v.x > v2.x or v.y > v2.y

func `<&`*(v : Vector2, n : float32 | int | float) : bool = ## True if both x and y < x2 and y2
    return v.x < n and v.y < n

func `<&`*(v : Vector2, v2 : Vector2) : bool = ## True if both x and y < x2 and y2
    return v.x < v2.x and v.y < v2.y

func `&>`*(v : Vector2, n : float32 | int | float) : bool = ## True if both x and y > x2 and y2
    return v.x < n and v.y < n

func `&>`*(v : Vector2, v2 : Vector2) : bool = ## True if both x and y > x2 and y2
    return v.x > v2.x and v.y > v2.y

template `$$`*[T](t : T) : cstring = cstring t ## cast to cstring

func drawTextCentered*(s : string, x, y, fsize : int, colour : Color) =
    let tSizeVec = MeasureTextEx(GetFontDefault(), s, float fsize, max(20 ,fsize) / 20) div 2 # max(20, fsize) is black box to me
    DrawText s, x - tSizeVec.x.int, y - tSizeVec.y.int, fsize, colour

func drawTextCenteredX*(s : string, x, y, fsize : int, colour : Color) =
    let tSizeVec = MeasureTextEx(GetFontDefault(), s, float fsize, max(20,fsize) / 10) div 2  # max(20, fsize) is black box to me
    DrawText s, x - tSizeVec.x.int, y, fsize, colour

func drawTextCenteredY*(s : string, x, y, fsize : int, colour : Color) =
    let tSizeVec = MeasureTextEx(GetFontDefault(), s, float fsize, max(20 ,fsize) / 20) div 2 # max(20, fsize) is black box to me
    DrawText s, x, y - tSizeVec.y.int, fsize, colour

func DrawTriangle*(t : Triangle, c : Color) = DrawTriangle(t.v1, t.v2, t.v3, c)

func DrawTriangleLines*(t : Triangle, c : Color) = DrawTriangleLines(t.v1, t.v2, t.v3, c)

proc int2bin*(i : int) : int =
    var i = i
    var rem = 1
    var tmp = 1
    while i != 0:
        rem = i mod 2
        i = i div 2
        result = result + rem * tmp
        tmp = tmp * 10

func makerect*(v, v2 : Vector2) : Rectangle = ## Make sure v2 is below and right of v
    Rectangle(x : v.x, y : v.y, width : v2.x - v.x, height : v2.y - v.y)

func makerect*(x: SomeInteger | SomeFloat, y : SomeInteger | SomeFloat, w : SomeInteger | SomeFloat, h : SomeInteger | SomeFloat) : Rectangle =
    Rectangle(x : float x, y : float y, width : float w, height : float h)

func `in`*(v : Vector2, r : Rectangle) : bool =
    return (v.x in r.x..r.x + r.width) and (v.y in r.y..r.y + r.height)

func `notin`*(v : Vector2, r : Rectangle) : bool =
    return not(v in r)

func triInUtil(v, v2, v3 : Vector2) : float =
    return (v.x - v3.x) * (v2.y - v3.y) - (v2.x - v3.x) * (v.y - v3.y)

func `in`*(v, t1, t2, t3 : Vector2) : bool =
    let d = triInUtil(v, t1, t2)
    let d2 = triInUtil(v, t2, t3)
    let d3 = triInUtil(v, t3, t1)
    return not (((d < 0) or (d2 < 0) or (d3 < 0)) and ((d > 0) or (d2 > 0) or (d3 > 0)))

func `in`*(v : Vector2, tri : Triangle) : bool = return v.in(tri.v1, tri.v2, tri.v3)

func `notin`*(v : Vector2, t : Triangle) : bool = not(v in t)

func `notin`*(v : Vector2, v1, v2, v3 : Vector2) : bool = not(v in maketri(v1, v2, v3))

func `in`*(v : Vector2, v1, v2: Vector2) : bool =
    return v in makerect(v1, v2)

proc UnloadTexture*(texargs : varargs[Texture]) = ## runs UnloadTexture for each vararg
    texargs.iterIt(UnloadTexture it)

proc UnloadMusicStream*(musargs : varargs[Music]) = ## runs UnloadMusicStream on each vararg
    musargs.iterIt(UnloadMusicStream it)

proc UnloadSound*(soundargs : varargs[Sound]) = ## runs UnloadSound for each varargs
    soundargs.iterIt(UnloadSound it)

func toTuple*(v : Vector2) : (float32, float32) = ## Returns (x, y)
    return (v.x, v.y) 

func min*(v, v2 : Vector2) : Vector2 = ## Returns min of x and min of y (componentwise)
    return makevec2(min(v.x, v2.x), min(v.y, v2.y))

func minVargs*[T](args : varargs[T]) : T =
    for i in args:
        if i < result:
            result = i 

func max*(v, v2 : Vector2) : Vector2 = ## Returns max of x and max of y (componentwise)
    return makevec2(max(v.x, v2.x), max(v.y, v2.y))

func maxVargs*[T](args : varargs[T]) : T =
    for i in args:
        if i > result:
            result= i

func mean*[T](items : varargs[T]) : T = sum(items) / items.len

func ceil*(v : Vector2) : Vector2 = ## Returns ceil x, ceil y
    return makevec2(ceil v.x, ceil v.y)

func grEqCeil*(n : int | float | float32) : int | float | float32 = ## Ceil but inclusive
    if n == n.int.float:
        return n
    return ceil(n)

func grEqCeil*(v : Vector2) : Vector2 = ## Returns vec2 with x and y grEqCeiled
    return makevec2(grEqCeil v.x, grEqCeil v.y)

func `[]`*[T](container : seq[seq[T]], v : Vector2) : T = ## Vector2 access to 2d arrays
    return container[int v.x][int v.y]

func `[]`*[T](container : seq[seq[T]], x, y : int | float | float32) : T = ## [i, j] access to 2d arrays
    return container[int x][int y]

func `[]=`*[T](container : var seq[seq[T]], x, y : int | float | float32, d : T) = ## [i, j] setter for 2d arrays
    container[int x][int y] = d

func `[]=`*[T](container : var seq[seq[T]], v : Vector2, d : T) = ## Vector2 setter for 2d arrays
    container[int v.x][int v.y] = d

# func genSeqSeq*[T](y, x : int, val : T) : seq[seq[T]] = ## return a seq[seq[T]] populated with the given value. X and Y are reversed like with matrices
#     for i in 0..<y:
#         result.add @[]
#         for j in 0..<x:
#             result[i].add(val)

func `&=`*[T](s : var string, z : T) = 
    s = s & $z

func apply*(v : Vector2, op : proc(f : float32) : float32) : Vector2 = ## runs proc on x and y
    return makevec2(op v.x, op v.y)

func round*(v : Vector2) : Vector2 = ## round x, round y
    return makevec2(round v.x, round v.y)

func round*(v : Vector2 , places : int) : Vector2 = ## round x, round y
    return makevec2(round(v.x, places), round(v.y, places))

func roundToInt*(f : float) : int = 
    int round f

func roundDown*(v : Vector2) : Vector2 = ## rounds down x and y
    return makevec2(float32 int v.x, float32 int v.y)

proc roundDown*(n : float | float32) : float | float32 = ## rounds down
    return float int n

proc drawTexCentered*(tex : Texture, pos : Vector2, tint : Color) = ## Draws Texture from center
    tex.DrawTexture(int pos.x - tex.width / 2, int pos.y - tex.height / 2, tint)

proc drawTexCentered*(tex : Texture, posx, posy : int | float | float32, tint : Color) = ## Draws texture from center
    tex.DrawTexture(int posx + tex.width div 2, int posy + tex.height div 2, tint)

proc drawTexCenteredEx*(tex : Texture, pos : Vector2, rotation : float, scale : float, tint : Color) = ## Draws Texture from center
    tex.DrawTextureEx(makevec2(int pos.x - tex.width * scale / 2, int pos.y - tex.height * scale / 2), rotation, scale, tint)

proc drawTexCenteredEx*(tex : Texture, posx, posy : int | float | float32, rotation : float, scale : float, tint : Color) = ## Draws Texture from center
    tex.DrawTextureEx(makevec2(int posx - tex.width * scale / 2, int posy - tex.height * scale / 2), rotation, scale, tint)

func reflect*(i, tp : int | float) : int | float = ## Flips value over tp
    return tp * 2 - i

func reflect*(v : Vector2, tp : int | float) : Vector2 =
    return makevec2(tp * 2 - v.x, tp * 2 - v.y)

func abs*(v : Vector2) : Vector2 =
    return makevec2(abs v.x, abs v.y)

func cart2Polar*(v : Vector2, c = Vector2(x : 0, y : 0)) : Vector2 = ## (rho, theta)
    let v = v - c
    result.x = sqrt((v.x ^ 2) + (v.y ^ 2))
    result.y = arctan(v.y / v.x)
    if v.x < 0: result.y += PI

func polar2Cart*(r : int | float | float32, th : float | float32) : Vector2 = return makevec2(r * cos(th), r * sin(th))

func polar2Cart*(v : Vector2) : Vector2 = return makevec2(v.x * cos(v.y), v.x * sin(v.y))

func invert*(v : Vector2) : Vector2 = ## switches x and y
    return makevec2(v.y, v.x)

func dist*(v, v2 : Vector2) : float = ## distance of 2 vecs (Untested)
    return abs sqrt(((v.x - v2.x) ^ 2) + ((v.y - v2.y) ^ 2))

func makevec3*(i, j, k : float) : Vector3 = ## Easy vec3 constructor
    return Vector3(x : i, y : j, z : k)

proc hash*(v : Vector2) : Hash = ## Hash for vec2
    var h : Hash = 0
    h = h !& hash v.x
    h = h !& hash v.y
    result = !$h

# proc drawTriangleFan*(verts : varargs[Vector2], color : Color) = ## CONVEX polygon renderer
#     var inpoint : Vector2
#     var mutverts : seq[Vector2]
# 
#     for v in verts: 
#         inpoint = inpoint + v
#         mutverts.add(v)
#     
#     inpoint = inpoint / float verts.len
#     mutverts.add(verts[0])
# 
#     for i in 1..<mutverts.len:
#         var points = [inpoint, mutverts[i - 1], mutverts[i]]
#         var ininpoint = (points[0] + points[1] + points[2]) / 3
#         var polarpoints = [cart2Polar(points[0], ininpoint), cart2Polar(points[1], ininpoint), cart2Polar(points[2], ininpoint)]
#         for j in 0..points.len:
#             for k in 0..<points.len - 1 - j:
#                 if polarpoints[k].y > polarpoints[k + 1].y:
#                     swap(polarpoints[k], polarpoints[k + 1])
#                     swap(points[k], points[k + 1])
#         DrawTriangle(points[0], points[1], points[2], color)

func makeMat(v, v1 : Vector2) : array[4, float32] = ## s = col1, s1 = col2
    return [v.x, v.y, v1.x, v1.y]

func isCCW*(s : seq[Vector2]) : bool =
    assert s.len >= 3
    var area : float
    for i in 0..<s.len:
        area += (-s[i].x + s[(i + 1) mod s.len].x)*(s[i].y + s[(i + 1) mod s.len].y)
    return area > 0

proc drawPolygon*(verts : varargs[Vector2], color : Color, ccw : bool) = ## general polygon renderer, naive ear clipping. CCW = counter clockwise - renderer needs to know if points are ccw or cw
    var mutverts = verts.toSeq
    var tris : seq[Triangle]
    var marked = -1
    
    while mutverts.len > 3:
        if marked != -1:
            mutverts.delete marked
            marked = -1
        for i in 1..mutverts.len:
            let (v0, v1, v2) = (mutverts[i - 1], mutverts[i mod mutverts.len], mutverts[(i + 1) mod mutverts.len])
            if (v2.y - v1.y)/(v2.x - v1.y) == (v0.y - v1.y)/(v0.x - v1.x):
                marked = i
                break
            
            # check if triangle formed by v0, v1, v2 contains any other vertices of polygons
            var noVertIn = true
            for j in 0..<mutverts.len:
                if j != i - 1 and j != i mod mutverts.len and j != (i + 1) mod mutverts.len:
                    if mutverts[j] in maketri(v0, v1, v2):
                        noVertIn = false
            if not noVertIn: continue

            # check if vertex is reflex

            let (r0, r2) = (v0 - v1, v2 - v1)
            let det = r0.x*r2.y - r0.y*r2.x
            if det == 0: 
                marked = i
                break
            if ccw:
                if det > 0:
                    marked = i
                    tris.add maketri(v0, v1, v2)
                    break
            else:
                if det < 0:
                    marked = i
                    tris.add maketri(v2, v1, v0)
                    break
    for i in tris:
        DrawTriangle i, color
    if mutverts.len >= 3: # Gotta be in ccw order
        if ccw: DrawTriangle mutverts[0], mutverts[1], mutverts[2], color
        else: DrawTriangle mutverts[2], mutverts[1], mutverts[0], color

proc drawPolygon*(verts : varargs[Vector2], color : Color) = ## general polygon renderer, naive ear clipping. CCW = counter clockwise - renderer needs to know if points are ccw or cw
    var mutverts = verts.toSeq
    let ccw = mutverts.isCCW
    var tris : seq[Triangle]
    var marked = -1
    
    while mutverts.len > 3:
        if marked != -1:
            mutverts.delete marked
            marked = -1
        for i in 1..mutverts.len:
            let (v0, v1, v2) = (mutverts[i - 1], mutverts[i mod mutverts.len], mutverts[(i + 1) mod mutverts.len])
            if (v2.y - v1.y)/(v2.x - v1.y) == (v0.y - v1.y)/(v0.x - v1.x):
                marked = i
                break
            
            # check if triangle formed by v0, v1, v2 contains any other vertices of polygons
            var noVertIn = true
            for j in 0..<mutverts.len:
                if j != i - 1 and j != i mod mutverts.len and j != (i + 1) mod mutverts.len:
                    if mutverts[j] in maketri(v0, v1, v2):
                        noVertIn = false
            if not noVertIn: continue

            # check if vertex is reflex

            let (r0, r2) = (v0 - v1, v2 - v1)
            let det = r0.x*r2.y - r0.y*r2.x
            if det == 0: 
                marked = i
                break
            if ccw:
                if det > 0:
                    marked = i
                    tris.add maketri(v0, v1, v2)
                    break
            else:
                if det < 0:
                    marked = i
                    tris.add maketri(v2, v1, v0)
                    break
    for i in tris:
        DrawTriangle i, color
    if mutverts.len >= 3: # Gotta be in ccw order
        if ccw: DrawTriangle mutverts[0], mutverts[1], mutverts[2], color
        else: DrawTriangle mutverts[2], mutverts[1], mutverts[0], color

func normalize*(v : Vector2) : Vector2 = ## Normalize Vector
    return v / sqrt(v.x ^ 2 + v.y ^ 2)

func drawTexCenteredFromGrid*(tex : Texture, pos : Vector2, tilesize : int, tint : Color) =
    DrawTexture(tex, int32 pos.x * tilesize + (tilesize - tex.width) / 2, int32 pos.y * tilesize + (tilesize - tex.height) / 2, tint)

func drawTexFromGrid*(tex : Texture, pos : Vector2, tilesize : int, tint : Color) =
    DrawTexture(tex, int pos.x * tilesize, int pos.y * tilesize, tint)

func drawTexCenteredFromGrid*(tex : Texture, posx, posy : int, tilesize : int, tint : Color) =
    DrawTexture(tex, int32 posx * tilesize + (tilesize - tex.width) / 2, int32 posy * tilesize + (tilesize - tex.height) / 2, tint)

func drawTexFromGrid*(tex : Texture, posx, posy : int, tilesize : int, tint : Color) =
    DrawTexture(tex, int posx * tilesize, int posy * tilesize, tint)

# iterator spsplit*(s : string, key : char | string) : string = ## deprecated, not sure how this differs from strutils split iterator
#     var result : string
#     for c in s:
#         result &= c
#         if key in result:
#             yield result 
#             result = ""
#     yield result

func DrawCircle*(centerX : float, centerY : float, radius : float, tint : Color) =
    DrawCircle int centerX, int centerY, radius, tint

func drawLines*(pts : varargs[Vector2], col : Color) =
    for i in 0..<pts.len - 1:
        DrawLineV(pts[i], pts[i + 1], col)
    DrawLineV(pts[^1], pts[0], col)

func IsKeyDown*[N](k : array[N, KeyboardKey]) : bool =
    for key in k:
        if IsKeyDown(key): return true
    return false

proc echo*[T](s : seq[seq[T]]) =
    for i in 0..<s.len:
        for j in 0..<s[i].len:
            stdout.write s[i, j], ' '
        stdout.write('\n')

func angleToPoint*(v : Vector2) : float = ## Returns in Radians
    result = -arctan(v.y / v.x)
    if v.x != abs(v.x) and v.y == abs(v.y):
        result = arctan(-abs(v.y / v.x))
        result = reflect(result, PI / 2)
    if v.x != abs(v.x) and v.y != abs(v.y):
        result = arctan(abs(v.y / v.x))
        result = reflect(result, -PI / 2)

func isPositive*[T](t : T) : bool =
    t == abs(t)

func rectPoints*(rect : Rectangle) : array[4, Vector2] =
    return [makevec2(rect.x, rect.y), makevec2(rect.x + rect.width, rect.y), makevec2(rect.x + rect.width, rect.y + rect.height), makevec2(rect.x, rect.y + rect.height)]

iterator items*(tri : Triangle) : Vector2 =
    yield tri.v1
    yield tri.v2
    yield tri.v3

iterator pairs*(tri : Triangle) : (int, Vector2) = 
    yield (0, tri.v1)
    yield (0, tri.v2)
    yield (0, tri.v3)

proc shuffleIt*[T](s : seq[T]) : seq[T] =
    var s = s; shuffle s; return s

proc shuffleIt*[N, T](s : array[N, T]) : array[N, T] =
    var s = s; shuffle s; return s

iterator findAll*[T](s : openArray[T], val : T) : int =
    for i, x in s:
        if x == val:
            yield i

iterator findAll*[T](s : openArray[T], pred : (T) -> bool) : int =
    for i, x in s:
        if pred x:
            yield i

# func delaunayBW*(pts : seq[Vector2], super : Triangle) : seq[Triangle] = ##Bowyer-Watson implementation, super = super triangle containing all points in pts, O(n^2)
#     result.add super
#     for i in 0..<pts.len:
#         var bad : seq[Triangle]
#         # for j in 0..<result.len:

func sgnmod*(a : int, range : (int, int)) : int = (((a - range[0]) mod (range[1] - range[0])) + (range[1] - range[0])) mod (range[1] - range[0]) ## wrap number a around range (min, max)


func sgnmod*(a, min, max : int) : int = (((a - min) mod (max - min)) + (max - min)) mod (max - min) ## wrap number a around range (min, max)

# proc randf(a, b : float) : float {.inline.} = rand(b) + a ## less frustrating rand

func slope*(v, v1 : Vector2) : float = return (v.y - v1.y)/(v.x - v1.x) ## calculates slope of line defined by 2 points

func checkColLine*(v, v1, v2, v3 : Vector2) : (bool, Vector2) = ## v and v1 should form a segment, v2 and v3 should form the other segment. not sure what happens if intsec is at endpoint
    let m1 = slope(v2, v3)
    let b1 = v2.y - m1*v2.x

    let m = slope(v, v1)
    let b = v.y - m*v.x

    let colX = (b1 - b)/(m - m1)
    return (colX in min(v2.x, v3.x)..max(v2.x, v3.x) and colX in min(v.x, v1.x)..max(v.x, v1.x), makevec2(colX, m*colX + b))

func `inPoly`*(v : Vector2, poly : openArray[Vector2]) : bool = ## vec in polygon
    let outpoint = makevec2(poly.map(x => x.x).max + 10, poly.map(x => x.y).max + 10)
    if v |> outpoint: return false
    var hits : int
    for i in 0..<poly.len:
        let (p1, p2) = (poly[i], poly[(i + 1) mod poly.len])
        if checkColLine(v, outpoint, p1, p2)[0]: hits += 1
    return bool(hits mod 2)

func center*(r : Rectangle) : Vector2 = makevec2(r.x + r.width/2, r.y + r.height/2)

func checkColRec*(r : Rectangle, poly : openArray[Vector2]) : bool =
    let verts : array[4, Vector2] = [makevec2(r.x, r.y), makevec2(r.x + r.width, r.y), makevec2(r.x + r.width, r.y + r.height), makevec2(r.x, r.y + r.height)]
    if r.center.inPoly poly: return true
    for i in 0..<4:
        let (p1, p2) = (verts[i], verts[(i + 1) mod 4])
        for j in 0..<poly.len:
            let (v1, v2) = (poly[j], poly[(j + 1) mod poly.len])
            if checkColLine(p1, p2, v1, v2)[0]: return true
    return false

func makerect*(c : Vector2, w, h : int | SomeFloat) : Rectangle = return makerect(int(c.x - w/2), int(c.y - h/2), int w, int h) ## Center, width, height

func SetMousePosition*(v : Vector2) = SetMousePosition(v.x.int, v.y.int)

template lerp*[T](a, b : T, c : int | SomeFloat) : untyped = a + (b - a)*c ## Moves a towards b linearly by a factory of c

proc parseInt*(c : char) : int = parseInt $c

func manhattanDist*(v, v1 : Vector2) : SomeFloat = abs(v1.x - v.x) + abs(v1.y - v.y) ## unsigned distance