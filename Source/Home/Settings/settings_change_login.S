.data
settings_change_login_msg:
.asciz "\x1B[2J\x1B[HPress ESC at any time to go back to Settings Menu.\n\nCurrent Login is %s\n\nEnter New Login:        \n"
end_of_login_msg:
.text
.align 6

.globl settings_change_login
settings_change_login:
/*Prologue*/
prologue 0, 0

/*Grab ptr to login, print it*/
settings_print_login:
add x1, invbin_ptr, login
adr x0, settings_change_login_msg
bl printf
/*Now wait on user to fill in Login then press Enter*/
wait_for_new_login_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq scl_epilogue
cmp w0, ascii_enter
beq scl_check_field
cmp w0, ascii_plus
beq scl_check_field
cmp w0, DELETE
beq scl_erase_char
cmp w0, ascii_Z
bhi do_scl_beep
cmp w0, ascii_0
blo do_scl_beep
cmp w0, ascii_A
bhs scl_insert_char
cmp w0, ascii_9
bls scl_insert_char
do_scl_beep:
bl beep
b wait_for_new_login_idle_loop

/*Epilogue*/
scl_epilogue:
/*reset the writable field*/
adr x0, end_of_login_msg-9
movz x2, 0x0A20, lsl 48 //ugh little endian, need the enter for the flush
movk x2, 0x2020, lsl 32
movk x2, 0x2020, lsl 16
movk x2, 0x2020
str x2, [x0]
epilogue 0, 0

/*Char stuff*/
scl_insert_char:
adr x1, end_of_login_msg-9
mov w2, 7
bl insert_char
cbz w0, settings_print_login
b wait_for_new_login_idle_loop
scl_erase_char:
adr x0, end_of_login_msg-9
mov w1, 7
bl erase_char
cbz w0, settings_print_login
b wait_for_new_login_idle_loop
scl_check_field:
adr x0, end_of_login_msg-9
mov w1, 7
bl enter_field
cbnz w0, wait_for_new_login_idle_loop
/*Write new login to inv.bin*/
adr x0, end_of_login_msg-9
ldr x1, [x0]
/*atm login ends in \n, must end in null byte*/
and x1, x1, 0x00FFFFFFFFFFFFFF
str x1, [invbin_ptr, login]
/*reset the writable field*/
movz x2, 0x0A20, lsl 48 //ugh little endian, need the enter for the flush
movk x2, 0x2020, lsl 32
movk x2, 0x2020, lsl 16
movk x2, 0x2020
str x2, [x0]
b settings_print_login
