pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
b={}r=rnd
function h()add(b,{x=r(128),y=r(128),r=-r(100)})end
h()h()h()h()h()poke(24372,1)::_::cls(1)for c in all(b) do c.r+=1if(c.r>50)del(b,c)h()
for i=0,4 do circ(c.x,c.y,c.r+min(i*(-3+c.r/12),0),0x10c1.0f0f-0x.0a05*flr(c.r/40))end;end;flip()goto _
