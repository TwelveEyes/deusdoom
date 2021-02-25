struct DD_EventHandlerQueue
{
	// queued state of ui processor
	bool qstate;
	bool ui_init;
}

class DD_EventHandler : StaticEventHandler
{
	SoundUtils snd_utils;
	RecognitionUtils recg_utils;

	ui UI_WindowManager wndmgr;
		ui UI_Augs wnd_augs;
		ui UI_Augs_Sidepanel wnd_augs_sidepanel;

	DD_EventHandlerQueue queue;

	// Font for augs holder
	ui Font aug_ui_font;

	override void onRegister()
	{
		setOrder(999);

		snd_utils = new("SoundUtils");
		recg_utils = new("RecognitionUtils");
		recg_utils.loadLists();

		queue.qstate = false;
	}

	override void playerSpawned(PlayerEvent e)
	{
		PlayerPawn plr = players[e.PlayerNumber].mo;
		DD_AugsHolder aughld = DD_AugsHolder(Inventory.Spawn("DD_AugsHolder"));
		queue.ui_init = false;
		if(plr.countInv("DD_AugsHolder") == 0)
			plr.addInventory(aughld);


			//aughld.installAug(DD_Aug_PowerRecirculator(Inventory.Spawn("DD_Aug_PowerRecirculator")));
			//aughld.installAug(DD_Aug_EnvironmentalResistance(Inventory.Spawn("DD_Aug_EnvironmentalResistance")));
			//aughld.installAug(DD_Aug_BallisticProtection(Inventory.Spawn("DD_Aug_BallisticProtection")));
			//aughld.installAug(DD_Aug_Cloak(Inventory.Spawn("DD_Aug_Cloak")));
			//aughld.installAug(DD_Aug_RadarTransparency(Inventory.Spawn("DD_Aug_RadarTransparency")));
			//aughld.installAug(DD_Aug_GravitationalField(Inventory.Spawn("DD_Aug_GravitationalField")));
			//aughld.installAug(DD_Aug_CombatStrength(Inventory.Spawn("DD_Aug_CombatStrength")));
			//aughld.installAug(DD_Aug_SpeedEnhancement(Inventory.Spawn("DD_Aug_SpeedEnhancement")));
			//aughld.installAug(DD_Aug_AgilityEnhancement(Inventory.Spawn("DD_Aug_AgilityEnhancement")));
			//aughld.installAug(DD_Aug_EnergyShield(Inventory.Spawn("DD_Aug_EnergyShield")));
			//aughld.installAug(DD_Aug_MicrofibralMuscle(Inventory.Spawn("DD_Aug_MicrofibralMuscle")));
			//aughld.installAug(DD_Aug_Regeneration(Inventory.Spawn("DD_Aug_Regeneration")));
			//aughld.installAug(DD_Aug_SyntheticHeart(Inventory.Spawn("DD_Aug_SyntheticHeart")));
			//aughld.installAug(DD_Aug_AggressiveDefenseSystem(Inventory.Spawn("DD_Aug_AggressiveDefenseSystem")));
			//aughld.installAug(DD_Aug_SpyDrone(Inventory.Spawn("DD_Aug_SpyDrone")));
			//aughld.installAug(DD_Aug_Targeting(Inventory.Spawn("DD_Aug_Targeting")));
			//aughld.installAug(DD_Aug_VisionEnhancement(Inventory.Spawn("DD_Aug_VisionEnhancement")));
	}

	override void worldTick()
	{
		snd_utils.worldTick();

		self.isUIProcessor = queue.qstate;
		self.requireMouse = queue.qstate;
	}


	override void renderUnderlay(RenderEvent e)
	{
		PlayerInfo plr = players[consoleplayer];
		DD_AugsHolder aughld = DD_AugsHolder(plr.mo.findInventory("DD_AugsHolder"));
		if(aughld)
			aughld.drawUnderlay(e, self);

		if(wndmgr)
			wndmgr.renderUnderlay(e);
	}
	override void renderOverlay(RenderEvent e)
	{
		PlayerInfo plr = players[consoleplayer];
		DD_AugsHolder aughld = DD_AugsHolder(plr.mo.findInventory("DD_AugsHolder"));
		if(aughld)
			aughld.draw(e, self, 301, 0);

		if(wndmgr)
			wndmgr.renderOverlay(e);
	}


	override bool InputProcess(InputEvent e)
	{
		if(wndmgr)
			if(wndmgr.inputProcess(e))
				return true;
		return false;
	}
	override bool UiProcess(UiEvent e)
	{
		if(wndmgr)
			return wndmgr.uiProcess(e);
		return false;
	}


	override void UiTick()
	{
		if(!queue.ui_init)
		{
			DD_AugsHolder aughld;
			if(players[consoleplayer].mo)
				aughld = DD_AugsHolder(players[consoleplayer].mo.findInventory("DD_AugsHolder"));
			if(aughld){
				queue.ui_init = true;
				aughld.UIInit();
				if(!wndmgr)
				{
					aug_ui_font = Font.getFont("DD_UI");
					wndmgr = new("UI_WindowManager");
					wnd_augs = new("UI_Augs");
					wnd_augs_sidepanel = new("UI_Augs_Sidepanel");
					wnd_augs.sidepanel = wnd_augs_sidepanel;
				}
			}
		}
		if(wndmgr)
			wndmgr.uiTick();
	}

	override void consoleProcess(ConsoleEvent e)
	{
		PlayerInfo plr = players[consoleplayer];
		DD_AugsHolder aughld = DD_AugsHolder(plr.mo.findInventory("DD_AugsHolder"));

		if(e.Name == "dd_togg_aug")
		{
			// Toggle augmentation (inverse it's current state)
			// Arguments: < augmentation slot >
			// (see DD_AugSlots enum)

			if(e.args[0] < 0 || e.args[0] >= aughld.augs_slots){
				console.printf("ERROR: Augmentation slot %d doesn't exist.",
						e.args[0]);
				return;
			}
			if(!aughld.augs[e.args[0]]){
				console.printf("ERROR: No augmentation in this slot.");
				return;
			}

			aughld.queueToggleAug(e.args[0]);
		}
		else if(e.Name == "dd_toggle_ui_augs")
		{
			// Open/close augmentations UI
			// Arguments: none

			wndmgr.addWindow(self, wnd_augs, 10, 5);
			wndmgr.addWindow(self, wnd_augs_sidepanel, 150, 5);

			// Closing windows is done in window classes themselves.
		}
		else if(e.Name == "dd_use_cell")
		{
			if(aughld){
	                        if(DD_BioelectricCell.queueConsume(plr.mo,
	                                DD_BioelectricCell(plr.mo.findInventory("DD_BioelectricCell"))))
	                        {
	                                SoundUtils.uiStartSound("ui/aug/cell_use");
	                        }
			}
		}
	}
}

class DD_InputEventHandler : EventHandler
{
	override void OnRegister()
	{
		SetOrder(1000);
	}

	override bool InputProcess(InputEvent e)
	{
		DD_AugsHolder aughld;
		if(players[consoleplayer].mo)
			aughld = DD_AugsHolder(players[consoleplayer].mo.findInventory("DD_AugsHolder"));
		if(aughld)
			if(aughld.inputProcess(e))
				return true;
		return false;
	}
}
