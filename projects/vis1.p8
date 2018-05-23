pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
poke(24372,1)r,b,d,k,j=rnd,{},0x10c1.0f0f,128,60
for i=1,4 do add(b,{x=r(k),y=r(i)*j,r=i*-r(25)})end
::_::cls(1)for c in all(b) do c.r+=1
if(c.r>j)c.r,c.x,c.y=-r(j),r(k),r(k)
for i=0,4 do circ(c.x,c.y,c.r+(i*min(-3+5*c.r/j,0)),d)end;end;flip()goto _
