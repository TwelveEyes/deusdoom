class DD_ProgressionTracker : Inventory
{
	int points_cells;
	int points_upgrades;
	int points_augs;

	const item_maxvel = 3.0;


	override void travelled()
	{
		let hndl = DD_SpawnHandler(StaticEventHandler.find("DD_SpawnHandler"));

		givePoints(hndl.pointsamt_exit_lvl);
		double items_ratio = double(hndl.prev_lvl_found_items) / hndl.prev_lvl_total_items;
		givePoints(items_ratio * DD_SpawnHandler.pointsamt_all_items);
		double secrets_ratio = double(hndl.prev_lvl_found_secrets) / hndl.prev_lvl_total_secrets;
		givePoints(secrets_ratio * DD_SpawnHandler.pointsamt_all_secrets);
	}

	// ------------------
	// Internal functions
	// ------------------

	void givePoints(int amount)
	{
		points_augs += amount;
		if(owner is "PlayerPawn" && owner.countInv("DD_AugsHolder") > 0)
		{
			DD_AugsHolder aughld = DD_AugsHolder(owner.findInventory("DD_AugsHolder"));
			bool plr_hasaugs = false;
			if(aughld.augs_toinstall1.size() > 0 || aughld.augs_toinstall2.size() > 0)
				plr_hasaugs = true;
			for(uint i = 0; i < DD_AugsHolder.augs_slots; ++i)
				if(aughld.augs[i]){
					plr_hasaugs = true;
					break;
			}

			if(plr_hasaugs){
				points_cells += amount;
				points_upgrades += amount;
			}
		}
	}

	protected void spawnItemActor(Actor ac, class<Actor> item, int amount)
	{
		vector3 spawnpos = ac.pos + (0, 0, ac.height/2);
		for(int i = 0; i < amount; ++i)
		{
			let itm = Spawn(item, spawnpos);
			itm.A_ChangeVelocity(frandom(-item_maxvel, item_maxvel), frandom(-item_maxvel, item_maxvel), 0);
				spawnpos.z += frandom(-0.1, 0.1);
		}
	}

	void trySpawnItemsActor(Actor ac)
	{
		let hndl = DD_SpawnHandler(StaticEventHandler.find("DD_SpawnHandler"));
		double pts_cell = DD_SpawnHandler.points_for_cell
				* hndl.points_global_mult
				* hndl.points_for_cell_mult;
		double pts_upgrade = DD_SpawnHandler.points_for_upgrade
				* hndl.points_global_mult
				* hndl.points_for_upgrade_mult;
		double pts_aug = DD_SpawnHandler.points_for_aug
				* hndl.points_global_mult
				* hndl.points_for_aug_mult;

		if(points_cells >= pts_cell)
		{
			int amnt = points_cells / pts_cell;
			spawnItemActor(ac, "DD_BioelectricCell", amnt);
			points_cells -= amnt * pts_cell;
		}
		if(points_upgrades >= DD_SpawnHandler.points_for_upgrade)
		{
			int amnt = points_upgrades / pts_upgrade;
			spawnItemActor(ac, "DD_AugmentationUpgradeCanister", amnt);
			points_upgrades -= amnt * pts_upgrade;
		}

		bool plr_hasaugs = false;
		if(owner is "PlayerPawn" && owner.countInv("DD_AugsHolder") > 0)
		{
			DD_AugsHolder aughld = DD_AugsHolder(owner.findInventory("DD_AugsHolder"));
			if(aughld.augs_toinstall1.size() > 0 || aughld.augs_toinstall2.size() > 0)
				plr_hasaugs = true;
			for(uint i = 0; i < DD_AugsHolder.augs_slots; ++i)
				if(aughld.augs[i]){
					plr_hasaugs = true;
					break;
			}
		}
		Actor obj;
		ThinkerIterator it = ThinkerIterator.create();
		while(obj = Actor(it.next()))
		{
			if(obj is "DD_AugmentationCanister")
			{
				plr_hasaugs = true;
				break;
			}
		}

		if(!plr_hasaugs && points_augs >= pts_aug * DD_SpawnHandler.points_for_aug_first_ml)
		{
			int amnt = points_augs / (pts_aug * DD_SpawnHandler.points_for_aug_first_ml);
			spawnItemActor(ac, "DD_AugmentationCanister", amnt);
			points_augs -= amnt * (pts_aug * DD_SpawnHandler.points_for_aug_first_ml);
		}
		else if(plr_hasaugs && points_augs >= pts_aug)
		{
			int amnt = points_augs / pts_aug;
			spawnItemActor(ac, "DD_AugmentationCanister", amnt);
			points_augs -= amnt * pts_aug;
		}
	}
}

class DD_SpawnHandler : StaticEventHandler
{
	// -----------------------------------
	// Progression variables and constants
	// -----------------------------------

	// Multipliers for various events
	const pointsml_killed_hp = 0.15;
	const pointsml_killed_hp_boss = 0.05;

	// Constants for rewarding exiting a level
	const pointsamt_exit_lvl = 350;
	const pointsamt_all_items = 125;
	const pointsamt_all_secrets = 225;

	// Set amount of points needed to gain an item
	double points_global_mult;
	const points_for_cell = 375;
	double points_for_cell_mult;
	const points_for_upgrade = 1750;
	double points_for_upgrade_mult;
	const points_for_aug = 4250;
	double points_for_aug_mult;
	const points_for_aug_first_ml = 0.1;

	// ---------------
	// Other variables
	// ---------------
	
	int prev_lvl_found_items;
	int prev_lvl_total_items;
	int prev_lvl_found_secrets;
	int prev_lvl_total_secrets;

	array<Inventory> transfer_items;

	const item_maxvel = 5.0;

	override void onRegister()
	{
		setOrder(1001);
	}


	override void playerSpawned(PlayerEvent e)
	{
		PlayerPawn plr = players[e.PlayerNumber].mo;
		if(plr.countInv("DD_ProgressionTracker") == 0){
			DD_ProgressionTracker tr = DD_ProgressionTracker(Inventory.Spawn("DD_ProgressionTracker"));
			plr.addInventory(tr);
		}

		while(transfer_items.size() > 0)
		{
			if(transfer_items[0])
			{
				transfer_items[0].changeStatNum(Thinker.STAT_DEFAULT);
				transfer_items[0].warp(plr, 0, 0, 0, 0, WARPF_NOCHECKPOSITION);
				vector2 velsign = (random(0, 1) ? 1 : -1, random(0, 1) ? 1 : -1);
				transfer_items[0].A_ChangeVelocity(velsign.x * item_maxvel, velsign.y * item_maxvel);
			}
			transfer_items.delete(0);
		}
	}


	// Tracking progression
	override void WorldThingDied(WorldEvent e)
	{
		if(!e.thing.bISMONSTER)
			return;

		for(uint i = 0; i < MAXPLAYERS; ++i)
		{
			if(!playeringame[i])
				continue;

			PlayerPawn plr = players[i].mo;
			let tr = DD_ProgressionTracker(plr.findInventory("DD_ProgressionTracker"));
			if(tr)
			{
				// Giving points for a monster dying
				if(e.thing.bBOSS)
					tr.givePoints(e.thing.getSpawnHealth() * pointsml_killed_hp_boss);
				else
					tr.givePoints(min(e.thing.getSpawnHealth() * pointsml_killed_hp, 50));

				tr.trySpawnItemsActor(e.thing);
			}
		}
	}

	override void WorldLoaded(WorldEvent e)
	{
		points_global_mult = CVar.getCVar("dd_ptmult_global").getFloat();
		points_for_cell_mult = CVar.getCVar("dd_ptmult_cell").getFloat();
		points_for_upgrade_mult = CVar.getCVar("dd_ptmult_upgrade").getFloat();
		points_for_aug_mult = CVar.getCVar("dd_ptmult_aug").getFloat();
	}
	override void WorldUnloaded(WorldEvent e)
	{
		prev_lvl_found_items = level.found_items;
		prev_lvl_total_items = level.total_items;
		prev_lvl_found_secrets = level.found_secrets;
		prev_lvl_total_secrets = level.total_secrets;

		// Carrying all unpickuped augmentation canisters to the next level
		Actor obj;
		ThinkerIterator it = ThinkerIterator.create();
		while(obj = Actor(it.next()))
		{
			if(obj is "DD_AugmentationCanister")
			{
				obj.changeStatNum(Thinker.STAT_TRAVELLING);
				transfer_items.push(Inventory(obj));
			}
		}
	}
}

