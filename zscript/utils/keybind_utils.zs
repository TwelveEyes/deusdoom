class KeyBindUtils
{
	static const int keychars[] = {96, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 45, 61, 8, 81, 87, 69, 82, 84, 89, 85, 73, 79, 80, 91, 93, 92, 65, 83, 68, 70, 71, 72, 74, 75, 76, 59, 39, 13, 90, 88, 67, 86, 66, 78, 77, 44, 46, 47, 32};
	static const int keyscans[] = {41, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 43, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 28, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 57, 56};
	const keyarrs_ln = 50;

	static int keyCharToScan(int keyChar)
	{
		for(uint i = 0; i < KeyBindUtils.keyarrs_ln; ++i)
			if(KeyBindUtils.keychars[i] == keyChar){
				return KeyBindUtils.keyscans[i];
			}

		return 0;
	}

	static bool checkBind(int keyScan, string command)
	{
		int kb1, kb2;
		[kb1, kb2] = Bindings.GetKeysForCommand(command);
		return kb1 == keyScan || kb2 == keyScan;
	}
}
