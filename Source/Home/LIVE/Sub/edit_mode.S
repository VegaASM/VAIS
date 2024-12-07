/*NOTE I see no reason to have price/qty checks & warnings in edit mode*/

edit_mode_title_msg:
.ascii "\x1B[2J\x1B[HEDIT MODE\n\nESC. Exit Edit Mode\n2. Go down one Record\n8. Go back up one Record\nBackspace. Delete Record\nTab. Edit Record\n\n"

edit_mode_draft_string:
.asciz "Selected Record~\nArea: %s, Loc: %s, Cat: %s, %10.2f x %13f, Rec Num: %u\n"

edit_mode_delete_confirmation_msg:
.asciz "\x1B[2J\x1B[HAre you sure you want to delete record number %u?\n"
edit_mode_delete_confirmation_msg_unk_bug_fix: /*For whatever reason I cant do more print shit after above line, gotta make 2 lines and back to back printf...huh?*/
.asciz "7. Yes\n8/ESC. No, Go back to Edit Mode menu."

edit_mode_disabled_msg:
.asciz "\x1B[2J\x1B[HNothing to edit! No valid records!\nPress any key to exit out of Edit Mode."

em_er_out_of_memory_msg: /*NOTE can this even happen? is it even possible TODO*/
.asciz "\x1B[2J\x1B[HERROR! You are out of memory for more Inventory entries.\nPress any key to exit out of Edit Mode"

.data
edit_mode_edit_mode_template:
.ascii "\x1B[2J\x1B[HEDIT MODE\n\nPrice:           . "
edit_mode_edit_mode_template_price_cursor:
.ascii " <<\n  Qty:             "
edit_mode_edit_mode_template_qty_cursor:
.asciz "   \n\nPress ESC at any time to abort back to edit mode menu\n"
.text

.align 6
/*No args*/
/*non-volatile regs that are used from parent func
d31 total cost
d30 area cost
d29 local loc cost
d28 local cat cost*/
.globl edit_mode
edit_mode:
/*Prologue*/
prologue 3, 296 /*This SHOULD be enough, max is 242 i think lul*/

/*Set in_edit_mode_flag HIGH*/
mov w0, 1
str x0, [masterptr, in_editmode_flag]

/*Register alias's*/
editmode_upperbound_ptr .req x19 /*x20 being used for a cursor the edit mode within edit mode*/
copy_of_legit_currdataptr .req x21

/*Backup REAL non-edit-mode curdataentry_ptr*/
mov copy_of_legit_currdataptr, curdataentry_ptr

/*Set a register to point at most recent (upper) valid SAVED/WRITTEN entry (NOT empty real curr entry ptr that is going to be used*/
/*NOTE this is a linear type check. If VAIS becomes non-linear in future, FIX THIS NOTE*/
sub editmode_upperbound_ptr, curdataentry_ptr, databin_entry_size
get_most_recent_written_entry:
cmp editmode_upperbound_ptr, dataentry_ptr
blo disable_edit_mode
ldrb w0, [editmode_upperbound_ptr, d_vflag]
cbnz w0, make_new_currdataentry_ptr
sub editmode_upperbound_ptr, editmode_upperbound_ptr, databin_entry_size
b get_most_recent_written_entry

/*Now make the upper bound ptr register be the NEW curdataentry_ptr*/
make_new_currdataentry_ptr:
mov curdataentry_ptr, editmode_upperbound_ptr

/*Printf the string*/
_start_edit_mode:
add x0, sp, 0x10
adr x1, edit_mode_title_msg
add x2, curdataentry_ptr, d_area
add x3, curdataentry_ptr, d_loc
add x4, curdataentry_ptr, d_cat
ldr x5, [curdataentry_ptr, d_record]
ldr d0, [curdataentry_ptr, d_price]
ldr d1, [curdataentry_ptr, d_qty]
bl sprintf

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
strh w2, [x1, 1] /*Must store the null byte*/
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
ldr x1, [curdataentry_ptr, d_record]
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
strb wzr, [curdataentry_ptr, d_vflag]
/*update live inventory cost float totals
d31 allinv, d30 area, d29 local loc, d28 local cat*/
ldr d0, [curdataentry_ptr, d_cost]
/*Load enable/disable flags*/
ldrb w11, [invbin_ptr, arealoccatflags]
/*Update inv total no matter what ofc*/
fsub d31, d31, d0
/*Is Area enabled?*/
tbz w11, 2, 0x18
/*Does record area match current area in inv.bin? If so subtract shit*/
ldr x0, [curdataentry_ptr, d_area]
ldr x1, [invbin_ptr, area]
cmp x0, x1
bne edit_mode_deleted_record_check
fsub d30, d30, d0
/*Is Loc enabled?*/
tbz w11, 1, 0x18
/*Does record for local loc match current loc in inv.bin? If so subtract shit*/
ldr x0, [curdataentry_ptr, d_loc]
ldr x1, [invbin_ptr, loc]
cmp x0, x1
bne edit_mode_deleted_record_check
fsub d29, d29, d0
/*Is Cat enabled?*/
tbz w11, 0, 0x18
/*Does record for local cat match current cat in inv.bin? If so subtract shit*/
ldr x0, [curdataentry_ptr, d_cat]
ldr x1, [invbin_ptr, cat]
cmp x0, x1
bne edit_mode_deleted_record_check
fsub d28, d28, d0
/*Now actually delete the record from the CSV*/
mov x0, curdataentry_ptr
bl delete_csv_line
/*Was record deleted the one you were currently on (aka Upperbound ptr)?, if so move down record to next valid one*/
edit_mode_deleted_record_check:
cmp curdataentry_ptr, editmode_upperbound_ptr
bne make_new_currdataentry_ptr /*Make edit mode re-display newest/latest record*/
/*It is, so let's move down to closest below valid record, stop if we run out of records*/
edit_mode_deleted_record_check_loop:
sub curdataentry_ptr, curdataentry_ptr, databin_entry_size
cmp curdataentry_ptr, dataentry_ptr
blo edit_mode_disabled_msg /*If branch taken, then we there's 0 records to show for edit mode*/
ldrb w1, [curdataentry_ptr, d_vflag]
cbz w1, edit_mode_deleted_record_check_loop
/*Okay, closest below valid record found, re-update editmode's upperbound ptr*/
mov editmode_upperbound_ptr, curdataentry_ptr
b _start_edit_mode

//========================

em_edit_record:
/*place price cursor in x20 and NOTE we actually don't need a register to hold the qty cursor statically, nice!*/
adr x20, edit_mode_edit_mode_template_price_cursor

print_edit_record:
adr x0, edit_mode_edit_mode_template
ldr x1, [curdataentry_ptr, d_record]
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
b _start_edit_mode

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

em_down_record:
mov x0, curdataentry_ptr
em_down_record_loop:
sub x0, x0, databin_entry_size
cmp x0, dataentry_ptr /*Compare editmode's current dataentry ptr to start dataentry ptr, must be equal or higher*/
bhs em_move_down_record
bl beep
b edit_mode_title_idle_loop /*Don't change curdataentry_ptr since we can't move down*/
/*Move down in record entry to most recent valid*/
em_move_down_record:
ldrb w1, [x0, d_vflag]
cbz w1, em_down_record_loop
/*Got the record, make this the new curdataentry_ptr & reprint screen*/
mov curdataentry_ptr, x0
b _start_edit_mode

//========================

em_up_record:
mov x0, curdataentry_ptr
em_up_record_loop:
add x0, x0, databin_entry_size
cmp x0, editmode_upperbound_ptr /*Compare edit mode's current dataentry ptr to the set upperbound ptr. Must be equal or lower*/
bls em_move_up_record
bl beep
b edit_mode_title_idle_loop /*Don't change curdataentry_ptr since we can't move up*/
/*Move up in record entry to most recent valid*/
em_move_up_record:
ldrb w1, [x0, d_vflag]
cbz w1, em_up_record_loop
/*Got the record, make this the new curdataentry_ptr & reprint screen*/
mov curdataentry_ptr, x0
b _start_edit_mode

//=============

/*main epilogue*/
edit_mode_epilogue:
/*Restore "OG" aka legit curdataentry_ptr*/
mov curdataentry_ptr, copy_of_legit_currdataptr
/*Set in_edit_mode_flag LOW*/
str xzr, [masterptr, in_editmode_flag]
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
bl beep
bl keyboard_input
cbz w0, -4
b edit_mode_epilogue
