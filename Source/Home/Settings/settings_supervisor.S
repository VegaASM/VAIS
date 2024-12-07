.data
settings_supervisor_passcode_msg:
.asciz "\x1B[2J\x1B[HPress ESC at any time to go back to Settings Menu.\nEnter Supervisor Passcode:        "
end_of_ssp_msg:

settings_supervisor_perm_table_msg:
.ascii "\x1B[2J\x1B[HPress the respective key to allow/disallow a Setting.\n* Symbol indicates ALLOW\nPress 0 to ALLOW all\n"
suloginspot: /*Space next to each number is for asterisk gets writen to*/
.ascii " 1.Login\n"
sumaxminspot:
.ascii " 2.Max/Mins\n"
sudirectspot:
.ascii " 3.Directories\n"
suwidthsspot:
.ascii " 4.Widths\n"
susyncspot:
.ascii " 6.Sync Settings\n"
sutdsspot:
.ascii " 7.TD's\n"
suaudiospot:
.asciz " 8.Audio"
.text

.set login_str_offset, suloginspot - settings_supervisor_perm_table_msg
.set maxmin_str_offset, sumaxminspot - settings_supervisor_perm_table_msg
.set direct_str_offset, sudirectspot - settings_supervisor_perm_table_msg
.set width_str_offset, suwidthsspot - settings_supervisor_perm_table_msg
.set sync_str_offset, susyncspot - settings_supervisor_perm_table_msg
.set td_str_offset, sutdsspot - settings_supervisor_perm_table_msg
.set audio_str_offset, suaudiospot - settings_supervisor_perm_table_msg

settings_supervisor_denied_msg:
.asciz "\x1B[2J\x1B[HIncorrect Passcode!\nPress any key to go back to Settings Menu."

.set sv_login, 0x003130524F534956 /*VISOR01 in little endian*/

.align 6

.globl settings_supervisor
settings_supervisor:
/*Prologue*/
prologue 1, 8

/*Print shit*/
settings_supervisor_print_passcode_msg:
adr x0, settings_supervisor_passcode_msg
bl puts
ssp_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq settings_supervisor_epilogue
cmp w0, ascii_enter
beq ssp_check_field
cmp w0, ascii_plus
beq ssp_check_field
cmp w0, DELETE
beq ssp_erase_char
cmp w0, ascii_Z
bhi do_ssp_beep
cmp w0, ascii_0
blo do_ssp_beep
cmp w0, ascii_A
bhs ssp_insert_char
cmp w0, ascii_9
bls ssp_insert_char
do_ssp_beep:
bl beep
b ssp_idle_loop

/*Char stuff*/
ssp_insert_char:
adr x1, end_of_ssp_msg-8
mov w2, 7
bl insert_char
cbz w0, settings_supervisor_print_passcode_msg
b ssp_idle_loop
ssp_erase_char:
adr x0, end_of_ssp_msg-8
mov w1, 7
bl erase_char
cbz w0, settings_supervisor_print_passcode_msg
b ssp_idle_loop
ssp_check_field:
adr x0, end_of_ssp_msg-8
mov w1, 7
bl enter_field
cbnz w0, ssp_idle_loop
/*reset the fillable passocde field*/
adr x0, end_of_ssp_msg-8
ldr x1, [x0] /*For checking passcode*/
movz x2, 0x0020, lsl 48 //ugh little endian
movk x2, 0x2020, lsl 32
movk x2, 0x2020, lsl 16
movk x2, 0x2020
str x2, [x0]

/*Check passcode*/
movz x3, :abs_g3:sv_login
movk x3, :abs_g2_nc:sv_login
movk x3, :abs_g1_nc:sv_login
movk x3, :abs_g0_nc:sv_login
cmp x1, x3
beq settings_supervisor_write_astis

/*Bad passcode*/
bl beep
adr x0, settings_supervisor_denied_msg
bl puts
bl keyboard_input
cbz w0, -4

/*Epilogue*/
settings_supervisor_epilogue:
/*Reset fillable passcode field just in case it wasnt resettted earlier*/
adr x0, end_of_ssp_msg-8
movz x2, 0x0020, lsl 48 //ugh little endian
movk x2, 0x2020, lsl 32
movk x2, 0x2020, lsl 16
movk x2, 0x2020
str x2, [x0]
epilogue 1, 8

/*Calc what asti's to write*/
settings_supervisor_write_astis:
/*
bit 0 supervisor; unused
bit 1 login
bit 2 maxmin's
bit 3 directories
bit 4 widths
bit 5 clear data; unused
bit 6 sync
bit 7 td's
bit 8 login
bit 9 more info
*/
adr x0, settings_supervisor_perm_table_msg
ldrh w1, [invbin_ptr, perms]
mov w2, ascii_mulli
mov w3, ascii_space

/*Because Clang sucks, I have to do this...*/
mov w4, login_str_offset
mov w5, maxmin_str_offset
mov w6, direct_str_offset
mov w7, width_str_offset
mov w8, sync_str_offset
mov w9, td_str_offset
mov w10, audio_str_offset

/*Write astis*/
tbz w1, permsB_login, 0xC
strb w2, [x0, x4]
b 0x8
strb w3, [x0, x4]
tbz w1, permsB_maxmin, 0xC
strb w2, [x0, x5]
b 0x8
strb w3, [x0, x5]
tbz w1, permsB_directs, 0xC
strb w2, [x0, x6]
b 0x8
strb w3, [x0, x6]
tbz w1, permsB_widths, 0xC
strb w2, [x0, x7]
b 0x8
strb w3, [x0, x7]
tbz w1, permsB_sync, 0xC
strb w2, [x0, x8]
b 0x8
strb w3, [x0, x8]
tbz w1, permsB_tds, 0xC
strb w2, [x0, x9]
b 0x8
strb w3, [x0, x9]
tbz w1, permsB_audio, 0xC
strb w2, [x0, x10]
b 0x8
strb w3, [x0, x10]
/*Print the bullshit*/
bl puts
/*Read keyhits*/
supervisor_perm_screen_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq settings_supervisor_epilogue
cmp w0, ascii_0
beq allow_everything
cmp w0, ascii_8
bhi su_perm_screen_asti_beep
cmp w0, ascii_5
beq su_perm_screen_asti_beep
cmp w0, ascii_1
bhs 0xC //1 thru 3, 5 thru 8 found!
su_perm_screen_asti_beep:
bl beep
b supervisor_perm_screen_idle_loop

/*GENIUS MOVE!*/
/*Change ascii to int, use int to edit perms byte*/
and w0, w0, 0xF
/*Set default mask1*/
mov w1, 1 //set default bit to shift
/*Generate mask1*/
lsl w1, w1, w0 //generate mask from bit
/*Load perms value*/
ldrh w2, [invbin_ptr, perms] //grab perms value
/*Extract respective bit out of perms value*/
and w3, w2, w1 //Extract respective bit out of perms value
/*Flip the bits value and remove all other 31 unrelated bits*/
bic w3, w1, w3 /*andc AND w/ Complement*/
/*Remove respective bit value from perms value*/
bic w2, w2, w1 /*andc AND w/ Complement*/
/*Place in new bit value into perms value*/
orr w2, w2, w3
/*Store new perms value*/
strh w2, [invbin_ptr, perms]
/*Update string to reprint*/
b settings_supervisor_write_astis

allow_everything:
mov w0, perms_all
strh w0, [invbin_ptr, perms]
b settings_supervisor_write_astis
