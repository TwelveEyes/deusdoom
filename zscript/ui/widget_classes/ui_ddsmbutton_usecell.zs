class UI_DDSmallButton_UseCell : UI_DDSmallButton
{
	UI_Augs_Sidepanel sidepanel;

	override void processUIInput(UiEvent e)
	{
		super.processUIInput(e);

		if(e.type == UiEvent.Type_LButtonUp)
		{
			EventHandler.sendNetworkEvent("dd_use_cell");
		}
	}

	override void uiTick()
	{
		PlayerInfo plr = players[consoleplayer];
		if(plr.mo)
		{
			if(DD_BioelectricCell.canConsume(plr.mo,
					DD_BioelectricCell(plr.mo.findInventory("DD_BioelectricCell")))){
				disabled = false;
				text_color = 11;
			}
			else{
				disabled = true;
				text_color = 12;
			}
		}
	}
}
