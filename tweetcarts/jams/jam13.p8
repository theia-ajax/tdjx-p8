pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
v={}for i=0,90 do
add(v,cos(i/20))add(v,cos(i/90))add(v,sin(i/30))end
function x(y,n)a=v[y*3+1]z=v[y*3+3]w=cos(n)*a-z*sin(n)q=sin(n)*a+cos(n)*z+3return 64+64*w/q,64+64*v[y*3+2]/q
end::_::cls()f=.1*t()for j=0,#v/3-2 do
c,d=x(j,f)g,h=x(j+1,f)line(c,d,g,h,11)
end
flip()goto _
