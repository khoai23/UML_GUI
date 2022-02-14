import types
from vehicle_systems.CompoundAppearance import CompoundAppearance
from vehicle_systems import camouflages
from items.customizations import CustomizationOutfit, CamouflageComponent, DecalComponent
from items.components.c11n_constants import ApplyArea
from vehicle_outfit.outfit import Outfit
import BigWorld
import ResMgr

import os, io

# BigWorld.injector_LastCompoundAppearance = None
# BigWorld.injector_LastOutfitCD = None

# decal_idx = 38 # try replace armored flag on both
"""old_applyVehicleOutfit = CompoundAppearance._CompoundAppearance__applyVehicleOutfit
def new_applyVehicleOutfit(self):
    print("[Injector] _applyVehicleOutfit called, setting to default.")
    BigWorld.injector_LastCompoundAppearance = self
    return old_applyVehicleOutfit(self)
CompoundAppearance._CompoundAppearance__applyVehicleOutfit = new_applyVehicleOutfit"""

# this function seems only to work in battle.
"""old_prepareOutfit = CompoundAppearance._prepareOutfit
def new_prepareOutfit(self, outfitCD):
    print("[Injector] _prepareOutfit called, setting to no outfit for everyone.")
    return Outfit(CustomizationOutfit().makeCompDescr())
    return old_prepareOutfit(self, outfitCD)
CompoundAppearance._prepareOutfit = new_prepareOutfit
"""
BigWorld.forcedCustomizationDict = getattr(BigWorld, "forcedCustomizationDict", dict())

def tryLoadIntValue(section, valueName, stringValue=None, tupleSizeCheck=None):
    """Try load tuple of int; if failed, load single int; if failed, return None
    Basically, either try to get `valueName` from section, or parse an independent string @ stringValue"""
    if(isinstance(stringValue, int)):
        return stringValue # if loaded in as int 
    elif(stringValue is None):
        stringValue = section.readString(valueName, "") # if needed to get from section
    if(stringValue == ""):
        return None
    try:
        if("," in stringValue):
            intTuple = tuple([int(v.strip()) for v in stringValue.split(",")])
            if(tupleSizeCheck and len(intTuple) != tupleSizeCheck):
                raise ValueError("Failed tuple size check: tuple`{}` original `{}` size`{}`".format(intTuple, stringValue, tupleSizeCheck))
            return intTuple
        else:
            return int(stringValue)
    except ValueError as e:
        print("Error @replaceOwnCustomization: can't convert value {} for int or int tuple of size {}. True error line: {}".format(stringValue, tupleSizeCheck, e))
        return 0
    return None

def loadSettingFromOMConfig(ownModelPath="scripts/client/mods/ownModel.xml"):
    """Update fields: OM.playerForcedEmblem (int or (int, int)); similar for allied/enemy"""
    # playerObject, alliedObject, enemyObject = [object() for _ in range(3)]
    sectionMain = ResMgr.openSection(ownModelPath)
    # emblem idx
    playerForcedEmblem = tryLoadIntValue(sectionMain, "player/forcedEmblem", tupleSizeCheck=2)
    allyForcedEmblem = tryLoadIntValue(sectionMain, "ally/forcedEmblem", tupleSizeCheck=2)
    enemyForcedEmblem = tryLoadIntValue(sectionMain, "enemy/forcedEmblem", tupleSizeCheck=2)
    # if set, force to display 2nd emblem regardless of original data
    playerForcedBothEmblem = sectionMain.readBool("player/forcedBothEmblem", False)
    allyForcedBothEmblem = sectionMain.readBool("ally/forcedBothEmblem", False)
    enemyForcedBothEmblem = sectionMain.readBool("enemy/forcedBothEmblem", False)
    print("Loaded values @replaceOwnCustomization: {} {} {}".format(playerForcedEmblem, allyForcedEmblem, enemyForcedEmblem))
    
    BigWorld.forcedCustomizationDict.update(playerForcedEmblem=playerForcedEmblem, allyForcedEmblem=allyForcedEmblem, enemyForcedEmblem=enemyForcedEmblem,
                                            playerForcedBothEmblem=playerForcedBothEmblem, allyForcedBothEmblem=allyForcedBothEmblem, enemyForcedBothEmblem=enemyForcedBothEmblem)

# keep a reference to work with UML GUI
BigWorld.forcedCustomizationDict["UML_reload_func"] = loadSettingFromOMConfig

def loadSettingFromText(textPath="forcedEmblem.txt"):
    with io.open(personalDecalPath, "r") as df:
        lines = [l.strip() for l in df.readlines()]
        playerForcedEmblem, allyForcedEmblem, enemyForcedEmblem = [tryLoadIntValue(None, None, stringValue=l, tupleSizeCheck=2) for l in lines[:3]]
        playerForcedBothEmblem, allyForcedBothEmblem, enemyForcedBothEmblem = [v.strip().lower() in ["enable", "enabled", "true"] for v in lines[3:]]
    
    BigWorld.forcedCustomizationDict.update(playerForcedEmblem=playerForcedEmblem, allyForcedEmblem=allyForcedEmblem, enemyForcedEmblem=enemyForcedEmblem,
                                            playerForcedBothEmblem=playerForcedBothEmblem, allyForcedBothEmblem=allyForcedBothEmblem, enemyForcedBothEmblem=enemyForcedBothEmblem)

TYPE_SELF, TYPE_ALLY, TYPE_ENEMY = "self", "ally", "enemy"
TYPE_LOOKUP = {TYPE_SELF: "playerForcedEmblem", TYPE_ALLY: "allyForcedEmblem", TYPE_ENEMY: "enemyForcedEmblem"}
FORCED_BOTH_LOOKUP = {TYPE_SELF: "playerForcedBothEmblem", TYPE_ALLY: "allyForcedBothEmblem", TYPE_ENEMY: "enemyForcedBothEmblem"}
def tryGetDecal(vehicleType, ownModelPath="scripts/client/mods/ownModel.xml", personalDecalPath="forcedEmblem.txt"):
    """Attempt to load and get decal index either OM or a set file."""
    decalIndexName = TYPE_LOOKUP[vehicleType]
    if decalIndexName not in BigWorld.forcedCustomizationDict:
        # unloaded (these fields always have value after loads)
        if hasattr(BigWorld, "om"): # load from UML config
            loadSettingFromOMConfig(ownModelPath=ownModelPath)
        elif(os.path.isfile(personalDecalPath)):
            loadSettingFromText(textPath=personalDecalPath)
        else:
            print("Warning @replaceOwnCustomization: Neither UML nor text config(searched at {:s}) detected. The mod will do nothing.".format(personalDecalPath))
            BigWorld.forcedCustomizationDict.update(playerForcedEmblem=None, allyForcedEmblem=None, enemyForcedEmblem=None,
                                            playerForcedBothEmblem=False, allyForcedBothEmblem=False, enemyForcedBothEmblem=False)
    # after load, this always return values
    return BigWorld.forcedCustomizationDict[decalIndexName]


old_prepareBattleOutfit = camouflages.prepareBattleOutfit
def new_prepareBattleOutfit(outfitCD, vehicleDescriptor, vehicleId):
    vehicleCD = vehicleDescriptor.makeCompactDescr()
    player = BigWorld.player()
    outfitComponent = camouflages.getOutfitComponent(outfitCD, vehicleDescriptor)
    # INJECTION HERE
    # vehicle type
    if BigWorld.player().playerVehicleID == vehicleId:
        vehicleType = TYPE_SELF # is own vehicle
    elif(BigWorld.player().team == BigWorld.player().arena.vehicles.get(vehicleId, {}).get('team', 1)): 
        vehicleType = TYPE_ALLY # is allied vehicle
    else:
        vehicleType = TYPE_ENEMY # is enemy vehicle
    # override (in battle only; when the decal value is not None or 0)
    if tryGetDecal(vehicleType):
        if(BigWorld.forcedCustomizationDict[FORCED_BOTH_LOOKUP[vehicleType]] and len(outfitComponent.decals) < 2):
            # add in turret regions. They don't need to have values, since the ids are overwritten anyway
            if(len(outfitComponent.decals) == 0):
                outfitComponent.decals.append(DecalComponent(id=-1, appliedTo=ApplyArea.TURRET))
            outfitComponent.decals.append(DecalComponent(id=-1, appliedTo=ApplyArea.TURRET_1))
        decal_idx = tryGetDecal(vehicleType)
        if(isinstance(decal_idx, tuple)):
            # replace both using matching. # TODO account for disabled (-1)
            for decal_item, new_idx in zip(outfitComponent.decals, decal_idx):
                if(new_idx != 0): # ignore zero
                    decal_item.id = new_idx
        else:
            # replace both using one # TODO account for disabled (-1)
            for decal_item in outfitComponent.decals:
                decal_item.id = decal_idx
    # INJECTION FINISHED
    outfit = Outfit(component=outfitComponent, vehicleCD=vehicleCD)
    forceHistorical = player.playerVehicleID != vehicleId and player.customizationDisplayType < outfit.customizationDisplayType()
    if outfit.style and (outfit.style.isProgression or camouflages.IS_EDITOR):
        progressionOutfit = camouflages.getStyleProgressionOutfit(outfit, toLevel=outfit.progressionLevel)
        if progressionOutfit is not None:
            outfit = progressionOutfit
    return outfit
camouflages.prepareBattleOutfit = new_prepareBattleOutfit


# No longer used (prototype concept test)
"""def tryGetPersonalDecal(ownModelPath="scripts/client/mods/ownModel.xml", personalDecalPath="forcedEmblem.txt"):
    #Attempt to get personal decal from either OM or a set file.
    if(hasattr(BigWorld, "om")):
        if(hasattr(BigWorld.om, "forcedEmblem")):
            personal_emblem_idx = BigWorld.om.forcedEmblem
        else:
            sectionMain = ResMgr.openSection(ownModelPath)
            personal_emblem_idx = BigWorld.om.forcedEmblem = sectionMain.readInt("forcedEmblem", -1)
            if(personal_emblem_idx == -1): # cant use none, whatthehell
                BigWorld.om.forcedEmblem = None
    elif(BigWorld.forcedEmblem or os.path.isfile(personalDecalPath)):
        if(BigWorld.forcedEmblem == -1):
            # this is when we read an invalid index as an emblem; we do not reopen the file
            personal_emblem_idx = None
        elif(BigWorld.forcedEmblem is None):
            # this is when the emblem is uninitiated; we open the file and record the value
            with io.open(personalDecalPath, "r") as df:
                try:
                    BigWorld.forcedEmblem = personal_emblem_idx = int(df.read().strip())
                except ValueError:
                    BigWorld.forcedEmblem = -1
        else:
            personal_emblem_idx = BigWorld.forcedEmblem
    else:
        personal_emblem_idx = None
    # TODO add emblem idx check (if invalid, set the values to None). Set here or the respective reads.
    return personal_emblem_idx

@override(CompoundAppearance, '_prepareOutfit')
def _prepareOutfit(baseMethod, baseInstance, outfitCD):
    print("[Injector] _prepareOutfit called")
    global injector_LastOutfitCD
    global injector_LastCompoundAppearance
    injector_LastCompoundAppearance = baseInstance
    injector_LastOutfitCD = outfitCD
    return baseMethod(baseInstance, outfitCD)
"""
# print("Override attempt done @injectFunction")