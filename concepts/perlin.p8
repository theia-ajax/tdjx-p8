pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- perlin

function shuffle(a)
	local n=#a
	for i=1,n-1 do
		local j=flr(rnd(n-i))+i
		a[i],a[j]=a[j],a[i]
	end
end

_noise={}
for i=1,256 do
	_noise[i]=i
end
shuffle(_noise)


function perlin(x,y,z)
	z=z or 0
	
	local ix=band(flr(x),255)
	local iy=band(flr(y),255)
	local iz=band(flr(z),255)
	
	x-=flr(x)
	y-=flr(y)
	z-=flr(z)
	
	local u,v,w=fade(x),fade(y),fade(z)
	
	local a=_noise[ix+1]+iy
	local aa=_noise[a+1]+iz
	local ab=_noise[a+2]+iz
	local b=_noise[ix+2]+iy
	local ba=_noise[b+1]+iz
	local bb=_noise[b+2]+iz
	
	local l1=lerp(
				grad(_noise[aa+1],x,y,z),
				grad(_noise[ba+1],x-1,y,z),
				u)
	
	local l2=lerp(
				grad(_noise[ab+1],x,y-1,z),
				grad(_noise[bb+1],x-1,y-1,z),
				u)
				
	local l3=lerp(
				grad(_noise[aa+2],x,y,z-1),
				grad(_noise[ba+2],x-1,y,z-1),
				u)
				
	local l4=lerp(
				grad(_noise[ab+2],x,y-1,z-1),
				grad(_noise[bb+2],x-1,y-1,z-1),
				u)
	
	local ret=lerp(lerp(l1,l2,v),lerp(l3,l4,v),w)
		
	return (ret+1)/2
end

function fade(a)
	return a*a*a*(a*(a*6-15)+10)
end

function grad(hash,x,y,z)
	local h=band(hash,15)
	local u=x
	if (h<8) u=y
	local v=y
	if h>=4 then
		if h==12 or h==14 then
			v=x
		else
			v=z
		end
	end
	if (band(h,1)~=0) u=-u
	if (band(h,2)~=0) v=-v
	return u+v
end

function lerp(a,b,t)
	return a+(b-a)*t
end
