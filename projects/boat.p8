pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	frame=0

	water={}
	water.y=110
	water.vts={}
	water.vtct=10

	for i=0,water.vtct+1 do
		water.vts[i]={
			x=i*(128/water.vtct),
			y=water.y
		}
	end

	boat={}
	boat.x=40
	boat.y=110
	boat.w=20
	boat.h=8
	boat.hw=boat.w/2
	boat.hh=boat.h/2
	boat.r=0
	boat.spd=0
	boat.mxspd=0.5
	boat.acl=.005
	boat.fric=.0025
	boat.drag=0.2
	boat.dx=0
	boat.dy=0
	boat.dr=0
	
	rocks={}
	add(rocks,{x=127,y=110})
	
	stars={}
	for i=0,15 do
		add(stars,{
			x=rnd(128),
			y=rnd(40),
			m=flr(rnd(10))
		})
	end
end

function _update60()
	water.y=sin(t()/10)*12+100

	for i=0,water.vtct do
		water.vts[i].y=water.y+
			sin(t()/4+i/(water.vtct/1))*4
	end
	
	local ix,iy=0,0
	if (btn(0)) ix-=1
	if (btn(1)) ix+=1
	if (btn(2)) iy-=1
	if (btn(3)) iy+=1
	
	boat.x+=ix*0.2
	
	if btn(4) then
	 boat.spd+=boat.acl
	else
		boat.spd-=boat.fric
	end
	
	boat.spd=clamp(boat.spd,0,boat.mxspd)
	
	boat.x+=boat.spd-boat.drag
	
	boat.x=clamp(boat.x,13,115)
	
	local lx,ly=boat_left()
	local rx,ry=boat_right()
	local left=water_y(lx)
	local right=water_y(rx)
	
	boat.y=water_y(boat.x)-2
	
	boat.r=atan2(rx-lx,right-left)
	
	for r in all(rocks) do
		r.x-=boat.spd/2
	end
	
	frame+=1
end

function _draw()
	cls(9)

	gradv(0,0,130,30,1,2)
	gradv(0,30,130,60,2,9)
	gradv(0,60,130,127,9,8)

	rectrfill(boat.x,boat.y,
		boat.w,boat.h,boat.r,0)
	
	local mastx,masty=
		rotate(0,-20,boat.r)
	line(boat.x,boat.y,
		mastx+boat.x,masty+boat.y,0)
		
	local slcx,slcy=rotate(0,-13,boat.r)
	local f=boat.spd/boat.mxspd
	local frac=max(f*f,0.3)

	rectrfill(slcx+boat.x,slcy+boat.y,
		frac*12,12,boat.r,0)

	for r in all(rocks) do
		circfill(r.x,r.y,8,4)
	end

	for i=0,water.vtct-1 do
		local v1=water.vts[i]
		local v2=water.vts[i+1]
		for y=0,7 do
			line(v1.x,v1.y+y,v2.x,v2.y+y,1)
		end
	end
	rectfill(0,water.y+4,127,127,1)

	for i=0,9 do
		x=rnd(128)
		c=12
		if (rnd(100)<20) c=14
		pset(x,water_y(x),c)
	end
	
	for star in all(stars) do
		if frame%star.m~=0 then
			pset(star.x,star.y,7)
		end
	end
	
	print(boat.x..","..boat.y,0,0,7)
	print(boat.spd,0,6,7)
	
	local mem="mem:"..band(stat(0)/2048,0xffff).."%"
	local cpu="cpu:"..band(stat(1)*100,0xffff).."%"
	print(mem,0,12,7)
	print(cpu,0,18,7)
end

function water_y(x)
	if (x<0 or x>128) return 127
	for i=0,water.vtct-1 do
		if x<water.vts[i+1].x then
			local v1,v2=water.vts[i],
				water.vts[i+1]
			local fx=(x-v1.x)/(v2.x-v1.x)
			return lerp(v1.y,v2.y,fx)
		end
	end
	return 127
end

_k_grad_ptns={
	0x0000,
	0x0208,
	0xa0a0,
	0x5a5a,
	0xf5f5,
	0xbfef,
	0xffff
}

function gradh(x,y,w,h,c1,c2,flp)
	if (flp) c1,c2=c2,c1
end

function gradv(x,y,w,h,c1,c2,flp)
	if (flp) c1,c2=c2,c1
	local col=bor(shl(c2,4),c1)
	local chnks=#_k_grad_ptns
	local delta=h/chnks
	for i=0,chnks-1 do
		fillp(_k_grad_ptns[i+1],flr(t())%4)
		rectfill(x,y+flr(i*delta),
			x+w,y+ceil((i+1)*delta),
			col)
	end

	fillp()
end

-- center x,y
-- width, height
-- rotation 0-1 tau
-- color
function rectr(cx,cy,w,h,r,c)
	local hw,hh=w/2,h/2
	local x1,y1=rotate(-hw,-hh,r)
	local x2,y2=rotate(hw,-hh,r)
	local x3,y3=rotate(-hw,hh,r)
	local x4,y4=rotate(hw,hh,r)
	
	line(x1+cx,y1+cy,x2+cx,y2+cy,c)
	line(x1+cx,y1+cy,x3+cx,y3+cy,c)
	line(x2+cx,y2+cy,x4+cx,y4+cy,c)
	line(x3+cx,y3+cy,x4+cx,y4+cy,c)
end

function rectrfill(cx,cy,w,h,r,c)
	local hw,hh=w/2,h/2
	local x1,y1=rotate(-hw,-hh,r)
	local x2,y2=rotate(hw,-hh,r)
	local x3,y3=rotate(-hw,hh,r)
	local x4,y4=rotate(hw,hh,r)

	line(x2+cx,y2+cy,x3+cx,y3+cy,c)
	tri(x1+cx,y1+cy,
		x2+cx,y2+cy,
		x3+cx,y3+cy,c)
	tri(x3+cx,y3+cy,
		x2+cx,y2+cy,
		x4+cx,y4+cy,c)
end

function rotate(x,y,r)
	return x*cos(r)-y*sin(r),
		x*sin(r)+y*cos(r)
end

function clamp(v,mn,mx)
	if (mx<mn) mn,mx=mx,mn
	return min(max(v,mn),mx)
end

function clamp01(v)
	return clamp(v,0,1)
end

function lerp(a,b,t)
	return a+(b-a)*t
end

function boat_left()
	local x,y=rotate(-boat.hw,
		boat.hw,
		boat.r)
	return x+boat.x,y+boat.y
end

function boat_right()
	local x,y=rotate(boat.hw,
		boat.hw,
		boat.r)
	return x+boat.x,y+boat.y
end


__tri_buff = {{x=0,y=0},{x=0,y=0},{x=0,y=0}}
__top_buff = {{x=0,y=0},{x=0,y=0},{x=0,y=0}}
__bot_buff = {{x=0,y=0},{x=0,y=0},{x=0,y=0}}
function tri(x1,y1,x2,y2,x3,y3,c)
	if (c) color(c)

	vts = __tri_buff
	vts[1].x, vts[1].y = x1, y1
	vts[2].x, vts[2].y = x2, y2
	vts[3].x, vts[3].y = x3, y3

 sort(vts, function(a,b) return a.y<b.y end)

 if vts[1].y == vts[2].y then
 	_fttri(vts)
 elseif vts[3].y == vts[2].y then
 	_fbtri(vts)
	else
		local tx, ty = vts[1].x, vts[1].y
		local mx, my = vts[2].x, vts[2].y
		local bx, by = vts[3].x, vts[3].y
		local x4 = tx +
			round(my-ty)/
			round(by-ty)*
			round(bx-tx)
		local y4 = vts[2].y

		__top_buff[1]=vts[1]
		__top_buff[2]=vts[2]
		__top_buff[3].x=x4
		__top_buff[3].y=y4

		__bot_buff[1]=vts[2]
		__bot_buff[2].x=x4
		__bot_buff[2].y=y4
		__bot_buff[3]=vts[3]
		
		_fbtri(__top_buff)
		_fttri(__bot_buff)
	end
end

function _fttri(vts)
	local bx=round(vts[3].x)
	local by=round(vts[3].y)
	local ty=vts[1].y
	local lx=min(vts[1].x,vts[2].x)
	local rx=max(vts[1].x,vts[2].x)

	local ml=round(bx-lx)/round(by-ty)
	local mr=round(bx-rx)/round(by-ty)

	local l,r=bx,bx

	for y=by,ty,-1  do
		_hline(y,l,r)
		l-=ml
		r-=mr
	end
end

function _fbtri(vts)
	local tx = round(vts[1].x)
	local ty = round(vts[1].y)
	local by = vts[2].y
	local lx = vts[2].x
	local rx = vts[3].x

	local ml = round(lx-tx)/round(by-ty)
	local mr = round(rx-tx)/round(by-ty)

	local l, r = tx, tx

	for y = round(ty), by  do
		_hline(y, l, r)
		l += ml
		r += mr
	end
end

function _hline(y,x1,x2)
	line(x1,y,x2,y)
end

function sort(a,fnlt)
	local i = 2
	while i <= #a do
		local x = a[i]
		local j = i - 1
		while j >= 1 and fnlt(x, a[j]) do
			a[j+1] = a[j]
			j -= 1
		end
		a[j+1] = x
		i += 1
	end
end

function round(n)
	if n-flr(n) < 0.5 then
		return flr(n)
	else
		return ceil(n)
	end
end

function mag(v)
	return sqrt(v.x*v.x+v.y*v.y+v.z*v.z)
end

function norm(v)
	local l = mag(v)
	if l > 0 then
		v.x /= l
		v.y /= l
		v.z /= l
	else
		v.x, v.y, v.z = 0, 0, 0
	end
	return v
end

__sfx__
010f002030075300053000537005370753700630005300053b0753000530005300053607530005300053000530075300053000537005370753000530005300053b07530005300053010536075300053000530005
010f00001f1721f1621f1521f1421f1321f1221f1121f1121f1721f1621f1521f1421f1321f1221f1121f1121e1721e1621e1521e1421e1321e1221e1121e1121e1721e1621e1521e1421e1321e1221e1121e112
010f00001c2361c2361c2361c2361c2361c2361c2361c2361c2261c2261c2261c2261c2261c2261c2261c2261a2361a2361a2361a2361a2361a2361a2361a2361a2261a2261a2261a2261a2261a2261a2261a226
010f00001f1721f1621f1521f1421e1721e1621e1521e1421c1721c1621c1521c1422317223162231522314219172191621915219142191321912219112191121917219162191521914219132191221911219112
010f00001c2361c2361c2361c2361c2361c2361c2361c2361c2261c2261c2261c2261c2261c2261c2261c2261c2361c2361c2361c23618236182361823618236172361723617236172361c2361c2361c2361c236
010f0000231722316223152231421f1721f1621f1521f1421e1721e1621e1521e1422317223162231522314218172181621815218142181321812218112181121817218162181521814218132181221811218112
010f00001a2361a2361a2361a2361a2361a2361a2361a2361a2261a2261a2261a2261a2261a2261a2261a2261c2361c2361c2361c23618236182361823618236172361723617236172361c2361c2361c2361c236
010f00001f1721f1621f1521f1421e1721e1621e1521e1421c1721c1621c1521c14223172231622315223142240050c00500005130052b0050000500005000052f0050000500005001052a005000050000500005
010f0000000000000000000000000000000000000000000000000000000000000000000000000000000000001c2361c2361c2361c23618236182361823618236172361723617236172361c2361c2361c2361c236
010f0000182361823618236182361823618236182361823618226182261822618226182261822618226182261c2361c2361c2361c23618236182361823618236172361723617236172361c2361c2361c2361c236
010f0000266350060400600006000060000600006000060026635006000060000600006000060000600006002d635001000020000100000000060000600006002d63500600006000000000000000000000000000
__music__
00 00424344
00 00414244
01 0001020a
00 0003040a
00 0001020a
00 0005060a
00 0001020a
00 0003040a
00 00010a44
00 0007080a
00 00020a44
02 00090a44

