#!/bin/bash

cd Source

aarch64-linux-gnu-gcc -ggdb3 -o dvais -static main.S

mv ./dvais ..
