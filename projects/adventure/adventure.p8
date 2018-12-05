pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- adventure.p8
--    tdjx

-- frame by frame
_dbg_fbf=false
-- should advance 1 frame
_dbg_adv=false
_dbg_col=false
_dbg_deep=false

function rewrite_tx_table()
	tx=build_tx_table()
	write_tx_table(tx)
end

function _init()
	if false then
		rewrite_tx_table()
	end
	
	poke(0x5f2d,1)
	
	g={
		move_lock=false,
		cls_base=3,
		bg_tile=0,
		fade_t=0,
		cr_payload={}
	}
	
	carts={
		"adventure.p8",
		"adv_maps_1.p8",
		"adv_maps_2.p8",
	}
	
	cam={x=0,y=0}

	actors={}
	daggers={}

	player=make_player()
	
	rooms={}
	load_cart_config()
	load_rooms(0)
	
	room=find_room(0,0)
	oldroom=nil
	
	sleep_t=0
end

function load_cart_config()
	g.cls_base=band(peek(52+56*64),0xf)
	g.bg_tile=peek(52+56*64+1)
	txtbl=read_tx_table()
end

function load_rooms(cartid)
	cartid=cartid or 0
	
	if _active_cart==cartid then
		return
	end

	_active_cart=cartid
	reload(0x800,0x0800,0x3000,carts[_active_cart+1])

	load_cart_config()
	
	g.cls_base=band(peek(52+56*64),0xf)
	g.bg_tile=peek(52+56*64+1)
	
	local cart=carts[_active_cart+1]

	rooms[cart]={}
	for y=0,48,16 do
		for x=0,112,16 do
			local rm=add(rooms[cart],{})
			rm.cartid=cartid
			rm.rx=x/16
			rm.ry=y/16
			rm.spawns={}
			rm.enemies={}
			rm.tx=txtbl[rm.ry+1][rm.rx+1]
			for xx=x,x+15 do
				for yy=y,y+15 do
					if mget(xx,yy)==17 then
						mset(xx,yy,g.bg_tile)
						add(rm.spawns,
							{t="goblin",x=xx,y=yy})
					elseif mget(xx,yy)==7 then
						mset(xx,yy,g.bg_tile)
						add(rm.spawns,
							{t="skull",x=xx,y=yy})
					end
				end
			end
		end
	end
end

function onkey(key)
	if key=="n" then
		_dbg_fbf=not _dbg_fbf
	elseif key=="m" then
		if (_dbg_fbf) _dbg_adv=true
	elseif key=="l" then
		_dbg_col=not _dbg_col
	elseif key==";" then
		_dbg_deep=not _dbg_deep
	elseif key=="-" then
		_console={}
	end
end

function _update60()
	if (stat(30)) onkey(stat(31))
	
	if _dbg_fbf then
		if not _dbg_adv then
			return
		else
			_dbg_adv=false
		end
	end

	if sleep_t>0 then
		sleep_t-=1
		return
	end
	
	if seq_cr and costatus(seq_cr)=="suspended"
	then
		assert(coresume(seq_cr,g.cr_payload))
	else
 	foreach(actors,update_actor)
 	
 	if player.x>(room.rx+1)*16 then
 		change_room(
 			"slide",room.rx+1,room.ry)
 	elseif player.x<room.rx*16-1 then
 		change_room(
 			"slide",room.rx-1,room.ry)
 	end
 	
 	if player.y>(room.ry+1)*16 then
 		change_room(
				"slide",room.rx,room.ry+1)
 	elseif player.y<room.ry*16-1 then
 		change_room(
 			"slide",room.rx,room.ry-1)
 	end
 	
 	if actor_transition(player) and not player.txguard then
 		local tx=room.tx
 		dbg_tbl(tx)
 		player.txguard=true
 		change_room(
 			"fade",tx.rx,tx.ry,tx.cart,tx.tx,tx.ty)
 	elseif not actor_transition(player) then
 		player.txguard=false
 	end
 	
 	local daggers_rq={}
 	for i,dg in pairs(daggers) do
 		update_dagger(dg)
 		if (dg.state==2) add(daggers_rq,i)
 	end
 	
 	local actors_rq={}
 	for i,a in pairs(actors) do
 		if hasf(a.flags,k_actf_destroy)
 		then
 			add(actors_rq,i)
 		end
 	end
 	
 	idelfa(actors,actors_rq)
 	idelfa(daggers,daggers_rq)
 end
end

function _draw()
	if (sleep_t>0) return

	

	local cl=fade_col(g.cls_base,
		g.fade_t)
 cls(cl)
 
 fade_scr(g.fade_t)
	
	camera(cam.x*8,cam.y*8)

	pal(14,0)
	--map(112,48,0,0,16,16)
	map(0,0,0,0,128,64)
--	map(room.rx*16,room.ry*16,cam.x*8,cam.y*8,16,16)
	foreach(actors,draw_actor)
	foreach(daggers,draw_dagger)
	
	camera()
	
	draw_fade(t()/16)
	
--	print("pos:"..player.x..","..player.y,0,0,7)
	draw_console()
	
	--[[local i=0
	for k,v in pairs(room.tx) do
		print(tostr(k)..":"..tostr(v),
			0,i*6,7)
		i+=1
	end]]
	
	print(g.bg_tile,0,0)
	
	if _dbg_fbf then
		print("fbf",117,123,8)
	end
	
	draw_perf()
end

function wait_frames(n)
	while n>0 do
		n-=1
		yield()
	end
end

function slide_camera(rate,delay)
	local rate=1/8
	local delay=1

	while cam.tx<cam.x do
		cam.x-=rate
		wait_frames(delay)
	end
	while cam.tx>cam.x do
		cam.x+=rate
		wait_frames(delay)
	end
	while cam.ty<cam.y do
		cam.y-=rate
		wait_frames(delay)
	end
	while cam.ty>cam.y do
		cam.y+=rate
		wait_frames(delay)
	end
end

function fade_out(delay)
	while g.fade_t<1 do
		wait_frames(delay)
		g.fade_t+=1/16
	end
end

function fade_in(delay)
	while g.fade_t>0 do
		wait_frames(delay)
		g.fade_t-=1/16
	end
end

function seq_change_room(pl)
	-- suspend movement
	g.move_lock=true
	
	if pl.trn=="fade"
	then
		-- todo: fade, climb anim
		fade_out(5)
		
		load_rooms(pl.cart)
		
		local r=find_room(pl.rx,pl.ry,pl.cart)
 	if r then
 		oldroom=room
 		room=r
 	end
		
		if (pl.tx>=0) player.x=pl.tx+pl.rx*16
		if (pl.ty>=0) player.y=pl.ty+pl.ry*16
		
		cam.x=room.rx*16
		cam.y=room.ry*16
		
		fade_in(5)
		
		-- todo: unfade, climb anim 
	elseif pl.trn=="slide" then
		local r=find_room(pl.rx,pl.ry,pl.cart)
 	if r then
 		oldroom=room
 		room=r
 	end
 	
 	cam.tx=room.rx*16
 	cam.ty=room.ry*16
	
		slide_camera()
	end
	
	-- despawn enemies in old room
	for e in all(oldroom.enemies) do
		destroy_actor(e)
	end
	
	-- spawn enemies in new room
	for s in all(room.spawns) do
		add(room.enemies,
			make_enemy(s.t,s.x,s.y))
	end
	
	-- unsuspend movement
	g.move_lock=false
end

function find_room(x,y,cartid)
	cartid=cartid or _active_cart
	local cart=carts[cartid+1]
	return rooms[cart][y*8+x+1]
end

function change_room(trn,x,y,cartid,tx,ty)
	cartid=cartid or _active_cart
	tx=tx or -1
	ty=ty or -1
	printh("|cr| cid:"..cartid..";"..x..","..y..";"..tx..","..ty)
	g.cr_payload.rx=x
	g.cr_payload.ry=y
	g.cr_payload.cart=cartid
	g.cr_payload.trn=trn or "slide"
	g.cr_payload.tx=tx
	g.cr_payload.ty=ty
	seq_cr=cocreate(seq_change_room)
end

k_left=0
k_right=1
k_up=2
k_down=3


-- daggers

dagger_id=0

k_dg_throw=0
k_dg_break=1
k_dg_destroy=2

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
	
	-- collider data
	-- default to horizontal
	-- offset
	dg.offx,dg.offy=0,2/8
	-- dimensions
	dg.w,dg.h=.5,3/16
	
	-- if direction is vertical
	-- swap offset and dimensions
	if cdir>1 then
		dg.w,dg.h=dg.h,dg.w
		dg.offx,dg.offy=dg.offy,dg.offx
	end
	
	dg.life_frames=12
	dg.life_t=dg.life_frames
	dg.destroy_t=6
	
	dg.state=k_dg_throw
	
	return add(daggers,dg)
end

function update_dagger(dg)
	if dg.state==k_dg_throw then
 	dg.spd=lerp(dg.spd,0,0.2)
 
 	dg.dx,dg.dy=card_to_vel(dg.cdir)
 	dg.dx*=dg.spd
 	dg.dy*=dg.spd
 
 	local tlx,tly=dg.x-dg.w,
 		dg.y-dg.h
 	
 	if area_solid(tlx,tly,dg.w*2,dg.h*2,true)
 	then
 		dg.state=k_dg_break
 	end
 	
 	for i,a in pairs(actors) do
 		if dagger_hit_actor(dg,a)
 		then
 			actor_hit(a,1,dg.cdir)
				dg.state=k_dg_break
				sleep(4)
 			break
 		end
 	end
 
 	dg.x+=dg.dx
 	dg.y+=dg.dy
 	
 	dg.life_t-=1
 	if dg.life_t<=0 then
			dg.state=k_dg_destroy
 	end
 elseif dg.state==k_dg_break then
 	dg.destroy_t-=1
 	if (dg.destroy_t<=0) dg.state=k_dg_destroy
 end
end

function dagger_hit_actor(dg,a)
	local colx,coly=
		dg.x-dg.w+dg.offx,
		dg.y-dg.h+dg.offy

	return hasf(a.flags,k_actf_enemy)
		and actor_overlap(a,
			colx,coly,
			dg.w*2,dg.h*2)
end

function draw_dagger(dg)
	local x=dg.x-dg.w
	local y=dg.y-dg.h
	local flx,fly=false,false
	if (dg.cdir==1) flx=true
	if (dg.cdir==3) flx,fly=true,true
	local sp=24
	if (dg.cdir>1) sp=25
	
--	if (dg.state==k_dg_break) sp+=2
	
	spr(sp,x*8,y*8,1,1,flx,fly)
	
	local colx,coly=(x+dg.offx)*8,
		(y+dg.offy)*8
		
	if _dbg_col then
		rect(colx,coly,
			colx+dg.w*16,
			coly+dg.h*16,7)
	end
end

function sleep(f) sleep_t=f end

function dbg_tbl(t)
	printh("table: ")
	for k,v in pairs(t) do
		printh("\t"..tostr(k)..": "..tostr(v))
	end
end

function draw_perf()
	local mem=flr(stat(0))
	local cpu=flr(stat(1)*100)
	local sys=flr(stat(2)*100)
	
	local mems="mem:"..tostr(mem).."/2048"
	local cpus="cpu:"..tostr(cpu).."%"
	local syss="sys:"..tostr(sys).."%"
	
	print(mems,128-#mems*4,0,11)
	print(cpus,128-#cpus*4,6,11)
	print(syss,128-#syss*4,12,11)
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

function dlog(m)
	if (_dbg_deep) log(m)
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

-- cartridges

function load_maps(cart,shared)
	local st,len=0x2000,0x1000
	if (shared) st,len=0x1000,0x2000
	reload(st,st,len,cart)
end

function clamp(v,mn,mx)
	return max(min(v,mx),mn)
end

function clamp01(v)
	return clamp(v,0,1)
end
-->8
-- physics

function area_solid(x,y,w,h,fly)
	return solid(x,y,fly) or
		solid(x+w,y,fly) or
		solid(x,y+h,fly) or
		solid(x+w,y+h,fly)
end

function solid(x,y,fly)
	fly=fly or false
	local m=mget(x,y)
	local solid=fget(m,0)
	if solid and y-flr(y)>=1/2 then
		m=mget(x,ceil(y))
		solid=fget(m,0)
	end
	if solid then
		local half=fget(m,2)
		local horiz=fget(m,3)
		
		if half then
			if horiz then
				local right=fget(m,4)
				if right then
					if (x-flr(x)<0.5) return false
				else
					if (x-flr(x)>=0.5) return false
				end
			else
				local bottom=fget(m,4)
				if bottom then
					if (y-flr(y)<0.5) return false
				else
					if (y-flr(y)>=0.5) return false
				end
			end
		end

		return not fly or not fget(m,1)
	end
end

function transition(x,y)
	return fget(mget(x,y),7)
end

function area_transition(x,y,w,h)
	return transition(x,y) or
		transition(x+w,y) or
		transition(x,y+h) or
		transition(x+w,y+h)
end
-->8
-- actors

-- actor flags
k_actf_dead=shl(1,0)
k_actf_fly=shl(1,1)
k_actf_enemy=shl(1,2)
k_actf_spawn=shl(1,3)
k_actf_destroy=shl(1,4)

-- actor constants
-- rate that an actor slides
-- to match the tile along
-- current axis
-- see  for details
k_act_slide_rate=1/16
k_act_spawn_rate=1/4
k_act_spawn_frames=4

function make_actor(x,y,w,h,f,life)
	life=life or 3
	return add(actors,{
		x=x or 0,y=y or 0,
		w=w or 1,h=h or 1,
		dx=0,dy=0,
		shvx=0,shvy=0,
		shv_t=0,
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
		hit_stun_f=16,
		sp=0,
		sp_t=0,
		sp_r=0.13,
		col1=6,col2=5
	})
end

function update_actor_trans(a)
	if actor_hasf(a,k_actf_spawn)
	then
		a.sp_t-=k_act_spawn_rate
		if a.sp_t<=0 then
			actor_unsetf(a,k_actf_spawn)
			a.sp_t=0
		end
	elseif actor_hasf(a,k_actf_dead)
	then
		a.sp_t+=k_act_spawn_rate
		if a.sp_t>=k_act_spawn_frames
		then
			destroy_actor(a)
		end
	end
end

function destroy_actor(a)
	actor_setf(a,k_actf_destroy)
end

function update_actor(a)
	if not actor_alive(a) then
		update_actor_trans(a)
		return
	end
	
	if a.ctrl~=nil then
		a.ctrl(a)
	end
	
	if (a.hit_t>0) a.hit_t-=1
	if (a.shv_t>0) a.shv_t-=1

	if actor_hasf(a,k_actf_fly)
	then
		actor_fly_move(a)
	else
		actor_land_move(a)
	end
end

function actor_speed(a)
	if a.hit_t>0 then
		return 0
	else
		return a.spd*a.spd_mul
	end
end

function actor_land_move(a)
	local ix,iy=a.input.x,a.input.y
	
	if ix~=0 or iy~=0 then
		a.sp_t+=a.sp_r
		if a.sp_t>=2 then
			a.sp_t-=2
		end
	else
		a.sp_t=0
	end

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

	local spd=actor_speed(a)
	
	mx,my=mx*spd,my*spd

	-- move to center of tile
	-- if not aligned along tile
	-- as movement is requested
	-- regardless of whether
	-- movement happens
	-- to make it possible to
	-- easily maneuver around
	-- corners
	if mx~=0 then
		local tgy=roundh(a.y)
		a.y=moveto(a.y,tgy,k_act_slide_rate)
	elseif my~=0 then
		local tgx=roundh(a.x)
		a.x=moveto(a.x,tgx,k_act_slide_rate)
	end
	
	if a.shv_t>0 then
		mx+=a.shvx
		my+=a.shvy
	end

	if (g.move_lock) mx,my=0,0

	a.dx=mx
	a.dy=my
	
	if actor_move_solid(a) then
		a.dx=0
		a.dy=0
	end
	
	a.x+=a.dx
	a.y+=a.dy
end

function actor_fly_move(a)
	local ix,iy=a.input.x,a.input.y
	
	if ix~=0 or iy~=0 then
		a.sp_t+=a.sp_r
		if a.sp_t>=2 then
			a.sp_t-=2
		end
	else
		a.sp_t=0
	end
	
	local mx,my=ix,iy
	
	local spd=actor_speed(a)
	
	mx,my=mx*spd,my*spd
	
	if a.shv_t>0 then
		mx+=a.shvx
		my+=a.shvy
	end

	if (g.move_lock) mx,my=0,0

	a.dx=mx
	a.dy=my
	
	if actor_move_solid(a) then
		a.dx=0
		a.dy=0
		a.throt=0
		a.theta+=0.5
	end
	
	a.x+=a.dx
	a.y+=a.dy
end

function actor_shove(a,sx,sy,f)
	a.shv_t,a.shvx,a.shvy=f,sx,sy
end

function actor_move_solid(a,dx,dy)
	dx=dx or a.dx
	dy=dy or a.dy
	return area_solid(a.x+dx,a.y+dy,7/8,7/8)
end

function actor_transition(a,dx,dy)
	dx=dx or 0
	dy=dy or 0
	return area_transition(a.x+dx,a.y+dy-2/8,7/8,7/8)
end

function actor_overlap(a,x,y,w,h)
	dlog(a.y+a.h..">="..y..":"..tostr(a.y+a.h>=y))
	return a.x+a.w>=x and
		a.y+a.h>=y and
		a.x<=x+w and
		a.y<=y+h
end

function actors_in(x,y,w,h)
	local ret={}
	for i,a in pairs(actors) do
		if actor_overlap(a,x,y,w,h) then
			add(ret,a)
		end
	end
	return ret
end

function actor_hit(a,dmg,cdir)
	if a.hit_t<=0 then
		a.life-=dmg
		a.hit_t=a.hit_stun_f
		if a.life<=0 then
			actor_kill(a)
		end
		local sx,sy=card_to_vel(cdir)
		actor_shove(a,sx/4,sy/4,a.hit_stun_f/2)
	end
end

function actor_setf(a,flags)
	a.flags=setf(a.flags,flags)
end

function actor_unsetf(a,flags)
	a.flags=unsetf(a.flags,flags)
end

function actor_hasf(a,flags)
	return hasf(a.flags,flags)
end

function actor_alive(a)
	return not actor_hasf(a,k_actf_spawn) and
		not actor_hasf(a,k_actf_dead)
end

function actor_kill(a)
	actor_setf(a,k_actf_dead)
	a.sp_t=0
end

function draw_actor(a)
	if a.hit_t>0 and actor_alive(a)
	then
		for i=0,15 do
			pal(i,7)
		end
	end

	if a.draw then
		a.draw(a)
	else
		local sp,flx=a.sp,false

		if not actor_alive(a)	then
			sp=32
			pal(6,a.col1)
			pal(5,a.col2)
		else
  	if a.fdir==0 then
  		flx=true
  	elseif a.fdir==2 then
  		sp+=4
  	elseif a.fdir==3 then
  		sp+=2
  	end
  end
		spr(sp+a.sp_t,
 		a.x*8,a.y*8,
 		1,1,
 		flx,false)
	end
	
	if _dbg_col then
		rect(a.x*8,a.y*8,(a.x+7/8)*8,(a.y+7/8)*8,11)
	end
	
	pal()
end

-- player
function make_player()
	local pl=make_actor(8,8)
	pl.ctrl=ctrl_player
	--pl.draw=draw_player
	pl.sp=1
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
	
	if (btnp(4)) then
		local sx,sy=card_to_vel(pl.fdir)
		local dgx,dgy=pl.x+sx*.5,
			pl.y+sy*.5
		if pl.fdir==0 then
			dgx+=1/2
			dgy+=2/8
		elseif pl.fdir==1 then
			dgx+=3/8
			dgy+=2/8
		elseif pl.fdir==2 then
			dgx+=2/8
			dgy+=1/2
		elseif pl.fdir==3 then
			dgx+=2/8
			dgy+=1/2
		end
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
	actor_setf(e,k_actf_enemy)
	actor_setf(e,k_actf_spawn)
	e.sp_t=k_act_spawn_frames
	return e
end

function make_goblin(x,y,f)
	local gb=make_actor(x,y,1,1,f)
	gb.sp=17
	gb.spd=0.05
	gb.spd_mul=1
	gb.ctrl=ctrl_goblin
	gb.t0=irand(60,300)
	gb.col1=8
	gb.col2=9
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

function make_skull(x,y,f)
	local sk=make_actor(x,y,1,1,f)
	sk.sp=7
	sk.spd=0.05
	sk.spd_mul=1
	sk.ctrl=ctrl_skull
	sk.draw=draw_skull
	sk.col1=8
	sk.col2=14
	sk.theta=rnd()
	sk.throt=0
	actor_setf(sk,k_actf_fly)
	return sk
end

function ctrl_skull(sk)
	sk.theta+=rnd(0.05)-0.025
	sk.throt+=0.01
	if (sk.throt>1) sk.throt=1
	sk.input.x=cos(sk.theta)*sk.throt
	sk.input.y=sin(sk.theta)*sk.throt
end

function draw_skull(sk)
	spr(sk.sp+sk.sp_t,
 	sk.x*8,sk.y*8,
 	1,1,
 	flx,false)
end

k_emake={}
k_emake["goblin"]=make_goblin
k_emake["skull"]=make_skull
-->8
-- todo

-- multiple enemy types
-- world building
-- loading maps from carts
-- stair/dungeon transitions
-- dynamic dungeon elements
--		doors
--		switches
--		keys/locks
--		opening doors on room clear

-- cart data layout (speculative):
--	cart data at 0x5e00-0x5eff
--	0x00-0x1f: save slot 1
--	0x20-0x3f: save slot 2
-- 0x40-0x5f: save slot 3

-- cart transition thoughts
--		requires cart id, room x,y
--		cart id: 0-7 (3 bits)
--		room x: [0-7] (3 bits), 
--						 y: [0-3] (2 bits)
--  1 byte per transition
--  limit 1 transition per room
--  storing transition per room
--			8x4 rooms, 32 bytes
--		most rooms have none
--			could store with room id
--		 takes more space per transition
--			need fewer entries
--			doesn't seem worth it.
--			in total there's 256 bytes
--			this table needs 32
--			that leaves 224 bytes
--			a single save file needs
--		
-- ★new problem!★
--		cart transition table wont
--		be able to be stored in
--		persistent data
--		will be storing in the last
--	 sprite on the second page
--		of the spritesheet
--		2 pixels per room, 1 byte
--		8x8 pixels, 4x8 room data
--		row 1-2: row 1 of map
--		row 3-4: row 2 of map, etc
--		same encoding as before
--  added benefit of bringing
--  transition table with
--  tileset of spritesheet
--  also immediate vis

-- save data space requirements
--		purely speculative without
--		full knowledge of mechanics
--		attempt to lay out a fairly
--	 generous space requirement
--		just for an idea of whats
--		needed before committing
--		more space.
--		basic thoughts:
--			name (8 chars) [4-8] bytes
--				can store as ascii but...
--				limit to lowercase chars
--				 only needs 4 bits...
--			progression data [2-4] bytes
--			item data [4-8] bytes
--		to be safe estimate 64 bytes
--		64x3 save slots -> 192 bytes
--		256-192=64 (save slots)
--		64-32=32 (transition table)
--		32 bytes left over!
--  probably can keep save slot
--		to 32 bytes which would only
--		require 96 bytes for all 3
--		that would leave 128 bytes
-->8
function draw_fade(t)
	
end

_fades={
	{0,0,0,0,0,0,0,0},
	{1,1,1,1,0,0,0,0},
	{2,2,2,1,1,0,0,0},
	{3,3,4,5,2,1,1,0},
	{4,4,2,2,1,1,1,0},
	{5,5,2,2,1,1,1,0},
	{6,6,13,5,2,1,1,0},
	{7,7,6,13,5,2,1,0},
	{8,8,9,4,5,2,1,0},
	{9,9,4,5,2,1,1,0},
	{10,15,9,4,5,2,1,0},
	{11,11,3,4,5,2,1,0},
	{12,12,13,5,5,2,1,0},
	{13,13,5,5,2,1,1,0},
	{14,9,9,4,5,2,1,0},
	{15,14,9,4,5,2,1,0}
}

function fade_col(col,ft)
	return _fades[col+1][flr(clamp01(ft)*8)+1]
end

function fade_scr(ft)
	for i=1,15 do
		pal(i,_fades[i+1][flr(clamp01(ft)*8)+1],0)
	end
end
-->8
-- cart transition tables

-- encodes transition
-- cart: cartid 0-7
-- room coordinates on map
--	each room is 1 16x16 screen
-- rx:		 room x 0-7
-- ry:			room y 0-3
-- tile to place player in room
-- tx:			tile x 0-15
-- ty:			tile y 0-15
-- encoded into two bytes
function encode_tx(cart,rx,ry,tx,ty)
	-- byte 1
	-- bits 0-2: cart id
	--	bits 3-5: room x
	--	bits 6-7: room y
	-- 
	-- byte 2
	-- bits 0-3: tile y
	-- bits 4-7: tile x

	cart=band(cart,0x7)
	rx=band(rx,0x7)
	ry=band(ry,0x3)
	
	tx=band(tx,0xf)
	ty=band(ty,0xf)
	
	-- cart << 5 + rx << 3 + ry,
	-- ty << 4 + tx
	return bor(
			bor(shl(cart,5),
				shl(rx,2)),
			ry),
		bor(shl(ty,4),tx)
end

-- rb: room byte (cart, room xy)
-- tb: tile byte (tile xy)
function decode_tx(rb,tb)
	return {
		cart=shr(band(rb,0xe0),5),
		rx=shr(band(rb,0x1c),2),
		ry=band(rb,0x3),
		tx=band(tb,0x0f),
		ty=shr(band(tb,0xf0),4),
	}
end

_txtbl_off=0x0e38

-- rx: 0-7
-- ry: 0-3
function tx_room_addr(rx,ry)
	local row=ry*2+flr(rx/4)
	return _txtbl_off+
		(ry*2+flr(rx/4))*64+	-- row
		(rx%4)*2													-- col
end

-- txtbl, array of 32 elements
-- each element should include:
-- 	cart: cart id (0-7),
--		rx: room x (0-7),
--		ry: room y (0-3),
--		tx: tile x (0-15),
--		ty: tile y (0-15)
function write_tx_table(txtbl)
	for y=0,3 do
		local row=txtbl[y+1]
		for x=0,7 do
			local trn=row[x+1]
			local b1,b2=encode_tx(
				trn.cart,trn.rx,trn.ry,trn.tx,trn.ty)
			local addr=tx_room_addr(x,y)
			poke(addr,b1)
			poke(addr+1,b2)
		end
	end
end

function read_tx_table()
	local ret={}
	for y=0,3 do
		local row=add(ret,{})
		for x=0,7 do
			local addr=tx_room_addr(x,y)
			local tx=decode_tx(
				peek(addr),
				peek(addr+1))
			add(row,tx)
		end
	end
	return ret
end

function build_tx_table()
	local ret={}

	for ry=0,3 do
		local row=add(ret,{})
		for rx=0,7 do
			local tx=add(row,{
					cart=0,rx=0,ry=0
				})
			for xx=rx*16,rx*16+15 do
				for yy=ry*16,ry*16+15 do
					local m=mget(xx,yy)
					if fget(m,7) then
						tx.rx,tx.ry=rx,ry
						tx.tx,tx.ty=xx,yy
					end
				end
			end
		end
	end
	
	return ret
end
__gfx__
000000000cccccc00cccccc00cccccc00cccccc000cccc0000cccc0000eeee0000eeee0000000000000000000000000000000000000000000000000000000000
00000000cf555500cf55550005555550055555500cccccc00cccccc00888888008e88e8000000000000000000000000000000000000000000000000000000000
00700700cfffcf00cfffcf00f5ffff5ff5ffff5ff5cccc5ff5cccc5f08e88e80eee88eee00000000000000000000000000000000000000000000000000000000
0007700055fffff055fffff0ffcffcffffcffcfff555555ff555555feee88eee0888888000000000000000000000000000000000000000000000000000000000
00077000555fff05555fff05555ffff5555ffff50fccccf00fccccf0088888800888888000000000000000000000000000000000000000000000000000000000
00700700cf5c55f5c5fc55f55f5cccc55f5cccc555c55c5f55c55c5fe888888ee8eeee8e00000000000000000000000000000000000000000000000000000000
00000000cffccc05ccffcc05555c55ff555c55ff5ccccccf5ccccccf0e8ee8e00e8ee8e000000000000000000000000000000000000000000000000000000000
0000000005505500550005500000055055500000000005500550000000eeee0000eeee0000000000000000000000000000000000000000000000000000000000
80888808009999000099990079899890098998970999999779999990000000000000000000005000000000000000500000000000000000000000000000000000
082222800888989008889890707887077078870700899807708998000c0000c00000000000065000000000000006000000000000000000000000000000000000
82222228888997898889978989999998899999987988889999888897000cc000000000c000065000000000c00000000000000000000000000000000000000000
8282282879989999799899999889988998899889998888899888889900c00c00555555cc00065000500005000006000000000000000000000000000000000000
8222222889988980898889809898898998988989988888877888888900c00c00066665cc000650000606000c0000000000000000000000000000000000000000
08288280979977677997777778888899998888877887788008877887000cc000000000c000055000000000c00000500000000000000000000000000000000000
088228800899888009988880099888977988899078888990099888870c0000c00000000000cccc000000000000c00c0000000000000000000000000000000000
800880080997099700099700799700077000799700009999999900000000000000000000000cc00000000000000c000000000000000000000000000000000000
00000000000000006006600650055005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000660000605506000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066000006556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00666600065005606500005650000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00666600065005606500005650000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066000006556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000660000605506000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000006006600650055005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000f44ff44400bbbb00000fff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000f44f444f0bbbbb3000ffddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000044ff44ffbbbbbb330ffddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000004ff44ff4bbbbb3330fdddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000004ff44ff4bbbbb333fddddfdd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000004f44ff44bbb33333ddddfddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000004f44ff4403333330ddddfddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000ff44f444003333000dddddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5555555555ddfdfffffffffddfffddd5fddffffffddffffffddfffff00000000444444444111111111111111111111c400000000000000000000000000000000
dd5ddd5555ddffffffffdffffffdfdd5ffffffffffffffffffffffff00000000cccccccc4c1c11111c1c11111c1c11c40b000000000000000000000000000000
dddddddd5ddfdfffdffffffffffdfd55ffffffffffffffffffffffff0000000011c1111141c1111111c1111111c111c40bb00000000000000000000000000000
dffddfdd5dddffffffdffddffdffddd5ffffdffdddddddddffffdffd00000000111111114111111111111111111111c400bb000b000000000000000000000000
fddffdff5dddffdfddfddffdffffddd5fdffdddddddddddddddddfff00000000111111114111111111111111111111c4000000bb000000000000000000000000
fffffffd55dfdfffddddddddfffdfdd5fffddddddddddddddddddfff0000000011111c1c41111c1c11111c1c11111cc4000000b0000000000000000000000000
fffdffff5ddfdfff55ddd5ddffffdd55fdddddeeeeeeeeeeeeddddff00000000111111c1411111c1111111c1111111c400bb0000000000000000000000000000
dfffffff5dddfffd55555555ffdfdd55ffddeeeeeeeeeeeeeeeedddf00000000111111114111111144444444111111c400000000000000000000000000000000
55555555555555555dfdfdffffdffdd5ffddeeeeeeeeeeeeeeeeddfd00000000444444444444444441111111111111c400000000000000000000000000000000
ddd5ddd55ddd5ddd5dffffffffffddd5ffddeeeeeeeeeeeeeeeeddff00000000ccccccc44ccccccc4c1c11111c1c11c400000000000000000000000000000000
ddddddd55ddfddff5ddffdfddfdffdd5dfddeeeeeeeeeeeeeeeed5ff0000000011c111c441c1111141c1111111c111c400000000000000000000000000000000
fdffdfd55ddddffd55ddfffffffffd55ffd5eeeeeeeeeeeeeeee5ddf00000000111111c44111111141111111111111c400000000000000000000000000000000
ffffdd5555dfffff5dfdffdfdffdddd5ddd5eeeeeeeeeeeeeeeed5fd00000000111111c44111111141111111111111c400000000000000000000000000000000
dfdffdd55ddffdfd5dddddddffddfdd5dd5deeeeeeeeeeeeeeee55dd0000000011111cc441111c1c41111c1c11111cc400000000000000000000000000000000
ffffffd55dddffff5ddd5dddddd5ddd55555eeeeeeeeeeeeeeeed5dd00000000111111c4411111c1411111c1111111c400000000000000000000000000000000
ffdfdfd55ddffdff55555555555555555555eeeeeeeeeeeeeeee555500000000111111c441111111444444444444444400000000000000000000000000000000
fffdf5d555ddfdffffdffffffffdffff000000000000000000000000000000001111111441111111111111111111111100000000000000000000000000000000
fffddd55d5dddffffffffdfffffffdff000000000000000000000000000000001c1c11111c1c11111c1c11111c1c111100000000000000000000000000000000
fdfdfddd5dddfffddffffffffdffdfff0000000000000000000000000000000011c1111111c1111111c1111111c1111100000000000000000000000000000000
ffdfddddfdfddffffdfdfffdfffffddd000000000000000000000000000000001111111111111111111111111111111100000000000000000000000000000000
dfffdfdfdddfffffddddfdfffffddfdf000000000000000000000000000000001111111111111111111111111111111100000000000000000000000000000000
fffffffdfffdffdfdddfdfdfdfffddd50000000000000000000000000000000011111c1c11111c1c11111c1c11111c1c00000000000000000000000000000000
ffdfffffffdfffff55dddffffffddd5d00000000000000000000000000000000111111c1111111c1111111c1111111c100000000000000000000000000000000
fffffdffffffdfff5d5fdfffffdfdd55000000000000000000000000000000001111111111111111411111111111111400000000000000000000000000000000
fddfffff00000000000000000000000000000000000000000000000000000000111111110000000000000000000000000000000030000000000042b100000000
ffffffff000000000000000000000000000000000000000000000000000000001c1c111100000000000000000000000000000000000000000000000000000000
ffffffff0000000000000000000000000000000000000000000000000000000011c1111100000000000000000000000000000000000000000000000000000000
ffffdffd000000000000000000000000000000000000000000000000000000001111111100000000000000000000000000000000000000000000000000000000
fdffdfff000000000000000000000000000000000000000000000000000000001111111100000000000000000000000000000000000000000000000000000000
ffffffff0000000000000000000000000000000000000000000000000000000011111c1c00000000000000000000000000000000000000000000000000000000
fdffffff00000000000000000000000000000000000000000000000000000000111111c100000000000000000000000000000000000000000000000000000000
ffffffdf000000000000000000000000000000000000000000000000000000001111111100000000000000000000000000000000000000000000000000000000
__label__
fddffffffddffffffddffffffddffffffddffffffddffffffddffffffddffffffddffffffddffffffddffffffddffffffddffffffddffffffddffffffddfffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffdffdffffdffdffffdffdffffdffdffffdffdffffdffdffffdffdffffdffdffffdffdffffdffdffffdffdffffdffdffffdffdffffdffdffffdffdffffdffd
fdffdffffdffdffffdffdffffdffdffffdffdffffdffdffffdffdffffdffdffffdffdffffdffdffffdffdffffdffdffffdffdffffdffdffffdffdffffdffdfff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdffffff
ffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdf
fddffffffffdfffffffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdffdffffffddfffff
fffffffffffffdffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdffffffffdffffffffff
fffffffffdffdfffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffffffffff
ffffdffdfffffdddffdffddfffdffddfffdffddfffdffddfffdffddfffdffddfffdffddfffdffddfffdffddfffdffddfffdffddfffdffddffdfdfffdffffdffd
fdffdffffffddfdfddfddffdddfddffdddfddffdddfddffdddfddffdddfddffdddfddffdddfddffdddfddffdddfddffdddfddffdddfddffdddddfdfffdffdfff
ffffffffdfffddd5dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddfdfdfffffffff
fdfffffffffddd5d55ddd5dd55ddd5dd55ddd5dd55ddd5dd55ddd5dd55ddd5dd55ddd5dd55ddd5dd55ddd5dd55ddd5dd55ddd5dd55ddd5dd55dddffffdffffff
ffffffdfffdfdd555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555d5fdfffffffffdf
fddfffffdfffddd533333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333355ddfdfffddfffff
fffffffffffdfdd53b3333333b33333333333333333333333333333333333333333333333333333333333333333333333b3333333333333355ddffffffffffff
fffffffffffdfd553bb333333bb3333333333333333333333333333333333333333333333333333333333333333333333bb33333333333335ddfdfffffffffff
ffffdffdfdffddd533bb333b33bb333b333333333333333333333333333333333333333333333333333333333333333333bb333b333333335dddffffffffdffd
fdffdfffffffddd5333333bb333333bb3333333333333333333333333333333379899893333333333333333333333333333333bb333333335dddffdffdffdfff
fffffffffffdfdd5333333b3333333b33333333333333333333333333333333373788737333333333333333333333333333333b33333333355dfdfffffffffff
fdffffffffffdd5533bb333333bb3333333333333333333333333333333333338999999833333333333333333333333333bb3333333333335ddfdffffdffffff
ffffffdfffdfdd557999999333333333333333333333333333333333333333339898898933333333333333333333333333333333333333335dddfffdffffffdf
fddfffffdfffddd573899833333333333333333333333333333333333333333398999989333333333333333333333333333333333333333355ddfdfffddfffff
fffffffffffdfdd5998888973b33333333333333333333333333333333333333788888993333333333333333333333333b3333333b33333355ddffffffffffff
fffffffffffdfd55988888993bb3333333333333333333333333333333333333399888973333333333333333333333333bb333333bb333335ddfdfffffffffff
ffffdffdfdffddd57888888933bb333b333333333333333333333333333333337997333733333333333333333333333333bb333b33bb333b5dddffffffffdffd
fdffdfffffffddd538877887333333bb3333333333333333333333333333333333333333333333333333333333333333333333bb333333bb5dddffdffdffdfff
fffffffffffdfdd539988887333333b33333333333333333333333333333333333333333333333333333333333333333333333b3333333b355dfdfffffffffff
fdffffffffffdd559999333333bb3333333333333333333333333333333333333333333333333333333333333333333333bb333333bb33335ddfdffffdffffff
ffffffdfffdfdd553333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333335dddfffdffffffdf
fddfffffdfffddd5333333333333333333333333333fff3333333333333333333333333333333333333fff3333333333333333333333333355ddfdfffddfffff
fffffffffffdfdd533333333333333333333333333ff44433333333333333333333333333333333333ff444333333333333333333b33333355ddffffffffffff
fffffffffffdfd553333333333333333333333333ff44444333333333333333333333333333333333ff4444433333333333333333bb333335ddfdfffffffffff
ffffdffdfdffddd53333333333333333333333333f444444333333333333333333333333333333333f444444333333333333333333bb333b5dddffffffffdffd
fdffdfffffffddd5333333333333333333333333f4444f4433333399993333333333333333333333f4444f443333333333333333333333bb5dddffdffdffdfff
fffffffffffdfdd53333333333333333333333334444f444333339898883333333333333333333334444f4443333333333333333333333b355dfdfffffffffff
fdffffffffffdd553333333333333333333333334444f444333398799888333333333333333333334444f444333333333333333333bb33335ddfdffffdffffff
ffffffdfffdfdd553333333333333333333333333444444333339999899733333333333333333333344444433333333333333333333333335dddfffdffffffdf
fddfffffdfffddd53333333333333333333fff33333fff3333333898899833333333333333333333333fff33333fff33333333333333333355ddfdfffddfffff
fffffffffffdfdd5333333333333333333ff444333ff44433333777799793333333333333333333333ff444333ff4443333333333b33333355ddffffffffffff
fffffffffffdfd5533333333333333333ff444443ff44444333338889983333333333333333333333ff444443ff44444333333333bb333335ddfdfffffffffff
ffffdffdfdffddd533333333333333333f4444443f444444333379937993333333333333333333333f4444443f4444443333333333bb333b5dddffffffffdffd
fdffdfffffffddd53333333333333333f4444f44f4444f4433333333333333333333333333333333f4444f44f4444f4433333333333333bb5dddffdffdffdfff
fffffffffffdfdd533333333333333334444f4444444f444333333333333333333333333333333334444f4444444f44433333333333333b355dfdfffffffffff
fdffffffffffdd5533333333333333334444f4444444f444333333333333333333333333333333334444f4444444f4443333333333bb33335ddfdffffdffffff
ffffffdfffdfdd553333333333333333344444433444444333333333333333333333333333333333344444433444444333333333333333335dddfffdffffffdf
fddfffffdfffddd533333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333355ddfdfffddfffff
fffffffffffdfdd533333333333333333333333333333333333333333b33333333333333333333333333333333333333333333333333333355ddffffffffffff
fffffffffffdfd5533333333333333333333333333333333333333333bb333333333333333333333333333333333333333333333333333335ddfdfffffffffff
ffffdffdfdffddd5333333333333333333333333333333333333333333bb333b3333333333333333333333333333333333333333333333335dddffffffffdffd
fdffdfffffffddd53333333333333333333333333333333333333333333333bb3333333333333333333333333333333333333333333333335dddffdffdffdfff
fffffffffffdfdd53333333333333333333333333333333333333333333333b333333333333333333333333333333333333333333333333355dfdfffffffffff
fdffffffffffdd55333333333333333333333333333333333333333333bb33333333333333333333333333333333333333333333333333335ddfdffffdffffff
ffffffdfffdfdd553333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333335dddfffdffffffdf
fddfffffdfffddd533999933333333333333333333333333333333333333333333333333333333333333333333333333333333333333333355ddfdfffddfffff
fffffffffffdfdd53989888333333333333333333333333333333333333333333b3333333b3333333333333333333333333333333333333355ddffffffffffff
fffffffffffdfd559879988833333333333333333333333333333333333333333bb333333bb33333333333333333333333333333333333335ddfdfffffffffff
ffffdffdfdffddd599998997333333333333333333333333333333333333333333bb333b33bb333b333333333333333333333333333333335dddffffffffdffd
fdffdfffffffddd5389889983333333333333333333333333333333333333333333333bb333333bb333333333333333333333333333333335dddffdffdffdfff
fffffffffffdfdd5777799793333333333333333333333333333333333333333333333b3333333b33333333333333333333333333333333355dfdfffffffffff
fdffffffffffdd5538889983333333333333333333333333333333333333333333bb333333bb3333333333333333333333333333333333335ddfdffffdffffff
ffffffdfffdfdd557993799333333333333333333333333333333333333333333333333333333333333333333333333333333333333333335dddfffdffffffdf
fddfffffdfffddd53333333333333333333333333333333333333333333333333cccccc3333333333333333333333333333333333333333355ddfdfffddfffff
fffffffffffdfdd53333333333333333333333333333333333333333333333333b5555fc3b3333333333333333333333333333333333333355ddffffffffffff
fffffffffffdfd553333333333333333333333333333333333333333333333333bfcfffc3bb33333333333333333333333333333333333335ddfdfffffffffff
ffffdffdfdffddd53333333333333333333333333333333333333333333333333fffff5533bb333b333333333333333333333333333333335dddffffffffdffd
fdffdfffffffddd533333333333333333333333333333333333333333333333353fff555333333bb333333333333333333333333333333335dddffdffdffdfff
fffffffffffdfdd53333333333333333333333333333333333333333333333335f55c5fc333333b33333333333333333333333333333333355dfdfffffffffff
fdffffffffffdd5533333333333333333333333333333333333333333333333353cccffc33bb3333333333333333333333333333333333335ddfdffffdffffff
ffffffdfffdfdd553333333333333333333333333333333333333333333333333355355333333333333333333333333333333333333333335dddfffdffffffdf
fddfffffdfffddd533333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333355ddfdfffddfffff
fffffffffffdfdd533333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333355ddffffffffffff
fffffffffffdfd553333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333335ddfdfffffffffff
ffffdffdfdffddd53333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333335dddffffffffdffd
fdffdfffffffddd53333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333335dddffdffdffdfff
fffffffffffdfdd533333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333355dfdfffffffffff
fdffffffffffdd553333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333335ddfdffffdffffff
ffffffdfffdfdd553333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333335dddfffdffffffdf
fddfffffdfffddd53333333333333333333fff33333fff3333333333333333333333333333333333333fff33333fff33333333333333333355ddfdfffddfffff
fffffffffffdfdd5333333333b33333333ff444333ff44433333333333333333333333333333333333ff444333ff4443333333333333333355ddffffffffffff
fffffffffffdfd55333333333bb333333ff444443ff44444333333333333333333333333333333333ff444443ff4444433333333333333335ddfdfffffffffff
ffffdffdfdffddd53333333333bb333b3f4444443f444444333333333333333333333333333333333f4444443f44444433333333333333335dddffffffffdffd
fdffdfffffffddd533333333333333bbf4444f44f4444f4433333333333333333333333333333333f4444f44f4444f4433333333333333335dddffdffdffdfff
fffffffffffdfdd533333333333333b34444f4444444f444333333333333333333333333333333334444f4444444f444333333333333333355dfdfffffffffff
fdffffffffffdd553333333333bb33334444f4444444f444333333333333333333333333333333334444f4444444f44433333333333333335ddfdffffdffffff
ffffffdfffdfdd553333333333333333344444433444444333333333333333333333333333333333344444433444444333333333333333335dddfffdffffffdf
fddfffffdfffddd5333333333333333333333333333fff3333333333333333333333333333333333333fff3333333333333333333333333355ddfdfffddfffff
fffffffffffdfdd53b3333333b3333333b33333333ff44433333333333333333333333333333333333ff444333333333333333333333333355ddffffffffffff
fffffffffffdfd553bb333333bb333333bb333333ff44444333333333333333333333333333333333ff444443333333333333333333333335ddfdfffffffffff
ffffdffdfdffddd533bb333b33bb333b33bb333b3f444444333333333333333333333333333333333f4444443333333333333333333333335dddffffffffdffd
fdffdfffffffddd5333333bb333333bb333333bbf4444f4433333333333333333333333333333333f4444f443333333333333333333333335dddffdffdffdfff
fffffffffffdfdd5333333b3333333b3333333b34444f444333333333333333333333333333333334444f44433333333333333333333333355dfdfffffffffff
fdffffffffffdd5533bb333333bb333333bb33334444f444333333333333333333333333333333334444f4443333333333333333333333335ddfdffffdffffff
ffffffdfffdfdd553333333333333333333333333444444333333333333333333333333333333333344444433333333333333333333333335dddfffdffffffdf
fddfffffdfffddd533333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333355ddfdfffddfffff
fffffffffffdfdd53b3333333b3333333b3333333b333333333333333333333333333333333333333333333333333333333333333333333355ddffffffffffff
fffffffffffdfd553bb333333bb333333bb333333bb3333333333333333333333333333333333333333333333333333333333333333333335ddfdfffffffffff
ffffdffdfdffddd533bb333b33bb333b33bb333b33bb333b33333333333333333333333333333333333333333333333333333333333333335dddffffffffdffd
fdffdfffffffddd5333333bb33339999333333bb333333bb33333333333333333333333333333333333333333333333333333333333333335dddffdffdffdfff
fffffffffffdfdd5333333b333398988833333b3333333b3333333333333333333333333333333333333333333333333333333333333333355dfdfffffffffff
fdffffffffffdd5533bb33333398799888bb333333bb333333333333333333333333333333333333333333333333333333333333333333335ddfdffffdffffff
ffffffdfffdfdd553333333333999989973333333333333333333333333333333333333333333333333333333333333333333333333333335dddfffdffffffdf
fddfffffdfffddd533333333333898899833333333333333333333333333333333333333333333333333333333333333333333333333333355ddfdfffddfffff
fffffffffffdfdd53b33333333777799793333333333333333333333333333333b3333333b33333333333333333333333b3333333333333355ddffffffffffff
fffffffffffdfd553bb33333333888998bb333333333333333333333333333333bb333333bb3333333333333333333333bb33333333333335ddfdfffffffffff
ffffdffdfdffddd533bb333b3379937993bb333b33333333333333333333333333bb333b33bb333b333333333333333333bb333b333333335dddffffffffdffd
fdffdfffffffddd5333333bb33333333333333bb333333333333333333333333333333bb333333bb3333333333333333333333bb333333335dddffdffdffdfff
fffffffffffdfdd5333333b333333333333333b3333333333333333333333333333333b3333333b33333333333333333333333b33333333355dfdfffffffffff
fdffffffffffdd5533bb33333333333333bb333333333333333333333333333333bb333333bb3333333333333333333333bb3333333333335ddfdffffdffffff
ffffffdfffdfdd553333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333335dddfffdffffffdf
fddffffffffdf5d555555555555555555555555555555555555555555555555533333333333333335555555555555555555555555555555555ddfdfffddfffff
fffffffffffddd55dd5ddd55dd5ddd55dd5ddd55dd5ddd55dd5ddd55ddd5ddd53b3333333b3333335ddd5ddddd5ddd55dd5ddd55dd5ddd55d5dddfffffffffff
fffffffffdfdfdddddddddddddddddddddddddddddddddddddddddddddddddd53bb333333bb333335ddfddffdddddddddddddddddddddddd5dddfffdffffffff
ffffdffdffdfdddddffddfdddffddfdddffddfdddffddfdddffddfddfdffdfd533bb333b33bb333b5ddddffddffddfdddffddfdddffddfddfdfddfffffffdffd
fdffdfffdfffdfdffddffdfffddffdfffddffdfffddffdfffddffdffffffdd55333333bb333333bb55dffffffddffdfffddffdfffddffdffdddffffffdffdfff
fffffffffffffffdfffffffdfffffffdfffffffdfffffffdfffffffddfdffdd5333333b3333333b35ddffdfdfffffffdfffffffdfffffffdfffdffdfffffffff
fdffffffffdffffffffdfffffffdfffffffdfffffffdfffffffdffffffffffd533bb333333bb33335dddfffffffdfffffffdfffffffdffffffdffffffdffffff
ffffffdffffffdffdfffffffdfffffffdfffffffdfffffffdfffffffffdfdfd533333333333333335ddffdffdfffffffdfffffffdfffffffffffdfffffffffdf
fddffffffddffffffddffffffddffffffddffffffddffffffddfffffdfffddd5333333333333333355ddfdfffddffffffddffffffddffffffddffffffddfffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffdfdd53b3333333b33333355ddffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffdfd553bb333333bb333335ddfdfffffffffffffffffffffffffffffffffffffffffff
ffffdffdffffdffdffffdffdffffdffdffffdffdffffdffdffffdffdfdffddd533bb333b33bb333b5dddffffffffdffdffffdffdffffdffdffffdffdffffdffd
fdffdffffdffdffffdffdffffdffdffffdffdffffdffdffffdffdfffffffddd5333333bb333333bb5dddffdffdffdffffdffdffffdffdffffdffdffffdffdfff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffdfdd5333333b3333333b355dfdfffffffffffffffffffffffffffffffffffffffffff
fdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdffffffffffdd5533bb333333bb33335ddfdffffdfffffffdfffffffdfffffffdfffffffdffffff
ffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffffffdfffdfdd5533333333333333335dddfffdffffffdfffffffdfffffffdfffffffdfffffffdf

__gff__
0000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000010101000000000000000000000001010101818181010303030300000000010101010d001d0103030303000000000101010100000000030303030000000001000000000000000300000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
7070707070707070707070707070707070707044454670707070707070707070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7063424242424242424242424242627070634254555642424242424242426270000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70434c4c00000000000000004c00417070430000000000000000000000004170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7043004c00000000000000004c4c417070430000000000000000000000004170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
704300000034000000003400004c417070430000000000000000000000004170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
704300003434000000003434004c524242530000000000000000000000004170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
704300000000004c000000000000000000000000000000070000000000004170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70430000000700004c4c00000000000000000000000000000000000000004170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70430000000000004c4c00000700514040500000000700000707000000004170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7043000000000000000000000000417070430000000000000000000000004170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7043004c34340000000034340000417070430000000000000000000000004170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70434c4c4c340000000034000000417070430000000000000000000000004170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70434c4c4c4c0000000000000000417070430000000000000000000000004170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70434c004c0000004c4c00004c00417070430000000000000000000000004170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70604040404040504c4c51404040617070604040404040404040404040406170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70707070707070434c4c41707070707070707070707070707070707070707070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
63424242424242534c4c52424242426270707044454670707070707070707070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4300000000004c4c4c4c4c000011004170634254555642424242424242426270000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4300004c000000004c4c00004c00004170430000000000000000000000004170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
43000000004c00000000004c0000004170430000000000000000000000004170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
43000000000000004c0000000000004170430000000000000000000000004170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4300001100000000000000000000004170430000000000000000000000004170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4300000000004c0000004c000000004170430000000000000000000000004170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4300000000000000000000000000004170430000000000000000000000004170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
43004c0000001100000011000000114170430000000000000000000000004170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4300000000000000000000000000004170430000000000000000000000004170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4300000000594858000000000000004170430000000000000000000000004170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
430000000049784b00004c000000004170430000000000000000000000004170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
43001100005a4a5b000000000011004170430000000000000000000000004170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
43000000004c0000001100000000004170430000000000000000000000004170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4300000000000000000000000000004170604040404040404040404040406170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6040404040404040404040404040406170707070707070707070707070707070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
