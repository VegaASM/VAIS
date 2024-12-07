#!/bin/bash

echo "Enter directory where vais project directory is at"
read vaisloc

echo "Enter directory Android NDK root (android-ndk-rXX) directory is at"
read androidloc

cd $androidloc/android-ndk-r27/toolchains/llvm/prebuilt/linux-x86_64/bin
./aarch64-linux-android35-clang -o $vaisloc/vais/vais -static $vaisloc/vais/Source/main.S

echo "Done. Did it work? Who knows."
