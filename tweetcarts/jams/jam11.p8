pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
n=circfill
m=fillp
::_::f=.15*t()cls()srand()for j=1,12 do
for i=2,20 do
y=.2-i/(5)g=y*y*.3+(sin(f)+1)*.5
k=j/12
w=cos(f+k)*g-sin(f+k)*g
q=sin(f+k)*g+cos(f+k)*g+5
a=64+64*w/q
b=64+64*y/q
m()n(a,b,6-q,8+((i-2)%7))m()n(a,64-b+64,6-q,1+(i%2))end
end
flip()goto _
