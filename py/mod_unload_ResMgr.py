from items.vehicles import getItemByCompactDescr
from items.vehicles import makeIntCompactDescrByID
from items.components.c11n_constants import CustomizationType
from helpers import i18n
from items import vehicles
import nations

"""
DataDict = dict()
camo = DataDict["camo"] = []
paint = DataDict["paint"] = []
pnum = DataDict["pnum"] = []
decal = DataDict["decal"] = []

import inspect
with open("@itemdata.txt", "w") as df:
    for i in range(200):
        try:
            intCD = makeIntCompactDescrByID('customizationItem', CustomizationType.CAMOUFLAGE, i)
            df.write(str(dir(getItemByCompactDescr(intCD))) + "\n----------------------\n")
            camo.append(getItemByCompactDescr(intCD))
        except Exception as e:
            df.write("Invalid camo index {:d}, Exception {}".format(i, e) + "\n----------------------\n")
        try:
            intCD = makeIntCompactDescrByID('customizationItem', CustomizationType.PAINT, i)
            df.write(str(inspect.getmembers(getItemByCompactDescr(intCD))) + "\n----------------------\n")
            paint.append(getItemByCompactDescr(intCD))
        except Exception as e:
            df.write("Invalid paint index {:d}, Exception {}".format(i, e) + "\n----------------------\n")
        try:
            intCD = makeIntCompactDescrByID('customizationItem', CustomizationType.PERSONAL_NUMBER, i)
            df.write(str((getItemByCompactDescr(intCD))) + "\n----------------------\n")
        except Exception as e:
            df.write("Invalid personal number index {:d}, Exception {}".format(i, e) + "\n----------------------\n")
        try:
            intCD = makeIntCompactDescrByID('customizationItem', CustomizationType.DECAL, i)
            df.write(str((getItemByCompactDescr(intCD))) + "\n----------------------\n")
        except Exception as e:
            df.write("Invalid decal index {:d}, Exception {}".format(i, e) + "\n----------------------\n")
            
    df.write(str((CustomizationType)) + "\n----------------------\n")
   
 
import pickle, json
with open("@itemdump.pkl", "wb") as dumpfile:
    pickle.dump(DataDict, dumpfile, protocol=-1)
    """
    
DataDict = dict()
decal = DataDict["decal"] = {}

def extract_values_cst(obj):
    # extract fields: season, userKey, userString, texture
    return {"season": obj.season, "texture": obj.texture, "userKey": obj.userKey, "userString": obj.userString, "testLocUserString": i18n.makeString(obj.userString)}
ogCamoDict = vehicles.g_cache.customization20().camouflages
camoDict = DataDict["camo"] = {k: extract_values_cst(v) for k, v in ogCamoDict.items() }
ogPaintDict = vehicles.g_cache.customization20().paints
paintDict = DataDict["paint"] = {k: extract_values_cst(v) for k, v in ogPaintDict.items() }

def extract_value_veh(obj, baseNname=None):
    # extract nation, profilename, tier, desc
    nation, profilename = obj.name.split(":")
    return profilename.strip(), {"name": obj.userString, "nation": nation.strip(), "baseNationName": baseNname, "tier": obj.level, "description": obj.description, "tags": list(obj.tags)}
list_every_vehicles = ((nationName, vehicles.g_cache.vehicle(nations.NAMES.index(nationName), vehicleId)) for nationName in nations.NAMES for vehicleId in vehicles.g_list.getList(nations.NAMES.index(nationName)))
conv = (extract_value_veh(v, baseNname=n) for n, v in list_every_vehicles)
vehicleDict = DataDict["vehicle"] = {k: v for k, v in conv}
"""import inspect
first_instance = True
for nationName in nations.NAMES:
    nationId = nations.NAMES.index(nationName)
    for vehicleId in vehicles.g_list.getList(nationId):
        vehicle = vehicles.g_cache.vehicle(nationId, vehicleId)
        vehicleDict.append([vehicle.name, vehicleId, nationId])
        if(first_instance):
            list_values = inspect.getmembers(vehicle)
            print("@unload_ResMgr: {} {}".format(nationId, vehicleId))
            for r in range(0, len(list_values), 10):
                print("Inspecting values of vehicle @unload_ResMgr [r]" + str(list_values[r:r+10]))
            first_instance = False"""

import pickle, json
with open("@itemdump.json", "w") as dumpfile:
    json.dump(DataDict, dumpfile, indent=2)