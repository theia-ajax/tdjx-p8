pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	poke(0x5f2d,1)

	plr={}
	plr.x=64
	plr.y=64
	plr.dx=0
	plr.dy=0
	plr.r=0
end

function _update()

	local movx,movy=0,0
	
	if(btn(1,1))movx+=1
	if(btn(0,1))movx-=1
	if(btn(3,1))movy+=1
	if(btn(2,1))movy-=1
	
	movx,movy=norm(movx,movy)
	plr.dx=movx*2
	plr.dy=movy*2
	
	plr.x+=plr.dx
	plr.y+=plr.dy
	
	local mx,my=stat(32),stat(33)
	plr.r=atan2(mx-plr.x,my-plr.y)
end

function _draw()
	cls()
	circ(plr.x,plr.y,4,7)
	
	line(plr.x,plr.y,
		plr.x+cos(plr.r)*4,
		plr.y+sin(plr.r)*4,7)
		
	local mx,my=stat(32),stat(33)
	line(mx-1,my,mx+1,my,11)
	line(mx,my-1,mx,my+1,11)
end

function len(x,y)
	return sqrt(x*x+y*y)
end

function norm(x,y)
	local l=len(x,y)
	if(l>0)return x/l,y/l
	return x,y
end
