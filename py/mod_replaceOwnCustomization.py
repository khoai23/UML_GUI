import types
from vehicle_systems.CompoundAppearance import CompoundAppearance
from vehicle_systems import camouflages
from items.customizations import CustomizationOutfit, CamouflageComponent, PaintComponent, DecalComponent
from items.components.c11n_constants import ApplyArea, SeasonType
from vehicle_outfit.outfit import Outfit
from items import vehicles
from gui.hangar_vehicle_appearance import HangarVehicleAppearance
import BigWorld
import ResMgr

import os, io
import random
import json

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

        
def checkCustomizationID(id, customization_sets):
    # sets should be from vehicle_cache objs
    if(isinstance(id, int)):
        return id if any(cst == id for cst in customization_sets) else 0
    elif(isinstance(id, (tuple, list))):
        return tuple([checkCustomizationID(subid, customization_sets) for subid in id])
    elif(id in [None, 0, -1]): # special values
        return id
    else:
        raise ValueError("Invalid input type: {} {}".format(id, type(id)))
        
def applyInHangar():
    # ignore by default or binded to UML's affectHangar
    return getattr(getattr(BigWorld, "om", None), "affectHangar", False)
        
def loadSettingFromOMConfig(ownModelPath="scripts/client/mods/ownModel.xml"):
    """Update fields in OM file to forcedCustomizationDict"""
    sectionMain = ResMgr.openSection(ownModelPath)
    # fields: OM.player.forcedEmblem (int or (int, int)), maximum override both emblems sequentially
    playerForcedEmblem = tryLoadIntValue(sectionMain, "player/forcedEmblem", tupleSizeCheck=2)
    allyForcedEmblem = tryLoadIntValue(sectionMain, "ally/forcedEmblem", tupleSizeCheck=2)
    enemyForcedEmblem = tryLoadIntValue(sectionMain, "enemy/forcedEmblem", tupleSizeCheck=2)
    # if set, force to display 2nd emblem regardless of original data
    playerForcedBothEmblem = sectionMain.readBool("player/forcedBothEmblem", False)
    allyForcedBothEmblem = sectionMain.readBool("ally/forcedBothEmblem", False)
    enemyForcedBothEmblem = sectionMain.readBool("enemy/forcedBothEmblem", False)
    # fields: OM.player.forcedCamo (int or (int, int, int)), either one camo for all or (summer, winter, desert)
    playerForcedCamo = tryLoadIntValue(sectionMain, "player/forcedCamo", tupleSizeCheck=3)
    allyForcedCamo = tryLoadIntValue(sectionMain, "ally/forcedCamo", tupleSizeCheck=3)
    enemyForcedCamo = tryLoadIntValue(sectionMain, "enemy/forcedCamo", tupleSizeCheck=3)
    # fields: OM.player.forcedPaint (int or (int, int, int)), either one camo for all or (summer, winter, desert)
    playerForcedPaint = tryLoadIntValue(sectionMain, "player/forcedPaint", tupleSizeCheck=3)
    allyForcedPaint = tryLoadIntValue(sectionMain, "ally/forcedPaint", tupleSizeCheck=3)
    enemyForcedPaint = tryLoadIntValue(sectionMain, "enemy/forcedPaint", tupleSizeCheck=3)
    
    # check every values with corresponding cache
    emblemSet = playerForcedEmblem, allyForcedEmblem, enemyForcedEmblem = [checkCustomizationID(v, vehicles.g_cache.customization20().decals.keys()) for v in (playerForcedEmblem, allyForcedEmblem, enemyForcedEmblem) ]
    camoSet = playerForcedCamo, allyForcedCamo, enemyForcedCamo = [checkCustomizationID(v, vehicles.g_cache.customization20().camouflages.keys()) for v in (playerForcedCamo, allyForcedCamo, enemyForcedCamo) ]
    paintSet = playerForcedPaint, allyForcedPaint, enemyForcedPaint = [checkCustomizationID(v, vehicles.g_cache.customization20().paints.keys()) for v in (playerForcedPaint, allyForcedPaint, enemyForcedPaint) ]
    print("Loaded values @replaceOwnCustomization [XML]: {} {} {}".format(emblemSet, camoSet, paintSet))
    
    BigWorld.forcedCustomizationDict.update(playerForcedEmblem=playerForcedEmblem, allyForcedEmblem=allyForcedEmblem, enemyForcedEmblem=enemyForcedEmblem,
                                            playerForcedBothEmblem=playerForcedBothEmblem, allyForcedBothEmblem=allyForcedBothEmblem, enemyForcedBothEmblem=enemyForcedBothEmblem,
                                            playerForcedCamo=playerForcedCamo, allyForcedCamo=allyForcedCamo, enemyForcedCamo=enemyForcedCamo,
                                            playerForcedPaint=playerForcedPaint, allyForcedPaint=allyForcedPaint, enemyForcedPaint=enemyForcedPaint
                                           )

# keep a reference to work with UML GUI
BigWorld.forcedCustomizationDict["UML_reload_func"] = loadSettingFromOMConfig

def loadSettingFromText(textPath="forcedEmblem.txt"):
    with io.open(personalDecalPath, "r") as df:
        try:
            """lines = [l.strip() for l in df.readlines()]
            playerForcedEmblem, allyForcedEmblem, enemyForcedEmblem = [tryLoadIntValue(None, None, stringValue=l, tupleSizeCheck=2) for l in lines[:3]]
            playerForcedBothEmblem, allyForcedBothEmblem, enemyForcedBothEmblem = [v.strip().lower() in ["enable", "enabled", "true"] for v in lines[3:6]]
            playerForcedCamo, allyForcedCamo, enemyForcedCamo = [tryLoadIntValue(None, None, stringValue=l, tupleSizeCheck=3) for l in lines[6:9]]
            playerForcedPaint, allyForcedPaint, enemyForcedPaint = [tryLoadIntValue(None, None, stringValue=l, tupleSizeCheck=3) for l in lines[9:12]]"""
            data = json.load(df)
        except JSONDecodeError as e:
            print("Failed parsing json data: Error: {}".format(e))
        playerForcedEmblem, allyForcedEmblem, enemyForcedEmblem = data.get("forcedEmblem", (None, None, None))
        playerForcedBothEmblem, allyForcedBothEmblem, enemyForcedBothEmblem = data.get("forcedBothEmblem", (False, False, False))
        playerForcedCamo, allyForcedCamo, enemyForcedCamo = data.get("forcedCamo", (None, None, None))
        playerForcedPaint, allyForcedPaint, enemyForcedPaint = data.get("forcedPaint", (None, None, None))
    
    # check every values with corresponding cache
    emblemSet = playerForcedEmblem, allyForcedEmblem, enemyForcedEmblem = [checkCustomizationID(v, vehicles.g_cache.customization20().decals.keys()) for v in (playerForcedEmblem, allyForcedEmblem, enemyForcedEmblem) ]
    camoSet = playerForcedCamo, allyForcedCamo, enemyForcedCamo = [checkCustomizationID(v, vehicles.g_cache.customization20().camouflages.keys()) for v in (playerForcedCamo, allyForcedCamo, enemyForcedCamo) ]
    paintSet = playerForcedPaint, allyForcedPaint, enemyForcedPaint = [checkCustomizationID(v, vehicles.g_cache.customization20().paints.keys()) for v in (playerForcedPaint, allyForcedPaint, enemyForcedPaint) ]
    print("Loaded values @replaceOwnCustomization [JSON]: {} {} {}".format(emblemSet, camoSet, paintSet))
    
    BigWorld.forcedCustomizationDict.update(playerForcedEmblem=playerForcedEmblem, allyForcedEmblem=allyForcedEmblem, enemyForcedEmblem=enemyForcedEmblem,
                                            playerForcedBothEmblem=playerForcedBothEmblem, allyForcedBothEmblem=allyForcedBothEmblem, enemyForcedBothEmblem=enemyForcedBothEmblem,
                                            playerForcedCamo=playerForcedCamo, allyForcedCamo=allyForcedCamo, enemyForcedCamo=enemyForcedCamo,
                                            playerForcedPaint=playerForcedPaint, allyForcedPaint=allyForcedPaint, enemyForcedPaint=enemyForcedPaint
                                           )

TYPE_SELF, TYPE_ALLY, TYPE_ENEMY = "self", "ally", "enemy"
DECAL_TYPE_LOOKUP = {TYPE_SELF: "playerForcedEmblem", TYPE_ALLY: "allyForcedEmblem", TYPE_ENEMY: "enemyForcedEmblem"}
FORCED_BOTH_LOOKUP = {TYPE_SELF: "playerForcedBothEmblem", TYPE_ALLY: "allyForcedBothEmblem", TYPE_ENEMY: "enemyForcedBothEmblem"}
def tryGetDecal(vehicleType, ownModelPath="scripts/client/mods/ownModel.xml", personalConfigPath="mods/configs/replaceOwnCustomization.json"):
    """Attempt to load and get decal index either OM or a set file."""
    decalIndexName = DECAL_TYPE_LOOKUP[vehicleType]
    if decalIndexName not in BigWorld.forcedCustomizationDict:
        # unloaded (these fields always have value after loads)
        if hasattr(BigWorld, "om"): # load from UML config
            loadSettingFromOMConfig(ownModelPath=ownModelPath)
        elif(os.path.isfile(personalConfigPath)):
            loadSettingFromText(textPath=personalConfigPath)
        else:
            print("Warning @replaceOwnCustomization: Neither UML nor text config(searched at {:s}) detected. The mod will do nothing.".format(personalConfigPath))
            BigWorld.forcedCustomizationDict.update(playerForcedEmblem=None, allyForcedEmblem=None, enemyForcedEmblem=None,
                                            playerForcedBothEmblem=False, allyForcedBothEmblem=False, enemyForcedBothEmblem=False,
                                            playerForcedCamo=None, allyForcedCamo=None, enemyForcedCamo=None,
                                            playerForcedPaint=None, allyForcedPaint=None, enemyForcedPaint=None
                                                    )
    # after load, this always return values
    return BigWorld.forcedCustomizationDict[decalIndexName]

CAMO_TYPE_LOOKUP = {TYPE_SELF: "playerForcedCamo", TYPE_ALLY: "allyForcedCamo", TYPE_ENEMY: "enemyForcedCamo"}
PAINT_TYPE_LOOKUP = {TYPE_SELF: "playerForcedPaint", TYPE_ALLY: "allyForcedPaint", TYPE_ENEMY: "enemyForcedPaint"}
WEATHER_LOOKUP = {SeasonType.SUMMER: 0, SeasonType.WINTER: 1, SeasonType.DESERT: 2}
def getCamoOrPaint(vehicleType, type_dict=CAMO_TYPE_LOOKUP, returnRandomSeason=True):
    # this is always AFTER tryGetDecal; hence no more needs to load any setting
    # if load camo, use CAMO_TYPE_LOOKUP; if load paint, use PAINT_TYPE_LOOKUP
    camo_idx = BigWorld.forcedCustomizationDict[type_dict[vehicleType]]
    if(camo_idx is None):
        return 0 # None is equal to 0
    elif(isinstance(camo_idx, int)):
        # single camo type for all, no need for any other check
        return camo_idx
    season = camouflages._currentMapSeason()
    if(season in WEATHER_LOOKUP.keys()):
        # found valid season, use correct camo type
        return camo_idx[WEATHER_LOOKUP[season]]
    else:
        # invalid season e.g Event; return a random season if flag is enabled; or 0 if disabled
        return camo_idx[random.randint(len(camo_idx))] if returnRandomSeason else 0

def modifyOutfitComponent(outfitComponent, vehicleId=None):
    # INJECTION HERE
    # vehicle type (player, ally, enemy) 
    if vehicleId is None:
        # vehicle call from __reload (hangar)
        vehicleType = TYPE_SELF
    if BigWorld.player().playerVehicleID == vehicleId:
        vehicleType = TYPE_SELF # is own vehicle (arena)
    elif(BigWorld.player().team == BigWorld.player().arena.vehicles.get(vehicleId, {}).get('team', 1)): 
        vehicleType = TYPE_ALLY # is allied vehicle (arena)
    else:
        vehicleType = TYPE_ENEMY # is enemy vehicle (arena)
    # override decals (in battle only; when the decal value is not None or 0)
    if tryGetDecal(vehicleType):
        if(BigWorld.forcedCustomizationDict[FORCED_BOTH_LOOKUP[vehicleType]] and len(outfitComponent.decals) < 2):
            # add in turret regions. They don't need to have values, since the ids are overwritten anyway
            if(len(outfitComponent.decals) == 0):
                outfitComponent.decals.append(DecalComponent(id=-1, appliedTo=ApplyArea.TURRET))
            outfitComponent.decals.append(DecalComponent(id=-1, appliedTo=ApplyArea.TURRET_1))
        decal_idx = tryGetDecal(vehicleType)
        if(isinstance(decal_idx, tuple)):
            # replace both using matching.
            for decal_item, new_idx in zip(outfitComponent.decals, decal_idx):
                if(new_idx != 0): # ignore zero
                    decal_item.id = new_idx
        else:
            # replace both using one
            for decal_item in outfitComponent.decals:
                decal_item.id = decal_idx
        # remove nonpositive ids (for -1, but can also deal with errant -2)
        del [d for d in outfitComponent.decals if d.id <= 0][:]
    # override camo (also in battle only)
    if getCamoOrPaint(vehicleType, type_dict=CAMO_TYPE_LOOKUP):
        camo_idx = getCamoOrPaint(vehicleType, type_dict=CAMO_TYPE_LOOKUP)
        del outfitComponent.camouflages[:]
        if(camo_idx > 0): # -1 will disable camo
            outfitComponent.camouflages.extend([CamouflageComponent(id=camo_idx, appliedTo=area) for area in (ApplyArea.HULL, ApplyArea.TURRET, ApplyArea.GUN)])
    # override paint (also in battle only)
    if getCamoOrPaint(vehicleType, type_dict=PAINT_TYPE_LOOKUP):
        paint_idx = getCamoOrPaint(vehicleType, type_dict=PAINT_TYPE_LOOKUP)
        del outfitComponent.paints[:]
        if(paint_idx > 0): # -1 will disable paint
            outfitComponent.paints.extend([PaintComponent(id=paint_idx, appliedTo=area) for area in (ApplyArea.HULL, ApplyArea.TURRET, ApplyArea.GUN)])
        
    # INJECTION FINISHED
    return outfitComponent

old_prepareBattleOutfit = camouflages.prepareBattleOutfit
def new_prepareBattleOutfit(outfitCD, vehicleDescriptor, vehicleId):
    outfit = old_prepareBattleOutfit(outfitCD, vehicleDescriptor, vehicleId)
    outfit_new_components = modifyOutfitComponent(outfit.pack(), vehicleId)
    return Outfit(component=outfit_new_components, vehicleCD=outfit.vehicleCD)
    
camouflages.prepareBattleOutfit = new_prepareBattleOutfit

"""old_reload_HangarVehicleAppearance = HangarVehicleAppearance.__reload
def new_reload_HangarVehicleAppearance(self, vDesc, vState, outfit):
    old_reload_HangarVehicleAppearance(self, vDesc, vState, outfit)
    if(applyInHangar()):
        # only run overriding outfit when flag is enabled
        outfit_new_components = modifyOutfitComponent(outfit.pack(), None)
        return Outfit(component=outfit_new_components, vehicleCD=outfit.vehicleCD)
# HangarVehicleAppearance.__reload = new_reload_HangarVehicleAppearance
"""

# No longer used (prototype concept test)
"""

old_prepareOutfit = CommonTankAppearance._prepareOutfit 
def new_prepareOutfit(self, outfitCD):
    outfitComponent = camouflages.getOutfitComponent(outfitCD)
    
    # INJECTION HERE
    if hasattr(BigWorld, "om") and not BigWorld.om.affectHangar:
        return outfit
    if BigWorld.forcedCustomizationDict["playerForcedEmblem"]:
        if BigWorld.forcedCustomizationDict["playerForcedBothEmblem"]:
            if len(outfit.decals) < 1:
                outfit.decals.append(DecalComponent(id=-1, appliedTo=ApplyArea.TURRET))
            outfit.decals.append(DecalComponent(id=-1, appliedTo=ApplyArea.TURRET_2))
        decal_idx = BigWorld.forcedCustomizationDict["playerForcedEmblem"]
        if(isinstance(decal_idx, tuple)):
        for new_idx, decal_item in zip(decal_idx, outfit.decals):
            decal_item.id = new_idx
        else:
            for decal_item in outfit.decals:
                decal_item.id = decal_idx
        # remove nonpositive ids
        del [d for d in outfit.decals if d.id <= 0]
    if BigWorld.forcedCustomizationDict["playerForcedCamo"]:
        camo_idx = BigWorld.forcedCustomizationDict["playerForcedCamo"]
        del outfit.camouflages[:]
        if(camo_idx > 0): # -1 is disabled
            outfit.camouflages.extend([CamouflageComponent(id=camo_idx, appliedTo=area) for area in (ApplyArea.GUN, ApplyArea.TURRET, ApplyArea.HULL)])
    if BigWorld.forcedCustomizationDict["playerForcedPaint"]:
        paint_idx = BigWorld.forcedCustomizationDict["playerForcedPaint"]
        del outfit.paints[:]
        if(paint_idx > 0): # -1 is disabled
            outfit.paints.extend([PaintComponent(id=paint_idx, appliedTo=area) for area in (ApplyArea.GUN, ApplyArea.TURRET, ApplyArea.HULL)])
    # INJECTION FINISHED
    
    return Outfit(component=outfitComponent, vehicleCD=self.typeDescriptor.makeCompactDescr())
CommonTankAppearance._prepareOutfit = new_prepareOutfit

def tryGetPersonalDecal(ownModelPath="scripts/client/mods/ownModel.xml", personalDecalPath="forcedEmblem.txt"):
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