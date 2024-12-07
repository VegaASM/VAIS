//x0 = pointer to first slotable char ptr of field, can be price or qty
//x1 = price first char slot ptr, cuz possible func call to write_entry
//x0 = returns new updated cursor position (last char ptr)

.set temp1, 0x10 //offset relative to sp for temp1 buffer
.set temp2, 0x20 //offset relative to sp for temp2 buffer

.align 6
.globl tab_func
tab_func:
/*Prologue, save x0 and x1*/
prologue 2, 0x40 /*TODO 0x20 too much for now but when we expand fields to be 8.16, we need this space*/
mov x19, x0
mov x20, x1

/*Check if we are in price or qty field*/
ldrb w2, [x0, -3]
cmp w2, ascii_y
beq tab_func_in_qty_field
/*We are in price field, do we have NO vs A value*/
ldrb w1, [x0, (FIELD_MAX-1)]
cmp w1, ascii_space
beq tabfunc_beep
/*We have A value in price field, thus move cursor and double arrows to qty field (cursor at last char)*/
ldrh w1, [x0, FIELD_MAX]
mov w2, 0x2020
strh w2, [x0, FIELD_MAX]
add x0, x0, (FIELD_MAX+22)
strh w1, [x0, 1]
b tab_func_epilogue
/*Beep then return back same field last char ptr*/
tabfunc_beep:
bl beep
add x0, x19, (FIELD_MAX-1)
tab_func_epilogue:
epilogue 2, 0x40
//====================================

/*We are in qty field, do we have NO vs A value?*/
tab_func_in_qty_field:
ldrb w1, [x0, (FIELD_MAX-1)]
cmp w1, ascii_space
beq tabfunc_qtyfield_novalue /*temp write 1 to qty, write entry, then return price last char ptr*/
/*Ok we have A value in qty field, Is the last char a SYMBOL?*/
cmp w1, ascii_0
blo tabfunc_qtyfield_symbol_as_last_char
/*Ok we have a number & plus/mulli is NOT last char but is it anywhere else in the field?*/
mov x1, x0
mov w2, (FIELD_MAX-1) //We can omit checking last char ofc
ldrb w3, [x1], 1
cmp w3, ascii_plus
beq tabfunc_qty_to_price_transfer
cmp w3, ascii_mulli
beq tabfunc_qty_to_price_transfer
subs w2, w2, 1
bne -0x18
/*Okay we have a plain jane number in the qty field, simply write it*/
b tabfunc_write_entry_for_noncomplextransfer

/*Alright! number has symbol within we need to...*/
/*
1.Create a temp1 buffer with spaces and temp2 buffer with spaces
2.Copy post-symbol value (already right aligned) to a temp1 buffer
2.Remove symbol, and save pre symbol value to temp2 buffer
3.Space out the qty field, rewrite presymbol value to it but right aligned
4.Execute write_entry
5.Clear/space out price and qty field
6. place presymbol value into price field right aligned
7. return back price last char slot ptr.
*/
tabfunc_qty_to_price_transfer:
/*Prefill temp1 and temp2 buffers with 13 spaces each*/
add x4, sp, temp1 //Price buffer, 0x20 offset is temp2 buffer fyi
movz x6, 0x2020, lsl 48 /*TODO put this value into masterptr, spacer*/
movk x6, 0x2020, lsl 32 /*Cant use x22+ cuz its global everywhere, and x22 can be used in this func*/
movk x6, 0x2020, lsl 16
movk x6, 0x2020
str x6, [x4]
str w6, [x4, 8]
strb w6, [x4, 12]
str x6, [x4, temp1]
str w6, [x4, 8+temp1]
strb w6, [x4, 12+temp1]
/*Temp place post symbol value (new new price value w/o dot ofc) into buffer1*/
add x1, sp, temp1+(FIELD_MAX-1) //Price save buffer, Dest, temp1 buffers last char slot
add x2, x0, (FIELD_MAX-1) //Src
add x3, x0, (FIELD_MAX-1) //Make copy of Qty last char ptr for later margin calc
ldrb w4, [x2], -1
cmp w4, ascii_plus
beq hit_symbol
cmp w4, ascii_mulli /*NOTE in future, add minus and div*/
beq hit_symbol
strb w4, [x1], -1
b -0x18
hit_symbol:
/*We need...
presymbol char length*/
sub x4, x3, x2 //x4 = //symbol+postchar length
sub w5, w4, FIELD_MAX
neg w5, w5 //presymbol char length
/*Transfer presymbol chars to 2nd buffer*/
add x1, sp, temp2+(FIELD_MAX-1) //Dest, points at temp2 buffers last char slot
add x3, x0, x5 //Src, points at symbol
ldrb w4, [x3, -1]!
strb w4, [x1], -1
subs w5, w5, 1
bne -0xC
/*Now transfer whole temp2 buffer back to qty field to rewrite prechar qty value ONLY*/
add x1, sp, temp2
ldr x2, [x1]
ldr w3, [x1, 8]
ldrb w4, [x1, 12]
str x2, [x0]
str w3, [x0, 8]
strb w4, [x0, 12]
/*NOW we can finally Write entry*/
mov x0, x20
bl write_entry
cbz w0, tab_func_epilogue
/*Transfer full temp1 price buffer to price field, remember the DOT!*/
add x1, sp, temp1+(FIELD_MAX-1)
ldrh w2, [x1, -1]
ldrh w3, [x1, -3]
ldr x4, [x1, -11] //byte at offset -12 is always untransferrable space, too lazy to fix, no material effect on our code anyway
strh w2, [x20, 11] //Do NOT write over hardcoded dot!
strh w3, [x20, 8]
str x4, [x20]
/*Space out entire Qty field!*/
movz x6, 0x2020, lsl 48 /*TODO put this value into masterptr, spacer*/
movk x6, 0x2020, lsl 32 /*Cant use x22+ cuz its global everywhere, and x22 can be used in this func*/
movk x6, 0x2020, lsl 16
movk x6, 0x2020
str x6, [x19]
str w6, [x19, 8]
strb w6, [x19, 12]
/*Keep cursor and double arrows in Qty field! Return back Qty field last char ptr*/
add x0, x19, (FIELD_MAX-1) //Redundant as we can to go epilogue-4 ins address but keep it like this for easy readability
b tab_func_epilogue

/*==================================*/

/*Tabbed with NO value in Qty field
Put a temp 1 into Qty field, write the entry, return price char last slot ptr!*/
tabfunc_qtyfield_novalue:
mov w1, ascii_1
strb w1, [x0, 12]
tabfunc_write_entry_for_noncomplextransfer:
mov x0, x20
bl write_entry
cbz w0, tab_func_epilogue
/*Clear price and qty field*/
movz x0, 0x2020, lsl 48
movk x0, 0x2020, lsl 32
movk x0, 0x2020, lsl 16
movk x0, 0x2020
str x0, [x20]
strh w0, [x20, 8] //Do NOT write over hardcoded dot!
strh w0, [x20, 11]
str x0, [x19]
str w0, [x19, 8]
strb w0, [x19, 12]

/*Move double arrow from qty to price field*/
dub_arrows_transfer_to_price_field:
ldrh w1, [x19, FIELD_MAX]
mov w2, 0x2020
strh w2, [x19, FIELD_MAX]
strh w1, [x20, FIELD_MAX]
/*Return price last char ptr, NOTE x20 is always PRICE field first char ptr*/
add x0, x20, (FIELD_MAX-1)
b tab_func_epilogue

/*Okay remove the last char plus/mulli symbol, shift/align everything to the right by 1 and then call write_entry then go back to price field (last char ptr)*/
tabfunc_qtyfield_symbol_as_last_char:
ldr x1, [x0]
ldr w2, [x0, 8]
mov w3, ascii_space
str x1, [x0, 1]
str w2, [x0, 9]
strb w3, [x0]
b tabfunc_write_entry_for_noncomplextransfer
