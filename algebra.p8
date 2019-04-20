pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
function vec3_zero() return vec3:new(0,0,0) end
function vec3_one() return vec3:new(1,1,1) end
function vec3_right() return vec3:new(1,0,0) end
function vec3_up() return vec3:new(0,1,0) end
function vec3_forward() return vec3:new(0,0,1) end

function vec3_is_vec3(o)
	return type(o)=="table" and
		type(o.x)=="number" and
		type(o.y)=="number" and
		type(o.z)=="number"
end

vec3={
	zero=vec3_zero,
	one=vec3_one,
	right=vec3_right,
	up=vec3_up,
	forward=vec3_forward
}

function vec3:new(x,y,z)
	self.__index=self
	return setmetatable(
		{x=x or 0,
			y=y or 0,
			z=z or 0},
		self)
end

function vec3:clone()
	return vec3:new(self.x,self.y,self.z)
end

function vec3:unpack()
	return self.x,self.y,self.z
end

function vec3:__tostring()
	return "<"..self.x..","..self.y..","..self.z..">"
end

function vec3.__unm(a)
	return vec3:new(-a.x,-a.y,-a.z)
end

function vec3.__add(a,b)
	assert(vec3_is_vec3(a))
	return vec3:new(a.x+b.x,
		a.y+b.y,
		a.z+b.z)
end

function vec3.__sub(a,b)
	return vec3:new(a.x-b.x,
		a.y-b.y,
		a.z-b.z)
end

function vec3.__mul(a,b)
	if type(a)=="number" then
		return vec3:new(a*b.x,a*b.y,a*b.z)
	elseif type(b)=="number" then
		return vec3:new(a.x*b,a.y*b,a.z*b)
	else
		return a.x*b.x,a.y*b.y,a.z*b.z
	end
end

function vec3.__div(a,b)
	return vec3:new(a.x/b,a.y/b,a.z/b)
end

function vec3.__eq(a,b)
	return a.x==b.x and
		a.y==b.y and
		b.z==b.z
end

function vec3:len2()
	return self.x*self.x+
		self.y*self.y+
		self.z*self.z
end

function vec3:len()
	return sqrt(self:len2())
end


__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
