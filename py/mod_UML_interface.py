from gui.Scaleform.framework.entities.abstract.AbstractWindowView import AbstractWindowView
from gui.Scaleform.framework import g_entitiesFactories, ViewSettings, ScopeTemplates
from gui.app_loader.settings import APP_NAME_SPACE
from gui.shared.personality import ServicesLocator
from gui.Scaleform.framework.managers.loaders import SFViewLoadParams

from frameworks.wulf import WindowLayer

import BigWorld
import ResMgr
from CurrentVehicle import g_currentVehicle, g_currentPreviewVehicle
from helpers import getClientLanguage
from items import vehicles, _xml
import nations
from items.components.c11n_constants import SeasonType

import os
import json
import re
_multispace_regex = re.compile("\s+")
import inspect

__all__ = ('UML_MainGUI', )

def getTextureFilename(tfn):
    # retrieve the texture filename for camo/paint/decal that are unnamed.
    # should have slash at front and dot at back
    if(r"/" in tfn):
        tfn = tfn.split(r"/")[-1]
    if(r"." in tfn):
        tfn = tfn.split(".")[0]
    return tfn
    
FIELD_PRIORITY = {f: i for i, f in enumerate(["enabled", "swapNPC", "useWhitelist", "whitelist", "alignToTurret", "camouflageID", "paintID", "parent", "styleID", "hull", "hullStyle", "turret", "turretStyle", "gun", "gunStyle", "configString"])}
def _custom_field_priority(field_and_value):
    field, value = field_and_value
    # prepend extra number to give priority to fields; this should hopefully cause the section to organize when dumping to xml.
    return (FIELD_PRIORITY.get(field, 1000), field)

class UML_mainMeta(AbstractWindowView):
    def onWindowClose(self):
        # print("onWindowClose called")
        self.destroy()
        
    def onWindowMinimize(self):
        # print("onWindowMinimize called")
        pass
        
    def onTryClosing(self):
        # print("onTryClosing called.")
        return True
        
    def onSourceLoaded(self):
        # print("onSourceLoaded called")
        pass

class UML_MainGUI(UML_mainMeta):
    def __init__(self, *args, **kwargs):
        super(UML_MainGUI, self).__init__(*args, **kwargs)
        # NOTE: metapath/fullpath are using xml file so it's one directory in (res/res_mods) and need the ..; json are using python default so it's root
        self.metapath, self.fullpath, self.localizationpath = '../mods/configs/UML/ownModelMeta.xml', "../mods/configs/UML/ownModel.xml", "scripts/client/mods/localization_{}.xml".format(getClientLanguage())
        self.external_localizationpath = "mods/configs/UML/localization.json"
        self.sectionMeta = self.openXMLConfig(self.metapath)
        self.sectionMain = self.openXMLConfig(self.fullpath)
        self.sectionLocalization = self.openXMLConfig(self.localizationpath)
        ctx = self.configCtx = (None, self.fullpath)
        self.sectionMainModel =  _xml.getChildren(ctx, self.sectionMain, 'models')
        self._localization = None
        
        self.metakey = {"remodelsFilelist" : "configLib"} # keys that will be written to sectionMeta
        self.mainkey = {"affectHangar":"affectHangar", 
                        "useUMLSound":"useUMLSound", 
                        "MOErank": "MOE_rank", # MOE
                        "MOEnation": "MOE_nation",
                        "MOElist": "MOE_list",
                        "removeUnhistoricalContent": "removeUnhistoricalContent", # Additional settings
                        "removeClanLogo": "removeClanLogo",
                        "remove3DStyle": "remove3DStyle",
                        "forceClanLogoID": "forceClanLogoID",
                        "swapAllFriendly": "swapAllFriendly",
                        "swapAllEnemy": "swapAllEnemy",
                        "friendlyProfiles": "friendlyProfiles",
                        "enemyProfiles": "enemyProfiles",
                        "ignoreList": "ignoreList"
                       } # keys that will be written to sectionMain
        # self.dumpCamouflageData()
        
        # Construct tank data
        list_every_vehicles = (vehicles.g_cache.vehicle(nations.NAMES.index(nationName), vehicleId) for nationName in nations.NAMES for vehicleId in vehicles.g_list.getList(nations.NAMES.index(nationName)))
        self._nation_data, self._tier_data, self._code_to_tank = {}, {}, {}
        self._type_data = {"heavyTank": set(), "lightTank": set(), "mediumTank": set(), "AT-SPG": set(), "SPG": set()}
        self._list_styles = dict()
        # ignore the variants by keywords. Maybe?
        ignore_keyword = {"MapsTraining", "_bootcamp", "_FL", "_training", "_IGR", "_bot", "_bob", "_CL", "_fallout", "_cl", "_SH"}
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
        
        # matching progression styles. TODO check for vehicle names as well 
        self._progression_styles = set([stl.modelsSet for stl in vehicles.g_cache.customization20().styles.values() if stl.isProgression])
        
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
            usedSection.writeString(truekey, ", ".join(str(v).strip() for v in value) )
        else:
            print("[UML GUI] Unknown type {} of value {}, can't write to chosen section.".format(type(value), value))
            
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
        return False
    
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
                    return [part.strip() for part in unparsed.split(" ") if part.strip() != ""]
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
                                "styleProgression": self.readValueFromSection(section, "styleProgression", str, sectionCtx=profileCtx, default="4"),
                                "alignToTurret": self.readValueFromSection(section, "alignToTurret", bool, sectionCtx=profileCtx, default=False),
                                # additional effect found in config
                                "effectsGun": self.readValueFromSection(section, "effectsGun", str, sectionCtx=profileCtx, default=""),
                                "effectsReload": self.readValueFromSection(section, "effectsReload", str, sectionCtx=profileCtx, default=""),
                                "soundChassisPC": self.readValueFromSection(section, "soundChassisPC", str, sectionCtx=profileCtx, default=""),
                                "soundChassisNPC": self.readValueFromSection(section, "soundChassisNPC", str, sectionCtx=profileCtx, default=""),
                                "soundTurret": self.readValueFromSection(section, "soundTurret", str, sectionCtx=profileCtx, default=""),
                                "soundEnginePC": self.readValueFromSection(section, "soundEnginePC", str, sectionCtx=profileCtx, default=""),
                                "soundEngineNPC": self.readValueFromSection(section, "soundEngineNPC", str, sectionCtx=profileCtx, default=""),
                             }
                # add, read parent; if exist, add it to the config structure
                parent = self.readValueFromSection(section, "parent", str, sectionCtx=profileCtx, default="invalid_parent_str")
                if(parent != "invalid_parent_str"):
                    new_config["parent"] = parent
                    # also add in hull, turret and gun for hybrid vehicles
                    new_config["hull"] = self.readValueFromSection(section, "hull", str, sectionCtx=profileCtx, default=parent)
                    new_config["turret"] = self.readValueFromSection(section, "turret", str, sectionCtx=profileCtx, default=parent)
                    new_config["gun"] = self.readValueFromSection(section, "gun", str, sectionCtx=profileCtx, default=parent)
                    new_config["hullStyle"] = self.readValueFromSection(section, "hullStyle", str, sectionCtx=profileCtx, default="0")
                    new_config["turretStyle"] = self.readValueFromSection(section, "turretStyle", str, sectionCtx=profileCtx, default="0")
                    new_config["gunStyle"] = self.readValueFromSection(section, "gunStyle", str, sectionCtx=profileCtx, default="0")
                    # if hull/turret/gun exists (hybrid vehicle), styleSet is converted to GUI-only chassisStyle
                    if any( (section.has_key(k) for k in ("hull", "turret", "gun")) ):
                        new_config["chassisStyle"] = new_config["styleSet"]
                        new_config["styleSet"] = "0"
                    else:
                        new_config["chassisStyle"] = "0"
                # if name or parent is WOT's known vehicle, allow a read of configString
                if(name in self._code_to_tank.keys() or parent in self._code_to_tank.keys()):
                    new_config["configString"] = self.readValueFromSection(section, "configString", str, sectionCtx=profileCtx, default="9999")
                configs.append(new_config)
            return configs
        else:
            print("[UML GUI] Error @retrieveProfileSettings: xmlConfigObj is not available.")
            return []
            
    def receiveStringConfigAtPy(self, strconf):
        if self._isDAAPIInited():
            try:
                jsondata = json.loads(strconf)
            except Exception as e:
                print("[UML GUI] Error while parsing json: " + str(e))
                return
            # lastProfileSelectedIdx should be popped as it is game instance setting, not worth keeping in UML
            self.currentOMObject.lastProfileSelectedIdx = jsondata.pop('lastProfileSelectedIdx', 0)
            # model data should be popped as well
            model_data = jsondata.pop("listProfileObjects", [])
            sectiondict = {k: v for k, v in _xml.getChildren(self.configCtx, self.sectionMain, 'models')} # convert list to dictionary
            for modelconf in model_data: # update individual model
                self.updateModel(modelconf, sectiondict, main_section=self.sectionMain, ctx=self.configCtx)
            for key, value in jsondata.items(): # update everything else in xml
                self.writeDataToSection(key, value)
            self.sectionMain.save(); self.sectionMeta.save();
            ResMgr.purge(self.metapath, True)
            ResMgr.purge(self.fullpath, True)
            # rerun the loadConfig and refresh model accordingly. 
            # TODO maybe we don't have to reload if the libModel isn't updated?
            self.currentOMObject.loadConfig()
            g_currentVehicle.refreshModel()
        else:
            jsondata = None
    
    def getStringConfigFromPy(self):
        om, config = self.currentOMObject, dict()
        config['affectHangar'] = getattr(om, 'affectHangar', False)
        config['useUMLSound'] = getattr(om, 'useUMLSound', False)
        config['MOErank'] = getattr(om, 'MOErank', -1)
        config['MOEnation'] = self.readValueFromSection(self.sectionMain, "MOE_nation", str, sectionCtx=None, default="placeholder_moenation")
        config['MOElist'] = self.readValueFromSection(self.sectionMain, "MOE_list", str, sectionCtx=None, default="placeholder_moelist")
        # config['forcedEmblem'] = getattr(om, 'forcedEmblem', 0)
        
        config['listProfileObjects'] = self.retrieveProfileSettings(self.sectionMainModel)
        config['remodelsFilelist'] = self.readValueFromSection(self.sectionMeta, "configLib", str, sectionCtx=None, default="placeholder_list_of_libs")
        config['ignoreList'] = self.readValueFromSection(self.sectionMain, "ignoreList", (tuple, str), sectionCtx=None, default=[])
        
        config['removeUnhistoricalContent'] = self.readValueFromSection(self.sectionMain, "removeUnhistoricalContent", bool, sectionCtx=None, default=False)
        config['removeClanLogo'] = self.readValueFromSection(self.sectionMain, "removeClanLogo", bool, sectionCtx=None, default=False)
        config['remove3DStyle'] = self.readValueFromSection(self.sectionMain, "remove3DStyle", bool, sectionCtx=None, default=False)
        config['forceClanLogoID'] = self.readValueFromSection(self.sectionMain, "forceClanLogoID", int, sectionCtx=None, default=0)
        config['swapAllFriendly'] = self.readValueFromSection(self.sectionMain, "swapAllFriendly", bool, sectionCtx=None, default=False)
        config['swapAllEnemy'] = self.readValueFromSection(self.sectionMain, "swapAllEnemy", bool, sectionCtx=None, default=False)
        config['friendlyProfiles'] = self.readValueFromSection(self.sectionMain, "friendlyProfiles", (tuple, str), sectionCtx=None, default=[])
        config['enemyProfiles'] = self.readValueFromSection(self.sectionMain, "enemyProfiles", (tuple, str), sectionCtx=None, default=[])
        
        config['hotkeyAnimation'] = self.readValueFromSection(self.sectionMain, "hotkey_animation", str, sectionCtx=None, default="KEY_INSERT")
        config['hotkeyAnimationReverse'] = self.readValueFromSection(self.sectionMain, "hotkey_animation_reverse", str, sectionCtx=None, default="KEY_DELETE")
        config['hotkeyFireSecondary'] = self.readValueFromSection(self.sectionMain, "hotkey_fire_secondary", str, sectionCtx=None, default="KEY_BACKSLASH")
        
        config['lastProfileSelectedIdx'] = getattr(om, 'lastProfileSelectedIdx', 0)
        # self.printObjToLog(config)
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
        tank_codes = list(sorted(list(vehicles)))
        tank_names = [self._code_to_tank.get(v, v) for v in tank_codes]
        return (tank_codes, tank_names)
        
    def loadVehicleProfileFromPy(self, name):
        try:
            return self._tank_to_code[name]
        except KeyError:
            print("[UML GUI] KeyError happened for tank name {:s}".format(name))
            return "#Error#"
       
    def removeProfileAtPy(self, profilename):
        profilexmlname = 'models/' + profilename
        self.sectionMain.deleteSection(profilexmlname)
    
    HYBRID_FIELDS = ("hull", "gun", "turret", "hullStyle", "gunStyle", "turretStyle", "chassisStyle")
    def updateModel(self, model_obj, sectiondict, main_section=None, ctx=None):
        main_section, ctx = main_section or self.sectionMain, ctx or self.configCtx
        # write the modified values
        pname = model_obj.pop("name")
        xmlname = 'models/' + str(pname)
        if(not main_section.has_key(xmlname) or pname not in sectiondict): # new config, create and update the sectiondict again
            print("[UML GUI] XML name used for createSection: {} {}".format(xmlname, type(xmlname)))
            main_section.createSection(xmlname)
            sectiondict = {k: v for k, v in _xml.getChildren(ctx, main_section, 'models')}
        section = sectiondict[pname]
        # split to handle styleSet >< hybrid fields
        if(pname not in self._code_to_tank and model_obj.get("parent", "invalid_parent_str") not in self._code_to_tank):
            # is UMLProfiles, do not allow either styleSet or hybrid
            for f in UML_MainGUI.HYBRID_FIELDS:
                section.deleteSection(f)
            section.deleteSection("styleSet")
            model_obj = {k: v for k, v in model_obj.items() if k not in UML_MainGUI.HYBRID_FIELDS and k != "styleSet"}
        elif (model_obj.get("styleSet", "0") == "0" and model_obj.get("parent", None)):
            # no styleSet with parent, remove styleSet field and allow hybrids (hull/gun/turret[Style])
            # chassisStyle will be converted to styleSet in this configuration
            # section.deleteSection("styleSet")
            model_obj["styleSet"] = model_obj.pop("chassisStyle", "0")
        else:
            # existing styleSet option, purge (hull/gun/turret[Style])
            for f in UML_MainGUI.HYBRID_FIELDS:
                section.deleteSection(f)
            model_obj = {k: v for k, v in model_obj.items() if k not in UML_MainGUI.HYBRID_FIELDS}
        if(model_obj.get("styleSet", None) not in self._progression_styles):
            # if the styleSet does not exist or not belong to the known styles, disable and remove styleProgression received
            # this doesn't need to work actually
            section.deleteSection("styleProgression")
            model_obj.pop("styleProgression", None)
        # write all remaining fields.
        for headerkey, headervalue in sorted(model_obj.items(), key=_custom_field_priority): # write all other options other than name
            self.writeDataToSection(headerkey, headervalue, usedSection=section)
        
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
            # when reaching here; the localization should have been loaded.
            return [self._localization.get("current_profile_no_style_option", "current_profile_no_style_option")] + self._list_styles[profilename]
        else:
            return None
        
    def checkIsValidWoTVehicleAtPy(self, profilename):
        return profilename in self._code_to_tank
        
    def debugEvalCommand(self, execCmd, evalCmd):
        exec(execCmd)
        result = eval(evalCmd)
        print("[UML GUI] Debug: " + str(result))
        return result
        
    def getStringPositionFromPy(self, override_path="mods/configs/UML/ui_customize.json"):
        flash_position_dict = {"start_x": 10, "start_y": 10, "box_offset": 3, "item_spacing": 10, "section_spacing": 40, "row_increment": 22, "profile_region_width": [200, 150, 300], "sound_region_width": [220, 100], "hybrid_region_width": [120, 200, 160, 160], "swapall_width": 160, "dropdown_width": 160, "subsection_indent": 20, "checkbox_width_per_char": 12}
        if override_path and os.path.isfile(override_path):
            # load & override with the external override if any 
            with open(override_path, "r") as ovrf:
                override = json.load(ovrf)
                flash_position_dict.update(override)
        else:
            print("[UML GUI] No file to override; use default.")
            if override_path and self.getIsDebugUMLFromPy():
                print("Also dumping example to path.")
                with open(override_path, "w") as ovrf:
                    json.dump(flash_position_dict, ovrf, indent=2)
        return json.dumps(flash_position_dict)
        
    def getStringLocalizationFromPy(self):
        use_cache = not self.getIsDebugUMLFromPy() # cache unless the debug mode is enabled.
        language = getClientLanguage()
        is_default_localization = False # this indicate if the localization is default (from inside python). Priority should be default < internal (xml) < external (json)
        # print("[UML GUI]: Received client language: " + language);
        if not use_cache or self._localization is None:
            try:
                with open(self.external_localizationpath, "r") as locfile:
                    self._localization = localization = json.load(locfile)
            except Exception as e:
                # if cannot open, use default alongside a warning.
                print("[UML GUI] Localization file cannot be loaded from `{}`; this will use & dump the default to directory.".format(self.external_localizationpath))
                print("Specific error: {}".format(e))
                self._localization = localization = {"en": self._defaultLocalization() }
                is_default_localization = True
            try:
                internal_localization = dict()
                for key, value in self._defaultLocalization().items():
                    # use the hardcoded variant as the baseline; attempt to read associating values from xml
                    value_type = str if isinstance(value, str) else (tuple, str)
                    value = self.readValueFromSection(self.sectionLocalization, key, value_type, sectionCtx=None, default=None)
                    if value:
                        internal_localization[key] = value 
                if internal_localization:
                    if not is_default_localization:
                        # what is at the localization is external (json), populate the xml result below it. 
                        internal_localization.update(localization.get(language, dict()))
                        localization[language] = internal_localization
                    else:
                        # what is at the localization is internal (py hardcode), populate the xml result above it 
                        localization[language] = localization.get(language, dict())
                        localization[language].update(internal_localization)
            except Exception as e:
                print("[UML GUI] Internal Localization file cannot be loaded from `{}`; this will use & dump the default to directory.".format(self.localizationpath))
                print("Specific error: {}".format(e))
            if is_default_localization:
                print("[UML GUI] dumping the default (after-xml-merge): {}".format(localization))
                # if default, also dumping the merged localization externally to allow modification
                directory = os.path.dirname(self.external_localizationpath)
                if not os.path.isdir(directory):
                    os.mkdir(directory)
                with open(self.external_localizationpath, "w") as locfile:
                    json.dump(localization, locfile, indent=2)
        if language not in self._localization:
            print("[UML GUI] Has no language '{}' in localization file, using default (en)".format(language))
            return json.dumps(self._localization["en"])
        return json.dumps(self._localization[language])
    
    def _defaultLocalization(self):
        return {
            # General, UML wide section - MOE, show in hangar, additional filelist etc.
            "moe_options": ["Default MOE", "No MOE", "1 MOE", "2 MOE", "3 MOE"],
            "add_profile_to_moe_desc": "From Selector",
            "moe_list_desc": "applied to: ", # label linking MOE selector - MOE list
            "moe_texture_desc": "using texture of: ", # label linking MOE list - MOE icon selection; this doesnt work yet.
            "moe_list_placeholder": "Test localization binding.", # doesnt work anyway since MOE get selected on entry.
            "affect_hangar_desc": "View UML effect in hangar",
            "remodels_filelist_desc": "Base Remodel files:",
            "use_uml_sound_desc": "Use UML's sound",
            "additional_setting_desc": "Additional Settings", # sub-section: additional, rarely used settings.
            "remove_3d_style_desc": "Remove all 3D Styles",
            "remove_unhistorical_desc": "Remove ahistorical items (incl. replays)",
            "remove_clan_logo_desc": "Remove Clan Logo",
            "force_clan_logo_desc": "Clan ID:",
            "swap_friendly_enable_desc": "Swap ALL friendly vehicles",
            "swap_friendly_desc": "Using:",
            "add_profile_friendly_desc": "Add current Profile",
            "swap_enemy_enable_desc": "Swap ALL enemy vehicles",
            "swap_enemy_desc": "Using:",
            "add_profile_enemy_desc": "Add current Profile",
            
            # Single profile section 
            "toggle_show_ignore_desc": "Show ignored profiles",
            "toggle_show_activated_desc": "Show only activated profiles",
            "current_profile_ignore_desc": "Ignore by GUI",
            "current_profile_target_desc": "Profile enabled for:",
            "current_profile_enable_desc": "Enabled",
            "current_profile_swapNPC_desc": "Model swap NPC",
            "current_profile_alignToTurret_desc": "Align to Turret",
            "current_profile_camo_desc": "Camouflage ID:",
            "current_profile_paint_desc": "Paint ID:",
            "current_profile_configString_desc": "Config:",
            "current_profile_style_progression_desc": "(Progress) Style:",
            "sound_effect_desc": "Custom Sound",
            "current_profile_gunEffect_desc": "Gun Effect/Sound",
            "current_profile_soundTurret_desc": "Turret Sound",
            "current_profile_soundChassis_desc": "Chassis Sound (PC/NPC)",
            "current_profile_soundEngine_desc": "Engine Sound (PC/NPC)",
            "current_profile_no_style_option": "No Style",
            "hybrid_desc": "Hybrid Vehicle Configuration", # sub-section: hybrid vehicle config.
            "profile_chassis_desc": "Chassis:",
            "profile_hull_desc": "Hull:",
            "profile_turret_desc": "Turret:",
            "profile_gun_desc": "Gun:",
            "profile_hull_from_selector_desc": "From Selector",
            "profile_turret_from_selector_desc": "From Selector",
            "profile_gun_from_selector_desc": "From Selector",
            "use_hangar_vehicle_btn": "Add hangar vehicle to Whitelist",
            "delete_profile_btn": "Delete this Profile",
            "camo_no_change_option": "No change", # sub-section: camo, paint & decal options.
            "camo_remove_option": "Remove",
            "paint_no_change_option": "No change",
            "paint_remove_option": "Remove",
            "decal_no_change_option": "No change",
            "decal_remove_option": "Remove",
            
            # Vehicle Selector option
            "vehicle_selector_desc": "Vehicle Selector",
            "add_profile_btn": "Add as new Profile",
            "add_whitelist_btn": "Add to Whitelist",
            "add_profile_as_parent_btn": "Add as Parent to ",
            
            "apply_btn": "Apply",
            "reload_btn": "Reload",
            }
    
"""Add binding from the AS's UML_MainGUI class to the current python UML_MainGUI class"""
g_entitiesFactories.addSettings(ViewSettings("UML_MainGUI", UML_MainGUI, 'UML_MainGUI.swf',
                        WindowLayer.WINDOW, None, ScopeTemplates.GLOBAL_SCOPE, isModal=True, canClose=True, canDrag=True))


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
    print '[UML GUI] No modsListApi found.'