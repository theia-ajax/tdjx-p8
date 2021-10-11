pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
cls()
?"●"
memcpy(0,0x6000,64*128)
::_::
cls(1)
for i=8,0,-1 do
u=t()/4-i/128
r=24+i*4
//x=58+cos(u)*r
//y=60+sin(u)*r
x=64
y=i*10
l=1
pal(6,7+i)
sspr(0,0,4,8,x+s,y+s,8-s,16-s*2)
sspr(4,0,8,8,x+8,y+s,16-s*2,16-s*2)
end
flip()goto _
