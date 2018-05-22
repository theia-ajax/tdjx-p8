pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
t=0
function _draw()
 cls()
 t+=2
 for c=1,8 do
  for i=1,28 do
   th=cos((t-i+c*2)/360)*.125+.75
   ii=i*6
   x=cos(th)*ii+63
   y=sin(th)*ii
   cl=c+7; if (cl==15) cl=7
   circfill(x,y,2,cl)
  end
 end
end
