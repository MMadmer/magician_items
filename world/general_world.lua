function GenWorld(inst)
	local function TableContains(tableData, element)
		for _, value in ipairs(tableData) do
			if value == element then
				return true
			end
		end
		
		return false
	end

	local function SaveDimContainers(inst)
		print("Saving")
		-- Get all spawned entities
		local entities = TheSim:FindEntities(0, 0, 0, 10000, {})
		
		local addedDim = {}
		
		for i, entity in ipairs(entities) do
			-- Access to every found entity
			if entity:HasTag("shared") and entity.components.container:IsEmpty() and not TableContains(addedDim, entity.components.container:GetDimension()) then
				entity.components.container.slots = inst.PocketDimensionContainers[entity.components.container:GetDimension()]
				table.insert(addedDim, entity.components.container:GetDimension())
				print(entity.prefab)
			end
			
			if #addedDim == #TUNING.GLOBAL_UTILS.DIMENSIONS then
				return
			end
		end
		print("Done")
	end
	
	inst.PocketDimensionContainers = {}
	for i, dim in pairs(TUNING.GLOBAL_UTILS.DIMENSIONS) do
		inst.PocketDimensionContainers[dim] = {}
	end
	
	inst.OnSave = 
	function(inst, data)
		data.culledGlowFlies = inst.culledGlowFlies
		data.culledMants = inst.culledMants
		data.fixedInteriorMirroring = inst.fixedInteriorMirroring
		data.fixedPlayerInteriorGridError = inst.fixedPlayerInteriorGridError
		data.fixedPlayerInteriorGridDuplication = inst.fixedPlayerInteriorGridDuplication
		data.movedInteriorSpawnOrigin = inst.movedInteriorSpawnOrigin
	
		if inst.cave_regenerator_retrofitted then
			data.cave_regenerator_retrofitted = true
		end
		
		SaveDimContainers(inst)
	end
	
	inst.OnLoad = 
	function(inst, data)
		inst.culledGlowFlies = data.culledGlowFlies
		inst.culledMants = data.culledMants
		inst.fixedInteriorMirroring = data.fixedInteriorMirroring
		inst.fixedPlayerInteriorGridError = data.fixedPlayerInteriorGridError
		inst.fixedPlayerInteriorGridDuplication = data.fixedPlayerInteriorGridDuplication
		inst.movedInteriorSpawnOrigin = data.movedInteriorSpawnOrigin
	
		if data and data.cave_regenerator_retrofitted then
			inst.cave_regenerator_retrofitted = true
		end
	end
end

AddPrefabPostInit("world", GenWorld)
