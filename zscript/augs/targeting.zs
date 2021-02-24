struct DD_Aug_Targeting_Queue
{
	bool zoomed_in; // current status of zooming
	double tfov; // desired FOV or 0 if shouldn't be changed
}
class DD_Aug_Targeting : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	ui TextureID reticle; // reticle for aiming
	ui TextureID targ_frame; // frame background for rendering target's image
	ui TextureID scope; // scope displayed while zooming in

	bool disp_reticle; // keeps the value of dd_show_reticle CVAR between toggles
	DD_Aug_Targeting_Queue queue;
	double zoom_fov; // FOV when zoomed

	// Target to render info about
	Actor target_obj;

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}

	override int get_base_drain_rate(){ return 40; }

	override void install()
	{
		super.install();

		id = 17;
		disp_name = "Targeting";
		disp_desc = "Image-scaling and recognition provided by multiplexing\n"
			    "the optic nerve with doped polyacetylene \"quantum wires\"\n"
			    "delivers situational info about a target.\n\n"
			    "TECH ONE: Distance and health level are provided.\n\n"
			    "TECH TWO: Maximum health level of a target and a reticle\n"
			    "for aiming are provided additionaly.\n\n"
			    "TECH THREE: Current state of the target and their\n"
			    "targeted entity are provided additionaly.\n\n"
			    "TECH FOUR: Also grants an ability to capture image of\n"
			    "a target and an autonomous telescopic zoom.\n\n"
			    "Energy Rate: 40 Units/Minute";

		slots_cnt = 1;
		slots[0] = Eyes;
		zoom_fov = 15.0;
	}
	override void UIInit()
	{
		tex_off = TexMan.checkForTexture("TARG0");
		tex_on = TexMan.checkForTexture("TARG1");
		reticle = TexMan.checkForTexture("AUGUI37");
		targ_frame = TexMan.checkForTexture("AUGUI20");
		scope = TexMan.checkForTexture("AUGUI38");
	}

	// ------------------
	// Internal functions
	// ------------------

	protected clearscope bool shouldDisplayObj(Actor ac)
	{
		if(!ac.bShootable || ac.health <= 0)
			return false;
		return true;
	}
	protected clearscope string getActorDisplayName(Actor ac)
	{
		string dname = ac.getTag("");
		if(ac.bFriendly)
			dname = dname .. " (friendly)";
		return dname;
	}

	// -------------
	// Engine events
	// -------------

	override void toggle()
	{
		super.toggle();
		CVar cdisp_reticle = CVar.getCVar("dd_show_reticle", players[consoleplayer]);
		disp_reticle = cdisp_reticle.getFloat();

		if(!enabled && queue.zoomed_in){
			queue.zoomed_in = false;
			queue.tfov = 0;
			players[consoleplayer].setFOV(CVar.getCVar("fov", players[consoleplayer]).getFloat());
		}
	}

	override void tick()
	{
		super.tick();

		if(!owner || !(owner is "PlayerPawn"))
			return;

		if(queue.tfov != 0){
			owner.player.setFOV(queue.tfov);
			queue.tfov = 0;
		}

		let look_tracer = new("DD_Targeting_Tracer");
		look_tracer.source = owner;

		vector3 dir = (AngleToVector(owner.angle, cos(owner.pitch)), -sin(owner.pitch));
		look_tracer.trace(owner.pos + (0, 0, PlayerPawn(owner).viewHeight), owner.curSector, dir, 999999.0, 0);

		target_obj = look_tracer.hit_obj;
		string ss = "look";
	}


	override void drawOverlay(RenderEvent e, DD_EventHandler hndl)
	{
		if(!enabled)
			return;
		if(queue.zoomed_in){
			UI_Draw.texture(scope,
					320/2-200/2, 0, 200, 200);
		}

		// level 2: reticle
		if( (getRealLevel() >= 2) && disp_reticle && !queue.zoomed_in){
			double ret_w = 10;
			double ret_h = 10;
			UI_Draw.texture(reticle,
						320/2 - UI_Draw.texWidth(reticle, ret_w, ret_h)/2 + 0.5,
						200/2 - UI_Draw.texWidth(reticle, ret_w, ret_h)/2 - 5.5,
						ret_w, ret_h);
		}
		if(target_obj && shouldDisplayObj(target_obj))
		{
			UI_Draw.str(hndl.aug_ui_font, getActorDisplayName(target_obj), 11,
					4, 2, -0.5, -0.5);
			double target_dist = ((target_obj.pos - owner.pos).length()
						- target_obj.radius - owner.radius);
			double target_ft_dist = target_dist
						/ 32 * 3.28; // see agressive defense system


			int target_hp = target_obj.health;

			UI_Draw.str(hndl.aug_ui_font, String.format("Range %.0f ft (%.0f map units)",
							round(target_ft_dist), round(target_dist)),
							11, 4, 7, -0.5, -0.5);

			// level 2: target max health
			if(getRealLevel() >= 2){
				int target_maxhp = target_obj.getSpawnHealth();
				UI_Draw.str(hndl.aug_ui_font, String.Format("Health %d\\%d",
								target_hp, target_maxhp),
								11, 4, 12, -0.5, -0.5);
			}
			// level 1: target range and health
			else if(getRealLevel() >= 1){
				UI_Draw.str(hndl.aug_ui_font, String.Format("Health %d",
								target_hp),
								11, 4, 12, -0.5, -0.5);
			}

			// level 3: target state, it's target and master
			if(getRealLevel() >= 3){
				UI_Draw.str(hndl.aug_ui_font, StateUtils.getTranslation(target_obj),
								11, 4, 17, -0.5, -0.5);
				if(target_obj.master)
				UI_Draw.str(hndl.aug_ui_font, "Master: "
								.. (target_obj.master ? target_obj.master.getTag("") : ""),
								11, 4, 22, -0.5, -0.5);
			}

			// level 4: target image
			if(getRealLevel() >= 4){
				double objang = deltaAngle(owner.angleTo(target_obj), target_obj.angle) + 180;
				int byte_ang = ( int( (objang + 22.5) / 45) % 8);
				TextureID sprtex = target_obj.curState.getSpriteTexture(byte_ang * 2);
				UI_Draw.texture(targ_frame,
							4, 27,
							UI_Draw.texWidth(sprtex, 0, 30) + 2,
							UI_Draw.texHeight(sprtex, 0, 30) + 2);
				UI_Draw.texture(sprtex,
							5, 28, 0, 30);
			}
		}
	}


	override bool inputProcess(InputEvent e)
	{
		super.inputProcess(e);

		if(!enabled)
			return false;
		if(e.type == UiEvent.Type_KeyDown)
		{
			if(KeyBindUtils.checkBind(e.KeyScan, "dd_togg_zoom")
			&& getRealLevel() >= 4)
			{
				queue.zoomed_in = !queue.zoomed_in;
				if(queue.zoomed_in){
					queue.tfov = zoom_fov;
				}
				else{
					queue.tfov = CVar.getCVar("fov", players[consoleplayer]).getFloat();
				}
			}
		}
		return false;
	}

}

class DD_Targeting_Tracer : LineTracer
{
	Actor source;
	Actor hit_obj;

	override ETraceStatus traceCallback()
	{
		if(results.hitActor)
		{
			if(results.hitActor == source)
				return TRACE_Skip;
			hit_obj = results.hitActor;
			return TRACE_Stop;
		}
		if(results.hitLine){
			return TRACE_Stop;
		}
		return TRACE_Skip;
	}
}
