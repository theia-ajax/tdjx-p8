pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
#include util.p8

k_pit=48

-- x and y are constrained
-- to map coordinates
-- so we can happily
-- store them in 8 bits
-- 4 each
function hash_xy(x,y)
	return bor(shl(x or 0,4),y or 0)
end

function unhash_xy(h)
	return shr(band(h,0xf0),4),
		band(h,0xf)
end

entity=class({
	etype="entity",
	x=0,y=0,w=4,h=4,
})

player=class({
	extends=entity,
	etype="player",
	cx=0,cy=2,cw=3,ch=2,
	w=4,
	id=0,
})

bullet=class({
	extends=entity,
	etype="bullet",
	dx=0,dy=0,
	t=0,
})

function bullet:on_update()
	self.x+=self.dx
	self.y+=self.dy
	self.t-=1
	
	local die=self.t<=0

	die=die or area_fn(self.x,self.y,
		self.w,self.h,
		function(x,y)
			local on_spawn=
				self.mx==flr(x/8) and
				self.my==flr(y/8)
			return not on_spawn
				and solid(x,y)
		end)
		
	if die then
		del_entity(self)
	end
end

function bullet:on_draw()
	local x,y=topleft(self)
	spr(3,x,y)
end

function is_map_entity(e)
	return e.mx~=nil
		and e.my~=nil
		and e.mv~=nil
end

mapentity=class({
	extends=entity,
	mx=0,my=0,mv=0,
})

function mapentity:hash()
	return bor(shl(self.mx,4),self.my)
end

toggleentity=class({
	extends=mapentity,
	m_on=0,m_off=0,
	blocker=false,
	down_ct=0,
	power_delay=2
})

function toggleentity:parent(child)
--	assert(child and type(child)=="table")
	if child
		and type(child)=="table"
	then
		add(self.chain,child)
	end
end

function toggleentity:swap_states()
	self.m_on,self.m_off=self.m_off,self.m_on
end

function toggleentity:on_on(sender)
	mset(self.mx,self.my,self.m_on)
	if self.blocker then
		recalc_all_guns()
	end
end

function toggleentity:on_off(sender)
	mset(self.mx,self.my,self.m_off)
	if self.blocker then
		recalc_all_guns()
	end
end

function toggleentity:push(sender)
	sender=sender or {}
	self.set=self.set or {}
	if not self.set[sender] then
		self.set[sender]=sender
		if self.down_ct==0 then
			self:on_on(sender)
		end
		self.down_ct+=1
	end
	sequence(
		function()
			if self.chain then
				for i=1,self.power_delay do
					yield()
				end
				for c in all(self.chain) do
					c:push(sender)
				end
			end
		end)
end

function toggleentity:pop(sender)
	if self.set[sender] then
		self.set[sender]=nil
		self.down_ct-=1
		if self.down_ct==0 then
			self:on_off(sender)
		end
	end
	sequence(
		function()
			if self.chain then
				for i=1,self.power_delay do
					yield()
				end
				for c in all(self.chain) do
					c:pop(sender)
				end
			end
		end)
end

-- breadth first search for
-- children of the same mget
function toggleentity:bfs_chain()
	local q={hash_xy(self.mx,self.my)}
	local found={}
	
	local offsets={
		{x=1,y=0},
		{x=-1,y=0},
		{x=0,y=-1},
		{x=0,y=1}
	}
	
	while #q>0 do
		local id=q[1]
		
		-- remove first entry
		-- by moving last entries
		-- back 1 index
		local n=#q
		for i=2,n+1 do
			q[i-1]=q[i]
		end
		
		found[id]=true
		local x,y=unhash_xy(id)
		
		local e=mapent(x,y)

		if e then
			for o in all(offsets) do
				local ox,oy=o.x+x,o.y+y
				local oid=hash_xy(ox,oy)
				if not found[oid] then
					local child=mapent(
						ox,oy)
					if child and child.etype==e.etype then
						e:parent(child)
						add(q,oid)
					end
				end
			end
		end
	end
end

door=class({
	extends=toggleentity,
	etype="door",
	m_on=17,m_off=18,
	blocker=true
})

bridge=class({
	extends=toggleentity,
	etype="bridge",
	m_on=49,m_off=k_pit
})

switch=class({
	extends=toggleentity,
	etype="switch",
	w=2,h=2,
	m_on=33,m_off=32,
	target=nil
})

function switch:on_enter(sender)
	self:push(sender)
end

function switch:on_exit(sender)
	self:pop(sender)
end

gun=class({
	extends=toggleentity,
	etype="gun",
	d=0,
	on=false,
	interval=12,
	frames=0,
})

function gun:on_update()
	if self.on then
		self.frames-=1
		if false and self.frames<=0 then
			-- fire
			local dx,dy=d_to_xy(self.d,1)
			add_entity(bullet:new({
				x=self.x,y=self.y,
				mx=self.mx,my=self.my,
				w=2,h=2,
				dx=dx,dy=dy,
				t=240
			}))
			self.frames+=self.interval
		end
	end
end

function gun:calc()
	self.points={}
	
	if not self.on or g.gun_wait_flag then
		return
	end
	
	add(self.points,
		{x=self.x,y=self.y})

	pts=self.points
	local add_world=function(wx,wy,dx,dy)
		local x=wx*8+4
		local y=wy*8+4

		add(pts,{x=x,y=y})
	end
	
	local d=self.d
	local wx,wy=self.mx,self.my
	local dx,dy=d_to_xy(self.d)
	
	local short_stop=false
	
	local laser_solid=function(wx,wy)
		local v=mget(wx,wy)
		local exclude=
			emap_add_fn(v)==add_mirror
		return solid_world(wx,wy) and
			not exclude
	end
	
	while not laser_solid(wx+dx,wy+dy) do
		wx+=dx
		wy+=dy
		
		if emap_add_fn(mget(wx,wy))==add_mirror
		then
			add_world(wx,wy,dx,dy)
			local e=mapent(wx,wy)
			d=e:reflect(d)
			if d==-1 then
				short_stop=true
				break
			end
			dx,dy=d_to_xy(d)
		end
	end
	
	entity=mapent(wx+dx,wy+dy)
	if entity~=self.powered then
		if self.powered then
			self.powered:pop(self)
		end
		if not entity or
			entity.etype~="power_switch"
		then
			self.powered=nil
		else
			self.powered=entity
			self.powered:push(self)
		end
	end
	
	local xx,yy=dx*4,dy*4
	if (dx>0) xx-=1
	if (dy>0) yy-=1
	if short_stop then
		xx,yy=0,0
	end
	
	add(self.points,
		{x=wx*8+4+xx,y=wy*8+4+yy})
end


function aa_line_rect_x
	(x1,y1, -- segment point a
		x2,y2, -- segment point b
		r)					-- rectangle
	--
	local l,t,r,b=bounds(r)
	local code=function(x,y)
		local c=0
		if x<l then c+=1
		elseif x>r then c+=2 end
		if y<t then c+=4
		elseif y>b then c+=8 end
		return c
	end
	
	local c1,c2=code(x1,y1),code(x2,y2)
	local mask=0xf
	if x1==x2 then
		mask=0x3
	elseif y1==y2 then
		mask=0xc
	end
	
	return band(c1,mask)==0 and
		band(c1,c2)==0
end

function gun:intersect_laser(r)
	local n=#self.points
	for i=1,n-1 do
		local a=self.points[i]
		local b=self.points[i+1]
		if aa_line_rect_x(a.x,a.y,b.x,b.y,r)
		then
			return true
		end
	end
	return false
end

function recalc_all_guns()
	g.gun_wait_flag=false
	for e in all(entities) do
		if e.calc then
			e:calc()
		end
	end
end

function gun:on_on(sender)
	self.on=true
	mset(self.mx,self.my,self.mv)
	self:calc()
end

function gun:on_off(sender)
	self.on=false
	mset(self.mx,self.my,self.mv+2)
	self:calc()
end

function gun:on_draw()
	if self.points then
		local n=#self.points
		for i=1,n-1 do
			local a=self.points[i]
			local b=self.points[i+1]
			line(a.x,a.y,b.x,b.y,8)
		end
	end
end

function d_to_xy(d,m)
	d=d or 0
	m=m or 1
	if d==0 then  return -m,0
	elseif d==1 then return m,0
	elseif d==2 then return 0,-m
	elseif d==3 then return 0,m
	else return 0,0 end
end

function player:on_update(dt)
	local ix,iy=input_xy(self.id)
	
	local speed=30*dt
	self.dx=ix*speed
	self.dy=iy*speed
	
	move_actor(self,self.dx,self.dy)
	
	local cr={
		x=self.x+self.cx,
		y=self.y+self.cy,
		w=self.cw,h=self.ch
	}
	
	if nofloor_area(cr.x,cr.y,cr.w,cr.h) then
		reset()
	end
	
	for e in all(entities) do
		if e~=self then
			if rect_overlap(cr,e) then
				if not self.touch[e] then
					self.touch[e]=e
					if (e.on_enter) e:on_enter(self)
				end
			else
				if self.touch[e] then
					self.touch[e]=nil
					if (e.on_exit) e:on_exit(self)
				end
			end
			
			if e.etype=="gun" then
				if e:intersect_laser(cr)
				then
					reset()
				end
			end
		end
	end
end

k_pcols={4,2}
function player:on_draw()
	local x,y=topleft(self)
	pal(7,k_pcols[self.id+1])
	spr(1,x,y)
	pal(7,7)
end

function make_refl_t(i1,o1,i2,o2)
	local r={}
	for i=0,3 do
		r[i]=-1
	end
	r[i1]=o1
	r[i2]=o2
	return r
end



mirror=class({
	extends=toggleentity,
	etype="mirror",
	d=0
})

function mirror:push(sender)
	self.d=(self.d+1)%4
	local mv=38
	if (self.mv==38) mv=54
	if (self.mv==54) mv=55
	if (self.mv==55) mv=39
	self.mv=mv
	mset(self.mx,self.my,self.mv)
	recalc_all_guns()
end

function mirror:on_off()
	recalc_all_guns()
end

refl_tt={}
refl_tt[0]=make_refl_t(3,1,0,2)
refl_tt[1]=make_refl_t(0,3,2,1)
refl_tt[2]=make_refl_t(1,3,2,0)
refl_tt[3]=make_refl_t(3,0,1,2)

function mirror:reflect(d)
	return refl_tt[self.d][d]
end

power_switch=class({
	extends=toggleentity,
	etype="power_switch",
	m_on=20,m_off=19,
})

function load_level()
	
end

function reset()
	reload(0x2000,0x2000,0x1000)
	g.checkpoint_lock=true
	play_reset()
end

function play_init()
	g={
		gun_wait_flag=true,
		level={
			x=0,y=0
		},
		checkpoint_lock=false,
		checkpoint=nil
	}
	
	play_reset()
end

function play_reset()
	entities={}
	mapentities={}
	drawables={}
	players={}
	
	g.gun_wait_flag=true
	
	g_pid=0
	
	for y=0,15 do
		for x=0,15 do
			local m=mget(x,y)
			local add_fn=emap_add_fn(m)
			add_fn(x,y,m)
		end
	end
	
	-- configure entities
	mapent(8,5):parent(mapent(7,4))
	mapent(8,5):parent(mapent(6,7))
	local d1=mapent(7,12)
	d1:bfs_chain()
	
	local s1=mapent(5,11)
	local s2=mapent(9,13)
	s1:parent(d1)
	s2:parent(d1)
	
	local b1=mapent(11,10)
	mapent(11,10):parent(mapent(11,9))
	b1:bfs_chain()
	
	mapent(12,11):parent(b1)
	mapent(10,8):parent(b1)
	
	local asdf=mapent(4,8)
	asdf:bfs_chain()
	
	mapent(5,8):parent(asdf)
--	mapent(5,8):parent(mapent(7,2))

	s1=mapent(9,2)
	s2=mapent(5,2)
	d1=mapent(8,2)
	d1:bfs_chain()
	s1:parent(d1)
	s2:parent(d1)

	g.checkpoint_lock=false
	if g.checkpoint then
		set_checkpoint(g.checkpoint)
		g.checkpoint:spawn()
	end
	
	recalc_all_guns()
end

checkpoint=class({
	extends=toggleentity,
	m_on=7,m_off=6
})

function checkpoint:spawn(sender)
	if g_pid<2 then
		add_player(self.mx+1,self.my,1)
		add_player(self.mx-1,self.my,1)
	end
end

function checkpoint:activate()
	
end

function checkpoint:on_enter(sender)
	set_checkpoint(self)
end

function set_checkpoint(checkpoint)
	if not g.checkpoint_lock
	then
		if (g.checkpoint) g.checkpoint:on_off()
		g.checkpoint=checkpoint
		if (g.checkpoint) g.checkpoint:on_on()
	end
end

function add_entity(e)
	local ret=add(entities,e)
	if is_map_entity(e) then
		e.chain={}
		e.set={}
	 local h=hash_xy(e.mx,e.my)
	 assert(not mapentities[h])
	 mapentities[h]=e
	end
	if e.on_draw then
		add(drawables,e)
	end
	return ret
end

function del_entity(e)
	del(entities,e)
	if is_map_entity(e) then
		local h=hash_xy(e.mx,e.my)
		mapentities[h]=nil
	end
	if e.on_draw then
		del(drawables,e)
	end
end

g_pid=0
function add_player(x,y,m)
	local p=add_entity(player:new({
		id=g_pid,
		x=x*8+4,
		y=y*8+4,
		touch={},
	}))
	players[g_pid]=p
	g_pid+=1
	mset(x,y,0)
	return p
end

function add_door(x,y,m)
	local ctx=emap_context(m)
	
	m=ctx.m or m
	
	m_on=18
	m_off=17

	local d=add_entity(door:new({
		mx=x,my=y,mv=m,
		m_on=m_on,m_off=m_off,
		x=x*8+4,y=y*8+4,
		w=4,h=4
	}))
	
	if fget(m,1) then
		d:swap_states()
	end
	
	return d
end

function add_switch(x,y,m)
	return add_entity(switch:new({
		mx=x,my=y,mv=32,
		x=x*8+4,y=y*8+4,
	}))
end

function add_bridge(x,y,m)
	local b=add_entity(bridge:new({
		mx=x,my=y,mv=49,
		x=x*8+4,y=y*8+4,
	}))
	
	if fget(m,1) then
		b:swap_states()
		b:on_on(b)
	else
		b:on_off(b)
	end
	return b
end

function add_gun(x,y,m)
	local ctx=emap_context(m)
	
	local d=ctx.d or 0
	
	-- use orange flag to tell
	-- gun is on by default
	local default_on=fget(m,1)
	
	local m_on=m
	local m_off=m_on+2
	
	if not default_on then
		m_on,m_off=m_off,m_on
	end
	
	local g=add_entity(gun:new({
		mx=x,my=y,mv=m,
		m_on=m_on,m_off,
		x=x*8+4,y=y*8+4,
		d=d,
		default_on=default_on,
		points={},
	}))

	-- some further initialization
	if g.default_on then
		g:on_on(g)
	end
end

function add_mirror(x,y,m)
	local ctx=emap_context(m)
	
	local d=ctx.d or 0
	
	return add_entity(mirror:new({
		mx=x,my=y,mv=m,
		x=x*8+4,y=y*8+4,
		d=d,
	}))
end

function add_power_switch(x,y,m)
	return add_entity(
		power_switch:new({
			mx=x,my=y,mv=m,
			x=x*8+4,y=y*8+4,
		}))

end

function add_checkpoint(x,y,m)
	local c=add_entity(
		checkpoint:new({
			mx=x,my=y,mv=m,
			x=x*8+4,y=y*8+4,
			w=3,h=2
		}))
		
	if fget(m,1) then
		set_checkpoint(c)
		c:on_off()
	end
end

function _init()

	poke(0x5f2d,1)
	poke(0x5f2e,1)

	play_init()
end

debug_colliders=false
function keypress(key)
	if key=="k" then
		debug_colliders=not debug_colliders
	end
end

function _update()
	dt=fps30_dt
	
	while stat(30) do
		keypress(stat(31))
	end
	
	tick_sequences()

	local n=#entities
	
	for i=1,n do
		local e=entities[i]
		if e and e.on_update then
			e:on_update(dt)
		end
	end
	
	local n=#drawables

	for j=1,3 do
		for i=1,n-1 do
			if drawables[i].y>drawables[i+1].y
			then
				local t=drawables[i]
				drawables[i]=drawables[i+1]
				drawables[i+1]=t
			end
		end
	end
	
	watch(band(stat(0)/204.8,0xffff.f).."%")
	watch(band(stat(1)/100,0xffff).."%")
	watch(band(stat(2)/100,0xffff).."%")
end

function _draw()
	pal(1,133,1)
	pal(3,130,1)
	pal(4,128+9,1)
	pal(2,128+12,1)
	pal(14,135,1)
	cls(1)
	
	map(0,0,0,0,16,16)
	
	palt(0,false)
	map(0,0,0,0,16,16,0x80)
	palt()
	
	foreach(drawables,function(e)
		if (e.on_draw) e.on_draw(e)
		if debug_colliders then
			--rect_draw(e,10)
			local r={x=e.x+(e.cx or 0),
				y=e.y+(e.cy or 0),
				w=e.cw or e.w,h=e.ch or e.h}
			rect_draw(r,10)
		end
	end)

	map(0,0,0,0,16,16,0x40)
	
	if btn(4,0) or btn(4,1)
	then
		draw_power_lines()
	end
	
	draw_log()
	draw_watches()
end

function draw_power_lines()
	function helper(node)
		for c in all(node.chain) do
			line(node.x,node.y,
				c.x,c.y,12)
			helper(c)
			pset(c.x,c.y,10)
		end
	end
	for e in all(entities) do
		if e.etype=="switch" or
			e.etype=="power_switch"
		then
			helper(e)
		end
	end
end

function mapent(x,y)
	local h=hash_xy(x,y)
	if mapentities[h] then
		return mapentities[h]
	end
	return nil
end
-->8
function move_actor(self,dx,dy)
	-- do physics	
	
	local x=function() return self.x+self.cx end
	local y=function() return self.y+self.cy end
	local w=self.cw
	local h=self.ch
	
	--[[
	if solid_area(self.x+dx,
		self.y+dy,
		w,h)
	then
		dx,dy=0,0
	end
	
	self.x+=dx
	self.y+=dy]]

	-- x movement
	local dirx=sgn(dx)
	local col_ox=dirx*w
	-- search an extra pixel ahead
	-- when moving left
	if (col_ox<0) col_ox-=1
	
	local nx=x()+dx+col_ox

	local chkx=x()+dx+col_ox				
	if not solid(chkx,y()-h+1) and
		not solid(chkx,y()+h-1)
	then
		-- no contact, move normally
		self.x+=dx
	else
		-- hit solid
		-- find contact point
		while not solid(x()+col_ox,y()-h+1)
			and not solid(x()+col_ox,y()+h-1)
		do
			self.x+=dirx*1
		end
	end

	-- y movement
	local diry=sgn(dy)
	local col_oy=diry*h
	-- search an extra pixel ahead
	-- when moving left
	if (col_oy<0) col_oy-=1
		
	local ny=y()+dy+col_oy

	local chky=y()+self.dy+col_oy
	if not solid(x()-w+1,chky)
		and not solid(x()+w-1,chky)
	then
		-- no contact, move normally
		self.y+=dy
	else
		-- hit solid
		-- find contact point
		while not solid(x()-w+1,y()+col_oy)
			and not solid(x()+w-1,y()+col_oy)
		do
			self.y+=diry*1
		end
	end
end

function solid_world(x,y)
	return fget(mget(x,y),0)
		or x<0 or x>127
		or y<0 or y>63
end

function solid(x,y)
	return fget(mget(x/8,y/8),0)
end

function nofloor(x,y)
	return fget(mget(x/8,y/8),7)
end

function area_fn(x,y,w,h,fn,t)
	t=t or "any"
	local r={x=x,y=y,w=w,h=h}
	local x1,y1=topleft(r)
	local x2,y2=botright(r)
	local ret={fn(x1,y1),
		fn(x2,y1),
		fn(x1,y2),
		fn(x2,y2)}
	if t=="any" then
		for r in all(ret) do
			if r then
				return true
			end
		end
		return false
	elseif t=="all" then
		for r in all(ret) do
			if not r then
				return false
			end
		end
		return true
	end
end

function solid_area(x,y,w,h)
	return area_fn(x,y,w,h,solid)
end

function nofloor_area(x,y,w,h)
	return area_fn(x,y,w,h,nofloor,"all")
end
-->8
-- entity map

_emap={}
_emap[1]=add_player
_emap[17]=add_door
_emap[18]=add_door
_emap[32]=add_switch
_emap[49]=add_bridge
_emap[4]=add_bridge

_emap[34]={add_gun,{d=0}}
_emap[35]={add_gun,{d=1}}
_emap[50]={add_gun,{d=2}}
_emap[51]={add_gun,{d=3}}

_emap[36]={add_gun,{d=0}}
_emap[37]={add_gun,{d=1}}
_emap[52]={add_gun,{d=2}}
_emap[53]={add_gun,{d=3}}

_emap[38]={add_mirror,{d=0}}
_emap[39]={add_mirror,{d=3}}
_emap[54]={add_mirror,{d=1}}
_emap[55]={add_mirror,{d=2}}

_emap[19]=add_power_switch

_emap[6]=add_checkpoint
_emap[7]=add_checkpoint

function emap_context(v)
	local em=_emap[v]
	if type(em)=="table" then
		return em[2]
	end
	return {}
end

function emap_add_fn(v)
	local em=_emap[v]
	if type(em)=="table" then
		return em[1]
	elseif type(em)=="function" then
		return em
	end
	return function() end
end
__gfx__
0000000000077000000000000aa00000cccccccc000000000000000000eea0000000000000000000000000000000000000000000000000000000000000000000
000000000007700000000000aaaa0000cdccccdc00000000000000000eeea0000000000000000000000000000000000000000000000000000000000000000000
00700700077777700ddddd00aaaa0000ccdccdcc00000000000000000000a0000000000000000000000000000000000000000000000000000000000000000000
0007700000077000000d00000aa00000cccccccc0000000000dddd0000eeae000000000000000000000000000000000000000000000000000000000000000000
0007700000077000000d000000000000cccccccc0000000003dddd300aeeaea00000000000000000000000000000000000000000000000000000000000000000
007007000077770000000dd000000000ccdccdcc0000000003dddd300aeeeea00000000000000000000000000000000000000000000000000000000000000000
00000000007007000000000000000000cdccccdc000000000033330000aaaa000000000000000000000000000000000000000000000000000000000000000000
00000000007007000000000000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddddddddccccccccc000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d333333dc222222c0000000000066000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d333333dc222222c000000000063360000f88f000000000000000000000000000077770000777700000000000000000000000000000000000000000000000000
d333333dc222222c00000000063333600f8888f00000000000444400002222000744447777222270000000000000000000000000000000000000000000000000
d333333dc222222c0000000003333330088888800000000004666644226666207444444422222227000000000000000000000000000000000000000000000000
d333333dc222222c0000000000533500003883000000000004666644226666207444444422222227000000000000000000000000000000000000000000000000
d333333dc222222c0000000000055000000330000000000000444400002222000744447777222270000000000000000000000000000000000000000000000000
ddddddddccccccccc000000c00000000000000000000000000000000000000000077770000777700000000000000000000000000000000000000000000000000
0000000000000000dddddddddddddddddddddddddddddddd77000000000000670000000000000000000000000000000000000000000000000000000000000000
0000000000000000333333dddd333333333333dddd33333367700000000006770000000000000000000000000000000000000000000000000000000000000000
000cc000000000003333dddddddd33333333dddddddd3333d67700000000677d0000000000000000000000000000000000000000000000000000000000000000
00cccc00000dd00033333eeddee33333333333dddd333333dd667000000767dd0000000000000000000000000000000000000000000000000000000000000000
00dccd0000dddd0033333eeddee33333333333dddd333333ddd7660000767ddd0000000000000000000000000000000000000000000000000000000000000000
001dd100005dd5003333dddddddd33333333dddddddd33330ddd77600776ddd00000000000000000000000000000000000000000000000000000000000000000
0001100000055000333333dddd333333333333dddd33333300ddd776776ddd000000000000000000000000000000000000000000000000000000000000000000
0000000000000000dddddddddddddddddddddddddddddddd000ddd7776ddd0000000000000000000000000000000000000000000000000000000000000000000
00000000ccccccccd333333dddddddddd333333ddddddddd000ddd6777ddd0000000000000000000000000000000000000000000000000000000000000000000
00000000cdccccdcd333333ddddeedddd333333ddddddddd00ddd677677ddd000000000000000000000000000000000000000000000000000000000000000000
00000000ccdccdccd333333dd3deed3dd333333dd3d33d3d0ddd67700677ddd00000000000000000000000000000000000000000000000000000000000000000
00000000ccccccccd333333dd3d33d3dd333333dd3d33d3dddd7670000667ddd0000000000000000000000000000000000000000000000000000000000000000
00000000ccccccccd3d33d3dd333333dd3d33d3dd333333ddd767000000766dd0000000000000000000000000000000000000000000000000000000000000000
00000000ccdccdccd3deed3dd333333dd3d33d3dd333333dd77600000000776d0000000000000000000000000000000000000000000000000000000000000000
00000000cdccccdcdddeedddd333333dddddddddd333333d77600000000007760000000000000000000000000000000000000000000000000000000000000000
00000000ccccccccddddddddd333333dddddddddd333333d76000000000000770000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000002000002000000000000000001014201030000000000000000000000000003030101010100000000000000008000030301010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1010101010101033101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1016173030000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000003030201212122000000700001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000003030000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000003131000027000000000037001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000003131000000200000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000003131000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000003131360000000000000027001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000003131130000000020000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010303030313030301000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000010303030313030301000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000200011000000002000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000011000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000600000010002000000600001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
