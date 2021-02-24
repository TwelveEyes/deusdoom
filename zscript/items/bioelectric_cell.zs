struct DD_BioelectricCell_Queue
{
	int cell_toconsume;
};

// Description:
// Main source of bioelectric energy needed to power up augmentations
class DD_BioelectricCell : Ammo
{
	DD_BioelectricCell_Queue queue;

	default
	{
		Inventory.Amount 1;
		Inventory.MaxAmount 16;
		Ammo.BackpackAmount 32;

		Inventory.PickupMessage "Picked up a bioelectric cell.";

		Scale 0.35;
	}

	states
	{
		Spawn:
			BCEL A -1;
			Stop;
	}


	int energy_value;

	override void BeginPlay()
	{
		energy_value = 25;
	}

	override void tick() // This should be static, but DD_EventHandler may become messy
	{
		super.tick();

		if(!self) // there is a strange crash sometimes
			return;

		while(queue.cell_toconsume > 0)
		{
			owner.TakeInventory("DD_BioelectricCell", 1);
			owner.GiveInventory("DD_BioelectricEnergy", 25);
			--queue.cell_toconsume;
		}
	}


	// ------------------
	// External functions
	// ------------------

	// Description:
	//	Queues trying to consume a bioelectrical cell from player's inventory
	//	to refill energy.
	// Arguments:
	//	plr - player's actor.
	//	cell_instance - instance of bioelectric cell class for queueing purposes.
	// Return value:
	//	false - no cells left or bioelectrical energy is full or cell instance is NULL.
	//	true - successfull queueing;
	static ui bool queueConsume(PlayerPawn plr, DD_BioelectricCell cell_instance)
	{
		if(plr.countInv("DD_BioelectricEnergy") >= DD_BioelectricEnergy.max_energy)
			return false;
		if(plr.countInv("DD_BioelectricCell") == 0)
			return false;
		if(!cell_instance)
			return false;

		cell_instance.queue.cell_toconsume++;

		return true;
	}

	// Description:
	//	Tells whether a cell can be consumed or not (for UI).
	static ui bool canConsume(PlayerPawn plr, DD_BioelectricCell cell_instance)
	{
		return cell_instance
		    && plr.countInv("DD_BioelectricEnergy") < DD_BioelectricEnergy.max_energy
		    && plr.countInv("DD_BioelectricCell") >= cell_instance.queue.cell_toconsume
		    && plr.countInv("DD_BioelectricCell") > 0;
	}
}
