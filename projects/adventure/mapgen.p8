pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
cartloadtext="adventure.p8"

function _init()
	ui_init()
	--reload(0x0000,0x0000,0x2000,"adventure.p8")
	
	txtbl=nil
	loaded=false
end

function _update()
	ui_update()

	if ui_keyboard_focused() then
		if (band(btn(),64)!=0) poke(0x5f30,1)
	end

	cartloadtext=
		ui_text(cartloadtext,0,0,97,8)
	
	if ui_button(98,0,"load",{off=loaded}) then
		load_cart_data(cartloadtext)
	end
	
	if ui_button(117,0,"⧗",{w=10}) then
		run()
	end
	
	if ui_button(98,9,"save",{w=29,off=not txtbl}) then
		write_tx_table(txtbl)
	end
	
	if txtbl then
		show_tx_controls()
	end
end

function show_tx_controls()
	local i=1
	for ry=0,3 do
		for rx=0,7 do
			local ox=rx*16
			local oy=ry*18+56
			local tx=txtbl[ry+1][rx+1]
//				rectfill(ox,oy,ox+15,oy+15,0)
//				rect(ox,oy,ox+15,oy+15,7)
			--print(tx.cart,ox,oy,7)
			local changed=false
			if ui_button(ox+5,oy,tostr(tx.cart),
				{nobdr=true})
			then
				tx.cart+=1
				if (tx.cart>7) tx.cart=0
				changed=true
			end
			if ui_button(ox+2,oy+8,tostr(tx.rx),
				{nobdr=true})
			then
				tx.rx+=1
				if (tx.rx>7) tx.rx=0
				changed=true
			end
			if ui_button(ox+8,oy+8,tostr(tx.ry),
				{nobdr=true})
			then
				tx.ry+=1
				if (tx.ry>3) tx.ry=0
				changed=true
			end
			
			if (changed) write_tx_table(txtbl)
			i+=1
		end
	end
end

function load_cart_data(cart)
	reload(0x0,0x0,0x1000,cart)
	txtbl=read_tx_table()
end

function _draw()
	cls()
	fillp(0xedb7)
	rectfill(0,0,127,127,1)
	fillp()
	
	if txtbl then
		vx,vy=48,12
		rect(vx,vy,vx+33,vy+33,7)
		palt(0,false)
		sspr(120,56,8,8,vx+1,vy+1,32,32)
		palt()
	
		rectfill(0,56,127,127,0)
		rect(0,55,127,127,7)
		for x=1,7 do
			line(x*16,56,x*16,127,7)
		end
		for y=1,3 do
			line(0,y*18+55,127,y*18+55,7)
		end
	end
	
	ui_flush()
	
	circ(mx(),my(),1,7)
end

-->8
function ui_init()
	poke(0x5f2d,1)
	_ui={
		mx=0,my=0,mb=0,
		lastmx=0,lastmy=0,lastmb=0,
		elemid=0,
		currelem=-1,
		drawtbl={
			_ui_draw_button,
			_ui_draw_text,
		},
	}
end

function ui_update()
	_ui.elemid=0
	
	_ui.lastmx=_ui.mx
	_ui.lastmy=_ui.my
	_ui.lastmb=_ui.mb
	_ui.mx=stat(32)
	_ui.my=stat(33)
	_ui.mb=stat(34)
end

k_ui_etype_button=1
k_ui_etype_text=2

_ui_queue={}

function ui_push(ui)
	ui.id=_ui.elemid
	_ui.elemid+=1
	add(_ui_queue,ui)
end

function ui_flush()
	for _,ui in pairs(_ui_queue) do
		_ui.drawtbl[ui.etype](ui)
	end
	
	_ui_queue={}
end

function mouse_hover(x,y,w,h)
	return mx()>=x and
		mx()<=x+w and
		my()>=y and
		my()<=y+h
end

function ui_button(x,y,text,props)
	props=props or {}
	local w=props.w or #text*4+2
	local h=props.h or 8
	local off=props.off or false

	local hover=mouse_hover(x,y,w,h)
	
	local state=0
	if (ui_selected()) state=1
	local ret=false
	
	if not off then
 	if hover and mbd(0) and _ui.currelem<0 then
 		ui_select()
 		state=1
 	elseif mbr(0) and ui_selected() then
 		ui_deselect()
 		if (hover) ret=true
 	end
 else
 	state=2
 end
	
	ui_push({
		etype=k_ui_etype_button,
		x=x,y=y,w=w,h=h,
		text=text,state=state,
		nobdr=props.nobdr or false,
	})
	
	return ret	
end

function ui_text(text,x,y,w,h,props)
	props=props or {}
	w=w or 32
	h=h or 6
	bdrcol=props.bdrcol or 5
	hlcol=props.hlcol or 9
	
	local hover=mouse_hover(x,y,w,h)
	
	local state=0
	if (ui_selected()) state=1
	local ret=text
	
	if hover and mbd(0) and _ui.currelem<0 then
		ui_select()
		state=1
	elseif not hover and mbd(0) and ui_selected() then
		ui_deselect()
	end
	
	if ui_selected() and stat(30) then
		local key=stat(31)
		if key=="\b" then
			if #text>0 then
				text=sub(text,0,#text-1)
			end
		elseif key=="\r" then
			poke(0x5f30,1)
			ui_deselect()
		else
			text=text..key
		end
	end
	
	ui_push({
		etype=k_ui_etype_text,
		x=x,y=y,w=w,h=h,
		text=text,state=state,
		bdrcol=bdrcol,
		hlcol=hlcol,
	})
	
	return text
end

function _ui_draw_button(ui)
	local c1,c2,c3,c4=7,5,6,0
	if ui.state==1 then
		c1,c2,c3,c4=5,7,13,12
	elseif ui.state==2 then
		c1,c2,c3,c4=7,5,13,5
	end
	if not ui.nobdr then
 	rect(ui.x,ui.y,
 		ui.x+ui.w,ui.y+ui.h,
 		c1)
 	rect(ui.x+1,ui.y+1,
 		ui.x+ui.w,ui.y+ui.h,
 		c2)
	end
	rectfill(ui.x+1,ui.y+1,
		ui.x+ui.w-1,ui.y+ui.h-1,
		c3)
	print(ui.text,ui.x+2,ui.y+2,c4)
end

function _ui_draw_text(ui)
	local bdr=ui.bdrcol
	if (ui_selected(ui.id)) bdr=ui.hlcol
	rectfill(ui.x,ui.y,ui.x+ui.w,ui.y+ui.h,0)
	rect(ui.x,ui.y,ui.x+ui.w,ui.y+ui.h,bdr)
	local t=ui.text
	local maxch=(ui.w-2)/4+1
	if #t>maxch then
		t=sub(t,0,maxch)
	end
	local ty=ui.y+ui.h/2-2
	print(t,ui.x+2,ty,7)
	if ui_selected(ui.id) then
		-- draw cursor
		local cx=#ui.text*4+ui.x+2
		if cx<ui.x+ui.w then
			rectfill(cx,ty,cx+3,ty+4,9)
		end
	end
end

function ui_keyboard_focused()
	return _ui.currelem>=0
end

-- button
--		0: left
--  1: right
--  2: middle
function mb(button)
	return band(_ui.mb,shl(1,button))~=0
end
function lastmb(button)
	return band(_ui.lastmb,shl(1,button))~=0
end

function mbd(button)
	return mb(button) and not lastmb(button)
end

function mbr(button)
	return not mb(button) and lastmb(button)
end

function mx() return _ui.mx end
function my() return _ui.my end

function ui_select(id)
	-- flush keypress queue
	while stat(30) do stat(31) end

	id=id or _ui.elemid
	_ui.currelem=id
end

function ui_deselect(id)
	id=id or _ui.currelem
	if _ui.currelem==id	then
		_ui.currelem=-1
	end
end

function ui_selected(id)
	return _ui.currelem==(id or _ui.elemid)
end

-->8
function encode_tx(cart,rx,ry)
	-- 8 bits
	-- 0-2: cart id (3 bits)
	--	3-5: room x  (3 bits)
	--	6-7: room y  (2 bits)

	cart=band(cart,0x7)
	rx=band(rx,0x7)
	ry=band(ry,0x3)
	
	-- cart << 5 + rx << 3 + ry
	return bor(
		bor(shl(cart,5),shl(rx,2)),
		ry)
end

function decode_tx(tx)
	return shr(band(tx,0xe0),5),
		shr(band(tx,0x1c),2),
		band(tx,0x3)	
end

_txtbl_off=0x0e3c

-- rx: 0-7
-- ry: 0-3
function tx_room_addr(rx,ry)
	local row=ry*2
	if (rx>3) row+=1
	return _txtbl_off+row*64+rx%4
end

-- txtbl, array of 32 elements
-- each element should include:
-- cart id (0-7), room x (0-7), room y (0-3)
function write_tx_table(txtbl)
	for y=0,3 do
		local row=txtbl[y+1]
		for x=0,7 do
			local tx=row[x+1]
			local val=encode_tx(
				tx.cart,tx.rx,tx.ry)
			local addr=tx_room_addr(x,y)
			poke(addr,val)
		end
	end
end

function read_tx_table()
	local ret={}
	for y=0,3 do
		local row=add(ret,{})
		for x=0,7 do
			local tx=add(row,{})
			local addr=tx_room_addr(x,y)
			tx.cart,tx.rx,tx.ry=
				decode_tx(peek(addr))
		end
	end
	return ret
end

function build_tx_table()
	local ret={}

	for ry=0,3 do
		local row=add(ret,{})
		for rx=0,7 do
			local tx=add(row,{
					cart=0,rx=0,ry=0
				})
			for xx=rx*16,rx*16+15 do
				for yy=ry*16,ry*16+15 do
					local m=mget(xx,yy)
					if fget(m,7) then
						tx.rx,tx.ry=rx,ry
					end
				end
			end
		end
	end
	
	return ret
end
