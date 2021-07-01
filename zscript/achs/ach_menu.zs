class DD_AchievementMenu : OptionMenu
{
	Font ach_title_font;
	Font ach_text_font;
	TextureID ach_bg;

	array<DD_Achievement> achs_finished;
	array<DD_Achievement> achs_available;

	override void init(Menu parent, OptionMenuDescriptor desc)
	{
		super.init(parent, desc);

		ach_title_font = Font.getFont("DD_UIBold");
		ach_text_font = Font.getFont("DD_UI");
		ach_bg = TexMan.checkForTexture("AUGUI39");

		string ach_finished_str = CVar.getCVar("dd_ach_finished", players[consoleplayer]).getString();
		array<string> achs_strs;
		ach_finished_str.split(achs_strs, ",");

		for(uint i = 0; i < allClasses.size(); ++i)
		{
			if(allClasses[i] is "DD_Achievement"
			&& allClasses[i] != "DD_Achievement")
			{
				int finished = 0;
				for(uint j = 0; j < achs_strs.size(); ++j)
				{
					if(allClasses[i].getClassName() == achs_strs[j])
					{ 
						achs_finished.push(DD_Achievement(new(allClasses[i])));
						achs_finished[achs_finished.size()-1].ui_init();
						finished = 1; break;
					}
				}
				if(finished) continue;
				achs_available.push(DD_Achievement(new(allClasses[i])));
				achs_available[achs_available.size()-1].ui_init();
			}
		}

		cur_ioff = 0;
		max_ioff = achs_finished.size() + achs_available.size()
			 - ((200.0 - ach_box_toffy - ach_box_boffy) / (ach_box_h + ach_box_moffy));
		
	}


	const ach_box_loffx = 10; // offset from left edge of the screen
	const ach_box_toffy = 17; // offset from top edge of the screen
	const ach_box_boffy = 10; // offset from bottom edge of the screen
	const ach_box_moffy = 2; // offset between achievement boxes

	const ach_box_w = 300;
	const ach_box_h = 25;
	const ach_text_w = 240;
	const ach_icon_w = 20;
	const ach_icon_h = 20;
	const ach_title_font_sz = -0.7;
	const ach_text_font_sz = -0.5;
	const ach_text_offy = 11;

	int cur_ioff; // current achievement index offset
	int max_ioff; // maximum achievement index offset, calulated during Init() call

	override void drawer()
	{
		super.drawer();

		UI_Draw.str(ach_title_font, "DeusDoom Achievements", 11,
				UI_Draw.strWidth(ach_title_font, "DeusDoom Achievements", -1, -1) / 2, 1,
				-1, -1);

		double x = ach_box_loffx, y = ach_box_toffy;
		uint i = 0;
		for(; i < achs_finished.size(); ++i)
		{
			UI_Draw.texture(ach_bg, x, y, ach_box_w, ach_box_h);
			UI_Draw.texture(achs_finished[i].icon, x + 2, y + 2,
						ach_icon_w, ach_icon_h);
			UI_Draw.str(ach_title_font, achs_finished[i].name, 11,
						x + 4 + ach_icon_w, y + 2,
						ach_title_font_sz, ach_title_font_sz);
			UI_Draw.str_wrap(ach_text_font, achs_finished[i].desc, 11,
						x + 4 + ach_icon_w, y + 2 + ach_text_offy,
						ach_text_font_sz, ach_text_font_sz,
						ach_text_w);

			y += ach_box_moffy + ach_box_h;
			if(y >= 320 - ach_box_boffy)
				return;
		}
		for(; i < achs_finished.size() + achs_available.size(); ++i)
		{
			uint j = i - achs_finished.size();
			UI_Draw.texture(ach_bg, x, y, ach_box_w, ach_box_h);
			UI_Draw.texture(achs_available[j].icon, x + 2, y + 2,
						ach_icon_w, ach_icon_h,
						UI_Draw_Grayscale);
			UI_Draw.str(ach_title_font, achs_available[j].name, Font.CR_GRAY,
						x + 4 + ach_icon_w, y + 2,
						ach_title_font_sz, ach_title_font_sz);
			UI_Draw.str_wrap(ach_text_font, achs_available[j].desc, Font.CR_GRAY,
						x + 4 + ach_icon_w, y + 2 + ach_text_offy,
						ach_text_font_sz, ach_text_font_sz,
						ach_text_w);

			y += ach_box_moffy + ach_box_h;
			if(y >= 320 - ach_box_boffy)
				return;
		}
	}

	override bool MenuEvent(int mkey, bool controller)
	{
		super.MenuEvent(mkey, controller);

		switch(mkey)
		{
			case MKEY_Up:
			{
				cur_ioff--;
				if(cur_ioff < 0) cur_ioff = 0;
				else MenuSound("menu/cursor");
			} return true;
			case MKEY_Down:
			{
				cur_ioff++;
				if(cur_ioff > max_ioff) cur_ioff = max_ioff;
				else MenuSound("menu/cursor");
			} return true;
		}
		return false;
	}
}
