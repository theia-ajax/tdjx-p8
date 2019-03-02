pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
e=2.7183::_::cls(10)u,q,v,s=t()/16,64,64,63
for i=0,22 do
r=63-i*e
d=s-r
x=q+d*cos(u*i)y=v+d*sin(u*i)circfill(x,y,r,9+i%2)s,q,v=r,x,y
end
flip()goto _
