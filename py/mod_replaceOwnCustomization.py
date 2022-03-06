import types
from vehicle_systems.CompoundAppearance import CompoundAppearance
from vehicle_systems import camouflages
from items.customizations import CustomizationOutfit, createNationalEmblemComponents, CamouflageComponent, PaintComponent, DecalComponent, PersonalNumberComponent
from items.components.c11n_constants import ApplyArea, SeasonType, CUSTOMIZATION_SLOTS_VEHICLE_PARTS, SLOT_TYPE_NAMES
from items.components.c11n_components import getAvailableDecalRegions
from vehicle_outfit.outfit import Outfit
from items import vehicles
from gui.hangar_vehicle_appearance import HangarVehicleAppearance
import BigWorld
import ResMgr
from debug_utils import LOG_WARNING, LOG_ERROR

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

def tryLoadStrList(section, valueName):
    """Load value; return None if not exist/blank; split by , if found."""
    value = section.readString(valueName, "").strip()
    if("," in value):
        # list of value, split, strip and sanitize
        listval = [v.strip() for v in value.split(",")]
        validval = [v for v in listval if v]
        if len(validval) == 0: # in the event of no valid fields
            return None
        return validval
    else:
        if value.strip(): # only return valid values as a single item list
            return [value.strip()]
        return None
        
RANDOMIZE = -999
HASH = -239
def tryLoadPersonalNumber(section, valueName):
    """Load value; return None if not exist/blank.
    Can be a single number; `random` to randomize; `hash` to pseudo-randomize using hash. TODO add customized by format e.g 3-random-random will generate 300 to 399
    """
    value = section.readString(valueName, "").strip()
    if(not value):
        return None
    elif(value.lower() == "random"):
        return RANDOMIZE
    elif(value.lower() == "hash"):
        return HASH
    else:
        try:
            value = int(value)
            return value if value > 0 else -value # should I raise more error?
        except ValueError:
            LOG_ERROR("Read value {:s} from valueName {:s} @tryLoadPersonalNumber not convertable to int.".format(value, valueName))
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
    # ignore by default or bound to UML's affectHangar
    return getattr(getattr(BigWorld, "om", None), "affectHangar", False)
        
        
preset_personal_number =  vehicles.g_cache.customization20().personal_numbers[1]
        
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
    # fields: OM.player.whitelist or .blacklist (str), list of vehicle wildcards separated by `,`
    playerBlacklist, playerWhitelist = tryLoadStrList(sectionMain, "player/blacklist"), tryLoadStrList(sectionMain, "player/whitelist")
    allyBlacklist, allyWhitelist = tryLoadStrList(sectionMain, "ally/blacklist"), tryLoadStrList(sectionMain, "ally/whitelist")
    enemyBlacklist, enemyWhitelist = tryLoadStrList(sectionMain, "enemy/blacklist"), tryLoadStrList(sectionMain, "enemy/whitelist")
    # field: OM.player.personalNumberID and OM.player.personalNumber
    playerPersonalNumberID = tryLoadIntValue(sectionMain, "player/personalNumberID")
    playerPersonalNumber = tryLoadPersonalNumber(sectionMain, "player/personalNumber")
    
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
    BigWorld.forcedCustomizationDict.update(playerBlacklist=playerBlacklist, playerWhitelist=playerWhitelist, 
                                            allyBlacklist=allyBlacklist, allyWhitelist=allyWhitelist, 
                                            enemyBlacklist=enemyBlacklist, enemyWhitelist=enemyWhitelist,
                                            playerPersonalNumberID=playerPersonalNumberID, playerPersonalNumber=playerPersonalNumber
                                           )

# keep a reference to work with UML GUI
BigWorld.forcedCustomizationDict["UML_reload_func"] = loadSettingFromOMConfig

def loadSettingFromText(textPath="forcedEmblem.txt"):
    with io.open(textPath, "r") as df:
        try:
            """lines = [l.strip() for l in df.readlines()]
            playerForcedEmblem, allyForcedEmblem, enemyForcedEmblem = [tryLoadIntValue(None, None, stringValue=l, tupleSizeCheck=2) for l in lines[:3]]
            playerForcedBothEmblem, allyForcedBothEmblem, enemyForcedBothEmblem = [v.strip().lower() in ["enable", "enabled", "true"] for v in lines[3:6]]
            playerForcedCamo, allyForcedCamo, enemyForcedCamo = [tryLoadIntValue(None, None, stringValue=l, tupleSizeCheck=3) for l in lines[6:9]]
            playerForcedPaint, allyForcedPaint, enemyForcedPaint = [tryLoadIntValue(None, None, stringValue=l, tupleSizeCheck=3) for l in lines[9:12]]"""
            data = json.load(df)
        except JSONDecodeError as e:
            print("Failed parsing json data: Error: {}".format(e))
            return
    # values needed to be popped instead of straight updating, as they need to be rechecked with g_cache
    playerForcedEmblem, allyForcedEmblem, enemyForcedEmblem = data.pop("forcedEmblem", (None, None, None))
    playerForcedCamo, allyForcedCamo, enemyForcedCamo = data.pop("forcedCamo", (None, None, None))
    playerForcedPaint, allyForcedPaint, enemyForcedPaint = data.pop("forcedPaint", (None, None, None))
    
    playerForcedBothEmblem, allyForcedBothEmblem, enemyForcedBothEmblem = data.pop("forcedBothEmblem", (False, False, False))
    
    # check every values with corresponding cache
    emblemSet = playerForcedEmblem, allyForcedEmblem, enemyForcedEmblem = [checkCustomizationID(v, vehicles.g_cache.customization20().decals.keys()) for v in (playerForcedEmblem, allyForcedEmblem, enemyForcedEmblem) ]
    camoSet = playerForcedCamo, allyForcedCamo, enemyForcedCamo = [checkCustomizationID(v, vehicles.g_cache.customization20().camouflages.keys()) for v in (playerForcedCamo, allyForcedCamo, enemyForcedCamo) ]
    paintSet = playerForcedPaint, allyForcedPaint, enemyForcedPaint = [checkCustomizationID(v, vehicles.g_cache.customization20().paints.keys()) for v in (playerForcedPaint, allyForcedPaint, enemyForcedPaint) ]
    print("Loaded values @replaceOwnCustomization [JSON]: {} {} {}".format(emblemSet, camoSet, paintSet))
    
    BigWorld.forcedCustomizationDict.update(playerForcedEmblem=playerForcedEmblem, allyForcedEmblem=allyForcedEmblem, enemyForcedEmblem=enemyForcedEmblem,
                                            playerForcedBothEmblem=playerForcedBothEmblem, allyForcedBothEmblem=allyForcedBothEmblem, enemyForcedBothEmblem=enemyForcedBothEmblem,
                                            playerForcedCamo=playerForcedCamo, allyForcedCamo=allyForcedCamo, enemyForcedCamo=enemyForcedCamo,
                                            playerForcedPaint=playerForcedPaint, allyForcedPaint=allyForcedPaint, enemyForcedPaint=enemyForcedPaint
                                            **data) # the rest of json data is read directly

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

BLACKLIST_LOOKUP = {TYPE_SELF: "playerBlacklist", TYPE_ALLY: "allyBlacklist", TYPE_ENEMY: "enemyBlacklist"}
WHITELIST_LOOKUP = {TYPE_SELF: "playerWhitelist", TYPE_ALLY: "allyWhitelist", TYPE_ENEMY: "enemyWhitelist"}
def checkList(vehicleType, vehicleDescriptor):
    vehicleName = vehicleDescriptor.type.name
    if(BigWorld.forcedCustomizationDict.get(WHITELIST_LOOKUP[vehicleType], None)): # WHITELIST TAKE PRECEDENCE
        # check if vehicle is in whitelist
        whitelist = BigWorld.forcedCustomizationDict[WHITELIST_LOOKUP[vehicleType]]
        # print("Found whitelist: {}; searching for {}".format(whitelist, vehicleName))
        return any(wtn in vehicleName for wtn in whitelist)
    elif(BigWorld.forcedCustomizationDict.get(BLACKLIST_LOOKUP[vehicleType], None)):
        # check if vehicle not in blacklist
        blacklist = BigWorld.forcedCustomizationDict[BLACKLIST_LOOKUP[vehicleType]]
        # print("Found blacklist: {}; searching for {}".format(blacklist, vehicleName))
        return not any(wtn in vehicleName for wtn in blacklist)
    else:
        # default to every vehicle.
        return True

def decomposeApplyAreaRegion(combinedRegionValue, regionList=ApplyArea.RANGE):
    # Because WoT already forced emblems and inscriptions to separate regions; it use appliedTo on this combined value (e.g TURRET & TURRET_1 is 512 + 256)
    # we can simply AND (&) every individual positions. Can feed a regionList if we KNOW what component it is.
    # print("Debug @decomposeApplyAreaRegion: ", combinedRegionValue, regionList)
    return [r for r in regionList if r & combinedRegionValue]

def modifyOutfitComponent(outfitComponent, outfitCD=None, vehicleDescriptor=None, vehicleId=None):
    # INJECTION HERE
    if(not outfitCD and not BigWorld.forcedCustomizationDict.get("overrideEmptyOutfit", False)):
        return outfitComponent # if the value is default (e.g dead vehicles), do not modify
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
    #try:
    #    print("Vehicle type {:s} with name {:s}".format(vehicleType, vehicleDescriptor.type.name))
    #except Exception as e:
    #    print("Error @replaceOwnCustomization: " + str(e))
    if not checkList(vehicleType, vehicleDescriptor):
        # when False, either not in whitelist or in blacklist, do not modify
        return outfitComponent
    # override decals (in battle only; when the decal value is not None or 0)
    # decal could be inscriptions or emblem; only replace the latter by locating their corresponding regions
    if tryGetDecal(vehicleType):
        emblem_regions_val, inscription_regions_val = getAvailableDecalRegions(vehicleDescriptor)
        existing_emblems = [emb for emb in outfitComponent.decals if emb.appliedTo & emblem_regions_val]
        replacing_emblems = existing_emblems # [ DecalComponent(id=e.id, appliedTo=reg) for e in existing_emblems for reg in decomposeApplyAreaRegion(e.appliedTo, ApplyArea.EMBLEM_REGIONS) ]
        original_decals = list(outfitComponent.decals)
        # print("Debug @replaceOwnCustomization: existing emblem regions {}, replacing emblem regions {}".format(existing_emblems, replacing_emblems))
        current_emblem_val = sum(emb.appliedTo for emb in existing_emblems)
        if(emblem_regions_val < current_emblem_val):
            # this shouldn't happen; log it when it does
            print("Error @replaceOwnCustomization: current emblem encompassing regions {}; while possible emblems encompass {}".format(current_emblem_val, emblem_region_val))
        elif(BigWorld.forcedCustomizationDict[FORCED_BOTH_LOOKUP[vehicleType]] and emblem_regions_val > current_emblem_val):
            # when this two values are mismatched, creating new DecalComponent to house needed emblems
            added_emblems = [DecalComponent(id=-1, appliedTo=reg) for reg in decomposeApplyAreaRegion(emblem_regions_val - current_emblem_val, ApplyArea.EMBLEM_REGIONS)]
            # outfitComponent.decals.extend(added_emblems)
            replacing_emblems.extend(added_emblems)
        decal_idx = tryGetDecal(vehicleType)
        if(isinstance(decal_idx, tuple)):
            # replace both using matching.
            for decal_item, new_idx in zip(replacing_emblems, decal_idx):
                if(new_idx != 0): # ignore zero
                    decal_item.id = new_idx
        else:
            # replace both using one
            for decal_item in replacing_emblems:
                decal_item.id = decal_idx
        # remove existing, add the replaced version. Note: this isn't needed for several versions already
        # del [d for d in outfitComponent.decals if d in existing_emblems][:]
        # outfitComponent.decals.extend(replacing_emblems)
        # remove nonpositive ids (for -1, but can also deal with errant -2)
        del [d for d in outfitComponent.decals if d.id <= 0][:]
        print("Debug @replaceOwnCustomization: before modifications {}, after modification {}".format(original_decals, outfitComponent.decals))
    # override camo (also in battle only)
    if getCamoOrPaint(vehicleType, type_dict=CAMO_TYPE_LOOKUP):
        camo_idx = getCamoOrPaint(vehicleType, type_dict=CAMO_TYPE_LOOKUP)
        if(camo_idx != 0): # only keep on replace
            del outfitComponent.camouflages[:]
        if(camo_idx > 0): # -1 will disable camo
            outfitComponent.camouflages.extend([CamouflageComponent(id=camo_idx, appliedTo=area) for area in (ApplyArea.HULL, ApplyArea.TURRET, ApplyArea.GUN)])
    # override paint (also in battle only)
    if getCamoOrPaint(vehicleType, type_dict=PAINT_TYPE_LOOKUP):
        paint_idx = getCamoOrPaint(vehicleType, type_dict=PAINT_TYPE_LOOKUP)
        if(paint_idx != 0): # only keep on replace
            del outfitComponent.paints[:]
        if(paint_idx > 0): # -1 will disable paint
            outfitComponent.paints.extend([PaintComponent(id=paint_idx, appliedTo=area) for area in (ApplyArea.HULL, ApplyArea.TURRET, ApplyArea.GUN)])
        
    if(vehicleType == TYPE_SELF and BigWorld.forcedCustomizationDict.get("playerPersonalNumberID", None)):
        # Experimental: attempt to add number components to all self's vehicles on valid slots
        emblem_regions_val, inscription_regions_val = getAvailableDecalRegions(vehicleDescriptor)
        current_inscription_val = sum(ins.appliedTo for ins in outfitComponent.decals if ins.appliedTo & inscription_regions_val)
        available_inscription_slots = set(decomposeApplyAreaRegion(inscription_regions_val, ApplyArea.INSCRIPTION_REGIONS)) - set(decomposeApplyAreaRegion(current_inscription_val, ApplyArea.INSCRIPTION_REGIONS))
        print("Debug @replaceOwnCustomization: available inscriptions: {} {} - {}".format(available_inscription_slots, inscription_regions_val, current_inscription_val))
        if(len(available_inscription_slots) == 0):
            print("Debug @replaceOwnCustomization: No available slot to add personal number. Ignoring the positions")
        else:
            personal_numbers_id = BigWorld.forcedCustomizationDict["playerPersonalNumberID"]
            personal_number_value = BigWorld.forcedCustomizationDict["playerPersonalNumber"]
            if(personal_number_value == RANDOMIZE):
                numberval = random.randint(1000) # random mode, picking a random value.
            elif(personal_number_value == HASH): 
                numberval = (id(vehicleDescriptor) * id(ApplyArea) + id(BigWorld)) % 1000 # hash mode; TODO try something more randomized?
            else:
                numberval = personal_number_value % 1000
            numberstr = "{:03d}".format(numberval) # include leading zeros if needed. TODO enforce digit version?
            outfitComponent.personal_numbers.append( PersonalNumberComponent(id=personal_numbers_id, number=numberstr, appliedTo=list(available_inscription_slots)[0]) )
    # INJECTION FINISHED
    return outfitComponent

old_prepareBattleOutfit = camouflages.prepareBattleOutfit
def new_prepareBattleOutfit(outfitCD, vehicleDescriptor, vehicleId):
    outfit = old_prepareBattleOutfit(outfitCD, vehicleDescriptor, vehicleId)
    outfit_new_components = modifyOutfitComponent(outfit.pack(), outfitCD=outfitCD, vehicleDescriptor=vehicleDescriptor, vehicleId=vehicleId)
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


        for partName in CUSTOMIZATION_SLOTS_VEHICLE_PARTS:
            list_positions = getattr(vehicleDescriptor, partName).emblemSlots 
            available_positions = [slot for slot in list_positions if slot.type == SLOT_TYPE_NAMES.INSCRIPTION]
            if len(available_positions) > 0:
                print("Debug @replaceOwnCustomization: partName {:s} has {:d} available slots for personal number.".format(partName, len(available_positions)))
            #print("Debug @replaceOwnCustomization: all slots {}".format( [slot.type for slot in list_positions]))
        print("Debug for application positions: {}".format([(c.id, c.number, c.appliedTo) for c in outfitComponent.personal_numbers]))
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