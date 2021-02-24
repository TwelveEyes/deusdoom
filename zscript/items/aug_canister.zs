class DD_AugmentationCanister : Inventory
{
	default
	{
		Inventory.Amount 1;
		Inventory.MaxAmount 400;

		Inventory.PickupMessage "Picked up an augmentation canister.";

		Scale 0.4;

		+DONTGIB;
	}

	states
	{
		Spawn:
			AGCN A -1;
			Stop;
	}

	// -------------
	// Engine events
	// -------------

	// 0 - augmentation got installed
	// 1 - out of augmentation slots, cease
	// 2 - other error (being picked up by a non-player), ignore event
	// 3 - reroll
	int roll_augs(Actor other, array<class<DD_Augmentation> > aug_pool)
	{
		if(!(other is "PlayerPawn"))
			return 2;

		PlayerPawn plr = PlayerPawn(other);
		DD_AugsHolder aughld = DD_AugsHolder(plr.findInventory("DD_AugsHolder"));
		if(!aughld)
			return 3;

		DD_AugSlots slot;

		uint installed_aug_cnt = 0;
		// Counting amount of augmentations installed
		for(uint i = 1; i < aughld.augs_slots; ++i)
		{
			if(aughld.augs[i])
				++installed_aug_cnt;
		}
		if(aughld.augs_toinstall1.size() + installed_aug_cnt >= aughld.augs_slots - 1) // can't fit more augmentations!
			return 1; //we ignore light slot for now

		DD_Augmentation.shuffleAugPool(aug_pool);

		// Rolling for a random slot
		int slot_max_taken; // maximum augmentations that can take this slot
		int slot_taken; // amount of augmentations that can currently take this slot
				 // (available to install)
		while(true)
		{
			slot = random(Subdermal1, Torso3);

			// Checking if this slot is occupied
			if(aughld.augs[slot])
				continue;

			slot_max_taken = 1;
			// This is crap, the system with slots should probably at least have this
			// as a separate function
			if(slot == Subdermal1 || slot == Subdermal2)
				slot_max_taken = 2;
			else if(slot == Torso1 || slot == Torso2 || slot == Torso3)
				slot_max_taken = 3;
			for(uint i = 1; i < aughld.augs_slots; ++i)
			{
				if(aughld.augs[i]){
					for(uint j = 0; j < aughld.augs[i].slots_cnt; ++j)
					{
						if(aughld.augs[i].slots[j] == slot){
							// For each installed augmentation that fits this slot
							// maximum amount of augmentations available for this
							// slot goes down by 1
							slot_max_taken--;
							break;
						}
					}
				}
			}

			slot_taken = 0;
			for(uint i = 0; i < aughld.augs_toinstall1.size(); ++i)
			{
				// we trust that both augs_toinstall1 and 2 contain augmentations for 1 slot
				for(uint j = 0; j < aughld.augs_toinstall1[i].slots_cnt; ++j)
				{
					if(aughld.augs_toinstall1[i].slots[j] == slot){
						slot_taken++;
						break;
					}
				}
			}

			if(slot_taken >= slot_max_taken)
				continue;

			break;
		}

		uint aug_i = 0;
		uint dup_amount = 0; // Amount of duplicated agumentations.
				     // if this exceeds 2, then they'll be rerolled
				     // (unusable canister).
		for(uint i = 0; i < aug_pool.size() && aug_i < 2; ++i)
		{
			DD_Augmentation aug_obj = DD_Augmentation(Inventory.Spawn(aug_pool[i]));
			aug_obj.install();

			// Checking if this augmentation class can be installed in this slot
			bool aug_obj_in_slot = false;
			for(uint i = 0; i < aug_obj.slots_cnt; ++i){
				if(aug_obj.slots[i] == slot){
					aug_obj_in_slot = true;
					break;
				}
			}
			if(!aug_obj_in_slot)
				continue;

			// Checking for dupes in installed augmentations
			bool found_dup = false;
			for(uint i = 0; i < aughld.augs_slots; ++i)
			{
				if(aughld.augs[i] && aughld.augs[i].id == aug_obj.id){
					++dup_amount;
					found_dup = true;
					break;
				}
			}
			if(!found_dup)
			{ // Checking for dupes in available augmentations
				for(uint i = 0; i < aughld.augs_toinstall1.size(); ++i)
				{
					if(!aughld.augs_toinstall1[i])
						continue;
					if(aughld.augs_toinstall1[i].id == aug_obj.id){
						++dup_amount;
						found_dup = true;
						break;
					}
				}
				if(!found_dup)
				{
					for(uint i = 0; i < aughld.augs_toinstall2.size(); ++i)
					{
						if(!aughld.augs_toinstall2[i])
							continue;
						if(aughld.augs_toinstall2[i].id == aug_obj.id){
							++dup_amount;
							found_dup = true;
							break;
						}
					}
				}
			}


			if(aug_i == 0){
				aughld.augs_toinstall1.push(aug_obj);
				aughld.addInventory(aug_obj);
			}
			else{
				aughld.augs_toinstall2.push(aug_obj);
				aughld.addInventory(aug_obj);
			}
			++aug_i;
		}
		if(aug_i == 2){
			if(dup_amount == 2){
				aughld.takeInventory(aughld.augs_toinstall1[aughld.augs_toinstall1.size()-1].getClass(), 1);
				aughld.augs_toinstall1.delete(aughld.augs_toinstall1.size()-1);
				aughld.takeInventory(aughld.augs_toinstall2[aughld.augs_toinstall2.size()-1].getClass(), 1);
				aughld.augs_toinstall2.delete(aughld.augs_toinstall2.size()-1);
				return 3;
			}
			return 0;
		}
		else{
			if(aug_i == 1){
				aughld.takeInventory(aughld.augs_toinstall1[aughld.augs_toinstall1.size()-1].getClass(), 1);
				aughld.augs_toinstall1.delete(aughld.augs_toinstall1.size()-1);
			}
			return 3;
		}
	}

	override void AttachToOwner(Actor other)
	{
		array<class<DD_Augmentation> > aug_pool;
		DD_Augmentation.initAugPool(aug_pool);
		while(1){
			int res = roll_augs(other, aug_pool);
			if(res == 0)
				break;
			else if(res == 1){
				A_Remove(AAPTR_DEFAULT);
				return;
			}
			else if(res == 2){
				return;
			}
		}
		super.AttachToOwner(other);
	}
	override bool HandlePickup(Inventory item)
	{
		//console.printf("%s", item.GetClassName());
		if(!(item is "DD_AugmentationCanister"))
			return false;

		array<class<DD_Augmentation> > aug_pool;
		DD_Augmentation.initAugPool(aug_pool);
		while(1){
			int res = roll_augs(self.owner, aug_pool);
			if(res == 0)
				break;
			else if(res == 1){
				self.master = item;
				A_RemoveMaster(RMVF_EVERYTHING);
				return false;
			}
			else if(res == 2){
				return false;
			}
		}	
		return super.HandlePickup(item);
	}

	override bool CanPickup(Actor toucher)
	{
		if(!(toucher is "PlayerPawn"))
			return false;

		PlayerPawn plr = PlayerPawn(toucher);
		DD_AugsHolder aughld = DD_AugsHolder(plr.findInventory("DD_AugsHolder"));
		uint installed_aug_cnt = 0;
		for(uint i = 1; i < aughld.augs_slots; ++i)
		{
			if(aughld.augs[i])
				++installed_aug_cnt;
		}
		if(aughld.augs_toinstall1.size() + installed_aug_cnt >= aughld.augs_slots - 1) // can't fit more augmentations!
			return false;

		return true;
	}
}
