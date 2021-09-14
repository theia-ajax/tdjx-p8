pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
function _init()
	poke(0x5f2d,1)

	play_init()
end

function play_init()
	_update60=play_update
	_draw=play_draw
	
	levels={
		{
			name="test_01",
			x=0,y=0,w=32,h=16,
		},
		{
			name="test_02",
			x=16,y=0,w=16,h=16,
		},
		{
			name="test_03",
			x=0,y=16,w=16,h=16,
			entities={}
		},
		{
			name="spike_test",
			x=16,y=16,w=16,h=16,
		}
	}
	for i=1,#levels do levels[i].id=i end
	level_id=1
	level=levels[level_id]
	
	init_actors()
	
	mc_anims={
		idle={
			base=32,
			w=1,
			h=2,
			frames=1,
			dt=0
		},
		walk={
			base=33,
			w=1,
			h=2,
			frames=4,
			dt=1/16
		},
		sprint={
			base=39,w=1,h=2,
			frames=4,
			dt=1/12,
		},
		jump={
			base=37,w=1,h=2,
			frames=1,
			dt=0
		},
		fall={
			base=38,w=1,h=2,
			frames=1,
			dt=0
		},
		shoot={
			base=41,w=1,h=2,
			frames=1,
			dt=0,
		}
	}
	
	guns={
		pistol={
			sp=21
		},
		ar={
			sp=20
		},
		shotgun={
			sp=22
		},
	}
	
	mc=add_actor({
  		x=8,y=8,
  		h=2,
  		keys={},
  		gun=guns.pistol,
  		ddy=35,
  		sp=34,
  		anim=mc_anims.idle,
  		anim_t=0,
  		k_accel=40,
  		k_max_move=6,
  		k_jump_force=18,
  		k_jump_hold_force=0,
  		on_death=function(self)
  			self.sp+=16
  		end,
  		coll=colldr:new({
  			x=0,y=-1,w=0.5,h=1
  		}),
  	})
 mc.coll.parent=mc
end

function keypress(key)
	if key=='f' then
		mc.gun=nil
	elseif key=='1' then
		mc.gun=guns.ar
	end
end		

function play_update()
	while stat(30) do
		keypress(stat(31))
	end

	local ix,iy=0,0
	if (btn(0)) ix-=1
	if (btn(1)) ix+=1
	if (btn(2)) iy-=1
	if (btn(3)) iy+=1
	
	local bts={btnp(4),btnp(5),btn(4),btn(5)}
	local bt=0
	for i=1,#bts do
		if bts[i] then
			bt+=shl(1,i-1)
		end
	end

	mc.inp.x=ix
	mc.inp.y=iy
	mc.inp.btns=bt
	
	foreach(actors,function(a)
 		a:move(1/60)
 	end)
 	
 if band(mc.flags,af.grounded)==0 then
 	if mc.dy<0 then
 		mc.anim=mc_anims.jump
 	else
 		mc.anim=mc_anims.fall
 	end
 else 	
		if mc.inp.x==0 then
			mc.anim=mc_anims.idle
		else
			if mc.gun~=nil then
				mc.anim=mc_anims.walk
			else
				mc.anim=mc_anims.sprint
			end
			mc.anim_t+=mc.anim.dt
		end
	end
end

function play_draw()
	cls()
	
	camera(mid(mc.x*8-64,0,256),0)
	local level_map=function(layer)
		map(level.x,level.y,
			64-level.w*4,64-level.h*4,
			level.w,level.h,
			layer)
	end
	
	map(level.x,level.y,0,0,level.w,level.h,127)
	local px,py=w2s(mc.x,mc.y)
	
	mc_draw(mc)
	
	draw_colliders()

	camera()
	
	draw_watch()
	draw_log()
end

function mc_draw(mc)
	local sx,sy=w2s(mc.x,mc.y)
	local sp=mc.anim.base+(mc.anim_t%1)*mc.anim.frames
	spr(sp,sx-4,sy-16,1,2,mc.face<0)
	if mc.gun then
		spr(mc.gun.sp,sx-4,sy-10,1,1,mc.face<0)
	end
end
-->8
-- actors

function make_inp(p)
	local p=p or {}
	return {x=p.x or 0,y=p.y or 0,btns=p.btns or 0}
end

function make_flags(tbl)
	local flags={}
	flags["none"]=0
	for i,v in ipairs(tbl) do
		assert(type(v)=="string")
		flags[v]=shl(1,i-1)
	end
	return flags
end

-- actor flags
af=make_flags({
	"grounded","platdrop","dead"
})

actor={
	x=0,y=0,					-- position
	dx=0,dy=0,			-- velocity
	pushx=0,pushy=0,
	ddx=0,ddy=20,	-- acceleration
	w=0.2,h=0.5, -- half width/height
	sp=1,
	face=1,
	flags=af.none,
	jumps=0,
	t_air=0,
	t_jump_hold=0,
	t_plat_drop=0,
	k_accel=64,
	k_coldst=0.3, -- collision check distance
	k_scndst=0.1, -- scan distance while searching for contact point
	k_bounce_wall=0,
	k_bounce_floor=0,
	k_jump_force=24,
	k_max_move=8,
	k_jump_forgive_t=5/60,
	k_jump_hold_t=1/2,
	k_jump_hold_force=1,
	k_jump_hold_delay=0.0833,
	k_plat_drop_t=0.1
}

function actor:kill()
	if not self:getf(af.dead) then
		self:setf(af.dead,true)
		self:on_death()
	end
end

function actor:jump(force)
	force=force or self.k_jump_force
	self.dy=-force
end

function actor:on_wall() end
function actor:on_death() end

function actor:move(dt)
	-- apply inputs
	local accel=self.k_accel*dt
	if not self:getf(af.grounded) then
		accel=shr(accel,1)
	end
		
	local stand=self:getf(af.grounded)
	if (self.t_plat_drop>0) self.t_plat_drop-=dt
	if self.inp.y>0 then
		self.t_plat_drop=self.k_plat_drop_t
	end

	if sgn(self.inp.x)~=sgn(self.dx) then
		accel*=2
	end

	if self.inp.x<0 then
		self.dx-=accel
		self.face=-1
	elseif self.inp.x>0 then
		self.dx+=accel
		self.face=1
	else
		local a=accel
		if (not stand) a/=2
		self.dx=moveto(self.dx,0,a)
	end
 
	if stand then	
		self.jumps=0
	end
	
	local canjump=stand
		or self.jumps<0
		or (not stand
						and self.t_air<self.k_jump_forgive_t)

	canjump=canjump and not self:getf(af.dead)
	canjump=canjump and
		not solid(self.x,self.y-0.5)
		
	local jumpreq=band(self.inp.btns,1)~=0
	local jumphold=band(self.inp.btns,4)~=0
		
	if jumpreq and canjump then
		self:jump()
		self.jumps+=1
	end
	
	if not stand
		and jumphold
		and self.t_jump_hold<self.k_jump_hold_t+self.k_jump_hold_delay
	then
		self.t_jump_hold+=dt
		if self.t_jump_hold>=self.k_jump_hold_delay then
			self.dy-=self.k_jump_hold_force*dt
		end
	elseif stand then
		self.t_jump_hold=0
	end

	-- do physics
	self:setf(af.grounded,false)
	
	self.dx+=self.ddx*dt
	self.dy+=self.ddy*dt
	
	local max_x,max_y=
		self.k_max_move,30
	self.dx=mid(self.dx,-max_x,max_x)
	self.dy=mid(self.dy,-max_y,max_y)
	
	local fdx,fdy=self.dx*dt,
		self.dy*dt
	
	local tdx=fdx+self.pushx
	local dirx=sgn(tdx)
	
	-- x movement
	local nx=self.x+
		tdx+dirx*self.k_coldst
				
	if not solid(nx,self.y-self.h) then
		-- no contact, move normally
		self.x+=tdx
	else
		-- hit solid
		-- find contact point
		while not solid(
			self.x+dirx*self.k_coldst,
			self.y-self.h)
		do
			self.x+=dirx*self.k_scndst
		end
		
		-- bounce
		if sgn(self.pushx)==0 or sgn(self.dx)==sgn(self.pushx) then
			self.dx*=-self.k_bounce_wall
		end
		
		self:on_wall()
	end

	-- y movement	
	local left,right=
		self.x-self.w,self.x+self.w

	if fdy<0 then
		-- going up
		if solid(left,self.y+fdy-self.h) or
			solid(right,self.y+fdy-self.h)
		then
			-- hit ceiling
			self.dy=0
			
			-- search contact point
			while not solid(left,self.y-self.h)
				and not solid(right,self.y-self.h)
			do
				self.y-=0.01
			end
		else
			self.y+=fdy
		end
	else
		-- going down
		
		local is_solid=nil
		if self.t_plat_drop<=0
		then
			is_solid=platform_solid
		else
			is_solid=blocked_platform_solid
		end
	
		if is_solid(left,self.y+fdy)
			or is_solid(right,self.y+fdy)
		then
			-- bounce
			if self.k_bounce_floor>0 and
				fdy>0.2*60
			then
				self.dy*=-self.k_bounce_floor
			else
				self:setf(af.grounded,true)
				self.dy=0
			end
			
			-- snap down
			while not is_solid(left,self.y)
				and not is_solid(right,self.y)
			do
				self.y+=0.05
			end

			-- pop up
			local count=5
			while 
				(is_solid(left,self.y-0.1)
					or is_solid(right,self.y-0.1))
				and not is_solid(left,self.y-0.5)
				and not is_solid(right,self.y-0.5)
			do
				self.y-=0.05
				count+=1
			end
--[[			while solidfn(right,self.y-0.1)
			do
				self.y-=0.05
			end]]
		else
			self.y+=fdy
		end
	end
	
	if self:getf(af.grounded) then
		self.t_air=0
	else
		self.t_air+=dt
	end
	
	local shootreq=band(self.inp.btns,2)~=0

	if shootreq then
		add_article(bullet:new({
			x=self.x,y=self.y-0.5,
			dx=self.face*12}))
	end
	
	self.pushx=0
	self.pushy=0
end

function actor:new(p)
	self.__index=self
	p=p or {}
	p.inp=p.inp or {x=0,y=0,btns=0}
	return setmetatable(p,self)
end

function actor:setf(f,v)
	if v then
		self.flags=bor(self.flags,f)
	else
		self.flags=band(self.flags,
			bnot(f))
	end
	return self.flags
end

function actor:getf(f)
	return band(self.flags,f)~=0
end

function actor:left() return self.x-self.w end
function actor:right() return self.x+self.w end
function actor:top() return self.y-self.h end
function actor:bottom() return self.y end

function actor:overlap(other)
	return self:left()<=other:right()
		and self:right()>=other:left()
		and self:top()<=other:bottom()
		and self:bottom()>=other:top()
end

function init_actors()
	actors={}
end

function add_actor(p)
	return add(actors,actor:new(p))
end
-->8
-- physics

function w2s(wx,wy)
	return wx*8,wy*8
end

function w2si(wx,wy)
	local sx,sy=w2s(wx,wy)
	return flr(sx),flr(sy)
end

function solid(wx,wy)
	-- todo: other things
	return map_solid(wx,wy)
end

-- is world coord: wx,wy solid
-- 1 world unit == 8 pixels
function map_solid(wx,wy)
	--return fget(mget(wx,wy),0)
	local val=mget(wx,wy)
	if fget(val,0) then
		if fget(val,4) then
			-- slope
			local l,r=flr(wx),ceil(wx)
			local t,b=flr(wy),ceil(wy)
			local nx,ny=wx-l,wy-t
			local flipx=fget(val,5)
			local flipy=fget(val,6)
			local chx,chy
			if flipx then
				if flipy then
					return nx<(0.875-ny)
				else
					return nx<=ny
				end
			else
				if flipy then
					return nx>=ny
				else
					return nx>(0.875-ny)
				end
			end
		elseif fget(val,2) then
		else
			return true
		end
	end
	return false
end

function platform_solid(wx,wy)
	local ret=solid(wx,wy)
	local val=mget(wx,wy)
	if fget(val,2) then
		return wy-flr(wy)<0.5
	end
	return ret
end

function blocked_platform_solid(wx,wy)
	local ret=solid(wx,wy)
	local val=mget(wx,wy)
	if fget(val,2) and fget(val,6) then
		return wy-flr(wy)<0.5
	end
	return ret
end

colldr={
	parent=nil,
	x=0,y=0,
	w=0,h=0,
}

colliders={}

function colldr:new(p)
	self.__index=self
	local c=
		setmetatable(p or {},self)
	return add(colliders,c)
end

function colldr:kill()
	del(colliders,self)
end

function colldr:parent_xy()
	if self.parent then
		return self.parent.x,
			self.parent.y
	end
	return 0,0
end

function colldr:bounds()
	local x,y=self:parent_xy()
	return
		x+(self.x-self.w),
		y+(self.y-self.h),
		x+(self.x+self.w),
		y+(self.y+self.h)
end

function draw_colliders()
	for i,c in ipairs(colliders) do
		local x0,y0,x1,y1=c:bounds()
		local sx0,sy0=w2s(x0,y0)
		local sx1,sy1=w2s(x1,y1)
		rect(sx0,sy0,sx1-1,sy1-1,10)
	end
end
-->8
-- utils

_sgn=sgn
function sgn(v)
	if (v==0) return 0
	return _sgn(v)
end

function moveto(a,b,d)
	if abs(b-a)<=d then
		return b
	else
		return a+sgn(b-a)*d
	end
end

_watches={}

function watch(msg,col)
	add(_watches,{msg=tostr(msg),
		col=col or 12})
end

function draw_watch(col)
	col=col or 12
	local n=#_watches
	for i=0,n-1 do
		local w=_watches[i+1]
		print(w.msg,0,i*6,w.col)
	end
	_watches={}
end

_logs={}

function log(msg,col)
	add(_logs,{msg=tostr(msg),col=col or 6})
	local n=#_logs
	if n>20 then
		for i=2,n do
			_logs[i-1]=_logs[i]
		end
		_logs[n]=nil
	end
end

function draw_log()
	local n=#_logs
	for i=1,n do
		local l=_logs[i]
		print(l.msg,127-#l.msg*4,(i-1)*6,l.col)
	end
end

function clone(o,m)
	local ret={}
	for k,v in pairs(o) do
		ret[k]=v
	end
	m=m or {}
	for k,v in pairs(m) do
		ret[k]=v
	end
	return ret
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
-- 	to subsequent calls
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

function moveto_angle(a,b,d)
	local dl=angle_diff(a,b)
	if -d<dl and dl<d then
		return b
	else
		return moveto(a,a+dl,d)
	end
end

function lerp(a,b,t)
	return (b-a)*t+a
end

function dist(x1,y1,x2,y2)
	return sqrt(dist2(x1,y1,x2,y2))
end

function dist2(x1,y1,x2,y2)
	local dx,dy=(x2-x1),(y2-y1)
	return dx*dx+dy*dy
end

function round(x)
 return flr(x+0.5)
end

function set(a,b)
	a=a or {}
	b=b or {}
	for k,v in pairs(b) do
		a[k]=v
	end
	return a
end

function class(clob)
	clob=clob or {}
	setmetatable(clob,
		{__index=clob.extends})
	clob.new=function(self,ob)
		ob=set(ob,{class=clob})
		setmetatable(ob,{__index=clob})
		if (clob.create) clob:create()
		return ob
	end
	return clob
end

function blink(ivl,tt)
	tt=tt or t()
	return tt%(ivl*4)<ivl*2
end
-->8
article={
	x=0,y=0,
	coll=colldr:new({
		x=0,y=0,
		w=0,h=0
	})
}

function init_articles()
	articles={}
end

function article:new(p)
	self.__index=self
	return setmetatable(
		p or {},self)
end

function add_article(a)
	return add(articles,a)
end

bullet={
	
}

__gfx__
00000000000000000000000000000000000000000000000000000000000000009999999999999999000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000009999999999999999000000000000000000000000000000000000000000000000
007007000000000000000000000000000000000000000000000000000000000099999999000000000000c000000000c00000000c000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000009999999900000000666666650066666066666666000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000009999999900000000666666660006500066065556000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000009999999900000000660066600006000060060000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000009999999900000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000009999999900000000000000000000000000000000000000000000000000000000
000bbb000bbbbbbb0bbbbbbb0bbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bbbbbb3bbbaaaa3bbbaaaa3bbbaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbbaaa03bbbaaaa3bbbaaaa3bbbaaaa0000c000000000c00000000c000000000000000000000000000000000000000000000000000000000000000000000000
0bbbaaa03bbbbaaa3bbbbaaa3bbbbaaa666666650066666066666666000000000000000000000000000000000000000000000000000000000000000000000000
0bbbbbb0033bbbbb033bbbbb033bbbbb666666660006500066065556000000000000000000000000000000000000000000000000000000000000000000000000
003bbbb00b3333300b3333300b333330660066600006000060060000000000000000000000000000000000000000000000000000000000000000000000000000
003333300bbbbbb00bbbbbb00bbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00330330b00000b0b000000b0b00000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bbb30000bbb30000bbb30000bbb30000bbb30000bbb30000bbb30000bbb30000bbb30000bbb30000bbb3000000000000000000000000000000000000000000
0bbbbb300bbbbb300bbbbb300bbbbb300bbbbb300bbbbb300bbbbb300bbbbb300bbbbb300bbbbb300bbbbb300000000000000000000000000000000000000000
bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb30000000000000000000000000000000000000000
bb9aaaa0bb9aaaa0bb9aaaa0bb9aaaa0bb9aaaa0bb9aaaa0bb9aaaa0bb9aaaa0bb9aaaa0bb9aaaa0bb9aaaa00000000000000000000000000000000000000000
bb9aaaa0bb9aaaa0bb9aaaa0bb9aaaa0bb9aaaa0bb9aaaa0bb9aaaa0bb9aaaa0bb9aaaa0bb9aaaa0bb9aaaa00000000000000000000000000000000000000000
bbb99ab0bbb99ab0bbb99ab0bbb99ab0bbb99ab0bbb99ab0bbb99ab0bbb99ab0bbb99ab0bbb99ab0bbb99ab00000000000000000000000000000000000000000
0bbbbbb00bbbbbb00bbbbbb00bbbbbb00bbbbbb00bbbbbb00bbbbbb00bbbbbb00bbbbbb00bbbbbb00bbbbbb00000000000000000000000000000000000000000
00bbbb0000bbbb0000bbbb0000bbbb0000bbbb0000bbbb0000bbbb0000bbbb0000bbbb0000bbbb0000bbbb000000000000000000000000000000000000000000
03333330033333300333333003333330033333300333333003333330033333300333333003333330333333300000000000000000000000000000000000000000
bb33333bbb3333bbbb3333bbbb3333bbbb3333bbbbbb333bbb3333bbbb33333b0bb33330bb33333bbb33333b0000000000000000000000000000000000000000
bbbb333bbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb333bbbbb33bbbbbb333b0bbbb330bbbb333bbb33333b0000000000000000000000000000000000000000
0bbb33300bbb33300bbb33300bbb33300bbb3330033333300bbb33300bbb333003bbb3300bbb33300bb333bb0000000000000000000000000000000000000000
033333300333333003333330033333300333333003333bb0033333300333333003333330033333300bb333bb0000000000000000000000000000000000000000
0333033003330bb0033303300bb30330033303300bb30bb00333033003330bb0033303300bb30330033303300000000000000000000000000000000000000000
0bb00bb00bb00bb0bb000bb00bb0bb0000bbbb000bb0000000bb0bb00bb00bb0bb000bb00bb0bb0000bbbb000000000000000000000000000000000000000000
0bb00bb00bb00000bb000bb00000bb0000bbbb000000000000bb0bb00bb00000bb000bb00000bb0000bbbb000000000000000000000000000000000000000000
00bbb30000bbb30000bbb30000bbb300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbbbb300bbbbb300bbbbb300bbbbb30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb9aaaa0bb9aaaa0bb9aaaa0bb9aaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb9aaaa0bb9aaaa0bb9aaaa0bb9aaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb99ab0bbb99ab0bbb99ab0bbb99ab0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbbbbb00bbbbbb00bbbbbb00bbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bbbb0000bbbb0000bbbb0000bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03333330033333300333333033333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb33333b0bb33330bb33333bbb33333b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbb333b0bbbb330bbbb333bbb33333b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbb333003bbb3300bbb33300bb333bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0333333003333330033333300bb333bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03330bb0033303300bb3033003330330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bb00bb0bb000bb00bb0bb0000bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bb00000bb000bb00000bb0000bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000010500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0808080808080808080808080808080808080808080808080808080808080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000080800000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000808080909090908080000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000008080800000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000080000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080808080808080808080808080808080808080808080808080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
