pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

function _init()
	mesh={
		verts={
			{pos=v2(-1,1),uv=v2(0,0)},
			{pos=v2(1,1),uv=v2(2,0)},
			{pos=v2(1,-1),uv=v2(0,2)},
			{pos=v2(-1,-1),uv=v2(2,2)},		
		},
		tris={1,2,3,3,4,1},
	}
	
	g={
		model=mat4:new(1)
	}
	
	watches={}
end

function _update()
	g.model=mat4:new(1)

	g.model:scale(v2(8,8))
	g.model:translate(v2(8,8))
--	g.model:rotate_z(t()/8)
--	g.model:scale(v2(1,2))

	if (btnp(2)) g_f-=1
	if (btnp(3)) g_f+=1
end
g_f=0

function _draw()
	cls()

	local n=#mesh.tris
	for i=1,n,3 do
		local ia=mesh.tris[i]
		local ib=mesh.tris[i+1]
		local ic=mesh.tris[i+2]
	
		local a=mesh.verts[ia]
		local b=mesh.verts[ib]
		local c=mesh.verts[ic]

		local wa=
			mat4.tx_pos(a.pos,g.model)
		local wb=
			mat4.tx_pos(b.pos,g.model)
		local wc=
			mat4.tx_pos(c.pos,g.model)
			
		tri(wa,wb,wc)
--		line(wa.x,wa.y,wb.x,wb.y,10)
--		line(wa.x,wa.y,wc.x,wc.y,10)
--		line(wb.x,wb.y,wc.x,wc.y,10)
	end
	
--	tri(v2(30,20),v2(50,40),v3(t()*10,40))
	
--	tri(v2(64,10),v2(32,30),v2(32,10+t()*10))
--	tri(v2(64,10),v2(32,30),v2(96,25+g_f))
	
	camera()
	local n=#watches
	for i=1,n do
		print(watches[i],0,(i-1)*6,11)
	end
	watches={}
end

function watch(m)
	add(watches,tostr(m))
end
-->8
-- math

function valid_idx(i,c)
	assert(i>=1 and i<=c or c==0)
end

vec4={x=0,y=0,z=0,w=1}
p3=function(x,y,z) return vec4:new(x,y,z,0) end
p2=p3
v4=function(x,y,z,w) return vec4:new(x,y,z,w) end
v3=v4
v2=v4

function vec4:new(x,y,z,w)
	self.__index=self
	self.__tostring=function(self)
		return "<"..self.x..","..self.y..">"
	end
	return setmetatable({
			x=x,y=y,z=z,w=w,

		},self)
end

function vec4:add(b)
	self.x+=b.x
	self.y+=b.y
	self.z+=b.z
	self.w+=b.w
end

mat4={}
m4=function(i)return mat4:new(i)end

function mat4:new(i)
	i=i or 1
	self.__index=self
	self.__tostring=function(self)
		local str=""
		for i=1,16 do
			local vs=tostr(self[i])
			local n=#vs
			for i=1,7-n do
				str=str.." "
			end
			str=str..vs
			if i<16 then
				str=str..","
				if i%4==0 then
					str=str.."\n"
				end
			end
		end
		str=str.."]"
		return str
	end
	return setmetatable({
		i,0,0,0,
		0,i,0,0,
		0,0,i,0,
		0,0,0,i,
	},self)
end

function mat4:clone()
	local ret=mat4:new(1)
	for i=1,16 do
		ret[i]=self[i]
	end
	return ret
end

function mat4:copy(to)
	for i=1,16 do
		to[i]=self[i]
	end
end

function m(row,col)
	return ((col or 1)-1)*4+row
end

function mat4.make_rotate_y(t,out)
	out=out or mat4:new(1)
	out[m(1,1)]=cos(t)
	out[m(1,3)]=-sin(t)
	out[m(3,1)]=sin(t)
	out[m(3,3)]=cos(t)
	return out
end

function mat4.make_rotate_z(t,out)
	out=out or mat4:new(1)
	out[m(1,1)]=cos(t)
	out[m(1,2)]=-sin(t)
	out[m(2,1)]=sin(t)
	out[m(2,2)]=cos(t)
	return out
end

function mat4.make_translate(pos,out)
	out=out or mat4:new(1)
	out[m(1,4)]=pos.x
	out[m(2,4)]=pos.y
	out[m(3,4)]=pos.z
	return out
end

function mat4.make_scale(scl,out)
	out=out or mat4:new(1)
	out[m(1,1)]=scl.x
	out[m(2,2)]=scl.y
	out[m(3,3)]=scl.z
	return out
end

function mat4:translate(pos)
	self:mul(mat4.make_translate(pos))
end

function mat4:rotate_z(t)
	self:mul(mat4.make_rotate_z(t))
end

function mat4:scale(scl)
	self:mul(mat4.make_scale(scl))
end

g_buf=mat4:new(1)
function mat4:mul(b)
	local a=g_buf
	self:copy(a)
	for i=1,4 do
		for j=1,4 do
			local c=0
			for k=1,4 do
				c+=a[m(i,k)]*b[m(k,j)]
			end
			self[m(i,j)]=c
		end
	end
end

function mat4.f(a,b,out)
	out=out or mat4:new(1)
	for i=1,4 do
		for j=1,4 do
			local c=0
			for k=1,4 do
				c+=a[m(i,k)]*b[m(k,j)]
			end
			out[m(i,j)]=c
		end
	end
	return out
end

function mat4.tx_pos(pos,mat,out)
	out=out or p3()
	local p={pos.x,pos.y,pos.z,0}
	for i=1,4 do
		p[i]=mat[m(i,1)]*pos.x+
			mat[m(i,2)]*pos.y+
			mat[m(i,3)]*pos.z+
			mat[m(i,4)]*pos.w
	end
	out.x=p[1]
	out.y=p[2]
	out.z=p[3]
	out.w=p[4]
	return out
end

function sort(a,fn)
	local n=#a
	for i=2,n do
		local j=i
		while j>1 and fn(a[j-1],a[j])
		do
			a[j],a[j-1]=a[j-1],a[j]
			j-=1
		end
	end
end

function tri(p1,p2,p3)
	local pts={p1,p2,p3}
	for pt in all(pts) do
		pt.x,pt.y=flr(pt.x),flr(pt.y)
	end
	sort(pts,function(a,b)
		return a.y>b.y
	end)
	
	local arrstr=function(a)
		local str="["
		local n=#a
		for i=1,n do
			str=str..tostr(a[i])
			if (i<n) str=str..","
		end
		str..="]"
		return str
	end

	local flat_top=function(pts)
		local a,b,c=unpack(pts)
		local l,r=pts[1],pts[2]
		if pts[2].x<pts[1].x then
			l,r=r,l
		end
		
		local dy=c.y-a.y
		local ldx=(c.x-l.x)/dy
		local rdx=(c.x-r.x)/dy
		local lx,rx=l.x,r.x
		
		for y=a.y,c.y do
			local u,v=0,(y-a.y)/16
			tline(lx,y,rx,y,u,v,1/16,0)
			watch(v)
			lx+=ldx
			rx+=rdx
		end
	end
	
	local flat_bot=function(pts)
		local a,b,c=unpack(pts)
		local l,r=pts[2],pts[3]
		if r.x<l.x then
			l,r=r,l
		end
		
		local dy=c.y-a.y
		local ldx=(a.x-l.x)/dy
		local rdx=(a.x-r.x)/dy
		local lx,rx=l.x,r.x
		
		for y=c.y,a.y,-1 do
			line(lx,y,rx,y,10)
			lx+=ldx
			rx+=rdx
		end
	end

	if pts[1].y==pts[2].y
	then
		flat_top(pts)
	elseif pts[2].y==pts[3].y
	then
		flat_bot(pts)
	else
		local a,b,c=unpack(pts)
		local dy=c.y-a.y
		local x4=a.x+(b.y-a.y)/dy*(c.x-a.x)
		local p4=v2(x4,b.y)
		local upper={a,p4,b}
		local lower={p4,b,c}
		
	
		flat_bot(upper)
		flat_top(lower)
		
		pset(p4.x,p4.y,7)

	end
	
	pset(p1.x,p1.y,12)
	pset(p2.x,p2.y,12)
	pset(p3.x,p3.y,12)
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
00ddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0dddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9d1d1d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9d1d1d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0dddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
