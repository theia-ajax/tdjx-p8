pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

-- collision
function cell_solid(cx, cy)
	return fget(mget(cx, cy), 1)
end

function point_solid(x, y)
	return cell_solid(x / 8, y / 8)
end

function area_solid(x, y, w, h)
	return point_solid(x, y)
		or point_solid(x+w, y)
		or point_solid(x, y+h)
		or point_solid(x+w, y+h)
end

function cast_h(ox, oy, dx)
	for x = ox, ox + dx do
		if point_solid(x, oy) then
			return true, x - ox
		end
	end
	return false, dx
end

function cast_v(ox, oy, dy)
	for y = oy, oy + dy do
		if point_solid(ox, y) then
			return true, y - oy
		end
	end
	return false, dy
end

-- level --
-----------------------------------
function new_level()
	local lvl = {}

	lvl.cx = 0
	lvl.cy = 0
	lvl.cw = 38
	lvl.ch = 16
	lvl.sx = 0
	lvl.sy = 0

	return lvl
end

function level_draw(lvl)
	map(lvl.cx, lvl.cy,
		lvl.sx, lvl.sy,
		lvl.cw, lvl.ch)
end

-----------------------------------
-- muzzle flashes --
-----------------------------------
function new_flash(x, y, left)
	local fls = {}
	fls.x = x
	fls.y = y
	fls.left = left
	fls.frm = 10
	fls.dx = 0.6 + abs(ship.dx)
	if fls.left then fls.dx *= -1 end
		add(flashes, fls)
	return fls
end

function flash_update(fls)
	if t % 2 == 0 then
		fls.frm -= 1
	end
	fls.x += fls.dx
	if fls.frm <= 0 then
		fls.dead = true
	end
end

function flash_draw(fls)
	spr(5 + 10 - max(fls.frm, 4),
		fls.x, fls.y,
		1, 1,
		fls.left, false)
end

-----------------------------------
-- sparks --
-----------------------------------
function new_spark(x, y)
	local spk = {}

	spk.x = x
	spk.y = y
	spk.spr = 13
	spk.frm = 10
	spk.dead = false

	add(sparks, spk)

	return spk
end

function spark_update(spk)
	spk.frm -= 1
	if spk.frm <= 0 then
		spk.spr += 1
		spk.frm = 10
		if spk.spr > 15 then
			spk.dead = true
		end
	end
end

function spark_draw(spk)
	circ(spk.x, spk.y, spk.frm/2, 10)
	spr(spk.spr,
		spk.x,
		spk.y,
		1, 1,
		false, false)
end

-----------------------------------
-- bullets --
-----------------------------------
function new_bullet(x, y, dx, dy)
	blt = {}

	dx = dx or 0
	dy = dy or 0

	blt.x = x
	blt.y = y
	blt.dx = dx
	blt.dy = dy
	blt.ox = 1
	blt.oy = 1
	blt.w = 6
	blt.h = 4
	blt.spr = 4
	blt.life = 50
	blt.dead = false

	blt.left = ship.left
	if blt.left then
		blt.dx *= -1
		blt.ox = 0
	end

	add(bullets, blt)

	return blt
end

function bullet_update(blt)
	blt.x += blt.dx
	blt.y += blt.dy
	blt.life -= 1
	if blt.life <= 0 then
		blt.dead = true
	end

	if area_solid(blt.x + blt.ox,
		blt.y + blt.oy,
		blt.w, blt.h) then
		blt.dead = true
	end
end

function bullet_draw(blt)
	spr(blt.spr,
		blt.x,
		blt.y,
		1, 1,
		blt.left, false)
end

-- ship --
-----------------------------------
function new_ship()
	local ship = {}

	ship.x = 63
	ship.y = 63
	ship.w = 8
	ship.h = 8
	ship.dx = 0
	ship.dy = 0
	ship.spr = 1
	ship.left = false
	ship.acl_x = 0.05
	ship.acl_y = 0.4
	ship.dcl_x = 0.02
	ship.dcl_y = 0.4
	ship.max_x = 1.5
	ship.max_y = 1
	ship.fire_del = 0

	return ship
end

function ship_solid(ship, dx, dy)
	return area_solid(ship.x + dx,
		ship.y + dy,
		ship.w, ship.h)
end

function ship_update(ship)
	-- movement input
	if btn(1) then
		ship.dx += ship.acl_x
		ship.left = false
	elseif btn(0) then
		ship.dx -= ship.acl_x
		ship.left = true
	else
		ship.dx = decay(ship.dx,
			ship.dcl_x)
	end

	if btn(3) then
		ship.dy += ship.acl_y
	elseif btn(2) then
		ship.dy -= ship.acl_y
	else
		ship.dy = decay(ship.dy,
			ship.dcl_y)
	end

	ship.dx = clamp(ship.dx,
		-ship.max_x, ship.max_x)
	ship.dy = clamp(ship.dy,
		-ship.max_y, ship.max_y)

	if (btn(5)) ship.dx = 0

	-- physics
	local nx = ship.x + ship.dx
	local ny = ship.y + ship.dy

	if ship_solid(ship, ship.dx, 0)
	then
		ship.dx = 0
	end

	if ship_solid(ship, 0, ship.dy)
	then
		ship.dy = 0
	end

	ship.x += ship.dx
	ship.y += ship.dy

	-- animate
	if t % 4 == 0 then
		ship.spr += 1
		if ship.spr > 2 then
			ship.spr = 1
		end
	end

	-- shoot
	if btn(4) then
		ship.fire_del -= 1
		if ship.fire_del <= 0 then
			ship.fire_del = 15

			local kx = 3
			if (ship.left) kx *= -1
			cam_kick(kx)

			local mx = 8
			if (ship.left) mx *= -1
			new_flash(ship.x + mx,
				ship.y + 2,
				ship.left)

			local bx = 8
			if (ship.left) bx = -8
			bx += ship.x
			b = new_bullet(bx,
				ship.y + 2,
				4,
				sin(t / 180) * 0.2)
		end
	else
		ship.fire_del = 0
	end
end

function ship_draw(ship)
	spr(ship.spr,
		ship.x, ship.y,
		1, 1,
		ship.left, false)

	local tx0, ty0 = ship.x, ship.y
	local tx1, ty1 = tx0 + ship.w,
		ty0 + ship.h

	local c = 11
	if area_solid(tx0, ty0,
			ship.w, ship.h) then
		c = 8
	end

	rect(tx0, ty0, tx1, ty1, c)
end
-----------------------------------

-- camera --
-----------------------------------
function new_camera()
	local cam = {}

	cam.x = 63
	cam.y = 63
	cam.kx = 0
	cam.kdx = 0.3
	cam.tx = 0

	return cam
end

function cam_update(cam)
	local tar = 0
	local lead = 24
	if ship.left then
		tar = -lead + 4
	else
		tar = lead + 4
	end

	cam.kx = decay(cam.kx, cam.kdx)

	cam.tx = lerp(cam.tx, tar, 0.1)
	cam.x = ship.x + cam.tx + cam.kx
	cam.x = clamp(cam.x, 64, 248)
end

function cam_kick(kx)
	cam.kx = kx
end
-----------------------------------

function _init()
	t = 0

	cam = new_camera()

	ship = new_ship()
	level = new_level()

	bullets = {}
	bullets.rem_q = {}

	flashes = {}
	flashes.rem_q = {}

	sparks = {}
	sparks.rem_q = {}
end

function _update60()
	t += 1

	-- update bullets

	for i = 1, #bullets do
		local blt = bullets[i]
		bullet_update(blt)
		if blt.dead then
			new_spark(blt.x, blt.y)
			add(bullets.rem_q, i)
		end
	end
	fst_del(bullets, bullets.rem_q)
	arr_clr(bullets.rem_q)

	-- update flashes

	for i = 1, #flashes do
		local fls = flashes[i]
		flash_update(fls)
		if fls.dead then
			add(flashes.rem_q, i)
		end
	end
	fst_del(flashes, flashes.rem_q)
	arr_clr(flashes.rem_q)

	-- update sparks
	for i = 1, #sparks do
		local spk = sparks[i]
		spark_update(spk)
		if spk.dead then
			add(sparks.rem_q, i)
		end
	end
	fst_del(sparks, sparks.rem_q)
	arr_clr(sparks.rem_q)

	-- update ship
	ship_update(ship)

	cam_update(cam)
end

function _draw()
	cls()

	camera(0, 0)
	rectfill(0, 0, 127, 127, 0)

	camera(cam.x-64, cam.y-64)
	level_draw(level)
	ship_draw(ship)
	foreach(bullets, bullet_draw)
	foreach(sparks, spark_draw)
	foreach(flashes, flash_draw)
end

function lerp(a, b, t)
	return a + (b - a) * t
end

function fst_del(arr, idx)
	local l = #arr

	if type(idx) == "table" then
		for i in all(idx) do
			arr[i] = nil
		end
		if #idx == l then
			return
		end
		for i = 1, l do
			if arr[i] == nil then
				while not arr[l]
					and l > i do
					l -= 1
				end
				if i ~= l then
					arr[i] = arr[l]
					arr[l] = nil
				else
					break
				end
			end
		end
	elseif type(idx) == "number" then
		arr[idx] = nil
		if l > idx then
			arr[idx] = arr[l]
			arr[l] = nil
		end
	end
end

function arr_clr(arr)
	for i, _ in pairs(arr) do
		arr[i] = nil
	end
end

function move_to(v, f, dv)
	if v < f then
		v += dv
		if v > f then v = f end
	elseif v > f then
		v -= dv
		if v < f then v = f end
	end
	return v
end

function decay(v, dv, tg)
	return move_to(v, tg or 0, dv)
end

function clamp(v, low, high)
	return max(min(v, high), low)
end


__gfx__
000000000d0000000d000000000000000000000000000000000a770000099a700000499a00000099000000490000000400000000000000000000000000000000
000000000dd000000dd0000000000000000000000aa700000aaa770004999aaa0000049a00000049000000040000000000000000000000000000000000000000
007007000ddd00000ddd00000000000009aaa770aa0000009aaaa00004999aaa0000499900000000000000090000000000000000000000000000000000000000
000770000066cc000866cc000000000009aaaa709777770099aaa77000449a77000449aa00000049000000090000000900000000000000000000000000000000
0007700009d66cd089d66cd00000000009aaaa709777770099aaa77000449a77000449aa00000049000000090000000900000000000000000000000000000000
0070070000ddd66608ddd6660000000009aaa770aa0000009aaaa00004999aaa0000499900000000000000090000000000000000000000000000000000000000
0000000000ddd55600ddd55600000000000000000aa700000aaa770004999aaa0000049a00000049000000040000000000000000000000000000000000000000
0000000000d0000000d00000000000000000000000000000000a770000099a700000499a00000099000000490000000400000000000000000000000000000000
ccccccccd000000cccdd000cd000ddccccccccccccccccccd000ddccccdd000cd000000cd000ddccccdd000cd000000cd000000c000000000000000000000000
cccccccc0cd00000ccdd00000cd0ddcccccccccccccccccc0cd0ddccccdd00000cd000000cd0ddccccdd00000cd000000cd00000000000000000000000000000
dddddddd000cd000ccddd000000cddccccddddddddddddcc000cddccccddd000000cd000000cddddddddd000000cd000000cd000000000000000000000000000
dddddddd00000cd0ccdd0cd00000ddccccddddddddddddcc0000ddccccdd0cd000000cd00000dddddddd0cd000000cd000000cd0000000000000000000000000
d000000cd000000cccdd000cd000ddccccdd000cd000ddccddddddccccddddddddddddddd000000cd000000cd000cccccccc000c000000000000000000000000
0cd000000cd00000ccdd00000cd0ddccccdd00000cd0ddccddddddccccdddddddddddddd0cd000000cd000000cd0cccccccc0000000000000000000000000000
000cd000000cd000ccddd000000cddccccddd000000cddcccccccccccccccccccccccccc000cd000000cd000000cccddddccd000000000000000000000000000
00000cd000000cd0ccdd0cd00000ddccccdd0cd00000ddcccccccccccccccccccccccccc00000cd000000cd00000ccddddcc0cd0000000000000000000000000
__gff__
0000000000000000000000000000000002020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1010150000000000000000000000000000000000000000000000000000000000000000001410100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111130000000000000000000000000000000000000000000000000000000000000000001211110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111130000000000000000000000000000000000000000000000000000000000000000001211110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111130000000000000000000000000000000000000000000000000000000000000000001211110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111130000000000000000141015000000000000000000000000000000000000000000001211110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111130000000000000000121113000000000000000000000000000000000000000000001211110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111130000000000000000171816000000000000000000000000000000000000000000001211110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111130000000000000000000000000000141500141500000000000000000000000000001211110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111130000000000000000000000000000171600171600000000000000000000000000001211110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111130000000000000000000000000000000000000000000000000000000000000000001211110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111130000000000000000000000000000000000000000000000000000000000000000001211110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111130000000000000000000000000000000000000000000000000000000000000000001211110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111130000000000000000000000000000000000000000000000000000000000000000001211110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111130000000000000000000000000000000000000000000000000000000000000000001211110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111191010101010101010101010101010101010101010101010101010101010101010101a11110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
