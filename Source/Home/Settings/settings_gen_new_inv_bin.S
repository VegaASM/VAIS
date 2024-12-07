/*NOTE NOTE NOTE UNUSED!!!! Keeping just in case I need this for future*/

settings_gen_new_invbin_msg:
.asciz "\x1B[2J\x1B[HNotice! This will clear all settings to their defaults! Are you sure?\n7. Yes\n8/ESC. No, go back to Settings Menu."
settings_gen_new_invbin_completed_msg:
.asciz "\x1B[2J\x1B[HNew inventory.bin has been generated successfully!\nPress any key to go back to Settings Menu."

.align 6

.globl settings_gen_new_inv_bin
settings_gen_new_inv_bin:
/*Prologue*/
prologue 0, 0

/*Print*/
adr x0, settings_gen_new_invbin_msg
bl puts
settings_gen_new_inv_bin_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq settings_gen_new_inv_bin_epilogue
cmp w0, ascii_8
beq settings_gen_new_inv_bin_epilogue
cmp w0, ascii_7
beq _gen_new_inv_bin
bl beep
b settings_gen_new_inv_bin_idle_loop
/*gen new inv.bin*/
/*gen default login*/
_gen_new_inv_bin:
movz x0, 0x0031, lsl 48 //little endian...
movk x0, 0x3030, lsl 32
movk x0, 0x5245, lsl 16
movk x0, 0x5355
str x0, [invbin_ptr, login]
/*gen 0's for max/min price+qty*/
stp xzr, xzr, [invbin_ptr, maxprice]
stp xzr, xzr, [invbin_ptr, maxqty]
/*gen default flags that enable all directories*/
mov w0, 0x7
strb w0, [invbin_ptr, arealoccatflags]
/*gen default max widths*/
strb w0, [invbin_ptr, areawidth]
strb w0, [invbin_ptr, locwidth]
strb w0, [invbin_ptr, catwidth]
/*gen 0000000 area,loc, and cat*/
movz x0, 0x0030, lsl 48 //little endian...
movk x0, 0x3030, lsl 32
movk x0, 0x3030, lsl 16
movk x0, 0x3030
str x0, [invbin_ptr, area]
str x0, [invbin_ptr, loc]
str x0, [invbin_ptr, cat]
/*gen default tdvalue-on & audio-on flag*/
mov w0, 1
strb w0, [invbin_ptr, soundkeyflags]
strb w0, [invbin_ptr, tdvalue]
/*Done, idle and wait*/
adr x0, settings_gen_new_invbin_completed_msg
bl puts
bl keyboard_input
cbz w0, -4

/*Epilogue*/
settings_gen_new_inv_bin_epilogue:
epilogue 0, 0
