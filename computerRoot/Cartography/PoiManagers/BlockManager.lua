-- Store and maintain the current important _blocks

BlockManager = Class()
BlockManager.ClassName = 'BlockManager'

--[[
	name: name of the item, 'chest', 'furnace', or block query that is used to select the item from inventory
	location: Position

	where the direction provided in Position will be the approach direction
	from the turtle to the block
]]
function BlockManager:constructor(map)
	self._map = assertParameter(map, 'map', Map)
	self._blocks = {}

	self.ev = EventManager()
end

function BlockManager.Deserialize(data)
	local map = BlockManager()
	for blockType, _ in ipairs(data) do
		for _, blockData in ipairs(data[key]) do
			block = _G[blockType].ConvertToInstance(blockData)
			block.location = Position.ConvertToInstance(block.location)
			block.interfaceLocation = Position.ConvertToInstance(block.interfaceLocation)
			-- print(block.location:toString())

			local blockList = map._blocks[blockType]
			if (blockList == nil) then
				map._blocks[blockType] = {block}
			else
				table.insert(blockList, block)
			end
		end
	end

	-- print(tableToString(data))
	return map
end

function BlockManager:serialize()
	return self._blocks
end

function BlockManager:add(block)
	assertType(block, Block, 'Attempt to add a non block to a block map', 2)

	local blockType = block.ClassName

	if (self:findBlockByLocation(blockType, block.location) ~= nil) then
		return false
	end

	local blockList = self._blocks[blockType]
	if (blockList == nil) then
		self._blocks[blockType] = {block}
	else
		table.insert(blockList, block)
	end

	self.ev:trigger('state_changed')

	return true
end

function BlockManager:remove(block)
	assertType(block, Block, 'Attempt to remove a non block to a block map', 2)

	local blockType = block.ClassName

	local blockInMap, key = self:findBlockByLocation(blockType, block.location)
	if (blockInMap == nil) then
		return false
	end

	table.remove(self._blocks[blockType], key)

	self.ev:trigger('state_changed')

	return true
end

function BlockManager:findBlockByLocation(blockType, atPosition)
	assertType(atPosition, Position, 'Attempted to find a block by a location that wasnt a position object', 2)
	assertType(blockType, 'string', 'Attempted to find a block by a block type that wasnt a string object', 2)

	local position = atPosition
	local blocksOfType = self._blocks[blockType]
	if (blocksOfType == nil) then
		return nil
	end

	for k, block in ipairs(blocksOfType) do
		if (block.location:posEquals(position)) then
			return block, k
		end
	end

	return nil
end

-- returns the closest block of that type to the provided location
-- block type should be the class name of the block
function BlockManager:findNearest(blockType, toLocation)
	assertType(toLocation, Position, 'Attempted to find a block by a location that wasnt a position object', 2)
	assertType(blockType, 'string', 'Attempted to find a block by a block type that wasnt a string object', 2)

	local other = toLocation

	local currentSmallest = nil
	local smallestDistance = 99999999

	if (self._blocks[blockType] == nil) then
		return nil
	end

	for _, block in ipairs(self._blocks[blockType]) do
		local distance = block.location:distanceTo(other)
		if distance < smallestDistance then
			smallestDistance = distance
			currentSmallest = block
		end
	end

	return currentSmallest
end