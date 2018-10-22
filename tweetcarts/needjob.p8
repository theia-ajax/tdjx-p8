pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
cls()c={10,4,9,8,7}
?"i need a job"
memcpy(0,24576,999)::_::cls()l=16r=112
for y=1,#c do
for x=l,r do
u=48*(x-l)/(r-l)pal(6,c[y])sspr(u,0,1,8,x,48+sin(x/80+t()/4+y/30)*10,1,40)end
end
flip()goto _
