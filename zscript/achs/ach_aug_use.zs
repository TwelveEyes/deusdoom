class DD_Achievement_AtYourService : DD_Achievement
{
	override void ui_init()
	{
		self.name = "At your service";
		self.desc = "Activate 5 unique switches with a single Spy Drone.";
		self.icon = TexMan.CheckForTexture("ACICON00");
		self.sound = "achievement/at_your_service";
	}
}
