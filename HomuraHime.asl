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

        vars.Helper["isTransitioning"] = mono.Make<bool>(
            "LevelManager",
            "isTransitioning"
        );

        vars.Helper["nextLevel"] = mono.MakeString(
            "LevelManager",
            "NextWantToLoadLevel"
        );

        // Allow setting the value to null to detect finished battles
        vars.Helper["battleId"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;

        return true;
    });

    // Subchapters list to split on subchapter start
    vars.subchapters = new HashSet<string>()
    {
        // Mihare Shrine
        "HubWorld_Main",

        // Chapter 1
        "Level_1_Area_1_Main"
    };

    // Battles list used to split on battles Start/End
    vars.battleIds = new HashSet<Tuple<int, string>>()
    {
        // Final chapter
        Tuple.Create(13, "BattleRoundDefulat"),
        Tuple.Create(13, "HUD_RankAndResult_Battle_Final"),
    };

    // Logic variables
    vars.visitedSubchapters = new HashSet<string>();

    vars.startedBattles = new HashSet<Tuple<int, string>>();
    vars.finishedBattles = new HashSet<Tuple<int, string>>();
}

split
{
    // Split on subchapter change
    if (current.nextLevel != old.nextLevel)
    {
        // Only split if this is the first time we visit this subchapter to avoid double splitting
        if (vars.subchapters.Contains(current.nextLevel) && vars.visitedSubchapters.Add(current.nextLevel))
        {
            return true;
        }
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

start
{
    if (current.nextLevel == "Level_0_Main")
    {
        return true;
    }
}

isLoading
{
    return current.isTransitioning;
}

reset
{
    if (current.nextLevel == "StartScreen")
    {
        return true;
    }
}

onStart
{
    vars.visitedSubchapters.Clear();

    vars.startedBattles.Clear();
    vars.finishedBattles.Clear();
}

onReset
{
    vars.visitedSubchapters.Clear();

    vars.startedBattles.Clear();
    vars.finishedBattles.Clear();
}