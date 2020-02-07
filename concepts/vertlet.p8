pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
function _init()
	poke(0x5f2d,1)

	net={
		x=stat(32),y=stat(33),
		w=8,h=8,
		space=8,
		pts={},
		links={},
	}
	
	for y=0,net.h-1 do
		for x=0,net.w-1 do
			local px,py=
				x*net.space+net.x,
				y*net.space+net.y
				
			local grav=0
			if (y>1) grav=2
			
			local pinx,piny=nil,nil
			
			if (y==0) pinx,piny=px-net.x,py-net.y

			add(net.pts,{
				x=px,y=py,		-- pos
				lx=px,ly=py,-- last pos
				dx=0,dy=0,		-- velocity
				ddx=0,ddy=20,-- accel
				pin_x=pin_x,pin_y=pin_y, -- pin
				mass=10,
				force=function(self,fx,fy)
					self.ddx+=fx/self.mass
					self.ddy+=fy/self.mass
				end
			})
		end
	end

	local add_link=function(ax,ay,bx,by)
		local a=net.pts[ax+ay*net.w+1]
		local b=net.pts[bx+by*net.w+1]
		return add(net.links,{
			a=a,b=b,
			rest=net.space,
			tear=64,
			stiff=0.4,
		})
	end
	
	local len=#net.pts
	for i=0,len-1 do
		local px,py=i%net.w,
			flr(i/net.w)
			
		if (px>0) add_link(px,py,px-1,py)
		if (py>0) add_link(px,py,px,py-1)		
	end

end

function _update()
	dt=1/30
	
	net.x,net.y=stat(32),stat(33)
	
	local ix,iy=0,0
	
	if (btn(0)) ix-=1
	if (btn(1)) ix+=1
	if (btn(2)) iy-=1
	if (btn(3)) iy+=1
	
	for pt in all(net.pts) do
		pt:force(0,9.8*pt.mass)
		
		pt:force(ix*10,0)
		
	end
	
--	net.y=8+sin(t())*8
--	net.x=32+sin(t()/4)*16
	
	for i=1,16 do
		for link in all(net.links) do
			local p1,p2=link.a,link.b
			
			local dx,dy=p1.x-p2.x,
				p1.y-p2.y
				
			local d=sqrt(dx*dx+dy*dy)
		
			if (d>=link.tear) then
				del(net.links,link)
			end
			
			local diff=(link.rest-d)/d
				
			local tx=dx*link.stiff*diff
			local ty=dy*link.stiff*diff
			
			p1.x+=tx
			p1.y+=ty
	
			p2.y-=tx
			p2.y-=ty
		
		end
	end
	
	for pt in all(net.pts) do
		pt.dx*=0.99
		pt.dy*=0.99
	
		pt.dx=pt.x-pt.lx
		pt.dy=pt.y-pt.ly

		pt.lx=pt.x
		pt.ly=pt.y
		
		pt.x=pt.x+pt.dx+pt.ddx*dt
		pt.y=pt.y+pt.dy+pt.ddy*dt
		
		if (pt.pinx) pt.x=pt.pinx+net.x
		if (pt.piny) pt.y=pt.piny+net.y
		
		pt.ddx,pt.ddy=0,0
	end

end

function _draw()
	cls()

	
	for link in all(net.links) do
		local a,b=link.a,link.b
		
		local col=12
		
		line(a.x,a.y,b.x,b.y,col)
	end
	
	for pt in all(net.pts) do
		pset(pt.x,pt.y,7)
	end

end
-->8
vertlet={
	x=px,y=py,		-- pos
	lx=px,ly=py,-- last pos
	dx=0,dy=0,		-- velocity
	ddx=0,ddy=20,-- accel
	pin_x=nil,pin_y=nil, -- pin
	mass=10,
}

function vertlet:new(p)
	self.__index=self
	return setmetatable(p or {},self)
end

function vertlet:force(fx,fy)
	self.ddx+=fx/self.mass
	self.ddy+=fy/self.mass
end

link={
	a=nil,b=nil,
	rest=1,
	tear=64,
	stiff=0.4,
}

function link:new(p)
	self.__index=self
	return setmetatable(p or {},self)
end

function integrate_verts(points,links)
	for i=1,16 do
		for link in all(links) do
			local p1,p2=link.a,link.b
			
			local dx,dy=p1.x-p2.x,
				p1.y-p2.y
				
			local d=sqrt(dx*dx+dy*dy)
		
			if (d>=link.tear) then
				del(links,link)
			end
			
			local diff=(link.rest-d)/d
				
			local tx=dx*link.stiff*diff
			local ty=dy*link.stiff*diff
			
			p1.x+=tx
			p1.y+=ty
	
			p2.y-=tx
			p2.y-=ty
		
		end
	end
	
	for pt in all(points) do
		pt.dx*=0.99
		pt.dy*=0.99
	
		pt.dx=pt.x-pt.lx
		pt.dy=pt.y-pt.ly

		pt.lx=pt.x
		pt.ly=pt.y
		
		pt.x=pt.x+pt.dx+pt.ddx*dt
		pt.y=pt.y+pt.dy+pt.ddy*dt
		
		if (pt.pin_x) pt.x=pt.pin_x
		if (pt.pin_y) pt.y=pt.pin_y
		
		pt.ddx,pt.ddy=0,0
	end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
