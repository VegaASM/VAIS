prep_csv_internal_open_error_msg:
.asciz "\x1B[2J\x1B[HERROR! Could not create the CSV to start the inventory with."
prep_csv_internal_write_error_msg:
.asciz "\x1B[2J\x1B[HERROR! Could not write the header to the CSV."

/*asciI not asciz to avoid null byte count*/
csv_header_string:
.ascii "Area,Loc,Cat,Price,Qty,ExtPrice,Login,RecordNum,TimeStamp,Edited?,PriceBypassed?,QtyBypassed?,UniqueID\n"
csv_header_string_end:
.set csv_header_size, 103 /*NOTE NOTE NOTE this has be hardcoded because clang SUCKS! GCC can do the end-string calc fine.*/
csv_simpfile_name:
.asciz "inv%d.csv"

.align 6
.globl prep_synced_csv
prep_synced_csv:
/*Prologue*/
prologue 0, 0x50

/*Get time
Arg: w0 = 0 null ptr, return time in register, NOT at a buffer space
x0 returns raw Unix time*/
mov w0, 0
bl time
mov x2, x0
adr x1, csv_simpfile_name
add x0, masterptr, csvfilename
bl sprintf
add x0, masterptr, csvfilename
mov w1, (O_WRONLY | O_DSYNC | O_CREAT | O_APPEND)
mov w2, (S_IRWXU | S_IRWXG | S_IRWXO)
bl open
tbnz w0, 31, prep_csv_internal_open_error
/*Store fd to masterptr*/
strb w0, [masterptr, fdstorespot]

/*Write Header to csv file*/
adr x1, csv_header_string
mov w2, csv_header_size
bl write
cmp w0, csv_header_size
bne prep_csv_internal_write_error

/*Return 0 for now...*/
mov w0, 0
epilogue 0, 0x50

prep_csv_internal_open_error:
adr x0, prep_csv_internal_open_error_msg
bl puts
b 0x0 /*TODO halt for now*/
prep_csv_internal_write_error:
adr x0, prep_csv_internal_write_error_msg
bl puts
b 0x0 /*TODO halt for now*/
