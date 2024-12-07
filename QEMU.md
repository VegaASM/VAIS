# Debugging Overview

This document will contain basic notes on how to compile and debug on a computer. This document assumes you already have the ARM64 Compiler, QEMU, and GDB installed. It also assumes you know how to operate these programs.

---

**How to compile the Source for a Linux Computer:**

cd Source
aarch64-linux-gnu-gcc -ggdb3 -o dvais -static main.S

NOTE: dvais stands for desktop vais
NOTE: Alternatively, you can run the assembleD.sh script...

chmod +x assembleD.sh
./assembleD.sh

---

**How to Debug:**

Step 1: Run dVAIS with QEMU (process will stall, this is normal)
qemu-aarch64 -g 1234 ./dvais

Step 2: While leaving Step 1's Terminal intact, open a different terminal in same directory and run this GDB command..
gdb-multiarch -q --nh \
  -ex 'set architecture aarch64' \
  -ex 'file dvais' \
  -ex 'target remote localhost:1234' \
  -ex 'break main' \
  -ex continue \
  -ex 'layout split' \
  -ex 'layout regs'
