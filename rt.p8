pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
show_state=false
px_delta=4

function _init()
	cls()
	
	poke(0x5f2d,1)
	
	seed=flr(rnd(32767))
--	seed=835
	seed=15249
	srand(seed)
	
	menuitem(1,"toggle display",
		function()
			show_state=not show_state
		end)

	scene={}
	scene.spheres={}
	scene.planes={}
	scene.lightdir=vec3:new({x=0.5,y=-1,z=0.1}):norm()
	
	for i=0,8 do
		add(scene.spheres,sphere:new(
			{center=vec3:new({
					x=rnd(20)-10,y=rnd(20)-10,z=10+i*2}),
				rad=2,
				col=7}))
	end
	
	--[[
	add(scene.planes,plane:new(
		{origin=vec3:new({y=5}),
			col=11}))
			]]
	cam={
		pos=vec3:new()
	}
	
	start_calc()
end

function start_calc()
	calc_cr=cocreate(calc_view)
end

function _update()
	local move=3
	
	while stat(30) do
		keypress(stat(31))
	end
	
	if calc_cr and costatus(calc_cr)~="dead" then
		coresume(calc_cr)
	end
	
	local pos=cam.pos:clone()

	if (btnp(0)) cam.pos.x-=move
	if (btnp(1)) cam.pos.x+=move
	if (btnp(2)) cam.pos.y-=move
	if (btnp(3)) cam.pos.y+=move
	if (btnp(4)) cam.pos.z+=move
	if (btnp(5)) cam.pos.z-=move
		
	if not vec3.eq(pos,cam.pos)
	then
		start_calc()
	end
end

function _draw()
	cls()
	
	sspr(0,0,128,128,0,0,128,128)
	
	if show_state then
		print("pos:"..cam.pos.x..","..cam.pos.y..","..cam.pos.z,0,0,7)
		print("seed:"..seed,0,6,7)
	end
	
	draw_log()
end

function keypress(key)
	if key=="[" then
		px_delta/=2
		px_delta=mid(px_delta,1,128)
		start_calc()
	elseif key=="]" then
		px_delta*=2
		px_delta=mid(px_delta,1,128)
		start_calc()
	end
end

function calc_view()
	local left,right=-1,1
	local top,bottom=-1,1
	local delta=px_delta
	local step=1/(64/delta)
	
	local far=50
	
	for y=top,bottom,step do
		for x=left,right,step do
			local origin=vec3:new(
				{
					x=x+cam.pos.x,
					y=y+cam.pos.y,
					z=0+cam.pos.z
				})
			local dirn=vec3:new(
				{x=x/2,y=y/2,z=1})
			dirn:norm()
							
			local sx=(x+1)/2*127
			local sy=(y+1)/2*127
							
			local hit,dist,norm,col=
				false,32767,nil,12
				
			for sp in all(scene.spheres) do
				local h,d,n,c=
					ray_hit_sphere(
						origin,dirn,
						sp)
																	
				if h and d<dist then
					hit,dist,norm,col=
						h,d,n,c
				end
			end
			
			for pl in all(scene.planes) do
				local h,d,n,c=
					ray_hit_plane(origin,dirn,pl)
						
				if h and d<dist then
					hit,dist,norm,col=
						h,d,n,c
				end
			end
			
			if hit and dist<=far
			then
				local pos=vec3.add(
					origin,vec3.scale(dirn,dist))
				local viewdir=vec3.sub(cam.pos,pos):norm()
				local refldir=vec3.reflect(vec3.neg(scene.lightdir),
					norm)
				local diffuse=(vec3.dot(scene.lightdir,norm)+1)/2
				local ambient=0.1
				local l=mid(diffuse+ambient,0,1)
--				local l=diffuse
				col=fade_col(col,l)
			end
			
			local nsx,nsy=sx+1,sy
			if nsx>127 then
				nsx,nsy=0,nsy+delta
			end


			for xx=0,delta-1 do
				for yy=0,delta-1 do
					sset(nsx+xx,nsy+yy,10)
					sset(sx+xx,sy+yy,col)
				end
			end
		end

	end
end

function ray_hit_sphere(origin,dirn,sph)
	local l=vec3.sub(sph.center,origin)
	local tc=vec3.dot(dirn,l)
	if (tc<0) return false

	local tcp=vec3.add(
		origin,vec3.scale(dirn,tc))
	
	local d=vec3.dist(tcp,sph.center)
	if (d>sph.rad) return false
	
	b=sqrt(sph.rad*sph.rad-d*d)

	local bp=vec3.add(
		tcp,vec3.scale(dirn,-b))
		
	local sd=vec3.sub(bp,sph.center)
	sd:norm()

	return true,tc-b,vec3.scale(sd,-1),sph.col
end

function ray_hit_plane(origin,dirn,pl)
	local denom=vec3.dot(pl.norm,dirn)
	if denom>0.0001 then
		local delta=vec3.sub(pl.origin,origin)
		local t0=vec3.dot(delta,pl.norm)/denom
		if t0>=0 then
			local pt=vec3.add(
				origin,vec3.scale(dirn,t0))
			
			local pd=vec3.dist(pt,pl.origin)
			
			if pd<20 and pd>=0 then	
				return true,t0,pl.norm,pl.col
			end
		end
	end
	return false
end

_log={enabled=true}

function log(m,c)
	if not _log.enabled then
		return
	end

	m=tostr(m)
	c=c or 7
	add(_log,{m=m,c=c})
	if #_log>21 then
		for i=2,22 do
			_log[i-1]=_log[i]
		end
		_log[22]=nil
	end
end

function log_on(val)
	_log.enabled=val
end

function draw_log()
	local n=#_log
	for i=1,n do
		local l=_log[i]
		local w=#l.m*4
		print(l.m,127-w,(i-1)*6,l.c)
	end
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

vec3=class({x=0,y=0,z=0})

function vec3:clone()
	return vec3:new({
		x=self.x,y=self.y,z=self.z})
end

function vec3.eq(a,b)
	return a.x==b.x and
		a.y==b.y and
		a.z==b.z
end

function vec3.neg(v)
	return vec3:new({x=-v.x,
		y=-v.y,
		z=-v.z})
end

function vec3.sub(a,b)
	return vec3:new({x=a.x-b.x,
		y=a.y-b.y,
		z=a.z-b.z})
end

function vec3.add(a,b)
	return vec3:new({x=a.x+b.x,
		y=a.y+b.y,
		z=a.z+b.z})
end

function vec3.scale(a,s)
	return vec3:new({x=a.x*s,
		y=a.y*s,
		z=a.z*s})
end

function vec3.dot(a,b)
	return a.x*b.x+a.y*b.y+a.z*b.z
end

function vec3.dist(a,b)
	local delta=vec3.sub(b,a)
	return sqrt(
		delta.x*delta.x+
		delta.y*delta.y+
		delta.z*delta.z)
end

function vec3:len()
	return sqrt(self.x*self.x+
		self.y*self.y+
		self.z*self.z)
end

function vec3.reflect(inc,norm)
	return vec3.sub(inc,
		vec3.scale(norm,-vec3.dot(norm,inc)*2))	
end

function vec3:norm()
	local l=self:len()
	if l>0 then
		self.x/=l
		self.y/=l
		self.z/=l
	end
	return self
end

function vec3:tostr()
	return "<"..self.x..","..
		self.y..","..self.z..">"
end

sphere=class({center=vec3:new(),rad=0,col=7})
plane=class({origin=vec3:new(),norm=vec3:new({y=1}),col=7})

-->8
_fades={
	{0,0,0,0,0,0,0,0},
	{1,1,1,1,0,0,0,0},
	{2,2,2,1,1,0,0,0},
	{3,3,4,5,2,1,1,0},
	{4,4,2,2,1,1,1,0},
	{5,5,2,2,1,1,1,0},
	{6,6,13,5,2,1,1,0},
	{7,7,6,13,5,2,1,1},
	{8,8,9,4,5,2,1,0},
	{9,9,4,5,2,1,1,0},
	{10,15,9,4,5,2,1,0},
	{11,11,3,4,5,2,1,0},
	{12,12,13,5,5,2,1,0},
	{13,13,5,5,2,1,1,0},
	{14,9,9,4,5,2,1,0},
	{15,14,9,4,5,2,1,0}
}

function fade_col(col,ft)
	return _fades[col+1][flr(mid(ft,0,1)*8)+1]
end
__gfx__
0000000077aaf66d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d55442100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
