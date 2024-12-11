/*
Args: Void
Return Values:
w0 - 0; tell main to idle
w0 - !0; tell main to power off VAIS*/

start_new_inventory_msg:
.asciz "\x1B[2J\x1B[HInventory Start Menu\n\n1. Start new Inventory\n8/ESC. Go back to Main Menu\n"

start_new_inventory_notice_msg:
.asciz "\x1B[2J\x1B[HNOTICE! This will clear all current (live) data. Are you sure you want to start a new Inventory?\n\n7. Yes\n8/ESC. No, Go back to Inventory Start Menu"

starting_new_inventory_wait_msg:
.asciz "\x1B[2J\x1B[HStarting new Inventory... Please wait..."

.align 6

.globl start_new_inventory
start_new_inventory:
prologue 0, 0

/*Print intro msg*/
start_new_inventory_pre_loop:
adr x0, start_new_inventory_msg
bl puts

/*keyboard input and wait*/
start_new_inventory_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq start_new_inventory_epilogue
cmp w0, ascii_8
beq start_new_inventory_epilogue
cmp w0, ascii_1
beq _do_start_new_inventory
bl beep
b start_new_inventory_idle_loop

/*------------------------------------*/

_do_start_new_inventory:
adr x0, start_new_inventory_notice_msg
bl puts
_do_start_new_inventory_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq start_new_inventory_pre_loop
cmp w0, ascii_8
beq start_new_inventory_pre_loop
cmp w0, ascii_7
beq 0xC
bl beep
b _do_start_new_inventory_idle_loop
adr x0, starting_new_inventory_wait_msg
bl puts
bl prep_synced_csv
/*Reset area, loc, cat to all spaces, TODO should this be width based?*/
movz x0, 0x0020, lsl 48
movk x0, 0x2020, lsl 32
movk x0, 0x2020, lsl 16
movk x0, 0x2020
str x0, [masterptr, area]
str x0, [masterptr, loc]
str x0, [masterptr, cat]
/*Clear all live data*/
mov recordnum, 0
mov curdataentry_ptr, dataentry_ptr
mov x0, dataentry_ptr
mov x1, databin_max_entries
str xzr, [x0], databin_entry_size /*clears vflag, eflag, pflag, and qflag*/
subs x1, x1, 1
bne -0x8
/*Set finalize flag LOW*/
str xzr, [masterptr, finalizeflag]

/*Go to area/loc/cat menu*/
bl continue_inventory

/*Epilogue*/
start_new_inventory_epilogue:
mov w0, 0 /*Signal to main to NOT power off*/
epilogue 0, 0
