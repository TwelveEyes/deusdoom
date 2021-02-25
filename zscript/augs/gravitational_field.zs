class DD_Aug_GravitationalField : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}

	override int get_base_drain_rate(){ return 100; }

	override void install()
	{
		super.install();

		id = 2;
		disp_name = "Gravitational field";
		disp_desc = "Nanoscale gravity field generators work in a pattern that\n"
			    "constantly pushes away everything at little force.\n\n"
			    "TECH ONE: Objects are pushed a little.\n\n"
			    "TECH TWO: Objects are pushed more at further distance.\n\n"
			    "TECH THREE: Objects are pushed away significantly\n"
			    "faster and further.\n\n"
			    "TECH FOUR: All but the fastest and furthest objects are\n"
			    "violently pushed away.\n\n"
			    "Enrgy Rate: 100 Units/Minute";

		slots_cnt = 2;
		slots[0] = Subdermal1;
		slots[1] = Subdermal2;
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("EMPSHLD0");
		tex_on = TexMan.CheckForTexture("EMPSHLD1");
	}

	// ------------------
	// Internal functions
	// ------------------

	protected double getMaxVel() { return 10 + 5 * (getRealLevel() - 1); }
	protected double getPushVel() { return 80 + 120 * (getRealLevel() - 1); }
	protected double getRange() { return 160 + 32 * (getRealLevel() - 1); }

	// -------------
	// Engine events
	// -------------

	override void tick()
	{
		super.tick();

		if(!enabled)
			return;
		if(!owner)
			return;

		Actor obj;
		ThinkerIterator it = ThinkerIterator.create();
		while(obj = Actor(it.next()))
		{
			if(obj.bMissile)
				continue;
			if(owner.distance2D(obj) > getRange())
				continue;
			if(obj.vel.length() > getMaxVel())
				continue;

			vector3 push_vec = owner.vec3To(obj);
			double push_vec_ln = push_vec.length();
			if(push_vec_ln == 0)
				continue;
			push_vec /= push_vec_ln;
			push_vec *= getPushVel();
			push_vec /= obj.mass;

			obj.A_ChangeVelocity(push_vec.x, push_vec.y, push_vec.z);
		}
	}
}
