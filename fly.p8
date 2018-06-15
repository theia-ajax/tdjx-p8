pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	plr={}
	plr.x=24
	plr.y=64
	plr.bstx=0
	plr.bsty=0
	plr.bstspd=2
	plr.brkspd=.5
	plr.bstf=0
	plr.bstacl=.2
	plr.bstpwr=1
	plr.bstdrn=.015
	plr.bstlock=false
	plr.spdmx=2
	plr.acl=.05
	plr.spd=0
	plr.r=0
	plr.dr=.01
	plr.rmx=.25*.66
	
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

	local my=0

	if (btn(2)) my-=1
	if (btn(3)) my+=1
		
	if my ~= 0 then
 	plr.r+=plr.dr*-my
 	plr.r=clamp(plr.r,-plr.rmx,
 		plr.rmx)
 else
		if plr.r<0 then
			plr.r+=plr.dr
			plr.r=min(plr.r,0)
		elseif plr.r>0 then
			plr.r-=plr.dr
			plr.r=max(plr.r,0)
		end
 end
 
 if plr.y<9 then
 	plr.y=9
 	plr.r=lerp(plr.r,0,.5)
 elseif plr.y>123 then
 	plr.y=123
  plr.r=lerp(plr.r,0,.5)
 end
 
 local bst,brk=btn(1),btn(0)
 
 if (bst and brk) brk=false
 
 if not bst and not brk and
 	plr.bstpwr>=1
 then
 	plr.bstlock=false
 end
 
 local usebst=not plr.bstlock
 	and (bst or brk)
 
 if usebst then
 	plr.bstpwr-=plr.bstdrn
 	if plr.bstpwr<=0 then
 		plr.bstpwr=0
 		plr.bstlock=true
 	end
 end
 
 if bst and not plr.bstlock
 then
 	plr.bstf+=plr.bstacl
 	plr.bstf=min(plr.bstf,1)
 end
 
 if brk and not plr.bstlock
 then
 	plr.bstf-=plr.bstacl
 	plr.bstf=max(plr.bstf,-1)
 end
 
 if not usebst then
 	plr.bstpwr+=plr.bstdrn
		if plr.bstpwr>=1 then
			plr.bstpwr=1
		end

		if plr.bstf<0 then 	
			plr.bstf+=plr.bstacl
 		plr.bstf=min(plr.bstf,0)
 	elseif plr.bstf>0 then
 		plr.bstf-=plr.bstacl
 		plr.bstf=max(plr.bstf,0)
 	end
 end


	local spd=plr.bstspd
	if (brk) spd=plr.brkspd
 local bstfc=plr.bstf*spd
 local bx,by=
 	cos(plr.r)*bstfc,
 	sin(plr.r)*bstfc

	plr.spd+=plr.acl
	plr.spd=clamp(plr.spd,
		-plr.spdmx,plr.spdmx)

	plr.dx=cos(plr.r)*plr.spd
	plr.dy=sin(plr.r)*plr.spd

	plr.x+=plr.dx+bx
	plr.y+=plr.dy+by
	
	if plr.x-24>cam.x then
		cam.x=plr.x-24
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
		cos(plr.r)*5+plr.x,
		sin(plr.r-.07)*6+plr.y
	local x2,y2=
		cos(plr.r+.33)*3+plr.x,
		sin(plr.r+.33)*3+plr.y
	local x3,y3=
		cos(plr.r+.66)*2+plr.x,
		sin(plr.r+.66)*3+plr.y
		
	tri(x1,y1,x2,y2,x3,y3,8)
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

function lerp(a,b,t)
	return a+(b-a)*t
end
-->8
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
			(my-ty)/
			(by-ty)*
			(bx-tx)
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
	local bx = vts[3].x
	local by = vts[3].y
	local ty = vts[1].y
	local lx = min(vts[1].x, vts[2].x)
	local rx = max(vts[1].x, vts[2].x)

	local ml = (bx-lx)/(by-ty)
	local mr = (bx-rx)/(by-ty)

	local l, r = bx, bx

	for y = by, ty, -1  do
		_hline(y, l, r)
		l -= ml
		r -= mr
	end
end

function _fbtri(vts)
	local tx = vts[1].x
	local ty = vts[1].y
	local by = vts[2].y
	local lx = vts[2].x
	local rx = vts[3].x

	local ml = (lx-tx)/(by-ty)
	local mr = (rx-tx)/(by-ty)

	local l, r = tx, tx

	for y = ty, by  do
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

function cross(a, b, out)
	out = out or {}

	out.x = a.y*b.z-a.z*b.y
	out.y = a.z*b.x-a.x*b.z
	out.z = a.x*b.y-a.y*b.x

	return out
end

function dot(a, b)
	return a.x*b.x+a.y*b.y+a.z*b.z
end

