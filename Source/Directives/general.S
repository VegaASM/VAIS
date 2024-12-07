/*Register Alias for "Super" Global Registers*/
masterptr .req x28 /*ptr to some important stuff that sits in main stack buffer*/
invbin_ptr .req x27 /*Pointer to inventory.bin*/
dataentry_ptr .req x26 /*Pointer to 1st data entry*/
curdataentry_ptr .req x25 /*Pointer to next usable data entry spot*/
recordnum .req x24 /*Current entry number; first record uses value 1; includes invalid entries as well*/

/*Commonly referenced integers that can be written via one mov instruction*/
.set entriesamt, 0x20000 /*max entries/recordnums possible*/
.set FIELD_MAX, 13 /*TODO make this 32 in future*/

.set termios_size, 60 /*0x3C, NOTE if this fails in future switch back to 128 (0x80)*/
.set TCSANOW, 0 /*For tcsetattr func*/

/*Master ptr's offsets*/
.set serialnum, 0
.set finalizeflag, serialnum + 0x8
.set in_editmode_flag, finalizeflag + 0x8 /*Hacky whatever, lets write_entry func know whenever we are in edit mode*/
.set enddataentry_ptr, in_editmode_flag + 0x8 /*No entry can have a ptr higher than this*/
.set og_term_struct, enddataentry_ptr + 0x8 /*buffer space*/
.set alt_term_struct, og_term_struct + 0x40 /*buffer space*/
.set keyboard_buffer, alt_term_struct + 0x40 /*buffer space*/
.set fdstorespot, keyboard_buffer + 0x10
.set csvfilename, fdstorespot + 0x8

/*Inventory.bin structure, this region of memory contains some current attributes for live inventory and contains various settings*/
.set login, 0 /*chars*/
.set maxprice, 0x8 /*double float*/
.set minprice, 0x10 /*double float*/
.set maxqty, 0x18 /*double float*/
.set minqty, 0x20 /*double float*/
.set arealoccatflags, 0x28 /*bit 2 area, bit 1 loc, bit 0 cat*/
.set areawidth, 0x29 /*unsigned int*/
.set locwidth, 0x2A /*unsigned int*/
.set catwidth, 0x2B /*unsigned int*/
.set area, 0x30 /*chars*/
.set loc, 0x38 /*chars*/
.set cat, 0x40 /*chars*/
.set soundkeyflags, 0x48 /*byte; 0x00 = no sound, 0x01 = sound*/
.set tdvalue, 0x49 /*byte; 00 = don't check td's, 01 = check td's*/
.set perms, 0x4A /*halfword, see settings_supervisor.S for bit details*/

/*Inventory.bin perm masks*/
.set perms_supervisor, 0x0001 /*unused*/
.set perms_login, 0x0002
.set perms_maxmin, 0x0004
.set perms_directs, 0x0008
.set perms_widths, 0x0010
.set perms_cleardata, 0x0020 /*unused*/
.set perms_sync, 0x0040
.set perms_tds, 0x0080
.set perms_audio, 0x0100
.set perms_moreinfo, 0x0200 /*unused*/
.set perms_all, 0x3FF
.set perms_always_high, (perms_supervisor | perms_cleardata | perms_moreinfo) /*Mask for force setting unused bits high*/

/*Inventory.bin perm bits*/
.set permsB_supervisor, 0 /*unused*/
.set permsB_login, 1
.set permsB_maxmin, 2
.set permsB_directs, 3
.set permsB_widths, 4
.set permsB_cleardata, 5 /*unused*/
.set permsB_sync, 6
.set permsB_tds, 7
.set permsB_audio, 8
.set permsB_moreinfo, 9 /*unused*/

/*Total inventory.bin size*/
.set invbin_size, (perms + 2)

/*Raw data entry Offsets*/
.set d_vflag, 0 /*0x00 = invalid, 0x01 = valid*/
.set d_eflag, 0x1 /*0x00 = unedited, 0x01 = edited*/
.set d_pflag, 0x2 /*0x00 = no limit bypass, 0x01 = limit bypassed*/
.set d_qflag, 0x3 /*0x00 = no limit bypass, 0x01 = limit bypassed*/
.set d_tdflag, 0x4 /*NOTE Unused*/
.set d_login, 0x8 /*chars*/
.set d_area, 0x10 /*chars*/
.set d_loc, 0x18 /*chars*/
.set d_cat, 0x20 /*chars*/
.set d_price, 0x28 /*double float*/
.set d_qty, 0x30 /*double float*/
.set d_cost, 0x38 /*double float*/
.set d_record, 0x40 /*unsigned double word int*/
.set d_time, 0x48 /*unsigned double word int*/

/*Raw data entry important values*/
.set databin_entry_size, d_time + 8
.set databin_max_entries, 0x20000
.set databin_max_size, databin_entry_size * databin_max_entries

/*syscall symbols*/
.set ioctl_sc, 29
.set read_sc, 63

/*termios struct flags*/
.set ECHO, 0x8
.set ICANON, 0x2

/*st fd's*/
.set stdin, 0
.set stdout, 1
.set stderr, 2

.set init_stack_size, csvfilename + 0x38 + 0xA0
.set align_init_stack_size, init_stack_size & 0xF
.if (align_init_stack_size != 0)
        .error "Error! Initial/Main Stack Buffer size is not 16-byte aligned!"
.endif

/*Useful macros for prologues and epilogues*/
/*The 2 Macros always starts the buffer space ptr at (sp + 0x10)*/
/*regs is for GPRs only*/
.macro prologue regs, buffer
        .if      (\regs < 0 || \regs > 10)
                .error "Error! Too many non-volatile registers used or a negative amount was used!"
        .endif

        .if      (\buffer < 0)
                .error "Error! Buffer size is negative!"
        .endif

        .set stacksize, (\regs << 3) + \buffer + 16
        .set alignsize, stacksize & 0xF

        .if (alignsize != 0)
                .error "Error! Buffer size is not 16-byte aligned!"
        .endif

        stp fp, lr, [sp, -stacksize]!
        .if     (\regs == 0)
                mov fp, sp
                .exitm
        .elseif     (\regs == 1)
                str x19, [sp, stacksize - 8]
        .elseif (\regs == 2)
                stp x19, x20, [sp, stacksize - 16]
        .elseif (\regs == 3)
                stp x19, x20, [sp, stacksize - 24]
                str x21, [sp, stacksize - 8]
        .elseif (\regs == 4)
                stp x19, x20, [sp, stacksize - 32]
                stp x21, x22, [sp, stacksize - 16]
        .elseif (\regs == 5)
                stp x19, x20, [sp, stacksize - 40]
                stp x21, x22, [sp, stacksize - 24]
                str x23, [sp, stacksize - 8]
        .elseif (\regs == 6)
                stp x19, x20, [sp, stacksize - 48]
                stp x21, x22, [sp, stacksize - 32]
                stp x23, x24, [sp, stacksize - 16]
        .elseif (\regs == 7)
                stp x19, x20, [sp, stacksize - 56]
                stp x21, x22, [sp, stacksize - 40]
                stp x23, x24, [sp, stacksize - 24]
                str x25, [sp, stacksize - 8]
        .elseif (\regs == 8)
                stp x19, x20, [sp, stacksize - 64]
                stp x21, x22, [sp, stacksize - 48]
                stp x23, x24, [sp, stacksize - 32]
                stp x25, x26, [sp, stacksize - 16]
        .elseif (\regs == 9)
                stp x19, x20, [sp, stacksize - 72]
                stp x21, x22, [sp, stacksize - 56]
                stp x23, x24, [sp, stacksize - 40]
                stp x25, x26, [sp, stacksize - 24]
                str x27, [sp, stacksize - 8]
        .else
                stp x19, x20, [sp, stacksize - 80]
                stp x21, x22, [sp, stacksize - 64]
                stp x23, x24, [sp, stacksize - 48]
                stp x25, x26, [sp, stacksize - 32]
                stp x27, x28, [sp, stacksize - 16]
        .endif
        mov fp, sp
.endm

.macro epilogue eregs, ebuffer
        .if      (\eregs < 0 || \eregs > 10)
                .error "Error! Too many non-volatile registers used or a negative amount was used!"
        .endif

        .if      (\ebuffer < 0)
                .error "Error! Buffer size is negative!"
        .endif

        .set estacksize, (\eregs << 3) + \ebuffer + 16
        .set ealignsize, estacksize & 0xF

        .if (ealignsize != 0)
                .error "Error! Buffer size is not 16-byte aligned!"
        .endif

        .if     (\eregs == 0)
                ldp fp, lr, [sp], estacksize
                ret
                .exitm
        .elseif (\eregs == 1)
                ldr x19, [sp, estacksize - 8]
        .elseif (\eregs == 2)
                ldp x19, x20, [sp, estacksize - 16]
        .elseif (\eregs == 3)
                ldr x21, [sp, estacksize - 8]
                ldp x19, x20, [sp, estacksize - 24]
        .elseif (\eregs == 4)
                ldp x21, x22, [sp, estacksize - 16]
                ldp x19, x20, [sp, estacksize - 32]
        .elseif (\eregs == 5)
                ldr x23, [sp, estacksize - 8]
                ldp x21, x22, [sp, estacksize - 24]
                ldp x19, x20, [sp, estacksize - 40]
        .elseif (\eregs == 6)
                ldp x23, x24, [sp, estacksize - 16]
                ldp x21, x22, [sp, estacksize - 32]
                ldp x19, x20, [sp, estacksize - 48]
        .elseif (\eregs == 7)
                ldr x25, [sp, estacksize - 8]
                ldp x23, x24, [sp, estacksize - 24]
                ldp x21, x22, [sp, estacksize - 40]
                ldp x19, x20, [sp, estacksize - 56]
        .elseif (\eregs == 8)
                ldp x25, x26, [sp, estacksize - 16]
                ldp x23, x24, [sp, estacksize - 32]
                ldp x21, x22, [sp, estacksize - 48]
                ldp x19, x20, [sp, estacksize - 64]
        .elseif (\eregs == 9)
                ldr x27, [sp, estacksize - 8]
                ldp x25, x26, [sp, estacksize - 24]
                ldp x23, x24, [sp, estacksize - 40]
                ldp x21, x22, [sp, estacksize - 56]
                ldp x19, x20, [sp, estacksize - 72]
        .else
                ldp x27, x28, [sp, estacksize - 16]
                ldp x25, x26, [sp, estacksize - 32]
                ldp x23, x24, [sp, estacksize - 48]
                ldp x21, x22, [sp, estacksize - 64]
                ldp x19, x20, [sp, estacksize - 80]
        .endif
        ldp fp, lr, [sp], estacksize
        ret
.endm
