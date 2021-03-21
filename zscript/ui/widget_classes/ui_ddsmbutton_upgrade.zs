class UI_DDSmallButton_Upgrade : UI_DDSmallButton
{
	UI_Augs parent_wnd; // parent window

	override void processUIInput(UiEvent e)
	{
		super.processUIInput(e);

		if(e.type == UiEvent.Type_LButtonUp)
		{
			PlayerInfo plr = players[consoleplayer];
			
			EventHandler.sendNetworkEvent("dd_upgrade_aug", parent_wnd.selected_aug_slot);
			/*DD_AugmentationUpgradeCanister.queueConsume(plr.mo,
				DD_AugmentationUpgradeCanister(plr.mo.findInventory("DD_AugmentationUpgradeCanister")),
				parent_wnd.selected_aug_slot);			*/
		}

		
	}

	override void uiTick()
	{
		return;
		PlayerInfo plr = players[consoleplayer];

		if(DD_AugmentationUpgradeCanister.canConsume(plr.mo,
				DD_AugmentationUpgradeCanister(plr.mo.findInventory("DD_AugmentationUpgradeCanister")),
				parent_wnd.selected_aug_slot)){
			disabled = false;
			text_color = 11;
		}
		else{
			disabled = true;
			text_color = 12;
		}
			
	}
}
