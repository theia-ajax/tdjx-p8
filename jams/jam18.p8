pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
l={12,6,2,1,2,6,12}
::_::
cls(15)
srand()
x=54+rnd(20)
for y=0,127 do
	i=flr((sin(y/64+t()/2)+1)/2*#l)
	c=l[i+1]
	w=x-20+sin(y/(rnd(2)+28))*4
	q=x+20+sin(y/(28+rnd(2)))*4
	line(w+15,y,q+15,y,0)
	line(w,y,q,y,c)
	x+=sin(y/30+t())*rnd()*2
end
flip()goto _
