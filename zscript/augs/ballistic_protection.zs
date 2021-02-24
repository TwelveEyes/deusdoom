class DD_Aug_BallisticProtection : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}

	override int get_base_drain_rate(){ return 80; }

	override void install()
	{
		super.install();

		id = 1;
		disp_name = "Ballistic Protection";
		disp_desc = "Monomolecular plates reinforce the skin's epithelial\n"
			    "membrane, reducing the damage an agent recieves\n"
			    "from bullet-like projectiles and piercing melee attacks.\n\n"
			    "TECH ONE: Damage from projectiles and melee attacks\n"
			    "is reduced sligthly.\n\n"
			    "TECH TWO: Damage from projectiles and melee attacks\n"
			    "is reduced moderately.\n\n"
			    "TECH THREE: Damage from projectiles and melee attacks\n"
			    "weapons is reduced significantly.\n\n"
			    "TECH FOUR: An agent is nearly invulnurable to damage\n"
			    "from projectiles and melee attacks.\n\n"
			    "Energy Rate: 80 Units/Minute";

		slots_cnt = 2;
		slots[0] = Subdermal1;
		slots[1] = Subdermal2;
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("BALPROT0");
		tex_on = TexMan.CheckForTexture("BALPROT1");
	}

	// ------------------
	// Internal functions
	// ------------------

	protected double getProtectionFactor()
	{
		if(getRealLevel() <= max_level)
			return 0.20 + 0.166 * (getRealLevel() - 1);
		else
			return 0.20 + 0.166  * (max_level - 1) + 0.1 * (getRealLevel() - max_level);
	}

	// ------
	// Events
	// ------

	override void ownerDamageTaken(int damage, Name damageType, out int newDamage,
					Actor inflictor, Actor source, int flags)
	{
		if(!enabled)
			return;

		double protfact_ml;
		if(RecognitionUtils.damageIsBallistic(inflictor, source, damageType, flags, protfact_ml))
		{
			newDamage = damage * (1 - getProtectionFactor() * protfact_ml);
			DD_AugsHolder aughld = DD_AugsHolder(players[consoleplayer].mo.findInventory("DD_AugsHolder"));
			aughld.absorbtion_msg = String.Format("%.0f%% ABSORB", getProtectionFactor()*100*protfact_ml);
			aughld.absorbtion_msg_timer = 35 * 2;
		}
	}
}
