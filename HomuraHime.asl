state("HomuraHime") { }

startup
{
    // Load asl-help binary and instantiate it
    // Will inject code into the asl in the background
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");

    // Set the helper to load the scene manager, you probably want this
    // (the helper is set at vars.Helper automagically)
    // vars.Helper.LoadSceneManager = true;

    // TODO
    // Add settings
    // settings.Add("Stage 1");
    // settings.Add("Stage 1_Savepoint 1-1", true, "Part 1", "Stage 1");
    // settings.Add("Stage 1_Savepoint 1-2", true, "Part 2", "Stage 1");
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        vars.Helper["category"] = mono.Make<int>(
            "StageManager",
            "ins",
            "currentCategory"
        );

        vars.Helper["battleId"] = mono.MakeString(
            "BattleRound",
            "Current",
            "battleRoundData",
            "ID"
        );

        // Allow setting the value to null to detect finished battles
        vars.Helper["battleId"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;

        return true;
    });

    // TODO Add missing battles to the list
    // Battles list
    vars.battleIds = new HashSet<Tuple<int, string>>()
    {
        // Chapter 1
        Tuple.Create(0, "HUD_RankAndResult_Battle_L1Boss"),

        // Chapter 3
        Tuple.Create(2, "HUD_RankAndResult_Battle_L3B01"),
        Tuple.Create(2, "HUD_RankAndResult_Battle_L3B02"),
        Tuple.Create(2, "HUD_RankAndResult_Battle_L3C01")
    };

    // Logic variables
    vars.startedBattles = new HashSet<Tuple<int, string>>();
    vars.finishedBattles = new HashSet<Tuple<int, string>>();
}

split
{
    if (current.category != old.category || current.battleId != old.battleId)
    {
        print("Category: " + old.category + "->" + current.category);
        print("BattleId: " + (old.battleId ?? "NULL") + "->" + (current.battleId ?? "NULL"));
    }

    // Split on battle start (current) and end (old)
    if (current.battleId != old.battleId)
    {
        // Split on battle start
        var currentPair = Tuple.Create(current.category, (string)current.battleId);

        if (vars.battleIds.Contains(currentPair) && vars.startedBattles.Add(currentPair))
        {
            return true;
        }

        // Split on battle end
        var oldPair = Tuple.Create(current.category, (string)old.battleId);

        if (vars.battleIds.Contains(oldPair) && vars.finishedBattles.Add(oldPair))
        {
            return true;
        }
    }
}

// start
// {
//     // Find new game start
//     if (current.stageName != old.stageName || current.checkpointName != old.checkpointName)
//     {
//         if (current.stageName == "Stage Start" && current.checkpointName == "Savepoint Start-1")
//         {
//             vars.startScene = true;
//         }
//     }

//     // Wait for first cutscene to end (goes from isCutscenePlaying True -> False)
//     if (vars.startScene && (old.isCutscenePlaying && !current.isCutscenePlaying))
//     {
//         return true;
//     }
// }

// isLoading
// {
//     return current.isLoadingScreen;
// }

// reset
// {
//     if (current.isTitleScreen && !old.isTitleScreen)
//     {
//         return true;
//     }
// }

onStart
{
    vars.startedBattles.Clear();
    vars.finishedBattles.Clear();
}

onReset
{
    vars.startedBattles.Clear();
    vars.finishedBattles.Clear();
}