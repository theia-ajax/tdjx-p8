pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
k=64::_::cls(0)srand()for j=0,99 do
s=0.1x=2*((sin(t()/4)+flr(rnd(64))/8-2)%4-2)y=(t()+flr(rnd(64))/8-2)%4-2
for i=16,flr(rnd(7))+1,-1 do
a=x-s
b=y-s
c=x+s
d=y+s
z=i/k+1
a=a/z*k+k
b=b/z*k+k
c=c/z*k+k
d=d/z*k+k
rectfill(a,b,c,d,11)end
end
flip()goto _
