pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
function _init()
	poke(0x5f2d,1)

	player={
		x=8,y=8,rad=0.25,r=0,
		dx=0,dy=0,
	}
end

function _update()
	local ix,iy=0,0
	
	if (btn(0,1)) ix-=1
	if (btn(1,1)) ix+=1
	if (btn(2,1)) iy-=1
	if (btn(3,1)) iy+=1
	
	local mx,my=norm(ix,iy)
	
	local mou_x,mou_y=stat(32),stat(33)
	
	local look_x,look_y=
		(mou_x/8)-player.x,
		(mou_y/8)-player.y
	look_x,look_y=norm(look_x,look_y)
	
	local targ_r=atan2(look_x,look_y)
	
	local accel=0.01
	player.dx+=accel*mx
	player.dy+=accel*my
	
	local max_speed=0.1
	local slow_speed=0.02
	local speed=len(player.dx,player.dy)
	if speed>max_speed then
		local nx,ny=norm(
			player.dx,player.dy)
		local fx,fy=-nx*slow_speed,
			-ny*slow_speed
		
		local ndx,ndy=player.dx+fx,
			player.dy+fy
			
		if sgn(dot(ndx,ndy,player.dx,player.dy))<0
		then
			player.dx=0
			player.dy=0
		else
			player.dx=ndx
			player.dy=ndy
		end
	end
	
	player.x+=player.dx
	player.y+=player.dy
	
	player.r=targ_r
end

function _draw()
	cls()

	local px,py=w2s(player.x,player.y)
	local rad=w2s(player.rad)
	circfill(px,py,rad,8)
	
	line(px,py,px+cos(player.r)*64,py+sin(player.r)*64,10)

	circ(stat(32),stat(33),1,11)	
end

function w2s(x,y)
	return x*8,(y or 0)*8
end

function len(x,y)
	return sqrt(x*x+y*y)
end

function norm(x,y)
	local l=len(x,y)
	if (l>0) return x/l,y/l
	return 0,0
end

function dot(x1,y1,x2,y2)
	return x1*x2+y1*y2
end

_sgn=sgn
function sgn(v)
	if (v==0) return 0
	return _sgn(v)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
