fi_internal_close_error_one_msg: //Close Normal
.asciz "\x1B[2J\x1B[HERROR! Could not close the current CSV file to begin finalization."
fi_internal_open_error_one_msg: //Reopen Normal in RD mode
.asciz "\x1B[2J\x1B[HERROR! Could not reopen CSV file to begin finalization."
fi_internal_fstat_error_msg: //Get File Size of Normal
.asciz "\x1B[2J\x1B[HERROR! Could not get the file size of the CSV file."
fi_internal_malloc_error_msg: //Space for New/Stripped
.asciz "\x1B[2J\x1B[HERROR! Could not allocate memory for the new finalized CSV file."
fi_internal_read_error_msg: //Read Normal
.asciz "\x1B[2J\x1B[HERROR! Could not read the current CSV file into memory."
fi_internal_close_error_two_msg: //Close Normal
.asciz "\x1B[2J\x1B[HERROR! Could not close the CSV file after reading it."
fi_internal_sprintf_error_msg: //Title for Temp
.asciz "\x1B[2J\x1B[HERROR! Sprintf failed when generating title for temp CSV"
fi_internal_open_error_two_msg: //Create Temp
.asciz "\x1B[2J\x1B[HERROR! Could not create the temp CSV."
fi_internal_write_error_one_msg: //Write Temp
.asciz "\x1B[2J\x1B[HERROR! Could not write the temp CSV."
fi_internal_close_error_three_msg: //Close Temp
.asciz "\x1B[2J\x1B[HERROR! Could not close the temp CSV after writing to it."
fi_internal_unlink_error_one_msg: //Remove Normal
.asciz "\x1B[2J\x1B[HERROR! Could not delete the old unfinalized CSV."
fi_internal_open_error_three_msg: //Create NEW Normal
.asciz "\x1B[2J\x1B[HERROR! Could not create the new finalized CSV."
fi_internal_write_error_two_msg: //Write NEW Normal
.asciz "\x1B[2J\x1B[HERROR! Could not write to the new finalized CSV."
fi_internal_close_error_four_msg: //Close NEW Normal
.asciz "\x1B[2J\x1B[HERROR! Could not close the new finlaized CSV."
fi_internal_unlink_error_two_msg: //Delete Temp
.asciz "\x1B[2J\x1B[HERROR! Could not delete the temp CSV."

finalize_inventory_msg:
.asciz "\x1B[2J\x1B[HNOTICE! This will remove/strip all deleted entries from the current Inventory CSV file.\nYou can choose to finalize to a generic CSV, or to a CSV that will work with JB's Custom United Software (separate generic will be done as well).\n\n7. Yes, finalize for Generic.\n5. Yes, finalize for JB + Generic.\n8/ESC. No, go back to Main Menu."

finalize_inventory_please_wait_msg:
.asciz "\x1B[2J\x1B[HFinalizing Data... Please wait..."

finalize_inventory_done_msg:
.asciz "\x1B[2J\x1B[HData has been finalized!\nPress any key to go back to Main Menu."

finalize_inventory_flaghigh_msg:
.asciz "\x1B[2J\x1B[HNOTICE! Finalization aborted.\nEither an inventory wasn't started yet, or finalization has already been completed.\nPress any key to go back to Main Menu."

fi_nano_to_ascii:
.asciz "%016x"

.align 6
.globl finalize_inventory
finalize_inventory:
prologue 7, 0x88 /*0x80 needed for fstat struct*/

/*Get finalize flag. If high stop user*/
ldr x1, [masterptr, finalizeflag]
cbz x1, finalize_inventory_start

/*Stop!, idle, wait for any keyhit to exit*/
adr x0, finalize_inventory_flaghigh_msg
bl puts
bl beep
bl keyboard_input
cbz w0, -4
b finalize_inventory_epilogue

/*Display the intro msg*/
finalize_inventory_start:
adr x0, finalize_inventory_msg
bl puts

/*Read input and wait on user*/
finalize_inventory_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq finalize_inventory_epilogue
cmp w0, ascii_8
beq finalize_inventory_epilogue
cmp w0, ascii_7
mov w25, 0 //Quality/DC5 flag low
beq finalize_the_csv_file
cmp w0, ascii_5
mov w25, 1 //Quality/DC5 flag high
beq finalize_the_csv_file
bl beep
b finalize_inventory_idle_loop

finalize_the_csv_file:
/*Print the wait msg*/
adr x0, finalize_inventory_please_wait_msg
bl puts
/*Close file*/
ldrb w0, [masterptr, fdstorespot]
bl close
cbnz x0, fi_internal_close_error_one
////////////////////////////////////////
/*Reopen with read + dsync*/
mov w1, (O_RDONLY | O_DSYNC)
add x0, masterptr, csvfilename
bl open
tbnz w0, 31, fi_internal_open_error_one
/*Get file size*/
strb w0, [masterptr, fdstorespot]
add x1, sp, 0x10
bl fstat
cbnz x0, fi_internal_fstat_error
/*Size is a dword at 0x30 offset of struct which is 0x40 relative to sp*/
ldr x19, [sp, 0x40]
/*Malloc*/
mov x0, x19
bl malloc
cbz x0, fi_internal_malloc_error
mov x20, x0
/*Dump whole file*/
mov x1, x0
ldrb w0, [masterptr, fdstorespot]
mov x2, x19
bl read
cmp x0, x19
bne fi_internal_read_error
/*Close file*/
ldrb w0, [masterptr, fdstorespot]
bl close
cbnz x0, fi_internal_close_error_two
////////////////////////////////////////
/*Create backup file using nanoseconds as name*/
bl get_time_in_nsecs
mov x2, x0
add x0, sp, 0x10
adr x1, fi_nano_to_ascii
bl sprintf
cmp w0, 16
bne fi_internal_sprintf_error
/*Create temp file*/
/*NOTE for whatever reason sprintf is excluding the upper 32-bits of the extended register when we change the nanos to ascii, thus the lower 16b-its of the nano value is the only value that gets converted and that value is prepended with 0's. not a big deal but just so we know...*/
add x0, sp, 0x10
mov w1, (O_WRONLY | O_DSYNC | O_CREAT)
mov w2, (S_IRWXU | S_IRWXG | S_IRWXO)
bl open
tbnz w0, 31, fi_internal_open_error_two
strb w0, [masterptr, fdstorespot]
/*write the temp file*/
mov x1, x20
mov x2, x19
bl write
cmp x0, x19
bne fi_internal_write_error_one
/*close temp file*/
ldrb w0, [masterptr, fdstorespot]
bl close
cbnz x0, fi_internal_close_error_three
////////////////////////////////////////
/*REMOVE the current NON-temp file*/
add x0, masterptr, csvfilename
bl unlink
cbnz x0, fi_internal_unlink_error_one
/*Recreate the file so its empty (EXclude APPEND)*/
add x0, masterptr, csvfilename
mov w1, (O_WRONLY | O_DSYNC | O_CREAT)
mov w2, (S_IRWXU | S_IRWXG | S_IRWXO)
bl open
tbnz w0, 31, fi_internal_open_error_three
strb w0, [masterptr, fdstorespot]
////////////////////////////////////////

/*Now we need to be in a loop and look for any DELETED!, shit*/
size_unfinalized_csv .req x19
start_csv_static_ptr .req x20
csv_load_ptr .req x21
csv_write_ptr .req x22
delete_entry_mask .req x23

/*Create a load and write ptr for the CSV, DON'T include Header*/
add csv_load_ptr, start_csv_static_ptr, csv_header_size
add csv_write_ptr, start_csv_static_ptr, csv_header_size

/*Set "!DELETE," in a non-vol register*/
movz delete_entry_mask, 0x2C21, lsl 48
movk delete_entry_mask, 0x4554, lsl 32
movk delete_entry_mask, 0x454C, lsl 16
movk delete_entry_mask, 0x4544

/*Fyi we are using GLOBAL recordnum (linear record count) register for this loop count, its volatile(safe) to use now*/
/*NOTE this is unsafe if VAIS ever becomes non-linear*/
remove_stale_deleted_entries_loop:
/*Check if entry is marked as DELETE!*/
ldr x0, [csv_load_ptr]
cmp x0, delete_entry_mask
bne DELETE_not_found

/*!DELETE'd entry found, adjust the load ptr but NOT the write ptr*/
add csv_load_ptr, csv_load_ptr, csv_entry_size

/*Decrement loop*/
decrement_remove_stale_deleted_entries_loop:
subs recordnum, recordnum, 1
bne remove_stale_deleted_entries_loop

/*Get out of Loop*/
b fi_calc_new_csv_size

/*Regular entry found, transfer entry using load to write ptr*/
DELETE_not_found:
mov w0, csv_entry_size
inner_DELETE_not_found_loop:
ldrb w1, [csv_load_ptr], 1
strb w1, [csv_write_ptr], 1
subs w0, w0, 1
bne inner_DELETE_not_found_loop
b decrement_remove_stale_deleted_entries_loop

/*Calc new file size*/
fi_calc_new_csv_size:
sub x19, csv_write_ptr, start_csv_static_ptr

/*Write new file*/
ldrb w0, [masterptr, fdstorespot]
mov x1, x20
mov x2, x19 /*Save for later verification with lseek*/
bl write
cmp x0, x19
bne fi_internal_write_error_two
/*Close finalized file*/
ldrb w0, [masterptr, fdstorespot]
bl close
cbnz x0, fi_internal_close_error_four
////////////////////////////////////////

/*See if DC5 csv will be made as well*/
cbz w25, fi_free_mallocd_space
mov x0, x19 //size of finalized generic
mov x1, x20 //ptr to finalized generic
bl dc5_csv

/*Free the malloc'd space*/
fi_free_mallocd_space:
mov x0, x20
bl free
/*Remove temp file*/
add x0, sp, 0x10
bl unlink
cbnz x0, fi_internal_unlink_error_two
/*Set finalize flag high*/
mov x1, 1
str x1, [masterptr, finalizeflag]
/*Set success message and idle*/
adr x0, finalize_inventory_done_msg
bl puts
bl keyboard_input
cbz w0, -4

finalize_inventory_epilogue:
mov w0, 0 /*return code for Main Menu, DON'T power off*/
/*Epilogue*/
epilogue 7, 0x88

/*Error handlers*/
fi_internal_close_error_one: //Close Normal
adr x0, fi_internal_close_error_one_msg
bl puts
b 0x0 /*TODO halt for now*/
fi_internal_open_error_one: //Reopen Normal in RD mode
adr x0, fi_internal_open_error_one_msg
bl puts
b 0x0 /*TODO halt for now*/
fi_internal_fstat_error: //Get File Size of Normal
adr x0, fi_internal_fstat_error_msg
bl puts
b 0x0 /*TODO halt for now*/
fi_internal_malloc_error: //Space for New/Stripped
adr x0, fi_internal_malloc_error_msg
bl puts
b 0x0 /*TODO halt for now*/
fi_internal_read_error: //Read Normal
adr x0, fi_internal_read_error_msg
bl puts
b 0x0 /*TODO halt for now*/
fi_internal_close_error_two: //Close Normal
adr x0, fi_internal_close_error_two_msg
bl puts
b 0x0 /*TODO halt for now*/
fi_internal_sprintf_error: //Title for Temp
adr x0, fi_internal_sprintf_error_msg
bl puts
b 0x0 /*TODO halt for now*/
fi_internal_open_error_two: //Create Temp
adr x0, fi_internal_open_error_two_msg
bl puts
b 0x0 /*TODO halt for now*/
fi_internal_write_error_one: //Write Temp
adr x0, fi_internal_write_error_one_msg
bl puts
b 0x0 /*TODO halt for now*/
fi_internal_close_error_three: //Close Temp
adr x0, fi_internal_close_error_three_msg
bl puts
b 0x0 /*TODO halt for now*/
fi_internal_unlink_error_one: //Remove Normal
adr x0, fi_internal_unlink_error_one_msg
bl puts
b 0x0 /*TODO halt for now*/
fi_internal_open_error_three: //Create NEW Normal
adr x0, fi_internal_open_error_three_msg
bl puts
b 0x0 /*TODO halt for now*/
fi_internal_write_error_two: //Write NEW Normal
adr x0, fi_internal_write_error_two_msg
bl puts
b 0x0 /*TODO halt for now*/
fi_internal_close_error_four: //Close NEW Normal
adr x0, fi_internal_close_error_four_msg
bl puts
b 0x0 /*TODO halt for now*/
fi_internal_unlink_error_two: //Delete Temp
adr x0, fi_internal_unlink_error_two_msg
bl puts
b 0x0 /*TODO halt for now*/
