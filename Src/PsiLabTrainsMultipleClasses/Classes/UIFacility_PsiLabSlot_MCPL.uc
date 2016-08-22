// This class does nothing right now
class UIFacility_PsiLabSlot_MCPL extends UIFacility_PsiLabSlot;

simulated function OnPersonnelSelected(StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit Unit;
	local UIScreen NewScreen;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));

	if (Unit.GetSoldierClassTemplateName() == 'PsiOperative' && class'MCPL_Utilities'.static.IsRandomTreeTrainable('PsiOperative'))
	{
		`HQPRES.UIChoosePsiAbility(UnitInfo.UnitRef, StaffSlotRef);
	}
	else if (Unit.GetRank() == 0)
	{
		if (`HQPRES.ScreenStack.IsNotInStack(class'UIChoosePsiClass_MCPL'))
		{
			NewScreen = `HQPRES.Spawn(class'UIChoosePsiClass_MCPL', `HQPRES);
			UIChoosePsiClass_MCPL(NewScreen).m_UnitRef = UnitInfo.UnitRef;
			UIChoosePsiClass_MCPL(NewScreen).m_StaffSlotRef = StaffSlotRef;
			`HQPRES.ScreenStack.Push(NewScreen);
		}
	}
	else
	{
		if (`HQPRES.ScreenStack.IsNotInStack(class'UIChoosePsiAbility_MCPL'))
		{
			NewScreen = `HQPRES.Spawn(class'UIChoosePsiAbility_MCPL', `HQPRES);
			UIChoosePsiAbility_MCPL(NewScreen).m_UnitRef = UnitInfo.UnitRef;
			UIChoosePsiAbility_MCPL(NewScreen).m_StaffSlotRef = StaffSlotRef;
			`HQPRES.ScreenStack.Push(NewScreen);
		}
	}
}