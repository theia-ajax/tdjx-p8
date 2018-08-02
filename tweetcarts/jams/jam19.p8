pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
e=2.7183
l={8,12,11}
::_::
cls(8)
for n=4,0,-1 do
for i=60,200,1 do
r=i*(1/e)+n/4
a=r+t()/e
o=i*r/64+(20*(sin(t()/15)+1)/2)
x=cos(a)y=sin(a)
circfill(64+x*o,64+y*o,4-sin((o+t()*20)/10)*4,14)
end
end
flip()goto _
