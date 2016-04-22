if AAE.Utils == nil then
	AAE.Utils = {}
end

if AAE.Utils.Timer == nil then
	AAE.Utils.Timer = {}
end


function AAE.Utils.Timer.Init()
	local GameMode = GameRules:GetGameModeEntity()

	AAE.Utils.Timer._functions = {}

	AAE.Utils.Timer._counter = GameRules:GetGameTime()
end

function AAE.Utils.Timer.Think( time )
	AAE.Utils.Timer._counter = time

	for i = #AAE.Utils.Timer._functions, 1, -1 do
		local func = AAE.Utils.Timer._functions[ i ]
		if func.timer <= time then
			local nextTime = func.func(func.index)
			if nextTime == nil then
				table.remove( AAE.Utils.Timer._functions, i )
			else
				func.timer = AAE.Utils.Timer._counter + nextTime
			end
		end
	end
end

function AAE.Utils.Timer.Register( func, delay, index )
	table.insert( AAE.Utils.Timer._functions, { func = func, timer = AAE.Utils.Timer._counter + delay, index = index } )
end