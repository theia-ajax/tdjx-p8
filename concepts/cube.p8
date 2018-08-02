pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	local hs=.5

	pt={}
	for x = 1, -1, -2 do
		for y = 1, -1, -2 do
			for z = 1, -1, -2 do
				local p = vec(x*hs,y*hs,z*hs)
				p.c = vec()
				add(pt,p)
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
		3,7,5,
		1,6,5,
		1,2,6,
		3,8,7,
		8,4,3
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

	draw_mesh(cam, pt, idx, 6)
	draw_mesh_wire(cam, pt, idx, 11)
end

function draw_mesh_wire(cam, vts, idx, col)
	color(col)

	mat = mx_new()
	tr = mx_trans(0, 0, ((sin(t()/4)+1)/2)*4+1)
	rot = mx_mul(mx_rotx(t()/8), mx_roty(t()/4))
	-- rot = mx_roty(t()/4)
	mx_mul(tr, rot, mat)

	for v in all(vts) do
		tform(v, mat, v.c)
	end

	for i = 1, #idx, 3 do
		local v1,v2,v3=vts[idx[i]],
			vts[idx[i+1]],
			vts[idx[i+2]]

		local leg1 = {x=v2.c.x-v1.c.x,y=v2.c.y-v1.c.y,z=v2.c.z-v1.c.z}
		local leg2 = {x=v3.c.x-v1.c.x,y=v3.c.y-v1.c.y,z=v3.c.z-v1.c.z}
		norm(leg1)
		norm(leg2)
		local n = cross(leg1, leg2)
		local cdiff = {x=cam.x-v1.c.x,y=cam.y-v1.c.y,z=cam.z-v1.c.z}
		norm(cdiff)
		local d = dot(n, cdiff)

		if d > 0 or true then
			sx1 = 64+64*v1.c.x/v1.c.z
			sy1 = 64+64*v1.c.y/v1.c.z

			sx2 = 64+64*v2.c.x/v2.c.z
			sy2 = 64+64*v2.c.y/v2.c.z

			sx3 = 64+64*v3.c.x/v3.c.z
			sy3 = 64+64*v3.c.y/v3.c.z

			line(sx1,sy1,sx2,sy2)
			line(sx1,sy1,sx3,sy3)
			line(sx2,sy2,sx3,sy3)
		end
	end
end

function draw_mesh(cam, vts, idx, col)
	color(col)

	mat = mx_new()
	tr = mx_trans(0, 0, ((sin(t()/4)+1)/2)*4+1)
	rot = mx_mul(mx_rotx(t()/8), mx_roty(t()/4))
	-- rot = mx_roty(t()/4)
	mx_mul(tr, rot, mat)

	for v in all(vts) do
		tform(v, mat, v.c)
	end

	for i=1,#idx,3 do
		local v1,v2,v3=vts[idx[i]],
			vts[idx[i+1]],
			vts[idx[i+2]]

		local leg1 = {x=v2.c.x-v1.c.x,y=v2.c.y-v1.c.y,z=v2.c.z-v1.c.z}
		local leg2 = {x=v3.c.x-v1.c.x,y=v3.c.y-v1.c.y,z=v3.c.z-v1.c.z}
		norm(leg1)
		norm(leg2)
		local n = cross(leg1, leg2)
		local cdiff = {x=cam.x-v1.c.x,y=cam.y-v1.c.y,z=cam.z-v1.c.z}
		norm(cdiff)
		local d = dot(n, cdiff)

		if d > 0 or true then
			sx1 = 64+64*v1.c.x/v1.c.z
			sy1 = 64+64*v1.c.y/v1.c.z

			sx2 = 64+64*v2.c.x/v2.c.z
			sy2 = 64+64*v2.c.y/v2.c.z

			sx3 = 64+64*v3.c.x/v3.c.z
			sy3 = 64+64*v3.c.y/v3.c.z

			tri(sx1,sy1,sx2,sy2,sx3,sy3)
		end
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

function vec(x, y, z)
	return {
		x = x or 0, y = y or 0, z = z or 0
	}
end

function tform(v, mx, out)
	out = out or {}

	out.x = v.x*mx[1] + v.y*mx[2] + v.z*mx[3] + mx[4]
	out.y = v.x*mx[5] + v.y*mx[6] + v.z*mx[7] + mx[8]
	out.z = v.x*mx[9] + v.y*mx[10] + v.z*mx[11] + mx[12]
	out.w = v.x*mx[13] + v.y*mx[13] + v.z*mx[14] + mx[15]

	return out
end

k_mx_idt = { 1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1 }
function mx_new(out)
	out = out or {}
	for i=1,16 do out[i]=k_mx_idt[i] end

	out.g = function(self, r, c)
		return self[(r-1)*4+c]
	end

	out.s = function(self, r, c, v)
		self[(r-1)*4+c] = v
	end

	return out
end

function mx_mul(a, b, out)
	out = out or mx_new()

	out:s(1, 1, a:g(1,1)*b:g(1,1)+a:g(1,2)*b:g(2,1)+a:g(1,3)*b:g(3,1)+a:g(1,4)*b:g(4,1))
	out:s(1, 2, a:g(1,1)*b:g(1,2)+a:g(1,2)*b:g(2,2)+a:g(1,3)*b:g(3,2)+a:g(1,4)*b:g(4,2))
	out:s(1, 3, a:g(1,1)*b:g(1,3)+a:g(1,2)*b:g(2,3)+a:g(1,3)*b:g(3,3)+a:g(1,4)*b:g(4,3))
	out:s(1, 4, a:g(1,1)*b:g(1,4)+a:g(1,2)*b:g(2,4)+a:g(1,3)*b:g(3,4)+a:g(1,4)*b:g(4,4))

	out:s(2, 1, a:g(2,1)*b:g(1,1)+a:g(2,2)*b:g(2,1)+a:g(2,3)*b:g(3,1)+a:g(2,4)*b:g(4,1))
	out:s(2, 2, a:g(2,1)*b:g(1,2)+a:g(2,2)*b:g(2,2)+a:g(2,3)*b:g(3,2)+a:g(2,4)*b:g(4,2))
	out:s(2, 3, a:g(2,1)*b:g(1,3)+a:g(2,2)*b:g(2,3)+a:g(2,3)*b:g(3,3)+a:g(2,4)*b:g(4,3))
	out:s(2, 4, a:g(2,1)*b:g(1,4)+a:g(2,2)*b:g(2,4)+a:g(2,3)*b:g(3,4)+a:g(2,4)*b:g(4,4))

	out:s(3, 1, a:g(3,1)*b:g(1,1)+a:g(3,2)*b:g(2,1)+a:g(3,3)*b:g(3,1)+a:g(3,4)*b:g(4,1))
	out:s(3, 2, a:g(3,1)*b:g(1,2)+a:g(3,2)*b:g(2,2)+a:g(3,3)*b:g(3,2)+a:g(3,4)*b:g(4,2))
	out:s(3, 3, a:g(3,1)*b:g(1,3)+a:g(3,2)*b:g(2,3)+a:g(3,3)*b:g(3,3)+a:g(3,4)*b:g(4,3))
	out:s(3, 4, a:g(3,1)*b:g(1,4)+a:g(3,2)*b:g(2,4)+a:g(3,3)*b:g(3,4)+a:g(3,4)*b:g(4,4))

	out:s(4, 1, a:g(4,1)*b:g(1,1)+a:g(4,2)*b:g(2,1)+a:g(4,3)*b:g(3,1)+a:g(4,4)*b:g(4,1))
	out:s(4, 2, a:g(4,1)*b:g(1,2)+a:g(4,2)*b:g(2,2)+a:g(4,3)*b:g(3,2)+a:g(4,4)*b:g(4,2))
	out:s(4, 3, a:g(4,1)*b:g(1,3)+a:g(4,2)*b:g(2,3)+a:g(4,3)*b:g(3,3)+a:g(4,4)*b:g(4,3))
	out:s(4, 4, a:g(4,1)*b:g(1,4)+a:g(4,2)*b:g(2,4)+a:g(4,3)*b:g(3,4)+a:g(4,4)*b:g(4,4))

	return out
end

function mx_trans(tx, ty, tz, out)
	out = out or mx_new()
	out:s(1, 4, tx)
	out:s(2, 4, ty)
	out:s(3, 4, tz)
	return out
end

function mx_scale(sx, sy, sz, out)
	out = out or mx_new()
	out:s(1, 1, sx)
	out:s(2, 2, sx)
	out:s(3, 3, sx)
	return out
end

function mx_rotx(a, out)
	out = out or mx_new(out)
	out:s(2, 2, cos(a))
	out:s(2, 3, -sin(a))
	out:s(3, 2, sin(a))
	out:s(3, 3, cos(a))
	return out
end

function mx_roty(a, out)
	out = out or mx_new(out)
	out:s(1, 1, cos(a))
	out:s(1, 3, -sin(a))
	out:s(3, 1, sin(a))
	out:s(3, 3, cos(a))
	return out
end

function mx_rotz(a, out)
	out = out or mx_new(out)
	out:s(1, 1, cos(a))
	out:s(1, 2, -sin(a))
	out:s(2, 1, sin(a))
	out:s(2, 2, cos(a))
	return out
end

function mx_tostr(m)
	return "["..m:g(1,1).." "..m:g(1,2).." "..m:g(1,3).." "..m:g(1,4).."\n"..
				 " "..m:g(2,1).." "..m:g(2,2).." "..m:g(2,3).." "..m:g(2,4).."\n"..
				 " "..m:g(3,1).." "..m:g(3,2).." "..m:g(3,3).." "..m:g(3,4).."\n"..
				 " "..m:g(4,1).." "..m:g(4,2).." "..m:g(4,3).." "..m:g(4,4).."]"
end