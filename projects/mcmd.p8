pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- mcmd.p8
-- tdjx
--

function new_msl()
	local msl ={}

	msl.tgx = m.rndri(5, 122)
	msl.tgy = 120
	msl.stx = m.rndri(5, 122)
	msl.sty = -5
	msl.x = msl.stx
	msl.y = msl.sty
	msl.dx = msl.tgx - msl.x
	msl.dy = msl.tgy - msl.y
	msl.dx,  msl.dy = m.norm(
		msl.dx, msl.dy)
	msl.spd = 0.5
	msl.dx *= msl.spd
	msl.dy *= msl.spd
	msl.trail = {}
	msl.dead = false
	msl.state = 0
	msl.frm = 0

	return msl
end

function msl_update(msl)
	if msl.state == 0 then
		msl.frm += 1
		msl.x += msl.dx
		msl.y += msl.dy

		if msl.y > 120 then
			msl.state = 1
		end

		local idx = flr(msl.x) +
			flr(msl.y) * 128
		if not contains(msl.trail, idx)
			and idx >= 0 and idx < 128 * 128
		then
			add(msl.trail, idx)
		end

		if #msl.trail > 50 then
			idel(msl.trail, 1)
		end

		for sh in all(shots) do
			if sh.state == 1 or sh.state == 2
			then
				if m.dist(msl.x, msl.y,
					sh.x, sh.y) <= sh.r
				then
					msl.state = 1
				end
			end
		end
	elseif msl.state == 1 then
		idelr(msl.trail, 1, 1)
		if #msl.trail == 0 then
			msl.dead = true
		end
	end
end

function msl_draw(msl)
	for idx in all(msl.trail) do
		local x = idx % 128
		local y = flr(idx / 128)
		pset(x, y, 8)
	end

	if msl.state == 0 and
		msl.frm % 16 < 8
	then
		local x = msl.x
		if msl.dx < 0 then
			x -= 1
		end
		rectfill(x,msl.y,
			x+1,msl.y+1,7)
		-- pset(msl.x, msl.y, 7)
	end
end

function new_shot(tx, ty)
	local shot = {}

	shot.sx = 64
	shot.sy = 116
	shot.x = shot.sx
	shot.y = shot.sy
	shot.tx = tx
	shot.ty = ty
	shot.dx = shot.tx - shot.x
	shot.dy = shot.ty - shot.y
	shot.dx, shot.dy = m.norm(
		shot.dx, shot.dy)
	shot.dx *= 3
	shot.dy *= 3
	shot.state = 0
	shot.r = 0
	shot.maxr = 12
	shot.dr = 0.2
	shot.col = 8

	return shot
end

function shot_update(shot)
	if shot.state == 0 then
		shot.x += shot.dx
		shot.y += shot.dy

		local dtx = abs(shot.tx - shot.x)
		local dty = abs(shot.ty - shot.y)

		if (m.invlerp(shot.sx, shot.tx,
				shot.x) >= 1 or dtx == 0) and
			(m.invlerp(shot.sy, shot.ty,
				shot.y) or dty == 0)
		then
			shot.x = shot.tx
			shot.y = shot.ty
			shot.state = 1
		end
	elseif shot.state == 1 then
		shot.r += shot.dr
		if shot.r > shot.maxr then
			shot.r = shot.maxr
			shot.state = 2
		end
	elseif shot.state == 2 then
		shot.r -= shot.dr
		if shot.r < 0 then
			shot.r = 0
			shot.dead = true
		end
	end
	if t % 4 == 0 then
		shot.col += 1
		if (shot.col > 14) shot.col = 8
	end
end

function shot_draw(shot)
	if shot.state == 0 then
		rectfill(shot.x-1,shot.y,
			shot.x+1,shot.y,
			7)
	else
		circfill(shot.x, shot.y, shot.r, shot.col)
	end
end


-----------------------------------
-- main --
-----------------------------------
function _init()
	t = 0
	tdel = 1

	ps = false
	pm = false

	curx = 63
	cury = 63

	missiles = {}
	missiles.rq = {}

	shots = {}
	shots.rq = {}
end

function _update60()
	t += 1
	if t % tdel ~= 0 then
		cls()
		return
	end

	if not ps and btn(4) then
		ps = true
		-- add(missiles, new_msl())
		add(shots, new_shot(curx, cury))
	elseif ps and not btn(4) then
		ps = false
	end

	if not pm and btn(5) then
		pm = true
		add(missiles, new_msl())
	elseif pm and not btn(5) then
		pm = false
	end

	local n = #missiles
	for i = 1, n do
		msl_update(missiles[i])
		if missiles[i].dead then
			add(missiles.rq, i)
		end
	end
	idelfa(missiles, missiles.rq)
	clra(missiles.rq)

	local n = #shots
	for i = 1, n do
		shot_update(shots[i])
		if shots[i].dead then
			add(shots.rq, i)
		end
	end
	idelfa(shots, shots.rq)
	clra(shots.rq)

	local spd = 1
	if btn(5) then
		spd = 2
	end

	if btn(1) then
		curx += spd
	end

	if btn(0) then
		curx -= spd
	end

	if btn(3) then
		cury += spd
	end

	if btn(2) then
		cury -= spd
	end
end

function _draw()
	cls()
	map(0, 0, 0, 0, 16, 16)
	foreach(missiles, msl_draw)
	foreach(shots, shot_draw)
	spr(32, curx - 1, cury - 1)
end
-----------------------------------

-----------------------------------
-- _____  ___     _   _
--  | |  | | \   | | \ \_/
--  |_|  |_|_/ \_|_| /_/ \
--  _    _____  _   _
-- | | |  | |  | | | |
-- \_\_/  |_|  |_| |_|__
-----------------------------------
-- tdjx stdlib
--
-----------------------------------
-- math --
-----------------------------------
m = {}

-- linear interpolation
function m.lerp(a, b, t)
    return a + (b - a) * t
end

function m.invlerp(a, b, c)
	-- c = a+(b-a)t
	-- c-a = (b-a)t
	-- (c-a)/(b-a)=t
	if b-a ~= 0 then
		return (c-a)/(b-a)
	else
		return 0
	end
end

function m.anglerp(a, b, t)
    local ax, ay = m.dir(a)
    local bx, by = m.dir(b)
    return m.atan2(m.lerp(ax, bx, t),
        m.lerp(ay, by, t))
end

-- sin but with degrees
function m.sin(deg)
    return sin(deg / 360)
end

-- cos but with degrees
function m.cos(deg)
    return cos(deg / 360)
end

-- atan2 in degrees
function m.atan2(dx, dy)
    return atan2(dx, dy) * 360
end

-- find delta angle between
-- a1 and a2 in degrees
function m.dang(a1, a2)
    local a = a2 - a1
    return m.mod((a + 180), 360) - 180
end

-- proper modulo that handles
-- negatives appropriately
function m.mod(a, b)
    return (a % b + b) % b
end

-- clamp value v within boundaries
-- low and high
function m.clamp(v, low, high)
    return max(min(v, high), low)
end

-- euclidean distance between
-- points at x1,y1 and x2,y2
function m.dist(x1, y1, x2, y2)
    return sqrt(m.dist2(x1, y1,
        x2, y2))
end

-- squared distance between
-- points at x1,y1 and x2,y2
-- avoids sqrt operation
function m.dist2(x1, y1, x2, y2)
    return (x2 - x1) * (x2 - x1)
        + (y2 - y1) * (y2 - y1)
end

-- magnitude of vector <x,y>
function m.mag(x, y)
    return m.dist(0, 0, x, y)
end

-- magnitude squared of <x,y>
-- avoids sqrt operation
function m.mag2(x, y)
    return m.dist2(0, 0, x, y)
end

function m.norm(x, y)
    local l = m.mag(x, y)
    if l ~= 0 then
        return x / l, y / l
    else
        return 0, 0
    end
end

function m.dir(deg)
    return m.cos(deg), m.sin(deg)
end

-- move value v towards f at rate
-- dv but do not exceed f
function m.moveto(v, f, dv)
    if v < f then
        v += dv
        if v > f then v = f end
    elseif v > f then
        v -= dv
        if v < f then v = f end
    end
    return v
end

-- random decimal value
-- in range [l..h] (inclusive)
function m.rndr(l, h)
    return l + rnd(h - l)
end

-- random integer value
-- in range [l..h] (inclusive)
function m.rndri(l, h)
    return flr(m.rndr(l, h))
end
--------------------------------

-----------------------------------
-- table utilities --
-----------------------------------
-- clear array
function clra(arr)
    for i, _ in pairs(arr) do
        arr[i] = nil
    end
end

function cpya(arr, dst)
  if dst then
    clra(dst)
  else
    dst = {}
  end
  for i = 1, #arr do
    dst[i] = arr[i]
  end
  return dst
end

function idxof(arr, v)
    local n = #arr
    for i = 1, n do
        if arr[n] == v then
            return i
        end
    end
    return -1
end

function contains(arr, v)
    return idxof(arr, v) >= 0
end

-- fast add, no check
function fadd(t, v)
    t[#t+1] = v
end

-- fast del, swap in last element
-- instead of maintaining order
function delf(t, v)
    local n = #t
    for i = 1, n do
        if t[i] == v then
            t[i] = t[n]
            t[n] = nil
            return true
        end
    end
    return false
end

-- delete at index, maintain order
function idel(t, i)
    local n = #t
    if i > 0 and i <= n then
        for j = i, n - 1 do
            t[j] = t[j + 1]
        end
        t[n] = nil
        return true
    end
    return false
end

-- delete [s, e], maintain order
-- compress for space
function idelr(t, s, e)
    local n = #t
    e = min(n, e)
    local d = e - s + 1
    for i = s, e do
        t[i] = nil
    end
    for i = e + 1, n do
        t[i - d] = t[i]
        t[i] = nil
    end
end

-- delete at index, swap in last
-- element, loses ordering
function idelf(t, i)
    local n = #t
    if i > 0 and i <= n then
        t[i] = t[n]
        t[n] = nil
        return true
    end
    return false
end

-- fast deletion of an array of
-- indices
function idelfa(arr, idx)
    local l = #arr

    for i in all(idx) do
        arr[i] = nil
    end
    if (#idx == l) return
    for i = 1, l do
        if arr[i] == nil then
            while not arr[l]
                and l > i
            do
                l -= 1
            end
            if i ~= l then
                arr[i] = arr[l]
                arr[l] = nil
            else return end
        end
    end
end
-----------------------------------

-----------------------------------
-- logging --
-----------------------------------
err = {}
err.dur = 120

function err_log(msg)
    add(err, { msg = msg,
        f = err.dur })
end

function err_update()
    for e in all(err) do
        e.f -= 1
        if e.f <= 0 then
            del(err, e)
        end
    end
end

function err_draw()
    local y = 0
    for e in all(err) do
        local x = 64 - #e.msg * 2
        print(e.msg, x, y, 8)
        y += 6
    end
end

lg = {}
lg.f = 0
lg.max = 6

function log(msg)
    lg.f = 120
    local n = #lg
    if n >= lg.max then
        idel(lg, 1)
        lg[n] = msg
    else
        add(lg, msg)
    end
end

function log_update()
    if (lg.f > 0) lg.f -= 1
end

function log_draw()
    if lg.f > 0 then
        local y = 0
        for m in all(lg) do
            print(m, 127-#m*4, y, 7)
            y += 6
        end
    end
end

dbglg = {}

function dbg(msg)
    add(dbglg, msg)
end

function dbg_update()
    clra(dbglg)
end

function dbg_draw()
    local y = 0
    for d in all(dbglg) do
        print(d, x, y, 11)
        y += 7
    end
end
-----------------------------------
__gfx__
00000000444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000444444444444444400000044440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700444444444444444400004444444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000444444444444444400444444444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000444444444444444444444444444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001001d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01ad0ad0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a1d01a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200100010001003041000100010000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
