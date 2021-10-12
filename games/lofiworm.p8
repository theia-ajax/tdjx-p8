pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function is_dev() return peek(0x5f2d)>0 end

function _init()
	poke(0x5f2d,0)
	if (is_dev()) log("debug on",8)

	_fade_f=1
	

	k_high_scores=5
	
	cartdata("tdjx_worm_01")

	if scores_need_reset() then
		reset_scores(default_score)
	end
	
	
	menuitem(1,"return to title",
		function() 
			sequence(seq_return_to_title)
		end)
		
	game={
		score=0,
		scores=load_scores(),
		high_score=0,
		state_name=nil,
		state=nil,
		pause=false,
	}
	
	game_states={
		menu={
			start=menu_start,
			update=menu_update,
			draw=menu_draw
		},
		play={
			start=play_start,
			update=play_update,
			draw=play_draw
		},
		name={
			start=name_start,
			update=name_update,
			draw=name_draw
		}
	}

	sequences={}
	
	--[[fade_in(function()
		sequence(function()
			wait_sec(0.5)
		end,fade_out)
	end)]]

	shuffle(_fade_idx)
	fade_out()
	set_game_state("menu")
end

function sequence(fn,on_finish)
	add(sequences,{
		cr=cocreate(fn),
		on_finish=on_finish
	})
end

function set_game_state(state)
	game.state_name=state
	game.state=game_states[state]
		
	game.state.start()
end
	

function play_start()
	game.score=0

	snek={
		x=63,y=63,
		r=0,
		speed=36,
		turn=1.2,
		rad=1,
		invul_f=10,
		last_x=63,
		last_y=63,
		col_idx=5,
		chunk_dist=2,
		app_chunk=6,
		tail={}
	}
	
	snek_add_chunk(snek,snek.app_chunk)
	
	apples={}
	apple_ct=1
	for i=1,apple_ct do
		add_apple()
	end

end

function keypress(key)
	if key=="s" then
		snek_add_chunk(snek,snek.app_chunk)
	elseif key=="a" then
		game.score+=10
	elseif key=="d" then
		snek.dead=true
	elseif key=="-" then
		reset_scores(function() return 0 end)
		game.scores=load_scores()
		save_scores(game.scores)
	end
end

function _update60()
	dt=1/60
	
	if is_dev() then
		while stat(30) do
			keypress(stat(31))
		end
	end

	for s in all(sequences) do
		if s.cr and costatus(s.cr)~="dead" then
			assert(coresume(s.cr))
		else
			if s.on_finish then
				s.on_finish()
			end
			del(sequences,s)
		end
	end

	local modal=modal_update(dt)

	if not modal
		and game.state
		and not game.pause
	then
		game.state.update(dt)
	end
end

function _draw()
	if game.state then
		game.state.draw()
	end
	
	modal_draw()
	
	draw_fade()
	draw_message()
	
	if is_dev() then
		draw_log()
	end
end

function rnd_apple_pos()
	local valid=function(x,y)
		return not fget(mget(x,y),0)
	end
	
	local tx,ty=0,0
	repeat
		tx,ty=flr(rnd(14))+1,flr(rnd(13))+2
	until valid(tx,ty)

	return tx*8+4,ty*8+4
end

function add_apple()
	local x,y=rnd_apple_pos()
	add(apples,{id=#apples,x=x,y=y,rad=2})
end

function snek_add_chunk(s,ct)
	local n=#s.tail
	local t=s.tail[n]
	
	local tx,ty=s.x,s.y
	if t then
		tx,ty=t.x,t.y
	end
	
	ct=ct or 1
	
	for i=1,ct do
		add(s.tail,{x=tx,y=ty,rad=1})
	end
end

function menu_start()
	menu_exit=false
	menuitem(2,"reset highscores",function()
		show_modal("reset scores?",function(opt)
			if opt=="yes" then
				reset_scores(default_score)
				game.scores=load_scores()
			end
		end)
	end)
end

function menu_update(dt)
	if btnp(4) or btnp(5) then
		sequence(seq_game_start)
		menuitem(2)
--[[		game.pause=true
		fade_in(function()
			sequence(function()
				set_game_state("play")
				wait_sec(1)
				fade_out(function()
					sequence(function() wait_sec(1); game.pause=false end)
				end)
			end)
		end)]]
	end
end

function menu_draw()
	cls(6)
	
	print("high scores",64-22,14,0)
	
	for i=1,k_high_scores do
		local rec=game.scores[i]
		local name,score=
			rec.name,rec.score
			
		print(tostr(i)..") "..name,64-16-12,(i-1)*8+24,0)
		
		local sstr=tostr(score)
		print(sstr,64+24-#sstr*4,(i-1)*8+24,0)
	end
	
	draw_header()
	
	local m1="turn with ⬅️/➡️"
	local m2="eat apples to grow"
	local m3="avoid yourself and walls"
	print(m1,64-#m1*2-3,76,0)
	print(m2,64-#m2*2,84,0)
	print(m3,64-#m3*2,92,0)
	
	local br=1/2
	if (menu_exit) br=1/16
	if blink(br) then
 	local m="press 🅾️ or ❎\n   to start"
 	print(m,36,112,0)
	end
end

function draw_header()
	rectfill(0,0,127,7,5)
	
	local m="pico worm"
	print(m,64-#m*2,1,7)
end

function play_update(dt)
	if (snek.invul_f>0) snek.invul_f-=1

	if not snek.dead then
		if dist(snek.x,snek.y,snek.last_x,snek.last_y)>=snek.chunk_dist then
 		snek.last_x=snek.x
 		snek.last_y=snek.y
  	local n=#snek.tail
  	if n>0 then
   	for i=n,2,-1 do
   		snek.tail[i].x=
   			snek.tail[i-1].x
   		snek.tail[i].y=
   			snek.tail[i-1].y
   	end
   	snek.tail[1].x=snek.x
   	snek.tail[1].y=snek.y
   end
 	end
	
		local ix,iy=0,0
	
 	if (btn(0)) ix-=1
 	if (btn(1)) ix+=1
 	if (btn(2)) iy-=1
 	if (btn(3)) iy+=1
 	
 	snek.r+=snek.turn*dt*-ix
 	
 	local vx,vy=cos(snek.r)*snek.speed,
 		sin(snek.r)*snek.speed
		
 	snek.x+=vx*dt
 	snek.y+=vy*dt
 	
 	for a in all(apples) do
 		if circhit(snek,a) then
 			snek_add_chunk(snek,snek.app_chunk)
 			a.x,a.y=rnd_apple_pos()
 			game.score+=1
 		end
 	end
	
 	if snek.invul_f<=0 then
 		local n=#snek.tail
 		local ox,oy=snek.x,snek.y
 		local dx,dy=cos(snek.r),sin(snek.r)
 		for i=snek.col_idx,n-1 do
 			local ax,ay,bx,by=
 				snek.tail[i].x,
 				snek.tail[i].y,
 				snek.tail[i+1].x,
 				snek.tail[i+1].y
 			local hit,dst,dbg=ray_line_check(
 				ox,oy,dx,dy,ax,ay,bx,by)
 			
 			if hit and dst<=snek.speed*dt then
 				snek.dead=true
 			end
 		end
 	end
	
		if level_solid(snek.x,snek.y)
 	or snek.x>127 or snek.x<0
 	or snek.y>127 or snek.y<0
 	then
 		snek.dead=true
 	end
	else
		if (btnp(4)) then
			if has_high_score() then
				set_game_state("name")
			else
				set_game_state("play")
			end
		end
	end
end

function play_draw()
	cls(6)

	--map(0,0,0,0,16,16)	
	
	for a in all(apples) do
		circfill(a.x,a.y,a.rad,0)
	end
	
	-- draw
	local n=#snek.tail
	for i=n,2,-1 do
		local sc=3
		if (i%2==0) sc=11
		line(snek.tail[i].x,
			snek.tail[i].y,
			snek.tail[i-1].x,
			snek.tail[i-1].y,
			0)
	end
	line(snek.tail[1].x,
		snek.tail[1].y,
		snek.x,
		snek.y,
		0)
		
	draw_header()
		
	print("score:"..game.score,1,1,7)
	
	local high=next_high()
	local highmsg="high:"..high
	print(highmsg,126-#highmsg*4,1,7)

	if snek.dead then
		print("dead",56,54,8)
		if has_high_score() then
			local m="new high score!"
			print(m,64-#m*2,62,8)
		end
	end
end

function dist(x1,y1,x2,y2)
	local dx,dy=x2-x1,y2-y1
	return sqrt(dx*dx+dy*dy)
end

function circhit(c1,c2,radj)
	return dist(c1.x,c1.y,c2.x,c2.y)<=c1.rad+c2.rad+(radj or 0)
end

function level_solid(x,y)
	return fget(mget(x/8,y/8),0)
end
-->8
function reset_scores(scorefn)
	local scores={}
	scorefn=scorefn or function(i) return 0 end
	for i=1,k_high_scores do
		scores[i]={name="aaa",score=scorefn(k_high_scores-i+1)}
	end
	save_scores(scores)
end

function load_scores()
	local ret={}

	for i=1,k_high_scores do
		local addr=(i-1)*8+0x5e00
		
		local c1,c2,c3=
			byte_to_char(peek(addr)),
			byte_to_char(peek(addr+1)),
			byte_to_char(peek(addr+2))
			
		local name=c1..c2..c3
			
		local score=peek4(addr+4)
		
		add(ret,{name=name,score=score})
	end

	return ret
end

function save_scores(scores)
	for i=1,k_high_scores do
		local addr=(i-1)*8+0x5e00
		
		local name,score=
			scores[i].name,scores[i].score
			
		poke(addr,char_to_byte(sub(name,1,1)))
		poke(addr+1,char_to_byte(sub(name,2,2)))
		poke(addr+2,char_to_byte(sub(name,3,3)))
		
		poke4(addr+4,score)
	end
end

function insert_score(scores,score)
	local n=#scores
	local idx=#scores+1
	for i=n,1,-1 do
		if scores[i].score>=score.score then
			break
		else
			idx=i
		end
	end
	
	for i=n,idx+1,-1 do
		scores[i]=scores[i-1]
	end
	scores[idx]=score
end

char_values={
	a=1,b=2,c=3,d=4,
	e=5,f=6,g=7,h=8,
	i=9,j=10,k=11,l=12,
	m=13,n=14,o=15,p=16,
	q=17,r=18,s=19,t=20,
	u=21,v=22,w=23,x=24,
	y=25,z=26,
}

byte_values={}
for k,v in pairs(char_values) do
	byte_values[v]=k
end

function char_to_byte(str)
	assert(#str==1)
	
	return char_values[str]
end

function byte_to_char(byte)
	if byte==0 then
		return " "
	else
		return byte_values[byte]
	end
end

function scores_need_reset()
	local k_score_size=8
	for i=0x5e00,0x5e00+k_high_scores*k_score_size do
		if peek(i)~=0 then
			return false
		end
	end
	return true
end

function has_high_score()
	return game.score>game.scores[#game.scores].score
end

function next_high()
	for i=#game.scores,1,-1 do
		if game.scores[i].score>=game.score then
			return game.scores[i].score
		end
	end
	return game.score
end

function default_score(i) return i*2 end
-->8
function blink(ivl,tt)
	tt=tt or t()
	return tt%(ivl*2)<ivl
end

function shuffle(a)
	local n=#a
	for i=n,2,-1 do
		local j=flr(rnd(i))+1
		a[i],a[j]=a[j],a[i]
	end
end

_fade_idx={1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16}
_fade_f=0
_fade_time=1

function fade_in(on_finish)
	shuffle(_fade_idx)
	sequence(seq_fade_in,on_finish)
end

function fade_out(on_finish)
	sequence(seq_fade_out,on_finish)
end

function seq_game_start_fast()
	set_game_state("play")
end

_rnd_messages={
	"you're a good worm",
	"the earliest bird\n can't get you",
	"just try your best\nyou're just a worm",
	"steady thyself\n young worm",
	"1) acquire apples\n2) ??????\n3) profit",
}

function seq_game_start()
	-- fade in
	-- wait
	-- start message enters
	-- start message waits
	-- start message leaves
	-- fade out
	-- pause briefly
	-- game starts
	
	game.pause=true
	menu_exit=true
	
	sfx(0)
	
	wait_sec(1/2)
		
	shuffle(_fade_idx)
	seq_fade_in()
	
	set_game_state("play")
	wait_sec(1/2)
	
	local i=flr(rnd(#_rnd_messages))+1
	_message=_rnd_messages[i]
	wait_sec(2)
	_message=nil
	
	wait_sec(0)
	
	seq_fade_out()
	wait_sec(1/2)
	
	music(0)
	game.pause=false
end

function seq_return_to_title()
	music(-1,300)
	game.pause=true
		
	shuffle(_fade_idx)
	seq_fade_in()
	
	set_game_state("menu")
	wait_sec(1/2)
	
	seq_fade_out()
	
	game.pause=false
end

function seq_fade_in()
	while _fade_f<1 do
		_fade_f+=(1/_fade_time)*dt
		_fade_f=mid(_fade_f,0,1)
		yield()
	end
	_fade_f=1
end

function seq_fade_out()
	while _fade_f>0 do
		_fade_f-=(1/_fade_time)*dt
		_fade_f=mid(_fade_f,0,1)
		yield()
	end
	_fade_f=0
end

function draw_fade()
	if _fade_f>0 then
		local idx=flr(_fade_f*15)+1
		local ptn=0
		for i=1,idx do
			ptn=bor(ptn,shl(1,_fade_idx[i]-1))
		end
		
		ptn=band(bnot(ptn),0xffff)
		ptn+=0b0.1

		fillp(ptn)
		rectfill(0,0,127,127,0x10)
		fillp()
	end
	
end

_message=nil
function draw_message()
	if _message then
		local w=str_width(_message)
		print(_message,64-w/2,60,7)
	end
end

function wait_sec(sec)
	sec=sec or 0
	while sec>0 do
		sec-=dt
		yield()
	end
end

function wait_for(pred,to)
	to=to or -1
	while not pred() do
		if t0>0 then
			t0-=dt
			if (t0<=0) break
		end
		yield()
	end
end

logs={}
function log(m,c)
	add(logs,{m=tostr(m),c=c or 7})
	if #logs>20 then
		for i=1,20 do
			logs[i]=logs[i+1]
		end
		logs[21]=nil
	end
end

function draw_log()
	for i=1,#logs do
		local m,c=logs[i].m,logs[i].c
		print(m,127-#m*4,(i-1)*6,c)
	end
end
-->8
function
ray_line_check
(ox,oy,dx,dy,ax,ay,bx,by)

 local tox,toy=ox-ax,oy-ay
 local dlx,dly=bx-ax,by-ay
 local px,py=-dy,dx
 
 local dot=dlx*px+dly*py
 
 if dot==0 then
 	return false,-1
 end
 
 --x1*y2-y1*x2
 local det=dlx*toy-dly*tox
 
 local hit=-1
 if abs(dot)>0.01 then
	 hit=det/dot
	else
		hit=32767
	end

	local pos=(tox*px+toy*py)/dot
	
	return (hit>=0 and
		pos>=0 and pos<=1),hit,{
			tox=tox,toy=toy,
			dlx=dlx,dly=dly,
			px=px,py=py,
			dot=dot,hit=hit,pos=pos
		}
end
-->8
function name_start()
	cur=1
	chars={0,0,0}
	name_exit=false
end

function name_update(dt)
	if name_exit then
		return
	end

	if (btnp(0) or btnp(5)) cur-=1
	if (btnp(1)) cur+=1
	
	local lock=false
	if (cur<4 and btnp(4)) cur+=1; lock=true
	
	cur=mid(cur,1,4)

	if cur<=3 then
 	if (btnp(2)) chars[cur]-=1
 	if (btnp(3)) chars[cur]+=1
 
 	if (chars[cur]<0) chars[cur]=26
 	if (chars[cur]>26) chars[cur]=0
 else
 	if not lock and btnp(4) then
 		-- insert score
 		local str=""
 		for i=1,3 do
 			if chars[i]<=0 then
 				str=str.." "
 			else
 				str=str..byte_values[chars[i]]
 			end
 		end
 		insert_score(game.scores,{name=str,score=game.score})
 		save_scores(game.scores)
 		sfx(1)
 		sequence(seq_name_exit)
 	end
 end
end

function seq_name_exit()
	name_exit=true
	wait_sec(1/2)
	seq_return_to_title()
end

function name_draw()
	cls(6)
	
	draw_header()
	
	local spacing=8
	
	if cur<=3 then
 	
 	local x=64+(cur-2)*spacing-1
 	rectfill(x,59,x+4,65,12)
 	up_arrow(x,54)
 	down_arrow(x,68)
	end
	
	for i=1,3 do
		local x=64+(i-2)*spacing
		line(x,66,x+2,66,0)
		if chars[i]>0 then
			local c=byte_values[chars[i]]
			print(c,x,60,0)
		end
	end
	
	if cur==4 then
		pal(7,12)
	end
	if not name_exit or blink(1/16) then
		spr(3,80,60)
	end
	pal()
end

function up_arrow(x,y)
	sspr(16,0,5,3,x,y,5,3)
end

function down_arrow(x,y)
	sspr(16,5,5,3,x,y,5,3)
end
-->8
_modal={
	on=off,
	x=64,y=64,
	w=80,h=40,
	message="",
	select=1,
	options={"yes","no"}
}

function show_modal(message,on_select,options,current)
	_modal.on=true
	_modal.on_select=on_select
	_modal.message=message
	_modal.options=options or {"no","yes"}
	_modal.select=current or 1
end

function modal_update()
	if not _modal.on then
		return false
	end
	
	if (btnp(0)) _modal.select-=1
	if (btnp(1)) _modal.select+=1
	
	if (_modal.select<1) _modal.select=#_modal.options
	if (_modal.select>#_modal.options) _modal.select=1
	
	if btnp(4) then
		_modal.on=false
		_modal.on_select(_modal.options[_modal.select])
	end
	
	return true
end

function modal_draw()
	if not _modal.on then
		return
	end
	
	local x,y,w,h=_modal.x,
		_modal.y,_modal.w,_modal.h
	
	rectfill(x-w/2,y-h/2,x+w/2,y+h/2,6)
	rect(x-w/2,y-h/2,x+w/2,y+h/2,0)
	rect(x-w/2+2,y-h/2+2,x+w/2-2,y+h/2-2,0)
	
	print(_modal.message,
		x-#_modal.message*2,
		y-6,
		0)

	local sx=x+(_modal.select-2)*20
	rectfill(sx-1,y+8,sx+#_modal.options[_modal.select]*4-1,y+14,12)
		
	for i=1,#_modal.options do
		local px=x+(i-2)*20
		local py=y+9
		rect(px-2,py-2,px+#_modal.options[i]*4,py+6,0)
		print(_modal.options[i],px,py,0)
	end
end
-->8
function str_width(str)
	local n=#str
	local m=0
	local l=0
	for i=1,n do
		if sub(str,i,i)=="\n" then
			if (l>m) m=l
			l=0
		else
			l+=1
		end
	end
	return max(m,l)*4
end

function str_height(str)
	local n=#str
	local row=1
	for i=1,n do
		if sub(str,i,i)=="\n" then
			row+=1
		end
	end
	return row*5+(row-1)*1
end
__gfx__
00000000888888880070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000888888880777000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700888888887777700000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000888888880000000007777070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000888888880000000007077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700888888887777700007777070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000888888880777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000888888880070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
01080000351602e160241601d160351602e160241601d160351402e140241401d140351402e140241401d140351202e120241201d120351202e120241201d120351102e110241101d110351102e110241101d110
010400001f050220502b050330501f040220402b040330401f030220302b030330301f020220202b0203302000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01080000106730000000000000001c173003001067300000106730000000000000001c173003001067300000106730000000000000001c173003001067300000106730000000000000001c173003001067300000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011100000c3430035500345003353c6150a3300a4320a3320c3430335503345033353c6151333013432133320c3430735507345073353c6151633016432163320c3430335503345033353c6151b3301b4321b332
01110000162251b425222253751227425375122b5112e2251b4352b2402944027240224471f440244422443224422244253a512222253a523274252e2253a425162351b4352e4302e23222431222302243222232
011100000c3430535505345053353c6150f3301f4260f3320c3430335503345033353c6151332616325133320c3430735507345073353c6151633026426163320c3430335503345033353c6150f3261b3150f322
011100001d22522425272253f51227425375122b5112e225322403323133222304403043030422375112e44237442372322c2412c2322c2222c4202c4153a425162351b4352b4402b4322b220224402243222222
011100001f2401f4301f2201f21527425375122b5112e225162251b5112e2253a5122b425375122b5112e225162251b425225133021033410375223341027221162251b425222253751227425373112b3112e325
01110000182251f511242233c5122b425335122b5112e225162251b5112e2253a5122b425375122b5112e225162251b425225133021033410375223341027221162251b425222253751227425373112b3112e325
011100000f22522425272253f51227425375122b5112e2252724027232272222444024430244222b511224422b4422b23220241202322023220420204153a425162351b4351f4401f4321f2201d4401d4321d222
__music__
00 23424344
00 23424344
01 23244344
00 23244344
00 25294344
00 25264344
00 23274344
02 23284344

