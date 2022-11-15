pico-8 cartridge // http://www.pico-8.com
version 38
__lua__
-- castle.p8
-- by: tdjx

test={x=64,y=96,w=0.5,h=0.5}
testcol=false

function _init()
	debug={
		view_log="log",
		phys=false,
		pause=false,
		nextframe=false,
	}
	
	-- uncomment to disable debug
--	debug=nil
	
	-- 64x64 mode
	poke(0x5f2c,0)
	
	if debug then
		-- kb/mouse for debug
		poke(0x5f2d,1)
	end
	
	entities={}
	drawables={}
	solid_entities={}
	overlap_entities={}
	overlap_triggers={}
	stand_triggers={}
	attack_triggers={}
	
	for mx=0,127 do
		for my=0,31 do
			local m=mget(mx,my)
			parse_tile(m,mx,my)
		end
	end

	-- move solid entities
	-- to back
	for e in all(solid_entities)
	do
		add(entities,del(entities,e))
	end	

	-- move player behind everything
	add(entities,del(entities,pl))
	
	-- map drawables
	add(drawables,{
		z_order=-100,
		on_draw=function()
			map(0,0,0,0,16,16)
		end})
	add(drawables,{
		z_order=50,
		on_draw=function()
			map(0,0,0,0,16,16,1<<7)
		end})
	
--	_update=test_update
	_update=play_update
	_draw=play_draw
end

function test_update()
	check_keys()
	if (btn(⬅️)) test.x-=1
	if (btn(➡️)) test.x+=1
	if (btn(⬆️)) test.y-=1
	if (btn(⬇️)) test.y+=1	
	testcol=solid(
		test.x,test.y,test)
	
	local wx,wy=test.x/8,test.y/8
	local lx,ly=wx-wx\1,wy-wy\1
	local lsx,lsy=lx*8,ly*8
	watch("ls:"..lsx..","..lsy)

end

function keypress(key)
	local el=_logs.ents

	if key=="1" then
		debug.view_log="watch"
	elseif key=="2" then
		debug.view_log="log"
	elseif key=="3" then
		debug.view_log="ents"
	elseif key=="`" then
		debug.phys=not debug.phys
	elseif key=="[" then
		debug.pause=not debug.pause
	elseif key=="]" and debug.pause then
		debug.nextframe=true
		clear_frame_logs()
	elseif key=="h" then
		el.right=false
	elseif key=="l" then
		el.right=true
	elseif key=="j" then
		el.sel+=1
		if (el.sel>el.len) el.sel=el.len
		if (el.sel>el.view+20) el.view=el.sel-20
	elseif key=="k" then
		el.sel-=1
		if (el.sel<1) el.sel=1
		el.view=min(el.view,el.sel)
	end
end

function parse_tile(░,x,y)
	local sx,sy=w2s(x,y)
	if ░==8 then
		pl=make_player(sx+4,sy+5)
		mset(x,y,0)
	elseif ░==48 then
		make_spring_bud(sx+4,sy+4)
		mset(x,y,0)
	elseif ░==32 then
		make_spring(sx+4,sy+4)
		mset(x,y,0)
	elseif ░==36 then
		parse_platform(░,x,y)
	elseif ░==16 then
		make_spikes(sx+4,sy+4)
		mset(x,y,0)
	elseif ░==40 then
		make_skeleton(sx+4,sy+4)
		mset(x,y,0)
	end
end

function parse_platform(░,x,y,opt)
	local sx,sy=w2s(x,y)
	local l,r=x,x
	local i=1
	while mget(l-i,y)==░ do
		i+=1
		l-=1
	end
	while mget(l+i,y)==░ do
		i+=1
 	r+=1
	end
	
	local is_elevator=
	(fget(mget(l-1,y))&0xf)~=0
		and (fget(mget(r+1,y))&0xf)~=0

	for mx=l,r do
		mset(mx,y,0)
	end
	
	local lx=l*8+4
	local rx=r*8+4
	local px=(lx+rx)/2
	local w=(r-l+1)*4
	local plat=
		is_elevator and make_elevator(px,sy+2,w,░)
	 or	make_platform(px,sy+2,w,░)
	tblcpy(plat,opt or {})
end

function check_keys()
	while stat(30) do
		keypress(stat(31))
	end
end

function play_update()
	check_keys()
	
	if debug and debug.pause then
		if debug.nextframe then
			debug.nextframe=false
		else
			return
		end
	end
	
	sort(entities,
		function(e1,e2)
			return e1.order<e2.order
				or e1.order==e2.order
							and e1.id<e2.id
		end,1)

	if (pl) proc_input(pl)
	foreach(entities,
		function(e) e:on_update() end)
		
	for e in all(overlap_entities)
	do
		for t in all(overlap_triggers)
		do
			if t.overlap_⧗<=0
				and aabb(e,t)
			then
				t:on_trigger(e)
			end
		end
	end
	
	if btnp(❎) then
		for t in all(attack_triggers)
		do
			t:on_trigger(e)
		end
	end

	watch(tostr(stat(0)/204.8).."%")
	watch(tostr(stat(1)*100).."%")
	watch(tostr(stat(2)*100).."%")

	local obs=skel
	if obs then
		watch("pos:"..obs.x..","..obs.y)
		watch("vel:"..obs.dx..","..obs.dy)
		watch("af:"..obs.frame)
		watch("am:"..obs.anim_mode)
		watch("se:"..tostr(obs.stand_entity))
		if obs.stand_entity then
			watch("sex:"..obs.stand_entity.x)
			watch("sey:"..obs.stand_entity.y)
		end
	end

	for i,e in ipairs(entities) do
		logent(e)
	end
end

function play_draw()
	cls()
	
	camera(pl.x\128*128,pl.y\128*128)
	
--	map(0,0,0,0,16,16)
	
	sort(drawables,function(e1,e2) return e1.z_order<e2.z_order end)
	foreach(drawables,
		function(e) 
		e:on_draw()
		 end)
		
	if debug and debug.phys then
		foreach(entities,function(e)
			pset(e.x,e.y,10)
			rect(e.x-e.w,e.y-e.h,
				e.x+e.w-1,e.y+e.h-1,12)
		end)
	end


--	pset(test.x,test.y,testcol and 8 or 11)
--	map(0,0,0,0,16,16,1<<7)
	camera()
	
	if debug then
		draw_log(debug.view_log)
		if not debug.pause then
			clear_frame_logs()
		end
	end
	pal(0,129,1)
end
-->8
-- utilities

function tblcpy(src,dst)
	dst=dst or {}
	for k,v in pairs(src) do
		dst[k]=v
	end
	return dst
end

function addrange(a,r)
	for v in all(r) do
		add(a,v)
	end
	return a
end

function sort(a,cmp,limit)
	cmp=cmp or function(a,b)return a<b end		
	local n=#a
	local swaps=0
	for i=2,n do
		local j=i
		while 
			j>1 and cmp(a[j],a[j-1])
			and (limit==nil or swaps<limit)
		do
			local tmp=a[j]
			a[j]=a[j-1]
			a[j-1]=tmp
			j-=1
			swaps+=1
		end
	end
end


function aabb(t1,t2)
	return t1.x+t1.w>=t2.x-t2.w
		and t1.x-t1.w<=t2.x+t2.w
		and t1.y+t1.w>=t2.y-t2.w
		and t1.y-t1.w<=t2.y+t2.w
end

function make_flag_enum(...)
	local enum={}
	for i,f in ipairs({...}) do
		enum[f]=0x0000.0001<<i-1
	end
	return enum
end

function make_flags(enum,...)
	local flags=0
	for i,f in ipairs({...}) do
		flags=flags|enum[f]
	end
	return flags
end

function sgn3(v)
	if (v==0) return 0
	return sgn(v)
end

-- world to screen
function w2s(x,y)
	return x*8,y*8
end

function s2w(x,y)
	return x/8,y/8
end

-- algebra
function len2(x,y)
	return x*x+y*y
end

function len(x,y)
	return sqrt(x*x+y*y)
end

function norm(x,y)
	local l=len(x,y)
	if (l==0) return 0,0
	return x/l,y/l
end

-- width of string
function strw(s)
	-- todo handle special chars
	return #s*4
end

-- logging
_logs={
	watch={log={},col=7},
	log={log={},col=6},
	ents={
		log={},
		col=10,
		bg=1,
		right=false,
		view=1,
		sel=1,
		selcol=12,
		len=0,
		},
}

function add_log(log,msg,col)
	add(log.log,{
		msg=msg or "",
		col=col or log.col
	})
end

function log(msg,col)
	add_log(_logs.log,msg,col)
	if #_logs.log.log>16 then
		deli(_logs.log.log,1)
	end
end

function watch(msg,col)
	add_log(_logs.watch,msg,col)
end

function logent(e,col)
	local msg=e.id..":"..e.name
	add_log(_logs.ents,msg,col)
end

function clear_frame_logs()
	_logs.watch.log={}
	_logs.ents.log={}
end

function draw_log(name)
	local lg=_logs[name]
	assert(lg~=nil)
	
	local bg=lg.bg
	

	local left,right=0,0
	if bg~=nil then
		local sw=0
		local n=0
		local ct=0
		for i,l in ipairs(lg.log) do
			local lsw=strw(l.msg)
			if (lsw>sw) sw=lsw
			n=i
		end
		
		right=sw
		
		if lg.right then
			right=127
			left=127-sw
		end
		
		rectfill(left,0,right,n*6,bg)
	end

	for i,l in ipairs(lg.log) do
		local view=lg.view or 1
		if lg.view and i<lg.view
		then
		else
			local y=(i-1)*6-(view-1)*6
	
			local mc=l.col
			if lg.sel and lg.sel==i
			then
				mc=9
				rectfill(left,y,right,y+6,2)
			end

			print(l.msg,left+1,y+1,mc)
		end
		lg.len=i
	end
end

function rottspr(x,y,rot,mx,my,w,flip,scale)
	scale=scale or 1
	w+=.8
	local halfw=scale*-w/2
	local cx=mx+w/2-.4
	local cs=cos(rot)/scale
	local ss=-sin(rot)/scale
	local cy=my-halfw/scale-.4
	local sx=cx+cs*halfw
	local sy=cy-ss*halfw
	local hx=w*(flip and -4 or 4)*scale
	local hy=w*4*scale
	
--	rect(x-hx,y-hy,x+hx,y+hy,5)
	
	for py=y-hy,y+hy do
		tline(x-hx,py,x+hx,py,
			sx+ss*halfw,sy+cs*halfw,
			cs/8,-ss/8)
		halfw+=1/8
	end
end

-->8
-- entities

entity={order=0}
entity.__index=entity

next_ent_id=1
function make_entity(params)
	local id=next_ent_id
	next_ent_id+=1

	local e={
		id=id,
		name="default",
		⧗=0,						-- frames active
		x=0,y=0,			-- position
		dx=0,dy=0,	-- velocity
		fdx=0,fdy=0, -- frame velocity, resets every frame, use to nudge
		ix=1,iy=1, -- inv friction
		physdx=0,		-- additional delta
		physdy=0,		-- added by collision resolution
		w=4,h=4,			-- half extents
		g=0,							-- gravity
		hp=1,   			-- health
		life_⧗=0,
		air_⧗=0,
		z_order=0,

		-- flags
		visible=true,
		collide=false,
		in_air=false,
		
		
		-- sprite
		facing=1,
		sw=8,sh=8,	 -- screen dim
		tw=1,th=1,	 -- tile dim
		
		-- animation
		frame=1,
		frames={1},
		fs=4,
		fc=0,
		fblend=0,
		fprio=0,
		-- valid modes
		--		pause, stay on current frame
		--		play, play anim normally
		--  loop, play normally and loop
		--		blend, set frame based on fblend (0-1)
		anim_mode="pause",
		
		on_draw=entity_draw,
		on_update=entity_update,
		on_air=function()end,
		on_land=function()end,
		on_hit_ceiling=function()end,
		on_hit_wall=function()end,
		on_fall=function()end,
		contains=entity_contains,
	
	}
	setmetatable(e,entity)
	tblcpy(params,e)
	add(drawables,e)
	return add(entities,e)
end

function set_anim(e,frames,mode,prio)
	prio=prio or 0
	if (e.frames==frames and e.anim_mode~="stop") return
	if (prio < e.fprio) return
	e.fprio=prio or 0
	e.frames=frames
	e.frame=1
	e.fc=0
	e.fs=4
	e.anim_mode=mode or "play"
	e.on_anim_stop=nil
end

function entity_draw(e)
	if (not e.visible) return
	
	spr(e.frames[e.frame],
		e.x-e.sw/2,
		e.y-e.sh/2,
		e.tw,e.th,
		e.facing==-1)
end

function entity_move_x(e)
	e.x+=e.dx+e.fdx
	e.dx*=e.ix
	e.fdx=0
end

function entity_move_y(e)
	if e.in_air or not e.collide
	then
		e.y+=e.dy+e.fdy
		e.dy=min(4,e.dy+e.g)
		e.dy*=e.iy
	else
		e.y+=e.fdy
	end
	e.fdy=0
end

function entity_update(e)
	e.⧗+=1
	
	if e.life_⧗>0
		and e.⧗>=e.life_⧗
	then
		destroy_entity(e)
	end
	
	-- last values
	e.ldx=e.dx
	e.ldy=e.dy
	e.lx2=e.lx
	e.ly2=e.ly
	e.lx=e.x
	e.ly=e.y
		
	entity_move_x(e)
	
	-- horizontal collision
	if e.collide then
		local hit,side=phys_side(e)
		if hit then
			e:on_hit_wall(side)
		end
	end

	entity_move_y(e)
	
	local flag=0
	if e.standing_entity then
		flag=1
	end
	
	if e.collide then
		e.physdy=0
		local ly=e.y
		if phys_floor(e) then
			if e.in_air then
				e:on_land()
			end
			e.in_air=false
		else
			if flag~=0 and e.name=="player" then
			asdf=asdf or 1
			log(e.name.." " ..asdf)
			asdf+=1
			end
			e.stand_entity=nil
			if not e.in_air and e.dy==0
			then
				if should_fall(e) then
					if not e.in_air then
						e:on_fall()
						e:on_air()
					end
					e.in_air=true
				end
			else
				if not e.in_air then
					e:on_air()
				end
				e.in_air=true
			end
		end
		if phys_roof(e) then
			e:on_hit_ceiling()
		end
		e.physdy=e.y-ly
	end
	
	if e.in_air then
		e.air_⧗+=1
	else
		e.air_⧗=0
	end
	
	-- update animation
	if e.anim_mode=="play"
		or e.anim_mode=="loop"
	then
  e.fc+=1
  
  if e.fc==e.fs then
	  e.fc=0
	  e.frame+=1
	  if e.frame>#e.frames then
	   if e.anim_mode=="loop" then
	    e.frame=1
	   else
	    e.frame=#e.frames
	    e.fprio=0
	    e.anim_mode="stop"
	    if e.on_anim_stop then
	    	e:on_anim_stop()
	    	e.on_anim_stop=nil
	    end
	   end
	  end
	 end
 elseif e.anim_mode=="blend" then
 	local nf=#e.frames
 	local b=mid(e.fblend,0,1-0x0000.0001)
 	e.frame=flr(nf*b)+1
 end
end

function destroy_entity(e)
	del(entities,e)
	del(drawables,e)
	del(solid_entities,e)
	del(overlap_entities,e)
	del(overlap_triggers,e)
	del(stand_triggers,e)
	del(attack_triggers,e)
end

function entity_contains(e,x,y)
	return x>=e.x-e.w and
		x<=e.x+e.w and
		y>=e.y-e.h and
		y<=e.y+e.h
end

function make_entity_solid(e)
	e.order=1000
	add(solid_entities,e)
end

-->8
-- player

pl_anim_idle={8}
pl_anim_walk={8,9}
pl_anim_air={12,13,14,15}
pl_anim_land={10}
pl_anim_land_hard={10,11}
pl_anim_die={24,25,26,27,28,29,30,0}

function make_player(px,py)
	pl_g=0.35
	pl_jumpf=3

	local e=make_entity({
		name="player",
		order=10000,
		collide=true,
		x=px,y=py,
		g=pl_g,
		ix=0,
		w=3,
		h=3.8,
		jump_⧗=0,
		charge_⧗=0,
		canjump=false,
		physent=true,
		dead=false,
		stand_entity=nil,
		on_update=player_update,
		on_air=player_on_air,
		on_land=player_on_land,
	})
	
	add(overlap_entities,e)
	return e
end

function proc_input(e)
	if (e.dead) return

	local inx,iny=0,0
	if (btn(⬅️)) inx-=1
	if (btn(➡️)) inx+=1
	if (btn(⬆️)) iny-=1
	if (btn(⬇️)) iny+=1
	
	if btn(❎) then
		e.charge_⧗+=1
	else
		if e.charge_⧗>15 then
			make_spore_blast(e.x,e.y-4,e.facing)
		end
		e.charge_⧗=0
	end
		
	if inx~=0 then
		e.dx+=inx
		e.facing=sgn(inx)
	end
	
	if not e.in_air then
		if inx~=0 then
			set_anim(e,pl_anim_walk,"loop")
		else
			set_anim(e,pl_anim_idle)
		end
	end
	
	if not btn(🅾️) then
		e.canjump=true
	end
	
	if e.canjump and btnp(🅾️)
	then
		if e.air_⧗<5 then
			jump(e)
			e.air_⧗=5
		end
	end
end

function jump(e)
	e.jump_⧗=5
	e.dy=-pl_jumpf
	e.in_air=true
	e.canjump=false
	set_anim(e,pl_anim_air,"blend",1)
end

function kill(e)
	e.dead=true
	e.ix,e.iy,e.dx,e.dy=0,0,0,0
	e.physent=false
	del(overlap_entities,e)
	set_anim(e,pl_anim_die,"play",1000)
end

function entity_stand_entity_move(e)
	if e.stand_entity then
		e.fdx+=e.stand_entity.mdx
		e.fdy+=e.stand_entity.mdy
	end
end

function player_update(e)
	if debug.pause then
		log("player_update "..t())
	end

	entity_stand_entity_move(e)

	entity_update(e)
	
	if e.in_air then
		local a,b=-2,1
		local t=(e.dy-a)/(b-a)
		e.fblend=t
	end
end

function player_on_air(e)
	set_anim(e,pl_anim_air,"blend",1)
end

function player_on_land(e)
	local a=pl_anim_land
	if (e.ldy>3) a=pl_anim_land_hard
	set_anim(e,a,"play",1)
end

function make_spore_blast(x,y,face)
	local e=make_entity({
		x=x,y=y,tw=2,th=2,
		sw=16,sh=16,
		facing=face,
--		dx=5*sgn(face),ix=0.9,
--		dy=3,iy=0.75,
		z_order=100,
		p_limit=18,
		p_count=2,
		p_interval=0,
		p_⧗=0,
		particles={},
		on_update=spore_blast_update,
		on_draw=spore_blast_draw,
	})
--	set_anim(e,
--		{128,130,132,134,136,138,140,142})
--	e.fs=2
	return e
end

function spore_blast_update(e)
	entity_update(e)
	
	e.p_⧗-=1
	if e.p_⧗<=0 then
		local i=0
		while i<e.p_count and e.p_limit>0 do
			i+=1
			e.p_⧗=e.p_interval
			e.p_limit-=1
			local a=rnd(0.3)+0.1
			local fx=cos(a)*2.5+rnd()
			local fy=sin(a)*2.5+rnd()
			add(e.particles,
				{x=e.x,y=e.y,
					dx=e.dx+fx,dy=e.dy+fy,
					ddx=0,ddy=0.04,
					ix=0.85,iy=0.95,
					⧗=0,life_⧗=120})
		end
	end
	
	for p in all(e.particles) do
		p.⧗+=1
		p.dx+=p.ddx
		p.dy+=p.ddy
		p.x+=p.dx
		p.y+=p.dy

		if map_solid(p.x+p.dx+2,p.y)
		then
			p.dx*=-0.9
		end
		
		if map_solid(p.x,p.y+p.dy+2)
		then
			p.dy*=-0.9
		end
		
		--[[local dyacc=0
		
		local ldx=p.dx
		while map_solid(p.x+p.dx,p.y)
			and abs(p.dx)>0
		do
			if (p.dx>0) p.dx=max(p.dx-1,0)
			if (p.dx<0) p.dx=min(p.dx+1,0)
			dyacc+=1
		end
		
		if (dyacc>0) p.dx=-ldx
		
--		p.dy+=sgn3(p.dy)*dyacc

		while map_solid(p.x,p.y+p.dy+sgn3(p.dy)*3)
			and abs(p.dy)>0
		do
			if (p.dy>0) p.dy=max(p.dy-1,0)
			if (p.dy<0) p.dy=min(p.dy+1,0)
		end]]
		
		p.dx*=p.ix
		p.dy*=p.iy
		
		if (p.⧗>30) p.ddy=0
		if (p.⧗>=p.life_⧗-10) p.ddy=0.1
		
		if p.⧗>=p.life_⧗ then
			del(e.particles,p)
		end
	end
	
	if e.p_limit<=0 and #e.particles==0 then
		destroy_entity(e)
	end
end

function spore_blast_draw(e)
	local nt=function(p)
		local val=0
		local hl=p.life_⧗/2
		if p.⧗>=hl then
			val=(p.⧗-hl)/hl/2
		end
		return val
	end
	
	watch(nt({⧗=0,life_⧗=120}))
	watch(nt({⧗=60,life_⧗=120}))
	watch(nt({⧗=90,life_⧗=120}))
	watch(nt({⧗=119,life_⧗=120}))
	
	for p in all(e.particles) do
		circfill(p.x,p.y,2+cos(nt(p))*3,2)
	end
	
	for p in all(e.particles) do
		circfill(p.x,p.y,2+cos(nt(p))*2,14)
	end
end
-->8
-- environment

function make_enviro_entity(param)
	local e=make_entity({
		ix=0,iy=0,
		collide=false,
		overlap_⧗=0,
		on_update=enviro_update,
		on_trigger=function()end,
	})
	tblcpy(param or {},e)
	return e
end

function enviro_update(e)
	entity_update(e)
	if (e.overlap_⧗>0) e.overlap_⧗-=1
end

-- spring bud
function make_spring_bud(x,y)
	local e=make_enviro_entity({
		name="bud_"..tostr(x)
			.."_"..tostr(y),
		x=x,y=y,
		w=1,
		on_update=bud_update,
		on_trigger=bud_trigger,
	})
	
	set_anim(e,{48})
	add(attack_triggers,e)
	
	return e
end

function bud_update(e)
	enviro_update(e)
	
	if e.grow_⧗~=nil then
		e.grow_⧗-=1
		if e.grow_⧗<=0 then
			make_spring(e.x,e.y,1)
			destroy_entity(e)
		end
	end
end

function bud_trigger(e)
	if (e.grow_⧗) return
	set_anim(e,{49,50})
	e.grow_⧗=10
end

-- spring
function make_spring(x,y,bounces)
	local e=make_enviro_entity({
		name="spring_"..tostr(x)
			.."_"..tostr(y),
		x=x,y=y,
		w=1,
		bounces=bounces,
		on_trigger=spring_trigger,
		on_draw=spring_draw
	})
	
	set_anim(e,{32})
	add(overlap_triggers,e)

	return e
end

function spring_trigger(e,src)
	if src.dy>0 then
		set_anim(e,{33,33,34,32})
		e.fs=2
		src.dy=-4
		e.overlap_⧗=5
		if e.bounces~=nil then
		 e.bounces-=1
		 if e.bounces<=0 then
		 	set_anim(e,{50,49,28})
		 	e.on_anim_stop=function(e)
		 		make_spring_bud(e.x,e.y)
		 		destroy_entity(e)
		 	end
		 end
		end
	end
end

function spring_draw(e)
	if not e.bounces then
		pal(8,11)
		pal(2,3)
		pal(13,2)
	end
	entity_draw(e)
	pal()
end

-- platforms
function make_platform(x,y,w,░)
	local mx,my=x\8,y\8
	local l,r=nil,nil

	local i=1
	while (l==nil or r==nil) and i<127 do
		local lf=fget(mget(mx-i,my))&0xf
		local rf=fget(mget(mx+i,my))&0xf
		if (l==nil and lf~=0) l=mx-i
		if (r==nil and rf~=0) r=mx+i
		i+=1
	end

	local leftx,rightx=0,119
	if (l~=nil) leftx=l*8+w+8
	if (r~=nil) rightx=r*8-w
	
	local e=make_entity({
			name="platform",
			x=x,y=y,
			leftx=leftx,
			rightx=rightx,
			dx=1,dy=0,
			wait_⧗=0,
			ix=1,iy=1,
			mdx=0,mdy=0,
			g=0,
			w=w or 4,
			h=2,
			sh=4,
			░=░,
			on_update=platform_update,
			on_draw=platform_draw,
		})
	tblcpy(opt or {},e)
	make_entity_solid(e)
	pf=e
	return e
end

function platform_update(e)
	if e.wait_⧗>0 then
		e.wait_⧗-=1
	else
		if e.nextdx then
			e.dx=e.nextdx
			e.nextdx=nil
		end
	end
	entity_update(e)
	e.mdx=e.x-e.lx
	
	if e.dx>0 then
		if e.x>=e.rightx then
			e.x=e.rightx
			change_dir(e)
		end
	elseif e.dx<0 then
		if e.x<=e.leftx then
			e.x=e.leftx
			change_dir(e)
		end
	end
end

function platform_draw(e)
--	rectfill(e.x-e.w,e.y-e.h,
--		e.x+e.w-1,e.y+e.h-1,9)
--	entity_draw(e)

	local sx1=e.x-e.w
	local sx2=e.x+e.w-e.sw
	for sx=sx1,sx2,e.sw do
		local sp=e.░
		if sx1==sx2 then
			sp+=1
		elseif sx==sx1 or sx==sx2 then
			sp-=1
		end
		spr(sp,sx,e.y-e.h,1,1,sx==sx2)
	end
end

function make_elevator(x,y,w,░)
	local mx,my=x\8,y\8
	local b=my
	
	repeat
		b+=1
	until mget(mx,b)==38
	
	local topy=y
	local boty=b*8+(y-y\8*8)
	
	local e=make_entity({
			name="elevator",
			collide=false,
			x=x,y=y,
			dx=0,dy=1,
			topy=topy,
			boty=boty,
			nextdy=nil,
			wait_⧗=0,
			ix=1,iy=1,
			mdx=0,mdy=0,
			g=0,
			w=w or 4,
			h=2,
			sh=4,
			░=░,
			on_update=elevator_update,
			on_draw=platform_draw,
		})
	tblcpy(opt or {},e)
	make_entity_solid(e)
	pf=e
	return e
end

function change_dir(e)
	e.nextdx=-e.dx
	e.nextdy=-e.dy
	e.dy=0
	e.dx=0
	e.wait_⧗=60
end

function elevator_update(e)
	if debug.pause then
		log("elevator_update")
	end

	if e.wait_⧗>0 then
		e.wait_⧗-=1
	else
		if e.nextdy then
			e.dy=e.nextdy
			e.nextdy=nil
		end
	end
	entity_update(e)
	e.mdy=e.y-e.ly

	if e.dy>0 then
		if e.y>=e.boty then
			e.y=e.boty
			change_dir(e)
		end
	elseif e.dy<0 then
		if e.y<=e.topy then
			e.y=e.topy
			change_dir(e)
		end
	end		
end

flash_min⧗=240
flash_max⧗=720

function rnd_flash⧗()
	return rnd(flash_max⧗-flash_min⧗)\1
		+flash_min⧗
end

function make_spikes(x,y)
	local flash⧗=rnd_flash⧗()
	local e=make_enviro_entity({
		name="spike",
		x=x,y=y,
		flash⧗=flash⧗,
		⧗=rnd(flash⧗)\1,
		on_trigger=spike_trigger,
		on_update=spike_update,
	})
	set_anim(e,{16})
	add(overlap_triggers,e)
	spike=e
	return e
end

spike_shine_anim={
	16,76,77,78,79,16
}
spike_shine_flash_anim=
	addrange(addrange({},spike_shine_anim),
		{92,93,94,95,16})
	
function spike_shine(e,extra)
	local anim=extra 
		and spike_shine_flash_anim
		or spike_shine_anim
	set_anim(e,anim)
	e.fs=4
end

function spike_update(e)
	entity_update(e)
	if e.⧗%e.flash⧗==0 then
		spike_shine(e,rnd()<0.2)
	end
end

function spike_trigger(e,src)
	kill(src)
end
-->8
-- physics

function map_solid(x,y)
	local wx=x/8
	local wy=y/8
	local lx=wx-flr(wx)
	local ly=wy-flr(wy)
	local m=mget(wx,wy)

	local q=0
	if lx<0.5 then
		q=ly<0.5 and 0 or 2
	else
		q=ly<0.5 and 1 or 3
	end

	return fget(m,q)
end

function entity_solid(x,y,ignore,info)
	for _,e in ipairs(solid_entities)
	do
		if e~=ignore
			and e:contains(x,y)
		then
			if type(info)=="table" then
				info.entity=e
			end
			return true
		end
	end
end

function solid(x,y,e,info)
	return	entity_solid(x,y,e,info)
		or map_solid(x,y)
end

function should_fall(e)
	if (e.in_air) return true
	
	local air=true
	for i=-e.w,e.w-1 do
		local ty=e.y+e.h+1
		if solid(e.x+i,ty,e) then
			air=false
		end
	end
	
	return air
end

function phys_side(e)
	local top,bot=-e.h,e.h-1
	e.physdx=0
	
	if e.dx>=0 then
		for i=top,bot do
			if map_solid(e.x+e.w,e.y+i) then
				e.dx=0
				local lx=e.x
				e.x=(e.x+e.w)\4*4-e.w
				e.physdx=e.x-lx
				return true,1
			end
		end
	end
	
	if e.dx<=0 then
		for i=top,bot do
			if map_solid(e.x-e.w,e.y+i) then
				e.dx=0
				local lx=e.x
				e.x=(e.x-e.w)\4*4+4+e.w
				e.physdx=e.x-lx
				return true,-1
			end
		end
	end
	
	return false
end

function phys_floor(e)
	if (e.dy<0) return false
	
	local landed=false
	local yover=nil
	local info={}
	
	local standing=nil
	local mct,ect=0,0
	for i=-e.w,e.w-1 do
		local ty=e.y+e.h
		local hit=false
		info.entity=nil
		hit,yover=
			solid(e.x+i,ty,e,info)
		if hit then
			landed=true
			if info.entity then
				standing=info.entity
				ect+=1
			else
				mct+=1
			end
		end
	end
	
	if ect>=mct then
		e.stand_entity=standing
	else
		e.stand_entity=nil
	end

	local se=e.stand_entity
	if landed then
		e.dy=0
		if se then
			e.y=se.y-se.h-e.h
		elseif yover~=nil then
			watch("yover:"..yover)
		else
			e.y=(e.y+e.h)\4*4-e.h
		end
	end
	
	return landed
end

function phys_roof(e)
	local collided=false
	local info={}
	for i=-e.w,e.w-1 do
		if map_solid(e.x+i,e.y-e.h) then
			e.dy=0
			collided=true
			if info.entity then
				e.y=info.entity.y+
					info.entity.h+e.h+1
				break
			else
				e.y=(e.y-e.h)\4*4+4+e.h
			end		
		end
	end
	return collided
end
-->8
-- enemies

function make_enemy(x,y,opt)
	opt=opt or {}
	opt.x=x
	opt.y=y
	opt.order=5000
	local e=make_entity(opt)
	return e
end

function make_skeleton(x,y)
	local e=make_enemy(x,y,{
		name="skeleton",
		collide=true,
		g=pl_g,
		w=3,
		on_update=skeleton_update,
	})
	skel=e
	set_anim(e,{40})
end

function skeleton_update(e)
	e.dx=e.facing*0.125
	entity_stand_entity_move(e)
	entity_update(e)
end
__gfx__
00000000888888880000000000000000000000000000000000000000000000000088780000000000000000000000000000888e00008878000088780007887880
000000008ee8eee8000000000000000000000000000000000000000000000000087888700088780000000000000000000088870008788870087888708fffff87
000000008e88e8e800000000000000000000000000000000000000000000000078ffff880878887000000000000000000e88888008ffff8078ffff88fffddfff
000000008ee8ee880000000000000000000000000000000000000000000000008fddddf878ffff880000000000000000078888e00fdcdcf08fddddf80dddddd0
000000008e88e8e8000000000000000000000000000000000000000000000000fddcdcdf8fddddf8008878000000000000de8d7000dddd000ddcdcd00dddddd0
000000008ee8e8e80000000000000000000000000000000000000000000000000dddddd0fddcdcdf887888780787888000d7dd0000dddd000dddddd00ddcdcd0
00000000888888880000000000000000000000000000000000000000000000000dddddd00dddddd07ddcdcd88888878700dddd0000dddd0000dddd000dddddd0
00000000888888880000000000000000000000000000000000000000000000000dddddd0dddddddddddddddd8dcdcdd800dddd0000dddd000000000000dddd00
00000000124122140000000000000000000000000000000000000000000000000087880000000000000000000000000000000000000000000000000000000000
004040402212224200000000000000000000000000000000000000000000000007888d2000878800002200000000000000000000000000000000000000000000
404004402112121100000000000000000000000000000000000000000000000088ffd22807828d20072200200000000000000000000000000000000000000000
04040400121221120000000000000000000000000000000000000000000000008fddddd888ff222888f222200200000000000000000000000000000000000000
0244004021211122000000000000000000000000000000000000000000000000fddddddf8fdd2d288fdd2d220220000000000000000000000000000000000000
04242444221122120000000000000000000000000000000000000000000000000dcddcd0fddddd2ffd5dd2220f20202002000000000000000000000000000000
24224220112121110000000000000000000000000000000000000000000000000dddddd00dcddcd0051551502520222202200200000000000000000000000000
22442242212212220000000000000000000000000000000000000000000000000dddddd0dd5dd5dddd5dd5ddd552d5d522220222020200200000000000000000
00000000000000000088880066666666666666666666666633333333555555550077777700000000000000000000000000000000000000000000000000000000
00088800000000000087880061999999999999996199991632222223522222250067577500777777000000000000000000000000000000000000000000000000
008787800000000008878780061999999999999906199160b122221bb122221b0067777700675775000000000000000000000000000000000000000000000000
088888880000880008888780006666666666666600666600b311113bb311113b0676777706677777000000000000000000000000000000000000000000000000
08788228008878800778d280000000000000000000000000b333333bb333333b0766757007767777000000000000000000000000000000000000000000000000
8882222088722878082dd22000000000000000000000000013333331133333310776600007667570000000000000000000000000000000000000000000000000
0822d000822dd228002dd20000000000000000000000000012222221122222210667660006676600000000000000000000000000000000000000000000000000
000dd00000dddd00000dd00000000000000000000000000011111111111111110770770077000770000000000000000000000000000000000000000000000000
00000000000780000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008780000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008887000088880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007887800887877000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000087d28800888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000082dd2808778d28800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00022000002dd200882dd22000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002dd200000dd000000dd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbb00000000bbbb000000000000000000000000000000000b1b3b300000000000000000000000000000000000000000000000000000000000000000
b333333b13310000000013310000000000000000000000000000000000b13100004040400040404000f040400040f0f00040404000f0404000f0f0400040f0f0
b333333b122100000000122100000000000000000000000000000000000b30004040044040400440f0f00440404004f040400440f0f00440f0f00f4040400440
b333333b1111000000001111000000000000000000000000000000000003b000040404000f0404000f0f0f0004040400040404000f0f0f000f0f0f0004040400
b333333b1110000000000111bbbb00000000bbbb000000000000000000031b000244004002ff0040024f00f0024400400244004002ff00f002ff00f002440040
1333333111000000000000111331000000001331000000000000000000033b00042424440f2f2ff4042424ff04242444042424440f2f2fff042f2fff0424244f
12222221100000000000000112210000000012210000000000000000003bb1002f2242202422f22024224220242242202f2242202422f2202422422024224220
1111111100000000000000001111000000001111000000000000000003b133b022ff22f2224422f2224422422244224222ff22f2224422f22244224222442242
0000bbbbbbbbbbbb00000000bbbb00000000bbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000013311333333100000000b33b00000000b33b00000000000000000000000000f0f0f000f0f0f0004040f00040404000f0f0f000f0f0f0004040f000404040
000112211222222100000000b33b00000000b33b000000000000000000000000f0f00ff0f0400940f040044040400440f0f00ff0f0400940f040044040400440
001111111111111100000000b33b00000000b33b0000000000000000000000000f0f0f000909090004090900040404000f0f0f00090909000409090004040400
bbbb111000000000bbbbbbbbb33b00000000b33b00000000000000000000000002ff00f00299009002990090024900400eff00f0029900900299009002490040
13311100000000001333333113310000000013310000000000000000000000000f2f2fff092929940429294f042929440fefefff092929940429294f04292944
12211000000000001222222112210000000012210000000000000000000000002f22f220242242202422922024229220efeefee0242242202422922024229220
111100000000000011111111111100000000111100000000000000000000000022ff22f222ff22f222f422f222442242eeffeefe22ff22f222f422f222442242
bbbb00000000bbbbbbbb0000bbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
133100000000b33bb33b0000b333333bb333333b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
122110000000b33bb33b0000b333333bb333333b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111111000000b33bb33b0000bbbbb33bb33bbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0111bbbbbbbbb33bb33bbbbb0111b33bb33b11100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111331133333311333333100111331133111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011221122222211222222100011221122110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001111111111111111111100001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddd0000000000000d000
000000000000000000000000000000000000000000000000000000000000d0000000000000ddd0000000000000ddd00000000000000deded000000000000d000
00000000000000000000000000000000000000000000e0000000000000deed000000000000deedd00000000000ddedd0000000000000ded00000000000000000
00000000000000000000000dddded000000000ed00deed000000000d0ddeeed000000dddd0deeed000000000d0ddeed000000000000ddddd0000000000000000
00000de00000000000000ddeeeeeee000000ddeeeeeeeee000000eeeeeddeed000000ddedddddddd0000000ddddddddd000000000000dddd00000000000000d0
000de0d0e0000000000dedeeeeeedde0000ddeeddeeeede000000eedddddeed0000000deeeeedeed0000000ddeeeddd00000000000000ddd0000000000000000
00dddee0de00000000dddeeeedddee0000deeedeeeddeeee00000ddeeeeeeedd0000000ddeeeeded00000000dddeeded000000000dd00dde00000000000000d0
0eeeeeee000e00000eeeeeeddeeeeee000eeeddeeeeedde00000dedeeddddddd00000dddddddddee000000dd00ddddee00000000000d0ddd00000000000d00d0
0eeeeeed000d00000eeeeeeeeeedde0000edeedddddeed00000deeeedddeeed00000dddeddeeddd0000000eed0ddddd000000000000d0ded000000000000000d
00eeedddd000000000eeedeeedeeeee000eedeeeeeeeeedd0000eeeddeeeeedd0000deeeddeeeed000000deedddeedd00000000000000ddd00000000000000d0
000deeee00000000000deeedeeddde00000eeeeeeeedded0000ddeedeeeeded000000deeeddeeed000000deeeddeedd00000000d0000dddd0000000000000000
00000d000000000000000ddeeeeeed000000dddeeddddde00000deeddddeeed000000eedddeeeed000000eedddeeeed0000000ded0dddddd00000000d0000000
000000000000000000000000deed000000000d0edd00e00000000d00ddddeed0000000d00dddeeed000000d00dddeeed0000000d00dddded000000000000000d
00000000000000000000000000000000000000000000000000000000000dde0000000000000ddddd00000000000ddddd000000000000dedd000000000000d000
00000000000000000000000000000000000000000000000000000000000000000000000000000dd00000000000000dd0000000000000ddd00000000000000d00
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d000000000000000d00
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
8888822222288ffffff8888888888888888888888888888888888888888888888888888888888888888228228888228822888fff8ff888888822888888228888
8888828888288f8888f8888888888888888888888888888888888888888888888888888888888888882288822888222222888fff8ff888882282888888222888
8888822222288f8888f8888888888888888888888888888888888888888888888888888888888888882288822888282282888fff888888228882888888288888
8888888888888f8888f8888888888888888888888888888888888888888888888888888888888888882288822888222222888888fff888228882888822288888
8888828282888f8888f8888888888888888888888888888888888888888888888888888888888888882288822888822228888ff8fff888882282888222288888
8888882828288ffffff8888888888888888888888888888888888888888888888888888888888888888228228888828828888ff8fff888888822888222888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
000000000000000000000000000000000000000033333333333333330000000000000000dddddddddddddddddddddddd00000000333333330000000000000000
1111111100000000000000000000000000000000b333333bb333333b000000000000000099999999999999999999999900000000b333333b0000000011111111
1111111100000000000000000000000000000000b333333bb333333b000000000000000099999999999999999999999900000000b333333b0000000011111111
1111111100000000000000000000000000000000b333333bb333333b000000000000000066666666666666666666666600000000b333333b0000000011111111
1111111100000000000000000000000000000000b333333bb333333b000000000000000000000000000000000000000000000000b333333b0000000011111111
11111111000000000000000000000000000000001333333113333331000000000000000000000000000000000000000000000000133333310000000011111111
11111111000000000000000000000000000000001222222112222221000000000000000000000000000000000000000000000000122222210000000011111111
11111111000000000000000000000000000000001111111111111111000000000000000000000000000000000000000000000000111111110000000011111111
11111111000000000000000000000000000000001111111111111111000000000000000000000000000000000000000000000000bbbbbbbb0000000011111111
11111111000000000000000000000000000000001111111111111111000000000000000000000000000000000000000000000000b333333b0000000011111111
11111111000000000000000000000000000000001111111111111111000000000000000000000000000000000000000000000000b333333b0000000011111111
11111111000000000000000000000000000000001111111111111111000000000000000000000000000000000000000000000000b333333b0000000011111111
11111111000000000000000000000000000000001111111111111111000000000000000000000000000000000000000000000000b333333b0000000011111111
11111111000000000000000000000000000000001111111111111111000000000000000000000000000000000000000000000000133333310000000011111111
11111111000000000000000000000000000000001111111111111111000000000000000000000000000000000000000000000000122222210000000011111111
11111111000000000000000000000000000000001111111111111111000000000000000000000000000000000000000000000000111111110000000011111111
11111111000000000000000000000000000000001111111111111111000000000000000000000000000000000000000000000000bbbbbbbb0000000011111111
11111111000000000000000000000000000000001111111111111111004040400040404000404040004040400040404000404040b333333b0000000011111111
11111111000000000000000000000000000000001111111111111111404004404040044040400440404004404040044040400440b333333b0000000011111111
11111111000000000000000000000000000000001111111111111111040404000404040004040400040404000404040004040400b333333b0000000011111111
11111111000000000000000000000000000000001111111111111111024400400244004002440040024400400244004002440040b333333b0000000011111111
11111111000000000000000000000000000000001111111111111111042424440424244404242444042424440424244404242444133333310000000011111111
11111111000000000000000000000000000220001111111111111111242242202422422024224220242242202422422024224220122222210000000011111111
11111111000000000000000000000000002dd2001111111111111111224422422244224222442242224422422244224222442242111111110000000011111111
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000011111111
b333333bb333333bb333333bb333333bb333333b1111111111111111b333333bb333333bb333333bb333333bb333333bb333333bb333333b0000000011111111
b333333bb333333bb333333bb333333bb333333b1111111111111111b333333bb333333bb333333bb333333bb333333bb333333bb333333b0000000011111111
b333333bb333333bb333333bb333333bb333333b1111111111111111b333333bb333333bb333333bb333333bb333333bb333333bb333333b0000000011111111
b333333bb333333bb333333bb333333bb333333b1111111111111111b333333bb333333bb333333bb333333bb333333bb333333bb333333b0000000011111111
13333331133333311333333113333331133333311111111111111111133333311333333113333331133333311333333113333331133333310000000011111111
12222221122222211222222112222221122222211111111111111111122222211222222112222221122222211222222112222221122222210000000011111111
11111111111111111111111111111111111111111111111111111111111111111111111111111117777777777111111111111111111111110000000011111111
11111111000000000000000000000000000000000000000000000000000000000000000000000007000000007000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000000000000000000000000000000000007000000007000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000000000000000000000000000000000007000000007000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000000000000000000000000000000000007000000007000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000000000000000000000000000000000007000000007000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000000000000000000000000000000000007000000007000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000000000000000000000000000000000007001000007000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000000000000000000000000000000000007017100007000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000000000000000000000000000000000007717717777000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000000000000000000000000000000000000017771000000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000000000000000000000000000000000000017777100000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000000000000000000000000000000000000017711000000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000000000000000000000000000000000000001171000000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111000000000088780000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111000000000878887000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
111111110000000078ffff8800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111000000008fddddf800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
1111111100000000fddcdcdf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111000000000dddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111000000000dddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111000000000dddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
1111111100000000bbbbbbbb0000000000000000bbbbbbbb666666666666666666666666bbbbbbbb0000000000000000bbbbbbbb000000000000000011111111
1111111100000000b333333b0000000000000000b333333b999999999999999999999999b333333b0000000000000000b333333b000000000000000011111111
1111111100000000b333333b0000000000000000b333333b999999999999999999999999b333333b0000000000000000b333333b000000000000000011111111
1111111100000000b333333b0000000000000000b333333b666666666666666666666666b333333b0000000000000000b333333b000000000000000011111111
1111111100000000b333333b0000000000000000b333333b000000000000000000000000b333333b0000000000000000b333333b000000000000000011111111
11111111000000001333333100000000000000001333333100000000000000000000000013333331000000000000000013333331000000000000000011111111
11111111000000001222222100000000000000001222222100000000000000000000000012222221000000000000000012222221000000000000000011111111
11111111000000001111111100000000000000001111111100000000000000000000000011111111000000000000000011111111000000000000000011111111
1111111100000000bbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbb000000000000000011111111
1111111100000000b333333b000000000000000000000000000000000000000000000000000000000000000000000000b333333b000000000000000011111111
1111111100000000b333333b000000000000000000000000000000000000000000000000000000000000000000000000b333333b000000000000000011111111
1111111100000000b333333b000000000000000000000000000000000000000000000000000000000000000000000000b333333b000000000000000011111111
1111111100000000b333333b000000000000000000000000000000000000000000000000000000000000000000000000b333333b000000000000000011111111
11111111000000001333333100000000000000000000000000000000000000000000000000000000000000000000000013333331000000000000000011111111
11111111000000001222222100000000000000000000000000000000000000000000000000000000000000000000000012222221000000000000000011111111
11111111000000001111111100000000000000000000000000000000000000000000000000000000000000000000000011111111000000000000000011111111
1111111100000000bbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbb000000000000000011111111
1111111100000000b333333b004040400040404000404040004040400040404000404040004040400040404000404040b333333b000000000000000011111111
1111111100000000b333333b404004404040044040400440404004404040044040400440404004404040044040400440b333333b000000000000000011111111
1111111100000000b333333b040404000404040004040400040404000404040004040400040404000404040004040400b333333b000000000000000011111111
1111111100000000b333333b024400400244004002440040024400400244004002440040024400400244004002440040b333333b000000000000000011111111
11111111000000001333333104242444042424440424244404242444042424440424244404242444042424440424244413333331000000000000000011111111
11111111000000001222222124224220242242202422422024224220242242202422422024224220242242202422422012222221000220000000000011111111
11111111000000001111111122442242224422422244224222442242224422422244224222442242224422422244224211111111002dd2000000000011111111
1111111100000000bbbbbbbb424422444244224442442244424422444244224442442244424422444244224442442244bbbbbbbbbbbbbbbb6666666611111111
1111111100404040b333333b224222422242224222422242224222422242224222422242224222422242224222422242b333333bb333333b9999999911111111
1111111140400440b333333b244242442442424424424244244242442442424424424244244242442442424424424244b333333bb333333b9999999911111111
1111111104040400b333333b424224424242244242422442424224424242244242422442424224424242244242422442b333333bb333333b6666666611111111
1111111102440040b333333b242444222424442224244422242444222424442224244422242444222424442224244422b333333bb333333b0000000011111111
11111111042424441333333122442242224422422244224222442242224422422244224222442242224422422244224213333331133333310000000011111111
11111111242242201222222144242444442424444424244444242444442424444424244444242444442424444424244412222221122222210000000011111111
11111111224422421111111124224222242242222422422224224222242242222422422224224222242242222422422211111111111111110000000011111111
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333b
b333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333b
b333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333b
b333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333b
13333331133333311333333113333331133333311333333113333331133333311333333113333331133333311333333113333331133333311333333113333331
12222221122222211222222112222221122222211222222112222221122222211222222112222221122222211222222112222221122222211222222112222221
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
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
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88282888882228228822288888282888882228222822288888888888888888888888888888888888888888888888888888888888888888888888888888888888
88282882882828828828288888282882882828282828288888888888888888888888888888888888888888888888888888888888888888888888888888888888
88828888882828828828288888222888882828282822288888888888888888888888888888888888888888888888888888888888888888888888888888888888
88282882882828828828288888882882882828282828288888888888888888888888888888888888888888888888888888888888888888888888888888888888
88282888882228222822288888222888882228222822288888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__gff__
00000000000000000000000000000000808000000000000000000000000000000000000000000f0f000000000000000000000000000000000000000000000f000f01020404000080000000000000000006030c050a0000000000000000000000090e0e0b0700000000000000000000000f000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4040404040404040404040404040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7000000000004024242400000040247000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7000000000004000000000000062007000000000000000000000000000000000000000000081000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7000000000404000000000000040007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7000000000707000000024240040007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7020000030707010101010101040007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040707040404040404040007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7000004700000000470000004700007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7000004700000000470000004700007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7008004700000000472800004700007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7040006300000000644024244000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7040004240404040410000004000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7040101040000040000000004030007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7040111140005556570000004040267000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404026264040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
