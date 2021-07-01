class DD_Achievement_VisionAugmented : DD_Achievement
{
	override void ui_init()
	{
		self.name = "My vision is augmented";
		self.desc = "Install and max out any eyes augmentation.";
		self.icon = TexMan.CheckForTexture("ACICON00");
		self.sound = "achievement/vision_is_augmented";
	}

	override void augUpgraded(DD_Augmentation aug)
	{
		if( (aug is "DD_Aug_VisionEnhancement" || aug is "DD_Aug_Targeting")
		&& aug.level >= 4)
		{
			self.complete = true;
		}
	}
}

class DD_Achievement_TheDragonToothRight : DD_Achievement
{
	override void ui_init()
	{
		self.name = "The Dragon Tooth, right";
		self.desc = "Install and max out Combat Strength augmentation.";
		self.icon = TexMan.CheckForTexture("ACICON00");
		self.sound = "achievement/the_dragon_tooth_right";
	}

	override void augUpgraded(DD_Augmentation aug)
	{
		if( (aug is "DD_Aug_CombatStrength")
		&& aug.level >= 4)
		{
			self.complete = true;
		}
	}
}

class DD_Achievement_PreparedToPerformDuties : DD_Achievement
{
	override void ui_init()
	{
		self.name = "I am prepared to perform my duties";
		self.desc = "Install your first augmentation.";
		self.icon = TexMan.CheckForTexture("ACICON00");
		self.sound = "achievement/prepared_to_perform_duties";
	}

	override void augInstalled(DD_AugsHolder hld, DD_Augmentation aug)
	{
		self.complete = true;
	}
}

class DD_Achievement_PreparedForAFight : DD_Achievement
{
	override void ui_init()
	{
		self.name = "I am prepared for a fight";
		self.desc = "Install all 10 augmentations.";
		self.icon = TexMan.CheckForTexture("ACICON00");
		self.sound = "achievement/prepared_for_a_fight";
	}

	override void augInstalled(DD_AugsHolder hld, DD_Augmentation aug)
	{
		int augs_cnt = 0;
		for(int i = 0; i < DD_AugsHolder.augs_slots; ++i)
			if(hld.augs[i]) ++augs_cnt;

		if(augs_cnt == DD_AugsHolder.augs_slots-1)
			self.complete = true;
	}
}
