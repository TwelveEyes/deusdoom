class TextureUtils : Actor
{
	// Description:
	// Gets a sprite texture from a frame from actor's current state.
	static clearscope TextureID, bool getActorSpriteTex(Actor ac, int byteang)
	{
		TextureID tex; bool flip;
		State st = ac.curState;

		if(!st.validateSpriteFrame()){
			[tex, flip] = ac.spawnState.getSpriteTexture(byteang);
		}
		else{
			[tex, flip] = st.getSpriteTexture(byteang);
		}
		return tex, !flip;
	}
	// Description:
	// Similar to getActorSpriteTexture, but byte angle is calculated depending on other actor's looking direction
	static clearscope TextureID, bool getActorRenderSpriteTex(Actor ac, Actor looker)
	{
		double objang = deltaAngle(looker.angleTo(ac), ac.angle) + 180.0;
		int byteang =  ( (objang + 22.5) / 45) % 8;
		TextureID tex; bool flip;
		[tex, flip] = getActorSpriteTex(ac, byteang * 2);
		return tex, flip;
	}
}
