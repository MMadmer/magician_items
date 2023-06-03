require "prefabutil"

local assets =
{
	Asset("ANIM", "anim/magician_chest.zip"),
	Asset("ANIM", "anim/ui_chest_4x5.zip"),
}

local prefabs = 
{
}

local function onopen(inst)
	inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")
	
	inst.AnimState:PlayAnimation("open")
	inst.AnimState:PushAnimation("loop")
end

local function onclose(inst)
	inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")
	
	inst.AnimState:PlayAnimation("close")
	inst.AnimState:PushAnimation("closed")
end

local function onhammered(inst, worker)
	inst.components.lootdropper:DropLoot()
	--inst.components.container:DropEverything()
	
	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
	inst:Remove()
end

local function onhit(inst, worker)
	inst.AnimState:PlayAnimation("hit")
	onclose(inst)
	
	inst.components.container:Close()
end

local function onbuilt(inst)
	inst.AnimState:PlayAnimation("place")
	inst.AnimState:PushAnimation("closed", false)
	inst.SoundEmitter:PlaySound("dontstarve/common/craftable/chest")
end

local slotpos = {}
for y = 2, 0, -1 do
	for x = 0, 3 do
		table.insert(slotpos, Vector3(80*x-346*2+72, 80*y-100*2+130,0))
	end
end

local function OnSave(inst, data)
	--print("magician saved")
end

local function OnLoad(inst, data)
	--print("magician loaded")
end

local function fn(Sim)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	
	local minimap = inst.entity:AddMiniMapEntity()
	minimap:SetIcon("magician_chest.tex")

	MakeObstaclePhysics(inst, 0.5)

	inst:AddTag("structure")

	inst.AnimState:SetBank("magician_chest")
	inst.AnimState:SetBuild("magician_chest")

	inst.AnimState:PushAnimation("closed")

	inst:AddComponent("inspectable")
	inst:AddComponent("container")
	inst.components.container:SetNumSlots(#slotpos)

	inst.components.container.onopenfn = onopen
	inst.components.container.onclosefn = onclose

	inst.components.container.widgetslotpos = slotpos
	inst.components.container.side_align_tip = 160

	inst:AddComponent("lootdropper")
	
	-- After shared always dimension
	inst:AddTag("shared")
	inst:AddTag(TUNING.GLOBAL_UTILS.DIMENSIONS[1])
	
	if TUNING.DESTRUCTION then
		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
		inst.components.workable:SetWorkLeft(5)
		inst.components.workable:SetOnWorkCallback(onhit)
		inst.components.workable:SetOnFinishCallback(onhammered)
	end
	
	inst:ListenForEvent( "onbuilt", onbuilt)
	MakeSnowCovered(inst)
	
	inst.OnLoad = OnLoad
	inst.OnSave = OnSave

	return inst
end

STRINGS.NAMES.MAGICIAN_CHEST = "Magician's Chest"
STRINGS.RECIPE_DESC.MAGICIAN_CHEST = "Imprison your belongings in  a shadowy vortex."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MAGICIAN_CHEST = "It's the safest place to be"

return Prefab( "common/magician_chest", fn, assets), 
	   MakePlacer("common/magician_chest_placer", "magician_chest", "magician_chest", "closed")
