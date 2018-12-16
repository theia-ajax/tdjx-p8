pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
_set_fps(60)

n=50
n=890
n=809
n=500
--n=2733
--n=3246

::⌂::
cls()
u=t()/8

srand()

n=64
for j=0,(256/n)-1 do
for i=0,n-1 do
r=(u+i/n)%1*256-j
x0=64-r
y0=64
x1=64-r*1.4
y1=64-r*1.4
x2=64
y2=64-r
line(x0,y0,x2,y2,8+i%8)
--line(x1,y1,x2,y2,8+i%8)
end
end

--[[
for i=0,n do
for j=0,5 do
u=(t()+rnd())
a=sin(u)/10+rnd()/4+j*.01
r=rnd()*92
x0=cos(a)*r+64
y0=sin(a)*r+64
x1=cos(a+j*.01)*r+64
y1=sin(a+j*.01)*r+64
--pset(cos(a)*r+64,sin(a)*r+64,8+j)--8+(flr(rnd()*7)))
line(x0,y0,x1,y1,8+(j+i)%7)
end
end
--]]

--[[
if (btnp(2)) n+=1
if (btnp(3)) n-=1
for i=1,n do
a=rnd()/4+.25
r=((rnd()+u)%1)*91
x=cos(a)*r+64
y=sin(a)*r+64
--x=64-((t()*.2+rnd())%1)*64
--y=64-((t()*.2+rnd())%1)*64
--pset(x,y,8+rnd()*7)
circfill(x,y,8,8+rnd()*7)
end


if (btn(4)) print("★:"..n,0,0,8)
--print("cpu:"..stat(1)*100,0,6,7)
--]]

-- copy top left corner to
-- top right
for y=0,63 do
memcpy(0x6000+y*64+32,0x6000+y*64,32)
end

-- flip pixels in top right
-- quarter
-- flip left/right pixel pairs
-- per byte
for y=0,63 do
for x=0,15 do
la=0x6000+y*64+32+x
ra=0x6000+y*64+32+(31-x)
l=peek(la)
l=bor(shl(band(l,0xf),4),shr(l,4))
r=peek(ra)
r=bor(shl(band(r,0xf),4),shr(r,4))
poke(la,r)
poke(ra,l)
end
end

-- copy top half to bottom half
-- inversed
for y=0,63 do
memcpy(0x6000+(127-y)*64,0x6000+y*64,64)
end

flip()
goto ⌂
