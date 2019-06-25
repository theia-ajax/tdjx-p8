pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- actors

actor_config={
	gravity=0.2,
}

-- actor flags
af={
	grounded=shl(1,0),
	platdrop=shl(1,1),
	dead=shl(1,2),
}

actor=class({
	x=0,y=0,					-- position
	dx=0,dy=0,			-- velocity
	pushx=0,pushy=0,
	ddx=0,ddy=0,	-- acceleration
	w=0.2,h=0.5, -- half width/height
	mass=1,
	sp=1,
	sw=1,sh=1,
	face=1,
	flags=0,
	jumps=0,
	t_air=0,
	t_jump_hold=0,
	t_plat_drop=0,
	t0=0,
	k_accel=64,
	k_coldst=0.3, -- collision check distance
	k_scndst=0.1, -- scan distance while searching for contact point
	k_bounce_wall=0,
	k_bounce_floor=0,
	k_jump_force=12,
	k_max_move=8,
	k_jump_forgive_t=5/60,
	k_jump_hold_t=1/2,
	k_jump_hold_force=1,
	k_jump_hold_delay=0.0833,
	k_plat_drop_t=0.1,
	k_grav_scale=1,
	k_fric=8,
	k_drag=32,
})

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

function actor:control(ix,iy,ibtns,dt)
	local accel=self.k_accel*dt
	if not self:getf(af.grounded) then
		accel=shr(accel,1)
	end
		
	local stand=self:getf(af.grounded)
	if (self.t_plat_drop>0) self.t_plat_drop-=dt
	if iy>0 then
		self.t_plat_drop=self.k_plat_drop_t
	end

	if sgn(ix)~=sgn(self.dx) then
		accel*=2
	end

	local fx=0
	
	if ix~=0 and stand then
		self.t0+=dt
	else
		self.t0=0.5
	end

	if ix<0 then
		fx-=accel
		self.face=-1
	elseif ix>0 then
		fx+=accel
		self.face=1
	else
--		local a=accel
--		if (not stand) a/=2
--		self.dx=moveto(self.dx,0,a)
	end
	
	self:force(fx,0)
 
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
		
	local jumpreq=band(ibtns,1)~=0
	local jumphold=band(ibtns,4)~=0
		
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
end

function actor:move(dt)
	if self.behavior then
		self:behavior(dt)
	end

	-- do physics
	if not self:getf(af.grounded) then
		local pdy=self.dy
		self.dy+=actor_config.gravity*dt*self.k_grav_scale
	end
		
	local stand=self:getf(af.grounded)
	self:setf(af.grounded,false)
	
	self.dx+=self.ddx*dt
	self.dy+=self.ddy*dt

	if stand and self.dx~=0 then
		if abs(self.dx)<0.1 then
			self.dx=0
		end
		self:force(-sgn(self.dx)*self.k_fric*dt,0)
	end
	
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
	
	self.pushx=0
	self.pushy=0
end

function actor:force(fx,fy)
	self.dx+=fx/self.mass
	self.dy+=fy/self.mass
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

function actor:center()
	return self.x,self.y-self.h/2
end

function actor:overlap(other)
	return self:left()<=other:right()
		and self:right()>=other:left()
		and self:top()<=other:bottom()
		and self:bottom()>=other:top()
end

function actor:rect()
	return {
		x=self.x,y=self.y-self.h,
		w=self.w,h=self.h,
	}
end

function init_actors()
	actors={}
end

function add_actor(p)
	local a=actor:new(p)
	if (a.start) a:start()
	return add(actors,a)
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

-- flags
-- 0:solid
-- 1:platform
-- 2:entity
-- 3:slope
-- 4/5:generic bits, used with slopes/platform
-- 6:background
-- 7:foreground

k_flag_solid=0
k_flag_platform=1
k_flag_platform_block=4
k_flag_slope=3
k_flag_flip_x=4
k_flag_flip_y=5

-- is world coord: wx,wy solid
-- 1 world unit == 8 pixels
function map_solid(wx,wy)
	--return fget(mget(wx,wy),0)
	local val=mget(wx,wy)
	if fget(val,k_flag_solid) then
		if fget(val,k_flag_slope) then
			-- slope
			local l,r=flr(wx),ceil(wx)
			local t,b=flr(wy),ceil(wy)
			local nx,ny=wx-l,wy-t
			local flipx=fget(val,k_flag_flip_x)
			local flipy=fget(val,k_flag_flip_y)
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
		elseif fget(val,k_flag_platform) then
		else
			return true
		end
	end
	return false
end

function platform_solid(wx,wy)
	local ret=solid(wx,wy)
	local val=mget(wx,wy)
	if fget(val,k_flag_platform) then
		return wy-flr(wy)<0.5
	end
	return ret
end

function blocked_platform_solid(wx,wy)
	local ret=solid(wx,wy)
	local val=mget(wx,wy)
	if fget(val,k_flag_platform) and fget(val,6) then
		return wy-flr(wy)<0.5
	end
	return ret
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
