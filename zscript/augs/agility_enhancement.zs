struct DD_Aug_AgilityEnhancement_Queue
{
	int mov_keys_held;
	// amount of ticks passed since a key was pressed last time,
	// used to engage dashses.
	// 0 - forward, 1 - backward, 2 - left, 3 - right, 4 - up
	int mov_keys_timer[5];

	vector3 dashvel[5];
	double deacc;
	int vwheight_timer;
	double vwheight_prev;
	double vwheight_delta;
}
class DD_Aug_AgilityEnhancement : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	DD_Aug_AgilityEnhancement_Queue queue;
	int dash_cd;
	const vwheight_time = 20;
	const vwheight_time_coff = 0.30;

	bool use_doubletap_scheme; // keeps the value of dd_dash_on_doubletap CVAR between toggles
	int dash_tap_time; // also keeps a value of dd_dash_doubletap_timer CVAR
	bool dash_held;

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}

	override int get_base_drain_rate(){ return 55; }

	override void install()
	{
		super.install();

		id = 18;
		disp_name = "Agility Enhancement";
		disp_desc = "The necessary muscle movements for quick and precise\n"
			    "body motions determined continuously with reactive\n"
			    "kinematics equations produced by embedded\n"
			    "nanocomputers, allowing an agent to quickly change\n"
			    "their momentum even while in air.\n\n"
			    "TECH ONE: Deceleration is a bit faster, agent can\n"
			    "do short dashes and double jumps.\n\n"
			    "TECH TWO: Deceleration is faster, agent can do\n"
			    "longer dashes and double jumps.\n\n"
			    "TECH THREE: Decelration is significantly faster and\n"
			    "agent can perform stunningly long dashes.\n\n"
			    "TECH FOUR: Agent decelerates almost instantly and\n"
			    "can cross entire rooms in one leap.\n\n"
			    "Energy Rate: 55 Units/Minute";

		slots_cnt = 1;
		slots[0] = Legs;
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("SILENT0");
		tex_on = TexMan.CheckForTexture("SILENT1");
	}


	protected clearscope double getDeaccFactor()
	{
		return 0.2 + 0.35 * (getRealLevel() - 1);
	}
	protected clearscope double getDashVel()
	{
		return 15 + 7.5 * (getRealLevel() - 1);
	}
	protected clearscope int getDashCD()
	{
		return 45 - 8 * (getRealLevel() - 1);
	}

	override void toggle()
	{
		if(use_doubletap_scheme){
			queue.mov_keys_timer[0] = dash_tap_time+1;
			queue.mov_keys_timer[1] = dash_tap_time+1;
			queue.mov_keys_timer[2] = dash_tap_time+1;
			queue.mov_keys_timer[3] = dash_tap_time+1;
			queue.mov_keys_timer[4] = dash_tap_time+1;
		}
		else{
			queue.mov_keys_timer[0] = 0;
			queue.mov_keys_timer[1] = 0;
			queue.mov_keys_timer[2] = 0;
			queue.mov_keys_timer[3] = 0;
			queue.mov_keys_timer[4] = 0;
		}

		super.toggle();

		if(owner && owner.player){
			use_doubletap_scheme = CVar.getCVar("dd_dash_on_doubletap", owner.player).getFloat();
			dash_tap_time = CVar.getCVar("dd_dash_doubletap_timer", owner.player).getInt();
		}
	}

	override void tick()
	{
		super.tick();
		if(!owner || !(owner is "PlayerPawn"))
			return;
		if(queue.vwheight_timer > 0){
			--queue.vwheight_timer;

			if(queue.vwheight_timer > vwheight_time * vwheight_time_coff)
				owner.player.viewHeight -= queue.vwheight_delta / (vwheight_time * vwheight_time_coff);
			else
				owner.player.viewHeight += queue.vwheight_delta / (vwheight_time * (1 - vwheight_time_coff));

			if(queue.vwheight_timer == 0)
				owner.player.viewHeight = queue.vwheight_prev;
		}
		if(!enabled)
			return;


		if(abs(queue.deacc) > 0)
		{
			if(abs(owner.vel.x) > queue.deacc){
				if(owner.warp(owner, owner.vel.x, owner.vel.y, owner.vel.z, 0, WARPF_TESTONLY)){
					owner.A_ChangeVelocity((owner.vel.x > 0 ? -1 : 1)*queue.deacc, 0, 0);
					owner.warp(owner, -owner.vel.x, -owner.vel.y, -owner.vel.z, 0, WARPF_TESTONLY);
				}
			}
			else
				owner.A_ChangeVelocity(0, owner.vel.y, owner.vel.z, CVF_REPLACE);
			if(abs(owner.vel.y) > queue.deacc){
				if(owner.warp(owner, owner.vel.x, owner.vel.y, owner.vel.z, 0, WARPF_TESTONLY)){
					owner.A_ChangeVelocity(0, (owner.vel.y > 0 ? -1 : 1)*queue.deacc, 0);
					owner.warp(owner, -owner.vel.x, -owner.vel.y, -owner.vel.z, 0, WARPF_TESTONLY);
				}
			}
			else
				owner.A_ChangeVelocity(owner.vel.x, 0, owner.vel.z, CVF_REPLACE);
		}

		if(dash_cd > 0)
			--dash_cd;
		for(uint i = 0; i < 5; ++i)
		{
			if(use_doubletap_scheme && queue.mov_keys_timer[i] <= dash_tap_time)
				++queue.mov_keys_timer[i];
			if(dash_cd == 0 && queue.dashvel[i].length() > 0){
				owner.A_ChangeVelocity(queue.dashvel[i].x, queue.dashvel[i].y, queue.dashvel[i].z, CVF_RELATIVE);
				dash_cd = getDashCD();
				if(queue.dashvel[i].z == 0 && queue.vwheight_timer == 0){
					queue.vwheight_prev = owner.player.viewHeight;
					queue.vwheight_timer = vwheight_time;
					queue.vwheight_delta = owner.player.viewHeight * 0.8;
				}
			}
			queue.dashvel[i] = (0, 0, 0);
		}
	}


	override bool inputProcess(InputEvent e)
	{
		if(!enabled)
			return false;
		if(e.type == InputEvent.Type_KeyDown)
		{
			if(KeyBindUtils.checkBind(e.keyScan, "+forward")
			|| KeyBindUtils.checkBind(e.keyScan, "+back")
			|| KeyBindUtils.checkBind(e.keyScan, "+moveleft")
			|| KeyBindUtils.checkBind(e.keyScan, "+moveright"))
			{
				++queue.mov_keys_held;
				queue.deacc = 0.0;
			}

			if(use_doubletap_scheme)
			{
				if(KeyBindUtils.checkBind(e.keyScan, "+forward"))
				{
					if(queue.mov_keys_timer[0] <= dash_tap_time)
						queue.dashvel[0].x = getDashVel();
					queue.mov_keys_timer[0] = 0;
				}
				else if(KeyBindUtils.checkBind(e.keyScan, "+back"))
				{
					if(queue.mov_keys_timer[1] <= dash_tap_time)
						queue.dashvel[1].x = -getDashVel();
					queue.mov_keys_timer[1] = 0;
				}
				else if(KeyBindUtils.checkBind(e.keyScan, "+moveleft"))
				{
					if(queue.mov_keys_timer[2] <= dash_tap_time)
						queue.dashvel[2].y = getDashVel();
					queue.mov_keys_timer[2] = 0;
				}
				else if(KeyBindUtils.checkBind(e.keyScan, "+moveright"))
				{
					if(queue.mov_keys_timer[3] <= dash_tap_time)
						queue.dashvel[3].y = -getDashVel();
					queue.mov_keys_timer[3] = 0;
				}
				else if(KeyBindUtils.checkBind(e.keyScan, "+jump"))
				{
					if(queue.mov_keys_timer[4] <= dash_tap_time)
						queue.dashvel[4].z = getDashVel() * 0.7;
					queue.mov_keys_timer[4] = 0;
				}
			}
			else
			{
				if(KeyBindUtils.checkBind(e.keyScan, "+forward"))
					queue.mov_keys_timer[0] = 1;
				else if(KeyBindUtils.checkBind(e.keyScan, "+back"))
					queue.mov_keys_timer[1] = 1;
				else if(KeyBindUtils.checkBind(e.keyScan, "+moveleft"))
					queue.mov_keys_timer[2] = 1;
				else if(KeyBindUtils.checkBind(e.keyScan, "+moveright"))
					queue.mov_keys_timer[3] = 1;
				else if(KeyBindUtils.checkBind(e.keyScan, "+jump"))
					queue.mov_keys_timer[4] = 1;

				else if(KeyBindUtils.checkBind(e.keyScan, "dd_dash")){
					if(queue.mov_keys_timer[0])
						queue.dashvel[0].x = getDashVel();
					if(queue.mov_keys_timer[1])
						queue.dashvel[1].x = -getDashVel();
					if(queue.mov_keys_timer[2])
						queue.dashvel[2].y = getDashVel();
					if(queue.mov_keys_timer[3])
						queue.dashvel[3].y = -getDashVel();
					if(queue.mov_keys_timer[4])
						queue.dashvel[4].z = getDashVel();
				}
			}
		}
		if(e.type == InputEvent.Type_KeyUp)
		{
			if(KeyBindUtils.checkBind(e.keyScan, "+forward")
			|| KeyBindUtils.checkBind(e.keyScan, "+back")
			|| KeyBindUtils.checkBind(e.keyScan, "+moveleft")
			|| KeyBindUtils.checkBind(e.keyScan, "+moveright"))
			{
				--queue.mov_keys_held;
				if(queue.mov_keys_held == 0)
					queue.deacc = getDeaccFactor();
			}
			if(!use_doubletap_scheme)
			{
				if(KeyBindUtils.checkBind(e.keyScan, "+forward"))
					queue.mov_keys_timer[0] = 0;
				else if(KeyBindUtils.checkBind(e.keyScan, "+back"))
					queue.mov_keys_timer[1] = 0;
				else if(KeyBindUtils.checkBind(e.keyScan, "+moveleft"))
					queue.mov_keys_timer[2] = 0;
				else if(KeyBindUtils.checkBind(e.keyScan, "+moveright"))
					queue.mov_keys_timer[3] = 0;
				else if(KeyBindUtils.checkBind(e.keyScan, "+jump"))
					queue.mov_keys_timer[4] = 0;
			}
		}
		return false;
	}

	override void drawOverlay(RenderEvent e, DD_EventHandler hndl)
	{
		if(!enabled)
			return;

		if(dash_cd > 0)
			UI_Draw.str(hndl.aug_ui_font,
					String.Format("Dash CD %.2fs", double(dash_cd) / 35),
					10, 8, 16, -0.7, -0.7);
	}
}
