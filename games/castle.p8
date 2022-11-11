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
		phys=true,
	}
	
	-- uncomment to disable debug
--	debug=nil
	
	-- 64x64 mode
--	poke(0x5f2c,3)
	
	if debug then
		-- kb/mouse for debug
		poke(0x5f2d,1)
	end
	
	entities={}
	solid_entities={}
	overlap_entities={}
	overlap_triggers={}
	stand_triggers={}
	attack_triggers={}
	
	for mx=0,127 do
		for my=0,63 do
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
	if key=="1" then
		debug.view_log="watch"
	elseif key=="2" then
		debug.view_log="log"
	elseif key=="3" then
		debug.view_log="ents"
	elseif key=="`" then
		debug.phys=not debug.phys
	end
end

function parse_tile(░,x,y)
	local sx,sy=w2s(x,y)
	if ░==24 then
		pl=make_player(sx+4,sy+5)
		mset(x,y,0)
	elseif ░==48 then
		make_spring_bud(sx+4,sy+4)
		mset(x,y,0)
	elseif ░==32 then
		make_spring(sx+4,sy+4)
		mset(x,y,0)
	elseif ░==20 then
		parse_platform(░,x,y)
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
	local lx=l*8+4
	local rx=r*8+4
	local px=(lx+rx)/2
	local w=(r-l+1)*4
	local plat=
		make_platform(px,sy+2,w,░)
	tblcpy(plat,opt or {})
	for mx=l,r do
		mset(mx,y,0)
	end
end

function check_keys()
	while stat(30) do
		keypress(stat(31))
	end
end

function play_update()
	check_keys()
	
	sort(entities,
		function(e1,e2)
			if e1==pl then
				return false
			elseif e2==pl then
				return true
			elseif e1.solid then
				return false
			elseif e2.solid then
				return true
			end
			return e1.id<e2.id
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
	
	if pl then
		watch("pos:"..pl.x..","..pl.y)
		watch("vel:"..pl.dx..","..pl.dy)
		watch("af:"..pl.frame)
		watch("am:"..pl.anim_mode)
	end

	for i,e in ipairs(entities) do
		logent(e)
	end

end

function play_draw()
	cls()
	
--	camera(pl.x-32,pl.y-32)
	
	map(0,0,0,0,16,16)
	
	foreach(entities,
		function(e) e:on_draw() end)

	pset(test.x,test.y,testcol and 8 or 11)

	camera()
	
	if debug then
		draw_log(debug.view_log)
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
	watch={log={},col=11},
	log={log={},col=6},
	ents={log={},col=10,bg=1},
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
	
	if bg~=nil then
		local sw=0
		local n=0
		for i,l in ipairs(lg.log) do
			local lsw=strw(l.msg)
			if (lsw>sw) sw=lsw
			n=i
		end
		rectfill(0,0,sw,n*6,bg)
	end

	for i,l in ipairs(lg.log) do
		local y=(i-1)*6
		print(l.msg,1,y+1,l.col)
	end
end

-->8
-- entities

entity={}

next_ent_id=1
function make_entity(params)
	local id=next_ent_id
	next_ent_id+=1

	local e={
		id=id,
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
		air_⧗=0,

		-- flags
		visible=true,
		collide=true,
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
	return add(entities,e)
end

function set_anim(e,frames,mode,prio)
	prio=prio or 0
	if (e.frames==frames) return
	if (prio < e.fprio) return
	e.fprio=prio or 0
	e.frames=frames
	e.frame=1
	e.fc=0
	e.fs=4
	e.anim_mode=mode or "play"
end

function entity_draw(e)
	if (not e.visible) return
	
	spr(e.frames[e.frame],
		e.x-e.sw/2,
		e.y-e.sh/2,
		e.tw,e.th,
		e.facing==-1)
		
	if debug and debug.phys then
		pset(e.x,e.y,10)
		rect(e.x-e.w,e.y-e.h,
			e.x+e.w-1,e.y+e.h-1,11)
	end
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
	e.solid=true
	add(solid_entities,e)
end

-->8
-- player

pl_anim_idle={24}
pl_anim_walk={24,25}
pl_anim_air={28,29,30,31}
pl_anim_land={26}
pl_anim_land_hard={26,27}

function make_player(px,py)
	pl_g=0.35
	pl_jumpf=3

	local e=make_entity({
		name="player",
		x=px,y=py,
		g=pl_g,
		ix=0,
		w=3,
		h=3.8,
		jump_⧗=0,
		canjump=false,
		physent=true,
		stand_entity=nil,
		on_update=player_update,
		on_air=player_on_air,
		on_land=player_on_land,
	})
	
	add(overlap_entities,e)
	return e
end

function proc_input(e)
	local inx,iny=0,0
	if (btn(⬅️)) inx-=1
	if (btn(➡️)) inx+=1
	if (btn(⬆️)) iny-=1
	if (btn(⬇️)) iny+=1
	
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

function player_update(e)
	if e.stand_entity then
		e.fdx+=e.stand_entity.mdx+e.stand_entity.physdx
	end


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

function make_spore_blast(x,y)
	
end

-->8
-- environment

function make_enviro_ent(param)
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
	local e=make_enviro_ent({
		name="bud_"..tostr(x)
			.."_"..tostr(y),
		x=x,y=y,
		w=1,
		grow_⧗=0,
		growing=false,
		on_update=bud_update,
		on_trigger=bud_trigger,
	})
	
	set_anim(e,{48})
	add(attack_triggers,e)
	
	return e
end

function bud_update(e)
	enviro_update(e)
	
	if e.growing then
		e.grow_⧗+=1
		if e.grow_⧗>=10 then
			make_spring(e.x,e.y)
			destroy_entity(e)
		end
	end
end

function bud_trigger(e)
	set_anim(e,{49,33,50})
	e.growing=true
end

-- spring
function make_spring(x,y)
	local e=make_enviro_ent({
		name="spring_"..tostr(x)
			.."_"..tostr(y),
		x=x,y=y,
		w=1,
		on_trigger=spring_trigger,
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
	end
end

-- platforms
function make_platform(x,y,w,░)
	local e=make_entity({
			name="platform",
			x=x,y=y,
			dx=1,dy=0,
			ix=1,iy=1,
			mdx=0,mdy=0,
			g=0,
			w=w or 4,
			h=2,
			sh=4,
			░=░,
			collide=true,
			on_update=platform_update,
			on_hit_wall=function(e,side)
				if side>0 then
					e.dx=-abs(e.ldx)
				else
					e.dx=abs(e.ldx)
				end
			end,
			on_draw=platform_draw,
		})
	tblcpy(opt or {},e)
	make_entity_solid(e)
	return e
end

function platform_update(e)
	e.mdx=e.dx
	entity_update(e)
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
-->8
-- physics

function slope_solid(x,y,m,sx,sy)
	if (fget(m,7)) sx=7-sx

	if fget(m,5) then
		local yy=7-(sx/2)
		return yy<=sy,yy\1
	elseif fget(m,6) then
		local yy=3-(sx/2)
		return yy<=sy,yy\1
	else
		local yy=7-sx
		return yy<=sy,yy
	end
--		
--	elseif fget(m,6) then
--	else
--		
--	end
end

function map_solid(x,y)
	local wx=x/8
	local wy=y/8
	local lx=wx-flr(wx)
	local ly=wy-flr(wy)
	local m=mget(wx,wy)

	if fget(m,4) then
		local hit,yy=slope_solid(
			x,y,m,lx*8,ly*8)
		if hit then
			return true,yy
		end
	end

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
		if e~=ignore and
			e:contains(x,y)
		then
			if type(info)=="table" then
				info.entity=e
			end
			return true
		end
	end
end

function solid(x,y,e,info)
	local hitmap,yover=
		map_solid(x,y)
	
	if hitmap then
		return true,yover
	elseif e and e.physent then
		return entity_solid(x,y,e,info)
	else
		return false
	end
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
		if solid(e.x+i,e.y-e.h,e,info) then
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
__gfx__
0000000088888888000000000000000000000000000000000000000000000000003b3b0000000000003b3b0000000000003b3b00003b3b000d3b3b000ddddd00
000000008ee8eee80000000000000000000000000000000000000000000000000d333300003b3b000d333300003b3b00003b3b000d333300dd3333d0dd3b3bd0
007007008e88e8e8000000000000000000000000000000000000000000000000dd3bbbd00d333300dd3bb3d00d333300003bbb00dd33bbd03d33bbdddd3333dd
000770008ee8ee88000000000000000000000000000000000000000000000000dddbdddddd33bbd0dddbdddddd3bb3d000dbbb00ddddddddddddddd33d33b3dd
000770008e88e8e80000000000000000000000000000000000000000000000003dddddd3ddddbddd3dddddd3ddddbddd00dbbd003ddbdddd0ddddddd0dddddd3
007007008ee8e8e80000000000000000000000000000000000000000000000000dddddd03dddddd30dddddd03dddddd300ddbd000dddbbd3033dd330033dd330
0000000088888888000000000000000000000000000000000000000000000000033dd330033ddd3333dddd3333ddd33000dbbd00033bd3300330033003300330
000000008888888800000000000000000000000000000000000000000000000003300330033ddd333300003333ddd3300033330003300b300000000000000000
00000000000000000000000066666666666666666666666600000000000000000088780000000000000000000000000000888e00008878000088780007887880
0040404000000000000000006799999999999999679999760000000000000000087888700088780000000000000000000088870008788870087888708fffff87
404004400000000000000000667999999999999966799766000000000000000078ffff880878887000000000000000000e88888008ffff8078ffff88fffddfff
04040400000000000000000006666666666666660666666000000000000000008fddddf878ffff880000000000000000078888e00fdcdcf08fddddf80dddddd0
0244004000000000000330000000000000000000000000000000000000000000fddcdcdf8fddddf8008878000000000000de8d7000dddd000ddcdcd00dddddd0
0424244400000000003bb30000000000000000000000000000000000000000000dddddd0fddcdcdf887888780787888000d7dd0000dddd000dddddd00ddcdcd0
242242200000000003bbbb3000000000000000000000000000000000000000000dddddd00dddddd07ddcdcd88888878700dddd0000dddd0000dddd000dddddd0
22442242000000000003300000000000000000000000000000000000000000000dddddd0dddddddddddddddd8dcdcdd800dddd0000dddd000000000000dddd00
000000000000000000bbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000bbb000000000000bbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bbbbb0000000000bbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbbbbbb0000bb000bbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbbb33b00bbbbb00bbb23b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb33330bbb33bbb0b32233000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b332000b332233b0032230000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00022000002222000002200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000bb00000000000000000000000000003bbbb3000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000bbb0000000000000000000000000003bbbbbb300000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000bbbb0000bbbb000000000000000000bbbbbbbb00333300000000000000000000000000000000000000000000000000000000000000000000000000
0000000000bbbbb00bbbbbb000000000000000000003300003bbbb30000000000000000000000000000000000000000000000000000000000000000000000000
000000000bb23bb00bbbbbbb0000000000000000000330000bbbbbb0000330000000000000000000000000000000000000000000000000000000000000000000
000000000b3223b0bbbb23bb00000000000000000003300000033000003bb3000000000000000000000000000000000000000000000000000000000000000000
0003300000322300bb3223300000000000000000000330000003300003bbbb300000000000000000000000000000000000000000000000000000000000000000
00322300000220000002200000000000000000000003300000033000000330000000000000000000000000000000000000000000000000000000000000000000
aaaaaaaaaaaa00000000aaaa00000000000000000000000a00000000000000aa0000000000000000000000000000000000000000000000000000000000000000
aaaaaaaaaaaa00000000aaaa0000000000000000000000aa000000000000aaaa0000000000000000000000000000000000000000000000000000000000000000
aaaaaaaaaaaa00000000aaaa000000000000000000000aaa0000000000aaaaaa0000000000000000000000000000000000000000000000000000000000000000
aaaaaaaaaaaa00000000aaaa00000000000000000000aaaa00000000aaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
aaaaaaaa0000000000000000aaaa00000000aaaa000aaaaa000000aaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
aaaaaaaa0000000000000000aaaa00000000aaaa00aaaaaa0000aaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
aaaaaaaa0000000000000000aaaa00000000aaaa0aaaaaaa00aaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
aaaaaaaa0000000000000000aaaa00000000aaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
0000aaaaaaaaaaaa00000000aaaa00000000aaaaa0000000bb000000000000000000000000000000000000000000000000000000000000000000000000000000
0000aaaaaaaaaaaa00000000aaaa00000000aaaaaa00000033bb0000000000000000000000000000000000000000000000000000000000000000000000000000
0000aaaaaaaaaaaa00000000aaaa00000000aaaaaaa000004b33bb00000000000000000000000000000000000000000000000000000000000000000000000000
0000aaaaaaaaaaaa00000000aaaa00000000aaaaaaaa0000433333bb000000000000000000000000000000000000000000000000000000000000000000000000
aaaa000000000000aaaaaaaaaaaa00000000aaaaaaaaa000443b4333bb0000000000000000000000000000000000000000000000000000000000000000000000
aaaa000000000000aaaaaaaaaaaa00000000aaaaaaaaaa004b33433333bb00000000000000000000000000000000000000000000000000000000000000000000
aaaa000000000000aaaaaaaaaaaa00000000aaaaaaaaaaa0434344b4b333bb000000000000000000000000000000000000000000000000000000000000000000
aaaa000000000000aaaaaaaaaaaa00000000aaaaaaaaaaaa43444344343b33bb0000000000000000000000000000000000000000000000000000000000000000
aaaa00000000aaaaaaaa0000aaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaa00000000aaaaaaaa0000aaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaa00000000aaaaaaaa0000aaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaa00000000aaaaaaaa0000aaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000aaaaaaaaaaaaaaaaaaaa0000aaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000aaaaaaaaaaaaaaaaaaaa0000aaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000aaaaaaaaaaaaaaaaaaaa0000aaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000aaaaaaaaaaaaaaaaaaaa0000aaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000001020408000000000000000000030000000000000000000000000000000000000e0d0b07000000000000000000000000000000000000000000000f000f01020408103050000000000000000006030c050a90d0b00000000000000000090e0d0b07000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4040404040404040404040404040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000062004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000404000001414000040004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000404000000000000040004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000020404010101010101040004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404040404040004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000001800004555000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000454055000046474040565700004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404040404040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
