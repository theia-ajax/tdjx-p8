pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

function _init()
	init_light_palettes()
	reset()
end

function reset()
	jk_init()

	actors={}
	
	local add_actor=function(p)
		return add(actors,
			actor:new(p))
	end

	player=add_actor({
		x=8,y=15,
		keys={},
		ddy=1,
		k_accel=30,
		k_max_move=4,
		k_jump_force=14,
		k_jump_hold_force=0,
	})
	
	for xx=0,127 do
		for yy=0,63 do
			local m=mget(xx,yy)
			if not _entity_map[m] and fget(m,3) then
				add_actor({
					x=xx+0.5,y=yy+1,sp=m,
					k_max_move=4,
					k_accel=30,
   		k_max_move=4,
					inp={x=1,y=0,bx=false,by=false},
					on_wall=function(self)
						self.inp.x=-self.inp.x
					end})
				mset(xx,yy,0)
			end
		end
	end
	
	init_entities(0,0,16,16)
	init_articles()
end

--function _update() dt=1/30; update(dt) end
function _update60() dt=1/60; update(dt) end

function update(dt)
	jk_update()
	
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
	
	if player:getf(af.dead) then
		if bts[1] then reset() end
	end
	
	if not player:getf(af.dead) then
 	player.inp.x=ix
 	player.inp.y=iy
 	player.inp.btns=bt
 else
 	player.inp.x=0
 	player.inp.y=0
 	player.inp.btns=0
 end
 
	tick_entities(dt)
	update_articles(dt)
	
	foreach(actors,function(a)
		a:move(dt)
	end)
		
	watch("pos:"..player.x..","..player.y)
	watch("vel:"..player.dx/dt..","..player.dy/dt)
	watch("fps:"..stat(7))
	watch("cpu:"..band(stat(1)*100,0xffff).."%")
end

function _draw()
	cls(5)
	
	map(0,0,0,0,16,16,127)
	
	foreach(actors,function(a)
 	local sx,sy=w2s(a.x,a.y)
 	local sp=a.sp
 	if a:getf(af.dead) then
 		sp+=16
 	end
 	
 	spr(sp,sx-4,sy-8,1,1,a.face<0)
--[[ 	rect(sx-a.w*8,sy-a.h*8,
 		sx+a.w*8,sy,11)
 	pset(sx,sy,8)]]
 end)
 
 draw_articles()
 
 map(0,0,0,0,16,16,128)
 
 
 
 local conew=1/6
 local hcw=conew/2
 local conesz=48
 local wx,wy=w2s(player.x,player.y)
 wx,wy=flr(wx),flr(wy-4)
--[[ 
 ]]
	
	if band(player.inp.btns,0x8)~=0 then
		local ang=player.look_r
		light_circ(wx,wy,conesz,-hcw+ang,hcw+ang)
	else
		if player.face>0 then
		 light_circ(wx,wy,conesz,-hcw,hcw)
		else
			light_circ(wx,wy,conesz,-hcw+.5,hcw+.5)
		end
	end
 
-- draw_entity_colliders()
	
	draw_log()
	draw_watch()
end
-->8
-- actors

-- actor flags
af={
	grounded=shl(1,0),
	platdrop=shl(1,1),
	dead=shl(1,2),
}

actor={
	x=0,y=0,					-- position
	dx=0,dy=0,			-- velocity
	ddx=0,ddy=2,	-- acceleration
	w=0.2,h=0.5, -- half width/height
	sp=1,
	face=1,
	flags=0,
	jumps=0,
	mass=1,
	drag=0,
	look_r=0,
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
	k_jump_hold_delay=5/60,
	k_plat_drop_t=4/60
}

function actor:premove()
end

function actor:postmove()
end

function actor:kill()
	self:setf(af.dead,true)
end

function actor:jump(force)
	force=force or self.k_jump_force
	local f=min(force*dt,1)
	self.dy=-f
end

function actor:force(fx,fy)
	local m=max(self.mass,0.01)
	self.dx+=fx/m*dt
	self.dy+=fy/m*dt
end

function actor:friction(fx,fy)
	fx=mid(fx,0,1)
	fy=mid(fy,0,1)
	self.dx=self.dx*(1-fx)
	self.dy=self.dy*(1-fy)
end

function actor:linfric(fx,fy)
	self.dx=moveto(self.dx,0,fx*dt)
	self.dy=moveto(self.dy,0,fy*dt)
end

function actor:control(dt)
	
end

function actor:on_wall() end

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
	
	local lockpos=band(self.inp.btns,0x8)~=0
	
	if lockpos then
		if self.inp.x<0 then
			self.face=-1
		elseif self.inp.x>0 then
			self.face=1
		end
		local a=accel
		if (not stand) a/=2
		self.dx=moveto(self.dx,0,a*dt)
		if self.inp.x==0 and self.inp.y==0 then
			if self.face>0 then
				self.look_r=0
			else
				self.look_r=0.5
			end
		else
			self.look_r=atan2(self.inp.x,self.inp.y)
		end
	else
 	if self.inp.x<0 then
 		self.dx-=accel*dt
 		self.face=-1
 		self.look_r=0
 	elseif self.inp.x>0 then
 		self.dx+=accel*dt
 		self.face=1
 		self.look_r=0.5
 	else
 		local a=accel
 		if (not stand) a/=2
 		self.dx=moveto(self.dx,0,a*dt)
 	end
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
		--player:force(0,-18)
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
		self.k_max_move*dt,30*dt
	self.dx=mid(self.dx,-max_x,max_x)
	self.dy=mid(self.dy,-max_y,max_y)
	
	-- x movement
	local nx=self.x+
		self.dx+sgn(self.dx)*self.k_coldst
		
	if map_kill(nx,self.y-self.h)
	then
		self:kill()
	end
		
	if not solid(nx,self.y-self.h) then
		-- no contact, move normally
		self.x+=self.dx
	else
		-- hit solid
		-- find contact point
		while not solid(
			self.x+sgn(self.dx)*self.k_coldst,
			self.y-0.5)
		do
			self.x+=sgn(self.dx)*self.k_scndst
		end
		
		-- bounce
		self.dx*=-self.k_bounce_wall
		
		self:on_wall()
	end

	-- y movement	
	local left,right=
		self.x-self.w,self.x+self.w

	if self.dy<0 then
		if map_kill(left,self.y+self.dy-1) or
			map_kill(right,self.y+self.dy-1)
		then
			self:kill()
		end
	
		-- going up
		if solid(left,self.y+self.dy-1) or
			solid(right,self.y+self.dy-1)
		then
			-- hit ceiling
			self.dy=0
			
			-- search contact point
			while not solid(left,self.y-1)
				and not solid(right,self.y-1)
			do
				self.y-=0.01
			end
		else
			self.y+=self.dy
		end
	else
		-- going down
	
		if map_kill(left,self.y+self.dy) or
			map_kill(right,self.y+self.dy)
		then
			self:kill()
		end
		
		local is_solid=nil
		if self.t_plat_drop<=0
		then
			is_solid=platform_solid
		else
			is_solid=blocked_platform_solid
		end
	
		if is_solid(left,self.y+self.dy)
			or is_solid(right,self.y+self.dy)
		then
			-- bounce
			if self.k_bounce_floor>0 and
				self.dy>0.2
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
				and not is_solid(left,self.y-0.25)
				and not is_solid(right,self.y-0.25)
			do
				self.y-=0.05
				count+=1
			end
--[[			while solidfn(right,self.y-0.1)
			do
				self.y-=0.05
			end]]
		else
			self.y+=self.dy
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


function jk_init()
	_jk_btns={}
	for i=0,5 do
		_jk_btns[i]={
 		last={},
 		curr={},
 	}
	end
end

function jk_update()
	_watches={}

	for p=0,5 do
		local pl=_jk_btns[p]
		for b=0,5 do
			pl.last[b]=pl.curr[b] or false
			pl.curr[b]=btn(b,p)
		end
	end
end

_btnp=btnp
function btnp(b,p)
	p=p or 0
	local pl=_jk_btns[p]
	return pl.curr[b] and not pl.last[b]
end

function btnr(b,p)
	p=p or 0
	local pl=_jk_btns[p]
	return not pl.curr[b] and pl.last[b]
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
-->8
-- physics

function w2s(wx,wy)
	-- todo: camera
	return wx*8,wy*8
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
			if not flipx then	
				return nx>(1-ny)
			else
				return nx<=ny
			end
			return false
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
		return wy-flr(wy)<0.25
	end
	return ret
end

function blocked_platform_solid(wx,wy)
	local ret=solid(wx,wy)
	local val=mget(wx,wy)
	if fget(val,2) and fget(val,6) then
		return wy-flr(wy)<0.25
	end
	return ret
end

function map_kill(wx,wy)
	return fget(mget(wx,wy),1)
end
-->8
-- entity

entity={
	x=0,y=0,val=0,
	wx=0,wy=0,
	w=0.5,h=0.5,
}

function entity:new(p)
	self.__index=self
	return setmetatable(p or {},self)
end

function entity:left()
	return self.wx-self.w
end

function entity:right()
	return self.wx+self.w
end

function entity:top()
	return self.wy-self.h
end

function entity:bottom() 
	return self.wy+self.h
end

function entity:center()
	return self.x+0.5,self.y+0.5
end

function entity:start(self) end
function	entity:tick(self,dt) end
--function	entity:actor_touch(a) end

switch_block=entity:new({
	name="switch_block",
	start=function(self)
		self.ivl=self.ivl or 1
		self.t0=self.ivl
		self.frame=0
		self.base=self.val
		if self.on then
			self.frame=1
			self.base-=1
		end
	end,
	tick=function(self,dt)
		self.t0-=dt
		if self.t0<=0 then
			self.t0+=self.ivl
			self.frame=(self.frame+1)%2
			mset(self.x,self.y,self.base+self.frame)
		end
	end
})

spring=entity:new({
	name="spring",
	ivl=1,
	force=19,
	w=0.125,
	h=0.25,
	start=function(self)
		self.t0=0
		self.sp=self.val
		self.wx=self.x+0.5
		self.wy=self.y+0.75
	end,
	tick=function(self,dt)
		if (self.t0>0) self.t0-=dt
		if self.t0>0.5 then
			mset(self.x,self.y,self.sp+1)			
		else
			mset(self.x,self.y,self.sp)
		end
	end,
	actor_touch=function(self,a)
		if self.t0<=0 then
			a:jump(self.force)
			self.t0=self.ivl
		end
	end,
})

key_door=entity:new({
	name="key_door",
	tdoor=0,
	closed=true,
	w=0.75,
	start=function(self)
		local f=fget(self.val)
		if band(f,1)~=0 then
			closed=false
		end
		f=band(f,0x60)
		f=shr(f,5)
		self.tdoor=f
		self.wx,self.wy=self:center()
	end,
	actor_touch=function(self,a)
		if self.closed then
			local k=a.keys or {}
			if k[self.tdoor] then
				self.closed=false
				mset(self.x,self.y,self.val-self.tdoor-1)
			end
		end
	end
})

door_key=entity:new({
	name="door_key",
	tdoor=0,
	taken=false,
	w=0.4,
	h=0.2,
	start=function(self)
		self.tdoor=shr(band(fget(self.val),0x60),5)
		self.wx,self.wy=self:center()
	end,
	actor_touch=function(self,a)
		if a.keys and not self.taken then
			self.taken=true
			a.keys[self.tdoor]=true
			mset(self.x,self.y,0)
		end
	end
})

_entity_map={}
_entity_map[7]=switch_block
_entity_map[8]=clone(switch_block,{on=true})
_entity_map[23]=switch_block
_entity_map[24]=clone(switch_block,{on=true})
_entity_map[19]=spring

for i=0,3 do
 _entity_map[26+i]=key_door
 _entity_map[42+i]=door_key
end

function init_entities(x,y,w,h)
	entities={}
	for xx=x,x+w-1 do
		for yy=y,y+h-1 do
			local val=mget(xx,yy)
			local entdef=_entity_map[val]
			if entdef then
				local def=clone(entdef)
				def.x=xx
				def.y=yy
				def.val=val
				local ent=add(entities,entity:new(def))
				ent:start()
			end
		end
	end
end

function tick_entities(dt)
	for e in all(entities) do
		e:tick(dt)
		if e.actor_touch then
			for a in all(actors) do
				if a:overlap(e) then
					e:actor_touch(a)
			 end
			end
		end
	end
end

function draw_entity_colliders()
	for e in all(entities) do
		if e.actor_touch then
 		local l,r,t,b=
 			e:left(),e:right(),
 			e:top(),e:bottom()
 		local tlx,tly=w2s(l,t)
 		local brx,bry=w2s(r,b)
 		rect(tlx,tly,brx,bry,11)
 	end
	end
end
-->8
-- articles

article={
	id=0,
	x=0,y=0,
	dx=0,dy=0,
	w=0.5,h=0.5,
	dead=false,
}

function article:new(p)
	self.__index=self
	return setmetatable(p or {},self)
end

function article:update(dt)
	self.x+=self.dx*dt
	self.y+=self.dy*dt
end

function article:draw()end

bullet=article:new({
	t_life=0.5,
})

function bullet:update(dt)
	article.update(self,dt)
	
	if self.t_life>0 then
		self.t_life-=dt
		if self.t_life<=0 then
			self.dead=true
		end
	end
end

function bullet:draw()
	local wx,wy=w2s(self.x,self.y)
	circfill(wx,wy,1,10)
end

-- article manager
function init_articles()
	articles={}
	article_id=0
end

function add_article(a)
	a.id=article_id
	article_id+=1
	return add(articles,a)
end

function update_articles(dt)
	foreach(articles,
		function(a)
			a:update(dt)
			if a.dead then
				del(articles,a)
			end
		end)
end

function draw_articles()
	foreach(articles,
		function(a) a:draw() end)
end
-->8
function init_light_palettes()
	load_palette(14,0)
	load_palette(15,1)
end

-- 1 palette
-- 256 bytes per light level
-- 8 light levels
-- 2048 bytes
-- 3 palettes fit in 0x4300 space
function palette_adr(pi)
	return 0x4300+(pi or 0)*0x800
end

-- sp: sprite to load palette from
-- reads two sprites vertically
-- pi: palette index to write to
--	[0,2]
function load_palette(sp,pi)
	paladr=palette_adr(pi)
	
	local sx=(sp%16)*8
	local sy=flr(sp/16)*8
	
	for li=0,7 do
		for l=0,15 do
			local lc=sget(sx+li,l+sy)
			for r=0,15 do
				local adr=paladr+li*0x100+l*0x10+r
				local rc=sget(sx+li,r+sy)
				local byte=bor(shl(lc,4),rc)
				poke(adr,byte)
			end
		end
	end
end

function palette_value(pi,val,li)
	return peek(
		palette_adr(pi)+val*8+li)
end

_ll_tbl={
	0,0,0,0,0,0,0,0,
	0,0,0,0,1,1,1,1,
	1,1,1,1,2,2,2,2,
	3,3,3,4,4,4,5,5,
}

function in_arc1(ang,a0,a1)
	return ang>=a0 and ang<=a1
end

function in_arc2(ang,a0,a1)
	return ang>=a0 or ang<=a1
end

function light_hline(y,lx,ly,rad,x1,x2,arc0,arc1,inarcfn)
	local r2=rad*rad
	local pi=0
	local l,r=flr(x1/2),flr(x2/2)
	local dy=y-ly
	local dy2=dy*dy
	
	-- todo: fix odd values
	-- at edges
--[[	if x1%2==0 then
		local dx=x1-lx
		local d=dx*dx+dy2
		local li=min(flr(d/r2*32),31)
		local ll=_ll_tbl[li+1]
		local addr=0x6000+y*64+max(l-1,0)
		local prev=peek(addr)
		
		local scradr=bor(0x6000,y*64+l)
		local paladr=bor(0x4300+pi*0x800+
			ll*0x100,peek(scradr))	
		poke(addr,bor(band(prev,0xf),
			band(peek(paladr),0xf0)))
	end]]
	
	for x=l,r do
		local dx=(x*2)-lx
		local d=dx*dx+dy2
		local ll=6
		local ang=atan2(dx,dy)
		if inarcfn(ang,arc0,arc1)  then
			local li=min(flr(d/r2*32),31)
			ll=_ll_tbl[li+1]	
		elseif d<=256 then
			local li=min(flr(d/256*32),31)
			ll=_ll_tbl[li+1]
		end

		local scradr=bor(0x6000,y*64+x)
		local paladr=bor(0x4300+pi*0x800+
			ll*0x100,peek(scradr))
		poke(scradr,peek(paladr))		
	end
end


function light_circ(lx,ly,ldist,arc0,arc1)
	lrx=ldist
	arc0=(arc0%1) or 0
	arc1=(arc1%1) or 1

	local tarc,barc

	local inarc=in_arc1
	if (arc1<arc0) inarc=in_arc2

	local td0,td1=abs(.25-arc0),
		abs(.25-arc1)
	local bd0,bd1=abs(.75-arc0),
		abs(.75-arc1)
	
	local aaa=(arc1+arc0)/2
	if abs(angle_diff(aaa,.25))<0.01 then
		tarc=.25
		barc=arc0
	elseif abs(angle_diff(aaa,.75))<0.01 then
		tarc=arc0
		barc=.75
	else
		local y0=sin(arc0)
		local y1=sin(arc1)
		if y0<y1 then
			tarc=arc0
			barc=arc1
		else
			tarc=arc1
			barc=arc0
		end
	end
	
	local ltop=mid(0,min(ly-16,ly+flr(sin(tarc)*ldist)),127)
	local lbot=mid(127,max(ly+16,ly+flr(sin(barc)*ldist)),0)
	
	if ltop>0 then
		memset(0x6000,0,ltop*64)
	end
	
	if lbot<127 then
		memset(bor(0x6000,(lbot+1)*64),
			0,(127-lbot)*64)
	end
	
	local l,r=max(lx-lrx,0),min(lx+lrx,127)
	
	for y=ltop,lbot do
		light_hline(y,lx,ly,ldist,l,r,arc0,arc1,inarc)
		
		local sladr=bor(0x6000,y*64)
		if l>0 then
			memset(sladr,0,flr(l/2))
		end
		if r<127 then
			local ro2=flr(r/2)
			memset(sladr+ro2,0,64-ro2)
		end
	end
end
-->8
-- todo/notes

-- story:
-- 	
__gfx__
000000000eeeeee09999999900000009900000009999999999999999999999994444444499999999808080800088008866666666000000000000000000000000
00000000ebbbbbb09999999900000099990000000999999999999990999999994444444499999999088888880088008866666666000000001110000011000000
00700700ebbb1b10999999990000099999900000009999999999990099999999444444440000000088eeee808800880000000000000000002211000021100000
00077000ebbbbbb0999999990000999999990000000999999999900099949999444944440000000008eeee888800880000000000000000003331100033110000
00077000ebbbbbbe999999990009999999999000000099999999000099994999444494440000000088eeee800088008800000000000000004221100044221000
00700700ebbbbbbe999999990099999999999900000009999990000099999999444444440000000008eeee880088008800000000000000005511100055110000
00000000ebbbbbbe99999999099999999999999000000099990000009999999944444444000000008888888088008800000000000000000066d5100066dd5100
000000000eeeeee0999999999999999999999999000000099000000099999999444444440000000008080808880088000000000000000000776d100077776d51
0cc000000000ddd09000000900000000000000000000000000000000999999999999999999999999999999999999999999999999999999998822100088842100
0ccc0000d656666d9000000900000000099999900000000000000000900000099888888990000009999cc99999988999999bb999999229999422100099942100
0cccccc0d666666d900000090000000000099000000000000000000090000009988888899000000999c99c999989989999b99b9999299299a9421000aa994210
0ccdddd0d656666d90000009000000000009900000000000000000009000000998888889900000099cccccc9988888899bbbbbb992222229bb331000bbb33100
cccdedecd666666d90000009000000000009900000000000000000009000000998888889900000099cc99cc9988998899bb99bb992299229ccd51000ccdd5100
cccdccccd666666d90000009000000000009900000000000000000009000000998888889900000099cc99cc9988998899bb99bb992299229dd511000dd511000
cccddcdcd666666d90000009099999900009900000000000000000009000000998888889900000099cccccc9988888899bbbbbb992222229ee421000ee444210
0cccccc00dddddd0900000090009900000099000000000000000000099999999999999999999999999999999999999999999999999999999f9421000fff94210
00005550003bbb300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000555003bb9aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0056256503bbb9a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00566555003b333000000000000000000000000000000000000000000000000000000000000000000cccccc0088888800bbbbbb0022222200000000000000000
0056256503bbb66000000000000000000000000000000000000000000000000000000000000000000cc0c0c0088080800bb0b0b0022020200000000000000000
005666650366666600000000000000000000000000000000000000000000000000000000000000000000ccc0000088800000bbb0000022200000000000000000
055556650bb566500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5505555503b003b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000035435b3b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000b44355b30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000054b335500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000333353300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000535335530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000055055530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000011131517109080503824500000008008088804000888a8089a9c9e900000000000000000000000088a8c8e800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0215151515151515151515151515150200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202151515151515151515150200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0215151502151515151515151510150200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
021515151a151515151515030909090200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020c0c021515150200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0215151517151815171513021513150200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0209090902020202020902021509150200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
021515151515150a0a1515121515150200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0215131515151015151515121515130200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020b020807080209090202020c02020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0215151515151515151515151515150200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0215151515151515151515151315150200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0215151515151515151515150209090200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020202020202152a2b2c2d151200030200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02001a1b1c1d1515151515151203020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
