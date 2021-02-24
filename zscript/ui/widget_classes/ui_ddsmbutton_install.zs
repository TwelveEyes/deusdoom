class UI_DDSmallButton_Install : UI_DDSmallButton
{
	UI_Augs_Sidepanel sidepanel;

	override void processUIInput(UiEvent e)
	{
		super.processUIInput(e);

		if(e.type == UiEvent.Type_LButtonUp)
		{
			PlayerInfo plr = players[consoleplayer];
			DD_AugsHolder aughld = DD_AugsHolder(plr.mo.findInventory("DD_AugsHolder"));

			if(sidepanel.aug_install_sel_slot == -1 || sidepanel.aug_install_sel == -1)
				return;

			DD_Augmentation aug_obj;
			if(sidepanel.aug_install_sel == 1)
				aug_obj = aughld.augs_toinstall1[sidepanel.aug_install_sel_slot];
			else if(sidepanel.aug_install_sel == 2)
				aug_obj = aughld.augs_toinstall2[sidepanel.aug_install_sel_slot];

			if(!aug_obj || !aughld.canInstallAug(aug_obj))
				return;

			aughld.queueInstallAug(aug_obj);
			sidepanel.aug_install_sel_slot = 0;
			sidepanel.aug_install_sel = 0;
		}
	}

	override void uiTick()
	{
		if(sidepanel.aug_install_sel_slot == -1
		|| sidepanel.aug_install_sel == -1)
		{
			disabled = true;
			text_color = 12;
			return;
		}

		PlayerInfo plr = players[consoleplayer];
		DD_AugsHolder aughld = DD_AugsHolder(plr.mo.FindInventory("DD_AugsHolder"));
		if(sidepanel.aug_install_sel == 1){
			if(!aughld.canInstallAug(aughld.augs_toinstall1[sidepanel.aug_install_sel_slot])){
				disabled = true;
				text_color = 12;
				return;
			}
		}
		else if(sidepanel.aug_install_sel == 2){
			if(!aughld.canInstallAug(aughld.augs_toinstall2[sidepanel.aug_install_sel_slot])){
				disabled = true;
				text_color = 12;
				return;
			}
		}

		disabled = false;
		text_color = 11;
	}
}
