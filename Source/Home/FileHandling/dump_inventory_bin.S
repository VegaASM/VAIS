inventory_bin_filepath:
.asciz "inventory.bin"
inventory_bin_read_perms:
.asciz "rb"
fopen_inventorybin_error_msg:
.asciz "\x1B[2J\x1B[HError! Can't open inventory.bin. Make sure one is present. VAIS has been powered off."
size_inventorybin_error_msg:
.asciz "\x1B[2J\x1B[HError! Inventory.bin has an incorrect size. VAIS has been powered off. Relaunch VAIS and go to settings and use the Generate New Inventory.bin option to fix."
malloc_inventorybin_error_msg:
.asciz "\x1B[2J\x1B[HError! Can't allocate memory. VAIS has been powered off."
fread_inventorybin_error_msg:
.asciz "\x1B[2J\x1B[HError! Unable to dump inventory.bin to memory. VAIS has been powered off."

.align 6

/*
Args (none/void)
Return Values:
0 = Success
Ptr = Msg that main will print to console
*/

.globl dump_inventory_bin
dump_inventory_bin:
prologue 2, 0

/*Open inventory.bin*/
adr x0, inventory_bin_filepath
adr x1, inventory_bin_read_perms
bl fopen
cbz x0, fopen_inventorybin_error_msg_loc
mov x19, x0

/*Get inv.bin file size*/
mov w1, 0
mov w2, 2 //seek end
bl fseek
mov x0, x19
bl ftell
mov w20, w0
mov x0, x19
bl rewind

/*Make sure size is correct*/
cmp w20, invbin_size
bne size_inventorybin_error_msg_loc

/*Make malloc space for inventory.bin + 131,072 raw inventory entries*/
add w0, w20, databin_max_size
bl malloc
cbz x0, malloc_inventorybin_error_msg_loc
/*Create the invbin global ptr*/
mov invbin_ptr, x0

/*Create the start dataentry ptr, curdataentry ptr, and enddataentry_ptr*/
add dataentry_ptr, x0, invbin_size
mov curdataentry_ptr, dataentry_ptr
mov w1, entriesamt
sub w1, w1, 1
mov w2, databin_entry_size
mul x3, x1, x2
add x4, dataentry_ptr, x3
str x4, [masterptr, enddataentry_ptr]

/*Dump inventory.bin*/
mov x0, invbin_ptr
mov w1, 1 //Size
mov w2, w20 //Count aka real size
mov x3, x19 //File pointer
bl fread
cmp w0, invbin_size
bne fread_inventorybin_error_msg_loc

/*Close inventory.bin*/
mov x0, x19
bl fclose

/*Return back zero (success)*/
mov w0, 0

/*Epilogue*/
dump_inventory_bin_epilogue:
epilogue 2, 0

fopen_inventorybin_error_msg_loc:
adr x0, fopen_inventorybin_error_msg
b dump_inventory_bin_epilogue

size_inventorybin_error_msg_loc:
adr x0, size_inventorybin_error_msg
b dump_inventory_bin_epilogue

malloc_inventorybin_error_msg_loc:
adr x0, malloc_inventorybin_error_msg
b dump_inventory_bin_epilogue

fread_inventorybin_error_msg_loc:
adr x0, fread_inventorybin_error_msg
b dump_inventory_bin_epilogue
