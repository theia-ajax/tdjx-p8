pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	pl={x=0,y=0,r=.25}
	vts={
		{x=-16,y=-16},
		{x=16,y=-16},
		{x=57-32,y=32-32},
		{x=48-32,y=60-32},
		{x=34-32,y=58-32},
		{x=20-32,y=40-32},
		{x=-16,y=-16},
	}
end

function _update()
	local ix,iy=0,0
	
	if (btn(0)) ix+=1
	if (btn(1)) ix-=1
	if (btn(2)) iy+=1
	if (btn(3)) iy-=1
	
	pl.r+=ix*0.025
	
	pl.x+=cos(pl.r)*0.5*iy
	pl.y+=sin(pl.r)*0.5*iy
	
	local sx=0
	if (btn(0,1)) sx+=1
	if (btn(1,1)) sx-=1
	
	pl.x+=cos(pl.r+1/4)*0.5*sx
	pl.y+=sin(pl.r+1/4)*0.5*sx
end

function _draw()
	cls(5)
	
	view(0,0,64,64,10)
		local px,py=pl.x,pl.y
		lx,ly=pl.x+cos(pl.r)*2,
			pl.y+sin(pl.r)*2
		line(px,py,lx,ly,6)
		pset(px,py,7)
		
		for i=1,#vts-1 do
			line(vts[i].x,vts[i].y,
				vts[i+1].x,vts[i+1].y,7+(i%8))
		end
	endview()
	
	view(64,0,64,64,11)
		local px,py=0,0
		local lx,ly=2,0
		line(px,py,lx,ly,6)
		pset(px,py,7)
	
		for i=1,#vts-1 do
			local wx0,wy0=vts[i].x-pl.x,vts[i].y-pl.y
			local wx1,wy1=vts[i+1].x-pl.x,vts[i+1].y-pl.y
			local a=-pl.r
			vx0=cos(a)*wx0-sin(a)*wy0
			vy0=sin(a)*wx0+cos(a)*wy0
			vx1=cos(a)*wx1-sin(a)*wy1
			vy1=sin(a)*wx1+cos(a)*wy1
			line(vx0,vy0,vx1,vy1,7+(i%8))
		end
	endview()
	
	view(0,64,64,64,12)
		for i=1,#vts-1 do
			-- model space
			local mx1,mz1=vts[i].x-pl.x,vts[i].y-pl.y
			local mx2,mz2=vts[i+1].x-pl.x,vts[i+1].y-pl.y

			-- world space
			local a=pl.r			
			wx1=sin(a)*mx1-cos(a)*mz1
			wz1=cos(a)*mx1+sin(a)*mz1
			wx2=sin(a)*mx2-cos(a)*mz2
			wz2=cos(a)*mx2+sin(a)*mz2
			
			if wz1>0 or wz2>0 then
				local ix1,iz1=intersect(
					wx1,wz1,wx2,wz2,-0.0001,0.0001,-20,5)
			
				local ix2,iz2=intersect(
					wx1,wz1,wx2,wz2,-0.0001,0.0001,20,5)
					
				if wz1<=0 then
					if iz1>0 then
						wx1=ix1
						wz1=iz1
					else
						wx1=ix2
						wz1=iz2
					end
				end
				
				if wz2<=0 then
					if iz1>0 then
						wx2=ix1
						wz2=iz1
					else
						wx2=ix2
						wz2=iz2
					end
				end
			
				local scl=48
				
 			-- view space
 			vx1=-wx1*scl/wz1
 			vy1a=-scl*2/wz1
 			vy1b=scl*2/wz1
 
 			vx2=-wx2*scl/wz2
 			vy2a=-scl*2/wz2
 			vy2b=scl*2/wz2

				for x=vx1,vx2 do
					local vt=(x-vx1)/(vx2-vx1)
					line(x,lerp(vy1a,vy2a,vt),
						x,lerp(vy1b,vy2b,vt),7+(i%8))
				end
	 			
 		end
		end	
	endview()
end

_view={x=0,y=0,w=127,h=127,c=nil}

function view(x,y,w,h,c)
	x=x or 0
	y=y or 0
	w=w or 127
	h=h or 127
	
	_view.x=x
	_view.y=y
	_view.w=w
	_view.h=h
	_view.c=c
	
	camera(-x-w/2,-y-h/2)
	clip(x,y,w,h)
end

function endview()
	if _view.c then
		camera(-_view.x,-_view.y)
		rect(0,0,_view.w-1,_view.h-1,_view.c)
	end
end

function cross(x1,y1,x2,y2)
	return x1*y2-y1*x2
end

function lerp(a,b,t)
	return a+(b-a)*t
end

function
intersect(x1,y1,x2,y2,x3,y3,x4,y4)
	local x,y=0,0
	x=cross(x1,y1,x2,y2)
	y=cross(x3,y3,x4,y4)
	det=cross(x1-x2,y1-y2,x3-x4,y3-y4)
	x=cross(x,x1-x2,y,x3-x4)/det
	y=cross(x,y1-y2,y,y3-y4)/det
	return x,y
end
