pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
l={10,9,8,2,1}::_::cls()srand()for m=0,100 do
y=rnd()w=rnd(3)+2x=w*cos(y)z=w*sin(y)b=rnd(1)y=rnd(14)-7
for n=0,4 do
a=t()/4+n*.01c=cos(a)*x-z*sin(a)d=sin(a)*x+cos(a)*z+7g=64+(c*64)/d
h=64+(y*64)/d
circfill(g,h,max((5-d)+n,0),l[5-n])end
end
flip()goto _
