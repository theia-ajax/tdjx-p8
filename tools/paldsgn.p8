pico-8 cartridge // http://www.pico-8.com
version 32
__lua__

function _init()
	poke(0x5f2d,0x3)

	active=make_pal()
end

function _update()
end

function _draw()
	cls()
	fillp(~0xc639)
	rectfill(0,0,127,127,1)
	fillp()
	
	
	pal(active,1)
	
	draw_pal_panel(sin(t()*2.72*0.1)*6+64,cos(t()*2.72*0.05)*4+18)
	
	for i=0,15 do
		local v=draw_pal_btn(i%8*12+20,76+i\8*32,active[i])
		active[i]=v
	end

	circ(stat(32),stat(33),1,12)
end

function draw_pal_panel(px,py)
	local sx,sy=12,12
	local cols=8
	local pw=cols*sx+4
	local ph=ceil(16/cols)*sy+4
	
	local x,y=px-pw\2,py-ph\2
	
	fillp(0xcc33)
	rectfill(x,y,x+pw-1,y+ph-1,0x67)
	fillp()
	for i=0,15 do
		local l,t=(i%cols)*sx+x+2,(i\8)*sy+y+2
		local r,b=l+sx-1,t+sy-1
		rectfill(l,t,r,b,i)
	end
end

function draw_pal_btn(x,y,v)
	local c=7
	local mx,my=stat(32),stat(33)
	if rect_check(x-2,y-6,6,5,mx,my)
	then
		c=12
	end

	local d=0
	local tog=checkbox(x-2,y-13,6,5,v>=128)
	if tog then
		if v>=128 then
			v&=~0x80
		else
			v|=0x80
		end
	end
	if (text_button(x-2,y-6,6,5,"⬆️")) d+=1
	print(tohex(v&0x8f,2),x-2,y,7)
	if (text_button(x-2,y+6,6,5,"⬇️")) d-=1
	return (v+d)&0x8f
end

function text_button(x,y,w,h,txt)
	local c=7
	local mx,my=stat(32),stat(33)
	local ret=false
	if rect_check(x,y,w,h,mx,my)
	then
		c=btn(5) and 13 or 12
		ret=btnp(5)
	end
	print(txt,x,y,c)
	return ret
end

function checkbox(x,y,w,h,v)
	local c=7
	local mx,my=stat(32),stat(33)
	local ret=false
	if rect_check(x,y,w,h,mx,my)
	then
		c=btn(5) and 13 or 12
		ret=btnp(5)
	end
	local bc=0
	if (v) bc=8
	rectfill(x,y,x+w,y+h,bc)
	rect(x,y,x+w,y+h,c)
	return ret
end

function rect_check(x,y,w,h,px,py)
	return px>=x and px<x+w
		and py>=y and py<y+h
end

hexdigits={
	"0","1","2","3",
	"4","5","6","7",
	"8","9","a","b",
	"c","d","e","f"
}
function tohex(v,lz)
	lz=lz or 0
	local str=""
	local vv=v
	local n=0
	repeat
		local digit=hexdigits[vv%16+1]
		str=digit..str
		vv\=16
		n+=1
	until vv<=0
	
	for i=n,lz-1 do
		str="0"..str
	end
	
	return str
end

function make_pal()
	local p={}
	for i=0,15 do
		p[i]=i
	end
	return p
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
