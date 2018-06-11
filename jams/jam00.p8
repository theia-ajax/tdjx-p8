pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
::_::cls(2)a=-t()z=cos(a)w=sin(a)s=10+18*(sin(t()/15+.25)+1)b=63
for i=1,1000,s do
x=i/10*cos(a+i/100)y=i/10*sin(a+i/100)line(z+b,w+b,x+b,y+b,1)line(-z+b,-w+b,-x+b,-y+b,1)z=x
w=y
end
flip()goto _
