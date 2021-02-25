class DD_Aug_PowerRecirculator : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}

	override int get_base_drain_rate(){ return 10; }

	override void install()
	{
		super.install();

		id = 7;
		disp_name = "Power Recirculator";
		disp_desc = "Power consumption for all augmentations\ is reduced by\n"
			    "polianilene circuits, plugged directly into cell membranes,\n"
			    "that allow nanite particles to interconnect electronically\n"
			    "without leaving their host cells.\n\n"
			    "TECH ONE: Power drain of augmentations is reduced\n"
			    "slightly.\n\n"
			    "TECH TWO: Power drain of augmentations is reduced\n"
			    "moderately.\n\n"
			    "TECH THREE: Power drain of augmentations is reduced\n"
			    "for a good amount.\n\n"
			    "TECH FOUR: Power drain of augmentations is reduced\n"
			    "significantly.\n\n"
			    "Energy Rate: 10 Units/Minute";

		slots_cnt = 3;
		slots[0] = Torso1;
		slots[1] = Torso2;
		slots[2] = Torso3;
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("POWREC0");
		tex_on = TexMan.CheckForTexture("POWREC1");
	}

	// ------------------
	// Internal functions
	// ------------------

	protected double getPowerSaveFactor() { return 0.15 + 0.15 * (getRealLevel() - 1); }

	// -------------
	// Engine events
	// -------------

	override void tick()
	{
		super.tick();
		if(!owner)
			return;
		if(!enabled)
			return;

		DD_AugsHolder aughld = DD_AugsHolder(owner.findInventory("DD_AugsHolder"));
		if(!enabled){
			aughld.energy_drain_ml = 1.0;
		}
		else{
			aughld.energy_drain_ml = 1.0 - getPowerSaveFactor();
		}

		
	}
}
