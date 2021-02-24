class UI_DDSmallButton_ToggleAug : UI_DDSmallButton
{
	UI_Augs_Sidepanel sidepanel;

	override void processUIInput(UiEvent e)
	{
		super.processUIInput(e);

		if(e.type == UiEvent.Type_LButtonUp)
		{
			PlayerInfo plr = players[consoleplayer];
			DD_AugsHolder aughld = DD_AugsHolder(plr.mo.FindInventory("DD_AugsHolder"));

			if(sidepanel.aug_sel != -1 && aughld.augs[sidepanel.aug_sel])
			{
				aughld.queueToggleAug(sidepanel.aug_sel);
			}
		}
	}
}
