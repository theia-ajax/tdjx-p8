pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
k=circfill
::_::cls()srand()for m=0,100 do
a=t()/4
y=rnd()w=1+rnd(4)x=w*cos(y)z=w*sin(y)y=(rnd(14)+a*-9)%14-7
b=rnd()c=x*cos(a)-z*sin(a)d=7+x*sin(a)+z*cos(a)
g=64+c*64/d
h=64+y*64/d
e=max(10-d,0)k(g,h,e,10)k(g,h,e-1,12)line(g-1,h-e,g-1,h+e,10)line(g-e,h,g+e,h,10)
end
flip()goto _
