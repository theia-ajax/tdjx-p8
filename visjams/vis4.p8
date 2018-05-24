pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
v=stat
x=63y=63r=61w=cos(rnd(1))z=sin(rnd(1))f=v(95)
function l(a,i,o,c)d=cos(-a+1/4)e=sin(-a+1/4)line(x+d*i,y+e*i,x+d*o,y+e*o,c)end
::_::cls()circ(x,y,r+1,7)for i=0,11 do l(i/12,r-10,r,7) end
m=v(94)/60l((v(93)%12+m)/12,0,r/2,7)l(m,0,r,7)l((f+t())/60,0,r,8)flip()goto _
