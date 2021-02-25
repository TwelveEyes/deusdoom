class DD_Aug_AggressiveDefenseSystem : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	// Targeted projectiles projection
	ui DDLe_ProjScreen proj_scr;
	DDLe_SWScreen proj_sw;
	DDLe_GLScreen proj_gl;
	ui DDLe_Viewport vwport;

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}

	override int get_base_drain_rate(){ return 60; }

	protected void initProjection()
	{
		proj_sw = new("DDLe_SWScreen");
		proj_gl = new("DDLe_GLScreen");
	}
	protected ui void prepareProjection()
	{
		CVar renderer_type = CVar.getCVar("vid_rendermode", players[consoleplayer]);

		if(renderer_type)
		{
			switch(renderer_type.getInt())
			{
				case 0: case 1: proj_scr = proj_sw; break;
				default:	proj_scr = proj_gl; break;
			}
		}
		else
			proj_scr = proj_gl;
	}

	override void install()
	{
		super.install();

		id = 8;
		disp_name = "Aggressive Defense System";
		disp_desc = "Aerosol nanoparticles are released upon the detection\n"
			    "of objects fitting the electromagnetic threat profile of\n"
			    "various missiles, like rockets or seeking missiles.\n"
			    "These nanoparticles will prematurely detonate such\n"
			    "objects prior to reaching the agent.\n\n"
			    "TECH ONE: The range at which incoming projectiles\n"
			    "are detonated is short, and cooldown is long.\n\n"
			    "TECH TWO: The range at which detonation occurs is\n"
			    "increased slightly and it goes off cooldown faster.\n\n"
			    "TECH THREE: The range at which detonation occurs is\n"
			    "increased moderately and it recharges even faster.\n\n"
			    "TECH FOUR: Projectiles are detonated very afar and\n"
			    "very often.\n\n"
			    "Energy Rate: 60 Units/Minute";

		slots_cnt = 1;
		slots[0] = Cranial;

		initProjection();
	}

	override void UIInit()
	{
		tex_off = TexMan.checkForTexture("AGRDSYS0");
		tex_on = TexMan.checkForTexture("AGRDSYS1");
	}

	// ------------------
	// Internal functions
	// ------------------

	int destr_cd;		    // projectile desctruction cooldown

	clearscope double getRange()
	{
		if(getRealLevel() <= max_level)
			return 140 + 16 * (getRealLevel() - 1);
		else
			return 140 + 16 * (max_level - 1) + 10 * (getRealLevel() - max_level);
	}
	int getBaseCD()
	{
		if(getRealLevel() <= max_level)
			return 57 - 15 * (getRealLevel() - 1);
		else
			return 57 - 15 * (max_level - 1) - 4 * (getRealLevel() - max_level);
	}

	array<double> proj_dispx;
	array<double> proj_dispy;
	array<double> proj_dispz;

	void detonateProjInRange()
	{
		if(!owner)
			return;

		if(destr_cd > 0)
			--destr_cd;
		Actor proj;
		ThinkerIterator it = ThinkerIterator.create();
		double cd_ml;
		proj_dispx.clear();
		proj_dispy.clear();
		proj_dispz.clear();
		while(proj = Actor(it.next()))
		{
			if(owner.Distance3D(proj) <= getRange() * 8.0
			&& RecognitionUtils.projCanBeDestroyed(proj, cd_ml))
			{
				proj_dispx.push(proj.pos.x);
				proj_dispy.push(proj.pos.y);
				proj_dispz.push(proj.pos.z);
			}

			if(owner.Distance3D(proj) > getRange())
				continue;
			if(RecognitionUtils.projCanBeDestroyed(proj, cd_ml)){
				if(destr_cd == 0){
					proj.die(proj, proj);
					destr_cd = getBaseCD() * cd_ml;
				}
			}
		}
	}

	// ------
	// Events
	// ------

	override void tick()
	{
		super.tick();
		if(!enabled)
			return;
		detonateProjInRange();
	}

	ui int ui_beep_timer; // timer between beeps; counts FROM zero till a certain value
			      // based on proximity to closest projectile that can be detonated.

	override void drawOverlay(RenderEvent e, DD_EventHandler hndl)
	{
		if(!enabled)
			return;

		if(destr_cd > 0)
			UI_Draw.str(hndl.aug_ui_font,
					String.Format("Aggr.Def.Sys. CD %.2fs", double(destr_cd) / 35),
					10, 8, 8, -0.7, -0.7);

		// Projecting any incoming projectiles' coordinates and then rendering a string
		vwport.fromHUD();
		prepareProjection();

		proj_scr.cacheResolution();
		proj_scr.cacheFOV();
		proj_scr.orientForRenderOverlay(e);
		proj_scr.beginProjection();

		double proj_min_dist = 999999;

		for(uint i = 0; i < proj_dispx.size(); ++i)
		{
			vector3 proj_pos = (proj_dispx[i], proj_dispy[i], proj_dispz[i]);
			proj_scr.projectWorldPos(proj_pos);
			vector2 proj_norm = proj_scr.projectToNormal();
			vector2 str_pos = vwport.sceneToWindow(proj_norm);

			if(!vwport.isInside(proj_norm) || !proj_scr.isInScreen())
				continue;

			str_pos.x *= double(320) / screen.getWidth();
			str_pos.y *= double(200) / screen.getHeight();

			double text_w = -0.5;
			double text_h = -0.5;

			double tstr_w = UI_Draw.strWidth(hndl.aug_ui_font, "* ADS Tracking *", text_w, text_h);
			double tstr_h = UI_Draw.strHeight(hndl.aug_ui_font, "* ADS Tracking *", text_w, text_h);
			double proj_dist = ((proj_pos - owner.pos).length()
						- owner.radius);
			double proj_ft_dist = proj_dist
						/ 32 * 3.28; // roughly "converting" to meters and then to feet
							     // https://doomwiki.org/wiki/Map_unit
			if(proj_dist < proj_min_dist)
				proj_min_dist = proj_dist;

			UI_Draw.str(hndl.aug_ui_font, "* ADS Tracking *", 10,
					str_pos.x - tstr_w/2, str_pos.y, text_w, text_h);
			UI_Draw.str(hndl.aug_ui_font, string.format("Range %.0f ft (%.0f map units)",
								round(proj_ft_dist), round(proj_dist)),
					10,
					str_pos.x - tstr_w/2, str_pos.y + tstr_h + 1, text_w, text_h);
		}

		if(proj_min_dist < 999999)
		{
			if(ui_beep_timer >= (proj_min_dist / getRange() * 4.0) * 2){
				SoundUtils.uiStartSound("ui/aug/agressive_defense_system_beep");
				ui_beep_timer = 0;
			}
			else
				++ui_beep_timer;
		}
	}
}
