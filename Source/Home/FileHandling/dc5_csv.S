dc5_sscanf_line:
.asciz "%lf,%lf"
dc5_sprintf_line:
.asciz "%10.3f,%13.4f,"
dc5_filename:
.asciz "TESTTEST.csv"

dc5_error_msg:
.asciz "\x1B[2J\x1B[HERROR! Internal error occurred during the JB CSV processing."

generic_size .req x19
generic_ptr .req x20 /*also updates/cur*/
dc5_baseptr .req x21
generic_oobptr .req x22
dc5_comma_reg .req w23
dc5_newline_reg .req w24
dc5_curptr .req x25
dc5_fd .req w26

/*x0 = size of finalized generic csv*/
/*x1 = ptr to generic.csv*/
/*Called after close thats after write in finalize_inventory.S*/


.align 6
.globl dc5_csv
dc5_csv:
/*Prologue*/
prologue 8, 0x20

/*Save Args*/
mov generic_size, x0
mov generic_ptr, x1

/*Remove any existing DC5 file*/
adr x0, dc5_filename
bl unlink /*No error check on this*/

/*Create+open new DC5 file*/
adr x0, dc5_filename
mov w1, (O_WRONLY | O_DSYNC | O_CREAT)
mov w2, (S_IRWXU | S_IRWXG | S_IRWXO)
bl open
tbnz w0, 31, dc5_create_error
mov dc5_fd, w0

/*Multiply size by 2 and malloc for DC5 CSV, this is WAY WAY MORE THAN ENOUGH*/
lsl x0, generic_size, 1
bl malloc
cbz x0, dc5_malloc_error
mov dc5_baseptr, x0

/*Set Eof+1 aka OoB generic CSV ptr*/
add generic_oobptr, generic_ptr, generic_size

/*Update ptr to past CSV header*/
add generic_ptr, generic_ptr, csv_header_size

/*Set comma and newline non-vol registers*/
mov dc5_comma_reg, ascii_comma
movz dc5_newline_reg, 0x0A0D //Windows carriage the newline once its stored (little endian), ugh

/*Make copy of DC5 ptr to be an updating/current-ptr*/
mov dc5_curptr, dc5_baseptr

/*Write "A," to DC5 csv*/
movz w0, 0x2C41 /*ugh, littleendian*/
strh w0, [dc5_curptr], 2

/*Loop*/
/*Transfer Area, loc, cat plus their commas from generic to DC5*/
dc5_mega_loop:
ldr x0, [generic_ptr], csv_area_size
ldr x1, [generic_ptr], csv_loc_size
ldr x2, [generic_ptr], csv_cat_size
str x0, [dc5_curptr], csv_area_size
str x1, [dc5_curptr], csv_loc_size
str x2, [dc5_curptr], csv_cat_size

/*Write comma to "after" non-existent sku field*/
strb dc5_comma_reg, [dc5_curptr], 1

/*Get Price and Qty float values*/
/*TODO transfer this shit to a null terminated buffer first
YES shit works for now but this is not proper code*/
mov x0, generic_ptr
adr x1, dc5_sscanf_line
add x2, sp, 0x10
add x3, sp, 0x20
bl sscanf
cmp w0, 2
bne dc5_sscanf_error

/*Convert to DC5 specs*/
ldr d0, [sp, 0x10]
ldr d1, [sp, 0x20]
mov x0, dc5_curptr
adr x1, dc5_sprintf_line
bl sprintf
add dc5_curptr, dc5_curptr, x0

/*Write Qty2 and its comma ("1,")*/
mov w0, 0x2C31 //ugh little endian
strh w0, [dc5_curptr], 2

/*Grab Login, chop off last 3 letters plus its original comma by not using correct post store index value LOL*/
add generic_ptr,generic_ptr, csv_go_from_price_to_login //Will now point to Login in generic
ldr x0, [generic_ptr], csv_go_from_login_to_next_entry //generic now points to area of next entry
str x0, [dc5_curptr], 4 //LOL
strb dc5_comma_reg, [dc5_curptr], 1

/*Store 9 commas then 0x0D0A then comma*/
movz x0, 0x2C2C
movk x0, 0x2C2C, lsl 16
movk x0, 0x2C2C, lsl 32
movk x0, 0x2C2C, lsl 48
str x0, [dc5_curptr], 8
strb dc5_comma_reg, [dc5_curptr], 1
strh dc5_newline_reg, [dc5_curptr], 2
strb dc5_comma_reg, [dc5_curptr], 1

/*Check if we hit end of generic CSV*/
cmp generic_ptr, generic_oobptr
blo dc5_mega_loop

/*Overwrite final comma (nonexistent next entry start-comma) with NULL byte*/
strb wzr, [dc5_curptr, -1]

/*Remove all spaces, must end in null byte before we call func*/
mov x0, dc5_baseptr
bl remove_all_spaces

/*Calc size, shit ends in NULL byte no matter what at this point*/
mov x1, dc5_baseptr
ldrb w0, [x1], 1
cbnz w0, -4
sub x19, x1, dc5_baseptr
sub x19, x19, 1 /*Must subtract the null byte away from the count*/

/*Write DC5 csv*/
mov w0, dc5_fd
mov x1, dc5_baseptr
mov x2, x19
bl write
cmp x0, x19
bne dc5_write_error

/*Close DC5 csv*/
mov w0, dc5_fd
bl close
cbnz x0, dc5_close_error

/*Epilogue*/
epilogue 8, 0x20

dc5_create_error:
dc5_malloc_error:
dc5_sscanf_error:
dc5_write_error:
dc5_close_error:
adr x0, dc5_error_msg
bl puts
b 0x0 /*TODO halt for now*/

