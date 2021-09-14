pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
function _init()
	play_init()
end

function play_init()
	_update60=play_update
	_draw=play_draw
	
	mc={
		x=8,y=8,
		dx=0,dy=0,
		t=0
	}
end

function play_update()
	mc.t+=1/30
end

function play_draw()
	cls()
	
	local px,py=w2s(mc.x,mc.y)
	spr(16+(mc.t%1)*4,px,py)
end

function w2s(x,y)
	return x*8,y*8
end

-->8
-- actors

function make_inp(p)
	local p=p or {}
	return {x=p.x or 0,y=p.y or 0,btns=p.btns or 0}
end

-- actor flags
af={
	grounded=shl(1,0),
	platdrop=shl(1,1),
	dead=shl(1,2),
}

actor={
	x=0,y=0,					-- position
	dx=0,dy=0,			-- velocity
	pushx=0,pushy=0,
	ddx=0,ddy=20,	-- acceleration
	w=0.2,h=0.5, -- half width/height
	sp=1,
	face=1,
	flags=0,
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
			self.y-0.5)
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
		if solid(left,self.y+fdy-1) or
			solid(right,self.y+fdy-1)
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
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbbbbbb0bbbbbbb0bbbbbbb0bbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbbaaaa3bbbaaaa3bbbaaaa3bbbaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbbaaaa3bbbaaaa3bbbaaaa3bbbaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbbbaaa3bbbbaaa3bbbbaaa3bbbbaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
033bbbbb033bbbbb033bbbbb033bbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b3333300b3333300b3333300b333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbbbbb00bbbbbb00bbbbbb00bbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0000b0b00000b0b000000b0b00000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
