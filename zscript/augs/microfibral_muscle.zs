struct DD_Aug_MicrofibralMuscle_Queue
{
	bool objwep;

	array<Actor> soldify_objs;
	array<int> soldify_timers;
	array<bool> soldify_wasthruactors;
}

class DD_Aug_MicrofibralMuscle : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	// Entity borders
	ui TextureID entbd_lt;
	ui TextureID entbd_rt;
	ui TextureID entbd_lb;
	ui TextureID entbd_rb;
	ui TextureID entframe;

	// Thing names/bounding boxes projections
	ui DDLe_ProjScreen proj_scr;
	DDLe_SWScreen proj_sw;
	DDLe_GLScreen proj_gl;
	ui DDLe_Viewport vwport;

	DD_Aug_MicrofibralMuscle_Queue queue;
	

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}

	override int get_base_drain_rate(){ return 20; }

	override void install()
	{
		super.install();

		id = 19;
		disp_name = "Microfibral Muscle";
		disp_desc = "Muscle strength is amplified with ionic polymeric gel\n"
			    "myofibrils that allow the agent to lift extraordinarily\n"
			    "heavy objects.\n\n"
			    "TECH ONE: Strength is increased slightly, agent can\n"
			    "pick up some objects.\n\n"
			    "TECH TWO: Strength is increased moderately, agent can\n"
			    "pick up heavier objects like barrels and corpses.\n\n"
			    "TECH THREE: Strength is increased significantly.\n\n"
			    "TECH FOUR: An agent is inhumanly strong.\n\n"
			    "Energy Rate: 20 Units/Minute";

		slots_cnt = 1;
		slots[0] = Arms;

		initProjection();
	}

	override void UIInit()
	{
		tex_off = TexMan.checkForTexture("MICMUSC0");
		tex_on = TexMan.checkForTexture("MICMUSC1");

		entbd_lt = TexMan.checkForTexture("AUGUI31");
		entbd_rt = TexMan.checkForTexture("AUGUI32");
		entbd_lb = TexMan.checkForTexture("AUGUI33");
		entbd_rb = TexMan.checkForTexture("AUGUI34");
		entframe = TexMan.checkForTexture("AUGUI35");
	}

	// ------------------
	// Internal functions
	// ------------------

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

	protected ui string getActorDisplayName(Actor ac)
	{
		string dname = ac.getTag("");
		if(ac.health < 0)
			if(ac.bIsMonster)
				dname = dname .. " (corpse)";
			else
				dname = dname .. " (remnants)";
		return dname;
	}

	protected int getMaxMassPickup() { return 80 + 100 * (getRealLevel() - 1); }
	double getThrowForceMult() { return 1.0 + 0.75 * (getRealLevel() - 1); }
	protected int cantPickupObj(Actor ac)
	{
		if(ac.bIsMonster && ac.health > 0)
			return 1;
		if(ac.mass > getMaxMassPickup()
		&& !(ac is "Inventory"))
			return 2;
		return 0;
	}

	// -------------
	// Engine events
	// -------------

	Actor target_obj;

	override void tick()
	{
		for(uint i = 0; i < queue.soldify_objs.size(); ++i)
		{
			if(queue.soldify_timers[i] > 0)
				queue.soldify_timers[i]--;
			else{
				queue.soldify_objs[i].A_ChangeLinkFlags(0, 0);
				if(!queue.soldify_wasthruactors[i])
					queue.soldify_objs[i].bThruActors = false;

				queue.soldify_objs.delete(i);
				queue.soldify_timers.delete(i);
				queue.soldify_wasthruactors.delete(i);
			}
		}

		super.tick();
		if(!enabled)
			return;
		if(!(owner is "PlayerPawn"))
			return;

		let cam_tracer = new("DD_MicrofibralMuscle_Tracer");
		cam_tracer.source = owner;

		vector3 dir = (AngleToVector(owner.angle, cos(owner.pitch)), -sin(owner.pitch));
		cam_tracer.trace(owner.pos + (0, 0, PlayerPawn(owner).viewHeight), owner.curSector, dir, 128.0, 0);

		target_obj = cam_tracer.hit_obj;

		if(queue.objwep)
		{
			queue.objwep = false;
			if(!owner.player.readyWeapon || owner.player.readyWeapon is "DD_MicrofibralMuscle_ObjectWeapon")
				return;
			if(owner.countInv("DD_MicrofibralMuscle_ObjectWeapon") > 0)
				return;
			if(!target_obj)
				return;
			int res = cantPickupObj(target_obj);
			if(res == 2)
				console.printf("It's too heavy to lift");
			if(res)
				return;

			owner.giveInventory("DD_MicrofibralMuscle_ObjectWeapon", 1);
			DD_MicrofibralMuscle_ObjectWeapon objwep = DD_MicrofibralMuscle_ObjectWeapon(owner.findInventory("DD_MicrofibralMuscle_ObjectWeapon"));
			objwep.held_obj = target_obj;
			objwep.parent_aug = self;
			// making target object dissapear from the world
			target_obj.warp(owner);
			target_obj.changeTID(0);
			target_obj.changeStatNum(STAT_TRAVELLING);
			target_obj.A_ChangeLinkFlags(1, 1);
			owner.player.pendingWeapon = Weapon(objwep);
			owner.player.bringUpWeapon();
		}
	}

	override void drawUnderlay(RenderEvent e, DD_EventHandler hndl)
	{
		if(owner && owner is "PlayerPawn" && owner.player.readyWeapon)
		{
			if(owner.player.readyWeapon is "DD_MicrofibralMuscle_ObjectWeapon")
			{
				DD_MicrofibralMuscle_ObjectWeapon objwep = DD_MicrofibralMuscle_ObjectWeapon(owner.player.readyWeapon);
				if(objwep.held_obj){
					TextureID sprtex = objwep.held_obj.CurState.getSpriteTexture(8);
					double radcoff = objwep.held_obj.radius / 320 * 150;
					double texw = UI_Draw.texWidth(sprtex, -1, -1)
							* radcoff
							* objwep.held_obj.scale.x;
					double texh = UI_Draw.texHeight(sprtex, -1, -1)
							* radcoff
							* objwep.held_obj.scale.y;
					UI_Draw.texture(sprtex,
								160 - texw/2, 180 - texh/2,
								texw, texh);
				}
			}
		}
	}
	override void drawOverlay(RenderEvent e, DD_EventHandler hndl)
	{
		if(!enabled)
			return;

		if(target_obj)
		{
			vector3 norm_to_bbox = (AngleToVector(owner.angle+90, cos(owner.pitch)), -sin(owner.pitch));
			if(norm_to_bbox.length() == 0)
				return;
			norm_to_bbox /= norm_to_bbox.length();
			vector3 targ_bbox_lbot = target_obj.pos + norm_to_bbox * target_obj.radius;

			norm_to_bbox = (AngleToVector(owner.angle, cos(owner.pitch-90)), -sin(owner.pitch-90));
			if(norm_to_bbox.length() == 0)
				return;
			vector3 targ_bbox_ltop = targ_bbox_lbot + norm_to_bbox * target_obj.height;

			norm_to_bbox = (AngleToVector(owner.angle-90, cos(owner.pitch)), -sin(owner.pitch));
			if(norm_to_bbox.length() == 0)
				return;
			norm_to_bbox /= norm_to_bbox.length();
			vector3 targ_bbox_rbot = target_obj.pos + norm_to_bbox * target_obj.radius;

			norm_to_bbox = (AngleToVector(owner.angle, cos(owner.pitch-90)), -sin(owner.pitch-90));
			if(norm_to_bbox.length() == 0)
				return;
			vector3 targ_bbox_rtop = targ_bbox_rbot + norm_to_bbox * target_obj.height;

			vwport.fromHUD();
			prepareProjection();

			proj_scr.cacheResolution();
			proj_scr.cacheFOV();
			proj_scr.orientForRenderOverlay(e);
			proj_scr.beginProjection();
			vector2 obj_norm;
			vector2 ind_pos;

			// Left top
			proj_scr.projectWorldPos(targ_bbox_ltop);
			obj_norm = proj_scr.projectToNormal();
			ind_pos = vwport.sceneToWindow(obj_norm);
			if(!vwport.isInside(obj_norm) || !proj_scr.isInScreen())
				return;
			ind_pos.x *= double(320) / screen.getWidth();
			ind_pos.y *= double(200) / screen.getHeight();
			UI_Draw.texture(entbd_lt, ind_pos.x, ind_pos.y, -0.2, -0.2);

			// Entity name
			string tdispname = getActorDisplayName(target_obj);
			UI_Draw.texture(entframe, ind_pos.x + 1, ind_pos.y + 1,
					UI_Draw.strWidth(hndl.aug_ui_font, tdispname, -0.5, -0.5) + 2,
					UI_Draw.strHeight(hndl.aug_ui_font, tdispname, -0.5, -0.5) + 2);
			UI_Draw.str(hndl.aug_ui_font, tdispname, 11,
					ind_pos.x + 2, ind_pos.y + 2, -0.5, -0.5);

			// Right top
			proj_scr.projectWorldPos(targ_bbox_rtop);
			obj_norm = proj_scr.projectToNormal();
			ind_pos = vwport.sceneToWindow(obj_norm);
			if(!vwport.isInside(obj_norm) || !proj_scr.isInScreen())
				return;
			ind_pos.x *= double(320) / screen.getWidth();
			ind_pos.y *= double(200) / screen.getHeight();
			UI_Draw.texture(entbd_rt, ind_pos.x, ind_pos.y, -0.2, -0.2);

			// Left bottom
			proj_scr.projectWorldPos(targ_bbox_lbot);
			obj_norm = proj_scr.projectToNormal();
			ind_pos = vwport.sceneToWindow(obj_norm);
			if(!vwport.isInside(obj_norm) || !proj_scr.isInScreen())
				return;
			ind_pos.x *= double(320) / screen.getWidth();
			ind_pos.y *= double(200) / screen.getHeight();
			UI_Draw.texture(entbd_lb, ind_pos.x, ind_pos.y, -0.2, -0.2);

			// Right bottom
			proj_scr.projectWorldPos(targ_bbox_rbot);
			obj_norm = proj_scr.projectToNormal();
			ind_pos = vwport.sceneToWindow(obj_norm);
			if(!vwport.isInside(obj_norm) || !proj_scr.isInScreen())
				return;
			ind_pos.x *= double(320) / screen.getWidth();
			ind_pos.y *= double(200) / screen.getHeight();
			UI_Draw.texture(entbd_rb, ind_pos.x, ind_pos.y, -0.2, -0.2);
		}
	}


	override bool inputProcess(InputEvent e)
	{
		if(e.type == InputEvent.Type_KeyDown)
		{
			if(KeyBindUtils.checkBind(e.keyScan, "+use"))
			{
				if(!owner || !(owner is "PlayerPawn"))
					return false;
				if(!enabled)
					return false;

				queue.objwep = true;
				return true;
			}
		}
		return false;
	}
}

class DD_MicrofibralMuscle_Tracer : LineTracer
{
	Actor source;
	Actor hit_obj;

	override ETraceStatus traceCallback()
	{
		if(results.hitActor && results.hitActor == source)
			return TRACE_Skip;

		if(results.hitActor){
			hit_obj = results.hitActor;
			return TRACE_Stop;
		}

		if(results.hitLine){
			return TRACE_Stop;
		}

		return TRACE_Skip;
	}
}

class DD_MicrofibralMuscle_ObjectWeapon : Weapon
{
	Actor held_obj;
	DD_Aug_MicrofibralMuscle parent_aug;

	default
	{
		Weapon.SelectionOrder 1000;
		Weapon.SlotNumber 0;
	}

	states
	{
		Ready:
			TNT1 A 1 A_WeaponReady();
			Loop;
		Deselect:
			TNT1 A 0 {
					DD_MicrofibralMuscle_ObjectWeapon(player.readyWeapon).respawnHeldObject();
					DD_MicrofibralMuscle_ObjectWeapon(player.readyWeapon).tossHeldObject(400.0);
					takeInventory("DD_MicrofibralMuscle_ObjectWeapon", 1);
				 }
			Stop;
		Select:
			Goto Ready;
		Fire:
			TNT1 A 0 {
					DD_MicrofibralMuscle_ObjectWeapon(player.readyWeapon).respawnHeldObject();
					DD_MicrofibralMuscle_ObjectWeapon(player.readyWeapon).tossHeldObject(800.0);
					takeInventory("DD_MicrofibralMuscle_ObjectWeapon", 1);
				 }
			Stop;
	}

	void respawnHeldObject()
	{
		if(!held_obj || !parent_aug)
			return;
		held_obj.changeStatNum(STAT_DEFAULT);
		held_obj.A_ChangeLinkFlags(1, 0);
		
		parent_aug.queue.soldify_wasthruactors.push(held_obj.bThruActors);
		held_obj.bThruActors = true;

		parent_aug.queue.soldify_objs.push(held_obj);
		parent_aug.queue.soldify_timers.push(17);

		held_obj.warp(self.owner, 0.0, 0.0, self.owner.player.viewHeight, 0.0,
				WARPF_ABSOLUTEOFFSET | WARPF_NOCHECKPOSITION);
	}
	void tossHeldObject(double force_scale)
	{
		if(!held_obj || !parent_aug)
			return;
		force_scale *= parent_aug.getThrowForceMult();

		vector3 owner_look = (AngleToVector(owner.angle, cos(owner.pitch)), -sin(owner.pitch));
		if(owner_look.length() == 0)
			return;
		owner_look /= owner_look.length();
		owner_look *= force_scale;
		owner_look /= held_obj.mass;
		held_obj.A_ChangeVelocity(owner_look.x, owner_look.y, owner_look.z);
	}
}
