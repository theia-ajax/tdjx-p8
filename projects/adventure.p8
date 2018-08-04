pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	cam={x=0,y=0}

	player=make_player()
	
	daggers={}
	
	dudes={}
	for i=1,3 do
		add(dudes,{
			x=rnd(16),
			y=rnd(16),
			w=0.5,
			h=0.5,
			sp=flr(rnd(2))+16
		})
	end
end

function _update60()
	update_player(player)
	
	local rq={}
	for i,dg in pairs(daggers) do
		update_dagger(dg)
		if dg.destroy then
			add(rq,i)
		end
	end
	idelfa(daggers,rq)
end

function _draw()
	cls(15)
	
	camera(cam.x*8,cam.y*8)
	
	map(0,0,0,0,48,48)
	draw_player(player)
	foreach(daggers,draw_dagger)
	for d in all(dudes) do
		spr(d.sp,d.x*8,d.y*8)
	end
	
	camera()	
	print("pos:"..player.x..","..player.y,0,0,7)
end

function make_player()
	local pl={
		x=8,y=8,dx=0,dy=0,
		w=0.5,h=0.5,
		mdir=-1,
		fdir=0
	}
	
	return pl
end

function update_player(pl)
	local ix,iy=0,0
	if (btn(0)) ix-=1
	if (btn(1)) ix+=1
	if (btn(2)) iy-=1
	if (btn(3)) iy+=1

	-- todo: better
	if ix~=0 and iy~=0 then
		iy=0
	end
		
	local req=-1
	if (ix<0) req=0
	if (ix>0) req=1
	if (iy<0) req=2
	if (iy>0) req=3
	
	pl.mdir=req
	if pl.mdir>=0 then
		pl.fdir=pl.mdir
	end

	local mx,my=card_to_vel(pl.mdir)

	if mx~=0 then
		local tgy=round(pl.y)
		pl.y=moveto(pl.y,tgy,1/16)
	elseif my~=0 then
		local tgx=round(pl.x)
		pl.x=moveto(pl.x,tgx,1/16)
	end

	local spd=0.1
	pl.dx=mx*spd
	pl.dy=my*spd
	
	if area_solid(pl.x+pl.dx,pl.y+pl.dy,7/8,7/8) then
		pl.dx=0
		pl.dy=0
	end
	
	pl.x+=pl.dx
	pl.y+=pl.dy
	
	if (btnp(4)) then
		local sx,sy=card_to_vel(pl.fdir)
		local dgx,dgy=pl.x+sx*.25+3/8,
			pl.y+sy*.25+3/8
		make_dagger(dgx,dgy,pl.fdir)	
	end
end

function draw_player(pl)
	spr(8,
		pl.x*8,pl.y*8)
	pset(pl.x*8,pl.y*8,11)
end

-- spawn x,y
-- cdir: cardinal direction
--		0 right, 1 left, 2 up, 3 down
function make_dagger(x,y,cdir)
	local dg={}
	dg.x=x
	dg.y=y
	dg.cdir=cdir
	dg.dx,dg.dy=card_to_vel(dg.cdir)
	dg.spd=0.8
	dg.dx*=dg.spd
	dg.dy*=dg.spd
	
	dg.w=0.5
	dg.h=0.2
	if (cdir>1) dg.w,dg.h=dg.h,dg.w
	
	dg.life_frames=12
	dg.life_t=dg.life_frames
	
	return add(daggers,dg)
end

function update_dagger(dg)
	dg.spd=lerp(dg.spd,0,0.2)

	dg.dx,dg.dy=card_to_vel(dg.cdir)
	dg.dx*=dg.spd
	dg.dy*=dg.spd

	dg.x+=dg.dx
	dg.y+=dg.dy
	
	dg.life_t-=1
	if dg.life_t<=0 then
		dg.destroy=true
	end
end

function draw_dagger(dg)
	local x=(dg.x-dg.w)*8
	local y=(dg.y-dg.h)*8
	local flx,fly=false,false
	if (dg.cdir==1) flx=true
	if (dg.cdir==3) fly=true
	local sp=24
	if (dg.cdir>1) sp=25
	
	spr(sp,x,y,1,1,flx,fly)
end

function card_to_vel(cdir)
	if cdir==0 then return -1,0
	elseif cdir==1 then return 1,0
	elseif cdir==2 then return 0,-1
	elseif cdir==3 then return 0,1
	else return 0,0 end
end
-->8
-- utils

function lerp(a,b,t)
	return a+(b-a)*t
end

function mag(x,y)
	return sqrt(x*x+y*y)
end

function norm(x,y)
	local l=mag(x,y)
	if (l>0) return x/l,y/l
	return 0,0
end

function scale(x,y,scl)
	return x*scl,y*scl
end

function moveto(v,tg,r)
	if v<tg then
		return min(v+abs(r),tg)
	elseif v>tg then
		return max(v-abs(r),tg)
	else
		return v
	end
end

function round(v)
	if v-flr(v)<0.5 then
		return flr(v)
	else
		return ceil(v)
	end
end

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

-->8
-- physics

function area_solid(x,y,w,h)
	return solid(x,y) or
		solid(x+w,y) or
		solid(x,y+h) or
		solid(x+w,y+h)
end

function solid(x,y)
	return fget(mget(flr(x),flr(y)),0)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000ccccc0000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000ccc0000000000000000000000000000000000000000000000000000000000
0070070000000000000000000000000000000000000000000000000000000000000ddd0d00000000000000000000000000000000000000000000000000000000
0007700000000000000000000000000000000000000000000000000000000000000ddd0d00000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000dcdddcd00000000000000000000000000000000000000000000000000000000
0070070000000000000000000000000000000000000000000000000000000000ddccccc000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000d0ccccc000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000c000c000000000000000000000000000000000000000000000000000000000
808888089009900000000000000000009009900000000000000000000000000000000000000d0000000000000000000000000000000000000000000000000000
082222809099990000000000000000009099990000000000000000000000000000000000000d0000000000000000000000000000000000000000000000000000
8222222890099099000000000000000090099099000000000000000000000000000000c0000d0000000000000000000000000000000000000000000000000000
8282282898888899000000000000000098888899000000000000000000000000ddddddcc000d0000000000000000000000000000000000000000000000000000
8222222890088099000000000000000090088099000000000000000000000000000000c0000d0000000000000000000000000000000000000000000000000000
082882809008800000000000000000009008800000000000000000000000000000000000000d0000000000000000000000000000000000000000000000000000
08822880908888000000000000000000908888000000000000000000000000000000000000ccc000000000000000000000000000000000000000000000000000
800880089080080000000000000000009080080000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000bbbbbb000000000000bb000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000bbbbbbbbbb0000000000bb000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000bbbbbbbbbbbb00000003bbbb30000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000bbbbbbbbbbbbb30000003bbbb30000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000bbbbbbbbbbbbb30000003bbbb30000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000bbbbbbbbbbbbb3330000b333333b000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000bbbbbbbbbbbbb333000bbbbbbbbbb00000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000bbbbbbbbbbbb3333003bbbbbbbbbb30000000000000000000000000000000000000000000000000000000000
40000000000000006556655500bbbb0000066600bbbbbbbbbbb33333003bbbbbbbbbb30000000000000000000000000000000000000000000000000000000000
0004000000000000655655560bbbbb3000665550bbbbbbbbbb3333330b333333333333b000000000000000000000000000000000000000000000000000000000
000000040000000055665566bbbbbb3306655555bbbbbbbbb33333330bbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000
000000000000000056655665bbbbb333065555550bbbbbbb33333330bbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
000400400000000056655665bbbbb333655556550bbbbbb333333330bbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
040000000000000056556655bbb333335555655500bbb333333333003bbbbbbbbbbbbbb300000000000000000000000000000000000000000000000000000000
00000000000000005665665603333330555565550003333333333000033333344333333000000000000000000000000000000000000000000000000000000000
00000400000000006665655600333300055555500000033333300000000000044000000000000000000000000000000000000000000000000000000000000000
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888777777888eeeeee888888888888888888888888888888888888888888888888888888888888888ff8ff8888228822888222822888888822888888228888
8888778887788ee88eee88888888888888888888888888888888888888888888888888888888888888ff888ff888222222888222822888882282888888222888
888777878778eeee8eee88888e88888888888888888888888888888888888888888888888888888888ff888ff888282282888222888888228882888888288888
888777878778eeee8eee8888eee8888888888888888888888888888888888888888888888888888888ff888ff888222222888888222888228882888822288888
888777878778eeee8eee88888e88888888888888888888888888888888888888888888888888888888ff888ff888822228888228222888882282888222288888
888777888778eee888ee888888888888888888888888888888888888888888888888888888888888888ff8ff8888828828888228222888888822888222888888
888777777778eeeeeeee888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555566656555555565556665566566655555566566556665666555555555cc5555555555555555555555555555555555555555555555555555555555555
555555555656565555555655565656555565555556555656556556565777555555c5555555555555555555555555555555555555555555555555555555555555
555555555666565555555655566656665565555556555656556556655555577755c5555555555555555555555555555555555555555555555555555555555555
555555555655565555555655565655565565555556555656556556565777555555c5555555555555555555555555555555555555555555555555555555555555
55555555565556665575566656565665556556665566566656665656555555555ccc555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555666565555555566566556665666555555555cc555555555555555555555555555555555555555555555555555555555555555555555555555555555
5555555556565655555556555616556556565777555555c555555555555555555555555555555555555555555555555555555555555555555555555555555555
5555555556665655555556555171556556655555577755c555555555555555555555555555555555555555555555555555555555555555555555555555555555
5555555556555655555556555177156556565777555555c555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555655566655755566517771665656555555555ccc55555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555551777715555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555eee5e5555ee5eee555551771155555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555e555e555e555e55555555117155555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555ee55e555eee5ee5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555e555e55555e5e55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555eee5eee5ee55eee555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555e5555ee55ee5eee5e5555555656556656655555565655665665555555555cc5555555555cc555555555555555555555555555555555555555555555
555555555e555e5e5e555e5e5e55555556565655565655555656565556565777555555c55555555555c555555555555555555555555555555555555555555555
555555555e555e5e5e555eee5e55555555655655565655555666565556565555577755c55555577755c555555555555555555555555555555555555555555555
555555555e555e5e5e555e5e5e55555556565655565655755556565556565777555555c55575555555c555555555555555555555555555555555555555555555
555555555eee5ee555ee5e5e5eee55555656556656665755566655665666555555555ccc575555555ccc55555555555555555555555555555555555555555555
55555555555588888555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555588888555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555577788888555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555588888555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555577788888555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555588888555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555566656555555556656655666566655555666556656655555555555555555555555555555555555555555555555555555555555555555555555555555
55555555565656555555565556565565565657775656565556565555555555555555555555555555555555555555555555555555555555555555555555555555
55555555566656555555565556565565566555555665565556565555555555555555555555555555555555555555555555555555555555555555555555555555
55555555565556555555565556565565565657775656565556565555555555555555555555555555555555555555555555555555555555555555555555555555
55555555565556665575556656665666565655555656556656665555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555eee5ee55ee55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555e555e5e5e5e5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555ee55e5e5e5e5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555e555e5e5e5e5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555eee5e5e5eee5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555e5555ee55ee5eee5e5555555666565655555666565655555ccc55555ccc5555555555555555555555555555555555555555555555555555555555555555
55555e555e5e5e555e5e5e5555555666565655555666565657775c5c55555c5c5555555555555555555555555555555555555555555555555555555555555555
55555e555e5e5e555eee5e5555555656556555555656566655555c5c55555c5c5555555555555555555555555555555555555555555555555555555555555555
55555e555e5e5e555e5e5e5555555656565655755656555657775c5c55755c5c5555555555555555555555555555555555555555555555555555555555555555
55555eee5ee555ee5e5e5eee55555656565657555656566655555ccc57555ccc5555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555eee5eee555555755666565555555566566556665666555555555ccc5575555556665656555556665656555555555cc555555ccc55555555555555555555
555555e55e55555557555656565555555655565655655656577757775c5c55575555566656565555566656565777555555c555555c5c55555555555555555555
555555e55ee5555557555666565555555655565655655665555555555c5c55575555565655655555565656665555577755c555555c5c55555555555555555555
555555e55e55555557555655565555555655565655655656577757775c5c55575555565656565575565655565777555555c555755c5c55555555555555555555
55555eee5e55555555755655566655755566566656665656555555555ccc5575555556565656575556565666555555555ccc57555ccc55555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555eee5eee555555755666565555555566566556665666555555555cc5557555555666565655555666565655555cc555555ccc555555555555555555555555
555555e55e555555575556565655555556555656556556565777577755c55557555556665656555556665656577755c555555c5c555555555555555555555555
555555e55ee55555575556665655555556555656556556655555555555c55557555556565565555556565666555555c555555c5c555555555555555555555555
555555e55e555555575556555655555556555656556556565777577755c55557555556565656557556565556577755c555755c5c555555555555555555555555
55555eee5e55555555755655566655755566566656665656555555555ccc557555555656565657555656566655555ccc57555ccc555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555eee5eee555555755666565555555566566556665666555555555ccc557555555666565655555666565655555ccc555555555cc555555555555555555555
555555e55e5555555755565656555555565556565565565657775777555c555755555666565655555666565657775c5c5555555555c555555555555555555555
555555e55ee5555557555666565555555655565655655665555555555ccc555755555656556555555656566655555c5c5555577755c555555555555555555555
555555e55e55555557555655565555555655565655655656577757775c55555755555656565655755656555657775c5c5575555555c555555555555555555555
55555eee5e55555555755655566655755566566656665656555555555ccc557555555656565657555656566655555ccc575555555ccc55555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555eee5eee555555755666565555555566566556665666555555555ccc557555555666565655555666565655555ccc55555cc5555555555555555555555555
555555e55e5555555755565656555555565556565565565657775777555c555755555666565655555666565657775c5c555555c5555555555555555555555555
555555e55ee55555575556665655555556555656556556655555555555cc555755555656556555555656566655555c5c555555c5555555555555555555555555
555555e55e5555555755565556555555565556565565565657775777555c555755555656565655755656555657775c5c557555c5555555555555555555555555
55555eee5e55555555755655566655755566566656665656555555555ccc557555555656565657555656566655555ccc57555ccc555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555e5555ee55ee5eee5e55555555665666566555555ccc55555cc5555555555555555555555555555555555555555555555555555555555555555555555555
55555e555e5e5e555e5e5e55555556555656565657775c5c555555c5555555555555555555555555555555555555555555555555555555555555555555555555
55555e555e5e5e555eee5e55555556665666565655555c5c555555c5555555555555555555555555555555555555555555555555555555555555555555555555
55555e555e5e5e555e5e5e55555555565655565657775c5c555555c5555555555555555555555555555555555555555555555555555555555555555555555555
55555eee5ee555ee5e5e5eee555556655655566655555ccc55c55ccc555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555666565555555665565655555666565657575566566656655555555555555555555555555555555555555555555555555555555555555555555555555555
55555656565555555656565657775666565655755655565656565555555555555555555555555555555555555555555555555555555555555555555555555555
55555666565555555656556555555656556557775666566656565555555555555555555555555555555555555555555555555555555555555555555555555555
55555655565555555656565657775656565655755556565556565555555555555555555555555555555555555555555555555555555555555555555555555555
55555655566655755666565655555656565657575665565556665555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555666565555555665565655555666565657575566566656655555555555555555555555555555555555555555555555555555555555555555555555555555
55555656565555555656565657775666565655755655565656565555555555555555555555555555555555555555555555555555555555555555555555555555
55555666565555555656566655555656566657775666566656565555555555555555555555555555555555555555555555555555555555555555555555555555
55555655565555555656555657775656555655755556565556565555555555555555555555555555555555555555555555555555555555555555555555555555
55555655566655755666566655555656566657575665565556665555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
82888222822882228888828882888882822882828288888888888888888888888888888888888888888888888222822282888882822282288222822288866688
82888828828282888888828882888828882882828288888888888888888888888888888888888888888888888282888282888828828288288282888288888888
82888828828282288888822282228828882882228222888888888888888888888888888888888888888888888222888282228828822288288222822288822288
82888828828282888888828282828828882888828282888888888888888888888888888888888888888888888882888282828828828288288882828888888888
82228222828282228888822282228288822288828222888888888888888888888888888888888888888888888882888282228288822282228882822288822288
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000001010101000000000000000000010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2526252625262526252625262526252632323232323232323232323232323232000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3536353635363536353635363536353632000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2526303030303030303030303030252632000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3536303030303030303030343430353632000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2526303400000000000000003030252632000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3536303000000000000000003030353632000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2526303000000000000000000000003100000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3536303000000000000000000000003100000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2526303000000000000000003030252632000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3536303000000000000000003030353632000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2526303030303030000030303030252632000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3536303030303030000030303030353632000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2526303030303030000030303030252632000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3536303030303030000030303030353632000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2526252625262526000025262526252632000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3536353635363536000035363536353632323232323232323232323232323232000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000