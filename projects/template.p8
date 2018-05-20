pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- template.p8
-- tdjx
--
-- basic template, good for new
-- projects

-----------------------------------
-- pico-8 game callbacks --
-----------------------------------
function _init()
end

function _update60()
end

function _draw()
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
	return flr(rnd_rng(l, h))
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
