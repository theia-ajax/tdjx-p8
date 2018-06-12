pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
l={10,9,8,2,1}
::_::
cls()srand()for m=0,100 do
y=rnd()w=rnd(3)+2
x=cos(y)*w
z=sin(y)*w
y=rnd(14)-7
b=rnd(1)
for n=0,4 do
a=t()/4+n*.01
c=cos(a)*x-sin(a)*z
d=sin(a)*x+cos(a)*z+7
g=64+(c*64)/d
h=64+(y*64)/d
circfill(g,h,max((5-d)+n,0),l[5-n])
end
end
flip()goto _
