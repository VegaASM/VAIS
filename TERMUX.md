# Instructions and information regarding Termux

---

**What is Termux?**

Termux is a Linux-style command line emulator for Android phones.

---

**How I do install Termux?**

First you need to get the ARM64 Version 119.0 APK. A quick google search will provide what you need. Once downloaded, using whatever personal method you prefer, place this apk into the Download folder of your Android phone.

Next, on your phone, touch on the apk file to install it. Your phone will gripe about the dangers of installing APK's. Proceed past all the warnings, and complete the installation. Your phone may require you to enable APK installations in the Phone's settings before attempting to install the Termux APK.

---

**Do I need "root access" to install Termux? What other requirements are to be met before installing?**

NO, you do NOT need root access. The only other requirement is that your phone runs on the ARM64/ARMv8 architecture, which is virtually every modern Android phone.

---

**I've installed Termux, now what do I do?**

Open up Termux. Type the following and press/touch Enter to clear the screen

*clear*

This is a basic Termux/Terminal command. Google "basic Linux Terminal commands" for more info. It's not too hard to pick up. There is a cheat sheet at the end of this document if you need it.

Now type and enter the following commands to update Termux...

*pkg update*
*pkg upgrade*

You may get a notification about Mirrors, this is fine, let Termux do its thing. It will temp select one for you and then proceed with the updates & upgrades.

Now type this command...

*pkg install nano binutils pulseaudio*

This will install some packages that we need. After that has completed, type this command...

*termux-setup-storage*

You may get a gripe about permissions and what not, simply enable/allow permissions to everything/everywhere.

Great! Termux has been installed and configured.

---

**IMPORTANT: Read this**

To properly exit out of the Termux app, you MUST type in this command

*exit*

If you simply try clearing Termux from your phone's memory (via typical swiping), it will NOT close Termux. It is still running in the background.

---

**Termux commmand cheat sheet**

*clear* = Clear screen
*exit* = Exit Termux (clearing the Phone's memory will NOT exit Termux!!!)
*cd $HOME* = No matter where you are at, you will navigate back to the Termux main/home directory
*pkg update* = Update your repo's information to the Mirror
*pkg upgrade* = Update your installed packages/software
*pkg install <package name>* = Install a package
*pkg remove <package name>* = Remove a package
*ls* = Show files and folders in current folder/directory
*ls -l* Same as above but provides the file's & folder's permissions
*cd <folder name>* = Replace folder name and the carrot symbosl with the folder name you just to navigate to.
*cd ..* = Go up to parent folder
*mkdir <new folder name>* = Make a new folder
*rm <file name>* = Removes a file only if you have the permissions to do so
*rm -r <folder name>* Removes a folder and any contents within it
*./<file name>* = NOTICE the dot at the start, it represents "HERE". This is needed for this particular command, this will execute/launch a file only if it has execute permissions
*chmod +x <filename>* = Makes a file have execution permissions
*chmod 777 <filename>* = Makes a file have read, write, and execution permissions universally
*cp <source path to file> <dest path to move file to>* = Copy paste's a file from one folder to another
*mv <source path to file> <dest path to move file to>* = move's a file from one folder to another
*mv oldfilename newfilename* = Rename a file
*mv oldfolder newfolder* = Rename a folder/directory

How paths work:
. = HERE/current workign dicreotry
/ = Root (This is NOT Home/Main), this is the Root directory to your phone
$HOME = Home/Main Directory of Termux

Example: Move example.txt from $HOME/folder1 to $HOME when you are already in the $HOME directory. Both commands function exactly the same.
mv folder1/example.txt $HOME
mv ./folder1/example.txt $HOME

