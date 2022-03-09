from gui.Scaleform.framework.entities.abstract.AbstractWindowView import AbstractWindowView
from gui.Scaleform.framework import g_entitiesFactories, ViewSettings, ScopeTemplates
from gui.app_loader.settings import APP_NAME_SPACE
from gui.shared.personality import ServicesLocator
from gui.Scaleform.framework.managers.loaders import SFViewLoadParams

from frameworks.wulf import WindowLayer

import BigWorld
import ResMgr
from CurrentVehicle import g_currentVehicle, g_currentPreviewVehicle
from items import vehicles, _xml
import nations
from items.components.c11n_constants import SeasonType

import json
import re
_multispace_regex = re.compile("\s+")
import inspect

__all__ = ('UML_main', )

def getTextureFilename(tfn):
    # should have slash at front and dot at back
    if(r"/" in tfn):
        tfn = tfn.split(r"/")[-1]
    if(r"." in tfn):
        tfn = tfn.split(".")[0]
    return tfn

class UML_mainMeta(AbstractWindowView):
    def onWindowClose(self):
        print("onWindowClose called")
        self.destroy()
        
    def onWindowMinimize(self):
        print("onWindowMinimize called")
        
    def onTryClosing(self):
        print("onTryClosing called.")
        return True
        
    def onSourceLoaded(self):
        print("onSourceLoaded called")

class UML_MainGUI(UML_mainMeta):
    def __init__(self, *args, **kwargs):
        super(UML_MainGUI, self).__init__(*args, **kwargs)
        self.metapath, self.fullpath = 'scripts/client/mods/ownModelMeta.xml', "scripts/client/mods/ownModel.xml"
        self.sectionMeta = self.openXMLConfig(self.metapath)
        self.sectionMain = self.openXMLConfig(self.fullpath)
        ctx = self.configCtx = (None, self.fullpath)
        self.sectionMainModel =  _xml.getChildren(ctx, self.sectionMain, 'models')
        
        self.metakey = {"remodelsFilelist" : "configLib"} # keys that will be written to sectionMeta
        self.mainkey = {"affectHangar":"affectHangar", 
                        "useUMLSound":"useUMLSound", 
                        "MOErank": "MOE_rank",
                        "ignoreList": "ignoreList"
                       } # keys that will be written to sectionMain
        
        # self.dumpCamouflageData()
        
        # Construct tank data
        list_every_vehicles = (vehicles.g_cache.vehicle(nations.NAMES.index(nationName), vehicleId) for nationName in nations.NAMES for vehicleId in vehicles.g_list.getList(nations.NAMES.index(nationName)))
        self._nation_data, self._tier_data, self._code_to_tank = {}, {}, {}
        self._type_data = {"heavyTank": set(), "lightTank": set(), "mediumTank": set(), "AT-SPG": set(), "SPG": set()}
        self._list_styles = dict()
        # ignore the variants by keywords. Maybe?
        ignore_keyword = {"MapsTraining", "_bootcamp", "_FL", "_training", "_IGR", "_bot", "_bob", "_CL", "_fallout", "_cl"}
        for vehicle_obj in list_every_vehicles:
            nation, tankprofilename = vehicle_obj.name.split(":")
            if(any(k in tankprofilename for k in ignore_keyword)):
                continue
            # add nation / type / tier
            nationlist = self._nation_data[nation] = self._nation_data.get(nation, set())
            nationlist.add(tankprofilename)
            tier = vehicle_obj.level
            tierlist = self._tier_data[tier] = self._tier_data.get(tier, set())
            tierlist.add(tankprofilename)
            for typetag in vehicle_obj.tags:
                if(typetag in self._type_data):
                    self._type_data[typetag].add(tankprofilename)
            # name reference
            self._code_to_tank[tankprofilename] = vehicle_obj.userString
            # self._vehicle_obj = vehicle_obj # keep a last vehicle obj to inspect
            # if have more than 1 styles (default), add to concerning dict
            possible_styles = list(vehicle_obj.hulls[0].modelsSets.keys())
            possible_styles.remove('default')
            if(len(possible_styles) > 0):
                # print("[UML GUI] Cached style: {:s} - {}".format(tankprofilename, possible_styles))
                self._list_styles[tankprofilename] = possible_styles
        # backward search from tank name to profilename
        self._tank_to_code = {name: key for key, name in self._code_to_tank.items()}
        # also update tier to str format (currently int)
        self._tier_data = {str(k): v for k, v in self._tier_data.items()}
        # debug
        # print("All callable from sectionMain: ", [att for att in dir(self.sectionMain) if callable(getattr(self.sectionMain, att))] )
        self.vehicleSelectorData = None
        
        # Construct camo & paint data
        camo_list = [(k, v.userString if v.userString != "" else "Unknown (ID {:d})".format(k), v.season) for k, v in vehicles.g_cache.customization20().camouflages.items()]
        paint_list = [(k, v.userString if v.userString != "" else "Unknown (ID {:d})".format(k), v.season) for k, v in vehicles.g_cache.customization20().paints.items()]
        # Merge the season to the description -  {}
        season_name_list = self._snl = {SeasonType.SUMMER: "Summer", SeasonType.WINTER: "Winter", SeasonType.DESERT: "Desert", SeasonType.EVENT: "Event", SeasonType.ALL: "All"}
        self._camo_list = [(k, "[{:s}] {:s}".format(season_name_list.get(s, "Unknown"), d)) for k, d, s in camo_list]
        self._paint_list = [(k, d) for k, d, s in paint_list] # paint doesn't have seasons apparently
        
        self._decal_list = []
        # Construct decal data for replaceOwnCustomization similarly; falling back to texturename when description are unavailable
        try:
            for k, v in vehicles.g_cache.customization20().decals.items():
                if hasattr(v, "i18n") and isinstance(v.i18n, str):
                    # customized decals put in by UML; the description retrieval is a bit different
                    desc = v.i18n
                else:
                    # normal WoT decal, retrieve as normal (userString, if it's bad use texture filename)
                    desc = v.userString 
                    if v.userString == "": # in case the strings are blank
                        desc = getTextureFilename(v.texture)
                self._decal_list.append( (k, desc) )
        except AttributeError as e:
            print("[UML GUI] decal read error: {} {} {} {}".format(e, k, v, v.i18n))
        
    def printObjToLog(self, obj):
        print("[UML GUI] printObjToLog, obj found: ", obj, type(obj))
    
    def writeDataToSection(self, key, value, usedSection=None):
        # attempt to write the key with value into the corresponding sections.
        if(usedSection is not None): # specified section, no need to trace with the key dictionary
            truekey = key
        elif(key in self.metakey.keys()): # key from sectionMeta
            usedSection, truekey = self.sectionMeta, self.metakey[key]
        elif(key in self.mainkey.keys()): # key from sectionMain
            usedSection, truekey = self.sectionMain, self.mainkey[key]
        else:
            print("[UML GUI] Unidentified key for value {}:{}, skipping.".format(key, value))
            return
        
        if(isinstance(value, (str, unicode))):
            usedSection.writeString(truekey, value);
        elif(isinstance(value, bool)):
            usedSection.writeBool(truekey, value);
        elif(isinstance(value, int)):
            usedSection.writeInt(truekey, value);
        elif(isinstance(value, (tuple, list))):
            # write tuple using UML formatting (separated by comma)
            usedSection.writeString(truekey, ", ".join(str(v) for v in value) )
        else:
            print("[UML GUI] Unknown type {} of value {}, can't write to chosen section.".format(type(value), value))
    
    def updateForcedCustomization(self, customizationdata, mainSection):
        # print("[UML GUI] debug: ", customizationdata)
        if(customizationdata):
            for namespace, datadict in zip(["player", "ally", "enemy"], customizationdata):
                for field, value in datadict.items():
                    if(isinstance(value, (tuple, list))):
                        if all((v == -2 for v in value[1:])):
                            # if all other values has -2, collapse to only one value
                            value = value[0]
                        else:
                            # if not, copy all the -2 with the base
                            value = tuple([v if v != -2 else value[0] for v in value])
                    self.writeDataToSection("{:s}/{:s}".format(namespace, field), value, usedSection=mainSection)
                    # print("[UML GUI] debug write to section {}/{} {} ({})".format(namespace, field, value, type(value)))
                    # TODO maybe update the dict here instead of `UML_reload_func`?
        else:
            pass # do nothing when this customization data doesn't exist
            
    @property
    def currentOMObject(self):
        if(hasattr(BigWorld, "om")):
            om_data = BigWorld.om
            return om_data
        else:
            print("[UML GUI] OM data not available ATM; resorting to default values.")
            return None
    
    def getIsDebugUMLFromPy(self):
        return getattr(self.currentOMObject, "isDebug", False)
    
    def forcedCustomizationIsAvailableAtPy(self):
        return hasattr(BigWorld, "forcedCustomizationDict")
    
    @staticmethod
    def openXMLConfig(fullpath):
        section = ResMgr.openSection(fullpath)
        return section
        
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
                if("," in unparsed): # split by , if exist
                    return [part.strip() for part in unparsed.split(",")]
                elif(" " in unparsed): # split by \s next
                    return [part.strip() for part in unparsed.split(",")]
                else: # no delimiter, single value
                    return [unparsed]
            else:
                raise ValueError("Unknown type {} set.".format(valuetype))
        else:
            return default
            
    def retrieveProfileSettings(self, xmlConfigObj):
        if xmlConfigObj:
            configs = []
            for name, section in xmlConfigObj:
                profileCtx = (self.configCtx, 'models/' + name)
                new_config = {"name": name, 
                                "enabled": self.readValueFromSection(section, "enabled", bool, sectionCtx=profileCtx, default=False), 
                                "swapNPC": self.readValueFromSection(section, "swapNPC", bool, sectionCtx=profileCtx, default=False),
                                "useWhitelist": self.readValueFromSection(section, "useWhitelist", bool, sectionCtx=profileCtx, default=True),
                                "whitelist": _multispace_regex.sub(" ", self.readValueFromSection(section, "whitelist", str, sectionCtx=profileCtx, default="")),
                                "camouflageID": self.readValueFromSection(section, "camouflageID", int, sectionCtx=profileCtx, default=0),
                                "paintID": self.readValueFromSection(section, "paintID", int, sectionCtx=profileCtx, default=0),
                                "styleSet": self.readValueFromSection(section, "styleSet", str, sectionCtx=profileCtx, default="0"),
                             }
                # add, read parent; if exist, add it to the config structure
                parent = self.readValueFromSection(section, "parent", str, sectionCtx=profileCtx, default="invalid_parent_str")
                if(parent != "invalid_parent_str"):
                    new_config["parent"] = parent
                    # also add in hull, turret and gun relative to the 
                    new_config["hull"] = self.readValueFromSection(section, "hull", str, sectionCtx=profileCtx, default=parent)
                    new_config["turret"] = self.readValueFromSection(section, "turret", str, sectionCtx=profileCtx, default=parent)
                    new_config["gun"] = self.readValueFromSection(section, "gun", str, sectionCtx=profileCtx, default=parent)
                # if name or parent is WOT's known vehicle, allow a read of configString
                if(name in self._code_to_tank.keys() or parent in self._code_to_tank.keys()):
                    new_config["configString"] = self.readValueFromSection(section, "configString", str, sectionCtx=profileCtx, default="9999")
                configs.append(new_config)
            return configs
        else:
            print("[UML GUI] Error @retrieveProfileSettings: xmlConfigObj is not available.")
            return []
    
    def retrieveForcedConfigSettings(self):
        if(self.forcedCustomizationIsAvailableAtPy()):
            config = [{}, {}, {}]
            customization_dict = BigWorld.forcedCustomizationDict
            if("playerForcedEmblem" not in customization_dict):
                # Ignore the usual lazyload - call the reload func immediately
                BigWorld.forcedCustomizationDict["UML_reload_func"]()
            # print("Customization dict: {}".format(customization_dict))
            for idx, namespace in enumerate(["player", "ally", "enemy"]):
                for field, size in [("forcedEmblem", 2), ("forcedBothEmblem", None), ("forcedCamo", 3), ("forcedPaint", 3)]:
                    truefield = field[:1].upper() + field[1:]
                    config[idx][field] = value = customization_dict.get("{:s}{:s}".format(namespace, truefield), 0)
                    # print("Try loading {:s}{:s} from customization dict, result: {}".format(namespace, truefield, value))
                    if(config[idx][field] is None): # None and 0 are functionally the same thing
                        config[idx][field] = 0
                    if(isinstance(config[idx][field], int) and size and size > 1):
                        # duplicate to help the GUI not messing up; thankfully the forcedBothEmblem is bool
                        config[idx][field] = tuple([config[idx][field]] + [-2] * (size - 1))
            return config
        else:
            return None
            
    def receiveStringConfigAtPy(self, strconf):
        if self._isDAAPIInited():
            try:
                jsondata = json.loads(strconf)
            except Exception as e:
                print("[UML GUI] Error while parsing json: " + str(e))
                return
            # lastProfileSelectedIdx should be popped as it is game instance setting, not worth keeping in UML
            self.currentOMObject.lastProfileSelectedIdx = jsondata.pop('lastProfileSelectedIdx', 0)
            # forcedCustomization should be converted
            self.updateForcedCustomization(jsondata.pop('forcedCustomization', None), self.sectionMain)
            # model data should be popped as well
            model_data = jsondata.pop("listProfileObjects", [])
            sectiondict = {k: v for k, v in _xml.getChildren(self.configCtx, self.sectionMain, 'models')} # convert list to dictionary
            for modelconf in model_data:
                # write the modified values
                pname = modelconf.pop("name")
                xmlname = 'models/' + str(pname)
                if(not self.sectionMain.has_key(xmlname) or pname not in sectiondict): # new config, create and update the sectiondict again
                    print("[UML GUI] XML name used for createSection: {} {}".format(xmlname, type(xmlname)))
                    self.sectionMain.createSection(xmlname)
                    sectiondict = {k: v for k, v in _xml.getChildren(self.configCtx, self.sectionMain, 'models')}
                section = sectiondict[pname]
                for headerkey, headervalue in modelconf.items(): # write all other options other than name
                    self.writeDataToSection(headerkey, headervalue, usedSection=section)
            for key, value in jsondata.items(): # update everything else in xml
                self.writeDataToSection(key, value)
            self.sectionMain.save(); self.sectionMeta.save();
            ResMgr.purge(self.metapath, True)
            ResMgr.purge(self.fullpath, True)
            # rerun the loadConfig and refresh model accordingly. 
            # TODO maybe we don't have to reload if the libModel isn't updated?
            self.currentOMObject.loadConfig()
            g_currentVehicle.refreshModel()    
            # additionally, if replaceOwnCustomization mod exist, attempt to reload its configuration as well.
            if(hasattr(BigWorld, "forcedCustomizationDict")):
                BigWorld.forcedCustomizationDict["UML_reload_func"]()
        else:
            jsondata = None
    
    def getStringConfigFromPy(self):
        om, config = self.currentOMObject, dict()
        config['affectHangar'] = getattr(om, 'affectHangar', False)
        config['useUMLSound'] = getattr(om, 'useUMLSound', False)
        config['MOErank'] = getattr(om, 'MOErank', -1)
        # config['forcedEmblem'] = getattr(om, 'forcedEmblem', 0)
        config['lastProfileSelectedIdx'] = getattr(om, 'lastProfileSelectedIdx', 0)
        
        config['listProfileObjects'] = self.retrieveProfileSettings(self.sectionMainModel)
        config['forcedCustomization'] = self.retrieveForcedConfigSettings()
        config['remodelsFilelist'] = self.readValueFromSection(self.sectionMeta, "configLib", str, sectionCtx=None, default="placeholder_list_of_libs")
        config['ignoreList'] = self.readValueFromSection(self.sectionMain, "ignoreList", (tuple, str), sectionCtx=None, default=[])
        return json.dumps(config)
    
    def getVehicleSelectorDataFromPy(self):
        if(self.vehicleSelectorData is None):
            # roman_conv = {"I": 1, "II": 2, "III": 3, "IV": 4, "V": 5, "VI": 6, "VII": 7, "VIII": 8, "IX": 9, "X": 10}
            self.vehicleSelectorData = {
                "nations": ["Any"] + sorted(list(self._nation_data.keys())),
                "types": ["Any"] + sorted(list(self._type_data.keys())),
                "tiers": ["Any"] + sorted(self._tier_data.keys(), key=lambda v: int(v))
            }
        return self.vehicleSelectorData
    
    def loadVehiclesWithCriteriaFromPy(self, vnation, vtype, vtier):
        #print("@loadVehicleProfileFromPy: ", vnation, vtype, vtier)
        str_nation = self.vehicleSelectorData["nations"][vnation] if vnation > 0 else None
        str_type = self.vehicleSelectorData["types"][vtype] if vtype > 0 else None
        str_tier = self.vehicleSelectorData["tiers"][vtier] if vtier > 0 else None
        if(str_nation is None):
            vehicles = {k for nset in self._nation_data.values() for k in nset}
        else:
            vehicles = self._nation_data[str_nation]
        if(str_type is not None):
            vehicles = vehicles & self._type_data[str_type]
        if(str_tier is not None):
            vehicles = vehicles & self._tier_data[str_tier]
        return [self._code_to_tank.get(v, v) for v in sorted(list(vehicles))]
        
    def loadVehicleProfileFromPy(self, name):
        try:
            return self._tank_to_code[name]
        except KeyError:
            print("[UML GUI] KeyError happened for tank name {:s}".format(name))
            return "#Error#"
       
    def removeProfileAtPy(self, profilename):
        profilexmlname = 'models/' + profilename
        self.sectionMain.deleteSection(profilexmlname)
    
    def loadCustomizationDataFromPy(self):
        camoID, camoName = zip(*self._camo_list)
        paintID, paintName = zip(*self._paint_list)
        decalID, decalName = zip(*self._decal_list)
        return {"camoID": list(camoID), "paintID": list(paintID), "decalID": list(decalID), 
                "camoName": list(camoName), "paintName": list(paintName), "decalName": list(decalName)
               }
        
    def getHangarVehicleFromPy(self):
        try:
            return g_currentVehicle.item.name.split(":")[-1].strip()
        except Exception as e:
            print("[UML GUI] Exception when trying to get vehicle profile name: {:s}. Raw name found before split: {:s}".format(str(e), g_currentVehicle.item.name))
            return ""
     
    def getPossibleStyleOfProfileFromPy(self, profilename):
        if(profilename in self._list_styles):
            return ["No Style"] + self._list_styles[profilename]
        else:
            return None
        
    def checkIsValidWoTVehicleAtPy(self, profilename):
        return profilename in self._code_to_tank
        
    def debugEvalCommand(self, execCmd, evalCmd):
        exec(execCmd)
        result = eval(evalCmd)
        print("[UML GUI] Debug: " + str(result))
        return result
    
"""Add binding from the AS's UML_MainGUI class to the current python UML_MainGUI class"""
g_entitiesFactories.addSettings(ViewSettings("UML_MainGUI", UML_MainGUI, 'UML_MainGUI.swf',
                        WindowLayer.WINDOW, None, ScopeTemplates.GLOBAL_SCOPE, isModal=True, canClose=True, canDrag=False))


def showManager():
    """fire load popover view on button click"""
    app = ServicesLocator.appLoader.getApp(APP_NAME_SPACE.SF_LOBBY)
    if not app:
        return
    app.loadView(SFViewLoadParams("UML_MainGUI"), {})

try:
    from gui.modsListApi import g_modsListApi
    g_modsListApi.addModification(id='UML_MainGUI', name='UML (GUI Interface)', description='GUI for Universal Model Loader', icon='maps/UML_alpha.png', enabled=True, login=False, lobby=True, callback=showManager)
except ImportError:
    print '[UML] No modsListApi found.'