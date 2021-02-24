class KeyBindUtils
{
	static int keyCharToScan(int keyChar)
	{
		return keyChar - 55;
	}

	static bool checkBind(int keyScan, string command)
	{
		int kb1, kb2;
		[kb1, kb2] = Bindings.GetKeysForCommand(command);
		return kb1 == keyScan || kb2 == keyScan;
	}
}
