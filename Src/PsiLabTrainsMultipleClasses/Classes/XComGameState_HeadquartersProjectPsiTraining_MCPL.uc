class XComGameState_HeadquartersProjectPsiTraining_MCPL extends XComGameState_HeadquartersProjectPsiTraining;

var() name NewClassName; // the name of the class the soldier will eventually be promoted to if they're a rookie

function SetProjectFocus(StateObjectReference FocusRef, optional XComGameState NewGameState, optional StateObjectReference AuxRef)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_GameTime TimeState;

	History = `XCOMHISTORY;
	ProjectFocus = FocusRef; // Unit
	AuxilaryReference = AuxRef; // Facility

	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ProjectFocus.ObjectID));

	// If the soldier is still a rookie (if they aren't, the ability will be assigned from the player's choice)
	if (UnitState.GetRank() == 0)
	{
		NewClassName = XComGameState_Unit_RookiePsiTraining(UnitState.FindComponentObject(class'XComGameState_Unit_RookiePsiTraining')).NewClassName;

		// If the rookie is training to be a random tree Psi Operative, randomly choose a branch and ability from the starting two tiers of the Psi Op tree
		if (NewClassName == 'PsiOperative' && class'MCPL_Utilities'.static.IsRandomTreeTrainable(NewClassName))
		{
			iAbilityRank = `SYNC_RAND(2);
			iAbilityBranch = `SYNC_RAND(2);
			ProjectPointsRemaining = CalculatePointsToTrain(true);
		}
		// If the rookie is training to be another random tree class, just choose the first ability for now
		else if (class'MCPL_Utilities'.static.IsRandomTreeTrainable(NewClassName))
		{
			iAbilityRank = 0;
			iAbilityBranch = 0;
			ProjectPointsRemaining = CalculatePointsToTrain(true);
		}
		// If the rookie is training to be an ordered tree class, just choose the first ability
		else if (class'MCPL_Utilities'.static.IsOrderedTreeTrainable(NewClassName))
		{
			iAbilityRank = 0;
			iAbilityBranch = 0;
			ProjectPointsRemaining = CalculatePointsToTrain(true);
		}
		// The rookie seems to be being previewed
		else
		{
			ProjectPointsRemaining = CalculatePointsToTrain(true);
		}
	}
	else
	{
		ProjectPointsRemaining = CalculatePointsToTrain();
	}

	InitialProjectPoints = ProjectPointsRemaining;

	UpdateWorkPerHour(NewGameState); 
	TimeState = XComGameState_GameTime(History.GetSingleGameStateObjectForClass(class'XComGameState_GameTime'));
	StartDateTime = TimeState.CurrentTime;

	if (`STRATEGYRULES != none)
	{
		if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(TimeState.CurrentTime, `STRATEGYRULES.GameTime))
		{
			StartDateTime = `STRATEGYRULES.GameTime;
		}
	}

	if (class'MCPL_Defaults'.default.DebugMode)
	{
		CompletionDateTime = StartDateTime;
	}
	else if(MakingProgress())
	{
		SetProjectedCompletionDateTime(StartDateTime);
	}
	else
	{
		// Set completion time to unreachable future
		CompletionDateTime.m_iYear = 9999;
	}
}