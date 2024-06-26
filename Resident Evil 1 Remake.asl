/*
Resident Evil HD Remaster Autosplitter Version 5.0.0
Supports room-room splits for every category, in addition to key-item and key-event splits.
Split files may be obtained from: 
by CursedToast 2/22/2016 (1.0 initial release) to 5/18/2018 (3.0 release)

Special thanks to:
Fatalis - original game time
Dchaps - initial scripting/data mining support
Pessimism - split order support, recorded runs with CE running for room ID data so I didn't have to.
LileyaCelestie - recorded runs with CE running for room ID data so I didn't have to.
wooferzfg - LiveSplit coding support and for developing LiveSplit so this script could happen
ZerothGames - item and inventory values
GrowthKasei - split order support.
Skhowl - splitter upkeep and rework
TheDementedSalad - load remover and rework

Beta testers:
Pessimism, LileyaCelestie, GrowthKasei, Bawkbasoup, ZerothGames.

Donators that supported this script's development:
Pessimism

Thank you to all the above people for helping me make this possible.
-CursedToast/Nate
*/

state("bhd")
{
	float time:			0x97C9C0, 0xE474C;
	int dslot1:			0x97C9C0, 0x5088;
	int dslot2:			0x97C9C0, 0x508C;
	int area:			0x97C9C0, 0xE4750;
	int room:			0x97C9C0, 0xE4754;
	int camera:			0x97C9C0, 0xE48B0;
	int playing:		0x98A0B0, 0x04;
	int vidplaying: 	0x9E4464, 0x5CBAC;
	
	byte load:			0x9E4270, 0x4F0;
	byte cutscene:		0x97C398, 0x1658;
}

startup
{
	/* Debug messages for DebugView (https://docs.microsoft.com/en-us/sysinternals/downloads/debugview) */
	//vars.DebugMessage = (Action<string>)((message) => { print("[ebug] " + message); });
	
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
	vars.Helper.Settings.CreateFromXml("Components/RE1make.Settings.xml");
	
	vars.Items = new List<int>()
    {4, 6, 7, 13, 21, 22, 23, 24, 26, 28, 29, 
	 30, 31, 32, 43, 45, 46, 47, 48, 49, 50, 
	 51, 52, 53, 54, 55, 60, 61, 63, 64, 65, 
	 66, 67, 69, 70, 71, 72, 74, 76, 77, 78,
	 80, 90, 91, 92, 93, 94, 95, 96, 97, 99, 
	 100, 102, 103, 106, 107, 110, 111, 112, 
	 123, 124, 125, 126, 127, 128, 129};
	 
	vars.Events = new List<int>()
    {11121, 31707, 22205, 22214, 30208, 31508, 32406, 32107, 50608, 51510, 51707};
	
	
}

init
{
	vars.compSplitsInt = new HashSet<int>();
	vars.compSplitsTxt = new HashSet<string>();
	current.Inventory = new int[9];

	refreshRate = 120.0;
}

update
{ 
	if(timer.CurrentPhase == TimerPhase.NotRunning)
	{
		vars.compSplitsInt.Clear();
		vars.compSplitsTxt.Clear();
		vars.keys = new HashSet<string>();
	}

	//Iterate through the inventory slots to return their values
	for(int i = 0; i < 9; i++)
	{
		current.Inventory[i] = new DeepPointer(0x97C9C0, 0x38 + (i * 0x8)).Deref<int>(game);
    }
	
	if(current.playing == 0x0550 && current.time < 0.05){
		for (int i = 1; i < 4; i++)
		{
			if (settings["outfit"+i])
			{
				game.WriteValue<int>(game.ReadPointer((IntPtr)modules.First().BaseAddress+0x97C9C0) + 0x5114, i);
				break;
			}
		}
	}
}

start
{
	if (current.area == 1 && current.room == 5 && current.camera == 0 && current.load == 0 && current.cutscene == 1){
		return true;
	}
	return false;
}

isLoading
{
	return current.load == 1 || current.cutscene == 2 || current.vidplaying != 0;
}

reset
{
	return current.playing == 0x0140 && old.playing == 0x0550;
}

split
{
	/* ROOMS */
	int RoomID = current.room;
	if (RoomID != old.room)
	{
		return settings["DoorSplit"];
	}

	/* VIDEOS */
	int AreaID = current.area;
	if (current.vidplaying > 0)
	{
		if (current.playing == 0x01B0 && !vars.compSplitsTxt.Contains("Ending"))
		{
			vars.compSplitsTxt.Add("Ending");
			return true;
		}
	}

	/*	For a full documentary look at:
		https://docs.google.com/spreadsheets/d/1tCN-INVKPmbCZTmgJvYW3zQOAaArVHfor1OXZDsn6EU */
	ushort SceneID = (ushort)(AreaID*10000+RoomID*100+current.camera);
	//vars.DebugMessage("Area: "+current.area+", Room: "+current.room+", Camera: "+current.camera+", Scene: "+SceneID+" (0x"+SceneID.ToString("X4")+")");


	//Event Splits
	if(settings["EventSplit"]){
		if(SceneID == 30110 && old.camera == 7 && !vars.compSplitsInt.Contains(30110)){
			vars.compSplitsInt.Add(30110);
            return settings["30110"];
		}
		else if(vars.Events.Contains(SceneID) && !vars.compSplitsInt.Contains(SceneID)){
            vars.compSplitsInt.Add(SceneID);
            return settings[SceneID.ToString()];
        }
	}
	
	//Inventory Splitter
	if(settings["ItemSplit"]){
		int[] currentInventory = (current.Inventory as int[]);
		
		for(int i = 0; i < 9; i++){
			//Old Keys
			if(currentInventory[i] == 44){
				if(SceneID == 10917 && !vars.compSplitsTxt.Contains("K1")){
					vars.compSplitsTxt.Add("K1");
					return settings["K1"];
				}
				else if(SceneID == 12401 && !vars.compSplitsTxt.Contains("K2")){
					vars.compSplitsTxt.Add("K2");
					return settings["K2"];
				}
				else if(SceneID == 11404 && !vars.compSplitsTxt.Contains("K3")){
					vars.compSplitsTxt.Add("K3");
					return settings["K3"];
				}
			}
			//Stone & Metal Objects
			else if(currentInventory[i] == 53 && SceneID == 12605 && !vars.compSplitsTxt.Contains("SM2")){
					vars.compSplitsTxt.Add("SM2");
					return settings["SM2"];
				}
			else if(currentInventory[i] != 52 && SceneID == 10603 && !vars.compSplitsTxt.Contains("SM3")){
				vars.compSplitsTxt.Add("SM3");
				return settings["SM3"];
			}
			//Other Item Splits
			else if(vars.Items.Contains(currentInventory[i]) && !vars.compSplitsInt.Contains(currentInventory[i])){
            	vars.compSplitsInt.Add(currentInventory[i]);
            	return settings[currentInventory[i].ToString()];
        	}
    	}
	}
	return false;
}
