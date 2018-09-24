pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	cam={x=0,y=0}

	actors={}
	daggers={}

	player=make_player()
	
	for i=1,3 do
		local tx,ty=rnd_tile_pos()
		gob=make_enemy("goblin",tx,ty)
	end
		
	room={}
	room.rx=0
	room.ry=0
end

function rnd_tile_pos()
	local tx,ty=0,0
	while true do
		tx=flr(rnd(16))
		ty=flr(rnd(16))
		if not solid(tx,ty) then
			return tx,ty
		end
	end
end

function _update60()
	foreach(actors,update_actor)
	
	if player.x>(room.rx+1)*16 then
		change_room(room.rx+1,room.ry)
	elseif player.x<room.rx*16-1 then
		change_room(room.rx-1,room.ry)
	end
	
	if player.y>(room.ry+1)*16 then
		change_room(room.rx,room.ry+1)
	elseif player.y<room.ry*16-1 then
		change_room(room.rx,room.ry-1)
	end
	
	local daggers_rq={}
	for i,dg in pairs(daggers) do
		update_dagger(dg)
		if (dg.destroy) add(daggers_rq,i)
	end
	
	local actors_rq={}
	for i,a in pairs(actors) do
		if hasf(a.flags,k_actf_dead)
		then
			add(actors_rq,i)
		end
	end
	
	idelfa(actors,actors_rq)
	idelfa(daggers,daggers_rq)
end

function _draw()
	cls(0)
	
	camera(cam.x*8,cam.y*8)
	
	map(room.rx*16,room.ry*16,cam.x*8,cam.y*8,16,16)
	foreach(actors,draw_actor)
	foreach(daggers,draw_dagger)
	
	camera()
	
	print("pos:"..player.x..","..player.y,0,0,7)
	draw_console()
end

function change_room(x,y)
	room.rx=x
	room.ry=y
	cam.x=room.rx*16
	cam.y=room.ry*16
end

k_left=0
k_right=1
k_up=2
k_down=3


-- daggers

dagger_id=0

-- spawn x,y
-- cdir: cardinal direction
--		0 right, 1 left, 2 up, 3 down
function make_dagger(x,y,cdir)
	dagger_id+=1

	local dg={}
	dg.x=x
	dg.y=y
	dg.id=dagger_id
	dg.cdir=cdir
	dg.dx,dg.dy=card_to_vel(dg.cdir)
	dg.spd=0.3
	dg.dx*=dg.spd
	dg.dy*=dg.spd
	
	dg.w=0.5
	dg.h=0.2
	if (cdir>1) dg.w,dg.h=dg.h,dg.w
	
	dg.life_frames=12
	dg.life_t=dg.life_frames
	
	return add(daggers,dg)
end

function update_dagger(dg)
	dg.spd=lerp(dg.spd,0,0.2)

	dg.dx,dg.dy=card_to_vel(dg.cdir)
	dg.dx*=dg.spd
	dg.dy*=dg.spd

	local tlx,tly=dg.x-dg.w,
		dg.y-dg.h
	
	if area_solid(tlx,tly,dg.w,dg.h)
	then
		dg.destroy=true
	end
	
	for i,a in pairs(actors) do
		if dagger_hit_actor(dg,a)
		then
			actor_hit(a,1)
			dg.destroy=true
		end
	end

	dg.x+=dg.dx
	dg.y+=dg.dy
	
	dg.life_t-=1
	if dg.life_t<=0 then
		dg.destroy=true
	end
end

function dagger_hit_actor(dg,a)
	return hasf(a.flags,k_actf_enemy)
		and actor_overlap(a,dg.x-dg.w,
			dg.y-dg.h,dg.w,dg.h)
end

function draw_dagger(dg)
	local x=(dg.x-dg.w)*8
	local y=(dg.y-dg.h)*8
	local flx,fly=false,false
	if (dg.cdir==1) flx=true
	if (dg.cdir==3) fly=true
	local sp=24
	if (dg.cdir>1) sp=25
	
	spr(sp,x,y,1,1,flx,fly)
	
	rect(x,y,x+dg.w*16,y+dg.h*16,7)
end


-->8
-- utils

function lerp(a,b,t)
	return a+(b-a)*t
end

function mag(x,y)
	return sqrt(x*x+y*y)
end

function norm(x,y)
	local l=mag(x,y)
	if (l>0) return x/l,y/l
	return 0,0
end

function scale(x,y,scl)
	return x*scl,y*scl
end

function moveto(v,tg,r)
	if v<tg then
		return min(v+abs(r),tg)
	elseif v>tg then
		return max(v-abs(r),tg)	
	else
		return v
	end
end

function round(v)
	if v-flr(v)<0.5 then
		return flr(v)
	else
		return ceil(v)
	end
end

function roundh(v)
	local l=flr(v)
	if v-l<0.167 then
		return l
	elseif v-l<0.833 then
		return l+0.5
	else
		return ceil(v)
	end
end

function rand(mn,mx)
	mn=mn or 1
	if mx==nil then
		mx=mn
		mn=0
	elseif mn>mx then
		mn,mx=mx,mn
	end
	return p8rnd(mn,mx)
end

function irand(mn,mx)
	return flr(rnd(mn,mx))
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

-- console
_console={}
function log(m)
	add(_console,m)
	if #_console>20 then
		idel(_console,1)
	end
end

function draw_console()
	for i=1,#_console do
		local msg=_console[i]
		print(msg,127-#msg*4,(i-1)*6,7)
	end
end
-------------------------------

function card_to_vel(cdir)
	if cdir==0 then return -1,0
	elseif cdir==1 then return 1,0
	elseif cdir==2 then return 0,-1
	elseif cdir==3 then return 0,1
	else return 0,0 end
end

_cdir_flip_table={1,0,3,2}
_cdir_cw_table={2,3,1,0}
_cdir_ccw_table={3,2,0,1}

function card_flip(cdir)
	return _cdir_flip_table[cdir+1]
end

function card_cw(cdir)
	return _cdir_cw_table[cdir+1]
end

function card_ccw(cdir)
	return _cdir_ccw_table[cdir+1]
end

-- flags

function setf(flg,f)
	return bor(flg,f)
end

function unsetf(flg,f)
	return band(flg,bnot(f))
end

function hasf(flg,f)
	return band(flg,f)~=0
end
-->8
-- physics

function area_solid(x,y,w,h)
	return solid(x,y) or
		solid(x+w,y) or
		solid(x,y+h) or
		solid(x+w,y+h)
end

function solid(x,y)
	return fget(mget(flr(x),flr(y)),0)
end

-->8
-- actors

-- actor flags
k_actf_dead=shl(1,0)
k_actf_fly=shl(1,1)
k_actf_enemy=shl(1,2)

-- actor constants
-- rate that an actor slides
-- to match the tile along
-- current axis
-- see update_actor for details
k_act_slide_rate=1/16

function make_actor(x,y,w,h,f,life)
	life=life or 3
	return add(actors,{
		x=x or 0,y=y or 0,
		w=w or 1,h=h or 1,
		dx=0,dy=0,
		mdir=-1,
		fdir=f or 0,
		flags=0,
		input={x=0,y=0},
		ctrl=nil,
		spd=0.1,
		spd_mul=1,
		life_mx=life,
		life=life,
		hit_t=0,
		hit_stun_f=15
	})
end

function update_actor(a)
	if a.ctrl~=nil then
		a.ctrl(a)
	end
	
	if a.hit_t>0 then
		a.hit_t-=1
	end
	
	local ix,iy=a.input.x,a.input.y
	
	-- todo: better
	if ix~=0 and iy~=0 then
		iy=0
	end
		
	local req=-1
	if (ix<0) req=0
	if (ix>0) req=1
	if (iy<0) req=2
	if (iy>0) req=3
	
	a.mdir=req
	if a.mdir>=0 then
		a.fdir=a.mdir
	end

	local mx,my=card_to_vel(a.mdir)

	-- move to center of tile
	-- if not aligned along tile
	-- as movement is requested
	-- regardless of whether
	-- movement happens
	-- to make it possible to
	-- easily maneuver around
	-- corners
	if mx~=0 then
		local tgy=round(a.y)
		a.y=moveto(a.y,tgy,k_act_slide_rate)
	elseif my~=0 then
		local tgx=round(a.x)
		a.x=moveto(a.x,tgx,k_act_slide_rate)
	end

	local spd=a.spd*a.spd_mul
	
	if (a.hit_t>0) spd=0

	a.dx=mx*spd
	a.dy=my*spd
	
	if actor_move_solid(a) then
		a.dx=0
		a.dy=0
	end
	
	a.x+=a.dx
	a.y+=a.dy
end

function actor_move_solid(a,dx,dy)
	dx=dx or a.dx
	dy=dy or a.dy
	return area_solid(a.x+dx,a.y+dy,7/8,7/8)
end

function actor_overlap(a,x,y,w,h)
	return a.x+a.w>=x and
		a.y+a.h>=y and
		a.x<=x+w and
		a.y<=y+h
end

function actor_hit(a,dmg)
	if a.hit_t<=0 then
		a.life-=dmg
		a.hit_t=a.hit_stun_f
		if a.life<=0 then
			a.flags=setf(a.flags,k_actf_dead)
		end
	end
end

function draw_actor(a)
	if a.hit_t>0 then
		for i=0,15 do
			pal(i,7)
		end
	end

	if a.draw then
		a.draw(a)
	else
		spr(a.sp,a.x*8,a.y*8)
	end
	
	rect(a.x*8,a.y*8,(a.x+7/8)*8,(a.y+7/8)*8,11)
	
	pal()
end

-- player
function make_player()
	local pl=make_actor(8,8)
	pl.ctrl=ctrl_player
	pl.draw=draw_player
	pl.sp_t=0
	pl.sp_r=0.13
	pl.dagger_t=0
	return pl
end

function ctrl_player(pl)
	local ix,iy=0,0
	if (btn(0)) ix-=1
	if (btn(1)) ix+=1
	if (btn(2)) iy-=1
	if (btn(3)) iy+=1

	pl.input.x,pl.input.y=ix,iy
	
	if pl.dagger_t<=0 then
		pl.spd_mul=1
	else
		pl.spd_mul=0
		pl.dagger_t-=1
	end
	
	if ix~=0 or iy~=0 then
		pl.sp_t+=pl.sp_r
		if pl.sp_t>=2 then
			pl.sp_t-=2
		end
	else
		pl.sp_t=0
	end
	
	if (btnp(4)) then
		local sx,sy=card_to_vel(pl.fdir)
		local dgx,dgy=pl.x+sx*.25+3/8,
			pl.y+sy*.25+3/8
		make_dagger(dgx,dgy,pl.fdir)
		pl.dagger_t=8
	end
end

function draw_player(pl)
	
	local sp,flx=10,false
	if pl.fdir==0 then
		flx=true
	elseif pl.fdir==2 then
		sp=14
	elseif pl.fdir==3 then
		sp=12
	end
	
	spr(sp+pl.sp_t,
		pl.x*8,pl.y*8,
		1,1,
		flx,false)
end

-- enemies

function make_enemy(kind,...)
	local fn=k_emake[kind]
	assert(fn)
	local e=fn(...)
	e.flags=setf(e.flags,k_actf_enemy)
	return e
end

function make_goblin(x,y,f)
	local gb=make_actor(x,y,0.5,0.5,f)
	gb.sp=17
	gb.spd=0.05
	gb.spd_mul=0
	gb.ctrl=ctrl_goblin
	gb.t0=irand(60,300)
	return gb
end

function ctrl_goblin(gb)
	gb.t0-=1
	if gb.t0<=0 then
		gb.t0=irand(60,300)
		gb.fdir=card_cw(gb.fdir)
	end

	local fx,fy=card_to_vel(gb.fdir)
	if actor_move_solid(gb) then
		gb.fdir=card_flip(gb.fdir)
		fx=0
		fy=0
	end
	
	gb.input.x=fx
	gb.input.y=fy
end

k_emake={}
k_emake["goblin"]=make_goblin
-->8
-- todo

-- enemies as actors
__gfx__
00000000000000000000000000000000000000000000000000000000000000000ccccc00000000000cccccc00cccccc00cccccc00cccccc000cccc0000cccc00
0000000000000000000000000000000000000000000000000000000000000000000ccc0000000000cfdddd00cfdddd000dddddd00dddddd00cccccc00cccccc0
0070070000000000000000000000000000000000000000000000000000000000000ddd0d00000000cfffcf00cfffcf00fdffffdffdffffdffdccccdffdccccdf
0007700000000000000000000000000000000000000000000000000000000000000ddd0d00000000ddfffff0ddfffff0ffcffcffffcffcfffddddddffddddddf
00077000000000000000000000000000000000000000000000000000000000000dcdddcd00000000dddfff0ddddfff0d0ffffffd0ffffffd0fccccf00fccccf0
0070070000000000000000000000000000000000000000000000000000000000ddccccc000000000cfdcddfdcfdcddfddddccccddddccccdddcddcdfddcddcdf
0000000000000000000000000000000000000000000000000000000000000000d0ccccc000000000cffccc0dcffccc0ddfdcddffdfdcddffdccccccfdccccccf
000000000000000000000000000000000000000000000000000000000000000000c000c0000000000dd0dd00dd000dd0ddd00dd0ddd0000000000dd00dd00000
808888089009900000000000000000009009900000000000000000000000000000000000000d0000000000000000000000000000000000000000000000000000
082222809099990000000000000000009099990000000000000000000000000000000000000d0000000000000000000000000000000000000000000000000000
8222222890099099000000000000000090099099000000000000000000000000000000c0000d0000000000000000000000000000000000000000000000000000
8282282898888899000000000000000098888899000000000000000000000000ddddddcc000d0000000000000000000000000000000000000000000000000000
8222222890088099000000000000000090088099000000000000000000000000000000c0000d0000000000000000000000000000000000000000000000000000
082882809008800000000000000000009008800000000000000000000000000000000000000d0000000000000000000000000000000000000000000000000000
08822880908888000000000000000000908888000000000000000000000000000000000000ccc000000000000000000000000000000000000000000000000000
800880089080080000000000000000009080080000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000bbbbbb000000000000bb000000000000bbbbbb00000000000bbbb00000000000bbbbbb0000000000000
0000000000000000000000000000000000000000000bbbbbbbbbb0000000000bb00000000000bbbbbbbb00000000bbbbb44440000000bbbbbbbb000000000000
000000000000000000000000000000000000000000bbbbbbbbbbbb00000003bbbb30000000f0b444444b0f0000bbbfbb4444440000f0bbbbbbbb0f0000000000
00000000000000000000000000000000000000000bbbbbbbbbbbbb30000003bbbb30000000f0444444440f000bbbbff44444400000fbbbbbbbbbbf0000000000
00000000000000000000000000000000000000000bbbbbbbbbbbbb30000003bbbb30000000ff4fbffbf4ff000b0bbfff4ffbf00000f4bbbbbbbb4f0000000000
0000000000000000000000000000000000000000bbbbbbbbbbbbb3330000b333333b000000ff4f4ff4f4ff00000b44ff4ff4fff000ff44bbbb44ff0000000000
0000000000000000000000000000000000000000bbbbbbbbbbbbb333000bbbbbbbbbb000000ffffffffff0000000444ffffff040000f444bb444f00000000000
0000000000000000000000000000000000000000bbbbbbbbbbbb3333003bbbbbbbbbb300000bbff44ffbb00000000bbbbffff0400004b444444b400000000000
40000000000000006556655500bbbb0000066600bbbbbbbbbbb33333003bbbbbbbbbb300044444ffffbb4440000b44bbfff44f400044bbbbbbb4400000000000
0004000000000000655655560bbbbb3000665550bbbbbbbbbb3333330b333333333333b044f4444bbbbbf44000044444fffb4f400044bbbbbbb44f0000000000
000000040000000055665566bbbbbb3306655555bbbbbbbbb33333330bbbbbbbbbbbbbb04fff44f44bbfff4000b44444ffbb404000044bbbbbb44f0000000000
000000000000000056655665bbbbb333065555550bbbbbbb33333330bbbbbbbbbbbbbbbb44f444fb4444fff000bb4444bbb40040000bb444444bff0000000000
000400400000000056655665bbbbb333655556550bbbbbb333333330bbbbbbbbbbbbbbbb44f444f44bbbbf00044bbbbb4444b040000bbbbbbbbbb00000000000
040000000000000056556655bbb333335555655500bbb333333333003bbbbbbbbbbbbbb3444444fbbbbb00000444bbbbbbbb4400000444bbbbb4000000000000
0000000000000000566566560333333055556555000333333333300003333334433333300fffff40044400000044400000444000000444400440000000000000
00000400000000006665655600333300055555500000033333300000000000044000000000004440000000000000000000000000000044000000000000000000
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888777777888eeeeee888888888888888888888888888888888888888888888888888888888888888ff8ff8888228822888222822888888822888888228888
8888778887788ee88eee88888888888888888888888888888888888888888888888888888888888888ff888ff888222222888222822888882282888888222888
888777878778eeee8eee88888e88888888888888888888888888888888888888888888888888888888ff888ff888282282888222888888228882888888288888
888777878778eeee8eee8888eee8888888888888888888888888888888888888888888888888888888ff888ff888222222888888222888228882888822288888
888777878778eeee8eee88888e88888888888888888888888888888888888888888888888888888888ff888ff888822228888228222888882282888222288888
888777888778eee888ee888888888888888888888888888888888888888888888888888888888888888ff8ff8888828828888228222888888822888222888888
888777777778eeeeeeee888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555566656555555565556665566566655555566566556665666555555555cc5555555555555555555555555555555555555555555555555555555555555
555555555656565555555655565656555565555556555656556556565777555555c5555555555555555555555555555555555555555555555555555555555555
555555555666565555555655566656665565555556555656556556655555577755c5555555555555555555555555555555555555555555555555555555555555
555555555655565555555655565655565565555556555656556556565777555555c5555555555555555555555555555555555555555555555555555555555555
55555555565556665575566656565665556556665566566656665656555555555ccc555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555666565555555566566556665666555555555cc555555555555555555555555555555555555555555555555555555555555555555555555555555555
5555555556565655555556555616556556565777555555c555555555555555555555555555555555555555555555555555555555555555555555555555555555
5555555556665655555556555171556556655555577755c555555555555555555555555555555555555555555555555555555555555555555555555555555555
5555555556555655555556555177156556565777555555c555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555655566655755566517771665656555555555ccc55555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555551777715555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555eee5e5555ee5eee555551771155555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555e555e555e555e55555555117155555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555ee55e555eee5ee5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555e555e55555e5e55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555eee5eee5ee55eee555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555e5555ee55ee5eee5e5555555656556656655555565655665665555555555cc5555555555cc555555555555555555555555555555555555555555555
555555555e555e5e5e555e5e5e55555556565655565655555656565556565777555555c55555555555c555555555555555555555555555555555555555555555
555555555e555e5e5e555eee5e55555555655655565655555666565556565555577755c55555577755c555555555555555555555555555555555555555555555
555555555e555e5e5e555e5e5e55555556565655565655755556565556565777555555c55575555555c555555555555555555555555555555555555555555555
555555555eee5ee555ee5e5e5eee55555656556656665755566655665666555555555ccc575555555ccc55555555555555555555555555555555555555555555
55555555555588888555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555588888555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555577788888555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555588888555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555577788888555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555588888555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555566656555555556656655666566655555666556656655555555555555555555555555555555555555555555555555555555555555555555555555555
55555555565656555555565556565565565657775656565556565555555555555555555555555555555555555555555555555555555555555555555555555555
55555555566656555555565556565565566555555665565556565555555555555555555555555555555555555555555555555555555555555555555555555555
55555555565556555555565556565565565657775656565556565555555555555555555555555555555555555555555555555555555555555555555555555555
55555555565556665575556656665666565655555656556656665555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555eee5ee55ee55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555e555e5e5e5e5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555ee55e5e5e5e5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555e555e5e5e5e5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555eee5e5e5eee5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555e5555ee55ee5eee5e5555555666565655555666565655555ccc55555ccc5555555555555555555555555555555555555555555555555555555555555555
55555e555e5e5e555e5e5e5555555666565655555666565657775c5c55555c5c5555555555555555555555555555555555555555555555555555555555555555
55555e555e5e5e555eee5e5555555656556555555656566655555c5c55555c5c5555555555555555555555555555555555555555555555555555555555555555
55555e555e5e5e555e5e5e5555555656565655755656555657775c5c55755c5c5555555555555555555555555555555555555555555555555555555555555555
55555eee5ee555ee5e5e5eee55555656565657555656566655555ccc57555ccc5555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555eee5eee555555755666565555555566566556665666555555555ccc5575555556665656555556665656555555555cc555555ccc55555555555555555555
555555e55e55555557555656565555555655565655655656577757775c5c55575555566656565555566656565777555555c555555c5c55555555555555555555
555555e55ee5555557555666565555555655565655655665555555555c5c55575555565655655555565656665555577755c555555c5c55555555555555555555
555555e55e55555557555655565555555655565655655656577757775c5c55575555565656565575565655565777555555c555755c5c55555555555555555555
55555eee5e55555555755655566655755566566656665656555555555ccc5575555556565656575556565666555555555ccc57555ccc55555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555eee5eee555555755666565555555566566556665666555555555cc5557555555666565655555666565655555cc555555ccc555555555555555555555555
555555e55e555555575556565655555556555656556556565777577755c55557555556665656555556665656577755c555555c5c555555555555555555555555
555555e55ee55555575556665655555556555656556556655555555555c55557555556565565555556565666555555c555555c5c555555555555555555555555
555555e55e555555575556555655555556555656556556565777577755c55557555556565656557556565556577755c555755c5c555555555555555555555555
55555eee5e55555555755655566655755566566656665656555555555ccc557555555656565657555656566655555ccc57555ccc555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555eee5eee555555755666565555555566566556665666555555555ccc557555555666565655555666565655555ccc555555555cc555555555555555555555
555555e55e5555555755565656555555565556565565565657775777555c555755555666565655555666565657775c5c5555555555c555555555555555555555
555555e55ee5555557555666565555555655565655655665555555555ccc555755555656556555555656566655555c5c5555577755c555555555555555555555
555555e55e55555557555655565555555655565655655656577757775c55555755555656565655755656555657775c5c5575555555c555555555555555555555
55555eee5e55555555755655566655755566566656665656555555555ccc557555555656565657555656566655555ccc575555555ccc55555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555eee5eee555555755666565555555566566556665666555555555ccc557555555666565655555666565655555ccc55555cc5555555555555555555555555
555555e55e5555555755565656555555565556565565565657775777555c555755555666565655555666565657775c5c555555c5555555555555555555555555
555555e55ee55555575556665655555556555656556556655555555555cc555755555656556555555656566655555c5c555555c5555555555555555555555555
555555e55e5555555755565556555555565556565565565657775777555c555755555656565655755656555657775c5c557555c5555555555555555555555555
55555eee5e55555555755655566655755566566656665656555555555ccc557555555656565657555656566655555ccc57555ccc555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555e5555ee55ee5eee5e55555555665666566555555ccc55555cc5555555555555555555555555555555555555555555555555555555555555555555555555
55555e555e5e5e555e5e5e55555556555656565657775c5c555555c5555555555555555555555555555555555555555555555555555555555555555555555555
55555e555e5e5e555eee5e55555556665666565655555c5c555555c5555555555555555555555555555555555555555555555555555555555555555555555555
55555e555e5e5e555e5e5e55555555565655565657775c5c555555c5555555555555555555555555555555555555555555555555555555555555555555555555
55555eee5ee555ee5e5e5eee555556655655566655555ccc55c55ccc555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555666565555555665565655555666565657575566566656655555555555555555555555555555555555555555555555555555555555555555555555555555
55555656565555555656565657775666565655755655565656565555555555555555555555555555555555555555555555555555555555555555555555555555
55555666565555555656556555555656556557775666566656565555555555555555555555555555555555555555555555555555555555555555555555555555
55555655565555555656565657775656565655755556565556565555555555555555555555555555555555555555555555555555555555555555555555555555
55555655566655755666565655555656565657575665565556665555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555666565555555665565655555666565657575566566656655555555555555555555555555555555555555555555555555555555555555555555555555555
55555656565555555656565657775666565655755655565656565555555555555555555555555555555555555555555555555555555555555555555555555555
55555666565555555656566655555656566657775666566656565555555555555555555555555555555555555555555555555555555555555555555555555555
55555655565555555656555657775656555655755556565556565555555555555555555555555555555555555555555555555555555555555555555555555555
55555655566655755666566655555656566657575665565556665555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
82888222822882228888828882888882822882828288888888888888888888888888888888888888888888888222822282888882822282288222822288866688
82888828828282888888828882888828882882828288888888888888888888888888888888888888888888888282888282888828828288288282888288888888
82888828828282288888822282228828882882228222888888888888888888888888888888888888888888888222888282228828822288288222822288822288
82888828828282888888828282828828882888828282888888888888888888888888888888888888888888888882888282828828828288288882828888888888
82228222828282228888822282228288822288828222888888888888888888888888888888888888888888888882888282228288822282228882822288822288
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000001010101000000000000000000010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
252625262526252625262526252625260a0a0a0a0a0a0a2c2b0a0a0a0a0a0a0a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
353635363536353635363536353635360a3c3b3c3b3c3b3c3b3c3b3c3b3c3b0a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
252621212121212121212121212125260a2c2b2c2b2c2b2c2b2c2b2c2b2c2b0a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
353621212121212121212121212135360a3c3b3c3b3c3b3c3b3c3b3c3b3c3b0a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
252621212134212121213421212125260a2c2b2c2b2c2b2c2b2c2b2c2b2c2b0a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
353621213434212121213434212135360a3c3b3c3b3c3b3c3b3c3b3c3b3c3b0a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
252621212121212121212121212125260a2c2b2c2b2c2b2c2b2c2b2c2b2c2b0a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
353621212121212121212121212135363b3c3b3c3b3c3b3c3b3c3b3c3b3c3b0a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
252621212121212121212121212125262b2c2b2c2b2c2b2c2b2c2b2c2b2c2b0a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
353621212121212121212121212135360a3c3b3c3b3c3b3c3b3c3b3c3b3c3b0a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
252621213434212121213434212125260a2c2b2c2b2c2b2c2b2c2b2c2b2c2b0a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
353621212134212121213421212135360a3c3b3c3b3c3b3c3b3c3b3c3b3c3b0a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
252621212121212121212121212125260a2c2b2c2b2c2b2c2b2c2b2c2b2c2b0a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
353621212121212121212121212135360a3c3b3c3b3c3b3c3b3c3b3c3b3c3b0a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
252625262526252625262526252625260a2c2b2c2b2c2b2c2b2c2b2c2b2c2b0a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
353635363536353635363536353635360a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
292a292a292a292a2121292a292a292a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
393a393a393a393a2121393a393a393a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
292a212121212121212121212121292a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
393a212121212121212121212121393a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
292a000000000000000000000000292a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
393a000000000000000000000000393a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
292a000000000000000000000000292a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
393a000000000000000000000000393a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
292a000000000000000000000000292a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
393a000000000000000000000000393a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
292a000000000000000000000000292a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
393a000000000000000000000000393a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
292a000000000000000000000000292a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
393a000000000000000000000000393a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
292a292a292a292a292a292a292a292a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
393a393a393a393a393a393a393a393a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
