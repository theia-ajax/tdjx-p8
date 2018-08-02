pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	plr={}

 -- config
 plr.spd=2
 plr.fireitvl=12
 plr.dirvel={{x=1,y=0},
 	{x=-1,y=0},
 	{x=0,y=-1},
 	{x=0,y=1}
 }
 plr.dirbltspwn={
 	{{x=0,y=2},{x=0,y=-4}},
 	{{x=-2,y=2},{x=-2,y=-4}},
 	{{x=2,y=-2},{x=-4,y=-2}},
 	{{x=2,y=0},{x=-4,y=0}}
 }

	-- runtime
	plr.x=12
	plr.y=64
	plr.dx=0
	plr.dy=0
	--cardinal direction
	--matches btn api numbers
	plr.cdir=0
 plr.firef=0
 
 boss={}
 boss.x=111
 boss.y=64
 
 bullets={}
 bullets.aq={}
 bullets.rq={}
 
 eshots={}
 eshots.aq={}
 eshots.rq={}
 
 bricks={}
 for x=0,7 do
 	for y=0,15 do
 		add(bricks,{
 			x=68+x*4,
 			y=y*8,
 			c=8+flr(rnd(7)),
 			w=4,
 			h=8,
 			dead=false
 		})
 	end
 end
end

function _update()
	mvx,mvy=0,0
	if (btn(0)) mvx-=1
	if (btn(1)) mvx+=1
	if (btn(2)) mvy-=1
	if (btn(3)) mvy+=1
	
	plr.dx,plr.dy=0,0
	local domove=false
	
	if mvx>0 then
		plr.cdir=0
		domove=true
	elseif mvx<0 then
		plr.cdir=1
		domove=true
	elseif mvy<0 then
		plr.cdir=2
		domove=true
	elseif mvy>0 then
		plr.cdir=3
		domove=true
	end

	local idx=plr.cdir+1
	local vel=plr.dirvel[idx]
	local offs=plr.dirbltspwn[idx]
	
	if domove then
 	plr.dx=vel.x*plr.spd
 	plr.dy=vel.y*plr.spd
 end

	plr.x+=plr.dx
	plr.y+=plr.dy
	
	if (plr.x<6) plr.x=6
	if (plr.x>60) plr.x=60
	if (plr.y<6) plr.y=6
	if (plr.y>121) plr.y=121
	
	if btn(4) then
		plr.firef-=1
		if plr.firef<=0 then
			plr.firef=plr.fireitvl
			local fx,fy=0,0
			for off in all(offs) do
 			add(bullets.aq,{
 				x=plr.x+off.x,
 				y=plr.y+off.y,
 				cdir=plr.cdir,
 			})
			end
		end
	else
		plr.firef=0
	end
	
	for i=1,#bullets do
		local blt=bullets[i]
		local bltspd=8
		
		if blt.cdir==0 then
			blt.x+=bltspd
		elseif blt.cdir==1 then
			blt.x-=bltspd
		elseif blt.cdir==2 then
			blt.y-=bltspd
		elseif blt.cdir==3 then
			blt.y+=bltspd
		end
		
		if blt.x<-5 or blt.x>132 or
			blt.y<-5 or blt.y>132
		then
			blt.dead=true
		end
		
		if blt.x>75 then
			for brk in all(bricks) do
				if not brk.dead and
					rect_overlap(
						blt.x,blt.y,2,1,
						brk.x,brk.y,brk.w,brk.h)
				then
					brk.dead=true
					blt.dead=true
					add(eshots.aq,{
						x=brk.x+1,y=brk.y+4
					})
					break
				end		
			end
		end

		if blt.dead then
			add(bullets.rq,i)
		end
	end
	
	idelfa(bullets,bullets.rq)
	clra(bullets.rq)
	
	for blt in all(bullets.aq) do
		add(bullets,blt)
	end
	clra(bullets.aq)
	
	boss.y=64+sin(t()/6)*48
	
	for i=1,#eshots do
		local sht=eshots[i]
		sht.x-=3
		if (sht.x<-5) sht.dead=true
	end
	
	idelfa(eshots,eshots.rq)
	clra(eshots.rq)
	
	for sht in all(eshots.aq) do
		add(eshots, sht)
	end
	clra(eshots.aq)
	
	for i=1,#bricks do
		local brk=bricks[i]
		if rnd(100)<2 then
			brk.c=8+flr(rnd(7))
		end
	end
end

function _draw()
	cls()
	spr(1+plr.cdir,plr.x-4,plr.y-4)
	spr(9,boss.x,boss.y-8,2,2)

	for blt in all(bullets) do
		rectfill(blt.x,blt.y,
			blt.x+1,blt.y+1,12)
	end
	
	for sht in all(eshots) do
		circfill(sht.x,sht.y,1,10)
	end
	
	for brk in all(bricks) do
		if not brk.dead then
 		rectfill(brk.x,brk.y,
 			brk.x+brk.w,brk.y+brk.h,
 			brk.c)
		end
	end
end

function
rect_overlap(x1,y1,w1,h1,
	x2,y2,w2,h2)
	
	return x1<=x2+w2 and
		x1+w1>=x2 and
		y1<=y2+h2 and
		y1+h1>=y2
end
	
-->8

-->8
-----------------------------------
-- table utilities --
-----------------------------------
-- clear array
function clra(arr)
	for i, _ in pairs(arr) do
		arr[i] = nil
	end
end

function cpya(arr, dst)
	if dst then
		clra(dst)
	else
		dst = {}
	end
	for i = 1, #arr do
		dst[i] = arr[i]
	end
	return dst
end

function idxof(arr, v)
	local n = #arr
	for i = 1, n do
		if arr[n] == v then
			return i
		end
	end
	return -1
end

function contains(arr, v)
	return idxof(arr, v) >= 0
end

-- fast add, no check
function fadd(t, v)
	t[#t+1] = v
end

-- fast del, swap in last element
-- instead of maintaining order
function delf(t, v)
	local n = #t
	for i = 1, n do
		if t[i] == v then
			t[i] = t[n]
			t[n] = nil
			return true
		end
	end
	return false
end

-- delete at index, maintain order
function idel(t, i)
	local n = #t
	if i > 0 and i <= n then
		for j = i, n - 1 do
			t[j] = t[j + 1]
		end
		t[n] = nil
		return true
	end
	return false
end

-- delete [s, e], maintain order
-- compress for space
function idelr(t, s, e)
	local n = #t
	e = min(n, e)
	local d = e - s + 1
	for i = s, e do
		t[i] = nil
	end
	for i = e + 1, n do
		t[i - d] = t[i]
		t[i] = nil
	end
end

-- delete at index, swap in last
-- element, loses ordering
function idelf(t, i)
	local n = #t
	if i > 0 and i <= n then
		t[i] = t[n]
		t[n] = nil
		return true
	end
	return false
end

-- fast deletion of an array of
-- indices
function idelfa(arr, idx)
	local l = #arr

	for i in all(idx) do
		arr[i] = nil
	end
	if (#idx == l) return
	for i = 1, l do
		if arr[i] == nil then
			while not arr[l]
				and l > i
			do
				l -= 1
			end
			if i ~= l then
				arr[i] = arr[l]
				arr[l] = nil
			else return end
		end
	end
end
-----------------------------------
__gfx__
000000009556c000000c655900666600990550990000000000000000000000000000000000000000000002220000000000000000000000000000000000000000
000000009666c000000c666900c66c00566666650000000000000000000000000000000000000022222222220000000000000000000000000000000000000000
00700700065000c66c00056000055000565665650000000000000000000000000000000000222222222222220000000000000000000000000000000000000000
000770005665656666565665cc0660cc660550660000000000000000000000000000000002222202222222220000000000000000000000000000000000000000
00077000566565666656566566055066cc0660cc0000000000000000000000000000000022002220222222220000000000000000000000000000000000000000
00700700065000c66c00056056566565000550000000000000000000000000000000000020000220222222220000000000000000000000000000000000000000
000000009666c000000c66695666666500c66c000000000000000000000000000000000020000220222222220000000000000000000000000000000000000000
000000009556c000000c655999055099006666000000000000000000000000000000000020000220222222220000000000000000000000000000000000000000
cc000000000000000000000000000000000000000000000000000000000000000000000020000220222222220000000000000000000000000000000000000000
cc000000000000000000000000000000000000000000000000000000000000000000000020000220222222220000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000020000220222222220000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000022002220222222220000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000002222202222222220000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000222222222222220000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000022222222220000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000002220000000000000000000000000000000000000000
