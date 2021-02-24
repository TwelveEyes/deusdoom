class RecognitionUtils
{
	array<class<Actor> > projCanBeDestroyed_wl;
	array<class<Actor> > projCanBeDestroyed_bl;
	array<double> projCanBeDestroyed_cd_ml;

	array<class<Actor> > damageIsBallistic_Source_wl;
	array<class<Actor> > damageIsBallistic_Source_bl;
	array<class<Actor> > damageIsBallistic_Inflictor_wl;
	array<class<Actor> > damageIsBallistic_Inflictor_bl;
	array<double> damageIsBallistic_Source_protfact_ml;
	array<double> damageIsBallistic_Inflictor_protfact_ml;

	array<class<Actor> > isFooledByCloak_wl;
	array<class<Actor> > isFooledByCloak_bl;

	array<class<Actor> > isFooledByRadarTransparency_wl;
	array<class<Actor> > isFooledByRadarTransparency_bl;

	array<class<Actor> > isHandToHandDamage_Weapon_wl;
	array<class<Actor> > isHandToHandDamage_Weapon_bl;
	array<class<Actor> > isHandToHandDamage_Inflictor_wl;
	array<class<Actor> > isHandToHandDamage_Inflictor_bl;

	array<class<Actor> > damageIsEnergy_Source_wl;
	array<class<Actor> > damageIsEnergy_Source_bl;
	array<class<Actor> > damageIsEnergy_Inflictor_wl;
	array<class<Actor> > damageIsEnergy_Inflictor_bl;
	array<double> damageIsEnergy_Source_protfact_ml;
	array<double> damageIsEnergy_Inflictor_protfact_ml;

	array<class<Actor> > damageIsEnvironmental_Source_wl;
	array<class<Actor> > damageIsEnvironmental_Source_bl;
	array<class<Actor> > damageIsEnvironmental_Inflictor_wl;
	array<class<Actor> > damageIsEnvironmental_Inflictor_bl;
	array<double> damageIsEnvironmental_Source_protfact_ml;
	array<double> damageIsEnvironmental_Inflictor_protfact_ml;

	// Description:
	// Should be called from an event handler's event onRegister().
	// Loads special lumps with information about black- and whitelisted
	// actors for certain checks.
	void loadLists()
	{
		for(int hndl = wads.FindLump("DDRGLIST", 0, wads.ANYNAMESPACE);
			hndl != -1;
			hndl = wads.FindLump("DDRGLIST", hndl+1, wads.ANYNAMESPACE))
		{
			processList(wads.readLump(hndl));
		}
	}
	protected void processList(string data)
	{
		int pstate = 0; // state of the parser:
				// 0 - looking for an actor class name
				// 1 - skipping a comment
				// 2 - reading actor class name
				// 3 - looking for a list attribute
				// 4 - reading a list attribute
		string actor_cls_name;
		class<Actor> actor_cls;
		array<string> lst_attribs;
		
		for(int i = 0; i < data.length(); ++i)
		{
			int c = data.byteAt(i);
			switch(pstate)
			{
				case 0:
				{ // looking for an actor class name
					if(c == ch("#")){
						pstate = 1;
					}
					else if(c != ch(" ") && c != ch("\n") && c != ch("\t")){
						pstate = 2;
						actor_cls_name.appendCharacter(c);
					}
				} break;
				case 1:
				{ // skipping a comment
					if(c == ch("\n")){
						pstate = 0;
					}
				} break;
				case 2:
				{ // reading actor class name
					if(c == ch(" ") || c == ch("\n") || c == ch("\t")){
						pstate = 3;
						actor_cls = actor_cls_name;
						if(!actor_cls){
							console.printf("[DeusDoom]ERROR: actor class \"%s\" does not exist",
									actor_cls_name);
						}
					}
					else{
						actor_cls_name.appendCharacter(c);
					}
				} break;
				case 3:
				{ // 3 - looking for a list attribute
					if(c != ch(" ") && c != ch("\n") && c != ch("\t")){
						pstate = 4;
						lst_attribs.push("");
						lst_attribs[lst_attribs.size()-1].appendCharacter(c);
					}
					else if(c == ch(";")){
						pstate = 0;
						actor_cls_name = "";
						lst_attribs.clear();
					}
				} break;
				case 4:
				{
					if(c == ch(" ") || c == ch("\n") || c == ch("\t") || c == ch(";")){
						if(c == ch(";"))
							pstate = 0;
						else
							pstate = 3;

						string attr = lst_attribs[lst_attribs.size()-1];

						if(attr.byteAt(0) == ch("$"))
						{ // it's a number
							if(lst_attribs.size() == 1){
								console.printf("[DeusDoom]ERROR: encountered a number \"%s\" without any preceeding attribute",
										attr);
								break;
							}
							string prev_attr;
							int prev_attr_i;
							bool prev_attr_found = false;
							for(int i = lst_attribs.size()-1; i >= 0; --i)
							{
								if(lst_attribs[i].byteAt(0) != ch("$")){
									prev_attr = lst_attribs[i];
									prev_attr_i = i;
									prev_attr_found = true;
									break;
								}
							}
							if(!prev_attr_found){
								console.printf("[DeusDoom]ERROR: encountered a number \"%s\" without any preceeding attribute",
										attr);
								break;
							}

							if(prev_attr == "projCanBeDestroyed")
								projCanBeDestroyed_cd_ml[prev_attr_i] = (attr.mid(1).toDouble());
							else if(prev_attr == "damageIsBallistic_Source")
								damageIsBallistic_Source_protfact_ml[prev_attr_i] = (attr.mid(1).toDouble());
							else if(prev_attr == "damageIsBallistic_Inflictor")
								damageIsBallistic_Inflictor_protfact_ml[prev_attr_i] = (attr.mid(1).toDouble());
							else if(prev_attr == "damageIsEnergy_Source")
								damageIsEnergy_Source_protfact_ml[prev_attr_i] = (attr.mid(1).toDouble());
							else if(prev_attr == "damageIsEnergy_Inflictor")
								damageIsEnergy_Inflictor_protfact_ml[prev_attr_i] = (attr.mid(1).toDouble());
							else if(prev_attr == "damageIsEnvironmental_Source")
								damageIsEnvironmental_Source_protfact_ml[prev_attr_i] = (attr.mid(1).toDouble());
							else if(prev_attr == "damageIsEnvironmental_Inflictor")
								damageIsEnvironmental_Inflictor_protfact_ml[prev_attr_i] = (attr.mid(1).toDouble());
						}
						else if(attr.byteAt(0) == ch("!"))
						{ // blacklist
							attr = attr.mid(1);
							if(attr == "projCanBeDestroyed")
								projCanBeDestroyed_bl.push(actor_cls);
							else if(attr == "damageIsBallistic_Source")
								damageIsBallistic_Source_bl.push(actor_cls);
							else if(attr == "damageIsBallistic_Inflictor")
								damageIsBallistic_Inflictor_bl.push(actor_cls);
							else if(attr == "isFooledByCloak")
								isFooledByCloak_bl.push(actor_cls);
							else if(attr == "isFooledByRadarTransparency")
								isFooledByRadarTransparency_bl.push(actor_cls);
							else if(attr == "isHandToHandDamage_Weapon")
								isHandToHandDamage_Weapon_bl.push(actor_cls);
							else if(attr == "isHandToHandDamage_Inflictor")
								isHandToHandDamage_Inflictor_bl.push(actor_cls);
							else if(attr == "damageIsEnergy_Source")
								damageIsEnergy_Source_bl.push(actor_cls);
							else if(attr == "damageIsEnergy_Inflictor")
								damageIsEnergy_Inflictor_bl.push(actor_cls);
							else if(attr == "damageIsEnvironmental_Source")
								damageIsEnvironmental_Source_bl.push(actor_cls);
							else if(attr == "damageIsEnvironmental_Inflictor")
								damageIsEnvironmental_Inflictor_bl.push(actor_cls);
							else
								console.printf("[DeusDoom]ERROR: no attribute \"%s\" exists",
										attr);
						}
						else
						{ // whitelist
							if(attr == "projCanBeDestroyed"){
								projCanBeDestroyed_wl.push(actor_cls);
								projCanBeDestroyed_cd_ml.push(1.0);
							}
							else if(attr == "damageIsBallistic_Source"){
								damageIsBallistic_Source_wl.push(actor_cls);
								damageIsBallistic_Source_protfact_ml.push(1.0);
							}
							else if(attr == "damageIsBallistic_Inflictor"){
								damageIsBallistic_Inflictor_wl.push(actor_cls);
								damageIsBallistic_Inflictor_protfact_ml.push(1.0);
							}
							else if(attr == "isFooledByCloak")
								isFooledByCloak_wl.push(actor_cls);
							else if(attr == "isFooledByRadarTransparency")
								isFooledByRadarTransparency_wl.push(actor_cls);
							else if(attr == "isHandToHandDamage_Weapon")
								isHandToHandDamage_Weapon_wl.push(actor_cls);
							else if(attr == "isHandToHandDamage_Inflictor")
								isHandToHandDamage_Weapon_wl.push(actor_cls);
							else if(attr == "damageIsEnergy_Source"){
								damageIsEnergy_Source_wl.push(actor_cls);
								damageIsEnergy_Source_protfact_ml.push(1.0);
							}
							else if(attr == "damageIsEnergy_Inflictor"){
								damageIsEnergy_Inflictor_wl.push(actor_cls);
								damageIsEnergy_Inflictor_protfact_ml.push(1.0);
							}
							else if(attr == "damageIsEnvironmental_Source"){
								damageIsEnvironmental_Source_wl.push(actor_cls);
								damageIsEnvironmental_Source_protfact_ml.push(1.0);
							}
							else if(attr == "damageIsEnvironmental_Inflictor"){
								damageIsEnvironmental_Inflictor_wl.push(actor_cls);
								damageIsEnvironmental_Inflictor_protfact_ml.push(1.0);
							}
							else
								console.printf("[DeusDoom]ERROR: no attribute \"%s\" exists",
										attr);
						}
						if(pstate == 0){
							actor_cls_name = "";
							lst_attribs.clear();
						}
					}
					else{
						lst_attribs[lst_attribs.size()-1].appendCharacter(c);
					}
				}
			}
		}
	}
	protected int ch(string str)
	{
		return str.byteAt(0);
	}

	// Description:
	// Small internal function that glorifies getting an instance of this class
	// from DeusDoom event handler.
	static RecognitionUtils getInstance()
	{
		return DD_EventHandler(StaticEventHandler.Find("DD_EventHandler")).recg_utils;
	}

	static bool, uint findActorClass(Actor a, array<class<Actor> > arr)
	{
		uint i = 0;
		for(; i < arr.size(); ++i)
			if(a is arr[i])
				return true, i;
		return false, i;
	}

	// Description:
	// Function for Agressive Defense augmentation that checks if the projectile
	// can be blown up. Doesn't check range (augmentation checks it instead).
	// proj_cd is projectile destruction cooldown multiplier.
	static bool projCanBeDestroyed(Actor proj, out double proj_cd_ml)
	{
		RecognitionUtils inst = getInstance();
		proj_cd_ml = 1.0;

		if(!proj.bMissile)
			return false;
		if(!proj.target || !(proj.target is "PlayerPawn"))
		{
			if(findActorClass(proj, getInstance().projCanBeDestroyed_bl))
				return false;
			bool in_wl; uint wl_i;
			[in_wl, wl_i] = findActorClass(proj, getInstance().projCanBeDestroyed_wl);
			if(in_wl){
				proj_cd_ml = getInstance().projCanBeDestroyed_cd_ml[wl_i];
				return true;
			}
		}

		return proj.bSeekerMissile;
	}

	// Description:
	// Function for Ballistic Protection augmentation that checks if the damage dealt
	// is a "ballistic" type of damage. That is instantly applied to most hitscan
	// sources with exceptions for some mods that use bullet-like projectiles
	// or use hitscan attacks for something not related to ballistic damage.
	// Can also change protection factor to balance some things, like make SpiderMastermind
	// ignore a lot of protection not to make her even more weak.
	static bool damageIsBallistic(Actor inflictor, Actor source,
						Name damageType, int damageMobjFlags,
						out double protfact_ml)
	{
		protfact_ml = 1.0;

		// Source
		if(source)
		{
			if(findActorClass(source, getInstance().damageIsBallistic_Source_bl))
				return false;
			bool in_wl; uint wl_i;
			[in_wl, wl_i] = findActorClass(source, getInstance().damageIsBallistic_Source_wl);
			if(in_wl){
				protfact_ml = getInstance().damageIsBallistic_Source_protfact_ml[wl_i];
				return true;
			}
		}

		// Inflictor
		if(inflictor)
		{
			if(findActorClass(inflictor, getInstance().damageIsBallistic_Inflictor_bl))
				return false;
			bool in_wl; uint wl_i;
			[in_wl, wl_i] = findActorClass(inflictor, getInstance().damageIsBallistic_Inflictor_wl);
			if(in_wl){
				protfact_ml = getInstance().damageIsBallistic_Inflictor_protfact_ml[wl_i];
				return true;
			}
		}

		if(damageMobjFlags & DMG_INFLICTOR_IS_PUFF){
			return true;
		}

		return false;
	}

	// Description:
	// Function for Cloak augmentation that checks if the given monster should ignore
	// players that has Cloak augmentation activated.
	static bool isFooledByCloak(Actor monster)
	{
		if(findActorClass(monster, getInstance().isFooledByCloak_bl))
			return false;
		if(findActorClass(monster, getInstance().isFooledByCloak_wl))
			return true;
		return !monster.bBoss;
	}
	// Description:
	// Function for Radar Transparency augmentation that checks if the given monster should ignore
	// players that has Radar Transparency augmentation activated.
	static bool isFooledByRadarTransparency(Actor monster)
	{
		if(findActorClass(monster, getInstance().isFooledByRadarTransparency_bl))
			return false;
		if(findActorClass(monster, getInstance().isFooledByRadarTransparency_wl))
			return true;
		return monster.bBoss;
	}

	// Description:
	// Function for Combat Strength augmentation that checks if a player dealt damage with
	// a melee weapon that can be boosted by Combat Strength augmentation (i.e. not
	// chainsaws).
	// Expected to be called if player is the damage source.
	static bool isHandToHandDamage(PlayerPawn source,
					Actor inflictor, Actor victim,
					Name damageType, int damageMobjFlags)
	{
		if(inflictor)
		{
			if(findActorClass(inflictor, getInstance().isHandToHandDamage_Inflictor_bl))
				return false;
			if(findActorClass(inflictor, getInstance().isHandToHandDamage_Inflictor_wl))
				return true;
		}
		if(damageMobjFlags & DMG_INFLICTOR_IS_PUFF && source && source.player){
			// Hitscan attack, player probably has a weapon out
			if(source.player.readyWeapon)
			{
				if(findActorClass(source.player.readyWeapon, getInstance().isHandToHandDamage_Weapon_bl))
					return false;
				if(findActorClass(source.player.readyWeapon, getInstance().isHandToHandDamage_Weapon_wl))
					return true;
			}
		}

		if(source && source.player && source.player.readyWeapon && source.player.readyWeapon.bMeleeWeapon)
			return true;

		return false;
	}

	// Description:
	// Function for Energy Shield augmentation that checks if the damage dealt
	// is an "energy" type of damage. That is instantly applied to most projectiles
	// with exceptions for some mods that use hitscan or other types of damage infliction
	// for something related to energy damage.
	// Can also change protection factor to balance some things.
	static bool damageIsEnergy(Actor inflictor, Actor source,
						Name damageType, int damageMobjFlags,
						out double protfact_ml)
	{
		protfact_ml = 1.0;


		// Source
		if(source)
		{
			if(findActorClass(source, getInstance().damageIsEnergy_Source_bl))
				return false;
			bool in_wl; uint wl_i;
			[in_wl, wl_i] = findActorClass(source, getInstance().damageIsEnergy_Source_wl);
			if(in_wl){
				protfact_ml = getInstance().damageIsEnergy_Source_protfact_ml[wl_i];
				return true;
			}
		}
		// Inflictor
		if(inflictor)
		{
			if(findActorClass(inflictor, getInstance().damageIsEnergy_Inflictor_bl))
				return false;
			bool in_wl; uint wl_i;
			[in_wl, wl_i] = findActorClass(inflictor, getInstance().damageIsEnergy_Inflictor_wl);
			if(in_wl){
				protfact_ml = getInstance().damageIsEnergy_Inflictor_protfact_ml[wl_i];
				return true;
			}
		}

		if(inflictor && inflictor.bMissile){
			return true;
		}

		return false;
	}

	// Description:
	// Function for Environmental Resistance augmentation that checks if the damage dealt
	// is an "environmental" type of damage. This applies by default to damaging
	// floors of any kind, or if no inflictor nor source are provided (i.e. lava floors)
	static bool damageIsEnvironmental(Actor inflictor, Actor source,
						Name damageType, int damageMobjFlags,
						out double protfact_ml)
	{
		protfact_ml = 1.0;

		// Source
		if(source)
		{
			if(findActorClass(source, getInstance().damageIsEnvironmental_Source_bl))
				return false;
			bool in_wl; uint wl_i;
			[in_wl, wl_i] = findActorClass(source, getInstance().damageIsEnvironmental_Source_wl);
			if(in_wl){
				protfact_ml = getInstance().damageIsEnvironmental_Source_protfact_ml[wl_i];
				return true;
			}
		}
		// Inflictor
		if(inflictor)
		{
			if(findActorClass(inflictor, getInstance().damageIsEnvironmental_Inflictor_bl))
				return false;
			bool in_wl; uint wl_i;
			[in_wl, wl_i] = findActorClass(inflictor, getInstance().damageIsEnvironmental_Inflictor_wl);
			if(in_wl){
				protfact_ml = getInstance().damageIsEnvironmental_Inflictor_protfact_ml[wl_i];
				return true;
			}
		}

		if( (!source && !inflictor)
		|| damageType == "Slime")
			return true;
		return false;
	}
}
