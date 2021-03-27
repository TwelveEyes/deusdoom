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
	DD_ModChecker mod_checker;
	DD_PatchChecker patch_checker;

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
		mod_checker = new("DD_ModChecker");
		mod_checker.init();
		patch_checker = new("DD_PatchChecker");
		patch_checker.init();

		queue.qstate = false;
	}

	override void playerSpawned(PlayerEvent e)
	{
		PlayerPawn plr = players[e.PlayerNumber].mo;
		DD_AugsHolder aughld = DD_AugsHolder(Inventory.Spawn("DD_AugsHolder"));
		queue.ui_init = false;
		if(plr.countInv("DD_AugsHolder") == 0)
			plr.addInventory(aughld);
		else
			aughld.destroy();


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
			if(wndmgr.uiProcess(e))
				return true;
		return false;
	}


	override void UiTick()
	{
		DD_AugsHolder aughld;
		if(players[consoleplayer].mo)
			aughld = DD_AugsHolder(players[consoleplayer].mo.findInventory("DD_AugsHolder"));
		if(!queue.ui_init)
		{
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
		if(aughld)
			aughld.UITick();
		if(wndmgr)
			wndmgr.uiTick();
	}

	override void networkProcess(ConsoleEvent e)
	{
		PlayerInfo plr = players[e.Player];
		if(!plr || !plr.mo)
			return;
		DD_AugsHolder aughld = DD_AugsHolder(plr.mo.findInventory("DD_AugsHolder"));

		if(e.name == "dd_togg_aug")
		{
			// Toggle augmentation (inverse it's current state)
			// Arguments: < augmentation slot >
			// (see DD_AugSlots enum)

			if(e.args[0] < 0 || e.args[0] >= aughld.augs_slots){
				if(consoleplayer == e.player)
					console.printf("ERROR: Augmentation slot %d doesn't exist.",
							e.args[0]);
				return;
			}
			if(!aughld.augs[e.args[0]]){
				if(consoleplayer == e.player)
					console.printf("ERROR: No augmentation in this slot.");
				return;
			}

			aughld.queueToggleAug(e.args[0]);
		}
		else if(e.name == "dd_install_aug")
		{
			// Install augmentation
			// Arguments: < DD_AugsHolder.augs_toinstall slot (shown in UI, starting from 0 up) > < aug selection (1 - leftmost, 2 - rightmost)  >

			DD_Augmentation aug_obj;
			if(e.args[1] == 1)
				aug_obj = aughld.augs_toinstall1[e.args[0]];
			else if(e.args[1] == 2)
				aug_obj = aughld.augs_toinstall2[e.args[0]];
			
			if(aug_obj && aughld.canInstallAug(aug_obj))
				aughld.queueInstallAug(aug_obj);
		}
		else if(e.name == "dd_upgrade_aug")
		{
			// Upgrade augmentation
			// Arguments: < DD_AugsHolder.augs slot >
			// (same slots as dd_togg_aug)

			let upgrcan = DD_AugmentationUpgradeCanister(plr.mo.findInventory("DD_AugmentationUpgradeCanister"));
			DD_AugmentationUpgradeCanister.queueConsume(plr.mo, upgrcan, e.args[0]);
		}
		else if(e.name == "dd_drop_aug")
		{
			// Drop augmentation
			// Arguments: < DD_AugsHolder.augs_toinstall slot >

			aughld.queueDropAug(e.args[0]);
		}
		else if(e.name == "dd_use_cell")
		{
			// Consume a bioelectric cell
			// Arguments: none
			if(aughld){
	                        if(DD_BioelectricCell.queueConsume(plr.mo,
	                                DD_BioelectricCell(plr.mo.findInventory("DD_BioelectricCell"))))
	                        {
	                                SoundUtils.playStartSound("ui/aug/cell_use", plr.mo);
	                        }
			}
		}

		// Augmentations-specific commands
		// I don't wanna spam EventHandlers too often
		else if(e.name == "dd_use_muscle")
		{
			DD_Aug_MicrofibralMuscle musaug;
			for(uint i = 0; i < DD_AugsHolder.augs_slots; ++i)
			{
				if(aughld.augs[i] && aughld.augs[i] is "DD_Aug_MicrofibralMuscle")
				{
					musaug = DD_Aug_MicrofibralMuscle(aughld.augs[i]);
					musaug.queue.objwep = true;
					break;
				}
			}
		}
		else if(e.name == "dd_dash")
		{
			DD_Aug_AgilityEnhancement agaug;
			for(uint i = 0; i < DD_AugsHolder.augs_slots; ++i)
			{
				if(aughld.augs[i] && aughld.augs[i] is "DD_Aug_AgilityEnhancement")
				{
					agaug = DD_Aug_AgilityEnhancement(aughld.augs[i]);
					switch(e.args[0])
					{
						case 0: agaug.queue.dashvel[0].x = agaug.getDashVel(); break;
						case 1: agaug.queue.dashvel[1].x = -agaug.getDashVel(); break;
						case 2: agaug.queue.dashvel[2].y = agaug.getDashVel(); break;
						case 3: agaug.queue.dashvel[3].y = -agaug.getDashVel(); break;
						case 4: agaug.queue.dashvel[4].x = agaug.getDashVel() * 0.7; break;
					}
					break;
				}
			}
		}
		else if(e.name == "dd_grip")
		{
			DD_Aug_AgilityEnhancement agaug;
			for(uint i = 0; i < DD_AugsHolder.augs_slots; ++i)
			{
				if(aughld.augs[i] && aughld.augs[i] is "DD_Aug_AgilityEnhancement")
				{
					agaug = DD_Aug_AgilityEnhancement(aughld.augs[i]);
					if(e.args[0])	agaug.queue.deacc = agaug.getDeaccFactor();
					else		agaug.queue.deacc = 0.0;
					break;
				}
			}
		}
		else if(e.name == "dd_drone")
		{
			DD_Aug_SpyDrone spyaug;
			for(uint i = 0; i < DD_AugsHolder.augs_slots; ++i)
			{
				if(aughld.augs[i] && aughld.augs[i] is "DD_Aug_SpyDrone")
				{
					spyaug = DD_Aug_SpyDrone(aughld.augs[i]);
					if(spyaug.drone_actor && spyaug.drone_actor.health > 0)
					{
						switch(e.args[0])
						{
							case 0: spyaug.drone_actor.queueAccelerationX(double(e.args[1]) / 10000); break;
							case 1: spyaug.drone_actor.queueAccelerationY(double(e.args[1]) / 10000); break;
							case 2: spyaug.drone_actor.queueAccelerationZ(double(e.args[1]) / 10000); break;
							case 3: spyaug.drone_actor.queueTurnAngle((double)(e.args[1]) / 10000);
							case 4: spyaug.drone_actor.queueUse();
						}
					}
				}
			}
		}
	}
	override void consoleProcess(ConsoleEvent e)
	{
		if(e.name == "dd_toggle_ui_augs")
		{
			// Open/close augmentations UI
			// Arguments: none

			wndmgr.addWindow(self, wnd_augs, 10, 5);
			wndmgr.addWindow(self, wnd_augs_sidepanel, 150, 5);

			// Closing windows is done in window classes themselves.
		}
	}
}

class DD_InputEventHandler : EventHandler
{
	override void onRegister()
	{
		SetOrder(1000);
	}

	override bool inputProcess(InputEvent e)
	{
		//if(e.type == UIEvent.Type_KeyDown)
		//	console.printf("%d", e.keyScan);
		//return true;

		DD_AugsHolder aughld;
		if(players[consoleplayer].mo)
			aughld = DD_AugsHolder(players[consoleplayer].mo.findInventory("DD_AugsHolder"));
		if(aughld)
			if(aughld.inputProcess(e))
				return true;
		return false;
	}
}
