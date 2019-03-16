pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	rand=rgen(flr(rnd(32767)))

	gm={
		players={},
		active=player:new({x=64,y=64}),
		round=1,
		bullets={},
	}
end

function next_round()
	rand:reset()
	
	gm.bullets={}

	gm.players[gm.round]=gm.active
	
	foreach(gm.players,
		function(p) p:reset() end)
	
	gm.round+=1

	gm.active=player:new({x=64,y=64})
end

function _update60()
	dt=1/60
	
	update_watch()

	local ix,iy=0,0
	
	if (btn(0)) ix-=1
	if (btn(1)) ix+=1
	if (btn(2)) iy-=1
	if (btn(3)) iy+=1
	
	if rand:next(100)<25 then
		local ang=rand:next()
		local rad=rand:next(64,128)
		add(gm.bullets,
			bullet:new({
				x=64+cos(ang+1/2)*rad,
				y=64+sin(ang+1/2)*rad,
				dx=cos(ang)*32,
				dy=sin(ang)*32,
			}))
	end
	
	foreach(gm.bullets,
		function(b) b:update(dt) end)
	
	gm.active:set_inp(ix,iy)
	gm.active:update(dt)
	
	foreach(gm.players,
		function(p) p:update(dt) end)
		
	for b in all(gm.bullets) do
		for p in all(gm.players) do
			if not b.dead
				and p.health>0
				and	dist(b.x,b.y,p.x,p.y)<3
			then
				b.dead=true
				p.health-=1
			end
		end

		if not b.dead and
			dist(b.x,b.y,gm.active.x,gm.active.y)<3
		then
			b.dead=true
			gm.active.health-=1
			if gm.active.health<=0 then
				next_round()
			end
		end
	end
		
	for b in all(gm.bullets) do
		if b.dead then
			del(gm.bullets,b)
		end
	end
	
	watch(#gm.players)
end

function _draw()
	cls()
	

	foreach(gm.players,
		function(p) p:draw() end)
	gm.active:draw()
	
	foreach(gm.bullets,
		function(b) b:draw() end)

	draw_watch()		
	draw_log()
end

player={
	x=0,y=0,r=0,
	frame=1,
	is_record=true,
	dead=false,
	health=10,
	inp_dx=0,
	inp_dy=0,
	inp_bx=false,
	inp_by=false,
}

function player:new(p)
	self.__index=self
	p=p or {}
	
	p.inp_recs={}
	
	p.stx=p.x or 0
	p.sty=p.y or 0
	
	return setmetatable(
		p or {},self)
end

function player:set_inp(
	dx,dy,bx,bo)
	self.inp_dx=dx or 0
	self.inp_dy=dy or 0
	self.inp_bx=bx or false
	self.inp_bo=bo or false
end

function player:update(dt)
	if not self.dead
	 and not self.is_record
	then
		local r=self.inp_recs[self.frame]
		if r then
			self.inp_dx=r.dx
			self.inp_dy=r.dy
			self.inp_bx=r.bx
			self.inp_bo=r.bo
		else
			self.dead=true
			self.inp_dx=0
			self.inp_dy=0
			self.inp_bx=false
			self.inp_bo=false
		end
	end

	self.x+=self.inp_dx*32*dt
	self.y+=self.inp_dy*32*dt
	
	if self.inp_dx~=0 or
		self.inp_dy~=0
	then
		local tg=atan2(self.inp_dx,
			self.inp_dy)
			
		self.r=lerp_angle(self.r,
			tg,10*dt)
	end
	
	if self.is_record then
 	self.inp_recs[self.frame]={
 		dx=self.inp_dx,
 		dy=self.inp_dy,
 		bx=self.inp_bx,
 		bo=self.inp_bo,
 	}
 end
 
 if (not self.dead) self.frame+=1
end

function player:reset()
	self.is_record=false
	self.frame=1
	self.health=10
	self.x=self.stx
	self.y=self.sty
	self.dead=false
end

function player:draw()
	local c=11
	if self.dead then
		c=5
	elseif not self.is_record then
		c=3
	end
	circfill(self.x,self.y,3,c)
	pset(self.x+cos(self.r)*3,
		self.y+sin(self.r)*3,
		10)
	if self.is_record then
		circfill(self.x,self.y,1,1)
		pset(self.x,self.y,12)
	end
end

bullet={
	x=0,y=0,dx=0,dy=0,
	t_life=5,
	dead=false,
}

function bullet:new(p)
	self.__index=self
	return setmetatable(p or {},self)
end

function bullet:update(dt)
	self.x+=self.dx*dt
	self.y+=self.dy*dt
	
	if self.t_life>0 then
		self.t_life-=dt
		if self.t_life<=0 then
			self.dead=true
		end
	end
end

function bullet:draw()
	pset(self.x,self.y,8)
end
-->8
-- util

function ins(a,i,v)
	local n=#a
	if (i>=n+1)	return add(a,v)
	i=max(i,1)
	for j=n+1,i+1,-1 do
		a[j]=a[j-1]
	end
	a[i]=v
	return v
end

function idel(a,i)
	local n=#a
	if (i<1 or i>n) return
	a[i]=nil
	
	for j=i,n-1 do
		a[j]=a[j+1]
	end
	a[n]=nil
end

function compress(a,n)
	local n=n or #a
	local h,t=1,n

	-- wind tail back to first
	-- non-nil entry in case len
	-- is wrong
	while a[t]==nil and t>h do
		t-=1
	end

	while h<t do
		if a[h]==nil then
			a[h]=a[t]
			a[t]=nil
			while a[t]==nil and t>h do
				t-=1
			end
		end
		h+=1
	end
end

__watch={}

function watch(m)
	m=tostr(m)
	local len=#m*4
	if (len>__watch.sx) __watch.sx=len
	__watch.sy+=6
	add(__watch,m)
end

function update_watch()
	__watch={sx=0,sy=0}
end

function draw_watch()
	local n=#__watch
	for i=1,n do
		local m=__watch[i]
		print(m,0,(i-1)*6,11)
	end
end

_logs={}

function log(m,c)
	add(_logs,{m=tostr(m),c=c or 7})
	local n=#_logs
	if n>21 then
		for i=1,n do
			_logs[i]=_logs[i+1]
		end
		_logs[n]=nil
	end
end

function draw_log()
	local n=#_logs
	for i=1,n do
		local l=_logs[i]
		print(l.m,127-#l.m*4,(i-1)*6,l.c)
	end
end

-- xorshift16 sort of
function rgen(seed,ct)
	seed=seed or 1
	ct=ct or 0
	local ret={
		seed=seed,
		sx=seed,
		count=0,
		_next=function(self)
			self.count+=1
			self.sx=bxor(self.sx,shl(self.sx,7))
			self.sx=bxor(self.sx,shr(self.sx,9))
			self.sx=bxor(self.sx,shl(self.sx,8))
			return self.sx
		end,
		next=function(self,mn,mx)
			if not mn then
			 mn,mx=0,1
			elseif not mx then
				mx,mn=mn,0
			elseif mx<mn then
				mn,mx=mx,mn
			end
			
			local f=(self:_next()/32767+1)/2
			return f*(mx-mn)+mn
		end,
		reset=function(self,ct,seed)
			ct=ct or 0
			self.seed=seed or self.seed
			self.sx=self.seed
			self.count=0
			for i=1,ct do
				self:next()
			end
		end,
		clone=function(self)
			return rgen(self.seed,self.count)
		end
	}
	for i=1,ct do ret:next() end
	return ret
end

function mod(a,b)
	local r=a%b
	if r>=0 then
		return r
	else
		return r+b
	end
end

function dist2(x1,y1,x2,y2)
	local dx,dy=x2-x1,y2-y1
	return dx*dx+dy*dy
end

function dist(x1,y1,x2,y2)
	return sqrt(dist2(x1,y1,x2,y2))
end

function sqr(n)
	return n*n
end

function angle_to(ox,oy,tx,ty)
	return atan2(tx-ox,ty-oy)
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

function _sgn(a)
	if a<0 then return -1
	elseif a>0 then return 1
	else return 0 end
end
sgn=_sgn

function moveto(a,b,d)
	if abs(b-a)<=d then
		return b
	else
		return a+sgn(b-a)*d
	end
end

function moveto_angle(a,b,d)
	local dl=angle_diff(a,b)
	if -d<dl and dl<d then
		return b
	else
		return moveto(a,a+dl,d)
	end
end

function m01(v)
	return mid(v,0,1)
end

function lerp(a,b,t)
	return a+(b-a)*t
end

function lerp_angle(a,b,t)
	local d=wrap((b-a),1)
	if (d>0.5) d-=1
	return a+d*m01(t)
end
