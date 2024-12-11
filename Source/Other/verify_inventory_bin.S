invalid_multi_msg:
.asciz "\x1B[2J\x1B[HError! Multiple items in the Inventory.bin file are invalid and were thus changed to their backup/default values. View INVALID.md for more details.\nPress any key to continue."
invalid_login_msg:
.asciz "\x1B[2J\x1B[HError! An Invalid Login was detected. The Login was changed to USER001.\nPress any key to continue."
invalid_area_loc_flags_msg:
.asciz "\x1B[2J\x1B[HError! Both Area and Location are disabled. Therefore Location has been enabled.\nPress any key to continue."
invalid_area_width_msg:
.asciz "\x1B[2J\x1B[HError! Area has an applied invalid width. It has been set to 4.\nPress any key to continue."
invalid_loc_width_msg:
.asciz "\x1B[2J\x1B[HError! Location has an applied invalid width. It has been set to 4.\nPress any key to continue."
invalid_cat_width_msg:
.asciz "\x1B[2J\x1B[HError! Category has an applied invalid width. It has been set to 3.\nPress any key to continue."
invalid_maxmin_price_msg:
.asciz "\x1B[2J\x1B[HError! Max Price is lower than Min Price. Therefore the Max Price parameter has been removed.\nPress any key to continue."
invalid_maxmin_qty_msg:
.asciz "\x1B[2J\x1B[HError! Max Qty is lower than Min Qty. Therefore the Max Qty parameter has been removed.\nPress any key to continue."

.align 6
.globl verify_inventory_bin
verify_inventory_bin:
/*Prologue*/
prologue 0, 0

/*Set register to hold amount of invalids found*/
mov w9, 0

/*Check for Invalid Login*/
ldr x1, [invbin_ptr, login]
tst x1, 0xFF00000000000000
bne invalid_login /*Last byte (first byte in register) should be null*/
add x3, invbin_ptr, login
mov w2, 7
invalid_login_verification_loop:
ldrb w0, [x3], 1
cmp w0, ascii_Z
bhi invalid_login
cmp w0, ascii_0
blo invalid_login
cmp w0, ascii_A
bhs valid_login
cmp w0, ascii_9
bhi invalid_login
valid_login:
subs w2, w2, 1
bne invalid_login_verification_loop
b verify_area_loc_flags

/*Invalid Login Found, fix it*/
invalid_login:
.set default_login, 0x0031303052455355 /*USER001\0*/
movz x0, :abs_g3:default_login
movk x0, :abs_g2_nc:default_login
movk x0, :abs_g1_nc:default_login
movk x0, :abs_g0_nc:default_login
str x0, [invbin_ptr, login]
add w9, w9, 1
adr x10, invalid_login_msg

/*An Area or Location HAS to be enabled*/
verify_area_loc_flags:
ldrb w0, [invbin_ptr, arealoccatflags]
tst w0, 0x6
bne verify_max_min_price

/*Neither area nor loc are enabled, this is invalid, fix it*/
orr w0, w0, 0x3 /*Force enable location*/
strb w0, [invbin_ptr, arealoccatflags]
add w9, w9, 1
adr x10, invalid_area_loc_flags_msg

/*Is Max Price lower min price?**/
verify_max_min_price:
ldr d0, [invbin_ptr, maxprice]
ldr d1, [invbin_ptr, minprice]
fcmp d0, d1
bhs verify_max_min_qty

/*Fix it*/
movi d0, 0
str d0, [invbin_ptr, maxprice]
add w9, w9, 1
adr x10, invalid_maxmin_price_msg

/*is Max Qty lower min qty?*/
verify_max_min_qty:
ldr d0, [invbin_ptr, maxqty]
ldr d1, [invbin_ptr, minqty]
fcmp d0, d1
bhs verify_area_width

/*Fix it*/
movi d0, 0
str d0, [invbin_ptr, maxqty]
add w9, w9, 1
adr x10, invalid_maxmin_qty_msg

/*Get Area width*/
verify_area_width:
ldrb w0, [invbin_ptr, areawidth]
cmp w0, 7
bhi invalid_area_width
cmp w0, 0
bhi verify_loc_width

/*Fix it*/
invalid_area_width:
mov w0, 4
strb w0, [invbin_ptr, areawidth]
add w9, w9, 1
adr x10, invalid_area_width_msg

/*Get Loc width*/
verify_loc_width:
ldrb w0, [invbin_ptr, locwidth]
cmp w0, 7
bhi invalid_loc_width
cmp w0, 0
bhi verify_cat_width

/*Fix it*/
invalid_loc_width:
mov w0, 4
strb w0, [invbin_ptr, locwidth]
add w9, w9, 1
adr x10, invalid_loc_width_msg

/*Get Cat width*/
verify_cat_width:
ldrb w0, [invbin_ptr, catwidth]
cmp w0, 7
bhi invalid_cat_width
cmp w0, 0
bhi done_verifying

/*Fix it*/
invalid_cat_width:
mov w0, 3
strb w0, [invbin_ptr, catwidth]
add w9, w9, 1
adr x10, invalid_cat_width_msg

/*Done, no need to check sound, td, or perms due to how those items are checked/read in other parts of this Program*/
done_verifying:
cbz w9, verify_inv_bin_epilogue
cmp w9, 1
bhi print_the_multi_msg
mov x0, x10
b print_verify_result_msg
print_the_multi_msg:
adr x0, invalid_multi_msg
print_verify_result_msg:
bl puts
bl keyboard_input
cbz w0, -4

/*Epilogue*/
verify_inv_bin_epilogue:
epilogue 0, 0
