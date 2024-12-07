settings_synced_msg:
.asciz "\x1B[2J\x1B[H7. Sync Settings\n8/ESC. Go back to Settings Menu."

settings_synced_msg_completed:
.asciz "\x1B[2J\x1B[HSettings have been synced.\nPress any key to go back to Settings Menu."

settings_sync_fopen_error_msg:
.asciz "\x1B[2J\x1B[HFailed to open inventory.bin for writing."

settings_sync_fwrite_error_msg:
.asciz "\x1B[2J\x1B[HFailed to write to inventory.bin."

sync_inventory_bin_filepath:
.asciz "inventory.bin"
sync_inventory_bin_write_perms:
.asciz "wb"

.align 6

.globl settings_sync
settings_sync:
/*Prologue*/
prologue 1, 8

/*Print msg*/
adr x0, settings_synced_msg
bl puts
settings_sync_main_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq settings_sync_epilogue
cmp w0, ascii_8
beq settings_sync_epilogue
cmp w0, ascii_7
beq start_syncing
bl beep
b settings_sync_main_idle_loop

/*Start syncing*/
start_syncing:
adr x0, sync_inventory_bin_filepath
adr x1, sync_inventory_bin_write_perms
bl fopen
cbz x0, settings_sync_fopen_error
mov x19, x0
/*Write new inventory.bin*/
mov x0, invbin_ptr //Where write contents are at
mov w1, 1 //Size
mov w2, invbin_size //Count aka real size
mov x3, x19 //File stream ptr
bl fwrite
cmp w0, invbin_size
bne settings_sync_fwrite_error
/*Close inventory.bin*/
mov x0, x19
bl fclose
/*Idle and wait for key hit*/
adr x0, settings_synced_msg_completed
bl puts
/*Idle*/
bl keyboard_input
cbz w0, -4

/*Epilogue*/
settings_sync_epilogue:
epilogue 1, 8

settings_sync_fopen_error:
adr x0, settings_sync_fopen_error_msg
bl puts
b 0x0 /*TODO HALT for now*/

/*Fuck you*/
settings_sync_fwrite_error:
adr x0, settings_sync_fwrite_error_msg
bl puts
b 0x0 /*TODO HALT for now*/
