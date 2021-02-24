class DD_Aug_Regeneration : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}

	override int get_base_drain_rate(){ return 175 + 25 * (getRealLevel() - 1); }

	override void install()
	{
		super.install();

		id = 5;
		disp_name = "Regeneration";
		disp_desc = "Programmable polymerase automatically directs\n"
			    "construction of proteins in injured cells, restoring an\n"
			    "agent to full health over time.\n\n"
			    "TECH ONE: Healing occurs at a normal rate.\n\n"
			    "TECH TWO: Healing occurs at a slightly faster\ rate.\n\n"
			    "TECH THREE: Healing occurs at a moderately faster rate.\n\n"
			    "TECH FOUR: Healing occurs at a significantly faster rate.\n\n";

		slots_cnt = 3;
		slots[0] = Torso1;
		slots[1] = Torso2;
		slots[2] = Torso3;

		regen_timer = getHealthRegenInterval();
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("REGEN0");
		tex_on = TexMan.CheckForTexture("REGEN1");
	}

	// ------------------
	// Internal functions
	// ------------------

	protected int getHealthRegenRate() { return 2 + 1 * (getRealLevel() - 1); }
	protected int getHealthRegenInterval()
	{
		if(getRealLevel() <= max_level)
			return 40 - 7 * (getRealLevel() - 1);
		else
			return 40 - 7 * (max_level - 1) - 3 * (getRealLevel() - max_level);
	}

	// -------------
	// Engine events
	// -------------

	int regen_timer;

	override void tick()
	{
		super.tick();
		if(!enabled)
			return;

		if(regen_timer > 0)
			--regen_timer;
		else{
			if(!owner.giveInventory("Health", getHealthRegenRate()))
				toggle();
			regen_timer = getHealthRegenInterval();
		}
	}
}
