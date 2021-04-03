class DD_Aug_EnvironmentalResistance : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}

	override int get_base_drain_rate(){ return 40; }

	override void install()
	{
		super.install();

		id = 13;
		disp_name = "Environmental Resistance";
		disp_desc = "Induced keratin production strengthens all epithelial\n"
			    "tissues and reduces an agent's vulnerability to radiation,\n"
			    "toxins and hot surfaces.\n\n"
			    "TECH ONE: Hazard resistance is increased slightly.\n\n"
			    "TECH TWO: Hazard resistance is increased moderately.\n\n"
			    "TECH THREE: Hazard resistance is increased\n"
			    "significantly.\n\n"
			    "TECH FOUR: An agent is invulnerable to damage from any.\n"
			    "environmental hazards.\n\n"
			    "Energy Rate: 40 Units/Minute";

		slots_cnt = 3;
		slots[0] = Torso1;
		slots[1] = Torso2;
		slots[2] = Torso3;
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("ENVRES0");
		tex_on = TexMan.CheckForTexture("ENVRES1");
	}

	// ------------------
	// Internal functions
	// ------------------

	protected double getProtectionFactor()
	{
		if(getRealLevel() <= max_level)
			return 0.25 + 0.25 * (getRealLevel() - 1);
		else
			return 0.25 + 0.25 * (max_level - 1);
	}

	// -------------
	// Engine events
	// -------------

	override void ownerDamageTaken(int damage, Name damageType, out int newDamage,
					Actor inflictor, Actor source, int flags)
	{
		if(!enabled)
			return;

		double protfact_ml;
		if(RecognitionUtils.damageIsEnvironmental(inflictor, source, damageType, flags, protfact_ml))
		{
			newDamage = damage * (1 - getProtectionFactor() * protfact_ml);
			DD_AugsHolder aughld = DD_AugsHolder(owner.findInventory("DD_AugsHolder"));
			aughld.absorbtion_msg = String.Format("%.0f%% ABSORB", getProtectionFactor() * 100 * protfact_ml);
			aughld.absorbtion_msg_timer = 35 * 1;
		}
	}
}
