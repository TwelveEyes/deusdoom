struct SoundUtils_Queue
{
	array<string> ui_snd;
}

class SoundUtils
{
	SoundUtils_Queue queue;

	// Engine events

	play void worldTick()
	{
		PlayerPawn plr = players[consoleplayer].mo;
		while(queue.ui_snd.size() > 0)
		{
			plr.giveInventoryType("UISound");
			queue.ui_snd.delete(0);
		}
	}


	// Functions

	static ui void uiStartSound(string snd_name)
	{
		SoundUtils snd_utils = DD_EventHandler(StaticEventHandler.Find("DD_EventHandler")).snd_utils;
		snd_utils.queue.ui_snd.push(snd_name);
	}
	static play void playStartSound(string snd_name)
	{
		SoundUtils snd_utils = DD_EventHandler(StaticEventHandler.Find("DD_EventHandler")).snd_utils;
		snd_utils.queue.ui_snd.push(snd_name);
	}
}

class UISound : Inventory
{
	default
	{
		+Inventory.ALWAYSPICKUP;
	}
	states
	{
		Spawn:
			TNT0 A 0;
			Stop;
	}
	override void AttachToOwner(Actor other)
	{
		SoundUtils snd_utils = DD_EventHandler(StaticEventHandler.Find("DD_EventHandler")).snd_utils;
		if(snd_utils.queue.ui_snd.size() > 0)
			pickupSound = snd_utils.queue.ui_snd[0];
		PlayPickupSound(other);
	}
}
