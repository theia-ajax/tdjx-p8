pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	plr={}
	plr.x=24
	plr.y=64
	plr.dx=0
	plr.dy=0
	plr.bstx=0
	plr.bsty=0
	plr.bstspd=.5
	plr.bstf=0
	plr.bstacl=.2
	plr.bstpwr=1
	plr.bstdrn=.02
	plr.bstlock=false
	plr.r=0
	
	cam={}
	cam.x=0
	cam.y=0
	
	clouds={}
	for i=0,14 do
		add(clouds,{
			x=rnd(128),
			y=rnd(128),
			w=2+rnd(6),
			h=2+rnd(3)
		})
	end
end

function _update()
	for cld in all(clouds) do
		if cam.x>cld.x+cld.w/2 then
			cld.x=cam.x+133
			cld.y=rnd(128)
		end
	end

	local mx,my=0,0

	if (btn(0)) mx-=1
	if (btn(1)) mx+=1
	if (btn(2)) my-=1
	if (btn(3)) my+=1
	
	if mx~=0 then
		plr.dx+=mx*.1
		plr.dx=clamp(plr.dx,-1,1)
	else
		plr.dx*=.97
	end
	
	if my ~= 0 then
 	plr.dy+=my*.1
 	plr.dy=clamp(plr.dy,-1,1)
 else
 	plr.dy*=.97
 end
 
 local a=plr.dy/2
 plr.r=-a*.2
 
 local bst,brk=btn(4),btn(5)
 
 local usebst=not plr.bstlock
 	and (bst or brk)
 
 if usebst then
 	plr.bstpwr-=plr.bstdrn
 	if plr.bstpwr<=0 then
 		plr.bstpwr=0
 		plr.bstlock=true
 	end
 end
 
 if bst and plr.bstpwr>0
 then
 	plr.bstf+=plr.bstacl
 	plr.bstf=min(plr.bstf,1)
 end
 
 if brk and plr.bstpwr>0
 then
 	plr.bstf-=plr.bstacl
 	plr.bstf=max(plr.bstf,-1)
 end
 
 if not usebst then
 	plr.bstpwr+=plr.bstdrn
		if plr.bstpwr>=1 then
			plr.bstpwr=1
			plr.bstlock=false
		end

		if plr.bstf<0 then 	
			plr.bstf+=plr.bstacl
 		plr.bstf=min(plr.bstf,0)
 	elseif plr.bstf>0 then
 		plr.bstf-=plr.bstacl
 		plr.bstf=max(plr.bstf,0)
 	end
 end

 
 local bstfc=plr.bstf*plr.bstspd
 local bx,by=
 	cos(plr.r)*bstfc,
 	sin(plr.r)*bstfc

	plr.x+=plr.dx+bx+1
	plr.y+=plr.dy+by
	
	cam.x+=1
	
	if plr.x-64>cam.x then
		cam.x=plr.x-64
	elseif plr.x-4<cam.x then
		cam.x=plr.x-4
	end
end

function _draw()
	cls(12)

	camera(cam.x,cam.y)
	
	for cld in all(clouds) do
		local hw,hh=cld.w/2,cld.h/2
		rectfill(cld.x-hw,cld.y-hh,
			cld.x+hw,cld.y+hh,7)
	end

	local x1,y1=
		cos(plr.r)*4+plr.x,
		sin(plr.r)*4+plr.y
	local x2,y2=
		cos(plr.r+.33)*3+plr.x,
		sin(plr.r+.33)*3+plr.y
	local x3,y3=
		cos(plr.r+.66)*2+plr.x,
		sin(plr.r+.66)*2+plr.y
		
	line(x1,y1,x2,y2,8)
	line(x2,y2,x3,y3,8)
	line(x3,y3,x1,y1,8)

	camera(0,0)
	
	local cl=1
	if (plr.bstlock) cl=8
	rectfill(0,0,32,4,6)
	rectfill(0,0,32*plr.bstpwr,4,cl)
end

function clamp(v,mn,mx)
	return min(max(v,mn),mx)
end
