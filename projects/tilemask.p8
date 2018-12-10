pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	poke(0x5f2d,1)

	num=0
	bits=4
	
	mx=shl(1,bits)
	
	cols={}
	for i=1,bits do
		add(cols,5)
	end
	
	mos={
		x=0,y=0,bt=0,
		px=0,py=0,pbt=0,
	}
end

function _update()
	mos.px,mos.py,mos.pbt=mos.x,mos.y,mos.bt
	mos.x=stat(32)
	mos.y=stat(33)
	mos.bt=stat(34)

	local amt=1
	if (btn(4)) amt=8
	
	if btnp(0) then
		num-=amt
		if (num<0) num+=mx
	end
	
	if btnp(1) then
		num+=amt
		if (num>mx-1) num-=mx
	end
	
	for i=1,bits do
		check_bit(i)
	end
	
	if mos.bt==1 and mos.pbt==0 then
		local sq=in_square(mos.x,mos.y,bits)
		if sq>=1 and sq<=bits then
			num=bxor(num,shl(1,sq-1))
		end
	end
end

function check_bit(b)
	if band(num,shl(1,b-1))~=0 then
		cols[b]=7
	else
		cols[b]=0
	end
end

function _draw()
	cls()
	
	print(lz3(num),59,8,7)
	
	if bits==8 then
 	rectfill(16,16,47,47,cols[1])
 	rectfill(48,16,79,47,cols[2])
 	rectfill(80,16,112,47,cols[3])
 	rectfill(16,48,48,79,cols[4])
 	rectfill(48,48,79,79,6)
 	rectfill(80,48,112,79,cols[5])
 	rectfill(16,80,48,112,cols[6])
 	rectfill(48,80,79,112,cols[7])
 	rectfill(80,80,112,112,cols[8])
 elseif bits==4 then
 	rectfill(48,16,79,47,cols[1])
 	rectfill(16,48,48,79,cols[2])
 	rectfill(48,48,79,79,6)
 	rectfill(80,48,112,79,cols[3])
 	rectfill(48,80,79,112,cols[4])
 end

	print(mos.x..","..mos.y..":"..mos.bt,0,0,7)
	circ(mos.x,mos.y,1,11)
end

function in_square(x,y,m)
	local offx,offy=16,16
	local szx,szy=32,32
	local bx,by=x or 0,y or 0
	
	bx-=offx
	by-=offy
	
	bx=flr(bx/szx)
	by=flr(by/szy)
	
	if m==4 then
		if (bx==1 and by==0) return 1
		if (bx==0 and by==1) return 2
		if (bx==2 and by==1) return 3
		if (bx==1 and by==2) return 4
	elseif m==8 then
		if (bx==0 and by==0) return 1
		if (bx==1 and by==0) return 2
		if (bx==2 and by==0) return 3
		if (bx==0 and by==1) return 4
		if (bx==2 and by==1) return 5
		if (bx==0 and by==2) return 6
		if (bx==1 and by==2) return 7
		if (bx==2 and by==2) return 8
	end
	
	return -1
end

function lz3(n)
	if n<10 then
		return "00"..tostr(n)
	elseif n<100 then
		return "0"..tostr(n)
	else
		return tostr(n)
	end
end
