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

		if (Unit.GetSoldierClassTemplateName() == 'PsiOperative' && IsUnitValidForPsiChamberSoldierSlot(SlotState, UnitInfo))
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