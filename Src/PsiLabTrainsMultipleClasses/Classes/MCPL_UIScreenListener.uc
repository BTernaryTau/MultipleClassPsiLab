class MCPL_UIScreenListener extends UIScreenListener;

var bool PushingScreen; // Prevents infinite recursion of OnLoseFocus

event OnInit(UIScreen Screen)
{
	local UIChoosePsiAbility_MCPL NewScreen;

	// If either a UIChoosePsiAbility_MCPL or a UIChoosePsiClass_MCPL has been initialized, a dialog box was partially removed
	if (UIChoosePsiAbility_MCPL(Screen) != none || UIChoosePsiClass_MCPL(Screen) != none)
	{
		`HQPRES.Get2DMovie().DialogBox.RemoveDialog(); // since the dialog box is now initialized, it can be fully removed
	}
	// Replace the current screen if it is a UIChoosePsiAbility and psi operatives are an ordered tree class
	else if (UIChoosePsiAbility(Screen) != none && class'MCPL_Utilities'.static.IsOrderedTreeTrainable('PsiOperative'))
	{
		`HQPRES.ScreenStack.Pop(Screen);
		NewScreen = `HQPRES.Spawn(class'UIChoosePsiAbility_MCPL', `HQPRES);
		NewScreen.m_UnitRef = UIChoosePsiAbility(Screen).m_UnitRef;
		NewScreen.m_StaffSlotRef = UIChoosePsiAbility(Screen).m_StaffSlotRef;
		PushingScreen = true;
		`HQPRES.ScreenStack.Push(NewScreen);
		PushingScreen = false;
	}
}

event OnLoseFocus(UIScreen Screen)
{
	local UIDialogueBox DialogBox;
	local TDialogueBoxData DialogData;
	local XComGameState_Unit UnitState;
	local UIScreen NewScreen;

	// The dialog for training psi ops doesn't seem to trigger ScreenListeners properly, so let's check for a UIFacility_PsiLab losing focus instead
	if (UIFacility_PsiLab(Screen) != none && !PushingScreen) // Also make sure this isn't just the call for us creating a screen
	{
		DialogBox = `HQPRES.Get2DMovie().DialogBox;

		// Check to see if the dialog box we want exists
		foreach DialogBox.m_arrData(DialogData)
		{
			if (DialogData.strTitle == class'UIFacility_PsiLabSlot'.default.m_strPsiTrainingDialogTitle)
			{
				// Retrieve the soldier to be psi trained
				UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UICallbackData_StateObjectReference(DialogData.xUserData).ObjectRef.ObjectID));

				// Create a UIChoosePsiClass_MCPL if the soldier is a rookie and the screen doesn't already exist
				if (UnitState.GetRank() == 0 && `HQPRES.ScreenStack.IsNotInStack(class'UIChoosePsiClass_MCPL'))
				{
					DialogBox.RemoveDialog(); // this hides the dialog box, but because it's not initialized, it doesn't remove it properly
					NewScreen = `HQPRES.Spawn(class'UIChoosePsiClass_MCPL', `HQPRES);
					UIChoosePsiClass_MCPL(NewScreen).m_UnitRef = UICallbackData_StateObjectReference(DialogData.xUserData).ObjectRef;
					UIChoosePsiClass_MCPL(NewScreen).m_StaffSlotRef = UIFacility_PsiLab(Screen).m_kStaffSlotContainer.m_kPersonnelDropDown.SlotRef;
					PushingScreen = true;
					`HQPRES.ScreenStack.Push(NewScreen);
					PushingScreen = false;
				}
				// Create a UIChoosePsiAbility_MCPL if the soldier is not a rookie and the screen doesn't already exist
				else if (`HQPRES.ScreenStack.IsNotInStack(class'UIChoosePsiAbility_MCPL'))
				{
					DialogBox.RemoveDialog(); // this hides the dialog box, but because it's not initialized, it doesn't remove it properly
					NewScreen = `HQPRES.Spawn(class'UIChoosePsiAbility_MCPL', `HQPRES);
					UIChoosePsiAbility_MCPL(NewScreen).m_UnitRef = UICallbackData_StateObjectReference(DialogData.xUserData).ObjectRef;
					UIChoosePsiAbility_MCPL(NewScreen).m_StaffSlotRef = UIFacility_PsiLab(Screen).m_kStaffSlotContainer.m_kPersonnelDropDown.SlotRef;
					PushingScreen = true;
					`HQPRES.ScreenStack.Push(NewScreen);
					PushingScreen = false;
				}
			}
		}
	}
}

event OnRemoved(UIScreen Screen)
{
	// Remove XComGameState_Unit_RookiePsiTraining for any soldiers that were dismissed
	if (UIArmory_Mainmenu(Screen) != none)
    {
		class'MCPL_Utilities'.static.GarbageCollectRookiePsiTraining();
	}
}