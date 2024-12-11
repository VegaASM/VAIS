# History of Releases

---

This does NOT include any revisions.

---

**Version 0.4.3**
* Moved inventory.bin verifications out from the Continue Inventory function and placed it as its own function after reading inventory.bin into the Program's memory.
* Added more verifications (and appropriate fixes if applicable) to inventory.bin once it's been read by the Program.
* Fixed bug where Edit Mode wouldn't fully delete a record if you weren't the record's applicable area + location + category
* Fixed bug where a deleted record would be left in the finalized CSV if the inventory ended with consecutive (2+) deleted records

**Version 0.4.2**
* Fixed some awkward navigation in regards to Edit Mode and Change Mode

**Version 0.4.1**
* All records now have a time stamp

**Version 0.4**
* Can now choose to export CSVs that are compatible with JB's custom United Software

**Version 0.3**
* Added Supervisor Mode (ability to selectively restrict Settings from regular Users)
* Can now write/update inventory.bin from VAIS (new Sync option within Settings)
* Removed "Generate default Inventory.bin" option from Settings
* Fixed bug where program would hang if an auditor attempted to finalize an inventory that wasn't started yet
* Added check to where an Auditor cannot choose "Choose Inventory" if an inventory wasn't started yet, and if an auditor already finalized (finished) an inventory
* Fixed bug where alternating between addition and multiplication chain-counts would cause a program fault
* Completed order of operations (add, sub, mulli, divide are 100% functional with any combination of mixing)
* Fixed bug where negative quantities would be logged in as zero's

**Version 0.2.1**
* Implemented Twin Digit checks
* Fixed bug where price/qty warning prompts would remain up while live inventory main menu was the true menu running
* Field gets auto cleared if max/min/td value is declined
* Removed excessive spacing in max/min/td prompts, and in edit mode
* Fixed bug that blocked Capital letter entries into Login and Directory entries

**Version 0.2:**
* Auditor no longer has to export/save data proactively. Data is auto-saved (written to file) after every entry, and after any modification to any entry. Therefore, it's impossible to lose Data.
* Fixed bug where VAIS would crash in Edit Mode if a Location was deleted

**Version 0.1:**
* Initial Release
