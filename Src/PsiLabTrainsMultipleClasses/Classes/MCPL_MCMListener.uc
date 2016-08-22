// Creates and handles the settings page if MCM is installed

class MCPL_MCMListener extends UIScreenListener config(PsiLabTrainsMultipleClasses);

`include(PsiLabTrainsMultipleClasses/Src/ModConfigMenuAPI/MCM_API_Includes.uci)
`include(PsiLabTrainsMultipleClasses/Src/ModConfigMenuAPI/MCM_API_CfgHelpers.uci)

var config int ConfigVersion;

var config array<name> OrderedTreeTrainableClasses, RandomTreeTrainableClasses;

var config array<name> ModAddedOrderedTreeTrainableClasses, ModAddedRandomTreeTrainableClasses;

var array<bool> OrderedTreeCheckboxValues, RandomTreeCheckboxValues;

var array<X2SoldierClassTemplate> TemplateArray;

var array<MCM_API_Checkbox> OrderedTreeCheckboxes, RandomTreeCheckboxes;

var localized string ModName, OrderedTreeGroupName, RandomTreeGroupName, RestartLabelText, OrderedTreeCheckboxDesc, RandomTreeCheckboxDesc;

event OnInit(UIScreen Screen)
{
	`MCM_API_Register(Screen, ClientModCallback);
}

simulated function ClientModCallback(MCM_API_Instance ConfigAPI, int GameMode)
{
	local int i;

	local MCM_API_SettingsPage Page;
	local MCM_API_SettingsGroup OrderedTreeGroup, RandomTreeGroup;

	TemplateArray = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().GetAllSoldierClassTemplates();

	// Remove templates for rookies, SPARKs, Bradford, and Shen
	for (i = 0; i < TemplateArray.Length; i++)
	{
		if (TemplateArray[i].DataName == 'Rookie' || TemplateArray[i].DataName == 'Spark' || TemplateArray[i].DataName == 'CentralOfficer' || TemplateArray[i].DataName == 'ChiefEngineer')
		{
			`LOG("Excluding soldier class template" @ TemplateArray[i].DataName @ "from MCM options", true, 'MultipleClassPsiLab');
			TemplateArray.Remove(i, 1);
			i--;
		}
		else
		{
			`LOG("Adding soldier class template" @ TemplateArray[i].DataName @ "to MCM options", true, 'MultipleClassPsiLab');
		}
	}

	LoadSavedSettings();

	if (OrderedTreeCheckboxes.Length == 0) // remove once random classes are implemented
	{
		OrderedTreeCheckboxes.Add(TemplateArray.Length);
		RandomTreeCheckboxes.Add(TemplateArray.Length);
	}

	Page = ConfigAPI.NewSettingsPage(ModName);
	Page.SetPageTitle(ModName);
	Page.SetSaveHandler(SaveButtonClicked);
	Page.SetCancelHandler(RevertButtonClicked);
	Page.EnableResetButton(ResetButtonClicked);
	
	OrderedTreeGroup = Page.AddGroup('MCPLOrderedTreeGroup', OrderedTreeGroupName);
	RandomTreeGroup = Page.AddGroup('MCPLRandomTreeGroup', RandomTreeGroupName);

	OrderedTreeGroup.AddLabel('MCPLLabel', RestartLabelText, RestartLabelText);

	//OrderedTreeCheckboxes.Length = 0;
	//RandomTreeCheckboxes.Length = 0;

	for (i = 0; i < TemplateArray.Length; i++)
	{
		OrderedTreeCheckboxes[i] = OrderedTreeGroup.AddCheckbox(name('MCPLOrderedTreeCheckbox_' $ i), TemplateArray[i].DisplayName, OrderedTreeCheckboxDesc, OrderedTreeCheckboxValues[i], OrderedTreeCheckboxSaveHandler, OrderedTreeCheckboxChangeHandler);
		//OrderedTreeCheckboxes.AddItem(OrderedTreeGroup.AddCheckbox(name('MCPLOrderedTreeCheckbox_' $ i), TemplateArray[i].DisplayName, OrderedTreeCheckboxDesc, OrderedTreeCheckboxValues[i], OrderedTreeCheckboxSaveHandler, OrderedTreeCheckboxChangeHandler));

		if (TemplateArray[i].DataName == 'PsiOperative' || class'MCPL_Defaults'.default.DebugMode)
			RandomTreeCheckboxes[i] = RandomTreeGroup.AddCheckbox(name('MCPLRandomTreeCheckbox_' $ i), TemplateArray[i].DisplayName, RandomTreeCheckboxDesc, RandomTreeCheckboxValues[i], RandomTreeCheckboxSaveHandler, RandomTreeCheckboxChangeHandler);
			//RandomTreeCheckboxes.AddItem(RandomTreeGroup.AddCheckbox(name('MCPLRandomTreeCheckbox_' $ i), TemplateArray[i].DisplayName, RandomTreeCheckboxDesc, RandomTreeCheckboxValues[i], RandomTreeCheckboxSaveHandler, RandomTreeCheckboxChangeHandler));
	}

	Page.ShowSettings();
}

`MCM_CH_VersionChecker(class'MCPL_Defaults'.default.ConfigVersion, ConfigVersion)

simulated function LoadSavedSettings()
{
	local int i;

	if (OrderedTreeCheckboxValues.Length == 0)
	{
		OrderedTreeCheckboxValues.Add(TemplateArray.Length);
		RandomTreeCheckboxValues.Add(TemplateArray.Length);
	}

	class'MCPL_MCMListener'.static.LoadUserConfig();
	
	for (i = 0; i < TemplateArray.Length; i++)
	{
		OrderedTreeCheckboxValues[i] = class'MCPL_Utilities'.static.IsOrderedTreeTrainable(TemplateArray[i].DataName);
		RandomTreeCheckboxValues[i] = class'MCPL_Utilities'.static.IsRandomTreeTrainable(TemplateArray[i].DataName);

		// If a soldier is in both arrays, default to one perk per rank
		if (OrderedTreeCheckboxValues[i] && RandomTreeCheckboxValues[i])
			RandomTreeCheckboxValues[i] = false;
	}
}

simulated function OrderedTreeCheckboxSaveHandler(MCM_API_Setting Checkbox, bool CheckboxValue)
{
	local int index;

	index = int(GetRightMost(Checkbox.GetName()));

	OrderedTreeCheckboxValues[index] = CheckboxValue;
}

simulated function RandomTreeCheckboxSaveHandler(MCM_API_Setting Checkbox, bool CheckboxValue)
{
	local int index;

	index = int(GetRightMost(Checkbox.GetName()));

	RandomTreeCheckboxValues[index] = CheckboxValue;
}

simulated function OrderedTreeCheckboxChangeHandler(MCM_API_Setting Checkbox, bool CheckboxValue)
{
	local int index;

	index = int(GetRightMost(Checkbox.GetName()));

	if (index >= RandomTreeCheckboxes.Length)
		return;

	// If both checkboxes for the class are checked, uncheck the one that wasn't just checked
	if (CheckboxValue && RandomTreeCheckboxes[index].GetValue())
		RandomTreeCheckboxes[index].SetValue(false, true);
}

simulated function RandomTreeCheckboxChangeHandler(MCM_API_Setting Checkbox, bool CheckboxValue)
{
	local int index;

	index = int(GetRightMost(Checkbox.GetName()));

	// If both checkboxes for the class are checked, uncheck the one that wasn't just checked
	if (CheckboxValue && OrderedTreeCheckboxes[index].GetValue())
		OrderedTreeCheckboxes[index].SetValue(false, true);
}

simulated function SaveButtonClicked(MCM_API_SettingsPage Page)
{
	local int i;

	OrderedTreeTrainableClasses.Remove(0, OrderedTreeTrainableClasses.Length);
	RandomTreeTrainableClasses.Remove(0, RandomTreeTrainableClasses.Length);

	for (i = 0; i < TemplateArray.Length; i++)
	{
		if (OrderedTreeCheckboxValues[i])
		{
			`LOG("Adding soldier class template" @ TemplateArray[i].DataName @ "to OrderedTreeTrainableClasses", true, 'MultipleClassPsiLab');
			OrderedTreeTrainableClasses.AddItem(TemplateArray[i].DataName);
		}
		else if (RandomTreeCheckboxValues[i])
		{
			`LOG("Adding soldier class template" @ TemplateArray[i].DataName @ "to RandomTreeTrainableClasses", true, 'MultipleClassPsiLab');
			RandomTreeTrainableClasses.AddItem(TemplateArray[i].DataName);
		}
	}

	ConfigVersion = `MCM_CH_GetCompositeVersion();
	SaveConfig();

	// Allow proper garbage collection of UI elements
	OrderedTreeCheckboxes.Length = 0;
	RandomTreeCheckboxes.Length = 0;
}

simulated function ResetButtonClicked(MCM_API_SettingsPage Page)
{
	local int i;

	for (i = 0; i < TemplateArray.Length; i++)
	{
		OrderedTreeCheckboxes[i].SetValue(class'MCPL_Defaults'.default.OrderedTreeTrainableClasses.Find(TemplateArray[i].DataName) != INDEX_NONE, true);
		RandomTreeCheckboxes[i].SetValue(class'MCPL_Defaults'.default.RandomTreeTrainableClasses.Find(TemplateArray[i].DataName) != INDEX_NONE, true);

		// If a soldier is in both arrays, default to one perk per rank and complain because this shouldn't happen in the default settings
		if (OrderedTreeCheckboxes[i].GetValue() && RandomTreeCheckboxes[i].GetValue())
		{
			RandomTreeCheckboxes[i].SetValue(false, true);
			`REDSCREEN("Soldier class" @ TemplateArray[i].DataName @ "was in both arrays in MCPL_Defaults!", true, 'MultipleClassPsiLab');
			`LOG("Soldier class" @ TemplateArray[i].DataName @ "was in both arrays in MCPL_Defaults!", true, 'MultipleClassPsiLab');
		}
	}
}

simulated function RevertButtonClicked(MCM_API_SettingsPage Page)
{
	// Allow proper garbage collection of UI elements
	OrderedTreeCheckboxes.Length = 0;
	RandomTreeCheckboxes.Length = 0;
}

static function LoadUserConfig()
{
	local name ModAddedClass;
	local int UserConfigVersion, DefaultConfigVersion;

	UserConfigVersion = default.ConfigVersion;
	DefaultConfigVersion = class'MCPL_Defaults'.default.ConfigVersion;

	if (UserConfigVersion < DefaultConfigVersion && !UpdateUserConfigValues(UserConfigVersion))
	{
		return;
	}

	// Update ModAdded lists to reflect the default config, and add classes (or remove Psi Op) as necessary.
	foreach class'MCPL_Defaults'.default.ModAddedOrderedTreeTrainableClasses(ModAddedClass)
	{
		if (default.ModAddedOrderedTreeTrainableClasses.Find(ModAddedClass) == INDEX_NONE)
		{
			default.ModAddedOrderedTreeTrainableClasses.AddItem(ModAddedClass);

			if (default.OrderedTreeTrainableClasses.Find(ModAddedClass) == INDEX_NONE)
			{
				default.OrderedTreeTrainableClasses.AddItem(ModAddedClass);
			}
		}
	}

	foreach default.ModAddedOrderedTreeTrainableClasses(ModAddedClass)
	{
		if (class'MCPL_Defaults'.default.ModAddedOrderedTreeTrainableClasses.Find(ModAddedClass) == INDEX_NONE)
		{
			default.ModAddedOrderedTreeTrainableClasses.RemoveItem(ModAddedClass);
		}
	}

	foreach class'MCPL_Defaults'.default.ModAddedRandomTreeTrainableClasses(ModAddedClass)
	{
		if (default.ModAddedRandomTreeTrainableClasses.Find(ModAddedClass) == INDEX_NONE)
		{
			default.ModAddedRandomTreeTrainableClasses.AddItem(ModAddedClass);

			if (ModAddedClass == 'PsiOperative' && default.RandomTreeTrainableClasses.Find(ModAddedClass) != INDEX_NONE)
			{
				default.RandomTreeTrainableClasses.RemoveItem(ModAddedClass);
			}
			else if (default.RandomTreeTrainableClasses.Find(ModAddedClass) == INDEX_NONE)
			{
				default.RandomTreeTrainableClasses.AddItem(ModAddedClass);
			}
		}
	}

	foreach default.ModAddedRandomTreeTrainableClasses(ModAddedClass)
	{
		if (class'MCPL_Defaults'.default.ModAddedRandomTreeTrainableClasses.Find(ModAddedClass) == INDEX_NONE)
		{
			default.ModAddedRandomTreeTrainableClasses.RemoveItem(ModAddedClass);
		}
	}

	StaticSaveConfig();
}

static function bool UpdateUserConfigValues(out int UserConfigVersion)
{
	switch (UserConfigVersion)
	{
		case 0:
			default.ConfigVersion = 1;

			default.OrderedTreeTrainableClasses = class'MCPL_Defaults'.default.OrderedTreeTrainableClasses;
			default.RandomTreeTrainableClasses = class'MCPL_Defaults'.default.RandomTreeTrainableClasses;

			default.ModAddedOrderedTreeTrainableClasses = class'MCPL_Defaults'.default.ModAddedOrderedTreeTrainableClasses;
			default.ModAddedRandomTreeTrainableClasses = class'MCPL_Defaults'.default.ModAddedRandomTreeTrainableClasses;
			break;

		default:
			`REDSCREEN("Unknown user config version" @ string(UserConfigVersion) @ "cannot be updated", true, 'MultipleClassPsiLab');
			`LOG("Unknown user config version " @ string(UserConfigVersion) @ "cannot be updated", true, 'MultipleClassPsiLab');
			return false;
	}

	`LOG("Updated user config version" @ string(UserConfigVersion) @ "to version" @ string(default.ConfigVersion), true, 'MultipleClassPsiLab');

	UserConfigVersion = default.ConfigVersion;

	return true;
}

defaultproperties
{
	ScreenClass = class'MCM_OptionsScreen'
}