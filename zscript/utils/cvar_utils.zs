class CVar_Utils
{
	// Description:
	// Gets a pair of offsets (x,y) using a CVar name without "x"/"y" postfix.
	// Return value:
	//	2D vector containing offsets if CVars could be obtained, (0,0) otherwise.
	static vector2 getOffset(string cvar_name)
	{
		vector2 off;
		CVar offvar = CVar.getCVar(cvar_name .. "x", players[consoleplayer]);
		if(offvar)
			off.x = offvar.getFloat();
		offvar = CVar.getCVar(cvar_name .. "y", players[consoleplayer]);
		if(offvar)
			off.y = offvar.getFloat();
		return off;
	}

	static bool isHUDDebugEnabled()
	{
		CVar dbg_cvar = CVar.getCVar("dd_hud_debug", players[consoleplayer]);
		return !dbg_cvar || dbg_cvar.getBool();
	}
}
