class DD_Aug_EnergyShield : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}

	override int get_base_drain_rate(){ return 70; }

	override void install()
	{
		super.install();

		id = 6;
		disp_name = "Energy Shield";
		disp_desc = "Polyanilene capacitors below the skin absorb heat and\n"
			    "electricity, reducing the damage received from flame,\n"
			    "electrical, and plasma attacks.\n\n"
			    "TECH ONE: Damage from energy attacks is reduced\n"
			    "slightly.\n\n"
			    "TECH TWO: Damage from energy attacks is reduced\n"
			    "moderately.\n\n"
			    "TECH THREE: Damage from energy attacks is reduced\n"
			    "significantly.\n\n"
			    "TECH FOUR: An agent is nearly invulnerable to damage\n"
			    "from energy attacks.\n\n"
			    "Energy Rate: 70 Units/Minute";

		slots_cnt = 3;
		slots[0] = Torso1;
		slots[1] = Torso2;
		slots[2] = Torso3;
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("ENGSHLD0");
		tex_on = TexMan.CheckForTexture("ENGSHLD1");
	}

	// ------------------
	// Internal functions
	// ------------------

	protected double getProtectionFactor()
	{
		if(getRealLevel() <= max_level)
			return 0.20 + 0.15 * (getRealLevel() - 1);
		else
			return 0.20 + 0.15 * (max_level - 1) + 0.1 * (getRealLevel() - max_level);
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
		if(RecognitionUtils.damageIsEnergy(inflictor, source, damageType, flags, protfact_ml))
		{
			newDamage = damage * (1 - getProtectionFactor() * protfact_ml);
			DD_AugsHolder aughld = DD_AugsHolder(players[consoleplayer].mo.findInventory("DD_AugsHolder"));
			aughld.absorbtion_msg = String.Format("%.0f%% ABSORB", getProtectionFactor() * 100 * protfact_ml);
			aughld.absorbtion_msg_timer = 35 * 2;
		}
	}
}
