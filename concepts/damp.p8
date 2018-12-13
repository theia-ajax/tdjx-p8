pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	val=0
	vel=0
	t0=0
end

function _update60()
	for k,_ in pairs(_watch) do
		_watch[k]=nil
	end
	
	val,vel=damp(val,1,vel,1,nil,1/60)
	if vel>0 then
		t0+=1/60
	end
	
	if btnp(4) then
		val,vel,t0=0,0,0
	end
end

function _draw()
	cls()

	circfill(128-val*128,val*128,4,8)

	local s=tostr(val)
	print(s,64-#s*2,60,7)
	s=tostr(t0)
	print(s,64-#s*2,66,7)
	
	for i=1,#_watch do
		print(_watch[i],0,(i-1)*6,6)
	end
end

-- a: current value
-- b: target value
-- vel: current velocity
-- tm: approx time in seconds to take
-- mx: max speed (defaults inf)
-- ts: timestep (defaults dt)
-- returns result,velocity
-- feed velocity back in
-- to subsequent calls
-- e.g.
-- a,v=damp(a,1,v,0.5,2)
function damp(a,b,vel,tm,mx,ts)
	mx=mx or 32767
	ts=ts or dt
	tm=max(.0001,tm or 0)
	local omega=2/tm
	
	local x=omega*ts
	local exp=1/(1+x+.48*x*x+.235*x*x*x)
	local c=b-a
	local orig=b
	
	local mxc=mx*tm
	c=mid(c,-mxc,mxc)
	b=a-c

	local tmp=(vel+omega*c)*ts
	vel=(vel+omega*tmp)*exp
	local ret=b+(c+tmp)*exp
	
	if (orig-a>0)==(ret>orig) then
		ret=orig
		vel=(ret-orig)/ts
	end
	
	return ret,vel
end

_watch={}

function watch(val)
	add(_watch,tostr(val))
end

