#include "zscript/augs/ballistic_protection.zs"
#include "zscript/augs/gravitational_field.zs"
#include "zscript/augs/cloak.zs"
#include "zscript/augs/radar_transparency.zs"

#include "zscript/augs/combat_strength.zs"
#include "zscript/augs/microfibral_muscle.zs"

#include "zscript/augs/speed_enhancement.zs"
#include "zscript/augs/agility_enhancement.zs"

#include "zscript/augs/energy_shield.zs"
#include "zscript/augs/environmental_resistance.zs"
#include "zscript/augs/power_recirculator.zs"
#include "zscript/augs/regeneration.zs"
#include "zscript/augs/synthetic_heart.zs"

#include "zscript/augs/aggressive_defense_system.zs"
#include "zscript/augs/spy_drone.zs"

#include "zscript/augs/vision_enhancement.zs"
#include "zscript/augs/targeting.zs"

enum DD_AugSlots
{
	Subdermal1	= 1,
	Subdermal2	= 2,
	Cranial		= 3,
	Arms		= 4,
	Legs		= 5,
	Eyes		= 6,
	Torso1		= 7,
	Torso2		= 8,
	Torso3		= 9,
	Light		= 0
};

// Description:
// Class that describes an augmentation stored in player's "body".
class DD_Augmentation : Inventory
{
	int id; // to identify duplicates
	String disp_name; // name to display
	String disp_desc; // description to display,
			  // lines are separated by '\n'

	uint level;
	clearscope uint getRealLevel()
	{
		if(!owner)
			return level;
		let aughld = DD_AugsHolder(owner.findInventory("DD_AugsHolder"));
		if(!aughld)
			return level;

		return level + aughld.level_boost;
	}
	uint max_level;
	bool enabled;

	DD_AugSlots slots[3];	// possible slot numbers
	uint slots_cnt;		// count of possible slots

	virtual int get_base_drain_rate(){ return 1; }	// amount of energy drained per minute
	double drain_queue;				// amount of energy drain queued (since inventory items have integer amount,
							// we can't just substract energy every tick; instead, amount of energy to
							// be drained is accumulated in this variable)

	// Returns texture ID based on augmentation state (false - disabled, true - enabled)
	// This code is a stub, refer to BallisticProtection for example!
	virtual ui TextureID get_ui_texture(bool state){ return TexMan.CheckForTexture("TNT0"); }


	// This is actually unused: AugsHolder class manages augmentations through a dynamic array
	default
	{
		Inventory.Amount 1;
		Inventory.MaxAmount 1;
	}


	// -------------
	// Engine events
	// -------------

	override void tick()
	{
		if(enabled)
		{
			if(owner.countInv("DD_BioelectricEnergy") == 0){
				enabled = false;
			}
	
			DD_AugsHolder aughld = DD_AugsHolder(owner.findInventory("DD_AugsHolder"));
			drain_queue += (get_base_drain_rate() * aughld.energy_drain_ml) / (35 * 60);
			if(drain_queue > 1.0)
			{
				owner.takeInventory("DD_BioelectricEnergy", floor(drain_queue));
				drain_queue -= ceil(drain_queue);
			}
		}
	}

	ui bool ui_init;
	virtual ui void UIInit(){}
	virtual ui void drawOverlay(RenderEvent e, DD_EventHandler hndl){}
	virtual ui void drawUnderlay(RenderEvent e, DD_EventHandler hndl){}
	virtual ui bool inputProcess(InputEvent e){ return false; }

	virtual void ownerDamageTaken(int damage, Name damageType, out int newDamage,
					Actor inflictor, Actor source, int flags){}
	virtual void ownerDamageDealt(int damage, Name damageType, out int newDamage,
					Actor inflictor, Actor source, int flags){}


	// ---------
	// Functions
	// ---------

	// Called when augmentation is installed the first time.
	virtual void install()
	{
		id = -1;
		level = 1;
		max_level = 4;

		slots_cnt = 0;

		enabled = false;
	}

	// Called to toggle augmentation state.
	virtual void toggle()
	{
		enabled = !enabled;
		if(enabled)
			SoundUtils.playStartSound("ui/aug/activate");
		else
			SoundUtils.playStartSound("ui/aug/deactivate");
	}

	// ---------------------
	// Static util functions
	// ---------------------

	
	static void initAugPool(out array<class<DD_Augmentation> > aug_pool)
	{
		for(uint i = 0; i < allActorClasses.size(); ++i)
		{
			Class<Actor> cls = allActorClasses[i];
			if(cls == "DD_Augmentation" || !(cls is "DD_Augmentation"))
				continue;

			aug_pool.push(cls);
		}
	}
	// Called by augmentation canister to generate it's contents
	static void shuffleAugPool(in out array<class<DD_Augmentation> > aug_pool)
	{
		for(uint i = 0; i < aug_pool.size()/2; ++i)
		{
			uint i1 = random(0, aug_pool.size()-1);
			uint i2 = random(0, aug_pool.size()-1);
			class<DD_Augmentation> t = aug_pool[i1];
			aug_pool[i1] = aug_pool[i2];
			aug_pool[i2] = t;
		}
	}
}

