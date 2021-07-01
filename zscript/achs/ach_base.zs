// Description:
// Class that manages achievements (calling event callbacks, disaplying pop-ups, managing saved progress)
class DD_AchievementManager : StaticEventHandler
{
	array<class<DD_Achievement> > ach_classes;
	
	override void onRegister()
	{
		for(uint i = 0; i < allClasses.size(); ++i)
		{
			if(allClasses[i] is "DD_Achievement"
			&& allClasses[i] != "DD_Achievement")
				ach_classes.push(allClasses[i]);
		}
	}

	override void PlayerSpawned(PlayerEvent e)
	{
		PlayerPawn plr = players[e.playerNumber].mo;
		if(plr.countInv("DD_AchievementHolder") == 0)
			plr.addInventory(DD_AchievementHolder.makeInstance(plr));
	}


	// Util functions
	protected void checkCompletion(DD_AchievementHolder ah)
	{
		for(uint i = 0; i < ah.achs.size(); ++i)
			if(ah.achs[i].complete)
			{
				DD_Achievement ach = ah.achs[i];

				CVar ach_finished_var = CVar.getCVar("dd_ach_finished", ah.owner.player);
				string ach_finished_str = ach_finished_var.getString();
				ach_finished_str = ach_finished_str .. "," .. ach.getClassName();
				ach_finished_var.setString(ach_finished_str);

				ah.queue.todisp.push(ach);
				ah.achs.delete(i); --i;
			}
	}


	// Classic engine events
	override void worldTick()
	{
		for(uint i = 0; i < MAXPLAYERS; ++i) {
			if(!playeringame[i]) continue;
			PlayerPawn plr = players[i].mo;
			let ah = DD_AchievementHolder(plr.findInventory("DD_AchievementHolder"));
			for(uint i = 0; i < ah.achs.size(); ++i){
				ah.achs[i].worldTick();
			}
			checkCompletion(ah);
		}
	}

	// Rendering assets
	ui bool ui_init;
	ui Font ach_title_font;
	ui Font ach_text_font;
	ui TextureID ach_bg;

	// Currently displayed completed achievement
	ui DD_Achievement disp_ach;
	ui vector2 disp_ach_pos;
	ui int disp_ach_state; // 0 - moving up; 1 - staying; 2 - moving down
	ui uint disp_ach_timer;
	ui int ach_soundtimer;

	// Animation settings
	const disp_ach_boxw = 140;
	const disp_ach_boxh = 30;
	const disp_ach_iconw = 25;
	const disp_ach_iconh = 25;
	const disp_ach_textw = 80;

	const disp_ach_x = 180;
	const disp_text_offx = 26;

	const disp_ach_ymin = 158;
	const disp_ach_ymax = 200;
	const disp_ach_ytick = 4;
	const disp_ach_time = 35 * 8;

	const ach_sounddelay = 6; // delay before starting any sounds
	const ach_soundtime = 35 * 3; // delay between generic and specific sounds

	override void uiTick()
	{
		if(!ui_init){
			ui_init = true;
			ach_title_font = Font.getFont("DD_UIBold");
			ach_text_font = Font.getFont("DD_UI");
			ach_bg = TexMan.checkForTexture("AUGUI39");
		}

		if(!disp_ach){
			PlayerPawn plr = players[consoleplayer].mo;
			if(plr)
			{
				let ah = DD_AchievementHolder(plr.findInventory("DD_AchievementHolder"));
				if(ah && ah.queue.todisp.size() > 0)
				{
					disp_ach = ah.queue.todisp[0];
					disp_ach_pos = (disp_ach_x, disp_ach_ymax);
					disp_ach_state = 0;

					ach_soundtimer = ach_soundtime + ach_sounddelay;

					ah.queue.todisp.delete(0);
					disp_ach.ui_init();
				}
			}
		}
		else{
			PlayerPawn plr = players[consoleplayer].mo;
			if(ach_soundtimer > ach_soundtime){
				ach_soundtimer--;
			}
			else if(ach_soundtimer == ach_soundtime){
				SoundUtils.uiStartSound("achievement/generic", plr);
				ach_soundtimer--;
			}
			else if(ach_soundtimer > 0){
				ach_soundtimer--;
			}
			else if(ach_soundtimer == 0){
				ach_soundtimer = -1;
				SoundUtils.uiStartSound(disp_ach.sound, plr);
			}

			switch(disp_ach_state)
			{
				case 0:
					if(disp_ach_pos.y > disp_ach_ymin)
						disp_ach_pos.y = max(disp_ach_pos.y - disp_ach_ytick, disp_ach_ymin);
					else{
						disp_ach_timer = disp_ach_time;
						disp_ach_state = 1;
					}
					break;
				case 1:
					if(--disp_ach_timer == 0){
						disp_ach_state = 2;
					}
					break;
				case 2:
					if(disp_ach_pos.y < disp_ach_ymax)
						disp_ach_pos.y = min(disp_ach_pos.y + disp_ach_ytick, disp_ach_ymax);
					else{
						disp_ach = null;
					}
					break;
			}
		}
	}

	override void renderOverlay(RenderEvent e)
	{
		if(disp_ach){
			UI_Draw.texture(ach_bg, disp_ach_pos.x, disp_ach_pos.y,
						disp_ach_boxw, disp_ach_boxh);

			UI_Draw.texture(disp_ach.icon, disp_ach_pos.x + 2, disp_ach_pos.y + 2,
						disp_ach_iconw, disp_ach_iconh);
			UI_Draw.str(ach_title_font, disp_ach.name, 11,
					disp_ach_pos.x + 2 + disp_text_offx, disp_ach_pos.y + 2, -0.45, -0.45);
			UI_Draw.str_wrap(ach_text_font, disp_ach.desc, 11,
					disp_ach_pos.x + 2 + disp_text_offx, disp_ach_pos.y + 8,
					-0.4, -0.4, disp_ach_textw);
		}
	}


	// External functions for ease of use

	static DD_AchievementManager getInstance()
	{ return DD_AchievementManager(StaticEventHandler.find("DD_AchievementManager")); }

	void triggerAchievement(PlayerPawn plr, class<DD_Achievement> ach_cls)
	{
		let ah = DD_AchievementHolder(plr.findInventory("DD_AchievementHolder"));
		for(uint i = 0; i < ah.achs.size(); ++i)
			if(ah.achs[i] is ach_cls)
			{ ah.achs[i].complete = true; checkCompletion(ah); break; }
	}


	// Custom events

	void damageAbsorbed(PlayerPawn plr, int amt, DD_Augmentation aug)
	{
		let ah = DD_AchievementHolder(plr.findInventory("DD_AchievementHolder"));
		for(uint i = 0; i < ah.achs.size(); ++i)
			ah.achs[i].damageAbsorbed(amt, aug);
		checkCompletion(ah);
	}
	void damageBoosted(PlayerPawn plr, int amt, DD_Augmentation aug)
	{
		let ah = DD_AchievementHolder(plr.findInventory("DD_AchievementHolder"));
		for(uint i = 0; i < ah.achs.size(); ++i)
			ah.achs[i].damageBoosted(amt, aug);
		checkCompletion(ah);
	}

	void augInstalled(PlayerPawn plr, DD_AugsHolder hld, DD_Augmentation aug)
	{
		let ah = DD_AchievementHolder(plr.findInventory("DD_AchievementHolder"));
		for(uint i = 0; i < ah.achs.size(); ++i)
			ah.achs[i].augInstalled(hld, aug);
		checkCompletion(ah);
	}
	void augUpgraded(PlayerPawn plr, DD_Augmentation aug)
	{
		let ah = DD_AchievementHolder(plr.findInventory("DD_AchievementHolder"));
		for(uint i = 0; i < ah.achs.size(); ++i)
			ah.achs[i].augUpgraded(aug);
		checkCompletion(ah);
	}
}



// Description:
// Class that contains achievement progress of each player in the game.
struct DD_AchievementQueue
{
	array<DD_Achievement> todisp;
}
class DD_AchievementHolder : Inventory
{
	default
	{
		+DONTGIB;
	}

	array<DD_Achievement> achs;
	DD_AchievementQueue queue;

	// Creates a new instance with all currently present achievements.
	static DD_AchievementHolder makeInstance(PlayerPawn owner)
	{
		let mngr = DD_AchievementManager(StaticEventHandler.find("DD_AchievementManager"));
		let inst = DD_AchievementHolder(Actor.Spawn("DD_AchievementHolder"));

		// Player argument doesn't do anything, since user-scoped CVars apparently
		// do not save changes done via CVar methods, at all!
		string ach_finished_str = CVar.getCVar("dd_ach_finished", owner.player).getString();
		array<string> ach_finished;
		ach_finished_str.split(ach_finished, ",");

		for(uint i = 0; i < mngr.ach_classes.size(); ++i)
		{
			int skip = 0;
			for(uint j = 0; j < ach_finished.size(); ++j)
			{
				if(mngr.ach_classes[i].getClassName() == ach_finished[j])
				{ skip = 1; break; }
			}
			if(skip) continue;

			let ach = DD_Achievement(new(mngr.ach_classes[i]));
			ach.play_init();
			ach.owner = owner;
			inst.achs.push(ach);
		}
		return inst;
	}
}


// Description:
// Class that describes an achievement, providing event callbacks for the achievement manager.
class DD_Achievement
{
	// Basic info

	PlayerPawn owner;
	bool complete;

	ui string name;
	ui string desc;
	ui TextureID icon;
	ui string sound;

	play virtual void play_init() {}
	ui virtual void ui_init() {}

	// Classic engine events
	virtual void worldTick() {}

	// Custom events
	virtual void damageAbsorbed(int amt, DD_Augmentation aug) {}
	virtual void damageBoosted(int amt, DD_Augmentation aug) {}

	virtual void augUpgraded(DD_Augmentation aug) {}
	virtual void augInstalled(DD_AugsHolder hld, DD_Augmentation aug) {}
}
