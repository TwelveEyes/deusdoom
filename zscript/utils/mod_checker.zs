class DD_ModChecker
{
	bool mod_loaded_cache[1];
	// Indicies:
	// 0 - HDest

	void init()
	{
		for(uint i = 0; i < AllActorClasses.size(); ++i)
			if(AllActorClasses[i].getClassName() == "HDPlayerPawn"){
				mod_loaded_cache[0] = true;
		}
	}
	static DD_ModChecker getInstance()
	{
		return DD_EventHandler(StaticEventHandler.find("DD_EventHandler")).mod_checker;
	}

	static bool isLoaded_HDest()
	{
		let inst = getInstance();
		return inst.mod_loaded_cache[0];
	}
}

class DD_PatchChecker
{
	bool patch_loaded_cache[1];
	// Indicies:
	// 0 - HDest

	void init()
	{
		for(uint i = 0; i < AllActorClasses.size(); ++i)
			if(AllActorClasses[i].getClassName() == "DD_HDHealthGiver"){
				patch_loaded_cache[0] = true;
		}
	}
	static DD_PatchChecker getInstance()
	{
		return DD_EventHandler(StaticEventHandler.find("DD_EventHandler")).patch_checker;
	}

	static bool isLoaded_HDest()
	{
		let inst = getInstance();
		return inst.patch_loaded_cache[0];
	}
}
