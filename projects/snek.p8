pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- snek.p8 by tdjx
-- copyright 2018

-- collision functions --
-- returns if sprite at x,y on map
-- has orange flag set to on
function pt_solid(x, y)
	local cx, cy = flr(x / 8),
		flr(y / 8)
	value = mget(cx, cy)
	return fget(value, 1)
end

-- takes half width and half height
-- centered on x, y
function area_solid(x, y, hw, hh)
	return pt_solid(x-hw,y-hh)
		or pt_solid(x-hw, y+hh)
		or pt_solid(x+hw, y-hh)
		or pt_solid(x+hw, y+hh)
end

-- snake functions --
function new_snk()
	local snk = {}

	-- ** config **
	-- head sprite
	snk.sp_hd = 0
	-- tail sprite
	snk.sp_tl = 1

 -- frame move interval
 -- lower values mean fewer frames
 -- between movement
	snk.mv_itvl = 80

	-- pixels to move in a move
	snk.spd = 8

	-- ** init **
	local x = 64
	local y = 64

	-- length of the snake
	snk.len = 4
	-- segments of snake, head is
	-- always at tail[1]
	snk.tail = {}
	for i = 1, snk.len do
		local t = { x = x, y = y }
		add(snk.tail, t)
	end

	-- ** runtime **

	-- frames til next move
	snk.mv_frm = snk.mv_itvl / 4
	-- cardinal direction of travel
	-- 0 none (uses last)
	-- 1 right, 2 up, 3 left, 4 right
	snk.dir = 0
	snk.last_dir = 0
	snk.dead = false

	return snk
end

function snk_update(snk)
	if snk.dead then
		-- todo
		return
	end

	if btn(1) then
		snk.dir = 1
	elseif btn(2) then
		snk.dir = 2
	elseif btn(0) then
		snk.dir = 3
	elseif btn(3) then
		snk.dir = 4
	end

	-- if last_dir is 0 no input
	-- has happened yet so don't move
	-- if dir is not 0 set last_dir
	-- to dir
	if snk.last_dir == 0
		and snk.dir == 0 then
		return
	elseif snk.last_dir == 0 then
		snk.last_dir = snk.dir
	end

	snk.mv_frm -= 1
	if snk.mv_frm <= 0 then
		-- reset move timer
		snk.mv_frm = snk.mv_itvl / 4

		snk_move(snk)
	end
end

function snk_move(snk)
	-- grab dir and fallback to last
	-- if no dir supplied this move
	local dir = snk.dir
	if dir == 0 then
		dir = snk.last_dir
	else
		snk.last_dir = snk.dir
	end
	snk.dir = 0

	-- determine velocity from dir
	local vx, vy = 0, 0
	if dir == 1 then
		vx += snk.spd
	elseif dir == 2 then
		vy -= snk.spd
	elseif dir == 3 then
		vx -= snk.spd
	elseif dir == 4 then
		vy += snk.spd
	end

	-- calculate next head pos
	local hx = snk.tail[1].x + vx
	local hy = snk.tail[1].y + vy

	-- if snek would collide on move
	-- kill the snek :(
	if pt_solid(hx, hy) then
		snk.dead = true
		return
	end

	-- move each tail to prev tail
	for i = snk.len, 2, -1 do
		local tl = snk.tail[i]
		tl.x = snk.tail[i-1].x
		tl.y = snk.tail[i-1].y
		if tl.x == hx and tl.y == hy then
			snk.dead = true
		end
	end

	-- set head to head position
	snk.tail[1].x = hx
	snk.tail[1].y = hy
end

function snk_draw(snk)
	local sx = snk.tail[1].x
	local sy = snk.tail[1].y

	-- render snk tail in reverse
	for i = snk.len, 1, -1 do
		local s = snk.tail[i]
		local sp = snk.sp_tl
		if i == 1 then
			spr(snk.sp_hd, s.x, s.y)
		else
			if s.x ~= sx or s.y ~= sy then
				spr(sp, s.x, s.y)
			end
		end
	end
end

function snk_head_pos(snk)
	return snk.tail[1].x,
		snk.tail[1].y
end

function snk_tail_pos(snk)
	return snk.tail[snk.len].x,
		snk.tail[snk.len].y
end

function snk_grow(snk, amt)
	local tx, ty = snk_tail_pos(snk)

	snk.len += amt
	for i = 1, amt do
		add(snk.tail, { x = tx, y = ty })
	end

	if snk.mv_itvl > 8 then
		snk.mv_itvl -= 1
	end
end

-- apple functions --
function space_free(x, y)
	if pt_solid(x, y) then
		return false
	end

	for t in all(g.s.tail) do
		if t.x == x and t.y == y then
			return false
		end
	end

	for a in all(g.apls) do
		if a.x == x and a.y == y then
			return false
		end
	end

	return true;
end

function new_apl()
	local apl = {}

	local x, y = 0, 0
	repeat
		x = rnd_rngi(1, 14) * 8
		y = rnd_rngi(1, 14) * 8
	until space_free(x, y)

	apl.x = x
	apl.y = y
	apl.dead = false
	apl.sp = 3

	add(g.apls, apl)

	return apl
end

function apl_draw(apl)
	spr(apl.sp, apl.x, apl.y)
end

-- utils --
function rnd_rng(l, h)
	return l + rnd(h - l)
end

function rnd_rngi(l, h)
	return flr(rnd_rng(l, h))
end

-- globals --
t = 0
dt = 1 / 60
g = {}
g.apls = {}
g.score = 0
g.high_score = 0
g.lives = 3
cfg = {}
cfg.apl_n = 7

-- pico-8 implementation --
function _init()
	g.s = new_snk()
	for i = 1, cfg.apl_n do
		new_apl()
	end
end

lbp = false
bp = false
function _update60()
	t += 1
	snk_update(g.s)
	lbp = bp
	bp = btn(4)
	if bp and not lbp then
		snk_grow(g.s, 1)
	end

	local hx, hy = snk_head_pos(g.s)
	for a in all(g.apls) do
		if a.x == hx and a.y == hy then
			del(g.apls, a)
			snk_grow(g.s, 1)
			new_apl()
			g.score += 1
			if g.score >= g.high_score then
				g.high_score = g.score
			end
		end
	end
end

function _draw()
	cls()
	map(0, 0, 0, 0, 20, 20)
	snk_draw(g.s)
	foreach(g.apls, apl_draw)

	print("score: "..tostr(g.score),
		2, 120, 7)

	print("high: "..tostr(g.high_score),
		50, 120, 7)

	for i = 1, g.lives do
		spr(4, 122 - (i-1) * 5, 121)
	end
	-- spr(0, 106, 120)
	-- print(" x"..tostr(g.lives),
	-- 	114, 122, 11)
end
__gfx__
aaaaaaa3aaaaaaa31111111100000000aaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
abbbbbb3abbbbbb31cccccc10e0880e0abb300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
abbbbbb3abbbbbb31c1111c100e88e00abb300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
abbaabb3abbbbbb31c1111c108888880a33300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
abbaabb3abbbbbb31c1111c108888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
abbbbbb3abbbbbb31c1111c100e88e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
abbbbbb3abbbbbb31cccccc10e0880e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333333331111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888ffffff882222228888888888888888888888888888888888888888888888888888888888888888228228888228822888fff8ff888888822888888228888
88888f8888f882888828888888888888888888888888888888888888888888888888888888888888882288822888222222888fff8ff888882282888888222888
88888ffffff882888828888888888888888888888888888888888888888888888888888888888888882288822888282282888fff888888228882888888288888
88888888888882888828888888888888888888888888888888888888888888888888888888888888882288822888222222888888fff888228882888822288888
88888f8f8f8882888828888888888888888888888888888888888888888888888888888888888888882288822888822228888ff8fff888882282888222288888
888888f8f8f882222228888888888888888888888888888888888888888888888888888888888888888228228888828828888ff8fff888888822888222888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1cccccc11cccccc11cccccc11cccccc11cccccc11cccccc11cccccc11cccccc11cccccc11cccccc11cccccc11cccccc11cccccc11cccccc11cccccc11cccccc1
1c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c1
1c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c1
1c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c1
1c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c11c1111c1
1cccccc11cccccc11cccccc11cccccc11cccccc11cccccc11cccccc11cccccc11cccccc11cccccc11cccccc11cccccc11cccccc11cccccc11cccccc11cccccc1
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
1cccccc100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001cccccc1
1c1111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c1111c1
1c1111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c1111c1
1c1111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c1111c1
1c1111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c1111c1
1cccccc100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001cccccc1
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
1cccccc100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001cccccc1
1c1111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c1111c1
1c1111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c1111c1
1c1111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c1111c1
1c1111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c1111c1
1cccccc100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001cccccc1
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
1cccccc100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001cccccc1
1c1111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c1111c1
1c1111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c1111c1
1c1111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c1111c1
1c1111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c1111c1
1cccccc100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001cccccc1
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
1cccccc100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001cccccc1
1c1111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c1111c1
1c1111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c1111c1
1c1111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c1111c1
1c1111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c1111c1
1cccccc100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001cccccc1
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
1cccccc100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001cccccc1
1c1111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c1111c1
1c1111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c1111c1
1c1111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c1111c1
1c1111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c1111c1
1cccccc100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001cccccc1
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
1cccccc100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001cccccc1
1c1111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c1111c1
1c1111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c1111c1
1c1111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c1111c1
1c1111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c1111c1
1cccccc100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001cccccc1
11111111000000000000000000000000000000000000000777777777700000000000000000000000000000000000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000700000000700000000000000000000000000000000000000000000000000000000000000011111111
1cccccc100000000000000000000000000000000000000070000000070000000000000000000000000000000000000000000000000000000000000001cccccc1
1c1111c100000000000000000000000000000000000000070000000070000000000000000000000000000000000000000000000000000000000000001c1111c1
1c1111c100000000000000000000000000000000000000070000100070000000000000000000000000000000000000000000000000000000000000001c1111c1
1c1111c100000000000000000000000000000000000000070001710070000000000000000000000000000000000000000000000000000000000000001c1111c1
1c1111c100000000000000000000000000000000000000070001771070000000000000000000000000000000000000000000000000000000000000001c1111c1
1cccccc100000000000000000000000000000000000000070001777170000000000000000000000000000000000000000000000000000000000000001cccccc1
11111111000000000000000000000000000000000000000700017777100000000000000000000000000000000000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000777717711700000000000000000000000000000000000000000000000000000000000000011111111
1cccccc100000000000000000000000000000000000000000000117100000000000000000000000000000000000000000000000000000000000000001cccccc1
1c1111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c1111c1
1c1111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c1111c1
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5555555555555555555555555555555555555555555555555555555555555555555555aaaaaaa355555555555555555555555555555555555555555555555555
55555555555555555555555557555555ddd5555d5d5d5d5555d5d55555555d55555555abbbbbb356666666666666555557777755555555555555555555555555
55555555555555555555555577755555ddd555555555555555d5d5d5555555d5555555abbbbbb356ddd6ddd6dd66555577ddd775566666555666665556666655
55555555555555555555555777775555ddd5555d55555d5555d5d5d55555555d555555abbbbbb356d6d6d6d66d66555577d7d77566dd666566ddd66566ddd665
55555555555555555555557777755555ddd555555555555555ddddd555ddddddd55555abbbbbb356d6d6d6d66d66555577d7d775666d66656666d665666dd665
555555555555555555555757775555ddddddd55d55555d55d5ddddd55d5ddddd555555abbbbbb356d6d6d6d66d66555577ddd775666d666566d666656666d665
555555555555555555555755755555d55555d555555555555dddddd55d55ddd5555555abbbbbb356ddd6ddd6ddd655557777777566ddd66566ddd66566ddd665
555555555555555555555777555555ddddddd55d5d5d5d55555ddd555d555d555555553333333356666666666666555577777775666666656666666566666665
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555566666665ddddddd5ddddddd5ddddddd5
00000007777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaaaa07aaaaaaa37011111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
abbbbb07abbbbbb370ccccc100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
abbbbb07abbbbbb3701111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
abbaab07abbbbbb3701111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
abbaab07abbbbbb3701111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
abbbbb07abbbbbb3701111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
abbbbb07abbbbbb370ccccc100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333307333333337011111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88282888882228222828888888282888882228222822288888888888888888888888888888888888888888888888888888888888888888888888888888888888
88282882882828282828888888282882882828282888288888888888888888888888888888888888888888888888888888888888888888888888888888888888
88828888882828282822288888222888882828282888288888888888888888888888888888888888888888888888888888888888888888888888888888888888
88282882882828282828288888882882882828282888288888888888888888888888888888888888888888888888888888888888888888888888888888888888
88282888882228222822288888222888882228222888288888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__gff__
0000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000202000000000000020200000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000202000000000000020200000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020000000000000000000000000000023f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020000000000000000000000000000023f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020000000000000000000000000000023f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000202000000000000020200000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000202000000000000020200000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
