//---------------------------------------------------------------------------------------
//  FILE:   XComDownloadableContentInfo_PsiLabTrainsMultipleClasses.uc                                    
//           
//	Use the X2DownloadableContentInfo class to specify unique mod behavior when the 
//  player creates a new campaign or loads a saved game.
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_PsiLabTrainsMultipleClasses extends X2DownloadableContentInfo;

/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
static event OnLoadedSavedGame()
{}

/// <summary>
/// Called when the player starts a new campaign while this DLC / Mod is installed
/// </summary>
static event InstallNewCampaign(XComGameState StartState)
{}

/// <summary>
/// Called after the Templates have been created (but before they are validated) while this DLC / Mod is installed.
/// </summary>
static event OnPostTemplatesCreated()
{
	local X2StrategyElementTemplateManager StrategyElementTemplateManager;
	local X2SoldierClassTemplateManager SoldierClassTemplateManager;
	local array<X2SoldierClassTemplate> SoldierClassTemplateArray;
	local array<X2DataTemplate> DataTemplateArray;
	local X2StaffSlotTemplate StaffSlotTemplate;
	local X2SoldierClassTemplate SoldierClassTemplate, SoldierClassDifficultyTemplate;
	local X2DataTemplate DataTemplate;

	class'MCPL_MCMListener'.static.LoadUserConfig();

	StrategyElementTemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	StaffSlotTemplate = X2StaffSlotTemplate(StrategyElementTemplateManager.FindStrategyElementTemplate('PsiChamberSoldierStaffSlot'));
	StaffSlotTemplate.FillFn = class'MCPL_Utilities'.static.FillPsiChamberSoldierSlot;
	StaffSlotTemplate.ShouldDisplayToDoWarningFn = class'MCPL_Utilities'.static.ShouldDisplayPsiChamberSoldierToDoWarning;

	if (class'MCPL_Utilities'.static.IsLW2Present())
	{
		StaffSlotTemplate.IsUnitValidForSlotFn = class'MCPL_Utilities'.static.IsUnitValidForPsiChamberSoldierSlotLW2;
	}
	else
	{
		StaffSlotTemplate.IsUnitValidForSlotFn = class'MCPL_Utilities'.static.IsUnitValidForPsiChamberSoldierSlot;
	}

	SoldierClassTemplateManager = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();

	SoldierClassTemplateArray = SoldierClassTemplateManager.GetAllSoldierClassTemplates();

	foreach SoldierClassTemplateArray(SoldierClassTemplate)
	{
		SoldierClassTemplateManager.FindDataTemplateAllDifficulties(SoldierClassTemplate.DataName, DataTemplateArray);

		foreach DataTemplateArray(DataTemplate)
		{
			SoldierClassDifficultyTemplate = X2SoldierClassTemplate(DataTemplate);

			if (SoldierClassDifficultyTemplate != none && class'MCPL_Utilities'.static.IsTrainable(SoldierClassDifficultyTemplate.DataName))
			{
				`LOG("Blocking soldier class template" @ string(SoldierClassDifficultyTemplate) @ "from ranking up", true, 'MultipleClassPsiLab');
				SoldierClassDifficultyTemplate.bBlockRankingUp = true;
			}
		}
	}
}