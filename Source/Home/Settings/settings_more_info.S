settings_more_info_msg:
.asciz "\x1B[2J\x1B[HVersion: v0.4.3\nRelease Date: Dec 10, 2024\nAuthor: Vega\nPress any key to go back to Settings Menu."

.align 6

.globl settings_more_info
settings_more_info:
prologue 0, 0
adr x0, settings_more_info_msg
bl puts
bl keyboard_input
cbz w0, -4
epilogue 0, 0
