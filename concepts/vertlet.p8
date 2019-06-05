pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
function _init()
	net={
		x=32,y=8,
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
			
			if (y==0) pinx,piny=px,py

			add(net.pts,{
				x=px,y=py,		-- pos
				lx=px,ly=py,-- last pos
				dx=0,dy=0,		-- velocity
				ddx=0,ddy=20,-- accel
				pinx=pinx,piny=piny, -- pin
			})
		end
	end

	local add_link=function(ax,ay,bx,by)
		local a=net.pts[ax+ay*net.w+1]
		local b=net.pts[bx+by*net.w+1]
		return add(net.links,{
			a=a,b=b,
			rest=net.space,
			tear=8,
			stiff=0.5,
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
	
	
	for i=1,6 do
	for link in all(net.links) do
		local p1,p2=link.a,link.b
		
		local dx,dy=p1.x-p2.x,
			p1.y-p2.y
			
		local d=sqrt(dx*dx+dy*dy)
		
		local diff=(link.rest-d)/d
		
		local tx=dx*0.5*diff
		local ty=dy*0.5*diff
		
		p1.x+=tx
		p1.y+=ty

		p2.y-=tx
		p2.y-=ty
	end
	end
	
	for pt in all(net.pts) do
		pt.ddx*=0.9
		pt.ddy*=0.9
	
		pt.dx=pt.x-pt.lx
		pt.dy=pt.y-pt.ly

		pt.lx=pt.x
		pt.ly=pt.y
		
		pt.x=pt.x+pt.dx+pt.ddx*dt
		pt.y=pt.y+pt.dy+pt.ddy*dt
		
		if (pt.pinx) pt.x=pt.pinx
		if (pt.piny) pt.y=pt.piny
		
		if pt.pinx and pt.piny then
			pt.piny=net.y+sin(t())*8
		end
	end

end

function _draw()
	cls()

	for pt in all(net.pts) do
		pset(pt.x,pt.y,7)
	end
	
	for link in all(net.links) do
		local a,b=link.a,link.b
		
		local col=12
		
		line(a.x,a.y,b.x,b.y,col)
		pset(b.x,b.y,10)
	end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
