class DD_Aug_CombatStrength : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}

	override int get_base_drain_rate(){ return 50; }

	override void install()
	{
		super.install();

		id = 3;
		disp_name = "Combat Strength";
		disp_desc = "Sorting rotors accelerate calcium ion concentration\n"
			     "in the sarcoplasmic reticulum, increasing an agent's\n"
			     "muscle speed several-fold and multiplying the damage\n"
			     "they inflict in melee combat.\n\n"
			     "TECH ONE: The effectiveness of melee weapons is\n"
			     "increased slightly.\n\n"
			     "TECH TWO: The effectiveness of melee weapons is\n"
			     "increased moderately.\n\n"
			     "TECH THREE: The effectiveness of melee weapons is\n"
			     "increased significantly.\n\n"
			     "TECH FOUR: Melee weapons are almost instantly lethal.\n\n"
			     "Energy Rate: 50 Units/Minute";

		slots_cnt = 1;
		slots[0] = Arms;
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("COMBSTR0");
		tex_on = TexMan.CheckForTexture("COMBSTR1");
	}

	// ------------------	
	// Internal functions
	// ------------------

	protected double getDamageFactor() { return 1 + 0.3 * getRealLevel(); }

	// ------
	// Events
	// ------

	override void ownerDamageDealt(int damage, Name damageType, out int newDamage,
					Actor inflictor, Actor source, int flags)
	{
		if(!enabled)
			return;
		if(!(owner is "PlayerPawn"))
			return;

		// source is actually the victim that got hit by augmentation owner (player)
		if(RecognitionUtils.isHandToHandDamage(PlayerPawn(owner), inflictor, source, damageType, flags))
		{
			newDamage = damage * getDamageFactor();
		}
	}
}
