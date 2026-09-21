-- Original silhouettes; reference URLs and limitations are documented in docs/ART_DIRECTION.md.
-- Gameplay IDs/rarity/ownership are unchanged by the visual redesign.
return {
    Units={
        StreetFighter={Outfit="Uniform",Hair="Sweep",Accent={233,118,88},Scarf=true},
        WindStudent={Outfit="Robe",Hair="Parted",Accent={164,223,196}},
        IronBrawler={Outfit="Armor",Hair="Crop",Accent={154,175,192}},
        FlameDisciple={Outfit="Haori",Hair="Flame",Accent={255,184,82}},
        StormNinja={Outfit="Uniform",Hair="Sweep",Accent={99,203,228},Mask=true,Scarf=true},
        SpiritKnight={Outfit="Armor",Hair="Parted",Accent={189,167,247}},
        VoidCaptain={Outfit="Longcoat",Hair="Crop",Accent={233,182,83}},
        CursedEmperor={Outfit="Robe",Hair="Long",Accent={255,140,161},Crown=true},
        ShadowSovereign={Outfit="Longcoat",Hair="Sweep",Accent={152,116,255},Crown=true},
        StarbornHero={Outfit="Armor",Hair="Flame",Accent={253,238,178},Crown=true},
    },
    -- Different shapes, not simply World 1 models painted purple.
    Enemies={
        [1]={Slime="Slime",Bandit="Shinobi",Ogre="Oni",Demon="Fiend",Titan="StoneGuardian",WorldBoss="Devourer"},
        [2]={Slime="Wisp",Bandit="Sentinel",Ogre="Obsidian",Demon="Reaper",Titan="Crystal",WorldBoss="Regent"},
    },
}
