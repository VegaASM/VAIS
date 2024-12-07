# How to Audit/Count

For Auditors. This assumes the Auditor already knows how to launch both Termux and VAIS.

---

**Starting an Inventory**

Once you have booted VAIS, you first want to change the Login to what you are assigned to by your Supervisor/Lead.

Press 5 for Settings. Then press 1 for Change Login. Type in the your Login and then hit Enter/Plus button. New Login is now applied.

Press ESC to exit the Change Login screen. Press ESC again to exit back to Main Menu.

Unless instructed by your Supervisor/Lead, all new Inventories start with the "Start New Inventory" option. Press 1 to select it. Press 1 again to confirm that you do indeed want to start a new Inventory.

You will be prompted about clearing data, press 7 for Yes. This will reset the Inventory totals.

At this point, depending on the how the Lead has configured the Settings, you will either be at the screen to enter Area or Location. Enter the Area/Location. At this point, you will enter in any other fields that may appear (Loc and/or Cat).

After this, you will be at the Live inventory screen. The top row will tell you what current Area , Loc, and/or Cat you are in. If a field is not being utilized, it will be left Blank, this is normal.

The 2nd row shows the current price you have temporarily entered.
The 3rd row shows the current qty you have temporarily entered.

Below that are all the financial totals and other keys to go to other menus.

You will notice a double arrow symbol to the right of the Price field, This cursor lets you know which field you are currently typing in. It can only be in price field, or the qty field. Never in both.

---

**How to do a simple entry**

To begin an inventory entry, you start by typing in the price of the item. You will see your price data fill into the field as you type it out. Once you have fully typed the price in, press the Enter button to move down to the Qty field. You will notice the Qty field will now contain the double arrow symbol indicating you are in said field.

Now type in the amount of the product you see. Once you have typed out that amount, press Enter. This new inventory entry will be logged in. You will see the cursor move back up to the price field and both fields are cleared. You will also notice the totals update in accordance to what you've just entered in. You are now ready to log in another entry.

IMPORTANT: You will NEVER need to type in the dot/period for the price. The dot always remains present in the price field. Therefore it's impossible to specify anything smaller than a penny. If you attempt to type a dot in the price field, the machine will reject it, then beep.

---

**Basic Field Navigation**

If you are in the price field, and hit the ESC button, you will exit the live inventory screen. Any temporary data in the price or qty fields are cleared.

If you are in the qty field and hit ESC, you will see the cursor move back up the price field, and the temp data in the Qty field *ONLY* is cleared. Data in the price field remains intact. Since you are now at the price field, if you hit ESC again, you exit the Live Inventory.

If you are in the price field and hit Enter, as long as there is some price present, you will be navigated to the Qty field. If not, the machine will beep at you, and nothing happens.

If you are in the qty field and hit Enter, the data is written to the inventory. If there is no data in the Qty field, then a qty of 1 is used for the entry. If you hit any other button (other than ESC) on a blank qty field, the machine will beep and nothing will happen.

---

**Fast Single Value Counts**

Due to the fact that if you enter in a blank qty, a value of 1 is written for the entry, you can use this feature for fast single value counts. Something such as a Grocery Store Meat Inventory where every price of a product is different would be a prefect candidate for this feature.

---

**Chain counting**

Sometimes it's faster to type in small quantities of a product instead of counting it all out "in your head" and then hitting the final quantity that you see. Let's say you see some soda bottles on a shelf. There are 15 bottles present. Due to the arrangement of the bottles, it may be faster to count it "as you see it". Let's say the bottles are broken up in groups of 4, 2, 9. Let's also say the price of this soda bottle is $1.99. Here's how to chain count the bottles...

First, type in the price (1.99) and hit enter.
Type in 4 and hit the plus button, you will notice a plus symbol will be appended to the 4 in the Qty field (4+)
Now type in 2. At this moment you will see "4+2". Now hit the plus symbol.
You will see the machine change the "4+2" to "6+". Notice how the machine did the addition for you!
Now type 9. At this moment you have "6+9". Hit plus again and you will see "15+"

Great, we have the total of 15 that we want. All you need to do now is hit Enter. The data will be logged in, both fields are cleared, and you are ready for another entry.

---

**Chain counting without "breaks"**

It is possible to chain together separate entries. Therefore you don't need to hit Enter after a basic chain count to start a new inventory entry. Let's say we have the follow entries with chain counts to log into the machine...

$1.99: 4, 2, 9
$4.79: 5, 5, 3
$2.50: 7, 2

The 1.99 values are what we've just covered from earlier (the soda bottles). So to recap, you would type this..

199 (no need to type the dot), 4 + 2 + 9

However, instead hitting enter once we reached 15+ on the Qty field, you can instead start typing the next item's price (4.79).

Therefore type: 479

At this moment you will see this in the Qty field...
15+479

Now hit the Enter button, what watch occurs. The 1.99 x 15 entry will be logged in, and then the "479" portion is moved up to the price field. Afterwards the Qty field is cleared, and the cursor (double arrow symbol) remains pointed at the Qty field.

So after hitting Enter, your price and qty fields are this...
Price: 4.79
  Qty:      <<

Notice how you can now start a brand new chain count! Okay now type in the chain count for the $4.79 item...
5 + 5 + 3

At this moment the Qty field will display "13+", now start typing in the final price ($2.50). Qty field is now this...
"13+250"

Hit Enter, the 4.79 x 13 entry will be logged in, 2.50 is placed into the Price field, Qty field cleared, and cursor remains at Qty field.

Finally finish our last chain count in the Qty field....
7 + 2

Qty field will read as "9+". To complete this entry, simply hit Enter. Both fields are cleared and you're done! Congratz, counting like a Pro!

---

**Other Order of Operations:**

You should notice by now the Plus button is used for addition and will append a + symbol the value in the Qty field as long as a value exists (if not, Machine beeps). The divide, multiple, and subtraction keys on your numpad also 100% work.

Example: Chain count a 5.99 priced item with 6 times 3 times 2 (36 total).

First type the price: 599. Hit enter to go to the Qty field, and type 6. Now press the times key (*), your Qty field is now this....
"6*"

Now type 3 and hit the times button again, Qty field is now this...
"18*"

Notice how the machine did the multiplication for you! Okay great, now type 2...
"18*2"

Now hit the times button again. You now have this...
"36*"

You can now press enter and the 5.99 x 36 entry will be logged in. This same concept works for division (the "/" key) and subtraction (the "-" key). You can mix in different operations (5 + 4 * 7). This will do...
(5+4) * 7

Which results in a total of 63.

NOTE: Order of Operations only works in the Quantity field! Hitting any Math key while in the Price field will result in the machine beeping and nothing will occur.

---

**Crate Counting**

When counting end displays (end-caps) or pallets of items, there is a method to quickly counting the "crate" of items as long as the "crate" is whole (no items removed).

Let's say we have an pallet of Twinky Boxes. The pallet is "even/whole" and no boxes are missing. Every "row" has the same amoutn of boxes. Let's say each row contains 14 boxes. The pallet has 12 rows for its height. A beginner auditor might do this...

14+14+14+14+.......

...til they hit all 12 rows and then hit Enter. This is a time waster. You can instead do multiple the amount in a single row with the total rows of the pallet. Therefore you just need to type...

14*12

Then hit times again....

168*

and finally hit Enter. That's it. Super simple.

---

**More Menus**

VAIS includes two menus within the Live Inventory to use just in case you made some mistakes during the inventory. To go into this menu, press the Tab button at any time. Keep in mind any temp data in price/qty fields are cleared.

At this point, you can either press..

* ESC to go back to Live Inventory
* 7 to enter into Edit Mode
* 8 to enter into Change Mode

---

**Edit Mode**

This mode allows you to see all your previous (non-deleted) records. You can only view one entry at a time. You are limited to deleting one entry at a time. Also, you can edit any entry.

---

**Change Mode**

This mode allows you to delete any Area, Loc, or Cat. You also have the ability to change an area/loc/cat to a new number. It's important to note that all operations are localized (non-global). No idea what that means? For example, let's say you have a Location 0004 within Area 0005 and another Location 0004 within Area 0012. If you enter into change Mode while in Area 0005 and you select "Delete Loc 0004". It will only delete Loc 0004 entries that were done under Area 0005. All Loc 0004 entries under Area 0012 are left alone. These localized effects also take place for deletions. Obviously, Areas themselves can't be localized as they are the "highest" out of the 3 fields.

---

**How to enter negative prices and quantities**

First off, negative prices cannot be entered in since Math keys are disabled (will beep) if hit while in Price field. Only negative quantities can be entered in. To enter a negative quantity, read below...

Example: Quantity of -5
Assume price has been entered in and you are now typing within the quantity field.
* Type in 0
* Now type in the negative value (-5)
* At this moment Qty field will be "0-5"
* Press any math-type key (plus, minus, multiple, divide). Assume we use plus for the next point
* At this moment Qty field will be "-5+"
* Simply enter in the Qty now. You may be prompted about going below the minimum qty limit.

Since negative prices can't be put in the literal sense, here's how to enter in a negative price given from a client.
Example: Price of -244.09
* Enter price as a positive number into the price field "244.09", hit Enter
* Now at quantity field, do the steps (from earlier) to enter in negative 1 (-1).
* Enter in the -1 quantity.
