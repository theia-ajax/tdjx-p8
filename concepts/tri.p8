pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	pts={
		{x=-1,y=.5},
		{x=1,y=.5},
		{x=-1,y=-.5},
		{x=1,y=-.5},
	}
	
	for p in all(pts) do
		p.x*=1
		p.y*=1
	end
	
	ang=0.599
end

function _update()
	debug_clear()

	local ix,iy=0,0
	if (btn(0)) ix-=1
	if (btn(1)) ix+=1
	ang+=1/60*-ix
	
	debug(ang)
	debug("mem:"..stat(0))
	debug("cpu:"..stat(1))
end

function _draw()
	cls()
	
	txpts={}
	for p in all(pts) do
		x,y=rotate(p.x,p.y,ang)
		x=x*64+64
		y=y*64+64
		add(txpts,{x=x,y=y})
	end
	
	tri(txpts[1].x,txpts[1].y,
		txpts[2].x,txpts[2].y,
		txpts[3].x,txpts[3].y,
		7)
		
	tri(txpts[2].x,txpts[2].y,
		txpts[4].x,txpts[4].y,
		txpts[3].x,txpts[3].y,
		7)

		
	debug_draw()
end

function rotate(x,y,r)
	return cos(r)*x-sin(r)*y,
		sin(r)*x+cos(r)*y
end


__tri_buff = {{x=0,y=0},{x=0,y=0},{x=0,y=0}}
__top_buff = {{x=0,y=0},{x=0,y=0},{x=0,y=0}}
__bot_buff = {{x=0,y=0},{x=0,y=0},{x=0,y=0}}
function tri(x1,y1,x2,y2,x3,y3,c)
	if (c) color(c)

	vts = __tri_buff
	vts[1].x, vts[1].y = x1, y1
	vts[2].x, vts[2].y = x2, y2
	vts[3].x, vts[3].y = x3, y3

 sort(vts, function(a,b) return a.y<b.y end)

 if vts[1].y == vts[2].y then
 	_fttri(vts)
 elseif vts[3].y == vts[2].y then
 	_fbtri(vts)
	else
		local tx, ty = vts[1].x, vts[1].y
		local mx, my = vts[2].x, vts[2].y
		local bx, by = vts[3].x, vts[3].y
		local x4 = tx +
			round(my-ty)/
			round(by-ty)*
			round(bx-tx)
		local y4 = vts[2].y

		__top_buff[1]=vts[1]
		__top_buff[2]=vts[2]
		__top_buff[3].x=x4
		__top_buff[3].y=y4

		__bot_buff[1]=vts[2]
		__bot_buff[2].x=x4
		__bot_buff[2].y=y4
		__bot_buff[3]=vts[3]
		
		debug(y4)

		_fbtri(__top_buff)
		_fttri(__bot_buff)
	end
end

function _fttri(vts)
	local bx=round(vts[3].x)
	local by=round(vts[3].y)
	local ty=vts[1].y
	local lx=min(vts[1].x,vts[2].x)
	local rx=max(vts[1].x,vts[2].x)

	local ml=round(bx-lx)/round(by-ty)
	local mr=round(bx-rx)/round(by-ty)

	local l,r=bx,bx

	for y=by,ty,-1  do
		_hline(y,l,r)
		l-=ml
		r-=mr
	end
end

function _fbtri(vts)
	local tx = round(vts[1].x)
	local ty = round(vts[1].y)
	local by = vts[2].y
	local lx = vts[2].x
	local rx = vts[3].x

	local ml = round(lx-tx)/round(by-ty)
	local mr = round(rx-tx)/round(by-ty)

	local l, r = tx, tx

	debug(ty.." "..flr(ty))
	for y = round(ty), by  do
		_hline(y, l, r)
		l += ml
		r += mr
	end
end

function _hline(y,x1,x2)
	line(x1,y,x2,y)
end

function sort(a,fnlt)
	local i = 2
	while i <= #a do
		local x = a[i]
		local j = i - 1
		while j >= 1 and fnlt(x, a[j]) do
			a[j+1] = a[j]
			j -= 1
		end
		a[j+1] = x
		i += 1
	end
end

function round(n)
	if n-flr(n) < 0.5 then
		return flr(n)
	else
		return ceil(n)
	end
end


debugs={}
function debug(msg)
	add(debugs,msg)
end

function debug_clear()
	for i,_ in pairs(debugs) do
		debugs[i]=nil
	end
end

function debug_draw()
	for i,m in pairs(debugs) do
		print(m,0,(i-1)*6,11)
	end
end
