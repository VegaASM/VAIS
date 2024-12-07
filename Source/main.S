/*NOTE : QEMU doesn't display printf immediately is there's no newline at every end, we have to call fflush(stdout). to prevent this, we MUST end printf with ENTER/newlinefeed
Therefore we call puts when we have no format specifiers*/

/*NOTE all bfc instructions are replaced with and equivalents so devices running on 8.0 and 8.1 can still run VAIS*/

#include "Directives/general.S"
#include "Directives/ascii.S"
#include "Directives/filestuff.S"

#include "Sound/beep.S"

#include "Keyboard/keyboard_input.S"

#include "Terminal/set_new_term_and_save_old.S"
#include "Terminal/restore_og_term.S"

#include "Other/get_time_in_nsecs.S" /*needs to be before finalize_inventory*/

#include "Home/FileHandling/dump_inventory_bin.S"
#include "Home/FileHandling/prep_synced_csv.S" /*needs to be before any func/file that uses csv_header_size*/
#include "Home/FileHandling/write_csv_line.S"
#include "Home/FileHandling/delete_csv_line.S"
#include "Home/FileHandling/dc5_csv.S"
#include "Home/continue_inventory.S"
#include "Home/start_new_inventory.S"
#include "Home/finalize_inventory.S"
#include "Home/settings.S"
#include "Home/power_off.S"

#include "Home/Char/remove_all_spaces.S"

main_menu_msg: /*Hides the cursor as well for rest of time til program powers off*/
.asciz "\x1B[2J\x1B[H\x1B[?25lWelcome to VAIS! (v0.4.1)\nCurrent Login: %s\n\n1. Start New Inventory\n2. Continue Inventory\n3. Finalize Inventory\n4. Settings\n5. Power Off\n"
poweroff_msg:
.asciz "\x1B[2J\x1B[H\x1B[?25hVAIS has been powered off."

func_table:
.xword start_new_inventory
.xword continue_inventory
.xword finalize_inventory
.xword settings
.xword power_off

.align 6

.section .text
.globl main
main:
/*Prologue*/
prologue 10, 0x150

/*Set the master pointer*/
add masterptr, sp, 0x10

/*Set linear record number ZERO*/
mov recordnum, 0

/*Set in_edit_mode_flag LOW*/
str xzr, [masterptr, in_editmode_flag]

/*Set finalize flag high because we dont need any checks for poweroff if an inventory wasn't even started*/
mov x0, 1
str x0, [masterptr, finalizeflag]

/*Change the terminal to semi-raw*/
bl set_new_term_and_save_old

/*NEW NOTE set terminal to reset at exit*/
/*bl make_at_exit*/

/*Dump inventory.bin*/
bl dump_inventory_bin
cbnz x0, dump_invbin_error_occurred

/*Get raw time and save it as serial num*/
add x0, masterptr, serialnum
bl time

/*Check if Login starts with NULL byte, if so use default login*/
ldrb w0, [invbin_ptr, login]
cbz w0, use_default_login
b call_printf_for_login_creds

/*Set Login to Default (USER001)*/
use_default_login:
movz x0, 0x0031, lsl 48 //little endian...
movk x0, 0x3030, lsl 32
movk x0, 0x5245, lsl 16
movk x0, 0x5355
str x0, [invbin_ptr, login]

/*Clear the screen, reset cursor position, hide the cursor, Print the Login*/
call_printf_for_login_creds:
add x1, invbin_ptr, login
adr x0, main_menu_msg
bl printf

/*Idle and poll keyboard input for ASCII 1,2,3,4, and 5*/
main_poll_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
/*Based on index call func*/
cmp w0, ascii_1
blo 0xC
cmp w0, ascii_5
bls 0xC
bl beep
b main_poll_loop
/*based on number enter, grab func from func table and call it*/
and w0, w0, 0x0000000F /*change ascii to int*/
sub w0, w0, 1 /*change int to index number*/
lsl w0, w0, 3 /*multiply index by 8 to get func addr within table to load*/
adr x1, func_table
ldr x0, [x1, x0]
blr x0
/*If zero returned go back to main idle, if not zero, end program*/
cbz w0, call_printf_for_login_creds

/*Set standard "power off" msg to print in OG terminal after alt buffer is shutdown*/
adr x19, poweroff_msg

/*Restore Original TermIOS struct*/
restore_termios_struct:
bl restore_og_term

/*Final msg. Also restore cursor*/
mov x0, x19
bl puts

/*Main's epilogue, End the Program (exit (0))*/
mov w0, 0
epilogue 10, 0x150

/*Backup msg to print since an error occurred on inv.bin, we need msg to be printed in main terminal, not alt buffer*/
dump_invbin_error_occurred:
mov x19, x0
b restore_termios_struct
