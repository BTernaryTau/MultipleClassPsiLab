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

function int CalculatePointsToTrain(optional bool bClassTraining = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit;
	local LWTuple BirthdayTuple;
	local LWTValue Birthday;
	local int RankDifference;
	local bool bIsBirthday;
	
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	// Reduce training time by 20% if it's the player's birthday
	BirthdayTuple = new class'LWTuple';
	BirthdayTuple.Id = 'Birthday';
	`XEVENTMGR.TriggerEvent('Birthday', BirthdayTuple);
	bIsBirthday = BirthdayTuple.Data.Length == 1 && BirthdayTuple.Data[0].kind == LWTVBool && BirthdayTuple.Data[0].b;
	
	if (bClassTraining && bIsBirthday)
	{
		return XComHQ.GetPsiTrainingDays() * XComHQ.XComHeadquarters_DefaultPsiTrainingWorkPerHour * 24 * 0.8;
	}
	else if (bIsBirthday)
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(ProjectFocus.ObjectID));
		RankDifference = Max(iAbilityRank - Unit.GetRank(), 0);
		return (XComHQ.GetPsiTrainingDays() + Round(XComHQ.GetPsiTrainingScalar() * float(RankDifference))) * XComHQ.XComHeadquarters_DefaultPsiTrainingWorkPerHour * 24 * 0.8;
	}
	else if (bClassTraining)
	{
		return XComHQ.GetPsiTrainingDays() * XComHQ.XComHeadquarters_DefaultPsiTrainingWorkPerHour * 24;
	}
	else
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(ProjectFocus.ObjectID));
		RankDifference = Max(iAbilityRank - Unit.GetRank(), 0);
		return (XComHQ.GetPsiTrainingDays() + Round(XComHQ.GetPsiTrainingScalar() * float(RankDifference))) * XComHQ.XComHeadquarters_DefaultPsiTrainingWorkPerHour * 24;
	}
}