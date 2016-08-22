class XComGameState_Unit_RookiePsiTraining extends XComGameState_BaseObject;

var name NewClassName;

simulated function EventListenerReturn RookiePsiTrainingCheck(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(GameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	GameState.AddStateObject(XComHQ);

	UnitState = XComGameState_Unit(GameState.GetGameStateForObjectID(XComGameState_Unit(EventData).ObjectID));

	if (UnitState.ObjectID != OwningObjectId || UnitState.GetRank() != 1 || (NewClassName == 'PsiOperative' && class'MCPL_Utilities'.static.IsRandomTreeTrainable(NewClassName)))
	{
		return ELR_NoInterrupt;
	}
	else if (NewClassName == 'PsiOperative')
	{
		UnitState.BuySoldierProgressionAbility(GameState, 0, 1);

		GameState.AddStateObject(UnitState);

		return ELR_NoInterrupt;
	}

	// Pretend the soldier never became a Psi Op
	UnitState.ResetRankToRookie();
	UnitState.ResetSoldierAbilities();
	UnitState.PsiAbilities.Length = 0;

	// Rank the soldier up with the assigned class
	UnitState.RankUpSoldier(GameState, NewClassName); // adds Squaddie abilities
	UnitState.ApplySquaddieLoadout(GameState, XComHQ);
	UnitState.ApplyBestGearLoadout(GameState); // Make sure the squaddie has the best gear available

	if (class'MCPL_Utilities'.static.IsRandomTreeTrainable(NewClassName))
	{
		UnitState.RollForPsiAbilities();
	}

	GameState.AddStateObject(UnitState);

	return ELR_NoInterrupt;
}