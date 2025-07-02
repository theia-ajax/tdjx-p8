pico-8 cartridge // http://www.pico-8.com
version 42
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
	
	--poke(0x5f2c,3) --64x64 mode
	poke(0x5f5c,255) --disable btnp repeat
	
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

	local lvlx,lvly=1,0
	for lx=0,15 do
		for ly=0,16 do
			local mx=lvlx*16+lx
			local my=lvly*16+ly
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
			map(lvlx*16,lvly*16,lvlx*128,lvly*128,16,16)
		end})
	add(drawables,{
		z_order=50,
		on_draw=function()
			map(lvlx*16,lvly*16,lvlx*128,lvly*128,16,16,1<<7)
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
	local cx,cy=sx+4,sy+4
	if ░==8 then
		pl=make_player(cx,cy+1)
		fb=make_fungball(cx,cy)	
	elseif ░==48 then
		make_spring_bud(cx,cy)
	elseif ░==32 then
		make_spring(cx,cy)
	elseif ░==36 then
		parse_platform(░,x,y)
	elseif ░==16 then
		make_spikes(cx,cy)
	elseif ░==40 then
		make_skeleton(cx,cy)
	elseif ░==57 then
		make_ghost(cx,cy)
	elseif ░>=85 and ░<=87 then
		make_bramble(cx,cy)
		return -- no mset
	else
		return -- avoids mset if nothing to parse
	end
	mset(x,y,0)
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

	local is_elevator=false
	for yy=y,15 do
		local f=fget(mget(x,yy))
		if (f&0x10~=0) is_elevator=true
		if (f&0xf~=0) break
	end

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
	
	if fb.attached==nil
	then
	
	for t in all(attack_triggers)
	do
		if aabb(fb,t,2) then
			t:on_trigger(e)
		end
	end
	end
	

	watch(tostr(stat(0)/204.8).."%")
	watch(tostr(stat(1)*100).."%")
	watch(tostr(stat(2)*100).."%")

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
	else
		clear_frame_logs()
	end
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


function aabb(t1,t2,r)
	r=r or 0
	local w1,w2=t1.w+r,t2.w+r
	return t1.x+w1>=t2.x-w2
		and t1.x-w1<=t2.x+w2
		and t1.y+w1>=t2.y-w2
		and t1.y-w1<=t2.y+w2
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

function norm(x,y,l)
	local l=l or len(x,y)
	if (l==0) return 0,0
	return x/l,y/l
end

function lerp(a,b,t)
	return (b-a)*t+a
end

function ilerp(a,b,c)
	if (a==b) return 0
	return (c-a)/(b-a)
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
		on_kill=function()end,
		contains=entity_contains,
		dropdown=function() return false end,
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
	
	update_animation(e)
end

function update_animation(e)
	if e.anim_mode=="play"
		or e.anim_mode=="loop"
	then
  if (e.fc<e.fs) e.fc+=1
  
  if e.fs>0 and e.fc==e.fs then
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
	e.mdx=0e.mdy=0
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
		drop_⧗=0,
		canjump=false,
		physent=true,
		dead=false,
		stand_entity=nil,
		on_update=player_update,
		on_air=player_on_air,
		on_land=player_on_land,
		on_kill=player_kill,
		dropdown=function(e) return e.drop_⧗>0 end,
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

	if btnp(❎) then	
		if fb.attached==nil then
			fungball_recover(fb,e)
		else
			local fx=abs(inx)
			local fy=iny
			if (fx==0 and fy==0) fx=1
			local dx=fx*e.facing*5
			local dy=fy*5
			if (not e.in_air) dy=min(dy,0.25)
			if (dy==0) dy=-1

			if fy>0 and not e.in_air
				and fx==0
			then
				fb.x=e.x
				fb.y=e.y+1
				fungball_throw(fb,0,0.1)
			else
				fungball_throw(fb,dx,dy)
			end
		end
	end
	
	if inx~=0 then
		e.dx+=inx
		e.facing=sgn(inx)
	end
	
	if iny>0 then
		e.drop_⧗=5
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
	e:on_kill()
end

function entity_stand_entity_move(e)
	if e.stand_entity then
		e.fdx+=e.stand_entity.mdx
		e.fdy+=e.stand_entity.mdy
	end
end

function player_update(e)
	entity_stand_entity_move(e)

	if (e.drop_⧗>0) e.drop_⧗-=1

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

function player_kill(e)
	set_anim(e,pl_anim_die,"play",1000)
	e.on_anim_stop=function(e)
		destroy_entity(e)
		pl=make_player(fb.x,fb.y)
	end
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
	
	for p in all(e.particles) do
		circfill(p.x,p.y,2+cos(nt(p))*3,2)
	end
	
	for p in all(e.particles) do
		circfill(p.x,p.y,2+cos(nt(p))*2,14)
	end
end

function make_fungball(x,y)
	fb_fast_fric=0.99
	fb_slow_fric=0.7
	local e=make_entity({
		x=x,y=y,
		g=pl_g,
		sw=8,sh=8,
		ix=fb_fast_fric,
		iy=fb_fast_fric,
		w=2,h=2,
		fd=0,
		target=nil,
		collide=true,
		attached=nil,
		on_land=function(e)
			e.dy=e.ldy*-0.6
			if (abs(e.dy)<0.5) e.dy=0
			
		end,
		on_hit_wall=function(e)
			e.dx=e.ldx*-0.7
			if (abs(e.dx)<0.5) e.dx=0
		end,
		on_update=fungball_update,
		on_draw=fungball_draw})
	set_anim(e,{43,44,45,46},"loop")
	e.fs=0
	add(overlap_entities,e)
	return e
end

function fungball_grab(e,src)
	e.target=nil
	e.attached=src
	e.fs=0
	e.fc=0
	e.frame=1
end

function fungball_recover(e,src)
	e.stand_entity=nil
	e.fdx,e.fdy=0,0
	del(overlap_entities,e)
	e.target=src
	e.fs=1
	e.fc=0
	e.frame=1
end

function fungball_throw(e,dx,dy)
	add(overlap_entities,e)
	e.attached=nil
	e.target=nil
	e.dx=dx
	e.dy=dy
	e.fs=1
	e.fc=0
	e.frame=1
end

function fungball_update(e)
	entity_stand_entity_move(e)
	if e.attached then
		e.facing=e.attached.facing
		e.x=e.attached.x-e.attached.facing*2
		e.y=e.attached.y+1
		update_animation(e)
	elseif e.target then
		local dx,dy=
			e.target.x-e.target.facing*2-e.x,
			e.target.y+1-e.y
		local dist=len(dx,dy)
		
		if dist<2 then
			fungball_grab(e,e.target)
		end
		
		local nx,ny=norm(dx,dy,dist)
		local accel=3--2-mid(dist/32,0,1)
		
		e.dx+=nx*accel
		e.dy+=ny*accel
		
		local maxspd=lerp(1,16,mid(dist/64,0,1))
		local spd=len(e.dx,e.dy)
		if spd>maxspd then
			e.dx=e.dx/spd*maxspd
			e.dy=e.dy/spd*maxspd
		end		
		
		e.x+=e.dx
		e.y+=e.dy

		update_animation(e)
	else
		local mspd=abs(e.dx)+abs(e.dy)
		if mspd<1 then
			e.fs=0
			e.fc=0
			e.frame=1
		elseif mspd<2 then
			e.fs=4
		elseif mspd<3 then
			e.fs=3
		elseif mspd<4 then
			e.fs=2
		elseif mspd<5 then
			e.fs=1
		end
		e.ix=fb_fast_fric
		if (abs(e.dx)<0.7) e.ix=fb_slow_fric
		entity_update(e)
	end
end

function fungball_draw(e)
	if (e.attached) pal(10,12)
	entity_draw(e)
	pal()
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
		src.dy=-5.5
		e.overlap_⧗=5
--		make_spore_blast(e.x,e.y-4,e.facing)
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
	entity_draw(e)
end

-- platforms
function make_platform(x,y,w,░,opt)
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
		if e.nextdy then
			e.dy=e.nextdy
			e.nextdy=nil
		end
	end
	entity_update(e)
	e.mdx=e.x-e.lx
	e.mdy=e.y-e.ly
	
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

function platform_draw(e)
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
	until b>=32 
		or fget(mget(mx,b),4)
	
	local topy=y
	local boty=b*8+(y-y\8*8)
	
	local e=make_platform(x,y,w,░,{
			name="elevator",
			collide=false,
			x=x,y=y,
			dx=0,dy=1,
			topy=topy,
			boty=boty,
			wait_⧗=0,
			ix=1,iy=1,
			mdx=0,mdy=0,
			g=0,
			w=w or 4,
			h=2,
			sh=4,
			░=░,
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

function make_bramble(x,y)
	local e=make_enviro_entity({
		name="bramble",
		x=x,y=y,
		on_draw=function()end,
		on_trigger=function(e)
			destroy_entity(e)
			mset(x/8,y\8,0)
		end,
	})
	set_anim(e,{70})
	add(attack_triggers,e)
	return e
end
-->8
-- enemies

function make_enemy(x,y,opt)
	opt=opt or {}
	opt.x=x
	opt.y=y
	opt.order=5000
	local e=make_entity(opt)
	add(overlap_entities,e)
	add(attack_triggers,e)
	return e
end

function make_skeleton(x,y)
	local e=make_enemy(x,y,{
		name="skeleton",
		collide=true,
		g=pl_g,
		w=3,
		on_trigger=destroy_entity,
		on_update=skeleton_update,
		on_hit_wall=skeleton_wall,
	})
	skel=e
	set_anim(e,{40})
end

function skeleton_update(e)
	e.dx=e.facing*0.125
	entity_stand_entity_move(e)
	entity_update(e)
end

function skeleton_wall(e)
	e.facing=-e.facing
end

function make_ghost(x,y)
	local e=make_enemy(x,y,{
		name="ghost",
		collide=true,
		g=0,
		w=3,h=3,
		on_update=ghost_udpate,
		on_trigger=function(e)
			make_spore_blast(e.x,e.y)
			destroy_entity(e)
		end,
	})
	gh=e
	set_anim(e,{57})

	return e
end

function ghost_udpate(e)
	local fx,fy=pl.x-e.x,pl.y-e.y
	fx,fy=norm(fx,fy)
	e.facing=sgn(fx)
	e.dx=fx*0.25
	e.dy=fy*0.25
	entity_stand_entity_move(e)
	entity_update(e)
end
-->8
-- physics

function map_solid(x,y,dropdown)
	local wx=x/8
	local wy=y/8
	local ly=wy-wy\1
	local m=mget(wx,wy)

	local dropable=fget(m,1)
	local hit=fget(m,0)
		and (ly<0.5 or not dropable)
	return hit
		and (not dropable or dropdown==false)
end

function entity_solid(x,y,ignore,info,dropdown)
	for _,e in ipairs(solid_entities)
	do
		if e~=ignore
			and e:contains(x,y)
		then
			if type(info)=="table" then
				info.entity=e
			end
			return dropdown==nil or dropdown==false
		end
	end
end

function solid(x,y,e,info,dropdown)
	return	entity_solid(x,y,e,info,dropdown)
		or map_solid(x,y,dropdown)
end

function should_fall(e)
	if (e.in_air) return true
	
	local air=true
	for i=-e.w,e.w-1 do
		local ty=e.y+e.h+1
		if solid(e.x+i,ty,e,{},e:dropdown()) then
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
				e.x=(e.x+e.w)\8*8-e.w
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
				e.x=(e.x-e.w)\8*8+8+e.w
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
	local info={}
	
	local standing=nil
	local mct,ect=0,0
	for i=-e.w,e.w-1 do
		local ty=e.y+e.h
		local hit=false
		info.entity=nil
		if solid(e.x+i,ty,e,info,e:dropdown()) then
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
		else
			e.y=(e.y+e.h)\8*8-e.h
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
				e.y=(e.y-e.h)\8*8+8+e.h
			end		
		end
	end
	return collided
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
0000000000000000008888006666666666666666666666663333333355555555007777770000000000000000000000c0000cecc000cc00000000000000000000
000888000000000000878800619999999999999961999916322222235222222500675775007777770000000000000ce0000cec00cec00000c000000000000000
008787800000000008878780061999999999999906199160b122221bb122221b0067777700675775000000000000cecc000ce0000ce00000cc00000000000000
088888880000880008888780006666666666666600666600b311113bb311113b067677770667777700000000000ee00c000ee00000cee000eeeeeccc00000000
08788228008878800778d280000000000000000000000000b333333bb333333b076675700776777700000000c00ee000000ee000000eec00ccceeeee00000000
8882222088722878082dd2200000000000000000000000001333333113333331077660000766757000000000ccec0000000ec00000000ec0000000cc00000000
0822d000822dd228002dd20000000000000000000000000012222221122222210667660006676600000000000ec0000000cec00000000cec0000000c00000000
000dd00000dddd00000dd00000000000000000000000000011111111111111110770770077000770000000000c0000000ccec0000000cc000000000000000000
00000000000780000000000033333333333333333333333333333333000000000ee0000000999900000000000000000000000000000000000000000000000000
0000000000878000000000003222222222222222222222233222222300000000eaae0000097777900000000000000000c0000000000000000000000000000000
000000000088870000888800b1222222222222222222221bb122221b00000000eaae0000977777900000000000000000cc000000000000000000000000000000
000000000078878008878770b3111111111111111111113bb311113b000000000ee00000977979790000000000000000eeeeeccc000000000000000000000000
00000000087d288008888888b333333bb333333bb333333bb333333b0000000000000000977777790000000000000000ccceeeee000000000000000000000000
00000000082dd2808778d288133333311333333113333331133333310000000000000000977979790000000000000000000000cc000000000000000000000000
00022000002dd200882dd2201222222112222221122222211222222100000000000000000977779000000000000000000000000c000000000000000000000000
002dd200000dd000000dd00011111111111111111111111111111111000000000000000000999900000000000000000000000000000000000000000000000000
bbbbbbbbbbbb00000000bbbb000000000000000099999999000000000b1b3b300000000000000000000000000000000000000000000000000000000000000000
b333333b13310000000013310000000000000000994999490000000000b13100004040400040404000f040400040f0f00040404000f0404000f0f0400040f0f0
b333333b122100000000122100000000000000004444444400000000000b30004040044040400440f0f00440404004f040400440f0f00440f0f00f4040400440
b333333b1111000000001111000000000000000000000000000000000003b000040404000f0404000f0f0f0004040400040404000f0f0f000f0f0f0004040400
b333333b1110000000000111bbbb00000000bbbb000000000000000000031b000244004002ff0040024f00f0024400400244004002ff00f002ff00f002440040
1333333111000000000000111331000000001331000000000000000000033b00042424440f2f2ff4042424ff04242444042424440f2f2fff042f2fff0424244f
12222221100000000000000112210000000012210000000000000000003bb1002f2242202422f22024224220242242202f2242202422f2202422422024224220
1111111100000000000000001111000000001111000000000000000003b133b022ff22f2224422f2224422422244224222ff22f2224422f22244224222442242
0000bbbbbbbbbbbb00000000bbbb00000000bbbb4922299909222999492229900000000000000000000000000000000000000000000000000000000000000000
000013311333333100000000b33b00000000b33b99449942004499429944994000f0f0f000f0f0f0004040f00040404000f0f0f000f0f0f0004040f000404040
000112211222222100000000b33b00000000b33b449944220099442244994400f0f00ff0f0400940f040044040400440f0f00ff0f0400940f040044040400440
001111111111111100000000b33b00000000b33b2229992220299922222999200f0f0f000909090004090900040404000f0f0f00090909000409090004040400
bbbb111000000000bbbbbbbbb33b00000000b33b22494942024949422249490002ff00f00299009002990090024900400eff00f0029900900299009002490040
13311100000000001333333113310000000013314999249409992494499924000f2f2fff092929940429294f042929440fefefff092929940429294f04292944
12211000000000001222222112210000000012219942249990422499994224902f22f220242242202422922024229220efeefee0242242202422922024229220
111100000000000011111111111100000000111194222249042222499422220922ff22f222ff22f222f422f222442242eeffeefe22ff22f222f422f222442242
bbbb00000000bbbbbbbb0000bbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
133100000000b33bb33b0000b333333bb333333b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
122110000000b33bb33b0000b333333bb333333b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111111000000b33bb33b0000bbbbb33bb33bbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0111bbbbbbbbb33bb33bbbbb0111b33bb33b11100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111331133333311333333100111331133111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011221122222211222222100011221122110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001111111111111111111100001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111bbbbbbbb0011110011110000000011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111133333310011110011110000000011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111122222210011110011110000000011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111110011110011110000000011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111001111000011110011110000000011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111001111000011110011110000000011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111001111000011110011110000000011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111001111000011110011110000000011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000083
__label__
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
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333b
b333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333b
b333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333b
b333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333b
13333331133333311333333113333331133333311333333113333331133333311333333113333331133333311333333113333331133333311333333113333331
12222221122222211222222112222221122222211222222112222221122222211222222112222221122222211222222112222221122222211222222112222221
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
bbbbbbbb00000000000000000000000000000000bbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbb
b333333b00000000000000000000000000000000b333333b000000000000000000000000000000000000000000000000000000000000000000000000b333333b
b333333b00000000000000000000000000000000b333333b000000000000000000000000000000000000000000000000000000000000000000000000b333333b
b333333b00000000000000000000000000000000b333333b000000000000000000000000000000000000000000000000000000000000000000000000b333333b
b333333b00000000000000000000000000000000b333333b000000000000000000000000000000000000000000000000000000000000000000000000b333333b
13333331000000000000000000000000000000001333333100000000000000000000000000000000000000000000000000000000000000000000000013333331
12222221000000000000000000000000000000001222222100000000000000000000000000000000000000000000000000000000000000000000000012222221
11111111000000000000000000000000000000001111111100000000000000000000000000000000000000000000000000000000000000000000000011111111
bbbbbbbb00000000000000000000000000000000bbbbbbbb000000000000000000000000000000000000000000000000000006666666666666666000bbbbbbbb
b333333b00000000000000000000000000000000b333333b000000000000000000000000000000000000000000000000000006199999999999916000b333333b
b333333b00000000000000000000000000000000b333333b000000000000000000000000000000000000000000000000000000619999999999160000b333333b
b333333b00000000000000000000000000000000b333333b000000000000000000000000000000000000000000000000000000066666666666600000b333333b
b333333b00000000000000000000000000000000b333333b000000000000000000000000000000000000000000000000000000000000000000000000b333333b
13333331000000000000000000000000000000001333333100000000000000000000000000000000000000000000000000000000000000000000000013333331
12222221000000000000000000000000000000001222222100000000000000000000000000000000000000000000000000000000000000000000000012222221
11111111000000000000000000000000000000001111111100000000000000000000000000000000000000000000000000000000000000000000000011111111
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb99999999bbbbbbbb000000000000000000000000000000000000000000000000bbbbbbbb0000000000000000bbbbbbbb
b333333bb333333bb333333bb333333b99499949b333333b000000000000000000000000000000000000000000000000b333333b0000000000000000b333333b
b333333bb333333bb333333bb333333b44444444b333333b000000000000000000000000000000000000000000000000b333333b0000000000000000b333333b
b333333bb333333bb333333bb333333b00000000b333333b000000000000000000000000000000000000000000000000b333333b0000000000000000b333333b
b333333bb333333bb333333bb333333b00000000b333333b000000000000000000000000000000000000000000000000b333333b0000000000000000b333333b
13333331133333311333333113333331000000001333333100000000000000000000000000000000000000000000000013333331000000000000000013333331
12222221122222211222222112222221000000001222222100000000000000000000000000000000000000000000000012222221000000000000000012222221
11111111111111111111111111111111000000001111111100000000000000000000000000000000000000000000000011111111000000000000000011111111
bbbbbbbb00000000000000000000000000000000bbbbbbbb000000000000000000000000000000006666666666666666bbbbbbbb0000000000000000bbbbbbbb
b333333b00000000000000000000000000000000b333333b000000000000000000000000000000006199999999999916b333333b0000000000000000b333333b
b333333b00000000000000000000000000000000b333333b000000000000000000000000000000000619999999999160b333333b0000000000000000b333333b
b333333b00000000000000000000000000000000b333333b000000000000000000000000000000000066666666666600b333333b0000000000000000b333333b
b333333b00000000000000000000000000000000b333333b000000000000000000000000000000000000000000000000b333333b0000000000000000b333333b
13333331000000000000000000000000000000001333333100000000000000000000000000000000000000000000000013333331000000000000000013333331
12222221000000000000000000000000000000001222222100000000000000000000000000000000000000000000000012222221000000000000000012222221
11111111000000000000000000000000000000001111111100000000000000000000000000000000000000000000000011111111000000000000000011111111
bbbbbbbb00000000000000000000000000000000bbbbbbbb000000000000000000000000000000000000000000000000bbbbbbbb0000000000000000bbbbbbbb
b333333b00000000000000000000000000000000b333333b000000000000000000000000000000000000000000000000b333333b0000000000088800b333333b
b333333b00000000000000000000000000000000b333333b000000000000000000000000000000000000000000000000b333333b0000000000878780b333333b
b333333b00000000000000000000000000000000b333333b000000000000000000000000000000000000000000000000b333333b0000000008888888b333333b
b333333b00000000000000000000000000000000b333333b000000000000000000000000000000000000000000000000b333333b0000000008788228b333333b
13333331000000000000000000000000000000001333333100000000000000000000000000000000000000000000000013333331000000008882222013333331
12222221000000000000000000000000000000001222222100000000000000000000000000000000000000000000000012222221000000000822d00012222221
1111111100000000000000000000000000000000111111110000000000000000000000000000000000000000000000001111111100000000000dd00011111111
bbbbbbbb0000000000000000bbbbbbbb00000000bbbbbbbb6666666666666666000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbb99999999bbbbbbbb
b333333b0000000000000000b333333b00000000b333333b6199999999999916000000000000000000000000b333333bb333333bb333333b99499949b333333b
b333333b0000000000000000b333333b00000000b333333b0619999999999160000000000000000000000000b333333bb333333bb333333b44444444b333333b
b333333b0000000000000000b333333b00000000b333333b0066666666666600000000000000000000000000b333333bb333333bb333333b00000000b333333b
b333333b0000000000000000b333333b00000000b333333b0000000000000000000000000000000000000000b333333bb333333bb333333b00000000b333333b
13333331000000000000000013333331000000001333333100000000000000000000000000000000000000001333333113333331133333310000000013333331
12222221000000000000000012222221000000001222222100000000000000000000000000000000000000001222222112222221122222210000000012222221
11111111000000000000000011111111000000001111111100000000000000000000000000000000000000001111111111111111111111110000000011111111
bbbbbbbb0000000000000000bbbbbbbb00000000bbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbb
b333333b0000000000000000b333333b00088800b333333b000000000000000000000000000000000000000000000000000000000000000000000000b333333b
b333333b0000000000000000b333333b00878780b333333b000000000000000000000000000000000000000000000000000000000000000000000000b333333b
b333333b0000000000000000b333333b08888888b333333b000000000000000000000000000000000000000000000000000000000000000000000000b333333b
b333333b0000000000000000b333333b08788228b333333b000000000000000000000000000000000000000000000000000000000000000000000000b333333b
13333331000000000000000013333331888222201333333100000000000000000000000000000000000000000000000000000000000000000000000013333331
122222210000000000000000122222210822d0001222222100000000000000000000000000000000000000000000000000000000000000000000000012222221
11111111000000000000000011111111000dd0001111111100000000000000000000000000000000000000000000000000000000000000000000000011111111
bbbbbbbb0000000000000000bbbbbbbbbbbbbbbbbbbbbbbb0000000000000000bbbbbbbbbbbbbbbb0000878800000000000000000000000000000000bbbbbbbb
b333333b0000000000000000b333333bb333333bb333333b0000000000000000b333333bb333333b0007888780000000000000000000000000000000b333333b
b333333b0000000000000000b333333bb333333bb333333b0000000000000000b333333bb333333b0088ffcf87000000000000000000000000000000b333333b
b333333b0000000000000000b333333bb333333bb333333b0000000000000000b333333bb333333b008fdcedf8000000000000000000000000000000b333333b
b333333b0000000000000000b333333bb333333bb333333b0000000000000000b333333bb333333b00fdceccdf000000000000000000000000000000b333333b
13333331000000000000000013333331133333311333333100000000000000001333333113333331000eeddcd000000000000000000000000000000013333331
12222221000000000000000012222221122222211222222100000000000000001222222112222221c00eedddd000000000000000000000000000000012222221
11111111000000000000000011111111111111111111111100000000000000001111111111111111ccecddddd000000000000000000000000000000011111111
bbbbbbbb000000000000000000000000000000000b1b3b3000000000bbbbbbbbbbbbbbbbbbbbbbbbbecbbbbb00000000000000000000000000000000bbbbbbbb
b333333b0008880000000000000000000000000000b1310000000000b333333bb333333bb333333bbc33333b00000000000000000000000000088800b333333b
b333333b00878780000000000000000000000000000b300000000000b333333bb333333bb333333bb333333b00000000000000000000000000878780b333333b
b333333b088888880000000000000000000000000003b00000000000b333333bb333333bb333333bb333333b00000000000000000000000008888888b333333b
b333333b0878822800000000000000000000000000031b0000000000b333333bb333333bb333333bb333333b00000000000000000000000008788228b333333b
133333318882222000000000000000000000000000033b0000000000133333311333333113333331133333310000000000000000000000008882222013333331
122222210822d000000000000000000000000000003bb10000000000122222211222222112222221122222210000000000000000000000000822d00012222221
11111111000dd00000000000000000000000000003b133b00000000011111111111111111111111111111111000000000000000000000000000dd00011111111
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
00000000000000000000000000000000808000000000000000000000000000000000000000000f0f00000000000000000000001f1f1f1f00000000000000000001000000000300800000000000000000000000000005050500000000000000000000000000000000000000000000000001000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4040404040404040404040404040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7000000000000800000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7000000000004024242400000040247040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7000000000004000003900000040007040003900004000000000000000000040000000000081000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7000000000404000000000000040007040000000004000000024240000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7000000000707000000024240040007040404040454000000000000040000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7020000030707010101010101040007040000000004000390000242440000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040707040404040404040007040000000004000000000000040002040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7000004700000000470000004700007040000040004000002424004040404540000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7000004700390000470000004700007040000040204000002800005655570040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7000004700000000472800004700007040000040404000004040005655570040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7040004000000000404024244000007040200800004700404040405655572040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7040004040404040400000004000007040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7040101040000040000000004030007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7040111140000047000000004040367000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404033354040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
