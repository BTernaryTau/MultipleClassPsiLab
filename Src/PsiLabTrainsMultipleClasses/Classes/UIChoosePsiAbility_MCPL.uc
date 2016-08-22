class UIChoosePsiAbility_MCPL extends UIChoosePsiAbility;

simulated function array<SoldierAbilityInfo> GetAbilities()
{
	local X2SoldierClassTemplate SoldierClassTemplate;
	local X2AbilityTemplate AbilityTemplate;	
	local SCATProgression ProgressAbility;
	local array<SoldierAbilityInfo> SoldierAbilities;
	local SoldierAbilityInfo SoldierAbility;
	local XComGameState_Unit Unit;
	local XComGameState_HeadquartersProjectPsiTraining AbilityProject;
	local array<name> AddedAbilityNames;
	local name AbilityName;
	local int iName, i;
	local bool bAddAbility;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_UnitRef.ObjectID));
	SoldierClassTemplate = Unit.GetSoldierClassTemplate();

	// First check to see if the soldier has a paused ability training project
	AbilityProject = XComHQ.GetPsiTrainingProject(m_UnitRef);
	if (AbilityProject != none && AbilityProject.bForcePaused)
	{
		// Only add the paused ability to the list as a choice to resume
		AbilityName = SoldierClassTemplate.GetAbilityName(AbilityProject.iAbilityRank, AbilityProject.iAbilityBranch);
		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName);

		SoldierAbility.AbilityTemplate = AbilityTemplate;
		SoldierAbility.iRank = AbilityProject.iAbilityRank;
		SoldierAbility.iBranch = AbilityProject.iAbilityBranch;

		SoldierAbilities.AddItem(SoldierAbility);
		AddedAbilityNames.AddItem(AbilityName);
	}
	else if (class'MCPL_Utilities'.static.IsOrderedTreeTrainable(SoldierClassTemplate.DataName))
	{
		// Add all abilities for the next rank to the list
		for (i = 0; i < SoldierClassTemplate.GetAbilityTree(Unit.GetRank()).Length; i++)
		{
			AbilityName = SoldierClassTemplate.GetAbilityName(Unit.GetRank(), i);
			AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName);

			SoldierAbility.AbilityTemplate = AbilityTemplate;
			SoldierAbility.iRank = Unit.GetRank();
			SoldierAbility.iBranch = i;

			SoldierAbilities.AddItem(SoldierAbility);
			AddedAbilityNames.AddItem(AbilityName);
		}
	}
	else if (class'MCPL_Utilities'.static.IsRandomTreeTrainable(SoldierClassTemplate.DataName))
	{
		// Generate a random list of abilities if it doesn't already exist
		if (Unit.PsiAbilities.Length == 0)
			Unit.RollForPsiAbilities();

		foreach Unit.PsiAbilities(ProgressAbility)
		{	
			if (SoldierAbilities.Length >= MaxAbilitiesDisplayed)
				break;
			
			bAddAbility = false;
			AbilityName = SoldierClassTemplate.GetAbilityName(ProgressAbility.iRank, ProgressAbility.iBranch);
			if (AbilityName != '' && !Unit.HasSoldierAbility(AbilityName) && AddedAbilityNames.Find(AbilityName) == INDEX_NONE)
			{
				AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName);
				if (AbilityTemplate != none)
				{
					bAddAbility = true;
					
					// Check to make sure that soldier has any prereq abilites required, and if not then add the prereq ability instead
					if (AbilityTemplate.PrerequisiteAbilities.Length > 0)
					{
						for (iName = 0; iName < AbilityTemplate.PrerequisiteAbilities.Length; iName++)
						{
							AbilityName = AbilityTemplate.PrerequisiteAbilities[iName];
							if (!Unit.HasSoldierAbility(AbilityName)) // if the soldier does not have the prereq ability, replace it
							{
								AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName);
								ProgressAbility = SoldierClassTemplate.GetSCATProgressionForAbility(AbilityName);
								
								if (AddedAbilityNames.Find(AbilityName) != INDEX_NONE)
								{
									// If the prereq ability was already added to the list, don't add it again
									bAddAbility = false;
								}
								
								break;
							}
						}
					}
				}
				
				if (bAddAbility)
				{
					SoldierAbility.AbilityTemplate = AbilityTemplate;
					SoldierAbility.iRank = ProgressAbility.iRank;
					SoldierAbility.iBranch = ProgressAbility.iBranch;
						
					SoldierAbilities.AddItem(SoldierAbility);
					AddedAbilityNames.AddItem(AbilityName);
				}
			}
		}
	}
	else
	{
		// Something went horribly wrong!
		`REDSCREEN("Invalid soldier class" @ SoldierClassTemplate.DataName @ "was sent to UIChoosePsiAbility_MCPL", true, 'MultipleClassPsiLab');
		`LOG("Invalid soldier class" @ SoldierClassTemplate.DataName @ "was sent to UIChoosePsiAbility_MCPL", true, 'MultipleClassPsiLab');
	}

	return SoldierAbilities;
}

function int SortAbilitiesByRank(SoldierAbilityInfo AbilityA, SoldierAbilityInfo AbilityB)
{
	if (AbilityA.iRank < AbilityB.iRank)
	{
		return 1;
	}
	//else if (AbilityA.iRank > AbilityB.iBranch) - this is the line in UIChoosePsiAbility
	else if (AbilityA.iRank > AbilityB.iRank)
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

function bool OnAbilitySelected(int iOption)
{
	local XComGameState NewGameState;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_HeadquartersProjectPsiTraining TrainPsiOpProject;
	local StaffUnitInfo UnitInfo;
	
	StaffSlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(m_StaffSlotRef.ObjectID));

	if (StaffSlotState != none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Staffing Train Psi Operative Slot");
		UnitInfo.UnitRef = m_UnitRef;
		StaffSlotState.FillSlot(NewGameState, UnitInfo);
						
		// If a paused project already exists for this ability, resume it
		TrainPsiOpProject = XComHQ.GetPausedPsiAbilityTrainingProject(m_UnitRef, m_arrAbilities[iOption]);
		if (TrainPsiOpProject != None)
		{
			TrainPsiOpProject = XComGameState_HeadquartersProjectPsiTraining(NewGameState.CreateStateObject(TrainPsiOpProject.Class, TrainPsiOpProject.ObjectID));
			NewGameState.AddStateObject(TrainPsiOpProject);
			TrainPsiOpProject.bForcePaused = false;
		}
		else
		{
			// Otherwise start a new psi ability training project
			TrainPsiOpProject = XComGameState_HeadquartersProjectPsiTraining_MCPL(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectPsiTraining_MCPL'));
			NewGameState.AddStateObject(TrainPsiOpProject);
			TrainPsiOpProject.iAbilityRank = m_arrAbilities[iOption].iRank; // These need to be set first so project PointsToComplete can be calculated correctly
			TrainPsiOpProject.iAbilityBranch = m_arrAbilities[iOption].iBranch;
			TrainPsiOpProject.SetProjectFocus(UnitInfo.UnitRef, NewGameState, StaffSlotState.Facility);

			XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			NewGameState.AddStateObject(XComHQ);
			XComHQ.Projects.AddItem(TrainPsiOpProject.GetReference());
		}

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Staff_Assign");

		FacilityState = XComHQ.GetFacilityByName('PsiChamber');
		if (FacilityState.GetNumEmptyStaffSlots() > 0)
		{
			StaffSlotState = FacilityState.GetStaffSlot(FacilityState.GetEmptyStaffSlotIndex());

			if ((StaffSlotState.IsScientistSlot() && XComHQ.GetNumberOfUnstaffedScientists() > 0) ||
				(StaffSlotState.IsEngineerSlot() && XComHQ.GetNumberOfUnstaffedEngineers() > 0))
			{
				`HQPRES.UIStaffSlotOpen(FacilityState.GetReference(), StaffSlotState.GetMyTemplate());
			}
		}

		XComHQ.HandlePowerOrStaffingChange();

		RefreshFacility();
	}

	return true;
}