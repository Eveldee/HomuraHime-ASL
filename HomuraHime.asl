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
        // Tutorial
        // "Level_0_Main",

        // --- Chapter 1: The Skeleton Girl
        "Level_1_Area_1_Main", // Adashino - Spiriting Away Border
        "Level_1_Ikai_Part_1_Main", // Demonic Realm - Carcass Ravine
        "Level1Boss_Main", // Agasa, Skeleton Girl

        // --- Chapter 2: The Flower and Corpse Princess
        "Level_2_Area_1_Main", // ??? - Hidden Path
        "Level_2_Area_3_Main", // Tanka Castle - Ninomaru Palace
        "Level_2_Area_5_Main", // Tanka Castle - Sannomaru Palace
        "Level_2_Area_6_Main", // Tanka Castle - Rakka Observatory
        "Level2Boss_Main", // Ling Ling, Flower and Corpse Princess

        // --- Chapter 3: The Holy Maiden of the Full Moon Order
        "Level_3_Area_1_Main", // Chirakuin - Front Gates
        "Level_3_Area_3_Main", // Chirakuin - Study
        "Level_3_Area_5_Main", // Chirakuin - Confessional
        "Level_3_Ikai_Part2_Main", // Demonic Realm - Twisted Utopia
        "Level3Boss_Main", // Chirakuin, Holy Maiden of the Full Moon Order

        // --- Chapter 4: The Twin Watchdogs
        "Level_4_Area_1_Main", // Kemono Island - Inugami Hill
        "Level_4_Ikai_Part1_Main", // Demonic Realm - Twilight Demonic Capital
        "Level_4_Area_3_Main", // Inumachi 1st District - Riverside
        "Level_4_Ikai_Part2_Main", // Demonic Realm - Airship
        "Level_4_Area_4_Main", // Mikan Festival - Shiba Shrine Approach
        "Level_4_Boss", // Yumiko & Kumiko, Twin Watchdogs

        // --- Chapter 5: The Fallen Samurai
        "Level_5_Area_1_Main", // Adashino - Firefly Bridges
        "Level_5_Area_4_Main", // Memory - Break of Dawn
        "Level_5_Area_5_Main", // Memory - Home
        "Level_5_Boss", // Mamiya, Fallen Samurai

        // --- Climax: The Choice
        "Level_FinalP0_Jinguu_Main", // Jinguu

        // --- Chapter 6: Where it All Began
        "Level_FinalP1_L1_Ikai_Main", // Demonic Realm - Carcass Ravine
        "Level_FinalP1_L2_A5_Main", // Tanka Castle - Sannomaru Palace
        "Level_FinalP1_L2Boss_Main", // Reunion: Ling Ling

        // --- Chapter 7: The Brambled Path of Rebellion
        "Level_FinalP2_L3_A5_Main", // Chirakuin: Confessional
        "Level_FinalP2_L3Boss_Main", // Reunion: Nozomi
        "Level_FinalP2_L4_A2_Main", // Inumachi 2nd District - Shopping District
        "Level_FinalP2_L4Boss_Phase1_Main", // Reunion: Yumiko & Kumiko

        // --- Chapter 8: The Future of Reunion
        "Level_FinalP3_L5_Ikai_Main", // Demonic Realm - Snowy End
        "Level_FinalP3_L5_A2_Main", // Reunion: Agasa
        "Level_FinalP3_L5_A5_Main", // Memory - Home
        "Level_FinalP3_L5Boss_Main", // Reunion: Mamiya

        // --- Final: Desire
        "Level_FinalP4_Passage_Main", // Jinguu - Pathway
        "Level_FinalP4_Jinguu_Phase1_Main", // Admini, the Adjucator
        "Level_FinalP4_Jinguu_Phase2_Main" // Admini, the Divine Punisher
    };

    // Logic variables
    vars.visitedSubchapters = new HashSet<string>();
    vars.visitedTransitionsToHub = new HashSet<string>();

    vars.finalBattleDone = false;
}

split
{
    // Split on subchapter change
    if (current.nextLevel != old.nextLevel)
    {
        // Exception for Mihare Shrine (HubWorld_Main) as it is visited multiple times
        if (current.nextLevel == "HubWorld_Main" && vars.visitedTransitionsToHub.Add(old.nextLevel))
        {
            return true;
        }
        // Only split if this is the first time we visit this subchapter to avoid double splitting
        else if (vars.subchapters.Contains(current.nextLevel) && vars.visitedSubchapters.Add(current.nextLevel))
        {
            return true;
        }
    }

    // Split on battle last battle end (final boss)
    if (current.battleId != old.battleId && !vars.finalBattleDone)
    {
        if (current.category == 13 && old.battleId == "HUD_RankAndResult_Battle_Final")
        {
            vars.finalBattleDone = true;

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
    if (current.nextLevel != old.nextLevel && current.nextLevel == "StartScreen")
    {
        return true;
    }
}

onStart
{
    vars.visitedSubchapters.Clear();
    vars.visitedTransitionsToHub.Clear();

    vars.finalBattleDone = false;
}

onReset
{
    vars.visitedSubchapters.Clear();
    vars.visitedTransitionsToHub.Clear();

    vars.finalBattleDone = false;
}