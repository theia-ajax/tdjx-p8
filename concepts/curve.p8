pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
pts={
	{x=32,y=96},
	{x=32,y=32},
	{x=64,y=32},
	{x=100,y=40},
	{x=120,y=60},
}

function _init()
end

function _update()
end

function _draw()
	cls()
	
	for i=1,#pts-1 do
		local p1,p2=pts[i],pts[i+1]
//		line(p1.x,p1.y,p2.x,p2.y,12)
	end

	local segments=10
	for i=1,#pts-2,2 do
		local p1,p2,p3=pts[i],pts[i+1],pts[i+2]
		for j=0,segments-1 do
			local t1=j/segments
			local t2=(j+1)/segments
			local a1=lerpp(p1,p2,t1)
			local b1=lerpp(p2,p3,t1)
			local c1=lerpp(a1,b1,t1)
			local a2=lerpp(p1,p2,t2)
			local b2=lerpp(p2,p3,t2)
			local c2=lerpp(a2,b2,t2)
			line(c1.x,c1.y,c2.x,c2.y,8)
		end
	end
	
	local t=t()%1
	local a=lerpp(pts[1],pts[2],t)
	local b=lerpp(pts[2],pts[3],t)
	local c=lerpp(a,b,t)
	circfill(c.x,c.y,4,8)
end

function evalcurve(t)
	
end

function lerp(a,b,t)
	return a+(b-a)*t
end

function lerpp(a,b,t)
	return {
		x=lerp(a.x,b.x,t),
		y=lerp(a.y,b.y,t),
	}
end

function subp(a,b)
	return {
		x=a.x-b.x,
		y=a.y-b.y,
	}
end

function addp(a,b)
	return {
		x=a.x+b.x,
		y=a.y+b.y,
	}
end

function midp(a,b)
	return {
		x=(a.x+b.x)/2,
		y=(a.y+b.y)/2,
	}
end
