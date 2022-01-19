class DD_Aug_GravitationalField : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;
	ui TextureID tex_alt;

	override TextureID get_ui_texture(bool state)
	{
		return !state ? tex_off
		      : mode  ? tex_alt
		      : tex_on;
	}

	override int get_base_drain_rate(){ return 100; }

	override void install()
	{
		super.install();

		id = 2;
		disp_name = "Gravitational field";
		disp_desc = "Nanoscale gravity field generators work in a pattern\n"
			    "that constantly pushes away everything at little force.\n\n"
			    "TECH ONE: Objects are pushed a little.\n\n"
			    "TECH TWO: Objects are pushed more at further\n"
			    "distance.\n\n"
			    "TECH THREE: Objects are pushed away significantly\n"
			    "faster and further.\n\n"
			    "TECH FOUR: All but the fastest and furthest objects\n"
			    "are violently pushed away.\n\n"
			    "Energy Rate: 100 Units/Minute\n\n";

		disp_legend_desc = "LEGENDARY UPGRADE: gains a second mode\n"
				      "that reverses gravity generation,\n"
				      "pulling objects towards the agent\n"
				      "instead of pushing them. Also improves\n"
				      "overall performance of the augmentation.";

		slots_cnt = 2;
		slots[0] = Subdermal1;
		slots[1] = Subdermal2;

		can_be_legendary = true;

		mode = 0;
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("EMPSHLD0");
		tex_on = TexMan.CheckForTexture("EMPSHLD1");
		tex_alt = TexMan.CheckForTexture("EMPSHLD2");
	}

	// ------------------
	// Internal functions
	// ------------------

	protected double getMaxVel() { return 10 + 5 * (getRealLevel() - 1) + (isLegendary() ? 15 : 0); }
	protected double getPushForce() { return 80 + 120 * (getRealLevel() - 1) + (isLegendary() ? 50 : 0); }
	protected double getRange() { return 160 + 50 * (getRealLevel() - 1) + (isLegendary() ? 70 : 0); }

	int mode;	// 0 - push, 1 - pull

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
		BlockThingsIterator it = BlockThingsIterator.Create(owner, getRange());
		while(it.next())
		{
			obj = it.thing;
			if(owner.distance2D(obj) > getRange())
				continue;
			if(obj.vel.length() > getMaxVel())
				continue;

			vector3 push_vec = owner.vec3To(obj);
			double push_vec_ln = push_vec.length();
			if(push_vec_ln == 0)
				continue;

			push_vec /= push_vec_ln;
			push_vec *= getPushForce();
			if(isLegendary() && mode)
				push_vec *= -0.6;
			push_vec /= obj.mass;

			obj.A_ChangeVelocity(push_vec.x, push_vec.y, push_vec.z);
		}
	}
}
