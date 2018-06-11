pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
_set_fps(60)
v={-1,-1,1,-1,-1,1,1,1}
i={2,0,1,3,1,0,2,3}
function x(y,n)a=v[i[y]*2+1]b=v[i[y]*2+2]w=a*cos(n)q=2+a*sin(n)
return 64+(99*w)/q,64+(64*-b)/q
end
::_::
cls()
for k=1,8 do
u=(k-1)/16+t()/8
for j=1,#i,2 do
c,d=x(j,u)g,h=x(j+1,u)line(c,d,g,h,11)end
end
flip()goto _
