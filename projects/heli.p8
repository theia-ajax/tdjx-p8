pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- heli
-- tdjx

fps30_dt=0x0000.0888
fps60_dt=0x0000.0444

g_seed=0xf33d
function gen()
	g_seed+=1
	seq_gen_map(g_seed,{
		island_ct=15,
		island_iter=1000,
		city_ct=25,
		city_iter=200,
	})
end

function _init()
	poke(0x5f2d,1)

	dbg={
		fbf=false,
		adv=false,
		watch=false,
	}
	
	mos={
		x=0,y=0,bt=0,
		px=0,py=0,pbt=0
	}

	sel={x=-1,y=-1,ld=-1}
	--music(5,0,1+4+8)
	heli={
		x=8,y=8,
		dx=0,dy=0,
		r=0,
		dr=0.8,
		mx_spd=12,
		accel=12,
		fric=1,
		bst_acl_scl=2,
		bst_mxspd_scl=1.5,
		fric_drag_scl=75,
		t0=0,dt0=0,
		t_fire=0,
		ct_shot=0,
		fire_rate=0.11,
		armor=1,
		heat=0,
		heat_gain=0.06,
		heat_decay=0.33,
		heat_locktime=4,
		heat_lt0=0,
		mana=0,
		vts={
			4,0,
			3,2,
			-4,2,
			-6,1,
			-9,0,
			-6,-1,
			-4,-2,
			3,-2,
		},
		vtct=9
	}
	
	cam={
		-- position
		posx=0,posy=0,
		
		-- shake
		shkm=0,t_shk=0,
		
		-- shove
		shvm=0,shva=0,shvv=0,
		t_shv=0,shvt=0,
		
		-- final
		x=0,y=0,
		offx=0,offy=0,
		ofdx=0,ofdy=0,
	}
	
	bullets={}
	monsters={}
	pulses={}
		
	init_particles()
	init_timers()
	
	smooth_mode=8
	
	new_map=false
	
	if new_map then
		gen()
		cstore(0x1000,0x1000,0x2000)
	end
		
	level_table={
		{ 
			max_mon=4, -- max monsters spawned
			spawn_min_ival=3, -- minimum interval between spawns
			spawn_chance=0.2, -- chance to spawn on spawn attempt
			spawn_tick=0.5, -- try to spawn every
			kill_target=4,
		},
	}
	
	gm={
		level=1,
		mon_count=0,
		spawn_t0=0,
		spawn_t1=0,
		kill_score=0
	}
	
	init_level(1)
		
--	sfx(16)
end

function _update()
	dt=fps30_dt
	update()
end

--[[
function _update60()
	dt=fps60_dt
	update()
end
]]

function keypress(key)
	if key=="n" then
		dbg.fbf=not dbg.fbf
	elseif key=="m" and dbg.fbf then
		dbg.adv=true
	elseif key=="f" then
		if sel.x>=0 and sel.y>=0 then
			map_fill(sel.x,sel.y,2,16)
		end
	elseif key=="s" then
		smooth_land()
	elseif key=="g" then
		gen()
	elseif key=="w" then
		dbg.watch=not dbg.watch
	end
end

function update()
	while stat(30) do
		keypress(stat(31))
	end
	
	if dbg.fbf then
		if dbg.adv then
			dbg.adv=false
		else
			return
		end
	end

	mos.px,mos.py,mos.pbt=
		mos.x,mos.y,mos.bt
	mos.x,mos.y=stat(32),stat(33)
	mos.bt=stat(34)
	
	if mos.bt==1 and mos.pbt==0 then
		local mx,my=s2w(mos.x,mos.y)
		sel.x,sel.y=flr(mx),flr(my)
	elseif mos.bt==2 and mos.pbt==0 then
		sel.x,sel.y=-1,-1
	end
	
	update_watch()

	update_ocean()
	
	update_level()

	update_heli(heli)
	update_elements(bullets,update_bullet)
	update_elements(monsters,update_monster)
	update_elements(pulses,update_pulse)
	
--	update_director()

	find_bullet_hits()

	update_particles()
	
	update_timers()
	
	local focx=heli.x*8-64+cos(heli.r)*24
	local focy=heli.y*8-56+sin(heli.r)*24
	
	cam.posx=mid(0,lerp(cam.posx,focx,dt*10),112*8)
	cam.posy=mid(0,lerp(cam.posy,focy,dt*10),50*8+2)
	
	cam.x,cam.y=cam.posx,cam.posy
	
	if cam.t_shk>0 then
		-- shake angle
		local shka=rnd()
		cam.x+=cos(shka)*cam.shkm
		cam.y+=sin(shka)*cam.shkm
		cam.t_shk-=dt
	end
	
	if cam.t_shv>0 then
		cam.x+=cos(cam.shva)*cam.shvm
		cam.y+=sin(cam.shva)*cam.shvm
		cam.t_shv-=dt
		cam.shvm,cam.shvv=
			damp(cam.shvm,0,cam.shvv,
				cam.shvt)
	end
	if btnp(5) then
		--local r=rnd()
		--cam.offx=cos(r)*64
		--cam.offy=sin(r)*64

	end
	
	cam.offx+=cam.ofdx
	cam.offy+=cam.ofdy
	
	cam.ofdx+=-cam.offx*0.98*dt
	cam.ofdy+=-cam.offy*1.4*dt
	if (_sgn(cam.ofdx)==_sgn(cam.offx)) cam.ofdx*=.5
	if (_sgn(cam.ofdy)==_sgn(cam.offy)) cam.ofdy*=.5

	if abs(cam.offx)<0.5 and abs(cam.ofdx)<0.1 then
		cam.ofdx=0
		cam.offx=0
	end
	
	if abs(cam.offy)<0.5 and abs(cam.ofdy)<0.1 then
		cam.ofdy=0
		cam.offy=0
	end
	
	
	
	watch(cam.shvm)

	watch("pos:"..heli.x..","..heli.y)	
	watch("vel:"..heli.dx..","..heli.dy)
	watch("fps:"..stat(7))
	watch("mem:"..stat(0)/2048)
	watch("cpu:"..stat(1)*100)
	
	if sel.x>=0 and sel.y>=0 then
		watch("sel:"..sel.x..","..sel.y)
		watch("msk:"..calc_dirt_mask(sel.x,sel.y,smooth_mode))
		watch("val:"..mget(sel.x,sel.y))
		watch("dep:"..sel.ld)
	end
	
	watch("rnd:"..g_seed)

end

function draw_world()
	map(0,0,-cam.x,-cam.y,128,64)
end

function draw_minimap(noents)
-- map bg
	rectfill(0,110,33,127,1)
	rect(0,110,33,127,7)
	
	-- draw map ground tiles
	for x=0,31 do
		for y=0,15 do
			local xx,yy=x*4,y*4
			local c=nil
			if is_dirt(xx,yy) then
				c=3
			elseif is_city(xx,yy) then
				c=6
			elseif is_rubble(xx,yy) then
				c=5
			end
			if (c)	pset(1+x,111+y,c)
		end
	end
	
	if not noents then
		-- draw map heli
		if blink(1/3) then
			local mhx,mhy=world_to_map(heli.x,heli.y)
			local rr=flr(wrap(heli.r+1/16,1)*8)+1
			local offtbl={
				{1,0},{1,-1},{0,-1},{-1,-1},
				{-1,0},{-1,1},{0,1},{1,1}
			}
			local off=offtbl[rr]
			map_pset(mhx,mhy,12)
			map_pset(mhx+off[1],mhy+off[2],12)
		end
	
		-- draw map monsters
	
		for m in all(monsters) do
			local mmx,mmy=world_to_map(m.x,m.y)
			map_pset(mmx,mmy,8)
		end
	end
end

function _draw()
	cls(1)

	if cam.ofdx~=0 or cam.ofdy~=0 then
		for i=0,15 do
			pal(i,12+((i+t()*i)%4))
		end
	else
		pal()
	end

	draw_world()
--	map(0,0,-cam.x,-cam.y,128,64)
	
	pal()
	
	if sel.x>=0 and sel.y>=0 then
		local sx,sy=sel.x*8-cam.x,
			sel.y*8-cam.y
		rect(sx,sy,sx+7,sy+7,10)
	end
	
	foreach(monsters,draw_monster)
	foreach(bullets,draw_bullet)
	draw_heli(heli)
	foreach(pulses,draw_pulse)
	draw_particles()
	
	if cam.ofdx~=0 or cam.ofdy~=0 then
		for i=0,15 do
			pal(i,12+((i+t()*i)%4))
		end
	else
		pal()
	end
	
	-- hud start
	
	-- map bg
	rectfill(0,110,33,127,1)
	rect(0,110,33,127,7)
	
	-- draw map ground tiles
	for x=0,31 do
		for y=0,15 do
			local xx,yy=x*4,y*4
			local c=nil
			if is_dirt(xx,yy) then
				c=3
			elseif is_city(xx,yy) then
				c=6
			elseif is_rubble(xx,yy) then
				c=5
			end
			if (c)	pset(1+x,111+y,c)
		end
	end
	
	-- draw map heli
	if blink(1/3) then
		local mhx,mhy=world_to_map(heli.x,heli.y)
		local rr=flr(wrap(heli.r+1/16,1)*8)+1
		local offtbl={
			{1,0},{1,-1},{0,-1},{-1,-1},
			{-1,0},{-1,1},{0,1},{1,1}
		}
		local off=offtbl[rr]
		map_pset(mhx,mhy,12)
		map_pset(mhx+off[1],mhy+off[2],12)
	end

	-- draw map monsters

	for m in all(monsters) do
		local mmx,mmy=world_to_map(m.x,m.y)
		map_pset(mmx,mmy,8)
	end
	
	-- hud panel
	
	rectfill(34,109,127,127,7)
	rect(34,109,127,127,7)
	
	-- speedometer
	
	local l=sqrt(heli.dx*heli.dx+heli.dy*heli.dy)
	local sf=l/heli.mx_spd
--	pbar(35,111,48,2,sf,3,11,3)
	
	local c=9
	if heli.heat_lt0>0 then
		--if (blink(1/4)) c=8
		c=8
	else
		if (heli.heat>0.75 and blink(1/4)) c=8
	end
	
	local hudy=110

	print("hull:",35,116,12)
	pbar(55,hudy,48,4,heli.armor,1,12,3)
	
	
	hudy+=6

	pbar(55,hudy,48,4,heli.heat,4,c,3)
	print("temp:",35,110,c)

	hudy+=6

	print("mana:",35,122,14)
	pbar(55,hudy,48,4,heli.mana,2,14,3)

	offset_scr(cam.offx,cam.offy)

	if (dbg.watch) draw_watch()
	
	if peek(0x5f2d)==1 then
		circ(mos.x,mos.y,1,11)
	end

	if false then	
	for y=0,127 do
		-- copy half of scanline into buffer in sprite sheet
		memcpy(32*64+32,0x6000+y*64+32,32)

		-- flip all the pixels in the buffer
		for x=0,15 do
			local l=peek(32*64+x+32)
			local r=peek(32*64+(31-x)+32)
			
			-- pixels in pairs,
			-- high bits, right pixel
			-- low bits, left pixel
			-- do some bit twiddling
			-- to swap them
			l=bor(shl(band(l,0xf),4),shr(l,4))
			r=bor(shl(band(r,0xf),4),shr(r,4))
			
			poke(32*64+x+32,r)
			poke(32*64+(31-x)+32,l)
		end
		
		-- write buffer back into screen buffer
		memcpy(0x6000+y*64,32*64+32,32)
	end
	end
end

function pbar(x,y,w,h,f,bg,fg,tk,tkc)
	tk=tk or 0
	tkc=tkc or 0
	f=mid(f,0,1)
	
	rectfill(x,y,x+w,y+h,bg)
	
	if f>0 then
		rectfill(x,y,x+w*f,y+h,fg)
	end
	
	for i=1,tk do
		local x=x+i*(w/(tk+1))
		line(x,y,x,y+h,0)
	end
end

function smnum(num,x,y)
	if (num==nil) return
	num=flr(num)
	pal(7,0)
	
	stack={}

	while num>0 do
		local digit=num%10
		num=flr(num/10)
		add(stack,digit)
	end
	
	
	local j=0
	for i=#stack,1,-1 do
		sspr(stack[i]*4,56,4,4,j*4+x,y,4,4)
		j+=1
	end
	
	pal()
end

function get_lt()
	return level_table[
		mid(1,gm.level,#level_table)]
end

function init_level(level)
	local lt=get_lt()
	
	clear(monsters)
	
	gm.level=level
	gm.mon_count=0
	gm.spawn_t0=lt.spawn_min_ival
	gm.spawn_t1=lt.spawn_tick
end

function update_level()
	local lt=get_lt()
	if gm.mon_count<lt.max_mon then
		if gm.spawn_t0>0 then
			gm.spawn_t0-=dt
		end
		
		gm.spawn_t1-=dt
		if gm.spawn_t1<=0 then
			gm.spawn_t1=lt.spawn_tick
			if gm.spawn_t0<=0 then
				if rnd()<lt.spawn_chance then
					spawn_monster(rnd(128),rnd(64))
					gm.spawn_t0=lt.spawn_min_ival
				end
			end
		end
	end	
end

function spawn_monster(x,y)
	gm.mon_count+=1
	add_monster(x,y)
end

k_map_w=32
k_map_h=16
k_map_ox=1
k_map_oy=111

function map_wpset(wx,wy,c)
	local x,y=world_to_map(wx,wy)
	map_pset(x,y,c)
end

function map_pset(mx,my,c)
	if mx>=0 and mx<k_map_w and
		my>=0 and my<k_map_h
	then
		pset(mx+k_map_ox,
			my+k_map_oy,
			c)
	end
end

function world_to_map(x,y)
	if x>=0 and x<128 and y>=0 and y<64 then
		local fx,fy=x/128,y/64
		return fx*k_map_w,
			fy*k_map_h
	else
		return -1,-1
	end
end

function cam_shake(sec,mag)
	cam.t_shk=sec
	cam.shkm=mag
end

function cam_knock(ang,mag,sec)
	cam.shvm=mag
	cam.shva=ang
	cam.t_shv=sec
	cam.shvt=sec
end

function update_heli(h)
	h.dt0=mid(h.dt0+1*dt,0,4)


	h.t0+=dt*h.dt0
	if (h.t0>1) h.t0-=1
	
	local ix,iy=0,0
	
	if (btn(0)) ix-=1
	if (btn(1)) ix+=1
	if (btn(3)) iy-=1
	if (btn(2)) iy+=1
	
	h.r+=ix*-h.dr*dt
	h.rr=flr(h.r*32)/32
	
	local ddx,ddy=0,0
	
	local boost=false
	if (btn(5)) boost=true
	
	local accel=h.accel
	if (boost) accel*=h.bst_acl_scl
	
	if iy~=0 then
		ddx=cos(h.rr)*accel*dt*iy
		ddy=sin(h.rr)*accel*dt*iy
	end
	
	h.dx+=ddx
	h.dy+=ddy
	
	local mx=h.mx_spd
	if (boost) mx*=h.bst_mxspd_scl

	local fric=h.fric
	
	local l=sqrt(h.dx*h.dx+h.dy*h.dy)
	if l>mx then
		local frac=l/mx
		fric+=lerp(0,h.fric_drag_scl,m01(frac-1))
	end

	local tarspd=moveto(l,0,fric*dt)
	
	local spdscl=tarspd
	if (l>0) spdscl/=l
	
	h.dx*=spdscl
	h.dy*=spdscl
		
	h.x+=h.dx*dt
	h.y+=h.dy*dt
	
	local border=0.5
	
	if h.x<border then
		h.x=border
		h.dx=max(h.dx,0)
	end
	
	if h.x>128-border then
		h.x=128-border
		h.dx=min(h.dx,0)
	end
	
	if h.y<border then
		h.y=border
		h.dy=max(h.dy,0)
	end
	
	if h.y>64-border then
		h.y=64-border
		h.dy=min(h.dy,0)
	end
	
	h.t_fire-=dt
	local fire=btn(4)

	if h.heat_lt0>0 then
		h.heat_lt0-=dt
		h.heat=h.heat_lt0/h.heat_locktime
		if h.heat_lt0<=0 then
			h.heat=0
		end
		fire=false
	end
	
	if fire and h.t_fire<=0 then
		h.heat+=h.heat_gain
	
		if h.heat>=1 then
			h.heat_lt0=h.heat_locktime
			fire=false
			sfx(12)
		end
	
		cam_knock(h.r,2,0.1)
		--cam_shake(0.1,1)
		sfx(1)
		add_bullet(h.x,h.y,h.rr+rndr(-0.015,0.015),
			{spd=25})
		h.ct_shot+=1
		h.t_fire=h.fire_rate
	else
		if h.heat_lt0<=0 then
			local d=h.heat_decay
			h.heat-=d*dt
		end
	end
	
	h.heat=mid(h.heat,0,1)
end

function draw_mesh(x,y,r,mesh,bgcol,linecol)
	x=x or 0
	y=y or 0
	r=r or 0
	bgcol=bgcol or 0
	linecol=linecol or bgcol
	
	local cx,cy=w2s(x,y)
	
	local vtct=#mesh.vts/2
	for i=0,vtct-1 do
		local j1=i%vtct
		local j2=(i+1)%vtct
		local i1,i2=j1*2+1,j2*2+1
		local x1,y1=mesh.vts[i1],mesh.vts[i1+1]
		local x2,y2=mesh.vts[i2],mesh.vts[i2+1]
		local t1=cos(r)*x1-sin(r)*y1+cx
		local t2=sin(r)*x1+cos(r)*y1+cy
		local t3=cos(r)*x2-sin(r)*y2+cx
		local t4=sin(r)*x2+cos(r)*y2+cy
		line(t1,t2,t3,t4,linecol)
	end
	
	if vtct>3 and cx>=0 and cx<=127 and cy>=0 and cy<=127 then
		flood_fill(cx,cy,bgcol,linecol,20)
	end
end

function draw_heli(h)
	draw_mesh(h.x,h.y,h.rr,h,12,0)
	
	local cx,cy=w2s(h.x,h.y)
	local rad=6
	local th=-h.t0
	local x1,y1,x2,y2,x3,y3,x4,y4=
		cos(th)*rad,sin(th)*rad,
		cos(th+.5)*rad,sin(th+.5)*rad,
		cos(th+.25)*rad,sin(th+.25)*rad,
		cos(th+.75)*rad,sin(th+.75)*rad
	line(x1+cx,y1+cy,x2+cx,y2+cy,7)
	line(x3+cx,y3+cy,x4+cx,y4+cy,7)
end

function flood_fill(x,y,c,bg,md,d)
	d=d or 0
	bg=bg or 0
	if (md and d>=md) return
	if (x>128 or x<0 or y>128 or y<0) return
	if (px_fill(x,y,c,bg)) pset(x,y,c)
	if (px_fill(x-1,y,c,bg)) flood_fill(x-1,y,c,bg,md,d+1)
	if (px_fill(x+1,y,c,bg)) flood_fill(x+1,y,c,bg,md,d+1)
	if (px_fill(x,y-1,c,bg)) flood_fill(x,y-1,c,bg,md,d+1)
	if (px_fill(x,y+1,c,bg)) flood_fill(x,y+1,c,bg,md,d+1)
end

function px_fill(x,y,c,bg)
	local p=pget(x,y)
	return p~=c and p~=bg
end

function add_bullet(x,y,r,props)
	p=props or {}
	spd=p.spd or 10
	t_life=p.lifetime or 1
	return add(bullets,{
		destroy=false,
		x=x or 0,y=y or 0,
		r=r or 0,
		spd=spd,t_life=t_life,
		on_destroy=function(b)
			create_explosion(b.x,b.y,
				0.25,0.03,3,function() return 10 end,
				function() return 3 end)
		end,
	})
end

function update_bullet(b)
	b.t_life-=dt
	if b.t_life<=0 then
		b.destroy=true
	end
	
	add_particle(b.x,b.y,{
		lifetime=0.1,
		col=10,
		size=3,f_size=0,
		fric=0.05,
		fade=true
	})

	local vx,vy=cos(b.r)*b.spd,
		sin(b.r)*b.spd
	
	b.x+=vx*dt
	b.y+=vy*dt
end

function draw_bullet(b)
	local cx,cy=w2s(b.x,b.y)
		
	local sz=3
		
	local fx,fy=cos(b.r)*sz+cx,
		sin(b.r)*sz+cy
	local tx,ty=cos(b.r)*-sz+cx,
		sin(b.r)*-sz+cy

	line(fx,fy,tx,ty,10)
	circ(fx,fy,1,10)	

end

function add_monster(x,y)
	return add(monsters,{
		destroy=false,
		x=x,y=y,rad=1.5,health=100,
		dx=(rnd()-0.5)*2,
		dy=(rnd()-0.5)*2,
		ax=0,
		ay=0,
		t0=0,
		dmg_time=0.06,t_dmg=0,
		tf_part=0,part_ivlf=2,
	})
end

function update_monster(m)
	if m.health<=0 then
		m.destroy=true
		gm.kill_score+=1
	end
	
	m.t0+=sin(t()/16)/32
	
	m.dx+=m.ax*dt
	m.dy+=m.ay*dt
	
	local dl=sqrt(m.dx*m.dx+m.dy*m.dy)
	if dl>2 then
		m.dx*=2/dl
		m.dy*=2/dl
	end
	
	m.x+=m.dx*dt
	m.y+=m.dy*dt
	
	local d2=dist2(heli.x,heli.y,
		m.x,m.y)
	
	if d2<256	then
 	m.tf_part-=1
 	if m.tf_part<=0 then
 		local l=mid(sqrt(m.dx*m.dx+m.dy*m.dy)/5,0,1)
 		m.tf_part=lerp(10,m.part_ivlf,l)
 		local a=rnd()*0.3+0.6
 		local px=m.x+cos(a)*3
 		local py=m.y+sin(a)*3
 		local col=7
 		if (is_dirt(px,py)) col=15
 		if (is_city(px,py) or is_rubble(px,py)) col=6
 		add_particle(px,py,{
  		lifetime=0.5,
  		col=col,
  		style="fill",
  		ax=0,ay=15,
 			size=1+rnd(2),
  		dx=(rnd()-0.5)*4,dy=-3
  		-rnd(2),
  	})
 	end
	end
	
	local lx=mid(flr(m.x)-1,0,127)
	local hx=mid(flr(m.x)+2,0,127)
	local ly=mid(flr(m.y)-1,0,127)
	local hy=mid(flr(m.y)+2,0,127)
	
	for x=lx,hx do
		for y=ly,hy do
			destroy_city(x,y)
		end
	end
	
	if (m.t_dmg>0) m.t_dmg-=dt
	
	local d=dist(m.x,m.y,heli.x,heli.y)
	if d<16 and rnd()<0.02 then
		local r=angle_to(m.x,m.y,heli.x,heli.y)
		add_pulse(m.x,m.y,r,3)
		m.ax=heli.x-m.x
 	m.ay=heli.y-m.y
 	local al=sqrt(m.ax*m.ax+m.ay*m.ay)
 	m.ax/=al
 	m.ay/=al
	else
		m.dx*=0.99
		m.dy*=0.99
	end
end

function destroy_city(x,y)
	if is_city(x,y) then
		mset(x,y,7+flr(rnd(4)))
	end
end

function damage_monster(m,amt)
	if m.health<=0 then
		return
	end

	if (m.t_dmg<=0) sfx(3)
	m.t_dmg=m.dmg_time
	m.health-=amt
	
end

function draw_monster(m)
--	spr(64,m.x*8-cam.x,m.y*8-cam.y,2,2)
		
	local mx,my=w2s(m.x,m.y)
		
--	fillellipse(mx,my+12,20,12,0)
		
	if m.t_dmg>0 then
		pal(8,15)
		pal(14,12)
	end
		
	--draw_mesh(m.x,m.y,0,m,14,8)
--	sspr(0,32,16,16,mx-16,my-16,32,32)

--	pset(mx,my,11)
--	circ(mx,my,m.rad*8,11)
	circfill(mx,my,m.rad*8,14)
	circ(mx,my,m.rad*8,0)

	local n=4
	for i=0,n do
		local f=i/n
		circfill(mx-3-4*f,my-2-2*f,2,8)
		circfill(mx+3+4*f,my-2-2*f,2,8)
	end
	
	local seg=3
	for r=5/8,7/8,1/16 do
		for i=seg,0,-1 do
			local rad=(m.rad+i/3-.25)*8
			local a=r+(r-6/8)*((sin(m.t0+i/3)+1)/2*0.4)*(i/6)
			local cx,cy=mx+rad*cos(a),
				my+rad*sin(a)
				
			circfill(cx,cy,4,14)

			if (i==seg) circ(cx,cy,4,0)
		end
	end

	pal()	
end

function find_bullet_hits()
	local bn,mn=#bullets,#monsters
	
	for i=1,mn do
		for j=1,bn do
			local m=monsters[i]
			local b=bullets[j]
			if not b.destroy then
				local d=dist(b.x,b.y,m.x,m.y)
				if d<m.rad+1/8 then
					b.destroy=true
					damage_monster(m,12)
				end
			end
		end
	end
end

function add_pulse(x,y,r,life)
	return add(pulses,{
		destroy=false,
		x=x,y=y,r=r,t_life=life,
		t0=0,tf0=0
	})
end

function update_pulse(p)
	p.t0+=dt
	p.tf0+=1

	p.t_life-=dt
	if p.t_life<=0 then
		p.destroy=true
	end
	
	local vx,vy=cos(p.r)*p.t_life*2,
		sin(p.r)*p.t_life*2
	
	p.x+=vx*dt
	p.y+=vy*dt
end

function draw_pulse(p)
	local px,py=w2s(p.x,p.y)
	--cols={2,14,7,14}
	--circfill(px,py,3+(flr(p.tf0/8)%2),cols[flr(p.t0*8)%4+1])
	cl={2,7,12,14}
	pal(7,cl[flr(p.t0*16)%#cl+1])
	local sz=16
	sspr(flr(p.t0*20)%5*16+16,40,16,16,
		px-(sz/2-1),py-(sz/2-1),sz,sz)
--	spr(82+flr(p.t0*20)%5,px-3,py-3)
	pal()
end

function w2s(wx,wy)
	return wx*8-cam.x,wy*8-cam.y
end

function s2w(sx,sy)
	return (sx+cam.x)/8,(sy+cam.y)/8
end

function update_ocean()
	-- water effect
	for x=0,7 do
		for y=0,7 do
			sset(16+x,y,1)
		end
	end

	for x=0,7 do
		for yy=0,1 do
			local y=sin(x/8+yy/16+t()/4)*1+4*yy-t()/4
			y=flr(y)%8
			sset(16+x,y,13)
		end
	end
end

function init_rq()
	rq={}
end
-->8
-- util

-- slow but maintains order
function compress_slow(a,n)
	local n=n or #a
	local i=1
	while i<n do
		local j=i
		while a[j]==nil and j<n do
			local k=j+1
			while k<n and a[k]==nil do
				k+=1
			end
			a[j]=a[k]
			a[k]=nil
			j=k
		end
		i+=1
	end
end

function idel(a,i)
	local n=#a
	if (i<1 or i>n) return
	a[i]=nil
	
	for j=i,n-1 do
		a[j]=a[j+1]
	end
	a[n]=nil
end

function compress(a,n)
	local n=n or #a
	local h,t=1,n

	-- wind tail back to first
	-- non-nil entry in case len
	-- is wrong
	while a[t]==nil and t>h do
		t-=1
	end

	while h<t do
		if a[h]==nil then
			a[h]=a[t]
			a[t]=nil
			while a[t]==nil and t>h do
				t-=1
			end
		end
		h+=1
	end
end

__watch={}

function watch(m)
	m=tostr(m)
	local len=#m*4
	if (len>__watch.sx) __watch.sx=len
	__watch.sy+=6
	add(__watch,m)
end

function update_watch()
	__watch={sx=0,sy=0}
end

function draw_watch()
	local n=#__watch
	for i=1,n do
		local m=__watch[i]
		print(m,0,(i-1)*6,11)
	end
end

_logs={}

function log(m,c)
	add(_logs,{m=tostr(m),c=c or 7})
	local n=#_logs
	if n>21 then
		for i=2,n do
			_logs[i]=_logs[i+1]
		end
		_logs[n]=nil
	end
end

function draw_log()
	local n=#_logs
	for i=1,n do
		local l=_logs[i]
		print(l.m,127-#l.m*4,(i-1)*6,l.c)
	end
end

function mod(a,b)
	local r=a%b
	if r>=0 then
		return r
	else
		return r+b
	end
end

function dist2(x1,y1,x2,y2)
	local dx,dy=x2-x1,y2-y1
	return dx*dx+dy*dy
end

function dist(x1,y1,x2,y2)
	return sqrt(dist2(x1,y1,x2,y2))
end

function sqr(n)
	return n*n
end

function angle_to(ox,oy,tx,ty)
	return atan2(tx-ox,ty-oy)
end

function wrap(a,l)
	return mid(a-flr(a/l)*l,0,l)
end

function angle_diff(a,b)
	local d=wrap(b-a,1)
	if (d>0.5) d-=1
	return d
end

-- a: current value
-- b: target value
-- vel: current velocity
-- tm: approx time in seconds to take
-- mx: max speed (defaults inf)
-- ts: timestep (defaults dt)
-- returns result,velocity
-- feed velocity back in
-- to subsequent calls
-- e.g.
-- a,v=damp(a,1,v,0.5,2)
function damp(a,b,vel,tm,mx,ts)
	mx=mx or 32767
	ts=ts or dt
	tm=max(.0001,tm or 0)
	local omega=2/tm
	
	local x=omega*ts
	local exp=1/(1+x+.48*x*x+.235*x*x*x)
	local c=b-a
	local orig=b
	
	local mxc=mx*tm
	c=mid(c,-mxc,mxc)
	b=a-c
	
	local tmp=(vel+omega*c)*ts
	vel=(vel+omega*tmp)*exp
	local ret=b+(c+tmp)*exp
	
	if (orig-a>0)==(ret>orig) then
		ret=orig
		vel=(ret-orig)/ts
	end
	
	return ret,vel
end

function damp_angle(a,b,vel,tm,mx,ts)
	b=a+angle_diff(a,b)
	return damp(a,b,vel,tm,mx,ts)
end

function _sgn(a)
	if a<0 then return -1
	elseif a>0 then return 1
	else return 0 end
end
sgn=_sgn

function moveto(a,b,d)
	if abs(b-a)<=d then
		return b
	else
		return a+sgn(b-a)*d
	end
end

function moveto_angle(a,b,d)
	local dl=angle_diff(a,b)
	if -d<dl and dl<d then
		return b
	else
		return moveto(a,a+dl,d)
	end
end

function m01(v)
	return mid(v,0,1)
end

function lerp(a,b,t)
	return a+(b-a)*t
end

function lerp_angle(a,b,t)
	local d=wrap((b-a),1)
	if (d>0.5) d-=1
	return a+d*m01(t)
end

function update_elements(a,fn)
	assert(type(fn)=="function")
	
	foreach(a,fn)
	clear_destroyed(a)
end

function clear_destroyed(a)
	local n=#a
	for i=1,n do
		local e=a[i]
		if e.destroy then
			if e.on_destroy then
				e.on_destroy(e)
			end
			a[i]=nil
		end
	end
	compress(a,n)
end

function clear(a)
	local n=#a
	for i=1,n do
		a[i]=nil
	end
end

function ins(a,v,idx)
	local n=#a
	assert(idx>0 and idx<=n)
	for i=n+1,idx+1,-1 do
		a[i]=a[i-1]
	end
	a[idx]=v
end

function direction(angle)
	return cos(angle),sin(angle)
end

function rndr(mn,mx)
	return rnd()*(mx-mn)+mn
end

function blink(ivl,tt)
	tt=tt or t()
	return tt%(ivl*2)<ivl
end

function fillellipse(x,y,rx,ry,c)
	local t,b=y-ry,y+ry
	for l=t,b do
		local lx=sin(1-((l-t)/(ry*4)))*rx
		if lx>1 then
			line(ceil(x-lx),l,flr(x+lx),l,c)
		end
	end
end
	
-- timers

function init_timers()
	timers={}
end

function defer(fn,sec,params)
	add(timers,{
		fn=fn or function() end,
		t0=sec or 0,
		params=params,
	})
end

function update_timers()
	update_elements(timers,
		function(tm)
			tm.t0-=dt 
			if tm.t0<=0 then
				tm.destroy=true,
				tm.fn(tm.params)
			end
		end)
end

function sort(a,lt)
	local n=#a
	local i=2
	while i<=n do
		local j=i
		while j>1 and lt(a[j],a[j-1]) do
			a[j],a[j-1]=a[j-1],a[j]
			j-=1
		end
		i+=1
	end
end

-- xorshift16 sort of
function rgen(seed,ct)
	seed=seed or 1
	ct=ct or 0
	local ret={
		seed=seed,
		sx=seed,
		count=0,
		_next=function(self)
			self.count+=1
			self.sx=bxor(self.sx,shl(self.sx,7))
			self.sx=bxor(self.sx,shr(self.sx,9))
			self.sx=bxor(self.sx,shl(self.sx,8))
			return self.sx
		end,
		next=function(self,mn,mx)
			if not mn then
			 mn,mx=0,1
			elseif not mx then
				mx,mn=mn,0
			elseif mx<mn then
				mn,mx=mx,mn
			end
			
			local f=(self:_next()/32767+1)/2
			return f*(mx-mn)+mn
		end,
		reset=function(self,ct)
			self.state=self.seed
			self.count=0
			for i=1,ct do
				self:next()
			end
		end,
		clone=function(self)
			return rgen(self.seed,self.count)
		end
	}
	for i=1,ct do ret:next() end
	return ret
end

function q_push(q,v)
	return add(q,v)
end

function q_pop(q)
	if (#q==0) return nil
	local ret=q[1]
	idel(q,1)
	return ret
end

-->8
-- particles

function init_particles()
	particles={}
	emitters={}
end

function add_particle(x,y,props)
	local p=props or {}
	local lifetime=p.lifetime or 2
	local size=p.size or 2
	return add(particles,{
		x=x,y=y,
		dx=p.dx or 0,dy=p.dy or 0,
		ax=p.ax or 0,ay=p.ay or 0,
		i_size=size,
		f_size=p.f_size or size,
		fric=p.fric or 0.01,
		col=p.col or 10,
		lifetime=lifetime,
		t_life=lifetime,
		fade=p.fade or false,
		style=p.style or "default",
	})
end

function update_particles()
	update_elements(particles,update_particle)
end

function draw_particles()
	foreach(particles,draw_particle)
end

function update_particle(p)
	p.t_life-=dt
	if (p.t_life<=0) p.destroy=true
	
	p.dx+=p.ax*dt
	p.dy+=p.ay*dt
	
	p.x+=p.dx*dt
	p.y+=p.dy*dt
	
	local kf=m01(1-p.fric)
	p.dx*=kf
	p.dy*=kf
end

function draw_particle(p)
	local pt=m01(1-(p.t_life/p.lifetime))
	local sz=lerp(p.i_size,
		p.f_size,
		pt*pt)
		
	local cx,cy=p.x*8-cam.x,
		p.y*8-cam.y
		
	local col=p.col
	if (p.fade) col=fade_col(col,pt)
		
	if col>0 then
		if p.style=="default" or
			p.style=="fill_outline"
		then
			circfill(cx,cy,sz,col)
			circ(cx,cy,sz,0)
		elseif p.style=="fill" then
			circfill(cx,cy,sz,col)
		elseif p.style=="point" then
			pset(cx,cy,col)
		end
	end
end


function create_explosion(x,y,r,ivl,ct,colfn,szfn)
	--sfx(8)
	r=r or .5
	ivl=ivl or 0.03
	ct=ct or 5
	colfn=colfn or function() return 8 end
	szfn=szfn or function() return 4+rnd(2) end
	for i=0,ct-1 do
		defer(function()
			local a=rnd()
			add_particle(x+cos(a)*r,
				y+sin(a)*r,
				{size=szfn(),f_size=0,col=colfn(),fade=true,lifetime=0.25+rnd()*.5})
			end,
			i*ivl)
	end
end
-->8
-- fade

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
	return _fades[col+1][flr(m01(ft)*8)+1]
end

function fade_scr(ft)
	for i=1,15 do
		pal(i,_fades[i+1][flr(m01(ft)*8)+1],0)
	end
end
-->8
-- screen effects

function offset_scr(ox,oy,hlock)
	ox=ox or 0
	oy=oy or 0
	hlock=hlock or false
	
	if ox~=0 then
		ox=flr(mod(ox,128))
		hx=flr(ox/2)
 	for y=0,127 do
 		--scanline address
 		local sla=0x6000+y*64
 		local ihx=64-hx
 	
 		if ox<64 then
 			memcpy(0x4300,sla+ihx,hx)
 			memcpy(sla+hx,sla,ihx)
 			memcpy(sla,0x4300,hx)
 		else
 			memcpy(0x4300,sla,ihx)
 			memcpy(sla,sla+ihx,hx)
 			memcpy(sla+hx,0x4300,ihx)
 		end
 
 		if not hlock and ox%2==1 then
 			local tmp=peek(sla+63)
 			for x=0,63 do
 				local addr=sla+x
 				local c=peek(addr)
 				local ch=shl(band(c,0xf),4)
 				local cl=shr(band(tmp,0xf0),4)
 				tmp=c
 				poke(addr,bor(ch,cl))
 			end
 		end
 	end
 end
	
	if oy~=0 then
		oy=flr(mod(oy,128))
		local h,t=oy*64,(128-oy)*64
 	if oy<64 then
 		memcpy(0x4300,0x6000+t,h)
 		memcpy(0x6000+h,0x6000,t)
 		memcpy(0x6000,0x4300,h)
 	else
 		memcpy(0x4300,0x6000,t)
 		memcpy(0x6000,0x6000+t,h)
 		memcpy(0x6000+h,0x4300,t)
 	end
 end
end


-->8
-- mapgen

function gen_bar(title,frac)
	frac=frac or 0
--	cls(1)
--	local msg="generating"
--	print(msg,centerx(msg),54,7)
--	print(title,centerx(title),60,7)
--	flip()
	draw_world()
	rectfill(0,66,frac*128,70,7)
	local msg="GENERATING"
	print(msg,centerx(msg),54,7)
	print(title,centerx(title),60,7)

	draw_minimap(true)
	flip()
end	

function centerx(msg)
	return 64-#msg*2
end

function seq_gen_map(seed,props)
	gen_map(seed,props)
end

function gen_map(seed,props)
	if (seed) srand(seed)
	
--	memset(0x1000,2,8192)
	for mx=0,127 do
		for my=0,63 do
			mset(mx,my,2)
		end
	end
	
	local p=props or {}
	assert(p.island_ct)
	assert(p.island_iter)
	assert(p.city_ct)
	assert(p.city_iter)
	local island_ct=p.island_ct or 24
	local island_iter=p.island_iter or 600
	local city_ct=p.city_ct or 25
	local city_iter=p.city_iter or 100
	
	for i=1,island_ct do
		gen_island(flr(rnd(128)),flr(rnd(64)),island_iter,
			function(x,y) return true end,
			function(x,y) mset(x,y,16) end,
			{
				{1,0},{-1,0},{0,1},{0,-1}
			})
		gen_bar("CREATING ISLANDS",i/island_ct)
	end
if true then
	smooth_water()
	smooth_land(smooth_mode)

	for i=1,city_ct do
		local x,y=get_coord_until(
			function(x,y)
				return mget(x,y)==16
			end,
			32)
		
		if x>=0 and y>=0 then
			gen_island(x,y,city_iter,
				function(x,y) return mget(x,y)==16 end,
				function(x,y) mset(x,y,3+flr(rnd(4))) end)
		end
		gen_bar("ADDING CITIES",i/city_ct)
	end
	end
end

function get_coord_until(fn_pred,mx)
	local x,y=0,0
	mx=mx or 32767
	local i=0
	while not fn_pred(x,y) do
		i+=1
		if (i>mx) return -1,-1

		x=flr(rnd(128))
		y=flr(rnd(64))
	end
	return x,y
end

_mv_tbl={
	{1,0},{-1,0},{1,0},{-1,0},{0,1},{0,-1}
}
function gen_island(x,y,ct,fn_valid,fn_set,mt)
	x=x or 0
	y=y or 0
	mt=mt or _mv_tbl
	for n=1,ct do
		if fn_valid(x,y) then
			fn_set(x,y)
		end
		local d=flr(rnd(#_mv_tbl))
		local mt=_mv_tbl[d+1]
		local mx,my=mt[1],mt[2]
		x=mid(x+mx,0,127)
		y=mid(y+my,0,63)
	end
end

function map_fill(x,y,fill,with)
	if (fill==with) return
	if (mget(x,y)~=fill) return
	
	mset(x,y,with)
	local q={{x,y}}
	while #q>0 do
		local n=q[1]
		idel(q,1)
		local xx,yy=n[1],n[2]
		
		if mget(xx-1,yy)==fill then
			mset(xx-1,yy,with)
			add(q,{xx-1,yy})
		end
		
		if mget(xx+1,yy)==fill then
			mset(xx+1,yy,with)
			add(q,{xx+1,yy})
		end
		
		if mget(xx,yy-1)==fill then
			mset(xx,yy-1,with)
			add(q,{xx,yy-1})
		end
		
		if mget(xx,yy+1)==fill then
			mset(xx,yy+1,with)
			add(q,{xx,yy+1})
		end
	end
end

function is_fillable_lake(x,y,dep)
	if mget(x,y)==2 then
		local sz=calc_lake_size(x,y,dep+1)
		if sz<=dep then
			return true
		end
	end
	return false
end

--function fill_lake(x,y,dep)
--	map_fill(x,y,2,16)
--end

function calc_lake_size(x,y,mx)
	local openq={}
	local closed={}
	local meta={}
	
	mx=mx or 20
	local maxdep=0
	
	local hash=function(x,y)
		return bor(shl(band(x,0xff),8),band(y,0xff))
	end
	
	if mget(x,y)==2 then
		add(openq,{x=x,y=y})
		meta[hash(x,y)]=0
	end
	
	while #openq>0 do
		local subroot=openq[1]
		idel(openq,1)
		local xx,yy=subroot.x,subroot.y
		local subh=hash(xx,yy)
	
		local children={
			{x=xx-1,y=yy},
			{x=xx+1,y=yy},
			{x=xx,y=yy-1},
			{x=xx,y=yy+1},
		}
	
		local dep=meta[subh] or 0
		
		if dep<mx then
 		for child in all(children) do
 			local h=hash(child.x,child.y)
 			if not closed[h] and mget(child.x,child.y)==2 then
 				closed[h]=true
 				add(openq,child)
 				meta[h]=dep+1
 				if meta[h]>maxdep then
 					maxdep=meta[h]
 				end
 			end
 		end
		end
	end
	
	return maxdep
end

function is_fillable_lake(x,y,dep)
	if mget(x,y)==2 then
		local sz=calc_lake_size(x,y,dep+1)
		if sz<=dep then
			return true
		end
	end
	return false
end

function smooth_water()
	local next_lake=0
	for y=0,63,2 do
		for x=0,127,2 do	
			if is_fillable_lake(x,y,3)
			then
				map_fill(x,y,2,16)
			end
		end
	gen_bar("FILLLING PUDDLES",y/63)  
 end
end

function smooth_land(mode)
	local water_fill={}
	for x=0,127 do
		for y=0,63 do
			if mget(x,y)==2 then
				local s=0
				if (is_land(x-1,y)) s+=1
				if (is_land(x+1,y)) s+=1
				if (is_land(x,y-1)) s+=1
				if (is_land(x,y+1)) s+=1
				if s>=3 then
					add(water_fill,{x,y})
				end
			end
		end
		if (x%4==0)	gen_bar("SMOOTHING COASTLINE",x/127)
	end
	
	for wf in all(water_fill) do
		mset(wf[1],wf[2],16)
	end

	mode=mode or 8
	for y=0,63 do
		for x=0,127 do
			if is_dirt(x,y) then
				smooth_dirt_tile(x,y,mode)
			end
		end
	end
end

function smooth_dirt_tile(x,y,mode)
	local m=calc_dirt_mask(x,y,mode)
	local d=get_dirt_tile(m,mode)
	mset(x,y,d)
end

function get_dirt_tile(idx,m)
	if m==4 then
		return _dirt_table_4[idx+1]
	elseif m==8 then
		return _dirt_table[idx+1]
	end
end

function calc_dirt_mask(x,y,m)
	if m==4 then
		return calc_dirt_mask4(x,y)
	elseif m==8 then
		return calc_dirt_mask8(x,y)
	end
end

function calc_dirt_mask8(x,y)
	local ret=0
	if (is_land(x-1,y-1)) ret+=1
	if (is_land(x,y-1)) ret+=2
	if (is_land(x+1,y-1)) ret+=4
	if (is_land(x-1,y)) ret+=8
	if (is_land(x+1,y)) ret+=16
	if (is_land(x-1,y+1)) ret+=32
	if (is_land(x,y+1)) ret+=64
	if (is_land(x+1,y+1)) ret+=128
	return ret
end

function calc_dirt_mask4(x,y)
	local ret=0
	if (is_land(x,y-1)) ret+=1
	if (is_land(x-1,y)) ret+=2
	if (is_land(x+1,y)) ret+=4
	if (is_land(x,y+1)) ret+=8
	return ret
end

function is_dirt(x,y)
	local m=mget(x,y)
	return m>=16 and m<=48
end

function is_city(x,y)
	local m=mget(x,y)
	return m>=3 and m<=6
end

function is_rubble(x,y)
	local m=mget(x,y)
	return m>=7 and m<=10
end

function is_land(x,y)
	return is_dirt(x,y) or
		is_city(x,y) or
		is_rubble(x,y)
end

_dirt_table={
	-- 0-31
 37,37,30,30,37,37,30,30, --0
 32,32,24,24,32,32,24,24, --8
 31,31,23,23,31,31,23,23, --16
 38,38,40,19,38,38,19,19, --24

	-- 32-63
 37,37,30,30,37,37,30,30,	--32
 32,32,24,24,32,32,24,24,	--40
 31,31,23,23,31,31,23,23,	--48
 38,38,40,19,38,38,19,19,	--56

	-- 64-95
 29,29,39,39,29,29,39,39,	--64
 21,21,41,20,21,21,41,20,	--72
 22,22,43,43,22,22,18,18,	--80
 42,42,44,47,42,42,45,35,	--88

	-- 96-127
 29,29,39,39,29,29,39,39,	--96
 21,21,20,20,21,21,20,20,	--104
 22,22,43,43,22,22,18,18,	--112
 17,17,48,36,17,17,16,28,	--120

	-- 128-159
 37,37,30,30,37,37,30,30,	--128
 32,32,24,24,32,32,24,24,	--136
 31,31,23,23,31,31,23,23,	--144
 38,38,40,19,38,38,19,19,	--152

	-- 160-191
 37,37,30,30,37,37,30,30,	--160
 32,32,24,24,32,32,24,24,	--168
 31,31,23,23,31,31,23,23,	--176
 38,38,40,19,38,38,19,19,	--184

	-- 192-223
 29,29,39,39,29,29,39,39,	--192
 21,21,41,20,21,21,41,20,	--200
 22,22,18,18,22,22,18,18,	--208
 17,17,45,16,17,17,34,27,	--216

	-- 224-255
 29,29,39,39,29,29,39,39,	--224
 21,21,20,20,21,21,20,20,	--232
	22,22,18,18,22,22,18,18, --240
 17,17,33,25,17,17,26,16, --248
}

_dirt_table_4={
	37,30,32,24,
	31,23,38,19,
	29,39,21,20,
	22,18,17,16,
}


-->8

-->8
-- todo

-- monsters:
--		spawning
--		targeting cities
--		targeting player
--		some more attacks
--		maybe different kinds?

-- helicopter:
--		shooting progression
--		powerups?

-- game loop:
--		generate region
--		save some % of city
--			against n waves of monsters
--		success: next region
--		failure: game over,
--			scoring,
--			high scores?
__gfx__
0000000011111111111111113637533377a533352d33d65d66333351353353353353355335535333355335330000000000000000000000000000000000000000
000000001dddd1111dddd1115557566a757577751133225156161651355555535555555555555556555555550000000000000000000000000000000000000000
007007001111ddd11111ddd137775ddda775ddd555555553dddddd5d553556553535565555655655556553530000000000000000000000000000000000000000
00077000111111111111111136665555ddd5555533577d5355555555355565553555555335555553355555530000000000000000000000000000000000000000
000770001111111111111111555556665555ddd57757a75733563653355555535556555535556555555565550000000000000000000000000000000000000000
0070070011ddd11111ddd111686656565d65d8d5665d7756dd56665d556556553565565355355655356556530000000000000000000000000000000000000000
000000001111ddd11111ddd1dddd5ddd53356665555ddd5522566652555555563555555335555553355555530000000000000000000000000000000000000000
00000000111111111111111155555555555555556655555633555555355353335355356335335335365355350000000000000000000000000000000000000000
3b13313311ff1fffff33333333133333331333f1f1fff111fffffffff33333333333333f3333fff11f3333333333333333333333ffff1111f333333f11ffffff
11333b13ffffff33f3313b1331b13b1331b133f13f33fff1f33f3f33f333bb133333bb1f333333ffff333b133333bb133333bb13f33ffff1f333bb1f1ff3ff33
3b1b31333333f333ff3131331b1331331b1b13f1333333fff3333333f33311333b1311313b13333ff33331333b3311333b131133f33333ffff33113f1f333333
31b13b1331133b131f333b1331333b13313133f13113333fff333333ff33333331333331313333333333333333333333313333331f33333ff333333f1f333333
331b131b333b131b1f3b131b333b131f333b133f333b133f1f3b131b1f3b133f333b133f333b1313333b131b333b131b333b13331f3b133ff33b133f1f3b131b
1b3133b11b3133b11f3133b1333133f31b31333f1b3133ff1f3133b11f3133f3333133ff333133b1333133b1f33133b133313333f33133fff33133fff33133b1
b13b1313b13b1313f33b13133fff3fffb13b133f313b13f1f33b13131fff33f3333b133f333b1313333b1313ff3b1313333b13fff33b133ff33ffff1f33f3313
13313bb3133133331f313333f11fff11133133f1f33133f1f3313333111ffffffff1fff133313333333133331ff1333333313ff1f331333ffffff111fff1ffff
ffffff11ff3333fffff331333b1331333b133fff1111dd11f1ffff1ff313f33fff1331fffff333f111ff1111ff3331ff1ff33ff11ff33ff11ff3333f33333ff1
3333fff1f33333fff3333b1311333b1311333b3f1dddffd13ff33ff31fb13b3ff3333b3fff3333ffffffffffff333b1fff3333ffff3333ffff333333333333ff
3b1333f13b1b3133331b31333b1b31333b1b3113dfffffd133b13133ffb131ff331b313f3b1b33ff333333f31f3b31333b1b313333333b1333333b133b133b13
313333f131b13b3333b13b1331b13b1331b13b331df33fd131133b13f3133bf131b13b1331b133f131b13b131f313b3331b13b13333331333333313331333133
333b13ff331b1313331b131b331b131b331b13331dff3fd1333b131bf33b13ff3313131b331b13f1331b131b1f3b1333331b131b333333333333333333333333
3331333f1b3133b1333133b11b3133b11b3133331dfffffd1b3133b1ff31333f13333f331b3133f11b3133b11f3133b1f3313313f3333b13f3333b13f3333b13
333fff3fb13b1313f33b1313f333331fb13b131f1ddfddd1333fff331f3b133ffffffffff33b13f1f13b133f1ffb131fff3b13ffff333133ff3331ffff3331ff
fff11fff13313b33ff313bb3ff3333ff13313bff11ddd111ffff1ffff331333f1ff11111fff133f1ff313bff1f313bff1ff13bf11ff333331ff333f11ff333f1
1ff33ff1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ff3333ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333b13000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333133000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b133333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
31333b13000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
333331ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
333b13f1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002200000000220000deed0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00e2200000022e000deeeed000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000e22222222e000dedeeded00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000228228220000eeeeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008ee22ee80000eeeeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0022eee88eee2200dedeeded00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222ee8228ee22220deeeed000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ee228282282822ee00deed0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22288828828882220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ee82228ee82222ee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0088288ee88288000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000
02e0828ee8280e200000000000000000000000000000000000000077700000000000007770000000000000000000000000000000000000000000000000000000
2e008828828800e20000000000000000000000777000000000007777777000000000777777700000000000777000000000000000000000000000000000000000
0002e08ee80e20000000000700000000000007777700000000007777777000000000777777700000000007777700000000000000000000000000000000000000
022e00e00e00e2200000007770000000000077777770000000077777777700000007777777770000000077777770000000000000000000000000000000000000
2e000e8008e000e20000077777000000000077777770000000077777777700000077777777777000000077777770000000000000000000000000000000000000
00000000000000000000007770000000000077777770000000077777777700000007777777770000000077777770000000000000000000000000000000000000
00000000000000000000000700000000000007777700000000007777777000000000777777700000000007777700000000000000000000000000000000000000
00000000000000000000000000000000000000777000000000007777777000000000777777700000000000777000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000077700000000000007770000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07007700777077700070077077707770777077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70700700077000707070700070000070707070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70700700700007707770077077700700777077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07007770777077700070770077707000777000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003
20202020202020202020202020202020202020202020206111a10101010101010101010101010130404060504091512020202101c18120202020202020202020
20202020202020202020202020202020206111a140505030506030500101412020202071b1010101915120202020202020202101010101010101010101010141
2020202020202020202020202020202020202020202020210101010101010101010101010101015040013001014091111111a150412020202020202020202020
2020202020202020202020202020202061a101305060605060500101010191111151202021010101014120202020202020202101014001010101010101010141
2020202020202020202020202020202020202020202061a101010101010101010101015060405040605050305040010101010101412020202020202020202020
20202020202020202020202020202061a10130604030403060604001606040400141202021010101019111111151202020202150603001010101010101010141
20202020202020202020202020202020202020202020210101010101010101010101010130406060405060303001010101010101412020202020206111111111
115120202020202020202020202020213030603030403060406060605040606030911111a130010101016040404120206111a130013030010101010101010141
20202020202020202020202020202020202020206111a1010101010101010101010101010101604040404040603001010101010141202020202061a101010101
01412020202020202020202020202021606040c1313131b1605060504030305060010150305001014040306050911111a1304001016040010101010101010141
2020202020202020202020202020202020202061a101010101010101010101010101010101306060504060010101010101010101420220202020210160300101
014202202020202020202020202020210101014120202071b1406001010101303060600130406060503040504040300101010101016001010101010101010141
202020202020202020202020202020202020202101010101010101010101010101010101603060306060300101010101010101014120202020207131b1606030
014120202020202020202020202061a1010101412020202021010101010101406001010140506050606050406060010101010101604060010101010101010141
20202020202020202020202020202020202020210101010101010101010101010101010101304050604030010101010101010101412020202020202021403001
0141202020202020202020202061a150303001412020202021010101010101010101010101c1313131b130403030605060010101010140010101c13131b10141
20202020202020202020202020202061111111a101010101c131313131b1010101010101010101010101010101010101010101014120202020202020216050c1
31812020202061111111111111a1404060010141202020202101010101010101010101010141202020216050504030404001010101010101c13181202071b141
202020202020202020202020206111a1010101010101010141202020202101010101010101010101010101010101010101010101911111111151202021305041
202020202020215060503040504060404001019111111111a1010101010101010101010101412020207131b16060503001010101010101014120202020202141
20202020202020202061111111a101010101010101010101412020202071b101010101010101010101010101010101010101010101010101014120202140c181
2020202020f12260405030010101010101010101010101010101010101010101010101010141202020202021306040010101c13131b101014120202020202141
20202020202020202021010101010101010101010101c13181202020202071313131b1010101010101010101010101010101010101010101c1311111a1404120
202020202020213001010101010101010101010101010101010101010101010101010101014120202020202150506001c1318120207131318120202020207181
202020202020202020210101010101010101c1313131812020202020202020202020210101010101010101010101010101010101010101014120210140014120
20202020202021010101010101010101010101010101010101010101010101010101010101412020202061a10101010141202020202020202020202020202020
202020202020202020210101c1313131313181202020202020202020202020202020713131b101010101010101010101010101c1313131318120210101014120
202020202061a1500101010101010101010101010101010101010101010101010101010101911151202021010101010141202020202020202020202020202020
20202020202020202071313181202020202020202020202020202020202020202020202020210101010101010101010101010141202020202020210101019111
1151202061a10101010101010101c131313131313131b101010101010101010101010101010101911111a1010101010141202020202020611151202020202020
20202020202020202020202020202020202020202020202020202020202020202020206111a10101016001010101010101010141202020206111a10101010101
019111622201010101010101c131812020202020202071b101010101010101010101010101010101010101010101010141202020202061a10191111111512020
2020202020202020202020202020202020202020202020202020202020202020202020210101010101304050010101010101019111111111a1010101010101c1
31318120210101c131313131812020202020202020202071b10101010101010101010101010101010101c13131b10101915120202061a1010101010101412020
20202020202020615120202020202020202020202020202020202020202020202020202160010160403060504001010101010101010101010101010101010141
20202020713132812020202020202020202020202020202071b10101010101010101010101010101c1318120207131313141206111a101010101010101911151
20202020206111a1911151202020202020d120202020202020202020202020202020207131b10101010101303040406030500101010101010101010101010141
202020202020e1202020202020202020202020202020202020210101010101010101010101010140412020202020202020e12021010101010101010101010141
202020202071b101010191512020d120207220202020202020202020202020202020202020213001015001505050306001010101010101010101010101010142
022020202020202020202020202020202020202020202020202101010101010101010101c1313131812020202020202020202021504030010101010101010141
20202020202071b10101019111111211111211111111512020202020202020202020206111a16050c1313131313131b130010101010101010101010101010141
2020202020202020202020202020202020202020202020202021010101010101010101014120202020202020202020202020f12201600101c13131b101010141
2020202020202071b1010101010101014001016040604120202020202020202020f16231b16050c1812020202020202101010101010101010101010101010191
51206111111111512020611151202020202020202020611111a10101010101010101010141202020202020202020202020202021010101014120207131313141
2020202020202020210101010101010140400160500191111111512020202020202020202160604120202020611111a1010101010101010101010101010101c1
8120210101010141202021604120206111111102202021010101010101010101010101019151202020202061111151202020207131b1010141202020202020e1
20202020202020202101010101010101405050503060604060c1812020202020202020207131b19111111111a101405001010101010101010101010101010141
2020713131b101911111a130911111a10101412020207131313131b1010101010101010101915120202020213131315120202020202101019111512020202020
202020611111512021010101010101014050403060504030c1812020202020202020202020202101010101010101016001010101010101010101010101010191
51202020202160500101605060303001010141202020202020202021010101010101010101019111111111812020207111512020202101010101911111111151
2020202101019111a101010101010101013001300101010141202020202020202020202020202101010101010101016030013040010101010101010101010101
412020202021303001010101506030010101412020202020202061a101010101010101010101010101c18120202020207131111111a10101c13131b101010141
2061113131b10101010101010101010101500101010101014120202020202020202020202061a101010150606001013060406050010101010101010101010101
9111512020216030603060306060603050309151202020202061a101010101010101010101010101014120202020202020207131323131318120202101010141
20718120202101010101010101010101015040400101010191111111110220202020202020210101014050606001014050014050010101010101010101010150
6050911111a150505040504060606060503001911111111111a10101010101010150603030500101014120202020202020202020e12020202020202101010141
20202020f131b10101010101010101010101606060010101010101c1812020202020202061a10101010101304040303040015040300101010101010101010150
404040503060403050503040405030603030600101c131313131b10101010101c13131313131b1010191512020202020202020202020202020202021c1313181
202020202020713131b10101010101010101010101010101010101412020202020206111a101010101010140500101013001c1313131313131b1010130306030
303040010130606050606060c1313131323131313181202020207131b1010101412020202020214060604202202020202020202020202020206111a141202020
20202020202020202021010101010101010101010101010101010142620220202020210101010101010160303001015060014120202020202021010140015050
4050604050304060406040c181202020e120202020202020202020207131313181202020202071b101c181202020202020202020202020202071313181202020
2020202020202020207131313131313131313131313131313131318120202020f162313131313131313131313131313131318120202020202071313131313131
31313131313131313131318120202020202020202020202020202020202020202020202020202071318120202020202020202020202020202020202020202020
__label__
bbb1d1d11d11d1d11d11d1d11d11d1d11d11d122eeee8888eeee22d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1ff444444444444444444444444
b1bddd1111dddd1111dddd1111dddd1111dddd22eeee8888eeee221111dddd1111dddd1111dddd1111dddd1111dddd1111ddddf444ff444444ff444444ff4444
bdb11111dd111111dd111111dd111111dd8888eeeeee2222eeeeee8888111111dd111111dd111111dd111111dd111111dd1111ff4444444f4444444f4444444f
bdb1d1ddddd1d1ddddd1d1ddddd1d1dddd8888eeeeee2222eeeeee8888d1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d11f444444444444444444444444
bbbd1d1dd11d1d1dd11d1d1dd11d1d88888888eeee22888822eeee888888881dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1f44444f444f444f444f444f44
dd1111dddd1111dddd1111dddd111188888888eeee22888822eeee88888888dddd1111dddd1111dddd1111dddd1111dddd11111f4444f4444444f4444444f444
bbb1dbbd1bb1d11db1b1b1bd11d1bbbebbb8bbb2bb228888bb88bbb888eebbbdbbb1b1bdbbb1d11d11d1d11d11d1d11d11d1d1f4444444444f4444444f444444
b1bdbdb1b1dd1bd1b1bdbdb111dd1dbebeb8b8b28b2288882b8822b888eebeb111bdbdb1b1bd1dd111dd1dd111dd1dd111dd1d1f444444444444444444444444
bbb1b1b1bbb1d1d1bbb1bbb11d11bbb8b8b8bbb22b8822228b222bb28888bbb11db1bbb1bbb1d1d11d11d1d11d11d111ffffff1ff44444444444444444444444
b1ddbdb111bddb1111bdddb111ddbd88b8b822b22b882b228b2222b2888888b111bdddb1b1bddd1111dddd1111dddd1ff4ff44ff4444444444ff444444ff4444
bd11bb11bb111111ddb111b1db11bbbebbb288b8bbb2beeebbb8bbb88beeeeb1ddb111b1bbb11111dd111111dd11111f444444444444444f4444444f4444444f
ddd1d1ddddd1d1ddddd1d1ddddd1d1eeee2288888822eeee2288888888eeeeddddd1d1ddddd1d1ddddd1d1ddddd1d11f44444444444444444444444444444444
b1bdbbbdb11d1d1dbbbd1d1dbbbd1d1dd12222882222eeee22228822221d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1f4f444f444f4444444f444f444f444f44
bdb1b1ddbd111bddbdb111ddbdb111dddd2222882222eeee22228822221111dddd1111dddd1111dddd1111dddd1111f44444f4f44444f4444444f4444444f444
b1b1bb1db1d1d11db1b1d11db1b1d11d88eed1228822eeee2288221dee88d11d11d1d11d11d1d11d11d1d11d11d1d1f44f4444ff444444444f4444444f444444
bbbdbdd1b1dd1bd1b1bd1bd1b1bd1dd188ee1d228822eeeedeed22d1ee881dd111dd1dd111dd1dd111dd1dd111dd1dfff1ffff1ff44444444444444444444444
1b11bbb1bbb1d1d1bbb1b1d1bbb1d188ee11d1222288222deeeed2d11dee88d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1ff444444444444444444444444
11dddd1111dddd1111dddd1111dddd88eedddd22228822dedeeded1111ee881111dddd1111dddd1111dddd1111dddd1111ddddf444ff444444ff444444ff4444
bbb1bbb1dbb11111bd11bbb1dd111111dd1188eedd22eeeeeeeeee88dd111111dd111111dd111111dd111111dd111111dd1111ff4444444f4444444f4444444f
bdd1b1bdbdd1dbddbdd1b1bdddd1d1ddddd188eedd22eeeeeeeeee88ddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d11f444444444444444444444444
bb1dbbbdbbbd1d1dbbbdbdbdd11d1d1d8888ee1dd1ee1ddedeededee88881d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1f44444f444f444f444f444f44
bd11b1ddddb11bddbdb1b1bddd1111dd8888eeddddee11ddeeeed1ee888811dddd1111dddd1111dddd1111dddd1111dddd11111f4444f4444444f4444444f444
b1d1b11dbbd1d11dbbb1bbbd11d1d188eed1d11dee22d11ddeedd11d11ee881d11d1d11d11d1d11d11d1d11d11d1d11d11d1d1f4444444444f4444444f444444
11dd1dd111dd1dd111dd1dd111dd1d88eedd1dd1ee221dd122ee1dd111ee88d111dd1dd111dd1dd111dd1dd111dd1dd111dd1d1f444444444444444444444444
bbb1bbb1bbb1d1d1bbb1d1d1bbb1bbb1bdb1bbb11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1f4444444444444444444444444
bbbdbd11bbbddb11b1bddd11b1bdddb1b1bdddb111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111ddddf444ff444444ff44444f444444
bdb1bb11bdb11111bdb11111bdb111b1bbb1bbb1dd111111dd111111dd111111dd111111dd111111dd111111dd111111dd1111f44444444f444444444444f44f
bdb1b1ddbdb1dbddbdb1d1ddbdb1d1bdddb1b1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ff44444444444444444f444444
b1bdbbbdb1bd1d1dbbbd1b1dbbbd1dbdd1bdbbbdd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1f4f444f444f444f4444444444
dd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd11111f4444f4444444f4ff4444f444
1bb1bbbdb1b1d11dbbb1d11dbbb1bbbdbbb1bbbd11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11fff44f44fff4fffff4444ff4f
b1ddbdb1b1bd1bd1b1bd1dd111bd1db1b1bd1db111dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1d111ffffff11fff111f4444f1f1
bd11bbb1bdb1d1d1bbb1d1d11bb1bbb1bbb1bbb11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1f444444fd1
b1ddbd11b1bddb1111bddd1111bdbd1111bdbd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111ddddf444ff4f11
dbb1b111dbb11111ddb11b11bbb1bbb1ddb1bbb1dd111111dd111111dd111111dd111111dd111111dd111111dd111111dd111111dd111111dd1111ff44444f11
ddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1f444444fdd
d11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1df44f444f1d
dd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111f44444ffdd
11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d1f44ffff11d
11dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1dfffff111d1
1d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d1
11dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd11
dd111111dd111111dd111111dd111111dd111111dd111111dd111111dd111111dd111111dd111111dd111111dd111111dd111111dd111111dd111111dd111111
ddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1dd
d11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1d
dd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dbdd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dd
11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1debdb1d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d
11dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111ddeeebd1dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1dd1
1d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11ddedeeded11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d1
11dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111eeeeeeeedddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd11
dd111111dd111111dd111111dd111111dd111111dd111111dd111111ddeeeeeeee111111dd111111dd111111dd111111dd111111dd111111dd111111dd111111
ddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1dddddedeededb1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1dd
d11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11deeeedbbd1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1d
dd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd11deedbbb177dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dd
11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d1b7bb77d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d
11dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1db777bd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1dd1
1d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1ffff1111777bb1d1d11d11d1d11d11d1fffffffff1fff111d11d11d1d11d11d1d11d11d1d1
11dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111ddddf44fff77bbdeeddd1111dddd1111ddddf44f4f444f44fff11111dddd1111dddd1111dddd11
dd111111dd111111dd111111dd111111dd111111dd111111dd1111f44477ffbdeeeed111dd111111dd1111f4444444444444ff11dd111111dd111111dd111111
ddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d11f44444fdedeededddddd1d1ddddd1d1ff4444444444444fddddd1d1ddddd1d1ddddd1d1dd
d11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1f4f444feeeeeeee1dd11d1d1dd11d1d1f4f444f444f444f1dd11d1d1dd11d1d1dd11d1d1d
dd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111f44444ffeeeeeeeedddd1111dddd11111f4444f4444444ffdddd1111dddd1111dddd1111dd
11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d1f44f444fdedeeded1d11d1d11d11d1d1f44f4444444f44f11d11d1d11d11d1d11d11d1d11d
11dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1df444444fddeeeeddd111dd1dd111dd1df4444444f44444f1d111dd1dd111dd1dd111dd1dd1
ffff1fffffff11d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1f444f44fd1deedd1d11d11d1d11d11d1ff444444444444f1d11d11d1d11d11d1d11d11d1d1
f44ff44444fff11111dddd1111dddd1111dddd1111dddd1111dddd1f44444f1111dddd1111dddd1111ddddf444ff44444444f11111dddd1111dddd1111dddd11
4444444f4444f111dd111111dd111111dd111111dd111111dd1111ff4444ff11dd1deed1dd111111dd1111ff4444444f4444f111dd111111dd111111dd111111
444444444444f1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1f44444f1dddddeeeedddd1d1ddddd1d11f444444444444f1ddddd1d1ddddd1d1ddddd1d1dd
4f444f444f44ff1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1df444f4ff1dddedeeded11d1d1dd11d1d1f44444f444f444f1dd11d1d1dd11d1d1dd11d1d1d
4444444444444fdddd1111dddd1111dddd1111dddd1111dddd1111ff44444fdddeeeeeeeed1111dddd11111f4444f44444444fdddd1111dddd1111dddd1111dd
4fff44444fff4f1d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11f44444f1d1eeeeeeee1d1d11d11d1d1f4444444444f444f1d11d1d11d11d1d11d11d1d11d
ff1ffffff11fffd111dd1dd111dd1dd111dd1dd111dd1dd111dd1df444444fd11dedeeded1dd1dd111dd1d1f444444444444f1d111dd1dd111dd1dd111dd1dd1
1d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1f444f44fd11ddeeeed1d11d1d11d11d1ff444444444444f1d11d11d1d11d11d1d11d11d1d1
11dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1f44444f1111ddeed111dddd1111ddddf444ff44444444f11111dddd1111dddd1111dddd11
dd111111dd111111dd111111dd111111dd111111dd111111dd1111ff4444ff11dd111111dd111111dd1111ff4444444f4444f111dd111111dd111111dd111111
ddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1f44444f1ddddd1d1ddddd1d1ddddd1d11f444444444444f1ddddd1d1ddddd1d1ddddd1d1dd
d11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1df444f4ff1dd11d1d1dd11d1d1dd11d1d1f44444f444f444f1dd11d1d1dd11d1d1dd11d1d1d
dd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111ff44444fdddd1111dddd1111dddd11111f4444f44444444fdddd1111dddd1111dddd1111dd
11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11f44444f1d11d1d11d11d1d11d11d1d1f4444444444f444f1d11d1d11d11d1d11d11d1d11d
11dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1df444444fd111dd1dd111dd1dd111dd1d1f444444444444f1d111dd1dd111dd1dd111dd1dd1
1d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1f444f44fd11d11d1d11d11d1d11d11d1ff444444444444f1d11d11d1d11d11d1d11d11d1d1
11dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1f44444f1111dddd1111dddd1111ddddf444ff44444444f11111dddd1111dddd1111dddd11
dd111111dd111111dd111111dd111111dd111111dd111111dd1111ff4444ff11dd111111dd111111dd1111ff4444444f4444f111dd111111dd111111dd111111
ddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1f44444f1ddddd1d1ddddd1d1ddddd1d11f444444444444f1ddddd1d1ddddd1d1ddddd1d1dd
d11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1df444f4ff1dd11d1d1dd11d1d1dd11d1d1f44444f444f444f1dd11d1d1dd11d1d1dd11d1d1d
dd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111ff44444fdddd1111dddd1111dddd11111f4444f44444444fdddd1111dddd1111dddd1111dd
11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11f44444f1d11d1d11d11d1d11d11d1d1f4444444444f444f1d11d1d11d11d1d11d11d1d11d
11dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1df444444fd111dd1dd111dd1dd111dd1d1f444444444444f1d111dd1dd111dd1dd111dd1dd1
1d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1f444f44fd11d11d1d11d11d1d11d11d1ff444444444444f1d11d11d1d11d11d1d11d11d1d1
11dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1f44444f1111dddd1111dddd1111ddddf444ff44444444f11111dddd1111dddd1111dddd11
dd111111dd111111dd111111dd111111dd111111dd111111dd1111ff4444ff11dd111111dd111111dd1111ff4444444f4444f111dd111111dd111111dd111111
ddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1f44444f1ddddd1d1ddddd1d1ddddd1d11f444444444444f1ddddd1d1ddddd1d1ddddd1d1dd
d11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1df444f4ff1dd11d1d1dd11d1d1dd11d1d1f44444f444f444f1dd11d1d1dd11d1d1dd11d1d1d
dd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111ff44444fdddd1111dddd1111dddd11111f4444f44444444fdddd1111dddd1111dddd1111dd
11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11f44444f1d11d1d11d11d1d11d11d1d1f4444444444f444f1d11d1d11d11d1d11d11d1d11d
11dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1df444444fd111dd1dd111dd1dd111dd1d1f444444444444f1d111dd1dd111dd1dd111dd1dd1
1d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1f444f44fd11d11d1d11d11d1d11d11d1ff444444444444f1d11d11d1d11d11d1d11d11d1d1
11dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1f44444f1111dddd1111dddd1111ddddf444ff44444444f11111dddd1111dddd1111dddd11
dd111111dd111111dd111111dd111111dd111111dd111111dd1111ff4444ff11dd111111dd111111dd1111ff4444444f4444f111dd111111dd111111dd111111
ddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1f44444f1ddddd1d1ddddd1d1ddddd1d11f444444444444f1ddddd1d1ddddd1d1ddddd1d1dd
d11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1df444f4ff1dd11d1d1dd11d1d1dd11d1d1f44444f444f444f1dd11d1d1dd11d1d1dd11d1d1d
dd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111ff44444fdddd1111dddd1111dddd11111f4444f44444444fdddd1111dddd1111dddd1111dd
11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11f44444f1d11d1d11d11d1d11d11d1d1f4444444444f444f1d11d1d11d11d1d11d11d1d11d
11dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1dd111dd1df444444fd111dd1dd111dd1dd111dd1d1f444444444444f1d111dd1dd111dd1dd111dd1dd1
1d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1d11d11d1f444f44fd11d11d1d11d11d1d11d11d1ff444444444444f1d11d11d1d11d11d1d11d11d1d1
11dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1f44444f1111dddd1111dddd1111ddddf444ff44444444f11111dddd1111dddd1111dddd11
dd111111dd111111dd111111dd111111dd111111dd111111dd1111ff4444ff11dd111111dd111111dd1111ff4444444f4444f111dd111111dd111111dd111111
ddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1ddddd1d1f44444f1ddddd1d1ddddd1d1ddddd1d11f444444444444f1ddddd1d1ddddd1d1ddddd1d1dd
d11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1d1dd11d1df444f4ff1dd11d1d1dd11d1d1dd11d1d1f44444f444f444f1dd11d1d1dd11d1d1dd11d1d1d
dd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111ff44444fdddd1111dddd1111dddd11111f4444f44444444fdddd1111dddd1111dddd1111dd
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
70000000000000000000000000000000077b55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555557
70000000000000000e00000000000000077b55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555557
70000000000e00000000000000000000077b55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555557
700000000000c0000000000000000000077555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555557
700000000000000000000000000000e0077555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555557
700000000000000000000e000e000000077555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555557
7000e0000000000000e000000000e000077555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555557
700000000000000000000e0000000000077555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555557
70000000000000000ee0000000000000077555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555557
70000000000e0000e000000000000000077555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555557
70000000000000000000000000000000077555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555557
700000000000000000e0000000000000077555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555557
70000000000000000000000000000000077555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555557
70000000000000000e00000000000000077555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555557
7000000000e00000000e000000000000077555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555557
700000e00000000000000000000e00e0077555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555557
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080800000000000000000000000000000808000000000000000000000000000008080000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0202020202020202020202020216150202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202161126261111111111111111111115020202020202020202021611111111111111111111111111111111111111111115
020202020202020202020216111a19150202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202021613180202171313131b101010101019111111111111111111111a1006050310101c13131b101010100505101010101014
02020202020202020202161a10101019150202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202270202020202020202121010101010101010101010101010101005051c13131b1c18020212101010050303051010101014
16150202020202021d021210101010101915020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202021611112002020202021211111502020202021210101010101010101010101010101010041c180202171802020212101010100506061010101014
121911111111111121111a101010101010140202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202021f2210140202020202161a101c1326200202161a101010101010101010101010101006061c18020202020202021f22101010100605030303101014
12101010101010101010101010101010101402021615020202020202020202020202020202020202020216111502020202020202020202020202020202020202020202020202171b1402020202161a101c1802020202161a10101010101010101010101010100505061402020202020202020212101010101004060406040514
12101010101010101010101010101010101911111a1911111115020202020202021615020202161111111a10191115020202020202020202020202020202020202020202020202171011112626131313180202020202121010101010101010101010101010100505041402020202020202020212101010101010040405040514
121010101010101010101010101010101005101010101c13131802020202020202121915020212101010101010101911150202020202020202020202020202020202020202020202171318020202020202020202020217131b101010101010050405061c13131313131802020202020202020212101010101003030603030614
121010101010101010101010101010060506031c131318020202020202020202021204191111131b10101010101010101911150202020202020202020202020202020202020202020202020202020202020202020202020212101010101c13131313131802020202020202020202020202020212101010101004060303050314
1210101010101010101010101010101003101c180202020202020202020202020212030310140212101010101010101c13131320020202020202020202020202020202020202020202020216111115020202020202020202171b101010140202020202020202020202020202020202020202161a101010101004060304030514
12101010101010101010101010101c131b1014020202020202020202020202020212060610140217131b101c131313180202020202020202020202020202020202020202020202020216111a10101915020202021611150202171313131802020202020202020202020202020202020202021205060305061010101010101014
1204030503040610101010101010140212101402020202020202020202020216111a060410140202021210140202020202020202020202020202020202020202020202020202020202121010101c1313150202021210140202020202020202020202161111150202020202020202020202161a04030310101010101010050614
12051c131313131b10101c13132318021713180202020202020202020216111a0604041c1318020202171b14020202020202020202020202020202020202020202020202020202020212101010140202172626262210140202020202020202020202171b10191111150202020202020202120410030510100503060505030414
120314020202021713131802021e02020202020202020202020202020217131b051c1318020202020202121915020202020202020202020202020202020202020202020202020202161a101010140202020202021210140202020202020202020202021210030510242002020202020202121010101010100506040305041014
1203140202020202020202020202021d020216262620020202020202020202171b140202021d020202021713180202020202020202020202020202020202020202020202020202021713131313140202020202021210140202020202020202020202021210030405140202020202020202121010101010100605060504061014
12051402020202020202020202020212111114020202020202020202020202021219111111140202020202020202020202020202021d0202021611150202020202020202020202020202020202121111150202021210140202020202020216150202161a10100304140202020202020202121010101010101003040603041014
12051911111115020202161115020212101c1802020202020202020202020202121004040419150202020202020202020202020216211111111a10191502020202020202020202020202020202171b03191111111a1019111111150202161a1911111a0410100610191502020202020202121010101010101010100510101014
120604101010191111111a1019111113131802020202020202020202020216111a06040604041402020202020202020202020202121010101010101c180202020202020202020202020202020202171b040410101010101003051911111a10060506060305040610101911150202020202121010101010101010101010101014
121010101010101010050410100514020202020202020202020202020202120510100406030414020202020202020202021611111a10101010101c180202020202020202020202020202020202020217131b101010101010100510101006050303060404050610101010101915020216111a0404101010101010101010101014
120303051010040503041010101c180202020202020202020202161111111a1010100506040514020202020202020202161a10101010101010101402020202020202020202020202020202020202020202171b101010101006060403060406040406040306030510101010101911111a10100510101010101010101010101c18
1205030404040406101010101c1802020202020202020202021f220403030304060503050506191111111111111111111a10101010101010101014020202020202020202020202020202020202020202020212101010101004060604041010050310050403050403040510101010101010101010101010101010101c13131802
121003030610061010101010140202020202020202020202020212050410101010101010050304051010101010101010101010101010101010101402161111111115020202020202020202020202020202021210101010030504050406101010101010101010101010101010101010101010101010101010101c131802020202
1713231313131b10101010101402020202020202020202020202171b06061010101010060306031010101010101010101010101010101010101019111a10101c13180202020202020202020202020202020212101010100605050605041010101010101010101010101010101010101010101010101010101014020202020202
02021e0202021210101c13132f2002020202020202020202020202171b1010101010100604060610101010101c1313131b1010101010101010101010101c131802020202020202020202020202020202020217131b10100404040606031010101010101010101010101010101010101010101010101010101014020202020202
0202020202021713131802021e0202020202020202020202020202021210101010100505040305101010101c180202021713131b10101010101010101014020202020202020202020202020202020202020202021206040303041005101010101010101010101010101010101010101010101c1313131b101019111111111115
020202020202020202020202020202020202020202020202020202021210101010101010101010101010101402020202020202121010101c131313131318020202020202020202020202020202020202020202021206040606041010101010101010101010101010101010101010101010101402020212101010101010101014
0202020202020202020202020202020202020202020202020202020212101010101010101010101010101014020202020202021210101c1802020202020202020202020202020202020202020202021f111111111a04050404030305031010101010101010101010101010101010101010101402020212101010101010101014
0202020202020202020202020202020202020202020202020202020212101010101010101010101010101c18020202021611111a10101402020202020202020202020202020202020202020202020202171b10040606060305100406031010101010101010101010101010101010101010101402020212101010101010101014
02020202020202020202020202020202020202020202020202020202121010101010101010101010101014020202020212101010031014020202020202020202020202020202020202020202020202020217131b0504050410100506040305051010101010101010101c13131313131b10101402021f22101010101010101014
020202020202020202020202020202020202020202020202020202161a1010101010101010101010101014020202020217131b04051014020202020202020202020202020202020202020202020202020202021204060605041005040610030406101010101010101c1802020202021210101402020212101010101010101014
0202020202020202020202020202020202020202020202020202161a101010101010101010101010101019111502020202021206031c180202020202020202020202020202020202020202020202020202020212050303061010030310101c1313131b1010101010140202020202021210101402020212101010101010101014
02020202020202020202020202020202020202020202020202161a1010101010101010101010101010040606191502020202120506140202020202020202020202020202020202020202020202020202020202120610100303050405101014020202171b1010101014020202020202171313101111111a101010101010101014
__sfx__
01040000070500a0500c0500a0500305003050030500a0000a0000a00007000050000a0000c0000a0000500005000050000300000000000000000000000000000000000000000000000000000000000000000000
000100001805016050160500f0500f0500c0500c05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200000c6500a6500a6500a65007650076400563003620036100361003610036140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100003562030620000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000c0433f4151b3133f215246430c6433f4151b2130c0431b3133f5153f415246433f2151b2130c6430c0433f1151b2131b313246430c6431b3133f4150c0431b3133f2151b513246430c6433f2150c643
01100020240212403524045240452b0212b0352b0452b041270212703527045270452702527035270452704524021240352404524045330213303533045330452b0212b0352b0452b0452b0252b0352b0452b045
01100000180211803518045180451f0211f0351f0451f0411b0211b0351b0451b0451b0251b0351b0451b04518021180351804518045270212703527045270451f0211f0351f0451f0451f0251f0351f0451f045
011000002d0312d04724035240452d0312d04724035240452b0212b0252b0352b0452b0252b0252b0352b0452b0212b0252b0352b0452d0212d0252d0352d0453302133025330353304533025330253303533045
01040000053550a354073550735400355003540a35307354052000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000e5530e00313655136550e5530e50313655136050e5530e00313655136550e5530e50313655136050e5530e00313655136550e5530e50313655136050e5530e00313655136550e5530e5031365513605
01100000175501742019550194201c5501c4201e5501e4202055521555235552155520555255552655526200175521742019551194201c5511c4201e5511e4202855526555255552655528555235552155521400
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000018630166301662013620116200c6200a6200a6100761007610056100561502600116000f6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400040862302020076200202000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00001830018100183001810018300181001830018100133001310013300131001330013100133001310011300111001130011100113001110011300111001330013100133001310013300131001330013100
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00002135021350151000000023350233501c000000002535025350203001e300283502835019300003002a3502a35000300003002c3502c3502a3502a3501c3001c300283502835019300193002535225352
010e00002535225352253522535225352253522535225352253522535225352253522535225352253522535223352233522335223352233522335223352233522335223352233522335223352233522335223352
010e0000253522535225352253522535225352253522535225352253522535225352253522535225352253521700017000170001700017000170001700017000106001700010600170000c000170001700017000
010e00000d053103001240012400106751530012400124000d053103001240012400106751530012400124000d053103001240012400106751530012400124000d05310300124001240010675153001240012400
010e00000d053103001240012400106751530012400124000d053103001240012400106751530012400124000d053103001240012400106751530012400106750d0530c0030d0530c00310675153001060512400
010e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000106751700010675170000d053000000000000000
010e00001e2301e23000000000001e2301e230000000000000000000002123021230002000020021230212301e2001e2001e2301e2301e2001e3001e2301e23021230212301e2301e23023230232302523025230
010e00000000000000000000000000000000000000000000000000000000000000000000000000202302023020230202302123021230202302023021230212302323023230212302123020230202301c2301c230
010e00000613006130121301213006130061301213012130061300613012130121300613006130121301213002130021300e1300e13002130021300e1300e13002130021300e1300e13002130021300e1300e130
010e00000913009130151301513009130091301513015130091300913015130151300913009130151301513008130081301413014130081300813014130141300813008130141301413008130081301413014130
010e00000020000200000000000000000000000000000000000000000000000000000000000000000000000026230262302523025230232302323021230212302123021230232302323021230212302023020230
010e00002135021350151000000023350233501c000000002535025350203001e3002335023350193000030021350213500030000300233502335021350213501c3001c3001e3501e35019300193002135221352
010e00002135221352213522135221352213522135221352213522135221352213522135221352213522135200000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00000000000000000000000000000000000000000000000000000000000000000000000000000000000026230262302523025230232302323021230212302123021230232302323021230212301e2301e230
__music__
01 04064344
00 04064344
00 04054344
02 04074344
03 090a4344
00 16195e44
00 17194344
00 16194344
00 181a1b44
01 16191e1c
00 17191f1d
00 16191e1c
00 181a1f20
00 16191e1c
00 17191f1d
00 21191e1c
00 221a1f23
00 41191e44
00 41191f44
00 41191e44
02 41191f44

