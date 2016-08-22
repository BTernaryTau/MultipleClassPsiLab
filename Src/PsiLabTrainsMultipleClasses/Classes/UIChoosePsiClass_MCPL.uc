class UIChoosePsiClass_MCPL extends UIChooseClass;

var StateObjectReference m_StaffSlotRef; // set in UIFacility_PsiLabSlot_MCPL

simulated function array<X2SoldierClassTemplate> GetClasses()
{
	local X2SoldierClassTemplateManager SoldierClassTemplateMan;
	local X2SoldierClassTemplate SoldierClassTemplate;
	local X2DataTemplate Template;
	local array<X2SoldierClassTemplate> ClassTemplates;

	SoldierClassTemplateMan = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();

	foreach SoldierClassTemplateMan.IterateTemplates(Template, none)
	{		
		SoldierClassTemplate = X2SoldierClassTemplate(Template);
		
		if (class'MCPL_Utilities'.static.IsTrainable(SoldierClassTemplate.DataName) && !SoldierClassTemplate.bMultiplayerOnly)
			ClassTemplates.AddItem(SoldierClassTemplate);
	}

	return ClassTemplates;
}

function bool OnClassSelected(int iOption)
{
	local XComGameState NewGameState;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameState_Unit_RookiePsiTraining TrainingState;
	local StaffUnitInfo UnitInfo;
	local Object Listener;

	StaffSlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(m_StaffSlotRef.ObjectID));
	
	if (StaffSlotState != none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Staffing Psi Training Slot");

		TrainingState = XComGameState_Unit_RookiePsiTraining(NewGameState.CreateStateObject(class'XComGameState_Unit_RookiePsiTraining'));
		TrainingState.NewClassName = m_arrClasses[iOption].DataName;
		XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_UnitRef.ObjectID)).AddComponentObject(TrainingState);
		NewGameState.AddStateObject(TrainingState);
		Listener = TrainingState;
		`XEVENTMGR.RegisterForEvent(Listener, 'PsiTrainingCompleted', TrainingState.RookiePsiTrainingCheck,,,,true);

		UnitInfo.UnitRef = m_UnitRef;
		StaffSlotState.FillSlot(NewGameState, UnitInfo); // The Training project is started when the staff slot is filled
		
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Staff_Assign");
		
		FacilityState = StaffSlotState.GetFacility();
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

simulated function RefreshFacility()
{
	local UIScreen QueueScreen;

	QueueScreen = Movie.Stack.GetScreen(class'UIFacility_PsiLab');
	if (QueueScreen != None)
		UIFacility_PsiLab(QueueScreen).RealizeFacility();
}

defaultproperties
{
	InputState = eInputState_Consume;

	bHideOnLoseFocus = true;
	//bSelectFirstAvailable = false;
	//bConsumeMouseEvents = true;

	DisplayTag="UIDisplay_Academy"
	CameraTag="UIDisplay_Academy"
}