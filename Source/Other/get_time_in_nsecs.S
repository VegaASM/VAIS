.set CLOCK_MONOTONIC_RAW, 4

clock_error_msg:
.asciz "Error! Can't get raw Clock time. Contact the Developer. Program has been halted. You must force shut it down."

.align 6
.globl get_time_in_nsecs
get_time_in_nsecs:
/*Prologue*/
prologue 0, 0x10

mov w0, CLOCK_MONOTONIC_RAW
add x1, sp, 0x10
bl clock_gettime
tbnz w0, 31, clock_error

/*x0 = secs, x1 = nano remainder*/
ldp x0, x1, [sp, 0x10]

/*Set x1 to 1,000,000,000 (billion)*/
movz w2, 0x3B9A, lsl 16
movk w2, 0xCA00

/*Convert secs to nanoseconds and then add nanosecond remainder
Total Nanos = (secs * billon) + nanos*/
madd x0, x0, x2, x1

/*Epilogue*/
epilogue 0, 0x10

/*Error*/
clock_error:
adr x0, clock_error_msg
bl puts
b 0 //halt for now
