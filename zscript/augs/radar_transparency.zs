class DD_Aug_RadarTransparency : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}


	override int get_base_drain_rate()
	{
		if(getRealLevel() <= max_level){
			if(blinktimer == 0)
				return 400 - 50 * (getRealLevel() - 1);
			else
				return 200 - 25 * (getRealLevel() - 1);
		}
		else{
			if(blinktimer == 0)
				return 400 - 50 * (max_level - 1);
			else
				return 200 - 25 * (max_level - 1);
		}
	}

	override void install()
	{
		super.install();

		id = 12;
		disp_name = "Radar Transparency";
		disp_desc = "Radar-absorbent resin augments epithelial proteins;\n"
			    "microprojection units distort agent's visual signature.\n"
			    "Provides highly effective concealment from electronic\n"
			    "detection methods used by cybernetic enemies. Attacking\n"
			    "by any means breaks this effect by a brief moment.\n\n"
			    "TECH ONE: Power drain is normal, agent is discovered\n"
			    "for a significant period of time.\n\n"
			    "TECH TWO: Power drain is reduced slightly, agent becomes\n"
			    "undetectable faster after attacking.\n\n"
			    "TECH THREE: Power drain is reduced moderately, agent\n"
			    "becomes undetectable significantly faster.\n\n"
			    "TECH FOUR: Power drain is reduced significantly. agent\n"
			    "is detected for a very brief moment.\n\n"
			    "Energy Rate: 400-250 Units/Minute";

		slots_cnt = 2;
		slots[0] = Subdermal1;
		slots[1] = Subdermal2;
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("RADTRNP0");
		tex_on = TexMan.CheckForTexture("RADTRNP1");
	}


	int getBlinkTime()
	{
		if(getRealLevel() <= max_level)
			return 45 - 12 * (getRealLevel() - 1);
		else
			return 45 - 12 * (max_level - 1) - 3 * (getRealLevel() - max_level);
	}
	int blinktimer; // timer that start when player starts an attack,
			// revealing him for a short time.

	override void tick()
	{
		super.tick();

		if(!enabled){
			return;
		}

		if(owner.curstate == PlayerPawn(owner).MissileState
		|| owner.curstate == PlayerPawn(owner).MeleeState)
		{
			owner.A_SetRenderStyle(1.0, Style_Normal);
			blinktimer = getBlinkTime();
			return;
		}
		if(blinktimer > 0){
			--blinktimer;
			return;
		}

		Actor mnst;
		ThinkerIterator it = ThinkerIterator.create("Actor", STAT_DEFAULT);
		if(DD_ModChecker.getInstance().isLoaded_HDest()
			&& DD_PatchChecker.getInstance().isLoaded_HDest())
		{
			while(mnst = Actor(it.next()))
			{
				if(!mnst.bIsMonster)
					continue;
				if(!RecognitionUtils.isFooledByRadarTransparency(mnst))
					continue;
	
				Class<Actor> tgclr_cls = ClassFinder.findActorClass("DD_HDTargetClearer");
				Actor tgclr = Spawn(tgclr_cls);
				tgclr.target = mnst;
				tgclr.master = owner;
			}
		}
		else
		{
			while(mnst = Actor(it.next()))
			{
				if(!mnst.bIsMonster)
					continue;
				if(!RecognitionUtils.isFooledByRadarTransparency(mnst))
					continue;

				if(mnst.target && mnst.target == owner){
					mnst.target = null;
					mnst.seeSound = "";
				}
			}
		}
	}

	override void toggle()
	{
		super.toggle();
		if(enabled)
			SoundUtils.playStartSound("ui/aug/cloak_up", owner);
		else
			SoundUtils.playStartSound("ui/aug/cloak_down", owner);

		if(!enabled){
			Actor mnst;
			ThinkerIterator it = ThinkerIterator.create("Actor", STAT_DEFAULT);
			while(mnst = Actor(it.next()))
			{
				if(!mnst.bIsMonster)
					continue;

				if(mnst.seeSound == "")
					mnst.seeSound = getDefaultByType(mnst.getClass()).seeSound;

				if(DD_ModChecker.getInstance().isLoaded_HDest()
					&& DD_PatchChecker.getInstance().isLoaded_HDest())
				{
					Class<Actor> tgrst_cls = ClassFinder.findActorClass("DD_HDTargetRestorer");
					Actor tgrst = Spawn(tgrst_cls);
					tgrst.target = mnst;
				}
			}
		}
	}

}
