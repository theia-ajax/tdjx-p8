pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
_logs={}

function log(m,c)
	m=tostr(m)
	c=c or 7
	add(_logs,{m=m,c=c})
	if #_logs>21 then
		for i=1,21 do
			_logs[i]=_logs[i+1]
		end
		_logs[22]=nil
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

function input_xy(player)
	player=player or 0

	local ix,iy=0,0
	
	if (btn(0,player)) ix-=1
	if (btn(1,player)) ix+=1
	if (btn(2,player)) iy-=1
	if (btn(3,player)) iy+=1
	
	return ix,iy
end

function moveto(f,t,s)
	s=max(s,0)
	if f<t then
		return min(f+s,t)
	else
		return max(f-s,t)
	end
end

function lerp(a,b,t)
	return (b-a)*t+a
end

_sgn=sgn
function sgn(v)
	if v==0 then return 0
	else return _sgn(v) end
end

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

-- wip
function sspr_slice(sx,sy,sw,sh,
	dx,dy,dw,dh,
	left,right,top,bot)
	
	sspr(sx,sy,sw,top,
		dx,dy,dw,top)
		
	sspr(sx,sy+sh-bot,sw,bot,
		dx,dy-dh-bot,dw,bot)
		
	sspr(sx,sy,left,sh,
		dx,dy,left,dh)
		
	sspr(sx+sw-right,sy,right,sh,
		dx+dh-right,dy,right,dh)
		
	local h=left+right
	local v=top+bot
		
	sspr(sx+left,sy+top,sw-h,sh-v,
		dx+left,dy+top,dw-h,dh-v)
	
end

function blink(ivl,tt)
	tt=tt or t()
	return flr((tt*2)/ivl)%2==0
end

function chance(perc)
	return rnd()<perc
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
