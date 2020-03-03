pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
function _init()
	ship={
		x=64,y=64,r=0,
		dx=0,dy=0,
		thrust=0,
	}
end

function _update()
	local ix,iy=0,0
	local pid=0
	
	if (btn(0,pid)) ix-=1
	if (btn(1,pid)) ix+=1
	if (btn(2,pid)) iy-=1
	if (btn(3,pid)) iy+=1
	
	ship.r-=ix*0.025
	
	ship.thrust=max(0,-iy)
	
	mr=clamp_8way(ship.r)

	ship.dx+=ship.thrust*cos(mr)
	ship.dy+=ship.thrust*sin(mr)
	
	ship.x+=ship.dx
	ship.y+=ship.dy
	
	ship.dx=0
	ship.dy=0
	
	local border=9
	local size=128+border*2
	if (ship.x<-border) ship.x+=size
	if (ship.x>128+border) ship.x-=size
	if (ship.y<-border) ship.y+=size
	if (ship.y>128+border) ship.y-=size
end

function _draw()
	cls(1)
	sprr(16,ship.x,ship.y,ship.r)
		print(mr,0,0,11)
end

function sprr(sp,x,y,r)
	cr=r
	x=x or 0
	y=y or 0
	r=((r or 0)+0.0625)%1
	spr(sp+r*8,x-4,y-4)
	
	line(x,y,x+cos(cr)*10,y+sin(cr)*10,10)
end

function clamp_8way(r)
	r=r or 0
	return (r+0.0625)%1

end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000cc00000000000000000000000d00000000000000d00000000000000000000000000000000000000000000000000000000000000000000
0dddd000000dccc0000770000cccd000000dddd0000dcc000dccccd000ccd0000000000000000000000000000000000000000000000000000000000000000000
0ccccc0000dc77c000c77c000c77cd0000ccccc000dcccc00dccccd00ccccd000000000000000000000000000000000000000000000000000000000000000000
0cccc77c0dcc77c00dccccd00c77ccd0c77cccc00dcccccd0dccccd0dcccccd00000000000000000000000000000000000000000000000000000000000000000
0cccc77cdcccccd00dccccd00dcccccdc77cccc00c77ccd00dccccd00dcc77c00000000000000000000000000000000000000000000000000000000000000000
0ccccc000ccccd000dccccd000dcccc000ccccc00c77cd0000c77c0000dc77c00000000000000000000000000000000000000000000000000000000000000000
0dddd00000ccd0000dccccd0000dcc00000dddd00cccd00000077000000dccc00000000000000000000000000000000000000000000000000000000000000000
00000000000d0000000000000000d0000000000000000000000cc000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000aa0000aa0000aa00000000000000000a90000a99a00009a00000000000000000000000000000000000000000000000000000000000000000000
0aa00000000099a0000aa0000a99000000000aa0000a999000a99a000999a0000000000000000000000000000000000000000000000000000000000000000000
09999aa000a999000009900000999a000aa99990000999a0000990000a9990000000000000000000000000000000000000000000000000000000000000000000
09999aa00a99900000099000000999a00aa9999000999a000009900000a999000000000000000000000000000000000000000000000000000000000000000000
0aa000000999a00000a99a00000a999000000aa00a990000000aa000000099a00000000000000000000000000000000000000000000000000000000000000000
00000000009a000000a99a000000a900000000000aa00000000aa00000000aa00000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000a00000000000000a00000000000000000000000000000000000000000000000000000000000000000000
00a000000000aa00000aa00000aa000000000a000000990000a99a00009900000000000000000000000000000000000000000000000000000000000000000000
00999a0000099a000009900000a9900000a99900000999a0000990000a9990000000000000000000000000000000000000000000000000000000000000000000
00999a000a99900000099000000999a000a9990000a990000009900000099a000000000000000000000000000000000000000000000000000000000000000000
00a000000099000000a99a000000990000000a0000aa0000000aa0000000aa000000000000000000000000000000000000000000000000000000000000000000
00000000000a0000000000000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
