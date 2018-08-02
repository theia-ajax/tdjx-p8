pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
_set_fps(60)w=128
c=circ
d=circfill
r=rnd::_::
srand()
cls()for i=1,25 do
l=1+2*flr(r(3))x=((r(w)-t()*l*15)%(w+l))-l
y=r(w)line(x,y,x+l,y,5+l/2)end
y=64+16*sin(t()/8)d(64,y,20,7)c(64,y,20,2)c(64,y,19,8)c(64,y,18,8)d(72+t()%2,y,8,1)d(74+t()%2,y,4,0)flip()goto _
