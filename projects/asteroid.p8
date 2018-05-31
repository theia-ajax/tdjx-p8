pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	gm = {}
	
	gm.plr = plr_new()
	gm.asts = {}
	
	for i = 1, 5 do
		add(gm.asts, ast_new(rnd(127), rnd(127)))
	end
end

function _update60()
	plr_update(gm.plr)
	
	for a in all(gm.asts) do
		ast_update(a)
	end
end

function _draw()
	cls()
	
	plr_draw(gm.plr)
	
	for a in all(gm.asts) do
		ast_draw(a)
	end
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
	
	-- border width
	local bdr_w = 6
	plr.x, plr.y = m.scr_wrap(
		plr.x, plr.y, bdr_w)
		
	plr.fx = m.cos(plr.r) * 3 + plr.x
 plr.fy = m.sin(plr.r) * 3 + plr.y
 plr.rx = m.cos(plr.r-135) * 3 + plr.x
 plr.ry = m.sin(plr.r-135) * 3 + plr.y
 plr.lx = m.cos(plr.r+135) * 3 + plr.x
 plr.ly = m.sin(plr.r+135) * 3 + plr.y
end

function plr_draw(plr)
	line(plr.fx, plr.fy, plr.rx, plr.ry, 7)
	line(plr.fx, plr.fy, plr.lx, plr.ly, 7)
	line(plr.lx, plr.ly, plr.rx, plr.ry, 7)
end

function ast_new(x, y)
	local ast = {}
	
	ast.x = rnd(127)
	ast.y = rnd(127)
	ast.sz = 7
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
