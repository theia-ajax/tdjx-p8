pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function onkey(key)
	if key=="f" then
		ghost_kill(ghosts[1])
	end
end

function _init()
	poke(0x5f2d, 1)

	plr={}
	plr.x=64
	plr.y=89
	plr.w=6
	plr.h=6
	plr.hw=plr.w/2
	plr.hh=plr.h/2
	plr.mvivl=2
	plr.mvf=0
	plr.sp=1
	plr.spivl=2
	plr.spf=plr.spivl
	plr.cdir=0
	plr.sdir=0
	plr.xfl=false
	plr.yfl=false
	plr.tlx,plr.tly=0,0
	plr.trx,plr.try=0,0
	plr.blx,plr.bly=0,0
	plr.brx,plr.bry=0,0
	
	wld={}
	wld.ox=1
	wld.oy=-4
	wld.cw=20
	wld.ch=20
	wld.cszx=6 --cell size
	wld.cszy=6
	wld.boundl=wld.ox+
		wld.cszx-
		plr.hw-1
	wld.boundr=wld.ox+
		wld.cw*wld.cszx+
		plr.hw
	wld.enspt={}
	for cx=0,wld.cw do
		for cy=0,wld.ch do
			local m=mget(cx,cy)
			if fget(m,5) then
				local wx,wy=cell_to_world(
					cx,cy)
				add(wld.enspt,{
					x=wx+4,y=wy+4,
					cx=cx,cy=cy
				})
			end
		end
	end
		
	ghosts={}
	ghostct=4
	for i=1,ghostct do
		local spt=wld.enspt[2]
		add(ghosts,new_ghost(
			spt.x,spt.y,i))
	end

	dots={}
	for x=1,wld.cw-1 do
		for y=0,wld.ch do
			local m=mget(x,y)
			if not fget(m,0) and
				not fget(m,2)
			then
				local wx,wy=
					cell_to_world(x,y)
				add(dots,{
					x=wx+2,y=wy+2,
					hide=false,
					power=false
				})
			end
		end
	end
	
	local n=#dots
	for i=1,n do
		for j=i+1,n do
			local d1=dots[i]
			local d2=dots[j]
			local dx=abs(d1.x-d2.x)
			local dy=abs(d1.y-d2.y)
			local mnx=min(d1.x,d2.x)
			local mny=min(d1.y,d2.y)
			-- dx==5 xor dy==5
			if (dx==6 and dy==0) or
				(dx==0 and dy==6)
			then
				add(dots,{
					x=mnx+dx/2,y=mny+dy/2,
					hide=false,
					power=false
				})
			end
		end
	end
	
	dots[2].power=true
	dots[8].power=true
	dots[137].power=true
	dots[143].power=true
end

mspico_mode=false
function _update60()
	if stat(30) then
		onkey(stat(31))
	end
	
	if btnp(4) then
		mspico_mode=not mspico_mode
	end

	for i=0,3 do
		local c=btn_cdir(i)
		if btn(i) and
			ent_clear(plr,c) and
			c~=plr.cdir
		then
			plr.cdir=c
			break
		end
	end
	
	plr.mvf-=1
	if plr.mvf<=0 then
		plr.mvf=plr.mvivl
		ent_move(plr)
	end

	if plr.cdir>0 then	
		plr.sdir=plr.cdir
 	plr.spf-=1
 	if plr.spf<=0 then
 		plr.spf=plr.spivl
 		plr.sp+=1
 		if (plr.sp>6) plr.sp=1
 	end
 else
 	plr.spf=plr.spivl
 	plr.sp=1
 end
 
 for gst in all(ghosts) do
 	if ent_overlap(plr,gst,3)
 	then
 		if gst.stunf>0 then
 			ghost_kill(gst)
 		end
 	end
 end
 
 for i=1,#dots do
 	local d=dots[i]
 	local dx=abs(plr.x-d.x)
 	local dy=abs(plr.y-d.y)
 	if not d.hide and dx<2 and
 		dy<2
 	then
 		d.hide=true
 		if d.power then
 			foreach(ghosts,ghost_stun)
 		end
 	end
 end
 
 foreach(ghosts,ghost_update)
end

function _draw()
	cls()
	ox=wld.ox
	oy=wld.oy
	if mspico_mode then
		pal(13,14)
		pal(1,2)
		pal(2,3)
	end
	for x=1,wld.cw-1 do
		for y=0,wld.ch do
			local m=mget(x,y)
			if m>0 and not fget(m,2) then
				spr(m,x*wld.cszx+ox,
					y*wld.cszy+oy)
			end
		end
	end
	pal()
	
	for i=1,#dots do
		local d=dots[i]
		if not d.hide then
			if not d.power then
				pset(d.x,d.y,6)
			else
				rectfill(d.x-1,d.y-1,
					d.x+1,d.y+1,5)
				circfill(d.x,d.y,1,6)
			end
		end
	end

	local sp=plr.sp
	if plr.sdir>0 and 
		plr.sdir%2==0
	then
		sp+=6
	end
	
	local xfl,yfl=false,false
	
	if (plr.sdir==2) yfl=true
	if (plr.sdir==3) xfl=true
	
	local ox,oy=-4,-4
	if (xfl) ox-=0
	if (yfl) oy-=0

	spr(sp,plr.x+ox,plr.y+oy,
		1,1,
		xfl,yfl)
		
	foreach(ghosts,ghost_draw)
		
//	pset(plr.tlx,plr.tly,8)
//	pset(plr.trx,plr.try,9)
//	pset(plr.blx,plr.bly,11)
//	pset(plr.brx,plr.bry,12)
	
	rectfill(0,0,wld.boundl+3,127,0)
	rectfill(wld.boundr-3,0,127,127,0)	
	
--[[	
	local msx,msy=stat(32),stat(33)
	for i=1,#dots do
		if dots[i].x==msx and
			dots[i].y==msy
		then
			print(i,64,123,7)
		end
	end
	pset(msx,msy,11)
]]

	spr(76+((t()*6)%4),40,119)
 spr(80+((t()*4)%10),64,119)
 
 local cpu=band(stat(1)*100,
 	0xffff)
 local cpustr="cpu: "..lz(tostr(cpu),1).."%"
 print(cpustr,127-#cpustr*4,123,7)
 
 local mem=band(
 	(stat(0)/2048)*100,0xffff)
 local memstr="mem: "..lz(tostr(mem),1).."%"
 print(memstr,127-#memstr*4,117,7)

 console_draw()
end

function
ent_clear(ent,cdir,dx,dy)
	local xx,yy=cdir_to_dir(cdir)
	dx=dx or xx
	dy=dy or yy

	local lx,ly=0,0
	local rx,ry=0,0
	
	if cdir==0 then
		return true
	elseif cdir==1 then
		lx,ly=ent.trx,ent.try
		rx,ry=ent.brx,ent.bry
	elseif cdir==2 then
		lx,ly=ent.tlx,ent.tly
		rx,ry=ent.trx,ent.try
	elseif cdir==3 then
		lx,ly=ent.blx,ent.bly
		rx,ry=ent.tlx,ent.tly
	elseif cdir==4 then
		lx,ly=ent.brx,ent.bry
		rx,ry=ent.blx,ent.bly
	else
		return true
	end
	
	lx+=dx
	ly+=dy
	rx+=dx
	ry+=dy
	
	local ph=ent.phase
	local s1=point_solid(lx,ly,ph)
	local s2=point_solid(rx,ry,ph)
	return not s1 and not s2
end

function ent_move(ent)
	local dx,dy=cdir_to_dir(
		ent.cdir)
		
	dx*=1
	dy*=1
	
	if not ent_clear(ent,ent.cdir)
	then
		ent.cdir=0
		dx=0
		dy=0
	end
	
	ent.x+=dx
	ent.y+=dy
	
	if dx>0 and ent.x>=wld.boundr
	then
		ent.x=ceil(wld.boundl)
	elseif dx<0 and
		ent.x<=wld.boundl
	then
		ent.x=ceil(wld.boundr-1)
	end
	
	ent.tlx=ent.x-ent.hw
	ent.tly=ent.y-ent.hh
	
	ent.blx=ent.x-ent.hw
	ent.bly=ent.y+ent.hh-1

	ent.trx=ent.x+ent.hw-1
	ent.try=ent.y-ent.hh

	ent.brx=ent.x+ent.hw-1
	ent.bry=ent.y+ent.hh-1
end

function ent_cell(ent)
	return world_to_cell(
		ent.x,ent.y)
end

function ent_overlap(e1,e2,tol)
	tol=tol or 0

	local dx,dy=abs(e1.x-e2.x),
		abs(e1.y-e2.y)
	return dx<=tol and dy<=tol
end

_ghost_data={
	{
		col=8,
		sp=64
	},
	{
		col=9,
		sp=64
	},
	{
		col=12,
		sp=65
	},
	{
		col=14,
		sp=65
	},
}

-- ghosts
function new_ghost(x,y,gt)
	local gst={}
	
	gst.x=x or 0
	gst.y=y or 0
	gst.tcx=-1 --target cell x
	gst.tcy=-1 --target cell y
	gst.cdir=0
	gst.sdir=1
	gst.gtype=gt or 0
	gst.w=6
	gst.h=6
	gst.hw=gst.w/2
	gst.hh=gst.h/2
	gst.tlx,gst.tly=0,0
	gst.trx,gst.try=0,0
	gst.blx,gst.bly=0,0
	gst.brx,gst.bry=0,0
	gst.mvivl=3
	gst.mvf=0
	gst.spivl=12+flr(rnd(8))
	gst.spf=gst.spivl
	gst.flx=false
	gst.stundur=300
	gst.stunf=0
	gst.stunmvivl=8
	gst.hide=true
	gst.phase=false
	gst.phasef=gst.gtype*60

	return gst
end

function ghost_mvivl(gst)
	if gst.stunf>0 then
		if gst.hide then
			return 1
		else
			return gst.stunmvivl
		end
	else
		return gst.mvivl
	end
end

function ghost_kill(gst)
	gst.hide=true
	gst.phase=true
	gst.phasef=gst.gtype*60
	gst.tcx=10
	gst.tcy=9
end

function
ghost_target_plr(gst,plr)
	gst.tcx,gst.tcy=
		world_to_cell(plr.x,plr.y)
end

function ghost_update(gst)
	if (gst.cdir==0) gst.cdir=flr(rnd(4))+1
	
	if ghost_on_spawn(gst) then
		gst.stunf=0
		
		if gst.phasef>0 then
			gst.phasef-=1
			gst.phase=false
			gst.tcx=-1
			gst.tcy=-1
		else
			gst.phase=true
		end
	else
		if not gst.phase then
			gst.hide=false
		end
	
		local cx,cy=world_to_cell(
			gst.x,gst.y)
		if fget(mget(cx,cy),6) and
			not cell_is_spawn(gst.tcx,gst.tcy)
		then	
			gst.phase=false
		end
		gst.phasef=gst.gtype*60
	end
	
	if not gst.hide then
		ghost_target_plr(gst,plr)
	end
	
	if gst.cdir>0 then
		gst.sdir=gst.cdir
		gst.mvf-=1
		if gst.mvf<=0 then
			gst.mvf=ghost_mvivl(gst)
			ghost_eval(gst)
			ent_move(gst)
		end
	end
	
	if gst.stunf>0 and
		not gst.hide
	then
		gst.stunf-=1
		gst.spf-=1
		if gst.spf<=0 then
			gst.spf=gst.spivl
			gst.flx=not gst.flx
		end
	end
end

function ghost_eval(gst)
	local opts={}
	local back=cdir_back(gst.cdir)
	for c=1,4 do
		if c~=back
		then
			if ent_clear(gst,c)
			then
				add(opts,c)
			end
		end
	end

	if #opts>0 then
 	if gst.tcx>=0 and gst.tcy>=0
 	then
 		local cx,cy=world_to_cell(
 			gst.x,gst.y)
 		local best=0
 		local mn=999
 		for i=1,#opts do
  		local o=opts[i]
  		local ox,oy=cell_in_dir(
  			cx,cy,o)
  		local dst=man_dist(ox,oy,
  			gst.tcx,gst.tcy)
  		if dst<mn then
  			mn=dst
  			best=o
  		end
  	end
  	gst.cdir=best
  else
 	 gst.cdir=opts[flr(rnd(#opts))+1]
  end
 end
end

function ghost_stun(gst)
	gst.stunf=gst.stundur
end

function ghost_on_spawn(gst)
	local cx,cy=world_to_cell(
		gst.x,gst.y)

	for spt in all(wld.enspt) do
		if spt.cx==cx and spt.cy==cy
		then
			return true
		end
	end
	
	return false
end

function ghost_draw(gst)
	local data=
		_ghost_data[gst.gtype]
	
	if not gst.hide then	
 	if gst.stunf<=0 then
 		pal(7,data.col)
 		spr(data.sp,gst.x-4,gst.y-4)
 		pal()
 		spr(67+gst.sdir,
 			gst.x-4,gst.y-4)
 	else
 		if not gst.flx then
 			pal(7,1)
 			pal(1,7)
 		end
 		spr(data.sp+2,
 			gst.x-4,gst.y-4,
 			1,1,
 			gst.flx,false)
 		pal()
 	end
 else
 	pal()
 	spr(67+gst.sdir,
 		gst.x-4,gst.y-4)
 end


//	pset(gst.x,gst.y,7)
//	pset(gst.tlx,gst.tly,8)
//	pset(gst.trx,gst.try,9)
//	pset(gst.blx,gst.bly,10)
//	pset(gst.brx,gst.bry,11)
end

_cdir_tbl={
	{x=0,y=0},
	{x=1,y=0},
	{x=0,y=-1},
	{x=-1,y=0},
	{x=0,y=1},
}
function cdir_to_dir(cdir)
	local v=_cdir_tbl[cdir+1]
	return v.x,v.y
end

_cdir_back_tbl={
	0,3,4,1,2
}
function cdir_back(cdir)
	return _cdir_back_tbl[cdir+1]
end

function point_solid(x,y,ph)
	local cx,cy=world_to_cell(x,y)
	return cell_solid(cx,cy,ph)
end

function world_to_cell(wx,wy)
	return 
		flr((wx-wld.ox)/wld.cszx),
		flr((wy-wld.oy)/wld.cszy)
end

function cell_is_spawn(cx,cy)
	return fget(mget(cx,cy),5)
end

function cell_to_world(cx,cy)
	return cx*wld.cszx+wld.ox,
		cy*wld.cszy+wld.oy
end

function cell_in_dir(cx,cy,d)
	local dx,dy=cdir_to_dir(d)
	return cx+dx,cy+dy
end

function cell_solid(cx,cy,ph)
	local m=mget(cx,cy)
	local f=fget(m,0)
	if f then
		if ph then
			return not fget(m,1)
		else
			return true
		end
	else
		return false
	end
end

function wld_rnd_spawn()
	local idx=flr(rnd(#wld.enspt))
	return wld.enspt[idx+1]
end

_btn_cdir={3,1,2,4}
function btn_cdir(b)
	return _btn_cdir[b+1]
end

function rndi(mx)
	return flr(rnd(ceil(mx)))
end

function rndr(mn,mx)
	if mx<mn then
		mn,mx=mx,mn
	end
	return rnd(mx-mn)+mn
end

function rndir(mn,mx)
	if mx<mn then
		mn,mx=mx,mn
	end
	mn=flr(mn)
	mx=ceil(mx)
	return rndi(mx-mn)+mn
end

console={}
console.mx=18
function log(msg)
	add(console,tostr(msg))
	if #console>console.mx then
		idel(console,1)
	end
end

function console_draw()
	for i=1,#console do
		local msg=console[i]
		print(msg,0,(i-1)*6)
	end
end

function man_dist(x1,y1,x2,y2)
	local dx,dy=x2-x1,y2-y1
//	return sqrt(dx*dx+dy*dy)
	return abs(dx)+abs(dy)
end

function lz(str,ct)
	local n=#str
	local ret=str
	for i=ct-n,0,-1 do
		ret="0"..ret
	end
	return ret
end
-->8
-------------------------------
-- table utilities --
-------------------------------
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
-------------------------------
-->8
-- todo

-- code:
--		enemy interaction
--			player death when not stun
--				reset player
--				reset ghosts
--				remove life
--				end game if necessary
--		enemy ai
--			better pathing, a*?
--			specific ghost quirks
--		lives
--		game cycle
--		leaderboard
--			data storage
--			score entry screen
--			leaderboard display
--			in-game scoring
--		menu
--		attract screen?
--		demo mode?
--		splash screen
--		hud
--		bonus fruit
--		ms. picoman mode!★

-- art:

-- audio:
--		all of it
__gfx__
0000000000aaaa0000aaaa0000aaaa0000aaa00000aaaa0000aaaa0000aaaa0000aaaa0000aaaa0000aaaa0000aaaa0000aaaa00000000000000000000000000
000000000aaaaaa00aaaaaa00aaaa0000aaa00000aaaa0000aaaaaa00aaaaaa00aaaaaa00aaaaaa00aaaaaa00aaaaaa00aaaaaa0000000000000000000000000
00700700aaaaaaaaaaaaaa00aaaa0000aaaa0000aaaa0000aaaaaa00aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa000000000000000000000000
00077000aaaaaaaaaaaaa000aaa00000aaa00000aaa00000aaaaa000aaaaaaaaaaaaaaaaaaa00aaaaaa00aaaaaa00aaaaaaaaaaa000000000000000000000000
00077000aaaaaaaaaaaaa000aaa00000aaa00000aaa00000aaaaa000aaaaaaaaaaaaaaaaaa0000aaa000000aaa0000aaaaaaaaaa000000000000000000000000
00700700aaaaaaaaaaaaaa00aaaa0000aaaa0000aaaa0000aaaaaa00aaaaaaaaaaa00aaaa000000a00000000a000000aaaa00aaa000000000000000000000000
000000000aaaaaa00aaaaaa00aaaa0000aaa00000aaaa0000aaaaaa00aaaaaa00a0000a00000000000000000000000000a0000a0000000000000000000000000
0000000000aaaa0000aaaa0000aaaa0000aaa00000aaaa0000aaaa0000aaaa000000000000000000000000000000000000000000000000000000000000000000
d0000d00dddddd00ddddd0000ddddd000dddd000d0000d000ddddd00d0000d00d0000d00ddddd000dddddd00d0000d00d0000d00d0000d00dddddd00d0000000
d0000d00000000000000dd00dd000000dd00dd00d0000d00dd000000d000000000000d000000dd0000000000d00000000000000000000d00d0000000d0000000
d0000d000000000000000d00d0000000d0000d00d0000d00d0000000d000000000000d0000000d0000000000d00000000000000000000d00d0000000d0000000
d0000d000000000000000d00d0000000d0000d00d0000d00d0000000d000000000000d0000000d0000000000d00000000000000000000d00d0000000d0000000
d0000d00000000000000dd00dd000000d0000d00dd00dd00d0000000dd0000000000dd0000000d0000000000d00000000000000000000d00d0000000d0000000
d0000d00dddddd00ddddd0000ddddd00d0000d000dddd000d0000d000ddddd00dddddd00d0000d00d0000d00d0000d00dddddd00d0000d00d0000000dddddd00
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000d00dddddd00d000000000000d00dddddd000000000022222200ddddd0000ddddd000dddd000d0dd0d00dddddd00000000000000000000000000dddddd00
00000d0000000d00d000000000000d000000000000000000000000000000dd00dd000000dd00dd00d0dd0d0000000000000000000000000000000000dddddd00
00000d0000000d00d000000000000d00000000000000000000000000dddd0d00d0dddd00d0dd0d00d0dd0d00dddddd0000000000000000000000000000000000
00000d0000000d00d000000000000d00000000000000000000000000dddd0d00d0dddd00d0dd0d00d0dd0d00dddddd0000000000000000000000000000000000
00000d0000000d00d000000000000d000000000000000000000000000000dd00dd000000d0dd0d00dd00dd0000000000dddddd000ddddd00ddddd00000000000
dddddd0000000d00d000000000000d0000000000dddddd0000000000ddddd0000ddddd00d0dd0d000dddd000dddddd00dddddd00dddddd00dddddd0000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddd00dddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ddddd00ddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000e00e000080080000d00d0000a00a000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ee00000088000000dd000000aa0000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ee00000088000000dd000000aa0000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e00e000080080000d00d0000a00a000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700007777000011110000111100000000000000000000000000000000000000000000000000000000000000000000aaaa0000a00a0000aaaa0000aaaa00
07777770077777700111111001111110000000000dd00dd00000000000000000000000000000000000000000000000000aaaaaa00aa00aa00aaaaaa00aaaaaa0
77777777777777771177177111771771007d007d07700770d700d7000000000000000000000000000000000000000000aaaaaaaaaaa00aaaaaaaaaaaaaaaaaaa
77777777777777771177177111771771007d007d00000000d700d7000000000000000000000000000000000000000000aaaa0000aaa00aaa0000aaaaaaaaaaaa
777777777777777711111111111111110000000000000000000000000770077000000000000000000000000000000000aaaa0000aaaaaaaa0000aaaaaaa00aaa
777777777777777711771771117717710000000000000000000000000dd00dd000000000000000000000000000000000aaaaaaaaaaaaaaaaaaaaaaaaaaa00aaa
7777777777777777171171171711711700000000000000000000000000000000000000000000000000000000000000000aaaaaa00aaaaaa00aaaaaa00aa00aa0
07700770707007070110011010100101000000000000000000000000000000000000000000000000000000000000000000aaaa0000aaaa0000aaaa0000a00a00
00aaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0aaaaaa00a0000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaaaaaaaaa00aaaa000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaaaaaaaaa00aaaaa0000aa000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000000
aaaaaaaaaaaaaaaaaaa00aaaaaa00aaa000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000000
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa00aaaa00000aa000000000000a00a0a00000000000000000000000000000000000000000000000000000000000000000
0aaaaaa00aaaaaa00aaaaaa00aaaaaa00aaaaaa0000aa000000000000a0000a00000000000000000000000000000000000000000000000000000000000000000
00aaaa0000aaaa0000aaaa0000aaaa0000aaaa00000aa000000aa00000a00a000000000000000000000000000000000000000000000000000000000000000000
04000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ee044e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88e08800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88808800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd1d
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd1d
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
__gff__
0000000000000000000000000000000001010101010101010101010101010101010101010101030101010101010101010101000000000000000000004424050400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
3e2d2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2e3e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3e100000000000000000100000000000000000103e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3e1000282700282b27001500282b2700282700103e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3e100000000000000000000000000000000000103e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3e1000131200140013111a1112001400131200103e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3e100000000010000000100000001000000000103e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3e1b111119001b11123f153f13111d001611111d3e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3e103f3f1000103f3f3f3c3f3f3f1000103f3f103e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3e1711111800153f1e242624213f1500171111183e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
003f3f3f3f003f3f223d3d3d233f3f003f3f3f3f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3e1611111900143f1f252525203f1400161111193e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3e103f3f1000103f3f3f3f3f3f3f1000103f3f103e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3e1b11111800153f13111a11123f15001711111d3e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3e100000000000000000100000000000000000103e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3e100013190013111200150013111200161200103e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3e100000100000003f3f3f3f3f000000100000103e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3e1b12001500140013111a11120014001500131d3e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3e100000000010000000100000001000000000103e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3e10001311111c111200150013111c11111200103e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3e100000000000000000000000000000000000103e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3e302f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f313e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
