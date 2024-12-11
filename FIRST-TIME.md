# First Time VAIS Setup and Config

NOTICE: This guideline already assumes you have completed the TERMUX.md guide, and know how to run basic Termux commands. It also provides some training material for auditors.

NOTICE: First thing's first. You must physicall remove and switch the ENTER and PLUS buttons on your external numberpad. This places the keyboard into a configuration that is similiar to other past/historical Inventory machines. When entering in data outside of VAIS, use the PLUS button.

---

**How do I get VAIS on the phone?**

Connect the phone to your work computer, and drag+drop the following items to the phone's Download folder..

1. vais (the ~2MB executable)
2. beep.ogg
3. inventory.bin

Once completed, open up Termux on your phone and run the following commands to move the files into Termux...

*cd $HOME*
*mv ./storage/downloads/vais $HOME*
*mv ./storage/downloads/beep.ogg $HOME*
*mv ./storage/downloads/inventory.bin $HOME*

Once completed, run these commands to update the files' permissions....

*chmod 777 vais*
*chmod 777 beep.ogg*
*chmod 777 inventory.bin*

VAIS is now ready to be launched.

---

**How do I launch VAIS?**

With this simple Termux command...

*./vais*

---

**How does an Auditor give a Supervisor/Lead their finalized Inventory csv file?**

The csv file needs to be moved out of Termux into one of the phone's typical folders. The Download folder is preferred.

Here's the Termux command...
*mv *.csv ./storage/downloads/*

This will move all csv files to the Phone's Download folder. At this point the Auditor can send the file(s) via any typical method (Skype, Teams, Computer plug-in drag+drop, etc).

---

**Help! The auditor experienced a program crash while Finalizing data, and the CSV file isn't present in Termux!**

If this has occurred, it means VAIS ran into a program exception while deleted entries were being removed. Do NOT worry! There will be a new file present in Termux named as 00000000xxxxxxxx where the x's appear to be random numbers. The file will have no extension/type. This is a temp file. Get the temp file out of the phone and onto your work computer. Rename the temp file to anything.csv. After renaming, open this temp CSV using Microsoft Excel or Access. You will have to manually delete all the entries marked as "DELETE!". Afterwards the CSV is now finalized.

---

**Any other notes I need to be aware of??**

Yes!!

NOTE: Once the inventory has FULLY completed, the supervisor has recieved all auditors' CSV files, and the customer has been provided any data/totals they've required, the auditor(s) and/or supervisor(s) should wipe out all the csv files out of Termux if any are somehow still present. You can easily wipe the csv file(s) with this one command..

*rm *.csv*

IMPORTANT: If somehow an auditor or supervisor changes to a different directory in Termux, you can always navigate back to Termux's main/home directory via this command..

*cd $HOME*

IMPORTANT: Be sure the auditor knows how to properly exit Termux.

*exit*

---

Here's some tips to avoid weird errors/bugs...

1. Have the numeric pad plugged in BEFORE launching Termux. If not exit Termux (using the exit command!), plug in numpad, reopen Termux.
2. Regarding locking the screen to portrait or landscape mode, this needs to be initated while VAIS is already running. First, exit Termux if its open (using exit command!), and unlock the screen orientation on the phone. Now reopen Termux and launch VAIS. Afterwards, while VAIS is up, go to the phone's shortcut menu, and change the Screen Mode to be locked. VAIS's console/screen will now adjust.

Conclusion/Overview of how an Auditor uses VAIS:
1. Turn on Phone
2. Plug in Numeric Pad
3. Launch Termux
4. Launch VAIS
5. Place phone into Locked Screen mode
6. Ready for Inventory

Understand that moving the necessary program files into Termux and setting those files' permissions are a ONE-TIME ordeal. Once done, they do NOT need to be completed again.

Conclusion/Overview of "cleaning up" once Inventory is fully completed (csv files given, results given to customer)
1. Remove all csv files from Termux if somehow any are still present
2. Exit Termux using the exit command
3. Clear ALL the phone's memory
4. Power off phone. Pack up equipment
