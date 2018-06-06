pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	local hs=.5

	pt={}
	for x = 1, -1, -2 do
		for y = 1, -1, -2 do
			for z = 1, -1, -2 do
				add(pt,{x=x*hs,y=y*hs,z=z*hs})
			end
		end
	end

	lidx={
		1,2,1,5,1,3,
		6,8,6,2,6,5,
		7,3,7,5,7,8,
		4,8,4,2,4,3
	}

	idx={
		1,2,4,
		1,4,3,
		8,2,6,
		8,4,2,
		6,5,7,
		6,7,8,
		1,3,5,
		3,7,5
	}

	cam = {x=0,y=0,z=2}
end

function rot(x,y,a)
	return cos(a)*x-sin(a)*y,
		sin(a)*x+cos(a)*y
end

function _update()
end

function _draw()
	cls()

	for p in all(pt) do
		p.cx,p.cz=rot(p.x,p.z,t()/4)
		p.cy=p.y
		p.cx+=cam.x
		p.cy+=cam.y
		p.cz+=cam.z
	end


	for i=1,#idx,3 do
		local p1,p2,p3=
			pt[idx[i]],
			pt[idx[i+1]],
			pt[idx[i+2]]

		local leg1 = {x=p2.cx-p1.cx,y=p2.cy-p1.cy,z=p2.cz-p1.cz}
		local leg2 = {x=p3.cx-p1.cx,y=p3.cy-p1.cy,z=p3.cz-p1.cz}
		norm(leg1)
		norm(leg2)
		local n = cross(leg1, leg2)
		local cdiff = {x=cam.x-p1.cx,y=cam.y-p1.cy,z=cam.z-p1.cz}
		norm(cdiff)
		local d = dot(n, cdiff)

		if d > 0 then
			sx1 = 64+64*p1.cx/p1.cz
			sy1 = 64+64*p1.cy/p1.cz

			sx2 = 64+64*p2.cx/p2.cz
			sy2 = 64+64*p2.cy/p2.cz

			sx3 = 64+64*p3.cx/p3.cz
			sy3 = 64+64*p3.cy/p3.cz

			tri(sx1,sy1,sx2,sy2,sx3,sy3,7)
		end
	end

	for i=1,#lidx,2 do
		local p1,p2=pt[lidx[i]],
			pt[lidx[i+1]]

		sx1 = 64+64*p1.cx/p1.cz
		sy1 = 64+64*p1.cy/p1.cz

		sx2 = 64+64*p2.cx/p2.cz
		sy2 = 64+64*p2.cy/p2.cz

		line(sx1,sy1,sx2,sy2,11)
	end
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