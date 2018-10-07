class MCPL_Utilities extends Object;

static function bool IsOrderedTreeTrainable(name DataName)
{
	return class'MCPL_MCMListener'.default.OrderedTreeTrainableClasses.Find(DataName) != INDEX_NONE;
}

static function bool IsRandomTreeTrainable(name DataName)
{
	return class'MCPL_MCMListener'.default.RandomTreeTrainableClasses.Find(DataName) != INDEX_NONE;
}

static function bool IsTrainable(name DataName)
{
	return IsOrderedTreeTrainable(DataName) || IsRandomTreeTrainable(DataName);
}

static function FillPsiChamberSoldierSlot(XComGameState NewGameState, StateObjectReference SlotRef, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit NewUnitState;
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_HeadquartersXCom NewXComHQ;
	local XComGameState_HeadquartersProjectPsiTraining ProjectState;
	local StateObjectReference EmptyRef;
	local int SquadIndex;

	class'X2StrategyElement_DefaultStaffSlots'.static.FillSlot(NewGameState, SlotRef, UnitInfo, NewSlotState, NewUnitState);

	if (NewUnitState.GetRank() == 0) // If the Unit is a rookie, start the project to train them as a Psi Operative
	{
		NewUnitState.SetStatus(eStatus_PsiTesting);

		NewXComHQ = class'X2StrategyElement_DefaultStaffSlots'.static.GetNewXComHQState(NewGameState);

		ProjectState = XComGameState_HeadquartersProjectPsiTraining_MCPL(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectPsiTraining_MCPL'));
		NewGameState.AddStateObject(ProjectState);
		ProjectState.SetProjectFocus(UnitInfo.UnitRef, NewGameState, NewSlotState.Facility);

		NewXComHQ.Projects.AddItem(ProjectState.GetReference());

		// If the unit undergoing training is in the squad, remove them
		SquadIndex = NewXComHQ.Squad.Find('ObjectID', UnitInfo.UnitRef.ObjectID);
		if (SquadIndex != INDEX_NONE)
		{
			// Remove their gear
			NewUnitState.MakeItemsAvailable(NewGameState, false);

			// Remove them from the squad
			NewXComHQ.Squad[SquadIndex] = EmptyRef;
		}
	}
	else // The unit is either starting or resuming an ability training project, so set their status appropriately
	{
		NewUnitState.SetStatus(eStatus_PsiTraining);
	}
}

static function bool ShouldDisplayPsiChamberSoldierToDoWarning(StateObjectReference SlotRef)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_StaffSlot SlotState;
	local XComGameState_Unit Unit;
	local StaffUnitInfo UnitInfo;
	local int i;

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	SlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(SlotRef.ObjectID));

	for (i = 0; i < XComHQ.Crew.Length; i++)
	{
		UnitInfo.UnitRef = XComHQ.Crew[i];
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Crew[i].ObjectID));

		if (IsLW2Present() && Unit.GetSoldierClassTemplateName() == 'PsiOperative' && IsUnitValidForPsiChamberSoldierSlotLW2(SlotState, UnitInfo))
		{
			return true;
		}
		else if (!IsLW2Present() && Unit.GetSoldierClassTemplateName() == 'PsiOperative' && IsUnitValidForPsiChamberSoldierSlot(SlotState, UnitInfo))
		{
			return true;
		}
	}

	return false;
}

static function bool IsUnitValidForPsiChamberSoldierSlot(XComGameState_StaffSlot SlotState, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit Unit; 
	local X2SoldierClassTemplate SoldierClassTemplate;
	local SCATProgression ProgressAbility;
	local name AbilityName;
	`LOG("My IsUnitValidForPsiChamberSoldierSlot has been called", true, 'MultipleClassPsiLab');
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));

	if (Unit.IsASoldier()
		&& !Unit.IsInjured()
		&& !Unit.IsTraining()
		&& !Unit.IsPsiTraining()
		&& !Unit.IsPsiAbilityTraining()
		&& !Unit.CanRankUpSoldier()) // Don't let any soldier train if they're awaiting a promotion
	{
		// Rookies can be trained as long as at least one class is trainable in the Psi Lab
		if ((class'MCPL_MCMListener'.default.RandomTreeTrainableClasses.Length > 0 || class'MCPL_MCMListener'.default.OrderedTreeTrainableClasses.Length > 0) && Unit.GetRank() == 0)
		{
			return true;
		}
		// Psi Ops can train until they learn all abilities if they're enabled as a random tree class
		else if (Unit.GetSoldierClassTemplateName() == 'PsiOperative' && IsRandomTreeTrainable('PsiOperative'))
		{
			SoldierClassTemplate = Unit.GetSoldierClassTemplate();
			foreach Unit.PsiAbilities(ProgressAbility)
			{
				AbilityName = SoldierClassTemplate.GetAbilityName(ProgressAbility.iRank, ProgressAbility.iBranch);
				if (AbilityName != '' && !Unit.HasSoldierAbility(AbilityName))
				{
					return true; // If we find an ability that the soldier hasn't learned yet, they are valid
				}
			}
		}
		// Random tree classes can train until they learn all abilities
		else if (IsRandomTreeTrainable(Unit.GetSoldierClassTemplateName()))
		{
			// Generate a random list of abilities if it doesn't already exist
			if (Unit.PsiAbilities.Length == 0)
				Unit.RollForPsiAbilities();

			SoldierClassTemplate = Unit.GetSoldierClassTemplate();
			
			foreach Unit.PsiAbilities(ProgressAbility)
			{
				AbilityName = SoldierClassTemplate.GetAbilityName(ProgressAbility.iRank, ProgressAbility.iBranch);

				if (AbilityName != '' && !Unit.HasSoldierAbility(AbilityName))
				{
					return true; // If we find an ability that the soldier hasn't learned yet, they are valid
				}
			}
		}
		// Ordered tree classes can train until they're colonels (or whatever their max rank is)
		else if (IsOrderedTreeTrainable(Unit.GetSoldierClassTemplateName()) && Unit.GetRank() < GetMaxRankForClass(Unit.GetSoldierClassTemplateName()))
		{
			return true;
		}
	}

	return false;
}

static function bool IsUnitValidForPsiChamberSoldierSlotLW2(XComGameState_StaffSlot SlotState, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit Unit; 
	local X2SoldierClassTemplate SoldierClassTemplate;
	local SCATProgression ProgressAbility;
	local name AbilityName;
	`LOG("My IsUnitValidForPsiChamberSoldierSlotLW2 has been called", true, 'MultipleClassPsiLab');
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));

	if (Unit.GetStatus() == eStatus_OnMission) // needed to work with infiltration system
	{
		return false;
	}

	if (Unit.CanBeStaffed()
		&& Unit.IsASoldier()
		&& !Unit.IsInjured()
		&& !Unit.IsTraining()
		&& !Unit.IsPsiTraining()
		&& !Unit.IsPsiAbilityTraining())
	{
		`LOG("1", true, 'MultipleClassPsiLab');
		// Rookies can be trained as long as at least one class is trainable in the Psi Lab and they're not awaiting a promotion
		if ((class'MCPL_MCMListener'.default.RandomTreeTrainableClasses.Length > 0 || class'MCPL_MCMListener'.default.OrderedTreeTrainableClasses.Length > 0) && Unit.GetRank() == 0 && !Unit.CanRankUpSoldier())
		{
			`LOG("2", true, 'MultipleClassPsiLab');
			return true;
		}
		// Psi Ops follow standard LW2 behavior if they're enabled as a random tree class
		else if (Unit.GetSoldierClassTemplateName() == 'PsiOperative' && IsRandomTreeTrainable('PsiOperative'))
		{
			`LOG("3", true, 'MultipleClassPsiLab');
			SoldierClassTemplate = Unit.GetSoldierClassTemplate();
			if (CanRankUpPsiSoldier(Unit))
			{
				`LOG("4", true, 'MultipleClassPsiLab');
				foreach Unit.PsiAbilities(ProgressAbility)
				{
					AbilityName = SoldierClassTemplate.GetAbilityName(ProgressAbility.iRank, ProgressAbility.iBranch);
					if (AbilityName != '' && !Unit.HasSoldierAbility(AbilityName))
					{
						`LOG("5", true, 'MultipleClassPsiLab');
						return true; // If we find an ability that the soldier hasn't learned yet, they are valid
					}
				}
			}
		}
		// Random tree classes can train until they learn all abilities
		else if (IsRandomTreeTrainable(Unit.GetSoldierClassTemplateName()))
		{
			`LOG("6", true, 'MultipleClassPsiLab');
			// Generate a random list of abilities if it doesn't already exist
			if (Unit.PsiAbilities.Length == 0)
				Unit.RollForPsiAbilities();

			SoldierClassTemplate = Unit.GetSoldierClassTemplate();
			
			foreach Unit.PsiAbilities(ProgressAbility)
			{
				AbilityName = SoldierClassTemplate.GetAbilityName(ProgressAbility.iRank, ProgressAbility.iBranch);

				if (AbilityName != '' && !Unit.HasSoldierAbility(AbilityName))
				{
					`LOG("7", true, 'MultipleClassPsiLab');
					return true; // If we find an ability that the soldier hasn't learned yet, they are valid
				}
			}
		}
		// Ordered tree classes can train until they're colonels (or whatever their max rank is)
		else if (IsOrderedTreeTrainable(Unit.GetSoldierClassTemplateName()) && Unit.GetRank() < GetMaxRankForClass(Unit.GetSoldierClassTemplateName()))
		{
			`LOG("8", true, 'MultipleClassPsiLab');
			return true;
		}
	}
	`LOG("9", true, 'MultipleClassPsiLab');
	return false;
}

// Taken from Utilities_PP_LW
static function bool CanRankUpPsiSoldier(XComGameState_Unit Unit)
{
	local int NumKills;
	local XComLWTuple Tuple; // LWS  added

	if (Unit.GetSoldierRank() + 1 < `GET_MAX_RANK && !Unit.bRankedUp)
	{
		NumKills = Unit.GetNumKills();

		//  Increase kills for WetWork bonus if appropriate
		NumKills += Round(Unit.WetWorkKills * class'X2ExperienceConfig'.default.NumKillsBonus);
		
		//  Add number of kills from assists
		NumKills += Unit.GetNumKillsFromAssists();

		// Add required kills of StartingRank
		NumKills += class'X2ExperienceConfig'.static.GetRequiredKills(Unit.StartingRank);

		//LWS set up a Tuple -- false means roll AWC ability as usual, true means skip it
		Tuple = new class'XComLWTuple';
		Tuple.Id = 'GetNumKillsForRankUpSoldier';
		Tuple.Data.Add(1);
		Tuple.Data[0].kind = XComLWTVInt;
		Tuple.Data[0].i = 0;

		//LWS add hook for modifying the number of effective kills for leveling up purposes, accessible by DLC/mod
		`XEVENTMGR.TriggerEvent('GetNumKillsForRankUpSoldier', Tuple, Unit);
		if (Tuple.Data[0].kind == XComLWTVInt)
			NumKills += Tuple.Data[0].i;

		if (	NumKills >= class'X2ExperienceConfig'.static.GetRequiredKills(Unit.GetSoldierRank() + 1)
				&& Unit.GetStatus() != eStatus_PsiTesting
				&& !Unit.IsPsiTraining()
				&& !Unit.IsPsiAbilityTraining())
			return true;
	}

	return false;
}
static function bool IsLW2Present()
{
	local bool bLW2;

	LW2Tuple = new class'LWTuple';
	LW2Tuple.Id = 'GetLWVersion';
	`XEVENTMGR.TriggerEvent('GetLWVersion', LW2Tuple);
	return LW2Tuple.Data.Length == 3;
}

static function int GetMaxRankForClass(name DataName)
{
	local X2SoldierClassTemplate Template;

	Template = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(DataName);

	return Min(class'X2ExperienceConfig'.static.GetMaxRank() - 1, Template.GetMaxConfiguredRank());
}

// This is a modified version of code provided by Amineri at https://forums.nexusmods.com/index.php?/topic/3853330-psa-you-have-to-garbage-collect-your-components-yourself/
static function GarbageCollectRookiePsiTraining()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local XComGameState_Unit_RookiePsiTraining TrainingState;
	
	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("RookiePsiTraining Cleanup");

	foreach History.IterateByClassType(class'XComGameState_Unit_RookiePsiTraining', TrainingState,,true)
	{
		if (TrainingState.OwningObjectId > 0)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(TrainingState.OwningObjectID));

			if (UnitState == none || UnitState.bRemoved)
			{
				NewGameState.RemoveStateObject(TrainingState.ObjectID);
			}
		}
	}

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		`GAMERULES.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}