class TextureUtils : Actor
{
	// Description:
	// Gets a sprite texture from a frame from actor's current state.
	// Uses a buffer to keep sprites used before wildcard frames (because wildcard sprites
	// are seemingly unobtainable) and their flip flag. Giving an invalid texture
	// (-1 texture index) results in not using buffer at all.
	// Also I cannot assign a default value to sbuft (cannot initialize it in a single statement).
	static clearscope TextureID, bool getActorSpriteTex(Actor ac, int byteang,
				in out TextureID sbuft, in out bool sbufb)
	{
		if(ac.curState.bSameFrame)
		{
			TextureID ntex;
			ntex.setNull();
			if(!sbuft.isValid())
				return ntex, false;
			if(sbuft.isNull())
				return ntex, false;

			return sbuft, sbufb;
		}

		TextureID tex; bool flip;
		[tex, flip] = ac.curState.getSpriteTexture(byteang);
		sbuft = tex; sbufb = flip;
		return tex, !flip;
	}
	// Description:
	// Similar to getActorSpriteTexture, but byte angle is calculated depending on other actor's looking direction
	static clearscope TextureID, bool getActorRenderSpriteTex(Actor ac, Actor looker,
				in out TextureID sbuft, in out bool sbufb)
	{
		double objang = deltaAngle(looker.angleTo(ac), ac.angle) + 180.0;
		int byteang =  ( (objang + 22.5) / 45) % 8;
		TextureID tex; bool flip;
		[tex, flip] = getActorSpriteTex(ac, byteang * 2, sbuft, sbufb);
		return tex, flip;
	}
}
