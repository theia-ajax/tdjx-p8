pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	cartdata("tdjx_worm_01")
		
	game={
		score=0,
		scores=load_scores(),
		high_score=0,
		state_name=nil,
		state=nil
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
		}
	}

	set_game_state("menu")
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
		col_idx=9,
		tail={}
	}
	
	snek_add_chunk(snek,6)
	
	apples={}
	apple_ct=1
	for i=1,apple_ct do
		add_apple()
	end
end

function _update()
	if game.state then
		game.state.update(1/30)
	end
end

function _draw()
	if game.state then
		game.state.draw()
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
end

function menu_update(dt)
	if btnp(4) then
		set_game_state("play")
	end
end

function menu_draw()
	cls(6)
	
	print("high scores",64-22,14,0)
	
	for i=1,10 do
		local rec=game.scores[i]
		local name,score=
			rec.name,rec.score
			
		print(name,64-24,(i-1)*8+24,0)
		
		local sstr=tostr(score)
		print(sstr,64+24-#sstr*4,(i-1)*8+24,0)
	end
	
	rectfill(0,0,127,7,5)
	local m="press 🅾️ or ❎"
	--print(m,64-#m*2-2,62,0)
	
	local m="pico worm"
	print(m,64-#m*2,1,7)
end

function play_update(dt)
	if (snek.invul_f>0) snek.invul_f-=1
	
	if dist(snek.x,snek.y,snek.last_x,snek.last_y)>=3 then
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
		
	if snek.dead then
		vx,vy=0,0
		
		if (btnp(4)) then
			set_game_state("play")
		end
	end
		
	snek.x+=vx*dt
	snek.y+=vy*dt
	
	for a in all(apples) do
		if circhit(snek,a) then
			snek_add_chunk(snek,3)
			a.x,a.y=rnd_apple_pos()
			game.score+=1
		end
	end
	
	if snek.invul_f<=0 then
		for i=snek.col_idx,#snek.tail do
			if circhit(snek,snek.tail[i]) then
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
end

function play_draw()
	cls(6)

	if false then	
	for x=0,127,8 do
		line(x,0,x,127,5)
	end
	for y=0,127,8 do
		line(0,y,127,y,5)
	end
	
	line(0,63,127,63,6)
	line(63,0,63,127,6)
	end
	
	map(0,0,0,0,16,16)
	
	for a in all(apples) do
		circfill(a.x,a.y,a.rad,0)
	end
	
	local n=#snek.tail
	for i=n,2,-1 do
		local sc=3
		if (i%2==0) sc=11
		line(snek.tail[i].x,
			snek.tail[i].y,
			snek.tail[i-1].x,
			snek.tail[i-1].y,
			0)
		local c=10
		if (i<snek.col_idx) c=9
--[[		pset(snek.tail[i].x,
			snek.tail[i].y,
			c)]]
--[[		circfill(snek.tail[i].x,
			snek.tail[i].y,
			snek.tail[i].rad,
			11)]]
	end
	line(snek.tail[1].x,
		snek.tail[1].y,
		snek.x,
		snek.y,
		0)
--[[	pset(snek.tail[1].x,
		snek.tail[1].y,
		9)]]
		
--[[	circfill(sx+cos(snek.r)*2,
		sy+sin(snek.r)*2,
		1,
		10)]]
		
	print(game.score,0,1,7)
	--print(tostr(band(stat(1)*100).."%",0xffff),0,0,7)
	
	if snek.dead then
		print("dead",56,62,8)
	end
end

function dist(x1,y1,x2,y2)
	local dx,dy=x2-x1,y2-y1
	return sqrt(dx*dx+dy*dy)
end

function circhit(c1,c2)
	return dist(c1.x,c1.y,c2.x,c2.y)<=c1.rad+c2.rad
end

function level_solid(x,y)
	return fget(mget(x/8,y/8),0)
end
-->8
function reset_scores()
	local scores={}
	for i=1,10 do
		scores[i]={name="aaa",score=0}
	end
	save_scores(scores)
end

function load_scores()
	local ret={}

	for i=1,10 do
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
	for i=1,10 do
		local addr=(i-1)*8+0x5e00
		
		local name,score=
			scores[i].name,scores[i].score
			
		poke(addr,char_to_byte(sub(name,1,1)))
		poke(addr+1,char_to_byte(sub(name,2,2)))
		poke(addr+2,char_to_byte(sub(name,3,3)))
		
		poke4(addr+4,score)
	end
end

char_values={
	a=0,b=1,c=2,d=3,
	e=4,f=5,g=6,h=7,
	i=8,j=9,k=10,l=11,
	m=12,n=13,o=14,p=15,
	q=16,r=17,s=18,t=19,
	u=20,v=21,w=22,x=23,
	y=24,z=25,
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
	return byte_values[byte]
end
__gfx__
00000000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
