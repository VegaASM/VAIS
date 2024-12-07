delete_csv_line_internal_error_msg:
.asciz "\x1B[2J\x1B[HERROR! Internal error for the delete_csv_line function."

/*x0 = ptr to raw data entry (on LIVE this is curdata_entry_ptr)
Returns 0 or halts with error message*/

.align 6
.globl delete_csv_line
delete_csv_line:
/*Prologue*/
prologue 1, 0x18
/*Close file since its in append mode*/
ldrb w0, [masterptr, fdstorespot]
bl close
cbnz w0, deletecsv_internal_close_error_one
/*Reopen withOUT O_CREAT and O_APPEND*/
mov w1, (O_WRONLY | O_DSYNC)
add x0, masterptr, csvfilename
bl open
tbnz w0, 31, deletecsv_internal_open_error_one
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
bne deletecsv_internal_seek_error_one
/*Write "DELETE!," to first csv entry*/
movz x3, 0x2C21, lsl 48
movk x3, 0x4554, lsl 32
movk x3, 0x454C, lsl 16
movk x3, 0x4544
ldrb w0, [masterptr, fdstorespot]
str x3, [sp, 0x10]
mov w2, 8
add x1, sp, 0x10
bl write
cmp w0, 8
bne deletecsv_internal_write_error
/*Close file and reopen with O_APPEND*/
ldrb w0, [masterptr, fdstorespot]
bl close
cbnz w0, deletecsv_internal_close_error_two
mov w1, (O_WRONLY | O_DSYNC | O_APPEND)
add x0, masterptr, csvfilename
bl open /*w2 arg isn't needed*/
tbnz w0, 31, deletecsv_internal_open_error_two
strb w0, [masterptr, fdstorespot]
/*Now seek to 1 byte past end of file*/
/*TODO we need to get fstat or
calc seekoffset using recordnum+0
because we have no way of checking lseek return correctly*/
mov w1, 0
mov w2, SEEK_END
bl lseek
tbnz x0, 63,  deletecsv_internal_lseek_error_two
/*Epilogue*/
epilogue 1, 0x18

deletecsv_internal_close_error_one:
deletecsv_internal_open_error_one:
deletecsv_internal_seek_error_one:
deletecsv_internal_write_error:
deletecsv_internal_close_error_two:
deletecsv_internal_open_error_two:
deletecsv_internal_lseek_error_two:
adr x0, delete_csv_line_internal_error_msg
bl puts
b 0x0 /*TODO halt for now*/

