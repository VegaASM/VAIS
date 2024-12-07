#include "Settings/settings_change_login.S"
#include "Settings/settings_max_min.S"
#include "Settings/settings_directories.S"
#include "Settings/settings_widths.S"
#include "Settings/settings_clear_data.S"
#include "Settings/settings_sync.S"
#include "Settings/settings_td.S"
#include "Settings/settings_audio.S"
#include "Settings/settings_more_info.S"
#include "Settings/settings_supervisor.S"

settings_main_msg:
.asciz "\x1B[2J\x1B[H1. Change Login\n2. Max/Min Values\n3. Directories\n4. Widths\n5. Clear Data\n6. Sync Settings\n7. Twin Digits\n8. Audio\n9. More Info\n0. Supervisor Mode\nESC. Go Back to Main Menu"

settings_perm_denied_msg:
.asciz "\x1B[2J\x1B[HAccess denied!\nContact your supervisor if you need to edit this feature.\nPress any key to go back to Settings Menu."

setting_options_address_lookup_table:
.xword settings_supervisor
.xword settings_change_login
.xword settings_max_min
.xword settings_directories
.xword settings_widths
.xword settings_clear_data
.xword settings_sync
.xword settings_td
.xword settings_audio
.xword settings_more_info

.align 6

.globl settings
settings:
/*Prologue*/
prologue 0, 0

/*Print settings main msg*/
settings_print_main_msg:
adr x0, settings_main_msg
bl puts
/*Read inputs*/
settings_main_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq settings_epilogue
cmp w0, ascii_0
blo 0xC
cmp w0, ascii_9
bls 0xC
bl beep
b settings_main_idle_loop
/*Convert ascii to int, check respective perm bit*/
and w0, w0, 0x0000000F
mov w1, 1
lsl w1, w1, w0
ldrh w2, [invbin_ptr, perms]
/*JUST INCASE sum1 manually fucked with the inv.bin incorrectly, always SET supervisor, clear-data, and more-info high!*/
mov w3, perms_always_high
orr w2, w2, w3
tst w2, w1 /*Check for high bit*/
beq settings_perm_denied

/*Perms allowed! Based on int, load up addr from table and branch to it*/
lsl w0, w0, 3
adr x1, setting_options_address_lookup_table
ldr x0, [x1, x0]
blr x0
b settings_print_main_msg

/*Epilogue*/
settings_epilogue:
mov w0, 0 /*tell main to NOT power off*/
epilogue 0, 0

/*Permission Denied*/
settings_perm_denied:
bl beep
adr x0, settings_perm_denied_msg
bl puts
bl keyboard_input
cbz w0, -4
b settings_print_main_msg
