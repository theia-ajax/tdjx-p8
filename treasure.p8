pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
#include util.p8

k_pit=48

entity=class({
	name="entity",
	x=0,y=0,w=4,h=4,
})

player=class({
	extends=entity,
	name="player",
	cx=0,cy=2,cw=3,ch=2,
	w=4,
	id=0,
})

bullet=class({
	extends=entity,
	name="bullet",
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

mapentity=class({
	extends=entity,
	mx=0,my=0,mv=0,
})

toggleentity=class({
	extends=mapentity,
	m_on=0,m_off=0,
	down_ct=0,
	chain=nil,
	parent=function(self,child)
		self.chain=self.chain or {}
		add(self.chain,child)
	end,	
	swap_states=function(self)
		self.m_on,self.m_off=self.m_off,self.m_on
	end,
	on_on=function(self)
		mset(self.mx,self.my,self.m_on)
	end,
	on_off=function(self)
		mset(self.mx,self.my,self.m_off)
	end,
	push=function(self,sender)
		sender=sender or {}
		if not self.set[sender] then
			self.set[sender]=sender
			if self.down_ct==0 then
				self:on_on()
				recalc_all_guns()
			end
			self.down_ct+=1
		end
		if self.chain then
			for c in all(self.chain) do
				c:push(sender)
			end
		end
	end,
	pop=function(self,sender)
		if self.set[sender] then
			self.set[sender]=nil
			self.down_ct-=1
			if self.down_ct==0 then
				self:on_off()
				recalc_all_guns()
			end
		end
		if self.chain then
			for c in all(self.chain) do
				c:pop(sender)
			end
		end
	end
})

-- breadth first search for
-- children of the same mget
function
toggleentity:bfs_chain()
--
		
	-- x and y are constrained
	-- to map coordinates
	-- so we can happily
	-- store them in 8 bits
	-- 4 each
	local hash=function(x,y)
		return bor(shl(x,4),y)
	end
	
	local unhash=function(h)
		return band(shr(h,4),0xf),
			band(h,0xf)
	end
	
	local q={hash(self.mx,self.my)}
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
		local x,y=unhash(id)
		
		local e=find_entity(x,y)

		if e then
			for o in all(offsets) do
				local ox,oy=o.x+x,o.y+y
				local oid=hash(ox,oy)
				if not found[oid] then
					local child=find_entity(
						ox,oy)
					if child and child.name==e.name then
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
	name="door",
	m_on=17,m_off=18
})

bridge=class({
	extends=toggleentity,
	name="bridge",
	m_on=49,m_off=k_pit
})

switch=class({
	extends=toggleentity,
	name="switch",
	w=2,h=2,
	m_on=33,m_off=32,
	target=nil,
	on_enter=function(self,sender)
		self:push(sender)
	end,
	on_exit=function(self,sender)
		self:pop(sender)
	end,
	on_on=function(self)
		toggleentity.on_on(self)
--		mset(self.mx,self.my,self.mv+1)
		if self.target then
			self.target:push(self)
		end
	end,
	on_off=function(self)
		toggleentity.on_off(self)
--		mset(self.mx,self.my,self.mv)
		if self.target then
			self.target:pop(self)
		end
	end
})

gun=class({
	extends=toggleentity,
	name="gun",
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
	
	if not self.on or gun_wait_calc then
		return
	end
	
	add(self.points,
		{x=self.x,y=self.y})

	pts=self.points
	local add_world=function(wx,wy)
		add(pts,{x=wx*8+4,y=wy*8+4})
	end
	
	local d=self.d
	local wx,wy=self.mx,self.my
	local dx,dy=d_to_xy(self.d)
	
	wx+=dx
	wy+=dy
	
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
			add_world(wx,wy)
			local e=find_entity(wx,wy)
			d=e:reflect(d)
			if d==-1 then
				break
			end
			dx,dy=d_to_xy(d)
		end
	end
	
	entity=find_entity(wx,wy)
	if entity then
		entity:push()
	end
	
	add(self.points,
		{x=wx*8+4+dx*4,y=wy*8+4+dy*4})
end

function recalc_all_guns()
	gun_wait_calc=false
	for e in all(entities) do
		if e.calc then
			e:calc()
		end
	end
end

function gun:on_on()
	self.on=true
	mset(self.mx,self.my,self.mv)
	self:calc()
end

function gun:on_off()
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
	name="mirror",
	d=0
})

function mirror:on_on()
	self.d=(self.d+1)%4
	local mv=38
	if (self.mv==38) mv=54
	if (self.mv==54) mv=55
	if (self.mv==55) mv=39
	self.mv=mv
	mset(self.mx,self.my,self.mv)
end

function mirror:on_off() end

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
	name="power_switch",
	target=nil,
	m_on=20,m_off=19,
})

function reset()
	reload(0x2000,0x2000,0x1000)
	_init()
end

function add_entity(e)
	local ret=add(entities,e)
	if e.on_draw then
		add(drawables,e)
	end
	return ret
end

function del_entity(e)
	del(entities,e)
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
		w=4,h=4,
		set={},
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
		set={},
	}))
end

function add_bridge(x,y,m)
	local b=add_entity(bridge:new({
		mx=x,my=y,mv=49,
		x=x*8+4,y=y*8+4,
		set={},
	}))
	
	if fget(m,1) then
		b:swap_states()
	else
		b:on_off()
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
		set={},
		points={},
	}))

	-- some further initialization
	if g.default_on then
		g:on_on()
	end
end

function add_mirror(x,y,m)
	local ctx=emap_context(m)
	
	local d=ctx.d or 0
	
	return add_entity(mirror:new({
		mx=x,my=y,mv=m,
		d=d,
		set={},
	}))
end

function add_power_switch(x,y,m)
	return add_entity(
		power_switch:new({
			mx=x,my=y,mv=m,
			x=x*8+4,y=y*8+4,
			set={},
		}))
end


function _init()

	poke(0x5f2d,1)
	poke(0x5f2e,1)

	gun_wait_calc=true

	entities={}
	drawables={}
	players={}
	
	g_pid=0
	
	for x=0,15 do
		for y=0,15 do
			local m=mget(x,y)
			local add_fn=emap_add_fn(m)
			add_fn(x,y,m)
		end
	end
	
	-- configure entities
	
	local d1=find_entity(7,12)
	local d2=find_entity(7,11)
	d1:parent(d2)
	
	local s1=find_entity(5,11)
	local s2=find_entity(9,13)
	s1.target=d1
	s2.target=d1
	
	local b1=find_entity(11,10)
	b1:parent(find_entity(11,9))
	
	find_entity(12,11).target=b1
	find_entity(10,8).target=b1
	
	s1=find_entity(14,5)
	s1.target=find_entity(11,2)
	
	find_entity(10,4).target=find_entity(9,4)
	
	local asdf=find_entity(4,8)
	asdf:bfs_chain()
	
	find_entity(5,11).target=asdf
	
	recalc_all_guns()
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
	
	draw_log()
	draw_watches()
end

function find_entity(x,y)
	for e in all(entities) do
		if e.mx==x and e.my==y then
			return e
		end
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
0000000000077000000000000aa00000cccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000007700000000000aaaa0000cdccccdc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700077777700ddddd00aaaa0000ccdccdcc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000077000000d00000aa00000cccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000077000000d000000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000077770000000dd000000000ccdccdcc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007007000000000000000000cdccccdc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007007000000000000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddddddddccccccccc000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d333333dc222222c0000000000066000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d333333dc222222c000000000065560000f88f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d333333dc222222c00000000065555600f8888f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d333333dc222222c0000000005555550088888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d333333dc222222c0000000000155100003883000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d333333dc222222c0000000000011000000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddddddddccccccccc000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000dddddddddddddddddddddddddddddddddd0000000000006d0000000000000000000000000000000000000000000000000000000000000000
0000000000000000333333dddd333333333333dddd3333336dd00000000006dd0000000000000000000000000000000000000000000000000000000000000000
000cc000000000003333dddddddd33333333dddddddd333336dd000000006dd30000000000000000000000000000000000000000000000000000000000000000
00cccc00000dd00033333eeddee33333333333dddd3333333366d000000d6d330000000000000000000000000000000000000000000000000000000000000000
00dccd0000dddd0033333eeddee33333333333dddd333333333d660000d6d3330000000000000000000000000000000000000000000000000000000000000000
001dd100005dd5003333dddddddd33333333dddddddd33330333dd600dd633300000000000000000000000000000000000000000000000000000000000000000
0001100000055000333333dddd333333333333dddd33333300333dd6dd6333000000000000000000000000000000000000000000000000000000000000000000
0000000000000000dddddddddddddddddddddddddddddddd000333ddd63330000000000000000000000000000000000000000000000000000000000000000000
00000000ccccccccd333333dddddddddd333333ddddddddd0003336ddd3330000000000000000000000000000000000000000000000000000000000000000000
00000000cdccccdcd333333ddddeedddd333333ddddddddd003336dd6dd333000000000000000000000000000000000000000000000000000000000000000000
00000000ccdccdccd333333dd3deed3dd333333dd3d33d3d03336dd006dd33300000000000000000000000000000000000000000000000000000000000000000
00000000ccccccccd333333dd3d33d3dd333333dd3d33d3d333d6d000066d3330000000000000000000000000000000000000000000000000000000000000000
00000000ccccccccd3d33d3dd333333dd3d33d3dd333333d33d6d000000d66330000000000000000000000000000000000000000000000000000000000000000
00000000ccdccdccd3deed3dd333333dd3d33d3dd333333d3dd600000000dd630000000000000000000000000000000000000000000000000000000000000000
00000000cdccccdcdddeedddd333333dddddddddd333333ddd60000000000dd60000000000000000000000000000000000000000000000000000000000000000
00000000ccccccccddddddddd333333dddddddddd333333dd6000000000000dd0000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000002000000000000000000000001014201030000000000000000000000000003030101010100000000000000008000030301010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1010101010101033101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000003030000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000003030000000000000120000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000003030000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000003131000026003720000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000003131000000300000000000201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000003131360000002727000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000003131000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000003131130000000020000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010303030313030301000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000010303030313030301000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000200011000000002000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000010001000011000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000010002000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
