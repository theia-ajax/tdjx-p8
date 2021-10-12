pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
cartloadtext="adventure.p8"

function _init()
	ui_init()
	
	txtbl=nil
	actv_trn=nil
	actv_x=-1
	actv_y=-1
	loaded=false
end

function _update60()
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
	
	if txtbl then
		show_room_controls()
	end
	
	if actv_trn then
		show_tx_controls(actv_trn)
	end
end

function show_room_controls()
	for ry=0,3 do
		for rx=0,7 do
			local tx=txtbl[ry+1][rx+1]
			local col=6
			if (actv_trn==tx) col=9
			if ui_button(rx*16,ry*10+88,rx..","..ry,{bgcol=col})
			then
				actv_trn=tx
				actv_x=rx
				actv_y=ry
			end
		end
	end
end

function show_tx_controls(tx)
	local ox=71
	local oy=20
	
	tx.cart=number_control("cart id:",tx.cart,ox,oy,0,7)
	tx.rx=number_control("room x:",tx.rx,ox,oy+8,0,7)
	tx.ry=number_control("room y:",tx.ry,ox,oy+16,0,3)
	tx.tx=number_control("tile x:",tx.tx,ox,oy+24,0,15)
	tx.ty=number_control("tile y:",tx.ty,ox,oy+32,0,15)
	
	write_tx_table(txtbl)

	if (changed) write_tx_table(txtbl)
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
		draw_table_view(0,24)
	end
	
	ui_flush()
	
	if txtbl and btn(5) then
		rectfill(0,0,127,127,0)
		local i=0
--[[		print("rows:"..#txtbl,0,0,7)
		for y=1,#txtbl do
			print("row "..y..":"..#txtbl[y],0,y*6,7)
		end]]
		for y=1,4 do
			for x=1,8 do
				local col=7
				if (actv_x==x-1 and actv_y==y-1) col=10
				local tx=txtbl[y][x]
				print(x..","..y..":"..tx.cart..tx.rx..tx.ry..hex(tx.tx)..hex(tx.ty),flr(i/16)*64,(i%16)*6,col)
				i+=1
			end
		end
	end
	

	if btn(4) then
		palt(0,false)
		sspr(0,0,128,128,0,0,128,128)
		palt()
	end
	
	circ(mx(),my(),1,7)
end

function draw_table_view(vx,vy)
	rect(vx,vy,vx+65,vy+33,7)
	palt(0,false)
	sspr(112,56,16,8,vx+1,vy+1,64,32)
	palt()
	
	if actv_trn then
		local col=actv_x%4*2
		local row=actv_y*2+flr(actv_x/4)
		local xx=vx+col*8
		local yy=vy+row*4
		rect(xx,yy,xx+17,yy+5,10)
	end
end

function number_control(label,val,x,y,mn,mx)
	local v=val
	ui_label(x,y+2,label)
	local bx=33+x
	local vs=tostr(val)
	ui_label(bx+10-(#vs-1)*2,y+2,vs)
	if ui_button(bx,y,"-",{nobdr=true}) then
		v-=1
	end	
	if ui_button(bx+16,y,"+",{nobdr=true}) then
		v+=1
	end
	if (v<mn) v=mx
	if (v>mx) v=mn
	return v
end

_hex_table={
	"0","1","2","3",
	"4","5","6","7",
	"8","9","a","b",
	"c","d","e","f"
}

function hex(val)
	return _hex_table[val+1]
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
			_ui_draw_label,
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
k_ui_etype_label=3

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
		bgcol=props.bgcol or 6,
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

function ui_label(x,y,text,props)
	props=props or {}
	col=props.col or 7
	w=props.w or #text*4
	h=props.h or 6
	
	ui_push({
		etype=k_ui_etype_label,
		x=x,y=y,w=w,h=h,text=text,
		col=col
	})
end

function _ui_draw_button(ui)
	local c1,c2,c3,c4=7,5,ui.bgcol,0
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

function _ui_draw_label(ui)
	print(ui.text,ui.x,ui.y,ui.col)
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
-- cart transition tables

-- encodes transition
-- cart: cartid 0-7
-- room coordinates on map
--	each room is 1 16x16 screen
-- rx:		 room x 0-7
-- ry:			room y 0-3
-- tile to place player in room
-- tx:			tile x 0-15
-- ty:			tile y 0-15
-- encoded into two bytes
function encode_tx(cart,rx,ry,tx,ty)
	-- byte 1
	-- bits 0-2: cart id
	--	bits 3-5: room x
	--	bits 6-7: room y
	-- 
	-- byte 2
	-- bits 0-3: tile y
	-- bits 4-7: tile x

	cart=band(cart,0x7)
	rx=band(rx,0x7)
	ry=band(ry,0x3)
	
	tx=band(tx,0xf)
	ty=band(ty,0xf)
	
	-- cart << 5 + rx << 3 + ry,
	-- ty << 4 + tx
	return bor(
			bor(shl(cart,5),
				shl(rx,2)),
			ry),
		bor(shl(ty,4),tx)
end

-- rb: room byte (cart, room xy)
-- tb: tile byte (tile xy)
function decode_tx(rb,tb)
	return {
		cart=shr(band(rb,0xe0),5),
		rx=shr(band(rb,0x1c),2),
		ry=band(rb,0x3),
		tx=band(tb,0x0f),
		ty=shr(band(tb,0xf0),4),
	}
end

_txtbl_off=0x0e38

-- rx: 0-7
-- ry: 0-3
function tx_room_addr(rx,ry)
	local row=ry*2+flr(rx/4)
	return _txtbl_off+
		(ry*2+flr(rx/4))*64+	-- row
		(rx%4)*2													-- col
end

-- txtbl, array of 32 elements
-- each element should include:
-- 	cart: cart id (0-7),
--		rx: room x (0-7),
--		ry: room y (0-3),
--		tx: tile x (0-15),
--		ty: tile y (0-15)
function write_tx_table(txtbl)
	for y=0,3 do
		local row=txtbl[y+1]
		for x=0,7 do
			local trn=row[x+1]
			local b1,b2=encode_tx(
				trn.cart,trn.rx,trn.ry,trn.tx,trn.ty)
			local addr=tx_room_addr(x,y)
			poke(addr,b1)
			poke(addr+1,b2)
		end
	end
end

function read_tx_table()
	local ret={}
	for y=0,3 do
		local row=add(ret,{})
		for x=0,7 do
			local addr=tx_room_addr(x,y)
			local tx=decode_tx(
				peek(addr),
				peek(addr+1))
			add(row,tx)
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
						tx.tx,tx.ty=xx,yy
					end
				end
			end
		end
	end
	
	return ret
end
