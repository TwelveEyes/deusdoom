// Description:
// Internal structure designed as a workaround for ConsoleProcess event
// being unable to modify augmentation states etc.
struct DD_UIQueue{
	bool aug_toggle_queue[DD_AugsHolder.augs_slots];
	array<DD_Augmentation> aug_install_queue;
	array<int> aug_trash_queue;
};

// Description:
// Item class that holds information about all augmentations installed in a player.

class DD_AugsHolder : Inventory
{
	const augs_slots = 10;
	DD_Augmentation augs[augs_slots];

	DD_UIQueue ui_queue;
	int aug_loop_snd_timer; // delay timer not to start the sound without waiting for activation sound

	array<DD_Augmentation> augs_toinstall1;
	array<DD_Augmentation> augs_toinstall2;

	// For drawing augmentations
	ui TextureID aug_frame_top;
	ui TextureID aug_frame_mid;
	ui TextureID aug_frame_bottom;
	ui TextureID aug_frame_bg;

	// For drawing damage directions and absorption amount
	ui TextureID dmg_dir_texs[5];
	int absorbtion_msg_timer;
	string absorbtion_msg;

	default
	{
		Inventory.Amount 1;
		Inventory.MaxAmount 1;
                Inventory.InterHubAmount 1;

		+Inventory.UNDROPPABLE;
		+Inventory.UNCLEARABLE;
		+Inventory.UNTOSSABLE;
	}

	override void BeginPlay()
	{
		absorbtion_msg = " ";

		aug_loop_snd_timer = 0;
		energy_drain_ml = 1.0;
	}


	// -------------
	// Engine events
	// -------------

	ui void UIInit()
	{
		aug_frame_top = TexMan.checkForTexture("AUGUI21");
		aug_frame_mid = TexMan.checkForTexture("AUGUI22");
		aug_frame_bottom = TexMan.checkForTexture("AUGUI23");
		aug_frame_bg = TexMan.checkForTexture("AUGUI25");

		dmg_dir_texs[0] = TexMan.checkForTexture("AUGUI26");
		dmg_dir_texs[1] = TexMan.checkForTexture("AUGUI27");
		dmg_dir_texs[2] = TexMan.checkForTexture("AUGUI28");
		dmg_dir_texs[3] = TexMan.checkForTexture("AUGUI29");
		dmg_dir_texs[4] = TexMan.checkForTexture("AUGUI30");
	}

	// Lil' hacks for Power Recirculator and Synthetic Heart
	double energy_drain_ml;
	int level_boost;

	override void tick()
	{
		super.tick();

		// Handling damage interface timers
		if(absorbtion_msg_timer > 0)
			--absorbtion_msg_timer;
		for(uint i = 0; i < 5; ++i)
			if(dmg_dir_timers[i] > 0)
				--dmg_dir_timers[i];

		bool one_aug_enabled = false;
		// Toggle queue
		for(uint i = 0; i < augs_slots; ++i)
		{
			if(augs[i] && ui_queue.aug_toggle_queue[i]){
				augs[i].toggle();
				ui_queue.aug_toggle_queue[i] = false;
			}
			if(augs[i] && augs[i].enabled){
				one_aug_enabled = true;
			}
		}
		// Installation queue
		while(ui_queue.aug_install_queue.size() > 0)
		{
			installAug(ui_queue.aug_install_queue[0]);
			ui_queue.aug_install_queue.delete(0);
		}
		// Trashing queue
		while(ui_queue.aug_trash_queue.size() > 0)
		{
			augs_toinstall1[ui_queue.aug_trash_queue[0]].detachFromOwner();
			augs_toinstall1[ui_queue.aug_trash_queue[0]].destroy();
			augs_toinstall1.delete(ui_queue.aug_trash_queue[0]);

			augs_toinstall2[ui_queue.aug_trash_queue[0]].detachFromOwner();
			augs_toinstall2[ui_queue.aug_trash_queue[0]].destroy();
			augs_toinstall2.delete(ui_queue.aug_trash_queue[0]);

			owner.takeInventory("DD_AugmentationCanister", 1);
			ui_queue.aug_trash_queue.delete(0);
		}

		// 3512 is just this mod's own slot for this sound
		if(one_aug_enabled)
		{
			if(aug_loop_snd_timer == 0)
				aug_loop_snd_timer = 55;
			else{
				if(aug_loop_snd_timer - 1 == 0 && owner)
					owner.A_StartSound("play/aug/loop", 3512, CHANF_LOOPING, 0.2);
				aug_loop_snd_timer--;
			}
		}
		else
			A_StopSound(3512);
	}

	// Inventory events
	override void modifyDamage(int damage, Name damageType, out int newDamage, bool passive,
					Actor inflictor, Actor source, int flags)
	{
		// Detecting damage directions
		if(passive){
			if(source && owner)
			{
				double dmg_ang = deltaAngle(owner.angleTo(source), owner.angle);
				dmg_dir_timers[int((dmg_ang + 45) % 360 / 90)] = 70;
			}

			else if(inflictor && owner)
			{
				double dmg_ang = deltaAngle(owner.angleTo(inflictor), owner.angle);
				dmg_dir_timers[int((dmg_ang + 45) % 360 / 90)] = 70;
			}
			else if(!source && !inflictor)
			{
				dmg_dir_timers[4] = 35;
			}
		}

		// Invoking damage events
		if(passive){
			for(uint i = 0; i < augs.size(); ++i)
				if(augs[i])
					augs[i].ownerDamageTaken(damage, damageType, newDamage,
									inflictor, source, flags);
		}
		else{
			for(uint i = 0; i < augs.size(); ++i)
				if(augs[i])
					augs[i].ownerDamageDealt(damage, damageType, newDamage,
									inflictor, source, flags);
		}
	}
	override double getSpeedFactor()
	{
		double speed_ml = 1.0;
		for(uint i = 0; i < augs.size(); ++i)
			if(augs[i])
				speed_ml *= augs[i].getSpeedFactor();
		return speed_ml;
	}


	ui bool inputProcess(InputEvent e)
	{
		for(uint i = 0; i < augs.size(); ++i)
			if(augs[i])
				if(augs[i].inputProcess(e))
					return true;
		return false;
	}

	// ---------------------------------
	// Augmentation management functions
	// --------------------------------

	// Description:
	// Makes an attempt to install an augmentation of a certain type into an augmentation holder.
	// Return values:
	//	false - augmentation couldn't be installed.
	//		(there is already an augmentation in this slot or of this type)
	//	true  - successfull installation.
	bool installAug(DD_Augmentation aug_obj)
	{
		aug_obj.install();

		// Trying to find a vacant slot
		bool has_slot = false;
		uint in_slot;
		for(in_slot = 0; in_slot < aug_obj.slots_cnt; ++in_slot)
		{
			if(!augs[aug_obj.slots[in_slot]]){
				has_slot = true;
				break;
			}
			else if(augs[aug_obj.slots[in_slot]].id == aug_obj.id){
				// it's a duplicate
				return false;
			}
		}
		if(!has_slot) // out of slots
			return false;

		augs[aug_obj.slots[in_slot]] = aug_obj;
		aug_obj.owner = self.owner;

		// Deleting it from available for installation augmentations array
		uint aui;
		aui = augs_toinstall1.find(aug_obj);
		if(aui != augs_toinstall1.size()){
			augs_toinstall1.delete(aui);
			augs_toinstall2.delete(aui);
		}
		else{
			aui = augs_toinstall2.find(aug_obj);
			if(aui != augs_toinstall2.size()){
				augs_toinstall1.delete(aui);
				augs_toinstall2.delete(aui);
			}
		}
		owner.takeInventory("DD_AugmentationCanister", 1);

		return true;
	}

	// Description:
	// Indicates whether the augmentation of this type can be installed or not.
	// Return values:
	//	false - augmentation can't be installed.
	//		(there is already an augmentation in this slot or of this type)
	//	true  - augmentation can be installed.
	ui bool canInstallAug(DD_Augmentation aug_obj)
	{
		// Trying to find a vacant slot
		bool has_slot = false;
		uint in_slot;
		for(in_slot = 0; in_slot < aug_obj.slots_cnt; ++in_slot)
		{
			if(!augs[aug_obj.slots[in_slot]]){
				has_slot = true;
				break;
			}
			else if(augs[aug_obj.slots[in_slot]].id == aug_obj.id){
				// it's a duplicate
				return false;
			}
		}
		if(!has_slot) // out of slots
			return false;
		return true;
	}
	play bool canInstallAugPlay(DD_Augmentation aug_obj)
	{
		// Trying to find a vacant slot
		bool has_slot = false;
		uint in_slot;
		for(in_slot = 0; in_slot < aug_obj.slots_cnt; ++in_slot)
		{
			if(!augs[aug_obj.slots[in_slot]]){
				has_slot = true;
				break;
			}
			else if(augs[aug_obj.slots[in_slot]].id == aug_obj.id){
				// it's a duplicate
				return false;
			}
		}
		if(!has_slot) // out of slots
			return false;
		return true;
	}


	// Description:
	// Queues installing an augemntation.
	ui void queueInstallAug(DD_Augmentation aug_obj)
	{
		if(!aug_obj.ui_init)
			aug_obj.UIInit();
		aug_obj.ui_init = true;
		ui_queue.aug_install_queue.push(aug_obj);
	}

	// Description:
	// Queues removing an augmentation from available augmentations (lost forever)
	ui void queueTrashAug(int install_index)
	{
		ui_queue.aug_trash_queue.push(install_index);
	}

	// Description:
	// Queues toggling an augmentation in certain slot.
	// Trusts validity of the slot.
	ui void queueToggleAug(int slot)
	{
		ui_queue.aug_toggle_queue[slot] = true;
	}

	// ------------
	// UI functions
	// ------------

	// Drawing damage absorbtion/directions interface
	int absorbmsg_timer;	// how long "XX% ABSORB" message stays on screen
	int dmg_dir_timers[5];	// timers for separate damage directions

	ui void draw(RenderEvent ev, DD_EventHandler hndl, double x, double y)
	{
		CVar offvar = CVar.getCVar("dd_augdisp_offx", players[consoleplayer]);
		if(offvar)
			x += offvar.getFloat();
		offvar = CVar.getCVar("dd_augdisp_offy", players[consoleplayer]);
		if(offvar)
			y += offvar.getFloat();

		// Invoking rendering of augmentations
		for(uint i = 0; i < augs.size(); ++i)
			if(augs[i]){
				augs[i].drawOverlay(ev, hndl);
			if(!augs[i].ui_init)
					augs[i].UIInit();
		}

		// Rendering damage directions
		double absmsg_w = UI_Draw.strWidth(hndl.aug_ui_font, absorbtion_msg, -0.5, -0.5);
		double absmsg_h = UI_Draw.strHeight(hndl.aug_ui_font, absorbtion_msg, -0.5, -0.5);

		if(dmg_dir_timers[0] > 0)
			UI_Draw.texture(dmg_dir_texs[0],
						14, 110,
						-0.45, -0.45);
		if(dmg_dir_timers[1] > 0)
			UI_Draw.texture(dmg_dir_texs[1],
						30, 120,
						-0.45, -0.45);
		if(dmg_dir_timers[2] > 0)
			UI_Draw.texture(dmg_dir_texs[2],
						14, 136,
						-0.45, -0.45);
		if(dmg_dir_timers[3] > 0)
			UI_Draw.texture(dmg_dir_texs[3],
						4, 120,
						-0.45, -0.45);
		if(dmg_dir_timers[4] > 0)
			UI_Draw.texture(dmg_dir_texs[4],
						14.9, 120.9,
						-0.53, -0.53);

		if(absorbtion_msg_timer > 0)
			UI_Draw.str(hndl.aug_ui_font, absorbtion_msg,
					Font.CR_UNTRANSLATED,
					35- UI_Draw.strWidth(hndl.aug_ui_font, absorbtion_msg, -0.5, -0.5),
					125,
					-0.5, -0.5);
		

		// Rendering augmentations frame
		double draw_x = x;
		double draw_y = y;
		double aug_sz_x = 16;
		double aug_sz_y = 16;
		double draw_dy = 2;

		uint aug_cnt = 0;
		for(uint i = 0; i < augs.size(); ++i)
			if(augs[i])
				aug_cnt++;

		// Drawing augmentations background frame
		draw_y = y + UI_Draw.texHeight(aug_frame_top, aug_sz_x * 0.5, 0);
		for(uint i = 0; i < augs.size(); ++i)
		{
			if(!augs[i]) // no augmentation in the slot
				continue;
			UI_Draw.texture(aug_frame_bg, draw_x+0.75, draw_y, aug_sz_x-1, aug_sz_y);
			
			draw_y += aug_sz_y + draw_dy;
		}

		// Drawing augmentations frame
		draw_y = y;
		UI_Draw.texture(aug_frame_top, draw_x - aug_sz_x * 0.44, draw_y, aug_sz_x * 1.621, 0);
		draw_y += UI_Draw.texHeight(aug_frame_top, aug_sz_x * 0.8, 0);
		if(aug_cnt > 0){
			UI_Draw.texture(aug_frame_mid, draw_x, draw_y, aug_sz_x, aug_sz_y * aug_cnt + draw_dy * (aug_cnt - 1) - aug_sz_y * 0.25);
		}

		draw_y = y + UI_Draw.texHeight(aug_frame_top, aug_sz_x * 0.8, 0) + aug_sz_y * aug_cnt + draw_dy * (aug_cnt - 1) + aug_sz_y * 0.2;
		if(aug_cnt > 0)
			UI_Draw.texture(aug_frame_bottom, draw_x - aug_sz_x * 0.44, draw_y - aug_sz_y * 1.0, aug_sz_x * 1.621, 0);
		else
			UI_Draw.texture(aug_frame_bottom, draw_x - aug_sz_x * 0.44, draw_y - 1, aug_sz_x * 1.621, 0);

		// Drawing augmentations
		draw_y = y + UI_Draw.texHeight(aug_frame_top, aug_sz_x * 0.5, 0);
		for(uint i = 0; i < augs.size(); ++i)
		{
			if(!augs[i]) // no augmentation in the slot
				continue;

			UI_Draw.texture(augs[i].get_ui_texture(augs[i].enabled),
						draw_x+0.75,
						draw_y + UI_Draw.texHeight(aug_frame_bg, aug_sz_x-1, aug_sz_y)/2
						       - UI_Draw.texHeight(augs[i].get_ui_texture(false),
										aug_sz_x-1, aug_sz_y)/2,
						aug_sz_x-1, aug_sz_y);
			
			draw_y += aug_sz_y + draw_dy;
		}
	}
	ui void drawUnderlay(RenderEvent ev, DD_EventHandler hndl)
	{
		for(uint i = 0; i < augs.size(); ++i)
			if(augs[i])
				augs[i].drawUnderlay(ev, hndl);
	}
}
