Steam page: https://steamcommunity.com/sharedfiles/filedetails/?id=717567622

Allows the Psi Lab to train classes besides the vanilla Psi Operative.

By default, the only change this mod will make is replacing the dialog box for training a rookie into a Psi Operative with a class selection window. However, the list of classes that can be trained in the Psi Lab is editable using [Mod Config Menu](http://steamcommunity.com/sharedfiles/filedetails/?id=667104300) or by following [these instructions](http://steamcommunity.com/workshop/filedetails/discussion/717567622/358416640402200718/). If changes were made in-game using Mod Config Menu, restart the game, and it should now be possible to train the class or classes you added in the Psi Lab.

#### Recommended Companion Mods
* [Mod Config Menu](http://steamcommunity.com/sharedfiles/filedetails/?id=667104300) provides an in-game menu that can be used to configure this mod
* [Disable Any Class](http://steamcommunity.com/sharedfiles/filedetails/?id=656267587) can be used to prevent classes trainable in the Psi Lab from appearing as promotions, rewards, or purchases; note that it currently uses [Mod Options Menu](http://steamcommunity.com/sharedfiles/filedetails/?id=652998069]), not Mod Config Menu

#### Known Issues
* The UI makes a lot of references to Psi Operatives even when a different class is being trained
* The continue training button currently leads to the armory instead of the Psi Lab for classes besides Psi Operatives
* When set to one perk per rank, the Psi Operative tree has a few issues, such as allowing Schism to be trained when Insanity and Void Rift weren’t

#### Compatibility
* Currently incompatible with Long War 2; this might be fixed in the future
* Overwrites the FillFn, ShouldDisplayToDoWarningFn, and IsUnitValidForSlotFn delegates for the 'PsiChamberSoldierStaffSlot' X2StaffSlotTemplate
* Currently has no class overrides, though some extensions of classes are used in place of the vanilla ones when training other classes
* A few screens are entirely replaced by custom ones using ScreenListeners
* [Grimy's Class Rebalance](http://steamcommunity.com/sharedfiles/filedetails/?id=693319658) breaks this mod if loaded after it; if loaded first, everything works except for the cap on Psi Operative abilities

#### Possible Future Changes
* Allow classes to train all of their perks in a random order, like the Psi Operative does (partially implemented)