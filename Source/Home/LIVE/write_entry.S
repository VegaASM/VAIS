sscanf_float_symbols:
.asciz "%lf,%lf" //sscanf and scanf must have l before f to designate double float

.align 6
/*Write entry to data.bin malloc buffer*/

/*
x0 = price1st char ptr. x0 + 23 = qty 1st char ptr
x0 returns 1 for success, 0 for out of memory*/

.globl write_entry
write_entry:
/*Prologue*/
prologue 3, 0x38
/*Get edit_mode flag in GVR and Save args*/
ldr x19, [masterptr, in_editmode_flag]
mov x20, x0 //price 1st char ptr
add x21, x0, FIELD_MAX+10 //qty 1st char ptr

/*Get end data entry ptr*/
ldr x12, [masterptr, enddataentry_ptr]

/*Check if we ran out of room for new inventory entries
NOTE should we just use record number 131,072????*/
check_room_for_new_entries:
cmp curdataentry_ptr, x12
bhi out_of_memory  //todo do the we REALLy are out of memory
/*Check if we are in edit mode*/
cbnz x19, proceed_to_write_entry_go_pass_arealoccat
/*Check if inventory entry within databin/malloc buffer is invalid (deleted) to know if we can use it ofc*/
ldrb w0, [curdataentry_ptr, d_vflag] /*I think we tehcnically dont need this cause VAIS is a linear program BUT just incase...lol*/
cbz w0, proceed_to_write_entry
/*Entry already in use, Try next entry*/
add curdataentry_ptr, curdataentry_ptr, databin_entry_size
b check_room_for_new_entries
/*Write the entry!*/
/*Transfer area loc and cat from inv.bin to data.bin only if we are calling this from LIVE*/
proceed_to_write_entry:
ldr x1, [invbin_ptr, area]
ldr x2, [invbin_ptr, loc]
ldr x3, [invbin_ptr, cat]
str x1, [curdataentry_ptr, d_area]
str x2, [curdataentry_ptr, d_loc]
str x3, [curdataentry_ptr, d_cat]
/*Put the unix time stamp, TODO what about edited records?*/
mov w0, 0
bl time
str x0, [curdataentry_ptr, d_time]
/*copy ascii price & qty to temp buffer*/
proceed_to_write_entry_go_pass_arealoccat:
add x0, sp, 0x10
ldr x3, [x20]
ldr w4, [x20, 8]
ldrb w5, [x20, 12]
ldr x6, [x21]
ldr w7, [x21, 8]
ldrb w8, [x21, 12]
mov w9, ascii_comma
mov w10, 0
str x3, [x0]
str w4, [x0, 8]
strb w5, [x0, 12]
strb w9, [x0, 13] /*place comma in middle*/
str x6, [x0, 14]
str w7, [x0, 22]
strb w8, [x0, 26]
strb w10, [x0, 27] /*Ensure we end in null*/

/*Remove all sapces from temp buffer before calling sscanf*/
bl remove_all_spaces /*NOTE func requires string to end in null byte, no checks*/

/*Change price & qty from ASCII to float*/
/*x0 ascii string ptr, x1 format ptr, x2+ where to store float int's*/
add x0, sp, 0x10
adr x1, sscanf_float_symbols
add x2, sp, 0x30
add x3, sp, 0x38
bl sscanf /*should we EC this?*/
cbz x19, get_pcq
/*We in edit mode, Get entries CURRENT cost*/
ldr d0, [curdataentry_ptr, d_cost]
/*Neg it*/
fneg d2, d0
/*Remove out old cost from totals*/
bl update_totals
/*Do price x qty to get cost*/
get_pcq:
ldr d0, [sp, 0x30]
ldr d1, [sp, 0x38]
fmul d2, d0, d1
/*write price, qty, and cost*/
str d0, [curdataentry_ptr, d_price]
str d1, [curdataentry_ptr, d_qty]
str d2, [curdataentry_ptr, d_cost]
/*Update totals*/
bl update_totals
/*write record number ONLY if LIVE*/
cbnz x19, write_login_dentry
add recordnum, recordnum, 1
str recordnum, [curdataentry_ptr, d_record]
/*write login to entry*/
write_login_dentry:
ldr x0, [invbin_ptr, login]
str x0, [curdataentry_ptr, d_login]
/*Write valid flag to entry*/
mov w0, 1
strb w0, [curdataentry_ptr, d_vflag]
/*Write the in-edit-mode flag as the NO-edit flag to entry*/
strb w19, [curdataentry_ptr, d_eflag] /*YES store as byte even though its loaded as dword*/

/*Sync time!*/
call_write_csv_line:
mov x0, curdataentry_ptr
bl write_csv_line

/*increment addr to next blank entry ONLY if called from LIVE*/
cbnz x19, write_entry_epilogue
add curdataentry_ptr, curdataentry_ptr, databin_entry_size

/*Epilogue*/
write_entry_epilogue:
/*Set finalize flag low*/
str xzr, [masterptr, finalizeflag]
mov w0, 1 /*1 indicates success*/
epilogue 3, 0x38

/*Args
d2 = What to add/sub to each total
no return values
Non-Volatile regs:
d31 = current inv total
d30 = current area total
d29 = current loc total
d28 = current cat total*/
update_totals:
/*No Prologue*/
/*Get enable/disable flag, if enable flag, update the total*/
ldrb w11, [invbin_ptr, arealoccatflags]
/*No matter what, do inv total*/
fadd d31, d31, d2
tbz w11, 2, 0x8 /*Is area enabled?*/
fadd d30, d30, d2
tbz w11, 1, 0x8 /*Is loc enabled?*/
fadd d29, d29, d2
tbz w11, 0, 0x8 /*Is cat enabled?*/
fadd d28, d28, d2
/*End func*/
ret

out_of_memory:
mov w0, 0
b write_entry_epilogue
