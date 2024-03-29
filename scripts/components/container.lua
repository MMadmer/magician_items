require "class"

local Container = Class(function(self, inst)
    self.inst = inst
    self.slots = {}
    self.boatequipslots = {}
    self.hasboatequipslots = false
    self.enableboatequipslots = true
    self.numslots = 0
    self.canbeopened = true
    self.acceptsstacks = true
    self.side_widget = false
    self.type = "chest"
	
	self.wasOpened = false
end)

function Container:SetWidgetInfo(widgetinfo)
    self.widgetslotpos =  widgetinfo.widgetslotpos
    self.side_align_tip =  widgetinfo.side_align_tip
    self.canbeopened =  widgetinfo.canbeopened
    self.type =  widgetinfo.type
    self.widgetanimbank =  widgetinfo.widgetanimbank
    self.widgetanimbuild =  widgetinfo.widgetanimbuild
    self.widgetbgatlas =  widgetinfo.widgetbgatlas
    self.widgetbgimage =  widgetinfo.widgetbgimage
    self.widgetpos =  widgetinfo.widgetpos
    self.widgetbuttoninfo =  widgetinfo.widgetbuttoninfo
    self.widgetboatbadgepos =   widgetinfo.widgetboatbadgepos
    self.widgetequipslotroot =  widgetinfo.widgetequipslotroot
end

function Container:GetWidgetInfo(boatwidget)
    local widgetinfo = {}
    if not boatwidget then
        widgetinfo.widgetslotpos = self.widgetslotpos
        widgetinfo.side_align_tip = self.side_align_tip
        widgetinfo.canbeopened = self.canbeopened
        widgetinfo.type = self.type
        widgetinfo.widgetanimbank = self.widgetanimbank
        widgetinfo.widgetanimbuild = self.widgetanimbuild
        widgetinfo.widgetbgatlas = self.widgetbgatlas
        widgetinfo.widgetbgimage = self.widgetbgimage
        widgetinfo.widgetpos = self.widgetpos
        widgetinfo.widgetbuttoninfo = self.widgetbuttoninfo
        widgetinfo.widgetboatbadgepos = self.widgetboatbadgepos 
        widgetinfo.widgetequipslotroot = self.widgetequipslotroot
		widgetinfo.hscale = self.hscale or 1
    else
        widgetinfo = self.boatwidgetinfo
    end

    return widgetinfo
end

function Container:NumItems()
    local num = 0
    for k,v in pairs(self.slots) do
        num = num + 1
    end
    
    return num
end

function Container:IsShared()
	return self.inst:HasTag("shared")
end

function Container:GetDimension()
	for i, dim in pairs(TUNING.GLOBAL_UTILS.DIMENSIONS) do
		if self.inst:HasTag(dim) then
			return dim
		end
	end

	print("Dimension not found:", self.inst.prefab)
	return nil
end

function Container:FindDimAnalog()
	-- Get all spawned entities
	local entities = TheSim:FindEntities(0, 0, 0, 10000, {})
	
	for i, entity in ipairs(entities) do
		-- Access to every found entity
		if entity:HasTag("shared") and entity.components.container:GetDimension() == self:GetDimension() and entity ~= self.inst then
			return entity
		end
	end
	
	return nil
end

function Container:OpenedCount()
	-- Get all spawned entities
	local entities = TheSim:FindEntities(0, 0, 0, 10000, {})
	local counter = 0
	
	for i, entity in ipairs(entities) do
		-- Access to every found entity
		if entity:HasTag("shared") and entity.components.container:GetDimension() == self:GetDimension() and entity ~= self.inst then
			if entity.components.container.wasOpened then
				counter = counter + 1
			end
		end
	end
	
	return counter
end

function Container:OnRemoveEntity()
	if self.open then
		local old_opener = self.opener
		if self.opener and self.opener.HUD then
			local opener = self.opener
			self.opener = nil
			opener.HUD:CloseContainer(self.inst, self.side_widget)
		end
		self:OnClose(old_opener)
	end
	
	if self:IsShared() then
		local entity = self:FindDimAnalog()
		-- print(#GetWorld().PocketDimensionContainers[self:GetDimension()])
		
		-- if entity ~= nil then
			-- entity.components.container.slots = GetWorld().PocketDimensionContainers[self:GetDimension()]
		-- else
			-- local x, y, z = 0, 0, -100
			-- local spawnedPrefab  = SpawnPrefab(self.inst.prefab)
			
			-- spawnedPrefab.Transform:SetPosition(x, y, z)
			-- spawnedPrefab.Physics:Teleport(x, y, z)
			-- spawnedPrefab.components.container.slots = GetWorld().PocketDimensionContainers[self:GetDimension()]
		-- end
		
		-- Drop loot if last dimension container
		if entity == nil or self:OpenedCount() == 0 then
			self:DropEverything()
		end
	end
end


function Container:IsFull()
	local items = 0
	for k,v in pairs(self.slots) do
		items = items + 1
    end
	return items >= self.numslots
end

function Container:IsEmpty()
	for k,v in pairs(self.slots) do
		return false
	end
	
	return true
end


function Container:SetNumSlots(numslots, skipcheck)
    if not skipcheck then 
        assert(numslots >= self.numslots)
    end 
    self.numslots = numslots
end


function Container:DropEverything()
    for k = 1,self.numslots do
		local item = self:RemoveItemBySlot(k)
        if item then
			local pos = Vector3(self.inst.Transform:GetWorldPosition())
			item.Transform:SetPosition(pos:Get())
			if item.components.inventoryitem then
				item.components.inventoryitem:OnDropped(true)
			end
			self.inst:PushEvent("dropitem", {item = item})
        end
    end
    if self.hasboatequipslots then 
         for k,v in pairs(self.boatequipslots) do
            local item = self:Unequip(k)
            if item then
                local pos = Vector3(self.inst.Transform:GetWorldPosition())
                item.Transform:SetPosition(pos:Get())
                if item.components.inventoryitem then
                    item.components.inventoryitem:OnDropped(true)
                end
                self.inst:PushEvent("dropitem", {item = item})
            end           
           
        end    
    end 
end

function Container:DropItem(itemtodrop, wholestack)
    local item = self:RemoveItem(itemtodrop, wholestack)
    if item then 
        local pos = Vector3(self.inst.Transform:GetWorldPosition())
        item.Transform:SetPosition(pos:Get())
        if item.components.inventoryitem then
            item.components.inventoryitem:OnDropped(true)
        end
        self.inst:PushEvent("dropitem", {item = item})                  
    end
end

function Container:CanTakeItemInSlot(item, slot)
	if not (item and item.components.inventoryitem and item.components.inventoryitem.cangoincontainer) then
		return false
	end
	
	if self.itemtestfn then
		return self.itemtestfn(self.inst, item, slot)
	end

	return true
end

function Container:DestroyContents()
	for k = 1,self.numslots do
		local item = self:RemoveItemBySlot(k)
		if item then
			item:Remove()
		end		
	end
end

function Container:GiveItem(item, slot, src_pos, drop_on_fail, skipsound)
    drop_on_fail = drop_on_fail == nil and true or drop_on_fail
    --print("Container:GiveItem", item.prefab)
    if item and item.components.inventoryitem and self:CanTakeItemInSlot(item, slot) then
		
		--try to burn off stacks if we're just dumping it in there
		if item.components.stackable and slot == nil and self.acceptsstacks then
            for k = 1,self.numslots do
				local other_item = self.slots[k]
				if other_item and other_item.prefab == item.prefab and not other_item.components.stackable:IsFull() then
					
					if self.inst.components.inventoryitem and self.inst.components.inventoryitem.owner and not skipsound then
						self.inst.components.inventoryitem.owner:PushEvent("containergotitem", {item = item, src_pos = src_pos})
					end
					
		            item = other_item.components.stackable:Put(item, src_pos)
		            if not item then
						return true
		            end
				end
            end
		end
		
        local use_slot = slot and slot <= self.numslots and not self.slots[slot]
        local in_slot = nil
        if use_slot then
            in_slot = slot
        elseif self.numslots > 0 then
            for k = 1,self.numslots do
                if not self.slots[k] then
                    in_slot = k
                    break
                end
            end
        end
        
        if in_slot then

			local owner = item.components.inventoryitem.owner
			--weird case where we are trying to force a stack into a non-stacking container. this should probably have been handled earlier, but this is a failsafe        
			if item.components.stackable and item.components.stackable:StackSize() > 1 and not self.acceptsstacks then
				item = item.components.stackable:Get()
				self.slots[in_slot] = item
				item.components.inventoryitem:OnPutInInventory(self.inst)
				self.inst:PushEvent("itemget", {slot = in_slot, item = item, src_pos = src_pos, owner = owner})	
				return false
			end
			
			self.slots[in_slot] = item
			item.components.inventoryitem:OnPutInInventory(self.inst)
			self.inst:PushEvent("itemget", {slot = in_slot, item = item, src_pos = src_pos, owner = owner})

			if self.inst.components.inventoryitem and self.inst.components.inventoryitem.owner and not skipsound then
				self.inst.components.inventoryitem.owner:PushEvent("containergotitem", {item = item, src_pos = src_pos})
            elseif self.type == "boat" and not skipsound then 
                GetPlayer():PushEvent("containergotitem", {item = item, src_pos = src_pos})
			end
			
			return true
        else
            if drop_on_fail then
				item.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
				if item.components.inventoryitem then
	                item.components.inventoryitem:OnDropped(true)
				end
			end				
            return false
        end
        
    end
end


function Container:RemoveItemBySlot(slot)
    if slot and self.slots[slot] then
        local item = self.slots[slot]
        if item then
			self.slots[slot] = nil
			if item.components.inventoryitem then
				item.components.inventoryitem:OnRemoved()
			end
			
			self.inst:PushEvent("itemlose", {slot = slot})
		end
        item.prevcontainer = self
        item.prevslot = slot
        return item        
    end
end

function Container:RemoveAllItems()
    local items = {}

    for k = 1,self.numslots do
        local item = self:RemoveItemBySlot(k)
        if item then
            table.insert(items, item)
        end
    end

    return items
end

function Container:GetNumSlots()
    return self.numslots
end

function Container:GetItemInSlot(slot)
    if slot and self.slots[slot] then
        return self.slots[slot]
    end
end

function Container:GetItemInBoatSlot(slot)
    if slot and self.boatequipslots[slot] then 
        return self.boatequipslots[slot]
    end 
end 

function Container:GetItemSlot(item)
    for k,v in pairs(self.slots) do
        if item == v then
            return k
        end
    end
end

function Container:Close(doer)	
	if self.open then
		local old_opener = self.opener
		if self.opener and self.opener.HUD then
			local opener = self.opener
			self.opener = nil
			opener.HUD:CloseContainer(self.inst, self.side_widget)
		end
		
		if self:IsShared() then
			GetWorld().PocketDimensionContainers[self:GetDimension()] = self.slots
			print(#GetWorld().PocketDimensionContainers[self:GetDimension(self.inst)])
		end
		
		self:OnClose(old_opener)
	end
end

function Container:Open(doer)
	self.wasOpened = true

	self.opener = doer
	if not self.open then
		if self:IsShared() then
			--print("Is shared")
			print(#GetWorld().PocketDimensionContainers[self:GetDimension()])
			self.slots = GetWorld().PocketDimensionContainers[self:GetDimension()]
			if #GetWorld().PocketDimensionContainers[self:GetDimension(self.inst)] > 0 then
				for key, dim in pairs(GetWorld().PocketDimensionContainers[self:GetDimension()]) do
					print(key)
					print(dim)
				end
				--print(GetWorld().PocketDimensionContainers)
			end
		end
	
		if doer and doer.HUD then
            if self.type == "boat" then
                doer.HUD:OpenBoat(self.inst, doer.components.driver and doer.components.driver.vehicle == self.inst)
            else
			    doer.HUD:OpenContainer(self.inst, self.side_widget)
            end
		end

		self:OnOpen()
	end
end

function Container:OnOpen()
    self.open = true
    
	if self.opener and self.opener.components.inventory then
		self.opener.components.inventory.opencontainers[self.inst] = true
        self.opener:PushEvent("refreshcrafting")
	end
    
    self.inst:PushEvent("onopen", {doer = self.opener})

    if self.onopenfn then
        self.onopenfn(self.inst)
    end
end

function Container:IsOpen()
	return self.open
end

function Container:OnClose(old_opener)
   	if old_opener and old_opener.components.inventory then
   		old_opener.components.inventory.opencontainers[self.inst] = nil
        old_opener:PushEvent("refreshcrafting")
   	end

    if self.open then
        self.open = false
        
        if self.onclosefn then
            self.onclosefn(self.inst)
        end

        self.inst:PushEvent("onclose")
    end
end

function Container:CollectSceneActions(doer, actions, right)
    if self.inst:HasTag("bundle") then
        if right and self:IsOpenedBy(doer) then
            table.insert(actions, ACTIONS.WRAPBUNDLE)
        end
    elseif not self.inst:HasTag("burnt") then
        if doer.components.inventory and self.canbeopened then
            table.insert(actions, ACTIONS.RUMMAGE)
        end
        if right and self.type == "boat" then --right click open is special case for boats.
            table.insert(actions, ACTIONS.RUMMAGE)
        end
    end
end

function Container:CollectInventoryActions(doer, actions)
    if not self.inst:HasTag("burnt") then
        if doer.components.inventory and self.canbeopened then
            if not (self.side_widget and TheInput:ControllerAttached()) then
                table.insert(actions, ACTIONS.RUMMAGE)
            end
        end
    end
end

function Container:FindItem(fn)
    for k,v in pairs(self.slots) do
        if fn(v) then
            return v
        end
    end
end

function Container:FindItems(fn)
    local items = {}
    
    for k,v in pairs(self.slots) do
        if fn(v) then
            table.insert(items, v)
        end
    end

    return items
end

function Container:Count(item)
    local num_found = 0
    for k,v in pairs(self.slots) do
        if v and v.prefab == item then
            if v.components.stackable ~= nil then
                num_found = num_found + v.components.stackable:StackSize()
            else
                num_found = num_found + 1
            end
        end
    end

    return num_found
end

function Container:Has(item, amount)
    local num_found = self:Count(item)
    return num_found >= amount, num_found
end

function Container:GetItemByName(item, amount)
    local total_num_found = 0
    local items = {}

    local function tryfind(v)
        local num_found = 0
        if v and v.prefab == item then
            local num_left_to_find = amount - total_num_found
            if v.components.stackable then
                if v.components.stackable.stacksize > num_left_to_find then
                    items[v] = num_left_to_find
                    num_found = amount
                else
                    items[v] = v.components.stackable.stacksize
                    num_found = num_found + v.components.stackable.stacksize
                end
            else
                items[v] = 1
                num_found = num_found + 1
            end
        end
        return num_found
    end

    for k,v in pairs(self.slots) do
        total_num_found = total_num_found + tryfind(v)
        
        if total_num_found >= amount then
            break
        end
    end

    return items
end

local function GetStackSize(inst)
    if inst.components.stackable == nil then
        return 1
    end

    return inst.components.stackable:StackSize()
end

local function crafting_priority_fn(a, b)
    if a.stacksize == b.stacksize then
        return a.slot < b.slot
    end
    return a.stacksize < b.stacksize --smaller stacks first
end

function Container:GetCraftingIngredient(item, amount, reverse_search_order)
    local items = {}
    for i = 1, self.numslots do
        local v = self.slots[i]
		if v ~= nil and v.prefab == item then
            table.insert(items, {
                item = v,
                stacksize = GetStackSize(v),
                slot = reverse_search_order and (self.numslots - (i - 1)) or i,
            })
        end
    end

    table.sort(items, crafting_priority_fn)

    local crafting_items = {}
    local total_num_found = 0
    for i, v in ipairs(items) do
        local stacksize = math.min(v.stacksize, amount - total_num_found)
        crafting_items[v.item] = stacksize
        total_num_found = total_num_found + stacksize
        if total_num_found >= amount then
            break
        end
    end

    return crafting_items
end

function Container:ConsumeByName(item, amount)
    
    local total_num_found = 0
    
    local function tryconsume(v)
		local num_found = 0
        if v and v.prefab == item then
            local num_left_to_find = amount - total_num_found            
            if v.components.stackable then
                if v.components.stackable.stacksize > num_left_to_find then
                    v.components.stackable:SetStackSize(v.components.stackable.stacksize - num_left_to_find)
                    num_found = amount
                else
                    num_found = num_found + v.components.stackable.stacksize
                    self:RemoveItem(v, true):Remove()
                end
            else
                num_found = num_found + 1
                self:RemoveItem(v):Remove()
            end
        end
        return num_found
    end   

    for k,v in pairs(self.slots) do
        total_num_found = total_num_found + tryconsume(v)
        
        if total_num_found >= amount then
            break
        end
    end

    return total_num_found
end

function Container:OnSave()
    local data = {items= {}, boatequipitems = {}}
    local references = {}
    local refs = {}
    for k,v in pairs(self.slots) do
        if v.persists then --only save the valid items
			data.items[k], refs = v:GetSaveRecord()
            if refs then
                for k,v in pairs(refs) do
                    table.insert(references, v)
                end 
            end
        end
    end
     for k,v in pairs(self.boatequipslots) do
        if v.persists then --only save the valid items
            data.boatequipitems[k], refs = v:GetSaveRecord()
            if refs then
                for k,v in pairs(refs) do
                    table.insert(references, v)
                end
            end
        end
    end
    return data, references
end

function Container:OnLoad(data, newents)
    if data.items then
        for k,v in pairs(data.items) do
            local inst = SpawnSaveRecord(v, newents)
            if inst then
                self:GiveItem(inst, k)
            end
        end
    end
    if data.boatequipitems then
        for k,v in pairs(data.boatequipitems) do
            local inst = SpawnSaveRecord(v, newents)
            if inst then
                self:Equip(inst, false)
            end
        end
    end
	
	-- Access to every spawned inst
	if self:IsShared("shared") then
		print("Shared")
		print(self.inst.prefab)
		print(self:IsEmpty())
		if not self:IsEmpty() then
			GetWorld().PocketDimensionContainers[self:GetDimension()] = self.slots
			print("Not empty:", self.prefab)
		end
	end
	
	self.wasOpened = false
end


function Container:Equip(item, old_to_active)
    if not item or not item.components.equippable or not item:IsValid() then
        return
    end
    --What inventory slot is this item currently in 
   -- item.prevslot = self:GetItemSlot(item) 
    --print("inventory?", item.components.inventoryitem.owner.components.inventory)
    local inventoryFrom = nil
    local containerFrom = nil 

    if item.components.inventoryitem.owner then 
        local owner = item.components.inventoryitem.owner
        if owner.components.inventory then 
            inventoryFrom = owner.components.inventory
        elseif owner.components.container then 
            containerFrom = owner.components.container
        end         
    end 
    
    if item.components.inventoryitem.owner and item.components.inventoryitem.owner.components.inventory then 
        item.prevslot = item.components.inventoryitem.owner.components.inventory:GetItemSlot(item)
    end 
    if item.prevslot == nil --Not in an inventory slot? What container and container slot is it in? 
            and item.components.inventoryitem.owner
            and item.components.inventoryitem.owner.components.container 
            and item.components.inventoryitem.owner.components.inventoryitem then
        item.prevcontainer = item.components.inventoryitem.owner.components.container
        item.prevslot = item.components.inventoryitem.owner.components.container:GetItemSlot(item)
    end
    
    item = item.components.inventoryitem:RemoveFromOwner(item.components.equippable.equipstack) or item
    
    if GetPlayer().components.inventory:GetActiveItem() == item then 
        GetPlayer().components.inventory:SetActiveItem(nil)
    end 

    local eslot = item.components.equippable.boatequipslot
    if self.boatequipslots[eslot] ~= item then
        local olditem = self.boatequipslots[eslot]
        if olditem then
            self:Unequip(eslot)
            olditem.components.equippable:ToPocket()
            if olditem.components.inventoryitem and not olditem.components.inventoryitem.cangoincontainer and not self.ignorescangoincontainer then
                olditem.components.inventoryitem:OnRemoved()
                self:DropItem(olditem)
            else
                if old_to_active and inventoryFrom then
                    inventoryFrom:GiveActiveItem(olditem)
                elseif inventoryFrom then 
                    inventoryFrom:GiveItem(olditem)
                elseif containerFrom then 
                    containerFrom:GiveItem(olditem)
                end
            end    
        end
        
        item.components.inventoryitem:OnPutInInventory(self.inst)
        item.components.equippable:Equip(self.inst)
        self.boatequipslots[eslot] = item
        --print(self.inst.prefab)
        self.inst:PushEvent("equip", {item=item, eslot=eslot})
        --if METRICS_ENABLED and item.prefab then
         --   ProfileStatsAdd("equip_"..item.prefab)
          --  FightStat_Equip(item.prefab,eslot)
        --end
        
        return true
    end
    -----
    --self.inst:PushEvent("equip", {item=item, eslot=eslot})
end

function Container:Unequip(equipslot)
    local item = self.boatequipslots[equipslot]
     if item and item.components.equippable then
        item.components.equippable:Unequip(self.inst)
    end
    self.boatequipslots[equipslot] = nil
    self.inst:PushEvent("unequip", {item=item, eslot=equipslot})
    return item
end 

function Container:RemoveItem(item, wholestack)
    local dec_stack = not wholestack and item and item.components.stackable and item.components.stackable:IsStack() and item.components.stackable:StackSize() > 1
	local slot = self:GetItemSlot(item)
    if dec_stack then
        local dec = item.components.stackable:Get()
        dec.components.inventoryitem:OnRemoved()
        dec.prevslot = slot
        dec.prevcontainer = self
        return dec
    else
        for k,v in pairs(self.slots) do
            if v == item then
                self.slots[k] = nil
                self.inst:PushEvent("itemlose", {slot = k, boatequipslot = nil})

                if item.components.inventoryitem then
                    item.components.inventoryitem:OnRemoved()
                end

		        item.prevslot = slot
		        item.prevcontainer = self
                return item
            end
        end
        if self.hasboatequipslots then 
            for k,v in pairs(self.boatequipslots) do
                if v == item then
                    --print("found item equipped!!!")
                    --self.boatequipslots[k] = nil
                    self.inst:PushEvent("itemlose", {slot = nil, boatequipslot = k}) 

                    if item.components.inventoryitem then
                        item.components.inventoryitem:OnRemoved()
                    end

                    self:Unequip(k)
                    item.prevslot = slot
                    item.prevcontainer = self
                    return item
                end
            end
        end 

    end
    
    return item

end

function Container:IsOpenedBy(guy)
    return self.opener == guy
end


return Container
