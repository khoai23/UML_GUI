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

import json
import re
_multispace_regex = re.compile("\s+")

__all__ = ('UML_main', )

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
        self.sectionMain = ResMgr.openSection(self.fullpath)
        ctx = self.configCtx = (None, self.fullpath)
        self.sectionMainModel =  _xml.getChildren(ctx, self.sectionMain, 'models')
        
        self.metakey = {"remodelsFilelist" : "configLib"} # keys that will be written to sectionMeta
        self.mainkey = {"affectHangar":"affectHangar", "useUMLSound":"useUMLSound", "MOErank": "MOE_rank"} # keys that will be written to sectionMain
        
        # self.dumpCamouflageData()
        
        # basefiledir = __file__.rsplit(r"/")[0] if "/" in __file__ else "."
        with open('mods/configs/tank_data.json', "r") as jf:
            self._nation_data, self._tier_data, self._type_data, self._code_to_tank = json.load(jf)
        self._nation_data = {k: set(v) for k, v in self._nation_data.items()}
        self._tier_data = {k: set(v) for k, v in self._tier_data.items()}
        self._type_data = {k: set(v) for k, v in self._type_data.items()}
        self._tank_to_code = {v: k for k, v in self._code_to_tank.items()}
        
        # debug
        # print("All callable from sectionMain: ", [att for att in dir(self.sectionMain) if callable(getattr(self.sectionMain, att))] )
        self.vehicleSelectorData = None

    def dumpCamouflageData(self):
        ogCamoDict = vehicles.g_cache.customization20().camouflages
        camoDict = {k: v.userString for k, v in ogCamoDict.items() }
        print(camoDict)
        with open("camo.json", "w") as cf:
            try:
                json.dump(camoDict, cf)
            except Exception as e:
                print("Error when dumping camo:", e)

    def printObjToLog(self, obj):
        print("printObjToLog, obj found: ", obj, type(obj))
    
    def writeDataToSection(self, key, value, usedSection=None):
        # attempt to write the key with value into the corresponding sections.
        if(usedSection is not None): # specified section, no need to trace with the key dictionary
            truekey = key
        elif(key in self.metakey.keys()): # key from sectionMeta
            usedSection, truekey = self.sectionMeta, self.metakey[key]
        elif(key in self.mainkey.keys()): # key from sectionMain
            usedSection, truekey = self.sectionMain, self.mainkey[key]
        else:
            print("Unidentified key for value {}:{}, skipping.".format(key, value))
            return
        
        if(isinstance(value, (str, unicode))):
            usedSection.writeString(truekey, value);
        elif(isinstance(value, bool)):
            usedSection.writeBool(truekey, value);
        elif(isinstance(value, int)):
            usedSection.writeInt(truekey, value);
        else:
            print("Unknown type {} of value {}, can't write to chosen section.".format(type(value), value))
    
    @property
    def currentOMObject(self):
        if(hasattr(BigWorld, "om")):
            om_data = BigWorld.om
            return om_data
        else:
            print("OM data not available ATM; resorting to default values.")
            return None
    
    @staticmethod
    def openXMLConfig(fullpath):
        sectionMain = ResMgr.openSection(fullpath)
        return sectionMain
        
    def retrieveProfileSettings(self, xmlConfigObj):
        if xmlConfigObj:
            configs = []
            for name, section in xmlConfigObj:
                profileCtx = (self.configCtx, 'models/' + name)
                configs.append({"name": name, 
                                "enabled": self.readValueFromSection(section, "enabled", bool, sectionCtx=profileCtx, default=False), 
                                "swapNPC": self.readValueFromSection(section, "swapNPC", bool, sectionCtx=profileCtx, default=False),
                                "useWhitelist": self.readValueFromSection(section, "useWhitelist", bool, sectionCtx=profileCtx, default=True),
                                "whitelist": _multispace_regex.sub(" ", self.readValueFromSection(section, "whitelist", str, sectionCtx=profileCtx, default="")),
                                "camouflageID": self.readValueFromSection(section, "camouflageID", int, sectionCtx=profileCtx, default=0),
                                "paintID": self.readValueFromSection(section, "paintID", int, sectionCtx=profileCtx, default=0)
                              })
            return configs
        else:
            print("Error @retrieveProfileSettings: xmlConfigObj is not available.")
            return []
    
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
                return section.readString(valuename)
            elif(valuetype == float):
                return section.readFloat(valuename, default)
            elif(valuetype == (tuple, int)):
                return _xml.readTupleOfInts(sectionCtx, section, valuename, tuplesize)
            elif(valuetype == (tuple, float)):
                return _xml.readTupleOfFloats(sectionCtx, section, valuename, tuplesize)
            else:
                raise ValueError("Unknown type {} set.".format(valuetype))
        else:
            return default
    
    def receiveStringConfigAtPy(self, strconf):
        if self._isDAAPIInited():
            try:
                jsondata = json.loads(strconf)
            except Exception as e:
                print("Error while parsing json: ", e)
                return
            #print("Received object:", jsondata)
            #print("List available function: ", [func for func in dir(self.sectionMain) if callable(func)])
            #return
            model_data = jsondata.pop("listProfileObjects", [])
            sectiondict = {k: v for k, v in _xml.getChildren(self.configCtx, self.sectionMain, 'models')} # convert list to dictionary
            for modelconf in model_data:
                # write the modified values
                pname = modelconf.pop("name")
                xmlname = 'models/' + str(pname)
                if(not self.sectionMain.has_key(xmlname) or pname not in sectiondict): # new config, create and update the sectiondict again
                    print("XML name used for createSection: {} {}".format(xmlname, type(xmlname)))
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
        else:
            jsondata = None
    
    def getStringConfigFromPy(self):
        om, config = self.currentOMObject, dict()
        config['affectHangar'] = getattr(om, 'affectHangar', False)
        config['useUMLSound'] = getattr(om, 'useUMLSound', False)
        config['MOErank'] = getattr(om, 'MOErank', -1)
        # convert later
        config['listProfileObjects'] = self.retrieveProfileSettings(self.sectionMainModel)
        config['remodelsFilelist'] = self.readValueFromSection(self.sectionMeta, "configLib", str, sectionCtx=None, default="placeholder_list_of_libs")
        return json.dumps(config)
    
    def getVehicleSelectorDataFromPy(self):
        if(self.vehicleSelectorData is None):
            roman_conv = {"I": 1, "II": 2, "III": 3, "IV": 4, "V": 5, "VI": 6, "VII": 7, "VIII": 8, "IX": 9, "X": 10}
            self.vehicleSelectorData = {
                "nations": ["Any"] + sorted(list(self._nation_data.keys())),
                "types": ["Any"] + sorted(list(self._type_data.keys())),
                "tiers": ["Any"] + sorted(list(self._tier_data.keys()), key=lambda s: roman_conv.get(s.replace("Tier_", ""), 99))
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
            print("KeyError happened for tank name {:s}".format(name))
            return "#Error#"
       
    def removeProfileAtPy(self, profilename):
        profilexmlname = 'models/' + profilename
        self.sectionMain.deleteSection(profilexmlname)
        
    
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