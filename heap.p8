pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
function _init()
	poke(0x5f2d,1)
	
	g_col1=9
	g_col2=11
	
	g_set={}

	g_seed=0
	gen_data()
	
	g_sort=sequence(function()
		sort(data,data_n)
	end)
end

function gen_data(seed)
	data={}
	srand(seed or 0)
	for i=1,8 do
		add(data,flr(rnd(21))-10)
	end
	data_n=#data
	for i=0,data_n do
		data[i]=data[i+1]
	end
end

function keypress(key)
end

function sequence(seq_f)
	seq_q=seq_q or {}
	seq_f=seq_f or function() end
	return add(seq_q,cocreate(seq_f))
end

function finish(seq)
	del(seq_q,seq)
end
	
function wait_sec(s)
	s=s or 0
	local start=t()
	while t()<start+s do
		yield()
	end
end

function wait_frame(f)
	f=f or 0
	for i=1,f do
		yield()
	end
end

function _update()
	_any_key_press=false

	while stat(30) do
		_any_key_press=true
		keypress(stat(31))
	end
	
	for seq in all(seq_q) do
		if seq and costatus(seq)~="dead"
		then
			assert(coresume(seq))
		else
			del(seq_q,seq)
		end
	end
	
	if btnp(5) then
		g_col()
		finish(g_sort)
		g_seed+=1
		gen_data(g_seed)
		g_sort=sequence(function()
			sort(data,data_n)
		end)
	end
end

function _draw()
	cls(1)
	
	rectfill(0,16,127,16,4)
	
	for i=0,data_n-1 do
		local x=i*128/data_n
		local y=-1.6*data[i]+16
		local c=g_col1
		if g_set[i] then
			c=g_col2
		end
		rectfill(x,16,x+4,y,c)
	end

	rectfill(0,32,127,127,0)	
	rect(0,32,127,127,7)
	
	draw_tree_view(data,data_n)
end
-->8
function swap(a,i0,i1)
	g_col(8,i0,i1)

	local t=a[i0]
	a[i0]=a[i1]
	a[i1]=t
end

function sift(a,p,n)
	n=n or #a
	
	g_col(12,p,n)
	wait_for_any_key()
	
	local v=a[p]
	local m=p*2+1
	while m<=n do
		
		if m<n and a[m+1]>a[m] then
			m+=1
		end
		if v>=a[m] then
			break
		end
		a[p]=a[m]
		p=m
		m=m*2+1
		g_col(2,m,n)
		wait_for_any_key()
	end
	a[p]=v
end



function sort(a,n)
	wait_for_any_key()
	n=n or #a
	for i=flr(n/2),0,-1 do
		sift(a,i,n-1)
	end
	for i=n-1,1,-1 do
		swap(a,0,i)
		wait_for_any_key(5)
		sift(a,0,i-1)
	end
	g_col()
end

function any_key_press()
	local ret=_any_key_press
	_any_key_press=false
	return ret
end

function wait_for_any_key()
	while not any_key_press() do
		yield()
	end
end

function g_col(c,l,r)
	g_col2=c
	g_set={}
	if (l) g_set[l]=true
	if (r) g_set[r]=true
end
-->8
function draw_nodes(data,l,r,x,y,depth)
	depth=depth or 0
	
	local n=r-l
	
	if n<=0 then
		return false
	end
		
	local p=flr(n/2)
	local m=tostr(band(data[p],0xffff))
	local w=#m*2-1
	print(m,x-w,y-2,7)
	circ(x,y,max(w*2,6),7)
	
	local mx=24-depth*8
	local my=16
	
	hl=draw_nodes(data,0,p,x-mx,y+my,depth+1)
	if (hl) line(x-4,y+3,x-mx+4,y+my-4,7)
	hr=draw_nodes(data,p+1,n,x+mx,y+my,depth+1)
	if (hr) line(x+4,y+3,x+mx-4,y+my-4,7)
	return true
end

function draw_tree_view(data,n)
	local x1,y1=0,32
	
	local p=flr(n/2)
	
	draw_nodes(data,0,n,64,y1+8)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
