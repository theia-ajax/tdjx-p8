pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
#include util.p8
#include class.p8

function _init()
	triangle=polygon:new({
		points={
			1,0,
			-1,-0.5,
			-1,0.5
		}
	})
end

function _update()
end

function _draw()
	cls()
	triangle:draw(64,64,t(),10,10)
	
	draw_log()
	draw_watches()
end

-->8
function rotate(x,y,r)
	x=x or 0
	y=y or 0
	r=r or 0
	
	return cos(r)*x-sin(r)*y,
		sin(r)*x+cos(r)*y
end

function transform(x,y,tx,ty,r,sx,sy)
	x=x or 0
	y=y or 0
	tx=tx or 0
	ty=ty or 0
	r=r or 0
	sx=sx or 1
	sy=sy or 1
	return (cos(r)*x-sin(r)*y)*sx+tx,
		(sin(r)*x+cos(r)*y)*sy+ty
end

polygon=class({})

function polygon:create()
end

function polygon:draw(tx,ty,rot,sx,sy)
	tx=tx or 0
	ty=ty or 0
	rot=rot or 0
	sx=sx or 1
	sy=sy or 1

	local n=#self.points
	for i=0,n-1,2 do
		local ax=self.points[i+1]
		local ay=self.points[i+2]
		local bi=i+2
		if (i==n-2) bi=0
		local bx=self.points[bi+1]
		local by=self.points[bi+2]
		
		ax,ay=transform(ax,ay,tx,ty,rot,sx,sy)
		bx,by=transform(bx,by,tx,ty,rot,sx,sy)
	 
	 line(ax,ay,bx,by,7)
	end
	
	for i=0,n-1,2 do
		local px,py=transform(
			self.points[i+1],
			self.points[i+2],
			tx,ty,rot,sx,sy)
		pset(px,py,8)
	end
end

-- perspective camera
pcamera=class({})
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
