pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

function _init()
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
	boat.y=64
	boat.r=0
	boat.dx=0
	boat.dy=0
	boat.dr=0
end

function _update()
	for i=0,water.vtct do
		water.vts[i].y=water.y+sin(t()+i/(water.vtct/2))*4
	end
end

function _draw()
	cls(9)

	gradv(0,0,127,30,1,2)
	gradv(0,30,127,60,2,9)
	gradv(0,60,127,127,9,8)

	for i=0,water.vtct-1 do
		local v1=water.vts[i]
		local v2=water.vts[i+1]
		for y=0,7 do
			line(v1.x,v1.y+y,v2.x,v2.y+y,1)
		end
	end
	rectfill(0,water.y+4,127,127,1)

	for i=0,19 do
		x=rnd(128)
		c=12
		if (rnd(100)<5) c=14
		pset(x,water_y(x),c)
	end
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

function gradv(x,y,w,h,c1,c2,sqsh,flp)
	if (flp) c1,c2=c2,c1
	local col=bor(shl(c2,4),c1)
	local chnks=#_k_grad_ptns
	local delta=(h-0)/chnks
	for i=0,chnks-1 do
		fillp(ptnrotr(_k_grad_ptns[i+1],flr(t())%4))
		rectfill(x,y+flr(i*(h/chnks)),
			x+w,y+ceil((i+1)*(h/chnks)),
			col)
	end

	fillp()
end

function lerp(a,b,t)
	return a+(b-a)*t
end

function ptnrotr(ptn,n)
	local p=rotr(ptn,n)
	local m=band(p,0x0000.ffff)
	p=shr(shl(band(p,0xffff.0000),n),n)
	p=bor(p,shl(m,16))
	return p
end

function ptnrotl(ptn,n)
	local p=rotr(ptn,n)
	local m=band(p,0x0000.ffff)
	p=band(p,0xffff.0000)
	p=bor(p,shl(m,16))
	return p
end