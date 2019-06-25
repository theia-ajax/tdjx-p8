pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- math/constants

-- constants
fps30_dt=0x0000.0888
fps60_dt=0x0000.0444

-- math
sgn1=sgn
function sgn(a)
	if (a==0) return 0
	return sgn1(a)
end

function dist2(x1,y1,x2,y2)
	local dx,dy=x2-x1,y2-y1
	return dx*dx+dy*dy
end

function dist(x1,y1,x2,y2)
	return sqrt(dist2(x1,y1,x2,y2))
end

function sqr(n)
	return n*n
end

function angle_to(ox,oy,tx,ty)
	return atan2(tx-ox,ty-oy)
end

function wrap(a,l)
	return mid(a-flr(a/l)*l,0,l)
end

function angle_diff(a,b)
	local d=wrap(b-a,1)
	if (d>0.5) d-=1
	return d
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

function damp_angle(a,b,vel,tm,mx,ts)
	b=a+angle_diff(a,b)
	return damp(a,b,vel,tm,mx,ts)
end

function moveto(a,b,d)
	if abs(b-a)<=d then
		return b
	else
		return a+sgn(b-a)*d
	end
end

function moveto_angle(a,b,d)
	local dl=angle_diff(a,b)
	if -d<dl and dl<d then
		return b
	else
		return moveto(a,a+dl,d)
	end
end

function m01(v)
	return mid(v,0,1)
end

function ilerp(a,b,c)
	local d=b-a
	if (d==0) return 0
	return (c-a)/d
end

function lerp(a,b,t)
	return a+(b-a)*t
end

function lerp_angle(a,b,t)
	local d=wrap((b-a),1)
	if (d>0.5) d-=1
	return a+d*m01(t)
end

function len(x,y)
	return sqrt(x*x+y*y)
end

function norm(x,y)
	local l=len(x,y)
	if (l>0) return x/l,y/l
	return 0,0
end

function midp(x1,y1,x2,y2)
	return (x1+x2)/2,(y1+y2)/2
end

function dot(x1,y1,x2,y2)
	return x1*x2+y1*y2
end

-- rect/collision

function topleft(o)
	return o.x-o.w,o.y-o.h
end

function botright(o)
	return o.x+max(o.w-1,0),o.y+max(o.h-1,0)
end

function rect_draw(r,c,f)
	f=f or rect
	local x1,y1=topleft(r)
	local x2,y2=botright(r)
	f(x1,y1,x2,y2,c)
end

function rect_coll(a,b)
	-- calculates minkowski sum
	-- of rectangles
	-- determines if collision
	-- occurs and on what side
	-- side is number based on
	-- btn inputs
	-- side: 0 left
	--       1 right
	--       2 top
	--       3 bottom
	
	-- returns:
	--		hit: bool, true if collision detected
	--		side: side the hit occurs on
	--		position: position on outside edge of collision

	local w=a.w+b.w
	local h=a.h+b.h
	
	local dx=a.x-b.x
	local dy=a.y-b.y
	
	if abs(dx)<=w and abs(dy)<=h then
		local wy=w*dy
		local hx=h*dx*0.75
		
		local side
		local position
		if wy>hx then
			if wy>-hx then
				side=2
				position=a.y-a.h-b.h
			else
				side=1
				position=a.x+a.w+b.w
			end
		else
			if wy>-hx then
				side=0
				position=a.x-a.w-b.w
			else
				side=3
				position=a.y+a.h+b.h
			end
		end
		return true,side,position
	end
	return false
end


-->8
-- gamestates

gamestates={}
active_gamestate=nil

function add_gamestate(name,init,update,draw)
	gamestates[name]={
		init=init,
		update=update,
		draw=draw
	}
end

function gamestate_update(dt)
	if active_gamestate and
		active_gamestate.update
	then
		active_gamestate.update(dt)
	end
end

function gamestate_draw()
	if active_gamestate and
		active_gamestate.draw
	then
		active_gamestate.draw()
	end
end

function set_gamestate(name)
	local gs=gamestates[name]
	if gs then
		active_gamestate=gs
		active_gamestate.init()
	end
end
-->8
-- logging

_logs={}
_log_max=21

function log(m,c)
	m=tostr(m)
	c=c or 7
	add(_logs,{m=m,c=c})
	if #_logs>_log_max then
		for i=1,_log_max do
			_logs[i]=_logs[i+1]
		end
		_logs[_log_max+1]=nil
	end
end

function draw_log()
	local n=#_logs
	for i=1,n do
		local l=_logs[i]
		print(l.m,127-#l.m*4,(i-1)*6,l.c)
	end
end

_watches={}
_watch_default_color=11

function watch(m,c)
	m=tostr(m)
	c=c or _watch_default_color
	add(_watches,{m=m,c=c})
end

function clear_watches()
	_watches={}
end

function draw_watches()
	local n=#_watches
	for i=1,n do
		local w=_watches[i]
		print(w.m,0,(i-1)*6,w.c)
	end
end


-->8
-- coroutines/sequences

function tick_sequences()
	if not sequences then
		sequences={}
	end
	
	for s in all(sequences) do
		if s and costatus(s)~="dead" then
			assert(coresume(s))
		else
			del(sequences,s)
		end
	end
end

function sequence(fn)
	if not sequences then
		sequences={}
	end
	
	return add(sequences,cocreate(fn))
end

function wait_sec(sec)
	sec=sec or 0
	local start=t()
	while t()<start+sec do
		yield()
	end
end
-->8
-- random

function chance(perc)
	return rnd()<perc
end

-- weighted table random
function rnd_wt(wt)
	local sum=0
	for w in all(wt) do
		assert(w>=0)
		sum+=w
	end
	
	if sum<=0 then
		return 0
	end
	
	local val=flr(rnd(sum)+1)
	
	local idx=0
	while val>0 do
		idx+=1
		val-=wt[idx]
	end
	
	return idx
end

hex_table={
	"0","1","2","3",
	"4","5","6","7",
	"8","9","a","b",
	"c","d","e","f"
}

function tohex(num)
	local str="0x"
	for i=1,8 do
		local v=(i-4)*4
		local shf=shl
		if v<0 then
			shf=shr
			v=abs(v)
		end
		local h=band(shf(num,v),0xf)
		local hs=hex_table[h+1]
		str=str..hs
		if (i==4) str=str.."."
	end
	
	return str
end

function shuffle(a)
	local n=#a
	for i=n,2,-1 do
		local j=flr(rnd(i))+1
		a[i],a[j]=a[j],a[i]
	end
	return a
end

function rnd_elem(a)
	local n=#a
	return a[flr(rnd(n))+1]
end

-- xorshift16 sort of
function rgen(seed,ct)
	seed=seed or 1
	ct=ct or 0
	local ret={
		seed=seed,
		sx=seed,
		count=0,
		_next=function(self)
			self.count+=1
			self.sx=bxor(self.sx,shl(self.sx,7))
			self.sx=bxor(self.sx,shr(self.sx,9))
			self.sx=bxor(self.sx,shl(self.sx,8))
			return self.sx
		end,
		next=function(self,mn,mx)
			if not mn then
			 mn,mx=0,1
			elseif not mx then
				mx,mn=mn,0
			elseif mx<mn then
				mn,mx=mx,mn
			end
			
			local f=(self:_next()/32767+1)/2
			return f*(mx-mn)+mn
		end,
		reset=function(self,ct)
			self.state=self.seed
			self.count=0
			for i=1,ct do
				self:next()
			end
		end,
		clone=function(self)
			return rgen(self.seed,self.count)
		end
	}
	for i=1,ct do ret:next() end
	return ret
end
-->8
-- class

function class(clob)
	clob=clob or {}
	setmetatable(clob,
		{__index=clob.extends})
	clob.new=function(self,ob)
		ob=set(ob,{class=clob})
		setmetatable(ob,{__index=clob})
		if (clob.create) clob:create()
		return ob
	end
	return clob
end

-->8
-- general utility

function input_xy(pid)
	pid=pid or 0

	local ix,iy=0,0
	
	if (btn(0,pid)) ix-=1
	if (btn(1,pid)) ix+=1
	if (btn(2,pid)) iy-=1
	if (btn(3,pid)) iy+=1
	
	return ix,iy
end

function input_btns(pid)
	pid=pid or 0
	local bt=0
	if (btnp(4,pid)) bt+=1
	if (btnp(5,pid)) bt+=2
	if (btn(4,pid)) bt+=4
	if (btn(5,pid)) bt+=8
	return bt
end

function blink(ivl,tt)
	tt=tt or t()
	return flr((tt*2)/ivl)%2==0
end

function set(a,b)
	a=a or {}
	b=b or {}
	for k,v in pairs(b) do
		a[k]=v
	end
	return a
end

function clone(a,b)
	local ret=set({},a)
	return set(ret,b)
end

function viewport(extx,exty)
	extx=flr((extx or 0)/2)
	exty=flr((exty or 0)/2)
	return cam.x-extx,cam.y-exty,
		cam.x+extx+128,cam.y+exty+128
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
