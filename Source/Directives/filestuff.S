/*Generic CSV file properties*/

/*CSV format (everything is chars)*/
/*7 bytes area
1 byte comma
7 bytes loc
1 byte comma
7 bytes cat
1 byte comma
32 bytes price (includes decimal pt)
1 byte comma
32 bytes qty (includes decimal pt)
1 byte comma
32 bytes cost (includes decimal pt)
1 byte comma
7 bytes login
1 byte comma
16 bytes record number
1 byte comma
19 bytes time stamp
1 byte comma
4 bytes: %20YES or %20%20No
1 byte comma
4 bytes: %20YES or %20%20No
1 byte comma
4 bytes: %20YES or %20%20No
1 byte comma
31 bytes uniqueID
1 byte enter (0xA)
Total bytes per entry is: 215*/

.set csv_entry_size, 215

/*includes spaces and respective trailing commas (cept for last entry, no comma ofc)*/
.set csv_area_size, 8
.set csv_loc_size, 8
.set csv_cat_size, 8
.set csv_price_size, 33
.set csv_qty_size, 33
.set csv_cost_size, 33 /*aka extended price*/
.set csv_login_size, 8
.set csv_recnum_size, 17
.set csv_time_size, 20
.set csv_eflag_size, 5
.set csv_pflag_size, 5
.set csv_qflag_size, 5
.set csv_uniqueid_size, 32 /*includes newline/enter byte*/

.set csv_go_from_price_to_login, (csv_price_size + csv_qty_size + csv_cost_size)
.set csv_go_from_login_to_next_entry, (csv_login_size + csv_recnum_size + csv_time_size + csv_eflag_size + csv_pflag_size + csv_qflag_size + csv_uniqueid_size)

/*Seek directives*/
.set SEEK_SET, 0
.set SEEK_CUR, 1
.set SEEK_END, 2

/*Raw/Direct File opening directives*/
.set O_RDONLY, 0
.set O_WRONLY, 1
.set O_RDWR, 2
.set O_CREAT, 0x40
.set O_APPEND, 0x400
.set O_NONBLOCK, 0x800
.set O_DSYNC, 0x1000
.set AT_FDCWD, -100 //if not working maybe its in octal hur dur!, yes this is negative

/*Raw/Direct File permission values*/
.set S_IRWXU, 00700
.set S_IRUSR, 00400
.set S_IWUSR, 00200
.set S_IXUSR, 00100
.set S_IRWXG, 00070
.set S_IRGRP, 00040
.set S_IWGRP, 00020
.set S_IXGRP, 00010
.set S_IRWXO, 00007
.set S_IROTH, 00004
.set S_IWOTH, 00002
.set S_IXOTH, 00001
