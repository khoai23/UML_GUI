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

def tryLoadIntValue(section, valueName):
    """Try load tuple of int; if failed, load single int; if failed, return default (0)"""
    stringValue = section.readString(valueName, "")
    if(stringValue == ""):
        return 0
    try:
        if("," in stringValue):
            return tuple([int(v.strip()) for v in stringValue.split(",")])
        else:
            return int(stringValue)
    except ValueError:
        print("Error @replaceOwnEmblem: can't convert value {}".format(stringValue))
    return 0

def loadSettingFromXML(ownModelPath="scripts/client/mods/ownModel.xml"):
    """Update fields: OM.player.forcedEmblem (int or (int, int)); OM.player.forcedCamouflage (int or (int, int, int))"""
    # playerObject, alliedObject, enemyObject = [object() for _ in range(3)]
    sectionMain = ResMgr.openSection(ownModelPath)
    playerForcedEmblem = tryLoadIntValue(sectionMain, "player/forcedEmblem")

BigWorld.forcedEmblem = None

def tryGetPersonalDecal(ownModelPath="scripts/client/mods/ownModel.xml", personalDecalPath="forcedEmblem.txt"):
    """Attempt to get personal decal from either OM or a set file."""
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

old_prepareBattleOutfit = camouflages.prepareBattleOutfit
def new_prepareBattleOutfit(outfitCD, vehicleDescriptor, vehicleId):
    vehicleCD = vehicleDescriptor.makeCompactDescr()
    player = BigWorld.player()
    outfitComponent = camouflages.getOutfitComponent(outfitCD, vehicleDescriptor)
    # INJECTION HERE
    if BigWorld.player().playerVehicleID == vehicleId and tryGetPersonalDecal():
        # override (player only, in battle)
        decal_idx = tryGetPersonalDecal()
        for decalItem in outfitComponent.decals:
            decalItem.id = decal_idx
    # INJECTION FINISHED
    outfit = Outfit(component=outfitComponent, vehicleCD=vehicleCD)
    forceHistorical = player.playerVehicleID != vehicleId and player.customizationDisplayType < outfit.customizationDisplayType()
    if outfit.style and (outfit.style.isProgression or camouflages.IS_EDITOR):
        progressionOutfit = camouflages.getStyleProgressionOutfit(outfit, toLevel=outfit.progressionLevel)
        if progressionOutfit is not None:
            outfit = progressionOutfit
    return outfit
camouflages.prepareBattleOutfit = new_prepareBattleOutfit

"""
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