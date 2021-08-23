class DD_Aug_Cloak : DD_Augmentation
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

		id = 10;
		disp_name = "Cloak";
		disp_desc = "Subdermal pigmentation cells allow an agent to blend with\n"
			    "their surrounding environment, rendering them effectively\n"
			    "invisible to observation by organic hostiles. Attacking by\n"
			    "any means breaks invisibility by a brief moment.\n\n"
			    "TECH ONE: Power drain is normal, invisiblity recovers slow.\n\n"
			    "TECH TWO: Power drain is reduced slightly, invisibility\n"
			    "recovers faster.\n\n"
			    "TECH THREE: Power drain is reduced moderately,\n"
			    "invisibility recovers fast.\n\n"
			    "TECH FOUR: Power drain is reduced significantly,\n"
			    "invisibility restores almost instantly.\n\n";
			    "Energy Rate: 400-250 Units/Minute";

		slots_cnt = 2;
		slots[0] = Subdermal1;
		slots[1] = Subdermal2;
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("CLOAK0");
		tex_on = TexMan.CheckForTexture("CLOAK1");
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

		owner.A_SetRenderStyle(1.0, Style_Fuzzy);

		Actor mnst;
		ThinkerIterator it = ThinkerIterator.create();

		if(DD_ModChecker.getInstance().isLoaded_HDest()
			&& DD_PatchChecker.getInstance().isLoaded_HDest())
		{
			while(mnst = Actor(it.next()))
			{
				if(!mnst.bIsMonster)
					continue;
				if(!RecognitionUtils.isFooledByCloak(mnst))
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
				if(!RecognitionUtils.isFooledByCloak(mnst))
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
			owner.A_SetRenderStyle(1.0, Style_Normal);

			Actor mnst;
			ThinkerIterator it = ThinkerIterator.create();
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

