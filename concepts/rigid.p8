pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	orbs={}
	for i=0,20 do
		make_orb(rnd(128),-rnd(128),8+(i%7))
	end
end

function _update()
	foreach(orbs,update_orb)
	
	for i=1,#orbs do
		for j=i+1,#orbs do
			local o1,o2=orbs[i],orbs[j]
			if orb_hit(o1,o2) then
				orb_coll(o1,o2)
			end
		end

		local o=orbs[i]		
		if o.y>127-o.r then
			o.y=127-o.r
			o.dy*=-o.bounce
		end
		if o.x<o.r then
			o.x=o.r
			o.dx*=-o.bounce
		end
		if o.x>127-o.r then
			o.x=127-o.r
			o.dx*=-o.bounce
		end
	end
end

function _draw()
	cls()
	
	for orb in all(orbs) do
		circ(orb.x,orb.y,orb.r,orb.c)
	end
end

function make_orb(x,y,c)
	local obj={}
	
	obj.x=x or 0
	obj.y=y or 0
	obj.dx=(rnd()-.5)*3
	obj.dy=0
	obj.ddx=0
	obj.ddy=0.6
	obj.bounce=0.9
	obj.c=c or 7
	obj.r=3
	
	return add(orbs,obj)
end

function orb_hit(o1,o2)
	local dx,dy=o1.x-o2.x,o1.y-o2.y
	return len(dx,dy)<=o1.r+o2.r
end

function orb_coll(o1,o2)
	local dx,dy=o1.x-o2.x,o1.y-o2.y
	local l=len(dx,dy)/2
	local nx,ny=norm(dx,dy)
	o1.x+=nx*l
	o1.y+=ny*l
	o2.x-=nx*l
	o2.y-=ny*l
	o1.dx*=-o1.bounce
	o1.dy*=-o1.bounce
	o2.dx*=-o2.bounce
	o2.dy*=-o2.bounce
end

function update_orb(orb)
	orb.dx+=orb.ddx
	orb.dy+=orb.ddy
	orb.x+=orb.dx
	orb.y+=orb.dy
end

function lerp(a,b,t)
	return a+(b-a)*t
end

function len(x,y)
	return sqrt(x*x+y*y)
end

function norm(x,y)
	local l=len(x,y)
	if (l>0) return x/l,y/l
	return 0,0
end
