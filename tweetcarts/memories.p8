pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function l(y)return 24576+mid(y,0,127)*64 end
::_::cls(12)srand()for i=0,50 do
u=t()/4
a=i/25+u
r=2+sin(u+i/99)z=9+sin(a)*r+r*cos(r)circfill(64+64*(cos(a)*r-sin(a)*r)/z,64+64*((i)%50-25)/z,25-z,14)end
for i=0,127 do
d=6*sin(u)+9memcpy(l(i+flr(rnd(d*2)-d)),l(i),64)end
flip()goto _
