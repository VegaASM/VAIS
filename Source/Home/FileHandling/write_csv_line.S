comma_reg .req w20

write_csv_line_internal_error_msg:
.asciz "\x1B[2J\x1B[HERROR! Internal error for the write_csv_line function."
csv_float_to_ascii:
.asciz "%32lf"
csv_intbyte_to_ascii:
.asciz "%016u"
csv_serno_to_ascii:
.asciz "%08x%s%016u"
csv_time_stamp:
.asciz "%04d-%02d-%02d %02d:%02d:%02d"

.align 3
.data
time_stamp_quick_hacky_buffer:
.zero 72
.text

/*x0 = ptr to raw data entry (on LIVE this is curdata_entry_ptr)
Returns 0 or halts with error message*/

.align 6
.globl write_csv_line
write_csv_line:
/*Prologue*/
prologue 3, 0xE8 //0xD7 required for csv entry, round up to 0xE8 cuz odd amount of regs saved to stack and just INCASE 0xD8 isnt enough even though it SHOULD be
/*Save Arg*/
mov x19, x0
/*Set other non-vol regs*/
mov comma_reg, ascii_comma
add x21, sp, 0x10
/*Convert data entry to csv entry, no need to check validflag cuz if we got here from LIVE then its always high and if from EDIT we're suppose to disregard it anyway*/
/*Write area, loc, cat and their respective commas*/
ldr x1, [x19, d_area]
ldr x2, [x19, d_loc]
ldr x3, [x19, d_cat]
str x1, [x21], 7
strb comma_reg, [x21], 1
str x2, [x21], 7
strb comma_reg, [x21], 1
str x3, [x21], 7
strb comma_reg, [x21], 1
/*Convert price float to ascii*/
ldr d0, [x19, d_price]
mov x0, x21
adr x1, csv_float_to_ascii
bl sprintf //Don't error check this...
/*write comma*/
strb comma_reg, [x21, x0]
add x21, x21, x0
add x21, x21, 1 //go past comma
/*Convert qty float to ascii*/
ldr d0, [x19, d_qty]
mov x0, x21
adr x1, csv_float_to_ascii
bl sprintf //Don't error check this...
/*write comma*/
strb comma_reg, [x21, x0]
add x21, x21, x0
add x21, x21, 1 //go past comma
/*Convert cost float to ascii*/
ldr d0, [x19, d_cost]
mov x0, x21
adr x1, csv_float_to_ascii
bl sprintf //Don't error check this...
/*write comma*/
strb comma_reg, [x21, x0]
add x21, x21, x0
add x21, x21, 1 //go past comma
/*write login*/
ldr x0, [x19, d_login]
str x0, [x21], 7
/*write comma*/
strb comma_reg, [x21], 1
/*convert recordnum from uint to ascii*/
ldr x2, [x19, d_record]
mov x0, x21
adr x1, csv_intbyte_to_ascii
bl sprintf //Don't error check this...
/*write comma*/
strb comma_reg, [x21, x0]
add x21, x21, x0
add x21, x21, 1 //go past comma
/*Write time stamp*/
ldr x1, [x19, d_time]
adr x0, time_stamp_quick_hacky_buffer
str x1, [x0]
/*Get real time
Arg x0 = ptr to struct
x1 = x0 return value stored at 0x0 offset of struct
x0 returns ptr where converted time data is at*/
bl localtime
ldp w7, w6, [x0]
ldp w5, w4, [x0, 0x8]
ldp w3, w2, [x0, 0x10]
adr x1, csv_time_stamp
mov x0, x21
add w3, w3, 1
add w2, w2, 1900
bl sprintf
/*Write comma*/
strb comma_reg, [x21, x0]
add x21, x21, x0
add x21, x21, 1 //go past comma
/*Write YES or No for Edited field*/
ldrb w0, [x19, d_eflag]
cbz w0, 0x10
movz w1, 0x5345, lsl 16 //ugh LE
movk w1, 0x5920
b 0xC
movz w1, 0x6F4E, lsl 16 //ugh LE
movk w1, 0x2020
str w1, [x21], 4
/*write comma*/
strb comma_reg, [x21], 1
/*Write YES or No for Price Bypass field*/
ldrb w0, [x19, d_pflag]
cbz w0, 0x10
movz w1, 0x5345, lsl 16 //ugh LE
movk w1, 0x5920
b 0xC
movz w1, 0x6F4E, lsl 16 //ugh LE
movk w1, 0x2020
str w1, [x21], 4
/*write comma*/
strb comma_reg, [x21], 1
/*Write YES or No for Qty Bypass field*/
ldrb w0, [x19, d_qflag]
cbz w0, 0x10
movz w1, 0x5345, lsl 16 //ugh LE
movk w1, 0x5920
b 0xC
movz w1, 0x6F4E, lsl 16 //ugh LE
movk w1, 0x2020
str w1, [x21], 4
/*write comma*/
strb comma_reg, [x21], 1
/*Write serialnum (timer + login + recordnum*/
ldr x2, [masterptr, serialnum]
add x3, x19, d_login
ldr x4, [x19, d_record]
mov x0, x21
adr x1, csv_serno_to_ascii
bl sprintf //Don't error check this...
/*write enter*/
mov w2, ascii_enter
strb w2, [x21, x0]

/*Load file descriptor*/
ldrb w0, [masterptr, fdstorespot]
/*Are we in edit mode?*/
ldr x1, [masterptr, in_editmode_flag]
cbnz x1, writecsv_ineditmode

/*Nope! Write to file!*/
add x1, sp, 0x10
mov w2, csv_entry_size
bl write
cmp w0, csv_entry_size
bne writecsv_internal_write_error_one

/*Epilogue*/
write_csv_line_epilogue:
mov w0, wzr //useless return code for now
epilogue 3, 0xE8

writecsv_ineditmode:
/*Close file, fd already in w0*/
bl close
cbnz x0, writecsv_internal_close_error_one
/*Reopen withOUT O_CREAT and O_APPEND*/
mov w1, (O_WRONLY | O_DSYNC)
add x0, masterptr, csvfilename
bl open /*w2 arg isn't needed*/
tbnz w0, 31, writecsv_internal_open_error_one
strb w0, [masterptr, fdstorespot]
/*Use record num selected/chosen in edit mode to seek to shit*/
mov w5, csv_header_size
ldr x6, [x19, d_record]
sub x6, x6, 1
mov w7, csv_entry_size
mul x8, x6, x7
add x1, x8, x5
mov w2, SEEK_SET
mov x19, x1
bl lseek
cmp x0, x19
bne writecsv_internal_lseek_error_one
/*Write that shit!*/
ldrb w0, [masterptr, fdstorespot]
add x1, sp, 0x10
mov w2, csv_entry_size
bl write
cmp w0, csv_entry_size
bne writecsv_internal_write_error_two
/*Close again, and reopen with O_APPEND*/
ldrb w0, [masterptr, fdstorespot]
bl close
cbnz x0, writecsv_internal_close_error_two
mov w1, (O_WRONLY | O_DSYNC | O_APPEND)
add x0, masterptr, csvfilename
bl open /*w2 arg isn't needed*/
tbnz w0, 31, writecsv_internal_open_error_two
strb w0, [masterptr, fdstorespot]
/*Now seek to 1 byte past end of file*/
/*TODO we need to get fstat or
calc seekoffset using recordnum+0
because we have no way of checking lseek return correctly*/
mov w1, 0
mov w2, SEEK_END
bl lseek
tbnz x0, 63, writecsv_internal_lseek_error_two
/*Finally end...*/
b write_csv_line_epilogue

writecsv_internal_write_error_one:
writecsv_internal_close_error_one:
writecsv_internal_open_error_one:
writecsv_internal_lseek_error_one:
writecsv_internal_write_error_two:
writecsv_internal_close_error_two:
writecsv_internal_open_error_two:
writecsv_internal_lseek_error_two:
adr x0, write_csv_line_internal_error_msg
bl puts
b 0x0 /*halt for now TODO*/
