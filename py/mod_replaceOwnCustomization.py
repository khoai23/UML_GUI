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
import re

TYPE_PLAYER, TYPE_ALLY, TYPE_ENEMY = "player", "ally", "enemy"
BigWorld.forcedCustomizationDict = getattr(BigWorld, "forcedCustomizationDict", dict())

PERSONAL_NUMBERS_DIGIT_COUNT = {idx : item.digitsCount for idx, item in vehicles.g_cache.customization20().personal_numbers.items()}
PERSONAL_NUMBERS_FORMAT = {2: "{:02d}", 3: "{:03d}"} # should only have these formats
WEATHER_LOOKUP = {SeasonType.SUMMER: 0, SeasonType.WINTER: 1, SeasonType.DESERT: 2}

def tryLoadIntValue(section, valueName, stringValue=None, tupleSizeCheck=None, default=None):
    """Try load tuple of int; if failed, load single int; if failed, return None
    Basically, either try to get `valueName` from section, or parse an independent string @ stringValue"""
    if(isinstance(stringValue, int)):
        return stringValue # if loaded in as int 
    elif(stringValue is None):
        stringValue = section.readString(valueName, "") # if needed to get from section
    if(stringValue == ""):
        return default
    try:
        if("," in stringValue):
            intTuple = list([int(v.strip()) for v in stringValue.split(",")])
            if(tupleSizeCheck and len(intTuple) != tupleSizeCheck):
                raise ValueError("Failed tuple size check: tuple`{}` original `{}` size`{}`".format(intTuple, stringValue, tupleSizeCheck))
            return intTuple
        else:
            return int(stringValue)
    except ValueError as e:
        print("Error @replaceOwnCustomization: can't convert value {} for int or int tuple of size {}. True error line: {}".format(stringValue, tupleSizeCheck, e))
        return 0
    return default

def tryLoadStrList(section, valueName, default=None):
    """Load value; return None if not exist/blank; split by , if found."""
    value = section.readString(valueName, "").strip()
    if("," in value):
        # list of value, split, strip and sanitize
        listval = [v.strip() for v in value.split(",")]
        validval = [v for v in listval if v]
        if len(validval) == 0: # in the event of no valid fields
            return default
        return validval
    else:
        if value.strip(): # only return valid values as a single item list
            return [value.strip()]
        return default
        
RANDOMIZE = -999
HASH = -239
def tryLoadPersonalNumber(section, valueName, default=None):
    """Load value; return None if not exist/blank.
    Can be a single number; `random` to randomize; `hash` to pseudo-randomize using hash. TODO add customized by format e.g 3-random-random will generate 300 to 399
    """
    value = section.readString(valueName, "").strip()
    if(not value):
        return default
    elif(value.lower() == "random"):
        return RANDOMIZE
    elif(value.lower() == "hash"):
        return HASH
    else:
        try:
            value = int(value)
            return value if value > 0 or value in (RANDOMIZE, HASH) else -value # should I raise more error?
        except ValueError:
            LOG_ERROR("Read value {:s} from valueName {:s} @tryLoadPersonalNumber not convertable to int.".format(value, valueName))
            return default


def checkCustomizationID(id, customization_sets):
    # sets should be from vehicle_cache objs
    if(isinstance(id, int)):
        return id if any(cst == id for cst in customization_sets) else 0
    elif(isinstance(id, (tuple, list))):
        return list([checkCustomizationID(subid, customization_sets) for subid in id])
    elif(id in [None, 0, -1]): # special values
        return id
    else:
        raise ValueError("Invalid input type: {} {}".format(id, type(id)))
        
def applyInHangar():
    # ignore by default or bound to UML's affectHangar, or bound to forcedCustomizationDict
    return BigWorld.forcedCustomizationDict.get(TYPE_PLAYER, dict()).get("affectHangar", getattr(getattr(BigWorld, "om", None), "affectHangar", False))
        
def printDebug(*args, **kwargs)
    # print only when UML's debug is enabled
    if getattr(getattr(BigWorld, "om", None), "debug", False):
        print(*args, **kwargs)
        
def retrieveSeason(): # return season. Adding the check since this is querried in hangar as well
    if hasattr(BigWorld.player(), "arena"):
        return camouflages._currentMapSeason()
    return None
    
def isBlank(value):
    # three types of blanks: None, "" and [] can be used for this.
    return value is None or (isinstance(value, (str, list, tuple)) and len(value) == 0)

re_validlist = re.compile(r"^[\w\d_\-,\s]+$")
def isValidList(lst):
    return all(re.match(re_validlist, value) is not None for value in lst)
    # blacklist/whitelist can only receive [\w\d_-] (char, digit, underscore and dash); split using comma and possibly space
   
# preset_personal_number =  vehicles.g_cache.customization20().personal_numbers[1]

#DECAL_TYPE_LOOKUP = {TYPE_PLAYER: "playerForcedEmblem", TYPE_ALLY: "allyForcedEmblem", TYPE_ENEMY: "enemyForcedEmblem"}
#FORCED_BOTH_LOOKUP = {TYPE_PLAYER: "playerForcedBothEmblem", TYPE_ALLY: "allyForcedBothEmblem", TYPE_ENEMY: "enemyForcedBothEmblem"}

def tryGetDecal(vehicleType):
    """Attempt to load and get decal index either OM or a set file."""
    decalIndexName = "forcedEmblem" # DECAL_TYPE_LOOKUP[vehicleType]
    # after load, this always return values
    return BigWorld.forcedCustomizationDict[vehicleType][decalIndexName]

# CAMO_TYPE_LOOKUP = {TYPE_PLAYER: "playerForcedCamo", TYPE_ALLY: "allyForcedCamo", TYPE_ENEMY: "enemyForcedCamo"}
# PAINT_TYPE_LOOKUP = {TYPE_PLAYER: "playerForcedPaint", TYPE_ALLY: "allyForcedPaint", TYPE_ENEMY: "enemyForcedPaint"}
def getCamoOrPaint(vehicleType, customization_name="forcedCamo", returnRandomSeason=True, consistentRandomIdx=None):
    # this is always AFTER tryGetDecal; hence no more needs to load any setting
    # if load camo, use CAMO_TYPE_LOOKUP; if load paint, use PAINT_TYPE_LOOKUP
    camo_idx = BigWorld.forcedCustomizationDict[vehicleType][customization_name]
    if(camo_idx is None):
        return 0 # None is equal to 0
    elif(isinstance(camo_idx, int)):
        # single camo type for all, no need for any other check
        return camo_idx
    season = retrieveSeason()
    if(season in WEATHER_LOOKUP.keys()):
        # found valid season, use correct camo type
        return camo_idx[WEATHER_LOOKUP[season]]
    else:
        # invalid season e.g Event; return a random season if flag is enabled; or 0 if disabled
        return camo_idx[consistentRandomIdx] if returnRandomSeason else 0

# BLACKLIST_LOOKUP = {TYPE_PLAYER: "playerBlacklist", TYPE_ALLY: "allyBlacklist", TYPE_ENEMY: "enemyBlacklist"}
# WHITELIST_LOOKUP = {TYPE_PLAYER: "playerWhitelist", TYPE_ALLY: "allyWhitelist", TYPE_ENEMY: "enemyWhitelist"}
def checkList(vehicleType, vehicleDescriptor):
    if vehicleType not in BigWorld.forcedCustomizationDict:
        # unloaded (these fields always have value after loads)
        if not ReplaceOwnCustomizationGUI.loadForcedCustomizationFromDisk():
            print("Warning @replaceOwnCustomization: Neither UML nor text config detected. The mod will do nothing.")
            BigWorld.forcedCustomizationDict = {
                TYPE_PLAYER: {"forcedEmblem": None, "forcedCamo": None, "forcedPaint": None, "forcedBothEmblem": None, "blacklist": None, "whitelist": None, "personalNumberID": None, "personalNumber": None},
                TYPE_ALLY: {"forcedEmblem": None, "forcedCamo": None, "forcedPaint": None, "forcedBothEmblem": None, "blacklist": None, "whitelist": None, "personalNumberID": None, "personalNumber": None},
                TYPE_ENEMY: {"forcedEmblem": None, "forcedCamo": None, "forcedPaint": None, "forcedBothEmblem": None, "blacklist": None, "whitelist": None, "personalNumberID": None, "personalNumber": None}
            }
    vehicleName = vehicleDescriptor.type.name
    if not isBlank(BigWorld.forcedCustomizationDict[vehicleType].get("whitelist", None)): # WHITELIST TAKE PRECEDENCE
        # check if vehicle is in whitelist
        whitelist = BigWorld.forcedCustomizationDict[vehicleType]["whitelist"]
        #print("Found whitelist: {}; searching for {}".format(whitelist, vehicleName))
        return any(wtn in vehicleName for wtn in whitelist)
    elif not isBlank(BigWorld.forcedCustomizationDict[vehicleType].get("blacklist", None)):
        # check if vehicle not in blacklist
        blacklist = BigWorld.forcedCustomizationDict[vehicleType]["blacklist"]
        #print("Found blacklist: {}; searching for {}".format(blacklist, vehicleName))
        return not any(wtn in vehicleName for wtn in blacklist)
    else:
        # default to every vehicle.
        return True

def decomposeApplyAreaRegion(combinedRegionValue, regionList=ApplyArea.RANGE):
    # Because WoT already forced emblems and inscriptions to separate regions; it use appliedTo on this combined value (e.g TURRET & TURRET_1 is 512 + 256)
    # we can simply AND (&) every individual positions. Can feed a regionList if we KNOW what component it is.
    # print("Debug @decomposeApplyAreaRegion: ", combinedRegionValue, regionList)
    if(combinedRegionValue <= 0):
        return []
    return [r for r in regionList if r & combinedRegionValue]

def modifyOutfitComponent(outfitComponent, outfitCD=None, vehicleDescriptor=None, vehicleId=None):
    # INJECTION HERE
    if(not outfitCD and not BigWorld.forcedCustomizationDict.get("overrideEmptyOutfit", False)):
        return outfitComponent # if the value is default (e.g dead vehicles), do not modify
    # vehicle type (player, ally, enemy) 
    if vehicleId is None:
        # vehicle call from __reload (hangar)
        vehicleType = TYPE_PLAYER
    elif BigWorld.player().playerVehicleID == vehicleId:
        vehicleType = TYPE_PLAYER # is own vehicle (arena)
    elif(BigWorld.player().team == BigWorld.player().arena.vehicles.get(vehicleId, {}).get('team', 1)): 
        vehicleType = TYPE_ALLY # is allied vehicle (arena)
    else:
        vehicleType = TYPE_ENEMY # is enemy vehicle (arena)
    #try:
    #    print("Vehicle type {:s} with name {:s}".format(vehicleType, vehicleDescriptor.type.name))
    #except Exception as e:
    #    print("Error @modifyOutfitComponent: " + str(e))
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
        # print("Debug @modifyOutfitComponent: existing emblem regions {}, replacing emblem regions {}".format(existing_emblems, replacing_emblems))
        current_emblem_val = sum(emb.appliedTo for emb in existing_emblems)
        if(emblem_regions_val < current_emblem_val):
            # this shouldn't happen; log it when it does
            print("[ROC] Error @modifyOutfitComponent: current emblem encompassing regions {}; while possible emblems encompass {}".format(current_emblem_val, emblem_region_val))
        elif(BigWorld.forcedCustomizationDict[vehicleType]["forcedBothEmblem"] and emblem_regions_val > current_emblem_val):
            # when this two values are mismatched, creating new DecalComponent to house needed emblems
            added_emblems = [DecalComponent(id=-1, appliedTo=reg) for reg in decomposeApplyAreaRegion(emblem_regions_val - current_emblem_val, ApplyArea.EMBLEM_REGIONS)]
            # outfitComponent.decals.extend(added_emblems)
            replacing_emblems.extend(added_emblems)
        decal_idx = tryGetDecal(vehicleType)
        if(isinstance(decal_idx, (tuple, list))):
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
        # print("Debug @modifyOutfitComponent: before modifications {}, after modification {}".format(original_decals, outfitComponent.decals))
    # override camo (also in battle only)
    consistentRandomIdx = random.randint(0, 12) % len(WEATHER_LOOKUP)
    if getCamoOrPaint(vehicleType, customization_name="forcedCamo", consistentRandomIdx=consistentRandomIdx):
        camo_idx = getCamoOrPaint(vehicleType, customization_name="forcedCamo", consistentRandomIdx=consistentRandomIdx)
        if(camo_idx != 0): # only keep on replace
            del outfitComponent.camouflages[:]
        if(camo_idx > 0): # -1 will disable camo
            outfitComponent.camouflages.extend([CamouflageComponent(id=camo_idx, appliedTo=area) for area in (ApplyArea.HULL, ApplyArea.TURRET, ApplyArea.GUN)])
    # override paint (also in battle only)
    if getCamoOrPaint(vehicleType, customization_name="forcedPaint", consistentRandomIdx=consistentRandomIdx):
        paint_idx = getCamoOrPaint(vehicleType, customization_name="forcedPaint", consistentRandomIdx=consistentRandomIdx)
        if(paint_idx != 0): # only keep on replace
            del outfitComponent.paints[:]
        if(paint_idx > 0): # -1 will disable paint
            outfitComponent.paints.extend([PaintComponent(id=paint_idx, appliedTo=area) for area in (ApplyArea.HULL, ApplyArea.TURRET, ApplyArea.GUN)])
        
    personal_numbers_id = BigWorld.forcedCustomizationDict[vehicleType].get("personalNumberID", None)
    if(personal_numbers_id and personal_numbers_id > 0):
        # Experimental: attempt to add number components to all concerning vehicles on valid slots
        emblem_regions_val, inscription_regions_val = getAvailableDecalRegions(vehicleDescriptor)
        current_inscription_val = sum(ins.appliedTo for ins in outfitComponent.decals if ins.appliedTo in ApplyArea.INSCRIPTION_REGIONS)
        available_inscription_slots = set(decomposeApplyAreaRegion(inscription_regions_val, ApplyArea.INSCRIPTION_REGIONS)) - set(decomposeApplyAreaRegion(current_inscription_val, ApplyArea.INSCRIPTION_REGIONS))
        printDebug("Debug @modifyOutfitComponent: available inscriptions: {} {} - {}".format(available_inscription_slots, inscription_regions_val, current_inscription_val))
        if(len(available_inscription_slots) == 0):
            print("[ROC] @modifyOutfitComponent: No available slot to add personal number. Ignoring the positions")
        else:
            personal_numbers_id = BigWorld.forcedCustomizationDict[vehicleType]["personalNumberID"]
            personal_number_value = BigWorld.forcedCustomizationDict[vehicleType]["personalNumber"]
            personal_number_digitcount = PERSONAL_NUMBERS_DIGIT_COUNT.get(personal_numbers_id, 3)
            MODULO = 10 ** personal_number_digitcount # enforce number format using modulo (100, 1000)
            if(personal_number_value == RANDOMIZE):
                numberval = random.randint(0, MODULO) # random mode, picking a random value.
            elif(personal_number_value == HASH): 
                numberval = ((id(vehicleDescriptor) * id(BigWorld) + id(ApplyArea)) // 97)  % MODULO # hash mode; TODO try something more randomized?
            else:
                numberval = personal_number_value % MODULO
            numberstr = PERSONAL_NUMBERS_FORMAT.get(personal_number_digitcount, "{:03d}").format(numberval) # include leading zeros if needed. 
            outfitComponent.personal_numbers.append( PersonalNumberComponent(id=personal_numbers_id, number=numberstr, appliedTo=list(available_inscription_slots)[0]) )
    # INJECTION FINISHED
    return outfitComponent

old_prepareBattleOutfit = camouflages.prepareBattleOutfit
def new_prepareBattleOutfit(outfitCD, vehicleDescriptor, vehicleId):
    printDebug("[ROC] Injection started for camouflages.prepareBattleOutfit")
    outfit = old_prepareBattleOutfit(outfitCD, vehicleDescriptor, vehicleId)
    outfit_new_components = modifyOutfitComponent(outfit.pack(), outfitCD=outfitCD, vehicleDescriptor=vehicleDescriptor, vehicleId=vehicleId)
    return Outfit(component=outfit_new_components, vehicleCD=outfit.vehicleCD)
camouflages.prepareBattleOutfit = new_prepareBattleOutfit

from gui.hangar_vehicle_appearance import HangarVehicleAppearance
from CurrentVehicle import g_currentVehicle, g_currentPreviewVehicle
# from gui.ClientSelectableCameraVehicle import ClientSelectableCameraVehicle
# self.__reload(self.__vDesc, self.__vState, outfit or self.__outfit)
old_internal_reload = HangarVehicleAppearance._HangarVehicleAppearance__reload
def new_internal_reload(self, vDesc, vState, outfit):
    if applyInHangar():
        printDebug("[ROC] Injection started for HangarVehicleAppearance.__reload")
        if isinstance(self, HangarVehicleAppearance) and outfit.style and outfit.style.isProgression:
            outfit = self._HangarVehicleAppearance__getStyleProgressionOutfitData(outfit)
        fakeOutfitCD = "Whatever" if outfit else None
        outfit_new_components = modifyOutfitComponent(outfit.pack(), outfitCD=fakeOutfitCD, vehicleDescriptor=vDesc, vehicleId=None)
        outfit = Outfit(component=outfit_new_components, vehicleCD=outfit.vehicleCD)
    return old_internal_reload(self, vDesc, vState, outfit)
HangarVehicleAppearance._HangarVehicleAppearance__reload = new_internal_reload

from gui.Scaleform.framework.entities.abstract.AbstractWindowView import AbstractWindowView
from gui.Scaleform.framework import g_entitiesFactories, ViewSettings, ScopeTemplates
from gui.shared.personality import ServicesLocator
from gui.Scaleform.framework.managers.loaders import SFViewLoadParams
from frameworks.wulf import WindowLayer
from gui.app_loader.settings import APP_NAME_SPACE


def getTextureFilename(tfn):
    # should have slash at front and dot at back
    if(r"/" in tfn):
        tfn = tfn.split(r"/")[-1]
    if(r"." in tfn):
        tfn = tfn.split(".")[0]
    return tfn

class ReplaceOwnCustomizationGUI(AbstractWindowView):
    """There should be three buttons to interact with three concerning objects: ingame dict, AS data, and config file
        Save: from AS data to both ingame dict and config file
        Load from File: from config file to both ingame dict and AS data (manual editing the config)
        Reload: from ingame dict into AS data. Don't need to reload the config file in this case
    """
    UML_PATH = "scripts/client/mods/ownModel.xml"
    JSON_PATH = "mods/configs/replaceOwnCustomization.json"
    def __init__(self, *args, **kwargs):
        super(ReplaceOwnCustomizationGUI, self).__init__(*args, **kwargs)
        if(ReplaceOwnCustomizationGUI.availableUML()):
            self.sectionMain = ResMgr.openSection(ReplaceOwnCustomizationGUI.UML_PATH)
        else:
            self.sectionMain = None
        
        ReplaceOwnCustomizationGUI.loadForcedCustomizationFromDisk(self.sectionMain) # always load once
        self._customization_data = None
        
    def getCustomizationDictFromPy(self, reloadFromDisk=False): # LOAD + RELOAD FUNCTION
        if(reloadFromDisk):
            ResMgr.purge(ReplaceOwnCustomizationGUI.UML_PATH, True) # would this work?
            ReplaceOwnCustomizationGUI.loadForcedCustomizationFromDisk(self.sectionMain)
        cleaned_data = ReplaceOwnCustomizationGUI.getCleanedForcedCustomization()
        # print("[ROC] Pre-dump data :" + str(cleaned_data))
        return json.dumps(cleaned_data)
        
    def updateCustomizationDictAtPy(self, dictStr): # SAVE function
        updated_kwargs = json.loads(dictStr)
        # BigWorld.forcedCustomizationDict.update(updated_kwargs)
        ReplaceOwnCustomizationGUI.saveForcedCustomization(updated_kwargs, sectionMain=self.sectionMain)
        # reload vehicles as well
        g_currentVehicle.refreshModel()
        
    @staticmethod
    def loadForcedCustomizationFromDisk(sectionMain=None, uml_path="scripts/client/mods/ownModel.xml", json_path="mods/configs/replaceOwnCustomization.json"):
        # from file to ingame dict function
        if(ReplaceOwnCustomizationGUI.availableUML()): # UML mode
            sectionMain = sectionMain or ResMgr.openSection(uml_path)
            ResMgr.purge(uml_path, True)
            for namespace in (TYPE_PLAYER, TYPE_ALLY, TYPE_ENEMY):
                keyed_dict = BigWorld.forcedCustomizationDict[namespace] = BigWorld.forcedCustomizationDict.get(namespace, dict())
                for field, size in (("forcedEmblem", 2), ("forcedCamo", 3), ("forcedPaint", 3), ): # tuple-able int values
                    keyed_dict[field] = tryLoadIntValue(sectionMain, "{:s}/{:s}".format(namespace, field), tupleSizeCheck=size, default=0)
                keyed_dict["forcedBothEmblem"] = ReplaceOwnCustomizationGUI.readValueFromSection(sectionMain, "{:s}/forcedBothEmblem".format(namespace), bool, default=False) # bool values
                for field in ("blacklist", "whitelist"): # str values
                    keyed_dict[field] = ReplaceOwnCustomizationGUI.readValueFromSection(sectionMain, "{:s}/{:s}".format(namespace, field), (tuple, str), default=[])
                    if not isValidList(keyed_dict[field]):
                        print("Error while loading {:s} for {:s} - {}. Reverting list to normal".format(field, namespace, keyed_dict[field]))
                        keyed_dict[field] == ""
                keyed_dict["personalNumberID"] = ReplaceOwnCustomizationGUI.readValueFromSection(sectionMain, "{:s}/personalNumberID".format(namespace), int, default=0) # int
                keyed_dict["personalNumber"] = tryLoadPersonalNumber(sectionMain, "{:s}/personalNumber".format(namespace), default=0) # int or possible keywords
                if(namespace == TYPE_PLAYER): # affectHangar only exist for [player]
                    keyed_dict["affectHangar"] = ReplaceOwnCustomizationGUI.readValueFromSection(sectionMain, "{:s}/affectHangar".format(namespace), bool, default=False)
            printDebug("Finished loading UML mode @loadForcedCustomizationFromDisk, loaded structure: {}".format(BigWorld.forcedCustomizationDict))
        else: # JSON mode
            if(os.path.isfile(json_path)):
                with io.open(json_path, "r") as jf:
                    BigWorld.forcedCustomizationDict.update( json.load(jf) )
                printDebug("Finished loading JSON mode @loadForcedCustomizationFromDisk, loaded structure: {}".format(BigWorld.forcedCustomizationDict))
            else:
                return False
        # recheck to ascertain the fields are valid
        customization_cache = vehicles.g_cache.customization20()
        for namespace in (TYPE_PLAYER, TYPE_ALLY, TYPE_ENEMY):
            for field, cachename in [("forcedEmblem", "decals"), ("forcedCamo", "camouflages"), ("forcedPaint", "paints"), ("personalNumberID", "personal_numbers")]:
                BigWorld.forcedCustomizationDict[namespace][field] = checkCustomizationID(BigWorld.forcedCustomizationDict[namespace][field], getattr(customization_cache, cachename).keys())
        return True
        
    @staticmethod
    def getCleanedForcedCustomization(): # Function to convert ingame dict to AS
        config = {}
        for namespace in (TYPE_PLAYER, TYPE_ALLY, TYPE_ENEMY): # make 2-tiered copies
            config[namespace] = dict(BigWorld.forcedCustomizationDict[namespace])
        # update for everything
        for namespace in (TYPE_PLAYER, TYPE_ALLY, TYPE_ENEMY):
            for field, size in [("forcedEmblem", 2), ("forcedBothEmblem", None), ("forcedCamo", 3), ("forcedPaint", 3)]:
                if(config[namespace][field] is None): # None and 0 are functionally the same thing
                    config[namespace][field] = 0
                if(isinstance(config[namespace][field], int) and size and size > 1):
                    # duplicate to help the GUI not messing up; thankfully the forcedBothEmblem is bool
                    config[namespace][field] = tuple([config[namespace][field]] + [-2] * (size - 1))
            for field in ["blacklist", "whitelist"]:
                # lists are updated from str to list
                value = config[namespace].get(field, [])
                if(not isinstance(value, str)):
                    value = "" if len(value) == 0 else ", ".join(value)
                    config[namespace][field] = value
        return config
            
    @staticmethod
    def saveForcedCustomization(customizationdata, sectionMain=None): # Function to write changes to file
        # print("[ROC] debug @saveForcedCustomization: ", customizationdata)
        # update the customizationdata to correct format
        for namespace, datadict in customizationdata.items():
            if not isinstance(datadict, dict):
                continue # only apply this for recursive child dicts
            for field, value in datadict.items():
                if (field in ("blacklist", "whitelist") and isinstance(value, (unicode, str))):
                    # convert string in AS to their list version (when needed)
                    value = str(value)
                    if len(value) > 0: # there is an actual valid string
                        value = [value] if "," not in value else [pcs.strip() for pcs in value.split(",")]
                    else: # empty string
                        value = []
                try:
                    if(isinstance(value, (tuple, list)) and len(value) > 0 and all((isinstance(v, int) for v in value)) ): # all actually return true on empty
                        if all((v == -2 for v in value[1:])):
                            # if all other values has -2, collapse to only one value
                            value = value[0]
                        else:
                            # if not, copy all the -2 with the base
                            value = tuple([v if v != -2 else value[0] for v in value])
                except Exception as e:
                    print(e, field, value)
                    raise e
                datadict[field] = value # reset the values to their correct formatting
        # save to XML/JSON depending on which mode
        if(ReplaceOwnCustomizationGUI.availableUML()): # UML mode
            sectionMain = sectionMain or ResMgr.openSection(ReplaceOwnCustomizationGUI.UML_PATH)
            for namespace, datadict in customizationdata.items():
                if isinstance(datadict, dict):
                    for field, value in datadict.items():
                        ReplaceOwnCustomizationGUI.writeDataToSection(sectionMain, "{:s}/{:s}".format(namespace, field), value)
            sectionMain.save(); ResMgr.purge(ReplaceOwnCustomizationGUI.UML_PATH, True)
        else:
            with io.open(ReplaceOwnCustomizationGUI.JSON_PATH, "w") as jf:
                json.dump(customizationdata, jf)
        BigWorld.forcedCustomizationDict.update(customizationdata)
        
    @staticmethod
    def writeDataToSection(section, key, value, valuetype=None):
        # attempt to write the key with value into the corresponding sections.
        if(value is None):
            print("[ROC] Error: None received for section {}; fix with correct types before trying again.".format(key))
            return
        if(isinstance(value, (str, unicode))):
            section.writeString(key, value);
        elif(isinstance(value, bool)):
            section.writeBool(key, value);
        elif(isinstance(value, int)):
            section.writeInt(key, value);
        elif(isinstance(value, (tuple, list))):
            # write tuple using UML formatting (separated by comma)
            section.writeString(key, ", ".join(str(v) for v in value) )
        else:
            print("[ROC] Unknown type {} of value {}, can't write to chosen section {}.".format(type(value), value, key))
            
            
    @staticmethod
    def readValueFromSection(section, valuename, valuetype, sectionCtx=None, tuplesize=3, default=None):
        # read the value from section depending on type.
        # tuplesize is optional for tuple type (int/float)
        # sectionCtx is optional for int, float and str
        # print("Called @readValueFromSection: ", section, valuename, valuetype)
        if section.has_key(valuename):
            if(valuetype == bool):
                return section.readBool(valuename, default)
            elif(valuetype == int):
                return section.readInt(valuename, default)
            elif(valuetype == str or valuetype == unicode):
                return section.readString(valuename, default)
            elif(valuetype == float):
                return section.readFloat(valuename, default)
            elif(valuetype == (tuple, int)):
                return _xml.readTupleOfInts(sectionCtx, section, valuename, tuplesize)
            elif(valuetype == (tuple, float)):
                return _xml.readTupleOfFloats(sectionCtx, section, valuename, tuplesize)
            elif(valuetype == (tuple, str)):
                unparsed = section.readString(valuename, "").strip()
                if(unparsed == ""):
                    return default
                elif("," in unparsed): # split by , if exist
                    return [part.strip() for part in unparsed.split(",")]
                elif(" " in unparsed): # split by \s next
                    return [part.strip() for part in unparsed.split(" ") if part.strip() != ""]
                else: # no delimiter, single value
                    return [unparsed]
            else:
                raise ValueError("Unknown type {} set.".format(valuetype))
        else:
            return default
            
    def loadCustomizationDataFromPy(self):
        if(not self._customization_data):
            # Construct camo & paint data
            customization_cache = vehicles.g_cache.customization20()
            camo_list = [(k, v.userString if v.userString != "" else "Unknown (ID {:d})".format(k), v.season) for k, v in customization_cache.camouflages.items()]
            paint_list = [(k, v.userString if v.userString != "" else "Unknown (ID {:d})".format(k), v.season) for k, v in customization_cache.paints.items()]
            # Merge the season to the description -  {}
            season_name_list = {SeasonType.SUMMER: "Summer", SeasonType.WINTER: "Winter", SeasonType.DESERT: "Desert", SeasonType.EVENT: "Event", SeasonType.ALL: "All"}
            camo_list = [(k, "[{:s}] {:s}".format(season_name_list.get(s, "Unknown"), d)) for k, d, s in camo_list]
            paint_list = [(k, d) for k, d, s in paint_list] # paint doesn't have seasons apparently
            
            number_list = [(k, v.userString if v.userString != "" else "Unknown (ID {:d})".format(k), v.digitsCount) for k, v in customization_cache.personal_numbers.items()]
            number_list = [(k, r"[{:d}-digit] {:s}".format(n, d)) for k, d, n in number_list]
            decal_list = []
            # Construct decal data for replaceOwnCustomization similarly; falling back to texturename when description are unavailable
            try:
                for k, v in customization_cache.decals.items():
                    if hasattr(v, "i18n") and isinstance(v.i18n, str):
                        # customized decals put in by UML; the description retrieval is a bit different
                        desc = v.i18n
                    else:
                        # normal WoT decal, retrieve as normal (userString, if it's bad use texture filename)
                        desc = v.userString 
                        if v.userString == "": # in case the strings are blank
                            desc = getTextureFilename(v.texture)
                    decal_list.append( (k, desc) )
            except AttributeError as e:
                print("[UML GUI] decal read error: {} {} {} {}".format(e, k, v, v.i18n))
                
            camoID, camoName = zip(*camo_list)
            paintID, paintName = zip(*paint_list)
            numberID, numberName = zip(*number_list)
            decalID, decalName = zip(*decal_list)
            self._customization_data = {
                    "camoID": list(camoID), "paintID": list(paintID), "decalID": list(decalID), "numberID": list(numberID), 
                    "camoName": list(camoName), "paintName": list(paintName), "decalName": list(decalName), "numberName": list(numberName)
                   }
        return self._customization_data
            
    def onWindowClose(self):
        self.destroy()
            
    @staticmethod
    def availableUML():
        return hasattr(BigWorld, "om")
            
    def onWindowMinimize(self):
        pass

    def onSourceLoaded(self):
        pass

    def onTryClosing(self):
        return True
        
"""Add binding from the AS's UML_MainGUI class to the current python UML_MainGUI class"""
g_entitiesFactories.addSettings(ViewSettings("ReplaceOwnCustomizationGUI", ReplaceOwnCustomizationGUI, 'ROC_GUI.swf',
                        WindowLayer.WINDOW, None, ScopeTemplates.GLOBAL_SCOPE, isModal=True, canClose=True, canDrag=True))


def showManager():
    """fire load popover view on button click"""
    app = ServicesLocator.appLoader.getApp(APP_NAME_SPACE.SF_LOBBY)
    if not app:
        return
    app.loadView(SFViewLoadParams("ReplaceOwnCustomizationGUI"), {})

try:
    from gui.modsListApi import g_modsListApi
    g_modsListApi.addModification(id='ReplaceOwnCustomizationGUI', name='Replace Customization', description='GUI to Replace Customization', icon='gui/maps/icons/customization/customization_items/48x48/icon_style.png', enabled=True, login=False, lobby=True, callback=showManager)
except ImportError:
    print 'Warning @replaceOwnCustomization: No modsListApi found.'
    
    
""" Old loading format; removed for consistency

old_updateCustomization = HangarVehicleAppearance.updateCustomization
def new_updateCustomization(self, outfit=None, callback=None):
    if g_currentVehicle.item:
        vehicleCD = g_currentVehicle.item.descriptor.makeCompactDescr()
    else:
        vehicleCD = g_currentPreviewVehicle.item.descriptor.makeCompactDescr()
    mockOutfitCD = "whatever" if outfit else None
    outfit = outfit or self.customizationService.getEmptyOutfitWithNationalEmblems(vehicleCD=vehicleCD)
    if applyInHangar(): # outfitCD is only used to check for destroyed vehicles;
        outfit_new_components = modifyOutfitComponent(outfit.pack(), outfitCD=mockOutfitCD, vehicleDescriptor= self.__vEntity.typeDescriptor, vehicleId=self.id)
        outfit = Outfit(component=outfit_new_components, vehicleCD=outfit.vehicleCD)
    return old_updateCustomization(self, outfit=outfit, callback=callback)
HangarVehicleAppearance.updateCustomization = new_updateCustomization
        
def loadSettingFromOMConfig(ownModelPath="scripts/client/mods/ownModel.xml", sectionMain=None):
    sectionMain = sectionMain or ResMgr.openSection(ownModelPath)
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
            lines = [l.strip() for l in df.readlines()]
            playerForcedEmblem, allyForcedEmblem, enemyForcedEmblem = [tryLoadIntValue(None, None, stringValue=l, tupleSizeCheck=2) for l in lines[:3]]
            playerForcedBothEmblem, allyForcedBothEmblem, enemyForcedBothEmblem = [v.strip().lower() in ["enable", "enabled", "true"] for v in lines[3:6]]
            playerForcedCamo, allyForcedCamo, enemyForcedCamo = [tryLoadIntValue(None, None, stringValue=l, tupleSizeCheck=3) for l in lines[6:9]]
            playerForcedPaint, allyForcedPaint, enemyForcedPaint = [tryLoadIntValue(None, None, stringValue=l, tupleSizeCheck=3) for l in lines[9:12]]
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
                                            **data) # the rest of json data is read directly"""

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