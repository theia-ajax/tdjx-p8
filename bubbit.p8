pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
function _init()
	play_init()
end
-->8
-- actor 😐

😐={
	x=0,y=0,
	w=0.5,h=0.5,
	col_ox=0,col_oy=0,
	col_w=0.5,col_h=0.5,
	dx=0,dy=0,
	nudge_x=0,nudge_y=0,
	face=1,
	sp=1,
}

function 😐:new(p)
	self.__index=self
	return setmetatable(p or {},self)
end

function 😐:update()
	local l,t,r,b=local_rect(self)
	
	self.dx+=self.nudge_x
	self.dy+=self.nudge_y
	
	self.nudge_x=0
	self.nudge_y=0
	
	if self.dx>0 then
		while solid_x(self.x+r+self.dx,self.y,t,b)
			and self.dx>0
		do
			self.dx=max(self.dx-0.125,0)
		end
	elseif self.dx<0 then
		while solid_x(self.x+l+self.dx,self.y,t,b)
			and self.dx<0
		do
			self.dx=min(self.dx+0.125,0)
		end
	end
	
	if self.dy>0 then
		while solid_y(self.x,self.y+self.dy+b,l,r)
			and self.dy>0
		do
			self.dy=max(self.dy-0.125,0)
		end
	elseif self.dy<0 then
		while solid_y(self.x,self.y+self.dy+t,l,r)
			and self.dy<0
		do
			self.dy=min(self.dy+0.125,0)
		end
	end
	
	self.x+=self.dx
	self.y+=self.dy
end

function 😐:draw()
	local px,py=w2s(self.x,self.y)
	px-=self.w*8
	py-=self.h*8
	local flipx=false
	if self.face and self.face<0 then
		flipx=true
	end
	local sp=self.sp
	spr(sp,px,py,1,1,false)
end

-->8
-- physics/math util

function solid(x,y)
	return fget(mget(x,y),0)
end

function solid_x(x,y,t,b)
	return solid(x,y+t) or
		solid(x,y+b)
end

function solid_y(x,y,l,r)
	return solid(x+l,y) or
		solid(x+r,y)
end

function w2s(x,y)
	return x*8,y*8
end

function w2sr(x1,y1,x2,y2)
	return x1*8,y1*8,x2*8,y2*8
end

-- math/utils

k_e=0x0002.b7e1
k_pi=0x0003.243f

function len(x,y)
	return sqrt(x*x+y*y)
end

function norm(x,y)
	local l=len(x,y)
	if (l~=0) return x/l,y/l
	return 0,0
end

function world_rect(self)
	local x1,y1,x2,y2=local_rect(self)
	return self.x+x1,self.y+y1,
		self.x+x2,self.y+y2
end

function local_rect(self)
	return self.col_ox,
		self.col_oy,
		self.col_ox+self.col_w,
		self.col_oy+self.col_h
end

function actor_overlap(a,b)
	if abs(a.x-b.x)<1 and
		abs(a.y-b.y)<1
	then
		local al,at,ar,ab=world_rect(a)
		local bl,bt,br,bb=world_rect(b)
		return al<=br and
			ar>=bl and
			at<=bb and
			ab>=bt
	else
		return false
	end
end

function random_pos(x,y,w,h)
	local px,py=0,0
	repeat
		px=flr(rnd(w))+x
		py=flr(rnd(h))+y
	until not solid(px,py)
	return px,py
end

function sin_rng(a,b,tt)
	tt=tt or t()
	return sin(tt)*(b-a)/2+a
end
-->8
function play_init()
	_update60=play_update
	_draw=play_draw
	
	actors={}
	
	add(actors,😐:new({
		x=8,y=8
	}))
end

function play_update()
	foreach(actors,function(😐)
		😐:update()
	end)
end

function play_draw()
	cls()
	
	foreach(actors,function(😐)
		😐:draw()
	end)
end
__gfx__
00000000e00000ee0aaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000eaaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000004444eaaaffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770000044747eaaffcfc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000e044444eaafffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700ee2222eeaa33333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ee2222eea033333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000eedeedee0050005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
