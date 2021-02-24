class UI_DDInstalledAugLevelDisplay : UI_Widget
{
	ui int aug_slot; // slot to display

	// Texture dimensions, as used in UI_Draw::texture()
	// They apply to each separate level checklet
	ui double tex_w;
	ui double tex_h;

	// Textures
	ui TextureID checklet;

	override void UIinit()
	{
		checklet = TexMan.CheckForTexture("AUGUI11");
	}

	override void drawOverlay(RenderEvent e)
	{
		PlayerInfo plr = players[consoleplayer];
		DD_AugsHolder aughld = DD_AugsHolder(plr.mo.FindInventory("DD_AugsHolder"));
		DD_Augmentation au = aughld.augs[aug_slot];

		double sx = x;
		double sy = y;
		double chk_gap = 0.44;
		if(au)
		{
			for(uint lvl = 1; lvl <= au.level; ++lvl)
			{
				UI_Draw.texture(checklet, sx, sy, tex_w, tex_h);
				sx += UI_Draw.texWidth(checklet, tex_w, tex_h) + chk_gap;
			}
		}
	}
}
