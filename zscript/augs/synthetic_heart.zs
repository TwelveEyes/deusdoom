class DD_Aug_SyntheticHeart : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}

	override int get_base_drain_rate(){ return 150; }

	override void install()
	{
		super.install();

		max_level = 1;

		id = 15;
		disp_name = "Synthetic Heart";
		disp_desc = "This synthetic heart circulates not only blood but a\n"
			    "steady concentration of mechanochemical power cells,\n"
			    "smart phagocytes, and liposomes containing prefab\n"
			    "diamondoid machine parts, resulting in upgraded\n"
			    "performance for all installed augmentations.\n\n"
			    "<UNATCO OPS FILE NOTE JR133-VIOLET> Interestingly,\n"
			    "this WILL enhance any augmentation past its maximum\n"
			    "upgrade level, but not as effectively.\n"
			    "-- Jaime Reyes <END NOTE>\n\n"
			    "Energy Rate: 150 Units/Minute";

		slots_cnt = 3;
		slots[0] = Torso1;
		slots[1] = Torso2;
		slots[2] = Torso3;
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("SYNHRT0");
		tex_on = TexMan.CheckForTexture("SYNHRT1");
	}

	int aug_dlevel[DD_AugsHolder.augs_slots];
	override void toggle()
	{
		super.toggle();

		if(!owner)
			return;
		let aughld = DD_AugsHolder(owner.findInventory("DD_AugsHolder"));
		if(!aughld)
			return;
		if(enabled)
			aughld.level_boost = 1;
		else
			aughld.level_boost = 0;
	}
}
