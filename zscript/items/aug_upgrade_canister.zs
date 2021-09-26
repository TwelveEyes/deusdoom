struct DD_AugmentationUpgradeCanister_Queue
{
	array<int> toupgrade;
};

class DD_AugmentationUpgradeCanister : Inventory
{
	DD_AugmentationUpgradeCanister_Queue queue;

	default
	{
		Inventory.Amount 1;
		Inventory.MaxAmount 8;

		Inventory.PickupMessage "Picked up an augmentation upgrade canister.";

		Scale 0.4;

		+DONTGIB;
	}

	states
	{
		Spawn:
			AUCN A -1;
			Stop;
	}

	override void Tick()
	{
		super.tick();
		if(!self || !owner) // there is a strange crash sometimes
			return;

		DD_AugsHolder aughld = DD_AugsHolder(owner.findInventory("DD_AugsHolder"));

		while(queue.toupgrade.size() > 0)
		{
			if(aughld.augs[queue.toupgrade[0]]._level < aughld.augs[queue.toupgrade[0]].max_level)
			{
				owner.TakeInventory("DD_AugmentationUpgradeCanister", 1);
				aughld.augs[queue.toupgrade[0]]._level++;
			}
			queue.toupgrade.Delete(0);
		}
	}


	// ------------------
	// External functions
	// ------------------

	// Description:
	//	Queues trying to consume an upgrade canister from player's inventory
	//	to upgrade an augmentation.
	// Arguments:
	//	plr - player's actor.
	//	cnst_instance - instance of upgrade canister class for queueing purposes
	//	aug_slot - augmentation slot to upgrade.
	// Return value:
	//	false - no canisters left or augmentation is at maximum level
	//		or there is no augmentation in this slot or canister instance is NULL.
	//	true - successfull queueing;
	static clearscope bool queueConsume(PlayerPawn plr, DD_AugmentationUpgradeCanister cnst_instance, int aug_slot)
	{
		DD_AugsHolder aughld = DD_AugsHolder(plr.findInventory("DD_AugsHolder"));

		if(aug_slot <= -1)
			return false;
		if(!aughld.augs[aug_slot])
			return false;
		if(aughld.augs[aug_slot]._level >= aughld.augs[aug_slot].max_level)
			return false;
		if(!cnst_instance)
			return false;
		if(plr.countInv("DD_AugmentationUpgradeCanister") < cnst_instance.queue.toupgrade.size())
			return false;

		cnst_instance.queue.toupgrade.push(aug_slot);

		return true;
	}

	// Description:
	//	Tells whether an augmentation canister can be consumed or not (for UI)
	static clearscope bool canConsume(PlayerPawn plr, DD_AugmentationUpgradeCanister cnst_instance, int aug_slot)
	{
		DD_AugsHolder aughld = DD_AugsHolder(plr.findInventory("DD_AugsHolder"));

		return cnst_instance
		    && aug_slot > -1
		    && aughld.augs[aug_slot]
		    && aughld.augs[aug_slot]._level < aughld.augs[aug_slot].max_level
		    && plr.countInv("DD_AugmentationUpgradeCanister") >= cnst_instance.queue.toupgrade.size()
		    && plr.countInv("DD_AugmentationUpgradeCanister") > 0;
	}
}
