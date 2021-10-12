pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- quadris
-- tdjx

-----------------------------------
-- main --
-----------------------------------
function _init()
	tf = 0
	tdel = 1

	init_scores()

	app = {}
	app.scores = load_scores()

	gs_init()
	gs_add(k_gs_splash,
		splash_update,
		splash_draw,
		splash_start)
	gs_add(k_gs_menu,
		menu_update,
		menu_draw,
		menu_start)
	gs_add(k_gs_play,
		play_update,
		play_draw,
		play_start)
	gs_chg(k_gs_splash)
end

function _update60()
	tf += 1
	if tf % tdel ~= 0 then
		return
	end

	loggers_update()

	btnupdate()

	gs_update()
end

function _draw()
	gs_draw()
	loggers_draw()
end

function menu_start()
	mn = {}
	mn.state = 0
	mn.timef = 120
end

function menu_update()
	if mn.state == 0 then
		if btn(k_btn_o) and btn(k_btn_x) then
			-- gs_chg(k_gs_play)
			mn.state = 1
		end
	elseif mn.state == 1 then
		mn.timef -= 1
		if (mn.timef <= 0) gs_chg(k_gs_play)
	end
end

function menu_draw()
	cls(0)

	-- local mx, my = 32, 40
	-- local w = #g.mnopts[g.selidx + 1] * 2
	-- rectfill(mx-w-1, my + g.selidx * 7 - 1, mx+w-1, my + 4 + g.selidx * 7 + 1, 8)

	-- for i = 1, #g.mnopts do
	-- 	print(g.mnopts[i], mx - #g.mnopts[i]*2, my + (i-1)*7, 6)
	-- end

	local tlx, tly = 37, 5 - (120 - mn.timef)
	for i = 1, 7 do
		pal(7, k_brd_cols[((i-1)+flr(tf/8))%(#k_brd_cols-1)+2])
		spr(i, tlx + (i-1)*7, tly)
	end
	pal()

	local scx, scy = 58, 20 - (120 - mn.timef)
	print("high scores", scx - 18, scy, 6)
	line(scx-34, scy+7,scx+36,scy+7, 6)
	for i = 1, #app.scores do
		local leadsp = " "
		if (i >= 10) leadsp = ""
		local leadscsp = ""
		local scorestr = tostr(app.scores[i].score)
		for j = 0, 10-#scorestr do
			leadscsp = leadscsp.." "
		end
		print(leadsp..i..". "..app.scores[i].name..leadscsp..scorestr,
			scx - 34, scy + i*6 + 4, 6)
	end

	if mn.state == 0 then
		local str = "press 🅾️+❎"
		if (tf % 60) < 30 then
			print(str, scx-#str*2-1, scy+80, 6)
		end
	end

	if mn.state == 1 and mn.timef < 10 then
		cls(7)
	end
end

function play_start()
	g = {}

	k_ps_play = 1
	k_ps_death = 2
	k_ps_gameover = 3

	g.play_state = k_ps_play

	g.brd = {}
	g.brd.back = {}
	g.brd.w = 10
	g.brd.h = 24
	g.brd.ph = 4
	g.brd.sz = g.brd.w * g.brd.h

	for i = 0, g.brd.sz - 1 do
		g.brd[i] = 0
		g.brd.back[i] = g.brd[i]
	end

	g.pc_sav = nil
	g.has_swp = false

	g.pc_q = {}
	for i = 1, 5 do
		add(g.pc_q, rnd_pc())
	end

	g.actpc = next_pc()

	g.linect = 0
	g.level = 0
	g.score = 0
	g.dropf = drop_itvl()

	g.cam = {
		tx = 0, ty = 0,
		kx = 0, ky = 0,
		shkf = 0, shkm = 0,
		shkx = 0, shky = 0
	}
end

function play_update()
	cam_update(g.cam)

	if g.play_state == k_ps_play then
		for i = 0, g.brd.sz - 1 do
			g.brd[i] = g.brd.back[i]
		end

		if g.actpc then
			play_move_update()
		end
	elseif g.play_state == k_ps_death then
		play_death_update()
	end
end

function play_move_update()
	if btnprs(k_btn_r) then
		if piece_clear_right(g.actpc, g.brd) then
			g.actpc.x += 1
			sfx_pcmove()
			if not piece_clear_down(g.actpc, g.brd) then
				g.dropf = drop_itvl()
			end
		else
			cam_knock(g.cam, 3, 0)
			sfx_pound()
		end
	end

	if btnprs(k_btn_l) then
		if piece_clear_left(g.actpc, g.brd) then
			g.actpc.x -= 1
			sfx_pcmove()
			if not piece_clear_down(g.actpc, g.brd) then
				g.dropf = drop_itvl()
			end
		else
			cam_knock(g.cam, -3, 0)
			sfx_pound()
		end
	end

	local drx, dry = piece_drop_pos(g.actpc, g.brd)

	if btnprs(k_btn_u) then
		sfx_altmode()
	end

	if btn(k_btn_u) then
		board_writepc(g.brd, g.actpc, drx, dry, "preview_primed")

		if btnprs(k_btn_o) then
			while piece_clear_down(g.actpc, g.brd) do
				g.actpc.y += 1
			end
			sfx_pound()
			board_writepc(g.brd, g.actpc)
			board_flip(g.brd)
			local lns = board_chk_lines(g.brd)
			g.linect += lns
			if g.linect >= g.level * 10 + 10 then
				g.level += 1
			end
			g.score += m.pow(2, lns) * 25
			g.actpc = next_pc()
			g.has_swp = false
			cam_knock(g.cam, 0, 3)
		end

		if btnprs(k_btn_x) then
			if not g.has_swp then
				g.has_swp = true
				sfx_swap()
				if g.pc_sav == nil then
					g.pc_sav = new_piece(g.actpc.type)
					g.actpc = next_pc()
				else
					local t = g.pc_sav.type
					g.pc_sav = new_piece(g.actpc.type)
					g.actpc = new_piece(t)
				end
			end
		end
	else
		sfx(14, -2)
		sfx(15, -2)
		sfx(16, -2)

		board_writepc(g.brd, g.actpc, drx, dry, "preview")

		if btnprs(k_btn_o) and
			piece_rot_clear(g.actpc, g.brd, -1)
		then
			g.actpc:decr()
			sfx_pcrot()
		end

		if btnprs(k_btn_x) and
			piece_rot_clear(g.actpc, g.brd, 1)
		then
			g.actpc:incr()
			sfx_pcrot()
		end
	end

	board_writepc(g.brd, g.actpc)

	local rate = 1
	if btn(3) then
		rate = 4
	end

	g.dropf -= rate

	if g.dropf <= 0 then
		if piece_clear_down(g.actpc, g.brd) then
			g.dropf = drop_itvl()
			g.actpc.y += 1
		else
			cam_knock(g.cam, 0, 3)
			board_flip(g.brd)
			board_chk_lines(g.brd)
			g.actpc = next_pc()
			if not piece_clear_down(g.actpc, g.brd) then
				play_death_start()
			end
			g.has_swp = false
		end
	end
end

function play_draw()
	camera()
	cls(5)
	fillp(0x1248)
	rectfill(0, 0, 127, 127, 0x50)
	fillp()
	-- for x = 0, 256, 2 do
	-- 	line(0, x, x, 0, 0)
	-- end

	camera(cam_pos(g.cam))

	rectfill(0, 0, 127, 127, 1)
	rect(-1, -1, 128, 128, 7)
	for x = 0, 127 do
		line(0, x, x, 127, 12)
	end

	board_draw(g.brd, 10, 4, 6, 6)
	board_draw(g.brd, 95, 95, 1, 1, 0)

	piece_queue_draw(g.pc_q, 73, 3)

	local savx, savy = 73, 88
	print("save:", savx, savy, 6)
	rectfill(savx, savy+6, savx + 19, savy + 36, 0)
	rect(savx, savy+6, savx + 19, savy + 36, 7)

	if g.pc_sav then
		piece_draw(g.pc_sav, savx + 16 + k_piece_pvwoff[g.pc_sav.val] * 6, savy + 34, 6, 6, k_piece_pvwrot[g.pc_sav.val])
	end

	--local lnx, lny = 95, 3
	local lnx, lny = 73, 42
	print("lines:", lnx, lny)
	rectfill(lnx, lny + 6, lnx + 24, lny + 14, 0)
	rect(lnx, lny + 6, lnx + 24, lny + 14, 7)
	local ctstr = tostr(g.linect)
	print(ctstr, lnx + 24 - #ctstr * 4, lny + 8)

	local lvx, lvy = 73, 58
	print("level:", lvx, lvy)
	rectfill(lnx, lvy + 6, lvx + 24, lvy + 14, 0)
	rect(lnx, lvy + 6, lvx + 24, lvy + 14, 7)
	local lvstr = tostr(g.level)
	print(lvstr, lvx + 24 - #lvstr * 4, lvy + 8)

	local scx, scy = 73, 74
	print("score:", scx, scy)
	rectfill(lnx, scy + 6, scx + 24, scy + 14, 0)
	rect(lnx, scy + 6, scx + 24, scy + 14, 7)
	local lvstr = tostr(g.score)
	print(lvstr, scx + 24 - #lvstr * 4, scy + 8)
end

function play_death_start()
	g.play_state = k_ps_death
	cam_shake(g.cam, 140, 1)
	g.deathrow = g.brd.h
	g.deathitvl = 4
	g.deathf = 60
	g.doffs = {}
	for i = 1, g.brd.w do
		g.doffs[i] = flr(rnd(15)) + 1
	end
end

function play_death_update()
	g.deathf -= 1
	if g.deathf <= 0 then
		g.deathf = g.deathitvl
		-- g.deathitvl *= 0.94
		g.deathrow -= 1
		-- cam_knock(g.cam, 0, 2)

		for c = 0, g.brd.w - 1 do
			local off = g.doffs[c + 1]
			if g.deathrow + off < g.brd.h  and
				g.deathrow + off >= 0
			then
				g.brd[(g.deathrow + off) * g.brd.w + c] = rnd_pc_val() + shl(k_style_vals['death'], 4)
			end
		end

		if g.deathrow < -15 then
			g.play_state = k_ps_gameover
		end
	end
end
-----------------------------------

function piece_queue_draw(pcq, x, y)
	local qx, qy = x, y
	print("next:", qx, qy, 6)
	rectfill(qx, qy + 6, qx + 19, qy + 37, 0)
	rect(qx, qy + 6, qx + 19, qy + 37, 7)
	rectfill(qx + 19, qy + 6, 126, qy + 24, 0)
	rect(qx + 19, qy + 6, 126, qy + 24, 7)
	line(qx + 19, qy + 7, qx + 19, qy + 23, 0)

	piece_draw(pcq[1], qx + 16 + k_piece_pvwoff[pcq[1].val] * 6, qy + 34, 6, 6, k_piece_pvwrot[pcq[1].val])
	for i = 2, #pcq do
		piece_draw(pcq[i], qx + 19 + k_piece_pvwoff[pcq[i].val] * 3 + 8 * (i-1), qy + 22, 3, 3, k_piece_pvwrot[pcq[i].val])
	end
end

function cam_pos(cam)
	if cam.shkf > 0 and cam.shkf % cam.shkivl == 0 then
		local r = rnd(1)
		cam.shkx = cos(r) * cam.shkm
		cam.shky = sin(r) * cam.shkm
	end


	local x, y = cam.tx + cam.kx + cam.shkx,
		cam.ty + cam.ky + cam.shky

	return -x, -y
end

function cam_update(cam)
	cam.kx = m.moveto(cam.kx, 0, 0.5)
	cam.ky = m.moveto(cam.ky, 0, 0.5)
	if cam.shkf > 0 then
		cam.shkf -= 1
	else
		cam.shkx, cam.shky = 0, 0
	end
end

function sfx_pcmove()
	sfx(flr(rnd(3))+11)
end

function sfx_pcrot()
	sfx(flr(rnd(3))+8)
end

function sfx_altmode()
	sfx(flr(rnd(3))+14)
end

function sfx_pound()
	sfx(flr(rnd(3))+17)
end

function sfx_swap()
	sfx(flr(rnd(3))+20)
end

function cam_knock(cam, kx, ky)
	cam.kx = kx
	cam.ky = ky
end

function cam_shake(cam, frm, mag, ivl)
	cam.shkx = 0
	cam.shky = 0
	cam.shkf = frm
	cam.shkm = mag
	cam.shkivl = ivl or 1
end

function rnd_pc()
	return new_piece(k_pieces[flr(rnd(7))+1])
end

function rnd_pc_val()
	return flr(rnd(7))+1
end

function next_pc()
	local ret = g.pc_q[1]
	idel(g.pc_q, 1)
	add(g.pc_q, rnd_pc())
	return ret
end

k_style_names = {}

k_style_vals = {
	normal = 0,
	preview = 1,
	preview_primed = 2,
	death = 3,
}

for s, v in pairs(k_style_vals) do
	k_style_names[v] = s
end

k_pieces = { "i", "t", "l", "j", "s", "z", "o" }

k_piece_i = {
	{{0,0},{0,1},{0,-1},{0,-2}},
	{{0,0},{1,0},{-1,0},{-2,0}},
}

k_piece_t = {
	{{-1,0},{0,0},{1,0},{0,-1}},
	{{0,-1},{0,0},{0,1},{1,0}},
	{{1,0},{0,0},{-1,0},{0,1}},
	{{0,1},{0,0},{0,-1},{-1,0}},
}

k_piece_l = {
	{{0,0},{0,-1},{0,1},{1,1}},
	{{0,0},{1,0},{-1,0},{-1,1}},
	{{0,0},{0,1},{0,-1},{-1,-1}},
	{{0,0},{-1,0},{1,0},{1,-1}},
}

k_piece_j = {
	{{0,0},{0,-1},{0,1},{-1,1}},
	{{0,0},{1,0},{-1,0},{-1,-1}},
	{{0,0},{0,1},{0,-1},{1,-1}},
	{{0,0},{-1,0},{1,0},{1,1}},
}

k_piece_s = {
	{{0,0},{1,0},{0,1},{-1,1}},
	{{0,0},{0,-1},{1,0},{1,1}},
}

k_piece_z = {
	{{0,0},{-1,0},{0,1},{1,1}},
	{{0,0},{0,1},{1,0},{1,-1}},
}

k_piece_o = {
	{{-1,0},{0,0},{-1,1},{0,1}},
}

k_piece_ptns = {
	i = k_piece_i,
	t = k_piece_t,
	l = k_piece_l,
	j = k_piece_j,
	s = k_piece_s,
	z = k_piece_z,
	o = k_piece_o,
}

k_piece_vals = {
	t = 1,
	j = 2,
	z = 3,
	o = 4,
	s = 5,
	l = 6,
	i = 7,
}

k_piece_pvwoff = {
	0, 0, 0, 1, 0, 0, 0
}

k_piece_pvwrot = {
	4, 1, 2, 1, 2, 3, 1
}

k_drop_itvls = {
	53, 49, 45, 41, 37, 33, 28, 22, 17, 11, 10, 9, 8, 7, 6, 6, 5, 5, 4, 4, 3
}

function drop_itvl()
	if g.level < #k_drop_itvls then
		return k_drop_itvls[g.level + 1]
	else
		return k_drop_itvls[#k_drop_itvls]
	end
end

function cpy_ptn(t)
	local ret = {}
	for i = 1, 16 do
		ret[i] = k_piece_ptns[t][i]
	end
	return ret
end

function ptn_bottom(ptn)
	local retx, rety = 0, 0
	for i = 1, 16 do
		if ptn[i] > 0 then
			local y = flr((i-1) / 4)
			if y > rety then
				retx = (i-1) % 4
				rety = y
			end
		end
	end
	return retx, rety
end

function new_piece(t)
	local self = {}

	self.x = 5
	self.y = 2
	self.r = 1
	self.type = t or "i"
	self.val = k_piece_vals[self.type]

	self.incr = function(self)
		self.r += 1
		self.r %= #k_piece_ptns[self.type]
	end

	self.decr = function(self)
		self.r -= 1
		self.r = m.mod(self.r,
			#k_piece_ptns[self.type])
	end

	self.ptn = function(self, dr)
		dr = dr or 0
		local r = m.mod((self.r + dr),
		 #k_piece_ptns[self.type])
		return k_piece_ptns[self.type][r+1]
	end

	return self
end

function piece_rot_clear(pc, brd, dr)
	local ptn = pc:ptn(dr)
	for i = 1, 4 do
		local xx, yy = ptn[i][1], ptn[i][2]
		local nx, ny = pc.x + xx,
			pc.y + yy
		local idx = nx + ny * brd.w
		if nx >= brd.w or nx < 0 or ny < 0 or
			ny >= brd.h or brd.back[idx] > 0
		then
			return false
		end
	end
	return true
end

function piece_move_clear(pc, brd, dx, dy)
	local ptn = pc:ptn()
	for i = 1, 4 do
		local xx, yy = ptn[i][1], ptn[i][2]
		local nx, ny = pc.x + xx + dx,
			pc.y + yy + dy
		local idx = nx + ny * brd.w
		if nx >= brd.w or nx < 0 or ny < 0 or
			ny >= brd.h or brd.back[idx] > 0
		then
			return false
		end
	end
	return true
end

function piece_clear_down(pc, brd)
	return piece_move_clear(pc, brd, 0, 1)
end

function piece_clear_right(pc, brd)
	return piece_move_clear(pc, brd, 1, 0)
end

function piece_clear_left(pc, brd)
	return piece_move_clear(pc, brd, -1, 0)
end

function piece_drop_pos(pc, brd)
	local d = 0
	while piece_move_clear(pc, brd, 0, d)
	do
		d += 1
	end
	return pc.x, pc.y + d-1
end

function piece_draw(pc, x, y, cw, ch, r)
	local ptn = pc:ptn(r or 1)

	for i = 1, 4 do
		local xx = ptn[i][1] - 2
		local yy = ptn[i][2] - 2
		chunk_draw(brd_col(pc.type),
			x + xx * cw, y + yy * ch,
			cw, ch)
	end
end

function chunk_draw(col, x, y, w, h, style, brd, bx, by)
	style = style or 'normal'
	local x1, x2 = x, x + w - 1
	local y1, y2 = y, y + h - 1
	if col > 0 then
		if style == "normal"
		then
			rectfill(x1, y1, x2, y2, col)
			if w > 1 and h > 1 then
				line(x1, y2, x2, y2, 7)
				line(x2, y1, x2, y2, 7)
			end
			if w > 3 and h > 3 then
				pset(x+1,y+1,7)
				pset(x+1,y+2,7)
				pset(x+2,y+1,7)
			end
			-- if h > 1 then
			-- 	line(x1, y1, x2, y1, 7)
			-- end
			-- if w > 1 then
			-- 	line(x2, y1+1, x2, y2, 6)
			-- end
			-- if h > 2 then
			-- 	line(x1, y1 + 1, x1, y2, 5)
			-- end
			-- if w > 2 then
			-- 	line(x1, y2, x2 - 1, y2, 5)
			-- end
		elseif style == "preview" then
			fillp(0xa5a5)
			rectfill(x1, y1, x2, y2, col)
			fillp()
		elseif style == "preview_primed" then
			fillp(0xa5a5)
			rectfill(x1, y1, x2, y2, col)
			fillp()
			local pp = k_style_vals["preview_primed"]
			if board_xy_style(brd, bx-1, by) ~= pp then
				line(x1, y1, x1, y2, col)
			end
			if board_xy_style(brd, bx+1, by) ~= pp then
				line(x2, y1, x2, y2, col)
			end
			if board_xy_style(brd, bx, by-1) ~= pp then
				line(x1, y1, x2, y1, col)
			end
			if board_xy_style(brd, bx, by+1) ~= pp then
				line(x1, y2, x2, y2, col)
			end
		elseif style == "death" then
			line(x1, y1, x2, y2, col)
			line(x1, y2, x2, y1, col)
		end
	end
end

k_brd_cols = { 0, 8, 9, 10, 14, 11, 12, 13 }

function brd_col(pt)
	return k_brd_cols[k_piece_vals[pt]+1]
end

function board_refresh(brd)
	for i = 0, brd.brd.sz - 1 do
		brd[i] = brd.back[i]
	end
end

function board_flip(brd)
	for i = 0, brd.sz - 1 do
		brd.back[i] = brd[i]
	end
end

function board_chk_lines(brd)
	local lines = {}
	for r = 0, brd.h do
		local fullln = true
		for c = 0, brd.w - 1 do
			if not board_xy_solid(brd, c, r)
			then
				fullln = false
				break
			end
		end
		if fullln then
			add(lines, r)
		end
	end

	for ln in all(lines) do
		board_clr_line(brd, ln)
	end

	return #lines
end

function board_clr_line(brd, ln)
	for r = ln, 1, -1 do
		for c = 0, brd.w - 1 do
			local idx1 = r * brd.w + c
			local idx2 = (r - 1) * brd.w + c
			brd.back[idx1] = brd.back[idx2]
		end
	end
	for c = 0, brd.w - 1 do
		brd.back[c] = 0
	end
end

function board_xy_solid(brd, x, y)
	return board_xy_val_back(brd, x, y) > 0
end

function board_xy_idx(brd, x, y)
	if x < 0 or x >= brd.w or y < 0 or y >= brd.h
	then
		return -1
	else
		return y * brd.w + x
	end
end

function board_xy(brd, x, y)
	local idx = board_xy_idx(brd, x, y)
	if idx >= 0 then
		return brd[idx]
	else
		return 0
	end
end

function board_xy_back(brd, x, y)
	local idx = board_xy_idx(brd, x, y)
	if idx >= 0 then
		return brd.back[idx]
	else
		return 0
	end
end

function board_xy_val(brd, x, y)
	return band(board_xy(brd, x, y),
		0xf)
end

function board_xy_style(brd, x, y)
	return shr(band(board_xy(brd, x, y), 0xf0), 4)
end

function board_xy_val_back(brd, x, y)
	return band(board_xy_back(brd, x, y),
		0xf)
end

function board_xy_style_back(brd, x, y)
	return shr(band(board_xy_back(brd, x, y), 0xf0), 4)
end

function board_writepc(brd, pc, x, y, style)
	local ptn = pc:ptn()
	x = x or pc.x
	y = y or pc.y
	style = style or 'normal'
	local styv = k_style_vals[style] or 0
	for i = 1, 4 do
		local xx, yy = ptn[i][1], ptn[i][2]
		local px = x + xx
		local py = y + yy
		if px >= 0 and px < brd.w and
			py >= 0 and py < brd.h
		then
			local idx = px + py * brd.w
			brd[idx] = k_piece_vals[pc.type] +
				shl(styv, 4)
		end
	end
end

function board_draw(brd, bx, by, cw, ch, sy, ey)
	sx = 0
	ex = brd.w - 1
	sy = sy or brd.ph
	ey = ey or brd.h - 1

	bw = brd.w * cw
	bh = (brd.h - sy) * ch

	rectfill(bx, by, bx + bw, by + bh, 0)
	rect(bx - 1, by - 1,
		bx + bw, by + bh,
		7)

	for r = sy, ey do
		for c = sx, ex do
			local v = board_xy_val(brd, c, r)
			local s = board_xy_style(brd, c, r)
			local x, y = bx + c * cw,
				by + (r - sy) * ch
			chunk_draw(k_brd_cols[v+1],
				x, y, cw, ch, k_style_names[s],
				brd, c, r)

			-- if cw > 3 then
			-- 	print(s, x, y, k_brd_cols[s+1]+1)
			-- end
		end
	end
end

k_btn_l = 0
k_btn_r = 1
k_btn_u = 2
k_btn_d = 3
k_btn_o = 4
k_btn_x = 5

btns = {}
prevbtns = {}

function btnupdate()
	for i = 0, 5 do
		prevbtns[i] = btns[i]
		btns[i] = btn(i)
	end
end

function btnprs(b)
	return btns[b] and not prevbtns[b]
end

function init_scores()
	if peek(0x5e00) == 0 then
		poke(0x5e00, 1)
		for i = 0, 9 do
			write_score(i, "aaa", (10-i)*50)
		end
	end
end

k_name_chars = " _abcdefghijklmnopqrstuvwxyz"
k_char_vals = {}
for i = 1, #k_name_chars do
	k_char_vals[sub(k_name_chars, i, i)] = i
end

function load_scores()
	-- scores are stored as 10 contiguous sets of
	-- 3 bytes for 3 chars per name
	-- 2 bytes for score
	local ret = {}

	for i = 0, 9 do
		local scr = load_score(i)
		add(ret, scr)
	end

	return ret
end

function write_scores(scores)
	local len = min(#scores, 10)
	for i = 0, len - 1 do
		write_score(i, scores[i+1].name, scores[i+1].score)
	end
end

function write_score(idx, name, score)
	if idx < 0 or idx >= 10 then
		return
	end
	local addr = 0x5e01 + idx * 5
	for i = 1, 3 do
		local c = sub(name, i, i)
		if c and k_char_vals[c] then
			poke(addr + (i - 1), k_char_vals[c])
		end
	end
	addr += 3
	poke(addr, shr(band(score, 0xff00), 4))
	poke(addr+1, band(score, 0x00ff))
end

function load_score(idx)
	if (idx < 0 or idx >= 10) return nil

	local ret = { name = nil, score = 0 }

	local name = ""
	local addr = 0x5e01 + idx * 5
	for i = 0, 2 do
		local val = peek(addr + i)
		if val > 0 then
			local c = sub(k_name_chars, val, val)
			if (c) name = name..c
		end
	end

	ret.name = name

	addr += 3
	-- log(peek(addr))
	-- log(peek(addr+1))
	local score = shl(peek(addr), 4) + peek(addr+1)

	ret.score = score

	return ret
end

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

function m.pow(a, b)
	if (b < 1) return 0
	local ret = a
	for i = 2, b do
		ret *= a
	end
	return ret
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
	add(err, { msg = tostr(msg) or 'nil',
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
		local len = 0
		if (e.msg) len = #e.msg
		local x = 64 - len * 2
		print(e.msg, x, y, 8)
		y += 6
	end
end

lg = {}
lg.f = 0
lg.max = 16

function log(msg)
	msg = tostr(msg) or 'nil'
	msg = "t "..tf..": "..msg
	lg.f = 600
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
	add(dbglg, msg or 'nil')
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
	err_update()
	log_update()
	dbg_update()
end

function loggers_draw()
	err_draw()
	log_draw()
	dbg_draw()
end
-----------------------------------

-----------------------------------
-- gamestates --
-----------------------------------
k_gs_splash = 1
k_gs_menu = 2
k_gs_play = 3
k_gs_hiscore = 4

function gs_init(fps30)
	gs = {}
	gs.fps30 = fps30 or false
	gs.tbl = {}
	gs.curr = nil
end

function gs_add(id,
	fn_update, fn_draw,
	fn_onstart, fn_onend)
	assert(gs.tbl[id] == nil)
	gs.tbl[id] = {
		id = id,
		update = fn_update,
		draw = fn_draw,
		onstart = fn_onstart,
		onend = fn_onend
	}
end

function gs_chg(id)
	local next = gs.tbl[id]

	if next == nil then
		return
	end

	if gs.curr then
		if type(gs.curr.onend) ==
			"function"
		then
			gs.curr.onend(next)
		end
	end

	gs.curr = next

	if type(gs.curr.onstart) ==
		"function"
	then
		gs.curr.onstart(next)
	end
end

function gs_update()
	if gs.curr then
		gs.curr.update()
	end
end

function gs_draw()
	if gs.curr then
		gs.curr.draw()
	end
end

-----------------------------------

-----------------------------------
-- splash screen --
-----------------------------------
function splash_start()
	splt = 180
	ltrs = {}
	add(ltrs, { x = -16, y = 62, tx = 40, ty = 62, c = 12, bc = 1, lst = {} })
	add(ltrs, { x = 24, y = 62, tx = 56, ty = 62, c = 11, bc = 3, lst = {} })
	add(ltrs, { x = 102, y = 62, tx = 72, ty = 62, c = 9, bc = 4, lst = {} })
	add(ltrs, { x = 142, y = 62, tx = 88, ty = 62, c = 14, bc = 2, lst = {} })
	local i = 0
	for lt in all(ltrs) do
		lt.ty = 62 + m.sin(i * 45 + t() * 300) * (max(min(splt, 120), 0) * 0.06667 * 12)
		i += 1
	end
end

function splash_update()
	if splt > 120 then
		splt -= 1
		return
	elseif splt == 120 then
		sfx(63)
	end

	if btn(4) or splt <= -120 then
		gs_chg(k_gs_menu)
	end

	local i = 0
	for lt in all(ltrs) do
		add(lt.lst, {x = lt.x, y = lt.y})
		if #lt.lst > 6 then
			idel(lt.lst, 1)
		end
		i += 1
		local xy = m.sin(i * 45 + t() * 300) * (max(min(splt, 120), 0) * 0.06667 * 12)
		if (splt <= 0) xy = 0
		lt.ty = 62 + xy
		if splt <= 0 then
			lt.x, lt.y = lt.tx, lt.ty
		else
			lt.x = m.lerp(lt.x, lt.tx, 0.05)
			lt.y = m.lerp(lt.y, lt.ty, 0.3)
		end
	end
	splt -= 1
	if (gs.fps30) splt -= 1
end

function splash_draw()
	cls()
	if splt > 120 then return end
	local infl = max((splt / 20), 0)
	for lt in all(ltrs) do
		for last in all(lt.lst) do
			rectfill(last.x-4-infl*4,last.y-5-infl,last.x+3+infl*4,last.y+4+infl, lt.bc)
		end
	end
	if splt <= -15 then
		for i=1,#ltrs do
			local lt = ltrs[i]
			pal(7, lt.c)
			spr(251+i, lt.x-4, lt.y-4)
		end
		pal()
	end
end
-----------------------------------
__gfx__
00000000777777007000070000770000777700007777000077777700007777000000000000000000000000000000000000000000000000000000000000000000
00000000700007007000070007007000700070007000770000070000070000000000000000000000000000000000000000000000000000000000000000000000
00700700700007007000070007007000700007007000070000070000700000000000000000000000000000000000000000000000000000000000000000000000
00077000700007007000070007007000700007007000770000070000700000000000000000000000000000000000000000000000000000000000000000000000
00077000700007007000070070000700700007007777000000070000077770000000000000000000000000000000000000000000000000000000000000000000
00700700700077007000070077777700700007007007000000070000000007000000000000000000000000000000000000000000000000000000000000000000
00000000777777007000070070000700700070007000700000070000000007000000000000000000000000000000000000000000000000000000000000000000
00000000000007007777770070000700777700007000070077777700777777000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000770000000007700000077007700770
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000770000000007700000077007777770
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777770077777700000077007777770
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777770077777700000077000077000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000770000077007700770077000077000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000770000077007700770077007777770
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777770077777700777777007777770
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777770077777700777777007700770
__label__
c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
c1111111177777777777777777777777777777777777777777777777777777777777777116611666161616661111111111111111111111111111111111111111
c111111117000000000000000000000000ccccc70000000000000000000000000000007116161611161611611161111111111111111111111111111111111111
c111111117000000000000000000000000c77cc70000000000000000000000000000007116161661116111611111111111111111111111111111111111111111
c111111117000000000000000000000000c7ccc70000000000000000000000000000007116161611161611611161111111111111111111111111111111111111
c111111117000000000000000000000000ccccc70000000000000000000000000000007116161666161611611111111111111111111111111111111111111111
c111111117000000000000000000000000ccccc70000000000000000000000000000007111111111111111111111111111111111111111111111111111111111
c1111111170000000000000000000000007777770000000000000000000000000000007117777777777777777777777777777777777777777777777777777771
c1111111170000000000000000000000000000000000000000000000000000000000007117000000000000000000000000000000000000000000000000000071
c1111111170000000000000000000000000000000000000000000000000000000000007117000000000000000000000000000000000000000000000000000071
c1111111170000000000000000000000000000000000000000000000000000000000007117000000000000000000000000000000000000000000000000000071
c1111111170000000000000000000000000000000000000000000000000000000000007117000000000000000000000000000000000000000000000000000071
c1111111170000000000000000000000000000000000000000000000000000000000007117000000000000000000000000000000000000000000000000000071
c1111111170000000000000000000000000000000000000000000000000000000000007117000000000000000000000000000000000000000000000000000071
cc1111111700000000000000000000000000000000000000000000000000000000000071170000000000000000000088700000cc700000000aa7008870000071
cc1111111700000000000000000000000000000000000000000000000000000000000071170000000000000000000088700000cc700000000aa7008870000071
cc111111170000000000000000000000000000000000000000000000000000000000007117000000000000000000007770000077700000000777007770000071
cc1111111700000000000000000000000000000000000000000000000000000000000071170008888870000000000088788700cc700000aa7aa7008878870071
cc1111111700000000000000000000000000000000000000000000000000000000000071170008778870000000000088788700cc700000aa7aa7008878870071
cc111111170000000000000000000000000000000000000000000000000000000000007117000878887000000000007777770077700000777777007777770071
cc1111111700000000000000000000000000000000000000000000000000000000000071170008888870000000000088700000cc7cc700aa7000008870000071
cc1111111700000000000000000000000000000000000000000000000000000000000071170008888870000000000088700000cc7cc700aa7000008870000071
cc111111170000000000000000000000000000000000000000000000000000000000007117000777777000000000007770000077777700777000007770000071
cc111111170000000000000000000000000000000000000000000000000000000000007117000888887888887000000000000000000000000000000000000071
cc111111170000000000000000000000000000000000000000000000000000000000007117000877887877887000000000000000000000000000000000000071
ccc11111170000000000000000000000000000000000000000000000000000000000007117000878887878887000777777777777777777777777777777777771
ccc11111170000000000000000000000000000000000000000000000000000000000007117000888887888887000711111111111111111111111111111111111
ccc11111170000000000000000000000000000000000000000000000000000000000007117000888887888887000711111111111111111111111111111111111
ccc11111170000000000000000000000000000000000000000000000000000000000007117000777777777777000711111111111111111111111111111111111
ccc11111170000000000000000000000000000000000000000000000000000000000007117000888887000000000711111111111111111111111111111111111
ccc11111170000000000000000000000000000000000000000000000000000000000007117000877887000000000711111111111111111111111111111111111
ccc11111170000000000000000000000000000000000000000000000000000000000007117000878887000000000711111111111111111111111111111111111
cccc1111170000000000000000000000000000000000000000000000000000000000007117000888887000000000711111111111111111111111111111111111
cccc1111170000000000000000000000000000000000000000000000000000000000007117000888887000000000711111111111111111111111111111111111
cccc1111170000000000000000000000000000000000000000000000000000000000007117000777777000000000711111111111111111111111111111111111
cccc1111170000000000000000000000000000000000000000000000000000000000007117000000000000000000711111111111111111111111111111111111
cccc1111170000000000000000000000000000000000000000000000000000000000007117000000000000000000711111111111111111111111111111111111
ccccc111170000000000000000000000000000000000000000000000000000000000007117000000000000000000711111111111111111111111111111111111
ccccc111170000000000000000000000000000000000000000000000000000000000007117777777777777777777711111111111111111111111111111111111
ccccc111170000000000000000000000000000000000000000000000000000000000007111111111111111111111111111111111111111111111111111111111
ccccc111170000000000000000000000000000000000000000000000000000000000007117111777177117771177111111111111111111111111111111111111
ccccc111170000000000000000000000000000000000000000000000000000000000007117111171171717111711117111111111111111111111111111111111
cccccc11170000000000000000000000000000000000000000000000000000000000007117111171171717711777111111111111111111111111111111111111
cccccc11170000000000000000000000000000000000000000000000000000000000007117111171171717111117117111111111111111111111111111111111
cccccc11170000000000000000000000000000000000000000000000000000000000007117771777171717771771111111111111111111111111111111111111
cccccc11170000000000000000000000000000000000000000000000000000000000007111111111111111111111111111111111111111111111111111111111
ccccccc1170000000000000000000000000000000000000000000000000000000000007117777777777777777777777777111111111111111111111111111111
ccccccc1170000000000000000000000000000000000000000000000000000000000007117000000000000000000000007111111111111111111111111111111
ccccccc1170000000000000000000000000000000000000000000000000000000000007117000000000000000000077707111111111111111111111111111111
cccccccc170000000000000000000000000000000000000000000000000000000000007117000000000000000000070707111111111111111111111111111111
cccccccc170000000000000000000000000000000000000000000000000000000000007117000000000000000000070707111111111111111111111111111111
cccccccc170000000000000000000000000000000000000000000000000000000000007117000000000000000000070707111111111111111111111111111111
cccccccc170000000000000000000000000000000000000000000000000000000000007117000000000000000000077707111111111111111111111111111111
ccccccccc70000000000000000000000000000000000000000000000000000000000007117000000000000000000000007111111111111111111111111111111
ccccccccc70000000000000000000000000000000000000000000000000000000000007117777777777777777777777777111111111111111111111111111111
ccccccccc70000000000000000000000000000000000000000000000000000000000007111111111111111111111111111111111111111111111111111111111
ccccccccc70000000000000000000000000000000000000000000000000000000000007117111777171717771711111111111111111111111111111111111111
ccccccccc70000000000000000000000000000000000000000000000000000000000007117111711171717111711117111111111111111111111111111111111
ccccccccc70000000000000000000000000000000000000000000000000000000000007117111771171717711711111111111111111111111111111111111111
ccccccccc70000000000000000000000000000000000000000000000000000000000007117111711177717111711117111111111111111111111111111111111
ccccccccc70000000000000000000000000000000000000000000000000000000000007117771777117117771777111111111111111111111111111111111111
ccccccccc70000000000000000000000000000000000000000000000000000000000007111111111111111111111111111111111111111111111111111111111
ccccccccc70000000000000000000000000c0c0c0c0c0c0c0c0c0000000000000000007117777777777777777777777777111111111111111111111111111111
ccccccccc7000000000000000000000000c0c0c0c0c0c0c0c0c00000000000000000007117000000000000000000000007111111111111111111111111111111
ccccccccc70000000000000000000000000c0c0c0c0c0c0c0c0c0000000000000000007117000000000000000000077707111111111111111111111111111111
ccccccccc7000000000000000000000000c0c0c0c0c0c0c0c0c00000000000000000007117000000000000000000070707111111111111111111111111111111
ccccccccc70000000000000000000000000c0c0c0c0c0c0c0c0c0000000000000000007117000000000000000000070707111111111111111111111111111111
ccccccccc7000000000000000000000000c0c0c0c0c0c0c0c0c00000000000000000007117000000000000000000070707111111111111111111111111111111
ccccccccc70000000000000000000000000c0c0c0000000000000000000000000000007117000000000000000000077707111111111111111111111111111111
ccccccccc7000000000000000000000000c0c0c00000000000000000000000000000007117000000000000000000000007111111111111111111111111111111
ccccccccc70000000000000000000000000c0c0c0000000000000000000000000000007117777777777777777777777777111111111111111111111111111111
ccccccccc7000000000000000000000000c0c0c00000000000000000000000000000007111111111111111111111111111111111111111111111111111111111
ccccccccc70000000000000000000000000c0c0c0000000000000000000000000000007111771177117717771777111111111111111111111111111111111111
ccccccccc7000000000000000000000000c0c0c00000000000000000000000000000007117111711171717171711117111111111111111111111111111111111
ccccccccc7000000000000000000000000ccccc70000000000000000000000000000007117771711171717711771111111111111111111111111111111111111
ccccccccc7000000000000000000000000c77cc70000000000000000000000000000007111171711171717171711117111111111111111111111111111111111
ccccccccc7000000000000000000000000c7ccc70000000000000000000000000000007117711177177117171777111111111111111111111111111111111111
ccccccccc7000000000000000000000000ccccc70000000000000000000000000000007111111111111111111111111111111111111111111111111111111111
ccccccccc7000000000000000000000000ccccc70000000000000000000000000000007117777777777777777777777777111111111111111111111111111111
ccccccccc70000000000000000000000007777770000000000000000000000000000007117000000000000000000000007111111111111111111111111111111
ccccccccc7000000888887000000000000ccccc70000000000000000000000000000007117000000000000000000077707111111111111111111111111111111
ccccccccc7000000877887000000000000c77cc70000000000000000000000000000007117000000000000000000070707111111111111111111111111111111
ccccccccc7000000878887000000000000c7ccc70000000000000000000000000000007117000000000000000000070707111111111111111111111111111111
ccccccccc7000000888887000000000000ccccc70000000000000000000000000000007117000000000000000000070707111111111111111111111111111111
ccccccccc7000000888887000000000000ccccc70000000000000000000000000000007117000000000000000000077707111111111111111111111111111111
ccccccccc70000007777770000000000007777770000000000000000000000000000007117000000000000000000000007111111111111111111111111111111
ccccccccc7000000888887888887000000ccccc7ccccc7bbbbb7bbbbb70000000000007117777777777777777777777777111111111111111111111111111111
ccccccccc7000000877887877887000000c77cc7c77cc7b77bb7b77bb70000000000007116111616161616111161111111111111111111111111111111111111
ccccccccc7000000878887878887000000c7ccc7c7ccc7b7bbb7b7bbb70000000000007116661666161616611111111111111111111111111111111111111111
ccccccccc7000000888887888887000000ccccc7ccccc7bbbbb7bbbbb70000000000007111161616166616111161111111111111111111111111111111111111
ccccccccc7000000888887888887000000ccccc7ccccc7bbbbb7bbbbb70000000000007116611616116116661111111111111111111111111111111111111111
ccccccccc70000007777777777770000007777777777777777777777770000000000007111111111111111111111111111111111111111111111111111111111
ccccccccc7000000888887bbbbb7bbbbb7000000bbbbb7bbbbb70000000000000000007117777777777777777777717777777777771111111111111111111111
ccccccccc7000000877887b77bb7b77bb7000000b77bb7b77bb70000000000000000007117000000000000000000717000000000071111111111111111111111
ccccccccc7000000878887b7bbb7b7bbb7000000b7bbb7b7bbb70000000000000000007117000000000000000000717000000000071111111111111111111111
ccccccccc7000000888887bbbbb7bbbbb7000000bbbbb7bbbbb70000000000000000007117000000000000000000717000000000071111111111111111111111
ccccccccc7000000888887bbbbb7bbbbb7000000bbbbb7bbbbb700000000000000000071170000000000000000007170000ccc00071111111111111111111111
ccccccccc700000077777777777777777700000077777777777700000000000000000071170000000000000000007170000c0000071111111111111111111111
ccccccccc7000000bbbbb7bbbbb7000000000000ddddd70000000000000000000000007117000000000000000000717000000000071111111111111111111111
ccccccccc7000000b77bb7b77bb7000000000000d77dd70000000000000000000000007117000000000000000000717000000000071111111111111111111111
ccccccccc7000000b7bbb7b7bbb7000000000000d7ddd70000000000000000000000007117000000000000000000717000000000071111111111111111111111
ccccccccc7000000bbbbb7bbbbb7000000000000ddddd70000000000000000000000007117000000000000000000717000000000071111111111111111111111
ccccccccc7000000bbbbb7bbbbb7000000000000ddddd70000000000000000000000007117000000000000000000717000000000071111111111111111111111
ccccccccc70000007777777777770000000000007777770000000000000000000000007117000000000000000000717000000000071111111111111111111111
ccccccccc7000000000000888887000000000000ddddd7000000aaaaa70000000000007117000000000000000000717000000000071111111111111111111111
ccccccccc7000000000000877887000000000000d77dd7000000a77aa70000000000007117000000000000000000717000000000071111111111111111111111
ccccccccc7000000000000878887000000000000d7ddd7000000a7aaa70000000000007117000000000000000000717000000000071111111111111111111111
ccccccccc7000000000000888887000000000000ddddd7000000aaaaa7000000000000711700000000000000000071700000c000071111111111111111111111
ccccccccc7000000000000888887000000000000ddddd7000000aaaaa700000000000071170000000000000000007170000c0000071111111111111111111111
ccccccccc700000000000077777700000000000077777700000077777700000000000071170000000000000000007170000c0000071111111111111111111111
ccccccccc7000000000000888887888887000000ddddd7aaaaa7aaaaa700000000000071170000000000000000007170800c0000071111111111111111111111
ccccccccc7000000000000877887877887000000d77dd7a77aa7a77aa700000000000071170000000000000000007170880ccbb0071111111111111111111111
ccccccccc7000000000000878887878887000000d7ddd7a7aaa7a7aaa7000000000000711700000000000000000071708bb0bb00071111111111111111111111
ccccccccc7000000000000888887888887000000ddddd7aaaaa7aaaaa700000000000071170000000000000000007170bb00d000071111111111111111111111
ccccccccc7000000000000888887888887000000ddddd7aaaaa7aaaaa7000000000000711700000000000000000071700800d0a0071111111111111111111111
ccccccccc7000000000000777777777777000000777777777777777777000000000000711700000000000000000071700880daa0071111111111111111111111
ccccccccc7000000000000888887000000000000ddddd7aaaaa7000000000000000000711700000000000000000071700800da00071111111111111111111111
ccccccccc7000000000000877887000000000000d77dd7a77aa70000000000000000007cc7000000000000000000717777777777771111111111111111111111
ccccccccc7000000000000878887000000000000d7ddd7a7aaa70000000000000000007cc7000000000000000000711111111111111111111111111111111111
ccccccccc7000000000000888887000000000000ddddd7aaaaa70000000000000000007cc7000000000000000000711111111111111111111111111111111111
ccccccccc7000000000000888887000000000000ddddd7aaaaa70000000000000000007cc7000000000000000000711111111111111111111111111111111111
ccccccccc70000000000007777770000000000007777777777770000000000000000007cc7000000000000000000711111111111111111111111111111111111
ccccccccc77777777777777777777777777777777777777777777777777777777777777cc77777777777777777777c1111111111111111111111111111111111
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111111111111111111111111111
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1111111111111111
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

__sfx__
010c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000160501b0501b0501805013050130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000180501f0501f0501b05016050130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001305018050180501605011050130000000000000000000000000000000000000000000000000000000000000001a00000000000000000000000000000000000000000000000000000000000000000000
000100003205032050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002e0502e050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100003705037050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000011313200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000010c13200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000010f13200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000f35300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001635300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001335313300000000000000000000002e10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001b35516354000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001f35518354000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001d35516354000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c0000291502715024150221501f1501d1501b150181501615013150111500f1500c1500a150071500a10007100031001105211062110723507235065350453503535025000000000000000000000000000000
010c00001105211062110723507235065350453503535025000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c0000291502715024150221501f1501d1501b150181501615013150111500f1500c1500a150071500a10007100031001105211062110723507235065350453503535025350153501500000000000000000000
