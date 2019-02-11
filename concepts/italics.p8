pico-8 cartridge // http://www.pico-8.com
version 16
__lua__


function _init()
	cls()
	
	ch_str="abcdefghijklmnopqrstuvwxyz0123456789!?.,';"
	ch_vals={}
	ch_len=#ch_str
	ch_per_line=128/4

	for i=1,ch_len do
		local ch=sub(ch_str,i,i)
		ch_vals[i-1]=ch
		ch_vals[ch]=i-1
	end
	
	local head=0
	while head<ch_len do
		local str=""
		local tail=head
		while tail<head+ch_per_line
			and tail<ch_len
		do
			str=str..ch_vals[tail]
			tail+=1
		end
		?str
		head+=ch_per_line
	end
	
	memcpy(0x0,0x6000,12*64)
end

function _update()
end

function _draw()
	cls()
	sspr(0,0,128,128,0,0,128,128)
end
-->8
function ch_scoord(ch)
	assert(type(ch)=="string")
	
	local v=ch_vals[ch]
	local row=flr(v/ch_per_line)
	local col=v%ch_per_line
	
	return row*6,col*4
end

function ch_print(str,x,y,col,style)
	local style=style or {}
	local italics=style.italics or false
end
