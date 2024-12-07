# How to compile VAIS (for android)

---

**Step 1: Get Android NDK**

Link - https://developer.android.com/ndk/downloads

Download the zip package for Linux 64-bit(x86). Extract the download at a desired location (i.e. $HOME). A new folder called "android-ndk-r27" will be created with all the NDK contents in it.

---

**Step 2: Compile the Source**

Make the script assemble.sh executable, then run it.
* chmod +x ./assemble.sh
* ./assemble.sh

The vais executable will now be at the vais project directory.

If the script doesn't work, do this...

Run this terminal command (assumes you've extracted the Android NDK zip at $HOME directory)

cd $HOME/android-ndk-r27/toolchains/llvm/prebuilt/linux-x86_64/bin

Now run this terminal command (assumes vais is at /home/yourusername)..

./aarch64-linux-android35-clang -o /home/yourusername/vais/vais -static /home/yourusername/vais/Source/main.S

