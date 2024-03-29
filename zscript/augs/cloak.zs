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
		disp_desc = "Subdermal pigmentation cells allow an agent to blend\n"
			    "with their surrounding environment, rendering them\n"
			    "effectively invisible to observation by organic hostiles.\n"
			    "Attacking by any means breaks invisibility by a brief\n"
			    "moment.\n\n"
			    "TECH ONE: Power drain is normal, invisiblity recovers\n"
			    "slowly.\n\n"
			    "TECH TWO: Power drain is reduced slightly, invisibility\n"
			    "recovers faster.\n\n"
			    "TECH THREE: Power drain is reduced moderately,\n"
			    "invisibility recovers fast.\n\n"
			    "TECH FOUR: Power drain is reduced significantly,\n"
			    "invisibility restores almost instantly.\n\n"
			    "Energy Rate: 400-250 Units/Minute\n\n";

		disp_legend_desc = "LEGENDARY UPGRADE: Augmentation recieves\n"
				   "ability to make holograms within certain proximity\n"
				   "of agent, causing enemies to nonintentionally\n"
				   "attack each other.";

		slots_cnt = 2;
		slots[0] = Subdermal1;
		slots[1] = Subdermal2;

		can_be_legendary = true;
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
	int blinktimer; // timer that starts when player starts an attack,
			// revealing him for a short time.

	const trick_range = 512;
	const trick_cd_min = 35 * 8;
	const trick_cd_max = 35 * 18;
	int tricktimer; // timer that tracks cooldown of making enemies infight

	override void tick()
	{
		super.tick();

		if(!enabled || !owner){
			return;
		}

		if(isLegendary() && tricktimer > 0)
			--tricktimer;

		if(owner is "PlayerPawn"
		&& (owner.curstate == PlayerPawn(owner).MissileState
		 || owner.curstate == PlayerPawn(owner).MeleeState))
		{
			owner.A_SetRenderStyle(1.0, Style_Normal);
			blinktimer = getBlinkTime();
			return;
		}
		if(blinktimer > 0){
			--blinktimer;
			return;
		}

		if(owner is "PlayerPawn")
			owner.A_SetRenderStyle(1.0, Style_Fuzzy);
		else
			owner.A_SetRenderStyle(0.1, Style_Translucent);

		Actor mnst;
		ThinkerIterator it = ThinkerIterator.create("Actor", STAT_DEFAULT);

		if(DD_ModChecker.getInstance().isLoaded_HDest()
			&& DD_PatchChecker.getInstance().isLoaded_HDest())
		{
			Class<Actor> tgclr_cls = ClassFinder.findActorClass("DD_HDTargetClearer");
			Actor tgclr = Spawn(tgclr_cls);
			while(mnst = Actor(it.next()))
			{
				if(!mnst.bIsMonster || mnst.health <= 0)
					continue;
				if(!RecognitionUtils.isFooledByCloak(mnst))
					continue;
	
				tgclr.target = mnst;
				tgclr.master = owner;
				tgclr.PostBeginPlay();
			}
		}
		else
		{
			while(mnst = Actor(it.next()))
			{
				if(!mnst.bIsMonster || mnst.health <= 0)
					continue;
				if(!RecognitionUtils.isFooledByCloak(mnst))
					continue;

				if(mnst.target && mnst.target == owner){
					mnst.target = null;
					mnst.seeSound = "";
				}
			}
		}

		// Creating illusions
		BlockThingsIterator itb = BlockThingsIterator.Create(owner, trick_range);
		Actor prevmnst = null;
		while(itb.next())
		{
			Actor mnst = itb.thing;

			if(!mnst.bIsMonster || mnst.health <= 0)
				continue;
			if(!RecognitionUtils.isFooledByCloak(mnst))
				continue;

			if(isLegendary() && tricktimer == 0 && !random(0, 4)) // random() to just not always pick the same monster
			{
				if(prevmnst){
					mnst.target = prevmnst;
					let ill = DD_Player_Illusion(Spawn("DD_Player_Illusion", prevmnst.pos));
					ill.target = owner;

					tricktimer = random(trick_cd_min, trick_cd_max);
				}
				prevmnst = mnst;
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


class DD_Player_Illusion : Actor
{
	default
	{
		RenderStyle "Translucent";
		Alpha 0.75;

		Scale 1.15;
	}

	void randomizeVel()
	{
		A_ChangeVelocity(frandom(-2, 2), frandom(-2, 2), frandom(-1.2, 1.2),
				CVF_REPLACE);
	}

	vector3 firstpos;
	override void PostBeginPlay()
	{
		super.PostBeginPlay();

		firstpos = pos;
		sprite = target.sprite;
		randomizeVel();
	}

	int livetimer;
	const livetime = 35 * 2;

	override void Tick()
	{
		super.tick();

		if(livetimer > livetime){
			Destroy();
			return;
		}

		livetimer++;
		if( sqrt((firstpos.x-pos.x)**2 + (firstpos.y-pos.y)**2 + (firstpos.z-pos.z)**2) > 3){
			A_Warp(AAPTR_DEFAULT, firstpos.x, firstpos.y, firstpos.z, 0, WARPF_ABSOLUTEPOSITION);
			randomizeVel();
		}
	}
}
