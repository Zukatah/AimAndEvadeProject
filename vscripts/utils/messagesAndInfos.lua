
--Give info about streaks and multikills; TODO: --Noch zu integrieren! Eigene Kill Multikill und Streakinfos; welcher Spieler usw; nur an Spieler "key" anzeigen
function StreakAndMultikillHeaders (key)
    if (AAE.PlayerMultikill[key].curCount >= 5) then
        ShowCustomHeaderMessage(AAE.multikillTable[5], 0, 0, 5)
    else
        for i = 2, 4, 1 do
            if (AAE.PlayerMultikill[key].curCount == i) then
                ShowCustomHeaderMessage(AAE.multikillTable[i], 0, 0, 5)
                break
            end
        end
    end
    if (AAE.PlayerStreak[key] >= 10) then
        ShowCustomHeaderMessage(AAE.streakTable[10], 0, 0, 5)
    else
        for i = 3, 9, 1 do
            if (AAE.PlayerStreak[key] == i) then
                ShowCustomHeaderMessage(AAE.streakTable[i], 0, 0, 5)
                break
            end
        end
    end
end



--Send pregame messages: TODO: Check if it works!
function PregameInfoMessages ()
    UTIL_MessageTextAll("Choose 5 abilities, the shortcuts are Q, W, E, R, T in the order you pick them (otherwise your specific DotA-config).\nAll abilities are skill shots, so the target is 'point' or 'no target' (but depended on your unit's facing) and not 'unit'.", 255, 0, 0, 1000)
    UTIL_MessageTextAll("\nBe aware of the moving lightning in the map. You can use them to enforce some abilities or to kick your enemys next to them.", 255, 0, 0, 1000)
    UTIL_MessageTextAll("\n\nMap created by Zukatah and Rogen.", 0, 255, 0, 1000)
    UTIL_MessageText(1, "\n\nPlease choose now: Left: Teamfight; Right: FFA", 0, 0, 255, 1000)
end