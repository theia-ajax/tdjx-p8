pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
r=rnd
s=srand
l=line
c=circfill::_::cls(1)s()for i=0,128,16 do
s(i)h=r(127)v=90+r(10)w=r(8)
for j=0,127 do
x=i+13*sin(t()-j/64+w)y=(h+t()*v-j+v)%128
z=1+4*(sin(t()+j/64)+1)l(x-z,y,x+z,y,3)l(x-z-z/4,y,x-z,y,1)l(x+z+z/4,y,x+z,y,11)end
end
flip()goto _
