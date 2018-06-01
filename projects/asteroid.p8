pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	gm = {}
	
	gm.plr = plr_new()

	gm.asts = {}
	gm.asts.rq = {}
	
	gm.blts = {}
	gm.blts.rq = {}
	
	for i = 1, 5 do
		add(gm.asts, ast_new(rnd(127), rnd(127)))
	end
end

function _update60()
	plr_update(gm.plr)
	
	for i = 1, #gm.blts do
		blt_update(gm.blts[i])
		if gm.blts[i].dead then
			add(gm.blts.rq, i)
		end
	end	
	idelfa(gm.blts, gm.blts.rq)
	clra(gm.blts.rq)
	
	for i = 1, #gm.asts do
		ast_update(gm.asts[i])
		if gm.asts[i].dead then
			add(gm.asts.rq, i)
		end
	end
	idelfa(gm.asts, gm.asts.rq)
	clra(gm.asts.rq)
end

function _draw()
	cls()
	
	plr_draw(gm.plr)

	foreach(gm.blts, blt_draw)
	foreach(gm.asts, ast_draw)	
end

function plr_new()
	plr = {}
	
	plr.x = 63
	plr.y = 63
	plr.dx = 0
	plr.dy = 0
	plr.r = 0
	plr.dr = 3
	plr.accel = 0.03
	plr.mx_spd = 1.5
	plr.shot_itvl = 13
	plr.shot_t = 0
	
	plr.fx, plr.fy = 0, 0
	plr.rx, plr.ry = 0, 0
	plr.lx, plr.ly = 0, 0

	return plr
end

function plr_update(plr)
	if btn(0) then
		plr.r += plr.dr
	end
	
	if btn(1) then
		plr.r -= plr.dr
	end

	local acl = 0
	if btn(2) then
		acl = plr.accel
	end

	local ax, ay = m.cos(plr.r) * acl,
		m.sin(plr.r) * acl
	
	plr.dx += ax
	plr.dy += ay

	local spd = sqrt(plr.dx*plr.dx +
		plr.dy*plr.dy)

	if spd > plr.mx_spd then
		plr.dx = plr.dx / spd * plr.mx_spd
		plr.dy = plr.dy / spd * plr.mx_spd
	end	

	plr.x += plr.dx
	plr.y += plr.dy
	
	plr.x, plr.y = m.scr_wrap(
		plr.x, plr.y, 3)
		
	plr.fx = m.cos(plr.r) * 3 + plr.x
 plr.fy = m.sin(plr.r) * 3 + plr.y
 plr.rx = m.cos(plr.r-135) * 3 + plr.x
 plr.ry = m.sin(plr.r-135) * 3 + plr.y
 plr.lx = m.cos(plr.r+135) * 3 + plr.x
 plr.ly = m.sin(plr.r+135) * 3 + plr.y
 
 if btn(4) then
 	plr.shot_t -= 1
 	if plr.shot_t <= 0 then
 		plr.shot_t = plr.shot_itvl
 		add(gm.blts,
 			blt_new(plr.fx, plr.fy, plr.r))
 	end
 else
 	plr.shot_t = 0
 end
end

function plr_draw(plr)
	line(plr.fx, plr.fy, plr.rx, plr.ry, 7)
	line(plr.fx, plr.fy, plr.lx, plr.ly, 7)
	line(plr.lx, plr.ly, plr.rx, plr.ry, 7)
end

function ast_new(x, y, sz)
	local ast = {}
	
	ast.x = rnd(127)
	ast.y = rnd(127)
	ast.sz = sz or 7
	ast.dx = (rnd(2)-1) * 0.25
	ast.dy = (rnd(2)-1) * 0.25
	ast.dead = false
	
	return ast
end

function ast_update(ast)
	ast.x += ast.dx
	ast.y += ast.dy
	
	ast.x, ast.y = m.scr_wrap(
		ast.x, ast.y, ast.sz)
end

function ast_draw(ast)
	circ(ast.x, ast.y, ast.sz, 7)
end

function blt_new(x, y, ang)
	local blt = {}
	
	blt.x = x or 0
	blt.y = y or 0
	blt.spd = 4
	blt.dx = m.cos(ang) * blt.spd
	blt.dy = m.sin(ang) * blt.spd
	blt.life_f = 35
	blt.dead = false
	
	return blt
end

function blt_update(blt)
	blt.x += blt.dx
	blt.y += blt.dy
	
	local nwasts = {}
	for a in all(gm.asts) do
		local dlx, dly =
			blt.x - a.x,
			blt.y - a.y
		
		local d = sqrt(dlx * dlx + dly * dly)
		if d <= a.sz then
			a.dead = true
			blt.dead = true
			if a.sz > 1 then
				add(gm.asts,
					ast_new(a.x, a.y, a.sz - 2))
				add(gm.asts,
					ast_new(a.x, a.y, a.sz - 2))
			end
			break
		end
	end
	
	blt.x, blt.y = m.scr_wrap(
		blt.x, blt.y, 2)

	blt.life_f -= 1
	if (blt.life_f <= 0) blt.dead = true
end

function blt_draw(blt)
	circfill(blt.x, blt.y, 1, 7)
end

-- math
m = {}

function m.cos(deg)
	return cos(deg / 360)
end

function m.sin(deg)
	return sin(deg / 360)
end

function m.scr_wrap(x, y, b)
	if (x < -b) x = 127 + b
	if (x > 127 + b) x = -b
	if (y < -b) y = 127 + b
	if (y > 127 + b) y = -b
	return x, y
end

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


