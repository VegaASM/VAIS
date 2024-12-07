/*NOTE I see no reason to have price/qty checks & warnings in edit mode*/

edit_mode_title_msg:
.ascii "\x1B[2J\x1B[HEDIT MODE\n\nESC. Exit Edit Mode\n2. Go down one Record\n8. Go back up one Record\nBackspace. Delete Record\nTab. Edit Record\n\n"

edit_mode_draft_string:
.asciz "Selected Record~\nArea: %s, Loc: %s, Cat: %s, %10.2f x %13f, Rec Num: %u\n"

edit_mode_delete_confirmation_msg:
.asciz "\x1B[2J\x1B[HAre you sure you want to delete record number %u?\n"
edit_mode_delete_confirmation_msg_unk_bug_fix: //For whatever reason I cant do more print shit after above line, gotta make 2 lines and back to back printf...huh?
.asciz "7. Yes\n8/ESC. No, Go back to edit mode menu."

edit_mode_disabled_msg:
.asciz "\x1B[2J\x1B[HNothing to edit! No valid records! Press any key to exit."

em_er_out_of_memory_msg: /*NOTE can this even happen? is it even possible TODO*/
.asciz "\x1B[2J\x1B[HERROR! You are out of memory for more Inventory entries. Press any key to escape out of Edit Mode"

.data
edit_mode_edit_mode_template:
.ascii "\x1B[2J\x1B[HEDIT MODE\n\nPrice:           . "
edit_mode_edit_mode_template_price_cursor:
.ascii " <<\n  Qty:             "
edit_mode_edit_mode_template_qty_cursor:
.asciz "   \n\nPress ESC at any time to abort back to edit mode menu\n"
.text

/*TODO negative signage implementation*/
.align 6
/*No args*/
/*non-volatile regs that are used from parent func
d31 = total cost
d30 = area cost
d29 = local loc cost
d28 = local cat cost*/
.globl edit_mode
edit_mode:
/*Prologue*/
prologue 3, 296 //This SHOULD be enough, max is 242 i think lul

/*Set in_edit_mode_flag HIGH*/
mov x0, 1
str x0, [masterptr, in_editmode_flag]

/*See if record count is 0*/
cbz recordnum, disable_edit_mode

/*Set a register to point at most recent SAVED/WRITTEN entry (curdataentry_ptr - databin_entrysize*/
sub x21, curdataentry_ptr, databin_entry_size

/*Find record that matches recordnum*/
mov x19, dataentry_ptr
mov x1, entriesamt
/*Load record, see if its valid*/
edit_mode_find_default_display_record:
ldr x0, [x19, d_record]
cmp x0, recordnum
beq em_check_rec_valid
/*Record not found yet, increment*/
add x19, x19, databin_entry_size
subs x1, x1, 1
bne edit_mode_find_default_display_record
/*Latest record(s), not valid, we now need to go backwards, and simply grab most recent valid record regardless of recordnum!*/
em_go_backwards_lol:
mov x1, entriesamt
sub x19, x19, databin_entry_size
ldrb w0, [x19, d_vflag]
cbnz w0, _start_edit_mode
subs x1, x1, 1
bne -0x10
/*Only can be reached here is all inventory entries are invalid (deleted)*/
b disable_edit_mode
/*make sure record is valid*/
em_check_rec_valid:
ldrb w0, [x19, d_vflag]
cbz w0, em_go_backwards_lol

/*Printf the string*/
_start_edit_mode:
add x0, sp, 0x10
adr x1, edit_mode_title_msg
add x2, x19, d_area
add x3, x19, d_loc
add x4, x19, d_cat
ldr x5, [x19, d_record]
ldr d0, [x19, d_price]
ldr d1, [x19, d_qty]
bl sprintf /*TODO should we check this? lol*/

/*Remove all double spaces*/
add x0, sp, 0xF
add x1, sp, 0xF
edit_mode_remove_dub_spaces_loop:
ldrh w2, [x0, 1]!
/*Check for null byte ender*/
tst w2, 0xFF00
beq edit_mode_print_title_msg
mov w3, 0x2020
cmp w2, w3
beq edit_mode_remove_dub_spaces_loop
strh w2, [x1, 1]!
b edit_mode_remove_dub_spaces_loop

/*Finally print this!*/
edit_mode_print_title_msg:
strh w2, [x1, 1]
add x0, sp, 0x10
bl puts

/*poll keyboard and read inputs*/
edit_mode_title_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq edit_mode_epilogue
cmp w0, DELETE
beq em_delete_record
cmp w0, ascii_tab
beq em_edit_record
cmp w0, ascii_2
beq em_down_record
cmp w0, ascii_8
beq em_up_record
edit_mode_beep:
bl beep
b edit_mode_title_idle_loop

//=================================

em_delete_record:
/*Print the stuff*/
adr x0, edit_mode_delete_confirmation_msg
ldr x1, [x19, d_record]
bl printf
adr x0, edit_mode_delete_confirmation_msg_unk_bug_fix
bl puts
delete_record_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq _start_edit_mode
cmp w0, ascii_8
beq _start_edit_mode
cmp w0, ascii_7
beq yes_delete_record
bl beep
b delete_record_idle_loop
/*delete record*/
yes_delete_record:
mov w0, 0
strb w0, [x19, d_vflag]
/*update live inventory cost float totals
d31 allinv, d30 area, d29 local loc, d28 local cat*/
ldr d0, [x19, d_cost]
/*Load enable/disable flags*/
ldrb w11, [invbin_ptr, arealoccatflags]
/*Update inv total no matter what ofc*/
fsub d31, d31, d0
/*Is Area enabled?*/
tbz w11, 2, 0x18
/*Does record area match current area in inv.bin? If so subtract shit*/
ldr x0, [x19, d_area]
ldr x1, [invbin_ptr, area]
cmp x0, x1
bne edit_mode_deleted_record_check
fsub d30, d30, d0
/*Is Loc enabled?*/
tbz w11, 1, 0x18
/*Does record for local loc match current loc in inv.bin? If so subtract shit*/
ldr x0, [x19, d_loc]
ldr x1, [invbin_ptr, loc]
cmp x0, x1
bne edit_mode_deleted_record_check
fsub d29, d29, d0
/*Is Cat enabled?*/
tbz w11, 0, 0x18
/*Does record for local cat match current cat in inv.bin? If so subtract shit*/
ldr x0, [x19, d_cat]
ldr x1, [invbin_ptr, cat]
cmp x0, x1
bne edit_mode_deleted_record_check
fsub d28, d28, d0
/*Now actually delete the record from the CSV*/
mov x0, x19
bl delete_csv_line
/*Was record deleted the one you were currently on?, if so move down record to next valid one
and decrement recordnum non-vol register*/
edit_mode_deleted_record_check:
cmp x19, curdataentry_ptr
bne edit_mode_epilogue
/*Now when we move down, do we run out of records?*/
sub x0, curdataentry_ptr, databin_entry_size
cmp x0, dataentry_ptr
bhs edit_mode_epilogue
/*Reset curdataentry_ptr*/
mov curdataentry_ptr, dataentry_ptr
b edit_mode_epilogue

//========================

em_edit_record:
/*place price cursor in x20 and NOTE we actually don't need a register to hold the qty cursor statically, nice!*/
adr x20, edit_mode_edit_mode_template_price_cursor

print_edit_record:
adr x0, edit_mode_edit_mode_template
ldr x1, [x19, d_record]
bl printf
edit_record_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq em_er_esc_hit
cmp w0, ascii_dot
beq em_er_dot_hit
cmp w0, DELETE
beq em_er_del_hit
cmp w0, ascii_plus
beq em_er_tab_hit
cmp w0, ascii_enter
beq em_er_enter_hit
cmp w0, ascii_mulli
beq em_er_mulli_hit
cmp w0, ascii_dash
beq em_er_sub_hit
cmp w0, ascii_slash
beq em_er_div_hit
cmp w0, ascii_0
blo em_er_beep
cmp w0, ascii_9
bls em_er_insert_char
em_er_beep:
bl beep
b edit_record_idle_loop

em_er_esc_hit:
mov x0, x20
bl inv_esc_func
mov x20, x0
cbnz x0, print_edit_record
b edit_mode_epilogue

em_er_insert_char:
mov x1, x20 //w0 already set
bl inv_insert_char
cbz x0, print_edit_record
b edit_record_idle_loop

em_er_del_hit:
mov x0, x20
bl inv_erase_char
cbz x0, print_edit_record
b edit_record_idle_loop

em_er_dot_hit:
mov x0, x20
bl inv_insert_dot
cbz x0, print_edit_record
b edit_record_idle_loop

em_er_tab_hit:
sub x0, x20, (FIELD_MAX-1) //CURRENT field FIRST char ptr
adr x1, edit_mode_edit_mode_template_price_cursor-12 //price field first char ptr
bl tab_func
cbz x0, em_er_out_of_memory
mov x20, x0
b print_edit_record

em_er_enter_hit:
sub x0, x20, (FIELD_MAX-1) //arg requires we must point to FIRST char of field, NOT last
mov w1, ascii_plus
bl symbol_func
b print_edit_record

em_er_mulli_hit:
sub x0, x20, (FIELD_MAX-1) //arg requires we must point to FIRST char of field, NOT last
mov w1, ascii_mulli
bl symbol_func
b print_edit_record

em_er_sub_hit:
sub x0, x20, (FIELD_MAX-1) //arg requires we must point to FIRST char of field, NOT last
mov w1, ascii_dash
bl symbol_func
b print_edit_record

em_er_div_hit:
sub x0, x20, (FIELD_MAX-1) //arg requires we must point to FIRST char of field, NOT last
mov w1, ascii_slash
bl symbol_func
b print_edit_record


//========================

/*NOTE NOTE NOTE OKAY figure out issue! when we move up and there are deleted records above, the x19 will keep going too high (above rec 3), then beep but the x19 stays too high, then when we move down were tech at rec 6, then once we reach 3, we show it even though we are already showing, thus resuling in a total of two downs to decrement. The opposite SHOULD NOT occur because x25 , datastartentry ptr is HARDCODED

how to fix..... somehow save og 19 and place into yet another hardcoded shit

NOTE afaik this will NOT cause any EXceptions! just a small non-material bug

01-02
125 1
250 2
577 5
01-09
700 1
822 4
.56 10
then del rec 2, go to change mode del Loc 9, go into edit mode, we see the non-material bug

*/

em_down_record:
sub x0, x19, databin_entry_size
cmp x0, dataentry_ptr //Compare editmode's dataentry ptr to start dataentry ptr, must be equal or higher
bhs 0xC
bl beep
b edit_mode_title_idle_loop
/*Move down in record entry to most recent valid*/
sub x19, x19, databin_entry_size
ldrb w1, [x19, d_vflag] //Don't do direct load (exclude sub) just incase vflag offset in future gets changed
cbz w1, em_down_record
/*Got the record, make this the new curdataentry_ptr print it*/
mov curdataentry_ptr, x0
b _start_edit_mode

//========================

em_up_record:
add x0, x19, databin_entry_size
cmp x0, x21 //Compare edit mode's current dataentry ptr to real/OG current dataentry ptr, must be equal or lower
bls 0xC
bl beep
b edit_mode_title_idle_loop
/*Move up in record entry to most recent valid*/
add x19, x19, databin_entry_size
ldrb w1, [x19, d_vflag] //Don't do direct load (exclude sub) just incase vflag offset in future gets changed
cbz w1, em_up_record
/*Got the record, make this the new curdataentry_ptr print it*/
mov curdataentry_ptr, x0
b _start_edit_mode

//=============

/*main epilogue*/
edit_mode_epilogue:
/*Restore "OG" curdataentry_ptr*/
add curdataentry_ptr, x21, databin_entry_size
/*Set in_edit_mode_flag LOW*/
str xzr, [masterptr, in_editmode_flag]
/*useless return code for now*/
mov w0, 0
epilogue 3, 296

disable_edit_mode:
adr x0, edit_mode_disabled_msg
bl puts
bl beep
bl keyboard_input
cbz w0, -4
b edit_mode_epilogue

//=============

em_er_out_of_memory:
adr x0, em_er_out_of_memory_msg
bl puts
bl keyboard_input
cbz w0, -4
b edit_mode_epilogue
