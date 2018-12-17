pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	offx=65
	offy=64
end

function _update()
	if (btnp(0)) offx-=1
	if (btnp(1)) offx+=1
	if (btnp(2)) offy-=1
	if (btnp(3)) offy+=1
	
	if (offx<0) offx=127
	if (offx>127) offx=0
	if (offy<0) offy=127
	if (offy>127) offy=0
end

function _draw()
	cls()
	
	n=16
	for i=0,n do
		local h=128/n
		local y=(i*h+t()*32)%(128+h)-h
		rectfill(0,y,127,y+h,8+(i%7))
	end
	
	for i=0,n do
		local w=128/n
		local x=(i*w+t()*32)%128
		line(x,0,x,127,5+(i%3))
	end
	
	srand()
	for i=0,50 do
		rr=rnd()+.2
		r=rr*rr*96
		a=t()*(1/rr)*.1+rnd()
		circfill(cos(a)*r+64,sin(a)*r+64,3+rnd(5),1+i%7)
	end
	
	rect(0,0,127,127,7)
	
	offset_scr(offx,offy)
	
	print("offset:"..offx..","..offy,0,0,6)
	print("cpu:"..stat(1),0,6,6)
end

function offset_scr(ox,oy)
	ox=ox or 0
	oy=oy or 0
	
	if ox~=0 then
		hx=flr(ox/2)
 	for y=0,127 do
 		--scanline address
 		local sla=0x6000+y*64
 		local ihx=64-hx
 	
 		if ox<64 then
 			memcpy(0x4300,sla+ihx,hx)
 			memcpy(sla+hx,sla,ihx)
 			memcpy(sla,0x4300,hx)
 		else
 			memcpy(0x4300,sla,ihx)
 			memcpy(sla,sla+ihx,hx)
 			memcpy(sla+hx,0x4300,ihx)
 		end
 
 		if ox%2==1 then
 			local tmp=peek(sla+63)
 			for x=0,63 do
 				local addr=sla+x
 				local c=peek(addr)
 				local ch=shl(band(c,0xf),4)
 				local cl=shr(band(tmp,0xf0),4)
 				tmp=c
 				poke(addr,bor(ch,cl))
 			end
 		end
 	end
 end
	
	if oy~=0 then
		local h,t=oy*64,(128-oy)*64
 	if oy<64 then
 		memcpy(0x4300,0x6000+t,h)
 		memcpy(0x6000+h,0x6000,t)
 		memcpy(0x6000,0x4300,h)
 	else
 		memcpy(0x4300,0x6000,t)
 		memcpy(0x6000,0x6000+t,h)
 		memcpy(0x6000+h,0x4300,t)
 	end
 end
end

function mod(a,b)
	local r=a%b
	if r>=0 then
		return r
	else
		return r+b
	end
end
