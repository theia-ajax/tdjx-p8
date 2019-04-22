pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

-- mines.p8
-- tdjx
--

k_mineflg = 8
k_flagflg = 4
k_revflg = 2
k_prsflg = 1

function new_cell(x, y)
	-- vflgs
	-- 76543210
	--
	-- 0: pressed
	-- 1: revealed
	-- 2: flagged
	-- 3: has mine
	-- 7654: neighbor count
	return {
		x = x,
		y = y,
		flags = 0b00000000
	}
end

function tobinstr(n, lz)
	lz = lz or 0
	local str = ""
	while n > 0 do
		str = tostr(n % 2)..str
		n = flr(n / 2)
	end
	local len = #str
	for i = len, lz - 1 do
		str = "0"..str
	end

	return str
end

function cell_hasmine(cell)
	if cell then
		return gflg(cell.flags, k_mineflg)
	else
		return false
	end
end

function cell_calcnbrs(cell)
	local n = 0
	if (cell_hasmine(cell_fromcs(cell.x-1,cell.y-1))) n += 1
	if (cell_hasmine(cell_fromcs(cell.x-1,cell.y))) n += 1
	if (cell_hasmine(cell_fromcs(cell.x-1,cell.y+1))) n += 1
	if (cell_hasmine(cell_fromcs(cell.x,cell.y-1))) n += 1
	if (cell_hasmine(cell_fromcs(cell.x,cell.y+1))) n += 1
	if (cell_hasmine(cell_fromcs(cell.x+1,cell.y-1))) n += 1
	if (cell_hasmine(cell_fromcs(cell.x+1,cell.y))) n += 1
	if (cell_hasmine(cell_fromcs(cell.x+1,cell.y+1))) n += 1
	cell_snbrs(cell, n)
	return n
end

-- set flag on
function cell_sf(c, flg)
	log(c.flags)
	c.flags = sflg(c.flags, flg, true)
end

-- clear flag to off
function cell_cf(c, flg)
	c.flags = sflg(c.flags, flg, false)
end

-- toggle flag
function cell_tf(c, flg)
	c.flags = sflg(c.flags, flg,
		not gflg(c.flags, flg))
end

-- get flag
function cell_gf(c, flg)
	return gflg(c.flags, flg)
end

function cell_snbrs(c, n)
	n = band(n, 0xf)
	n = shl(n, 4)
	c.flags = band(c.flags, 0xf)
	c.flags = bor(c.flags, n)
end

function cell_gnbrs(c)
	if c then
		local n = band(c.flags, 0xf0)
		return shr(n, 4)
	else
		return 0
	end
end

-- set flag
function sflg(bf, flg, v)
	if (v == nil) v = true
	if v then
		return bor(bf, flg)
	else
		return band(bf, bnot(flg))
	end
end

-- get flag
function gflg(bf, flg)
	return band(bf, flg) ~= 0
end

function board_fldrev(cx, cy)
	local c = cell_fromcs(cx, cy)
	if c and
		not gflg(c.flags, k_revflg) and
		not gflg(c.flags, k_mineflg) and
		not cell_gf(c, k_flagflg)
	then
		c.flags = sflg(c.flags, k_revflg, true)
		if cell_gnbrs(c) <= 0 then
			board_fldrev(cx-1, cy)
			board_fldrev(cx+1, cy)
			board_fldrev(cx, cy-1)
			board_fldrev(cx, cy+1)
			board_fldrev(cx-1, cy-1)
			board_fldrev(cx-1, cy+1)
			board_fldrev(cx+1, cy-1)
			board_fldrev(cx+1, cy+1)
		end
	end
end

function board_reveal(cx, cy)
	local c = cell_fromcs(cx, cy)
	if c and
		not cell_gf(c, k_revflg) and
		not cell_gf(c, k_mineflg)
	then
		if cell_gnbrs(c) == 0 then
			board_fldrev(cx, cy)
		else
			cell_sf(c, k_revflg)
		end
	end
end

function ct_mines()
	local sum = 0
	for c in all(board) do
		if gflg(c.flags, k_mineflg) then
			sum += 1
		end
	end
	return sum
end

function ct_flags()
	local sum = 0
	for c in all(board) do
		if gflg(c.flags, k_mineflg) and
			gflg(c.flags, k_flagflg)
		then
			sum += 1
		end
	end
	return sum
end

function chk_win()
	if ct_mines() == ct_flags() then
		gs = k_gswin
		for c in all(board) do
			if not cell_gf(c, k_mineflg)
			then
				cell_sf(c, k_revflg)
			end
		end
	end
end

function on_mclick(btn)
	if gs == k_gsplay then
		if btn == 1 then
			local cell = cell_fromws(mouse.x,
				mouse.y)
			if cell and
				not cell_gf(cell, k_flagflg)
			then
				cell_sf(cell, k_prsflg)
			end
			lmbcell = cell
		elseif btn == 2 then
			if not lmbcell then
				rmbcell = cell_fromws(mouse.x,
					mouse.y)
			end
		end
	elseif gs == k_gsmenu then
		if btn == 1 then
			start_play()
		end
	end
end

function on_mrelease(btn)
	local dead = false

	if gs == k_gsplay then
		if btn == 1 then
			local cell = cell_fromws(
				mouse.x, mouse.y)
			if cell and
				cell == lmbcell and
				not cell_gf(cell, k_flagflg)
			then
				if not cell_gf(cell, k_mineflg)
				then
					board_reveal(cell.x, cell.y)
					chk_win()
				else
					gs = k_gsdead
				end
			end
			if lmbcell then
				lmbcell.flags = sflg(lmbcell.flags,
					k_prsflg,
					false)
				lmbcell = nil
			end
		elseif btn == 2 then
			local cell = cell_fromws(
				mouse.x, mouse.y)
			if cell and
				cell == rmbcell and
				not cell_gf(cell, k_revflg)
			then
				cell_tf(cell, k_flagflg)
				chk_win()
			end
			rmbcell = nil
		end
	elseif gs == k_gsdead or
		gs == k_gswin
	then
		if btn == 1 then
			restart()
		end
	end
end

function draw_bfld(bf, x, y, lz)
	lz = lz or 8
	local bstr = tobinstr(bf, lz)
	for i = 1, #bstr do
		local c = sub(bstr, i, i)
		if c == "0" then
			line(x, y + 4, x, y + 4, 7)
		else
			line(x, y, x, y + 4, 7)
		end
		x += 1
	end
end

function cell_fromws(x, y)
	x = flr((x - board.ox) / board.cw)
	y = flr((y - board.oy) / board.ch)
	return cell_fromcs(x, y)
end

function cell_fromcs(x, y)
	if x < 0 or x >= board.w or
		y < 0 or y >= board.h
	then
		return nil
	end
	local idx = (y * board.w + x) + 1
	if idx >= 1 and idx <= #board
	then
		return board[idx]
	else
		return nil
	end
end

k_gsplay = 1
k_gsdead = 2
k_gswin = 3
k_gsmenu = 4

function restart()
	gs = k_gsplay
	pop_board(settings)
end

function pop_board(settings)
	local w, h, mct = settings.w,
		settings.h,
		settings.mct


	board = {}
	board.w = w
	board.h = h

	board.w = min(board.w, 21)
	board.h = min(board.h, 19)

	board.sz = board.w * board.h

	board.mct = min(mct, board.sz - 1)

	if board.w > 15 or
		board.h > 14
	then
		board.big = false
		board.cw = 6
		board.ch = 6
	else
		board.big = true
		board.cw = 8
		board.ch = 8
	end

	local tw = board.w * board.cw
	local th = board.h * board.ch
	board.ox = (128 - tw) / 2
	board.oy = (128 - th) / 2 + board.ch

	for i = 1, board.sz do
		local x = (i - 1) % board.w
		local y = flr((i - 1) / board.w)
		board[i] = new_cell(x, y)
	end

	local mct = board.mct
	while mct > 0 do
		local idx = -1
		while not board[idx] or
			cell_gf(board[idx], k_mineflg)
		do
			idx = m.rndri(1, board.sz)
		end
		cell_sf(board[idx], k_mineflg)
		mct -= 1
	end

	for x = 0, board.w - 1 do
		for y = 0, board.h - 1 do
			cell_calcnbrs(cell_fromcs(x, y))
		end
	end
end

k_spr_sm = {}
k_spr_sm["norm"] = 48
k_spr_sm["prsd"] = 49
k_spr_sm["rvld"] = 50
k_spr_sm["mine"] = 51
k_spr_sm["flag"] = 52
k_spr_sm["nmst"] = 31

k_spr_lg = {}
k_spr_lg["norm"] = 1
k_spr_lg["prsd"] = 2
k_spr_lg["rvld"] = 3
k_spr_lg["mine"] = 4
k_spr_lg["flag"] = 6
k_spr_lg["nmst"] = 15

function start_play()
	gs = k_gsplay
	pop_board(settings)
end

-----------------------------------
-- main --
-----------------------------------
function _init()
	poke(0x5f2d, 1)

	settings = {
		w = 16,
		h = 16,
		mct = 35,
	}

	mouse = {}
	mouse.x = 0
	mouse.y = 0
	mouse.btn = 0
	mouse.lbtn = 0
	mouse.cx = 0
	mouse.cy = 0

	gs = k_gsmenu
end

function _update60()
	loggers_update()

	mouse.x = stat(32)
	mouse.y = stat(33)

	mouse.lbtn = mouse.btn
	mouse.btn = stat(34)

	for b = 1, 3 do
		if band(mouse.btn, b) ~= 0 and
			band(mouse.lbtn, b) == 0
		then
			on_mclick(b)
		elseif band(mouse.btn, b) == 0
			and band(mouse.lbtn, b) ~= 0
		then
			on_mrelease(b)
		end
	end
end

function _draw()
	cls()

	local c = 1
	if (gs == k_gsdead) c = 8
	rect(0, 0, 127, 127, c)
	for y = 0, 256, 4 do
		line(0, y, y, 0, c)
	end

	if gs ~= k_gsmenu then
		draw_play()
	else

	end

	spr(5, mouse.x-3, mouse.y-3)
end

function draw_play()
	local spst = k_spr_lg
	if not board.big then
		spst = k_spr_sm
	end

	for cx = 0, board.w - 1 do
		for cy = 0, board.h - 1 do
			local idx = cy * board.w
				+ cx + 1
			local c = board[idx]

			local x = cx * board.cw + board.ox
			local y = cy * board.ch + board.oy

			local pv = cell_gf(c, k_prsflg)
			local rv = cell_gf(c, k_revflg)
			local fv = cell_gf(c, k_flagflg)
			local mv = cell_gf(c, k_mineflg)

			if rv then
				spr(spst["rvld"], x, y)
			elseif pv then
				spr(spst["prsd"], x, y)
			else
				spr(spst["norm"], x, y)
			end

			if rv then
				local nbrs = cell_gnbrs(c)
				if not mv and nbrs > 0 then
					spr(spst["nmst"] + nbrs,
						x, y)
				end
			end

			if fv then
				spr(spst["flag"], x, y)
			end

			if mv and
				(gs == k_gsdead or btn(5))
			then
				spr(spst["mine"], x, y)
			end
		end
	end

	if gs == k_gswin then
		palt(15, true)
		palt(0, false)
		rectfill(64-16+1, 60+1, 64+14+1, 68+1, 0)
		rectfill(64-16, 60, 64+14, 68, 0)
		rect(64-16, 60, 64+14, 68, 7)
		print("you win", 64-14, 62, 7)
		palt()
	elseif gs == k_gsdead then
		palt(15, true)
		palt(0, false)
		rectfill(64-18+1, 60+1, 64+16+1, 68+1, 0)
		rectfill(64-18, 60, 64+16, 68, 0)
		rect(64-18, 60, 64+16, 68, 7)
		print("you lose", 64-16, 62, 7)
		palt()
	end

	palt(0, false)
	rectfill(0, 0, 127, 7, 0)
	line(0, 8, 127, 8, 7)
	palt()
	local mt = ct_mines()
	local ft = ct_flags()
	spr(4, 119, 0)
	local sstr = tostr(mt-ft).."/"..mt
	print(sstr, 120-#sstr*4, 1, 7)
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
	return flr(m.rndr(l, h))
end
--------------------------------

-----------------------------------
-- table utilities --
-----------------------------------
-- clear array
function clra(arr)
	for i = 1, #arr do
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
	add(err, { msg = tostr(msg),
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
		lg[n] = tostr(msg)
	else
		add(lg, tostr(msg))
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
	add(dbglg, tostr(msg))
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

function loggers_update()
	log_update()
	dbg_update()
	err_update()
end

function loggers_draw()
	log_draw()
	dbg_draw()
	err_draw()
end
-----------------------------------


__gfx__
0000000077777777ddddddd6565656560000000000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000007666666dd55555566555555505c00c500070000000040000000000000000000000000000000000000000000000000000000000000000000000000000
007007007666666dd5555556555555550c5555c0c777c00000048800000000000000000000000000000000000000000000000000000000000000000000000000
000770007666666dd555555665555555005cc5000070000000048880000000000000000000000000000000000000000000000000000000000000000000000000
000770007666666dd555555655555555005cc50000c0000000048800000000000000000000000000000000000000000000000000000000000000000000000000
007007007666666dd5555556655555550c5555c00000000000040000000000000000000000000000000000000000000000000000000000000000000000000000
000000007666666dd55555565555555505c00c500000000000444000000000000000000000000000000000000000000000000000000000000000000000000000
000000007ddddddd6666666665555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000110000003300000888000000aa0000022220000bbb00000cccc00000ee0000000000000000000000000000000000000000000000000000000000000000000
00001000003003000000080000a0a0000020000000b0000000000c0000e00e000000000000000000000000000000000000000000000000000000000000000000
00001000000003000000080000a0a0000022220000b0000000000c00000ee0000000000000000000000000000000000000000000000000000000000000000000
00001000000333000008800000aaaa000000020000bbbb000000c00000e00e000000000000000000000000000000000000000000000000000000000000000000
0000100000300000000008000000a0000000020000b00b00000c000000e00e000000000000000000000000000000000000000000000000000000000000000000
0011110000333300008880000000a0000022220000bbbb00000c0000000ee0000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0011000000333000008880000a0a00000022200000bbb00000ccc00000eee0000000000000000000000000000000000000000000000000000000000000000000
0001000000003000000080000a0a00000020000000b000000000c00000e0e0000000000000000000000000000000000000000000000000000000000000000000
0001000000330000000880000aaaa0000002200000bbb000000c000000eee0000000000000000000000000000000000000000000000000000000000000000000
001110000033300000888000000a00000022200000bbb00000c0000000eee0000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777700dddddd005656560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76666d00d55556006555550005cc5000048000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76666d00d5555600555555000c55c000048800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76666d00d5555600655555000c55c000048880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76666d00d55556005555550005cc5000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7ddddd00d66666006555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
