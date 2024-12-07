# Vega's Awesome Inventory Software (VAIS)

Author: Vega

Version: v0.4.2

This document is an overview of VAIS and of other documents present in this directory.

---

**What is VAIS?**

VAIS (pronounced "Vase") is basic inventory software that can be used on any modern Android phone. It is written in ARM64 Assembly Language.

---

**Why did you make VAIS?**

I use to work for an inventory company. This company contracted a Developer to create new and improved proprietary Inventory Software. Long story short, the Developer scammed the company and the final product was a disaster. However, the company refused to get rid of or fix the Software. Therefore, I've decided to write my own Software to prove to a few curious workers in the company how simple it is to create plain jane Inventory Software.

---

**Why write this in ARM64 Assembly??**

Since almost all modern Android phones run on ARM64, and most Inventory Software is meant to run on a cell phone, this was a perfect project to write in ARM64.

---

**Does VAIS need any unaffiliated/third-party software?**

Yes, it needs Termux's Version 119.0 ARM64 APK installed. A simple Google search will give you what you need. Instructions for a proper Termux install is found in the TERMUX.md document.

---

**What kind of hardware (i.e numberpad) does VAIS require?**

Most external numberpads (that are at least of the 21-key type) will work. Only caveat is that you must physically swap the ENTER and + buttons. See NUMPAD.md for more details.

---

**What kind of inventories can VAIS perform?**

For now, only plain jane financial inventories (manually enter price then manually enter quantity).

---

**What features does VAIS have?**

* No Lag, Lightweight, Uses Android
* Data itself can NEVER be lost
* Inventories can be started very quickly.
* Area, Location, & Cat combination & width settings
* Change mode allows for basic Area/Loc/Cat fixes (changes are basically instant)
* Files used are standard CSV's (any third party software on the planet can read these)
* Audio on/off settings
* Max/min price and quantity settings
* Supervisor Mode to restrict auditors from accessing certain Settings
* All entries have a record number attached
* All entries have a login attached
* All entries have a unique ID number
* All entires have a time stamp
* All entries will contain a Edited?, PriceBypassed?, and QtyBypassed? field.
* Can handle a max 131,072 linear entries.
* Can easily change + view Login at any time.

---

**What are some limitations of VAIS?**

Current limitations/cons:
* Financial Counts only
* Edit Mode is bare-bones (DC5 style)
* Data cannot be transmitted over the internet during an inventory
* Since there is no live-internet-connection, there's no warnings about being in somebody else's Location

---

**How is it possible that VAIS can never lose data?**

The CSV file is created on the phone once an inventory has been started. After every entry that is entered in by the auditor, the CSV file is immediately updated and synced. If VAIS powers off randomly, freezes, or the phone loses battery, it doesn't matter. All previous entered data (the CSV) still exists on the phone.

The only way to lose data, is for the auditor to literally lose or destroy the phone. Other than that, it's IMPOSSIBLE.

---

**How does one "Upload" an inventory?**

Once an auditor has finished counting, they will select the Finalize Inventory option at the Main Menu. Then press 7 to finalize to a Generic CSV. This will "strip" the CSV file (remove CSV entries marked as "DELETE!"). Once the auditor has completed this option, they can then power off VAIS. The final CSV file is now residing in the Termux directory, and the auditor will then move the CSV file out of the Termux directory and into the Phone's Download folder.

At this point, you now have regular phone access to the CSV file. The auditor can give it to your Supervisor via Teams, Discord, Skype, etc. Or you can plug the Phone into the Supervisor's Computer, and do simple drag and drop.

Keep in mind that the "Finalize" option is not needed when push comes to shove, but it does make things convenient. A supervisor/lead can open up an "unfinished" CSV and easily configure a option/parameter on Excel or Access to remove all the "DELETE!" CSV entries.

More information regarding Termux is in the TERMUX.md doc. More information specifically regarding moving files out of Termux is in the FIRST-TIME.md doc.

---

**How would a supervisor/lead perform a routine inventory setup/prep for VAIS?**

Read the PREP.md doc.

**Where is the source code and how do I compile it?**

The Source is located in the Source directory. Instructions to compile it for Android is in the ANDROID.md doc. Instructions to compile it for Linux-ARM64-QEMU (debugging purposes using QEMU and GDB) is in the QEMU.md doc.

---
