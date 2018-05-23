pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
t=0
poke(24372,1)r,b=rnd,{}function a()add(b,{x=cos(t/90)*40+63,y=sin(t/30)*40+63,r=-9})end
color(0x10c1.0f0f)
::_::cls(1)
t+=1
if(t%8==0)a()
for c in all(b) do c.r+=1
if(c.r>60)del(b,c)
for i=0,4 do circ(c.x,c.y,c.r+(i*min(-3+5*c.r/60,0)))end;end;flip()goto _
