NeedleMineSkill = Class(Skill)
NeedleMineSkill.ClassName = 'NeedleMineSkill'
NeedleMineSkill.description = 'Gets things from a needle mine'

NeedleMineSkill.MineableItems = {
	'cobblestone',
	'gold_ore',
	'iron_ore',
	'coal',
	'dirt',
	'lapis_lazuli',
	'emerald',
	'redstone',
	'diamond',
	'gravel',
	--Could mine flint but its probably faster to mine gravel specifically then run a loop placing and digging that instead
	'stone:1', --granite
	'stone:3', --diorite
	'stone:5' --andesite
	--Could mine sand, but its probably faster to travel around looking for beaches
	--TODO: etc
}

function NeedleMineSkill:canHandleTask(task)
	--TODO: 'minecraft:sand:0' == 'sand'

	if isType(task, GatherItemTask) then
		for _, itemId in ipairs(NeedleMineSkill.MineableItems) do
			local detail = ItemDetail.FromId(itemId)
			if (detail:matches(task.item)) then
				return true
			end
		end
	end

	return false
end

function NeedleMineSkill:completeTask(task)
	local planner = Class.LoadOrNew('data/needleMines.tbl', NeedleMinePlanner, Mov:getPosition())
	fs.writeTableToFile('data/needleMines.tbl', planner:serialise())

	local needleMine = include 'api/needleMine'

	while (Inv:countItem(task.item) < task.amount) do
		local location = planner:getNextLocation()

		Mov:push(true, true, true)
		Nav:pathTo(location)
		Mov:pop()
		needleMine()

		fs.writeTableToFile('data/needleMines.tbl', planner:serialise())
	end

	return true
end
