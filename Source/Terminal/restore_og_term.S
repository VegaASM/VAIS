.align 6
.globl restore_og_term
restore_og_term:

/*Prologue*/
prologue 0, 0

/*Set args and call tcsetattr*/
mov w0, stdin
mov w1, TCSANOW
add x2, masterptr, og_term_struct
bl tcsetattr

/*Epilogue*/
epilogue 0, 0
