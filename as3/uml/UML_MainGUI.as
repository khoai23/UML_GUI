package uml
{
   import net.wg.infrastructure.base.AbstractWindowView;
   import flash.utils.Dictionary;
   import flash.events.Event;
   import flash.text.TextFieldAutoSize;
   import scaleform.clik.events.ListEvent;
   import scaleform.clik.events.FocusHandlerEvent;
   import scaleform.gfx.TextFieldEx;
   import scaleform.clik.events.ButtonEvent;
   import scaleform.clik.controls.ScrollingList;
   //import scaleform.clik.controls.TextInput;
   import scaleform.clik.core.UIComponent;
   import scaleform.clik.data.DataProvider;
   import mx.utils.StringUtil;

   import net.wg.gui.components.controls.CheckBox;
   import net.wg.gui.components.controls.DropdownMenu;
   import net.wg.gui.components.controls.TextInput;
	import net.wg.gui.components.controls.LabelControl;
   import net.wg.gui.components.controls.SoundButtonEx;
   import net.wg.gui.components.controls.ScrollingListPx;
   import net.wg.gui.components.controls.SoundListItemRenderer;
   import net.wg.infrastructure.events.ListDataProviderEvent;
   import net.wg.gui.components.controls.ScrollBar;
	import net.wg.gui.components.controls.UILoaderAlt;
   
   import uml.UML_Profile

   
   public class UML_MainGUI extends AbstractWindowView
   {
	  
	  public var moe_selector : DropdownMenu;
	  public var affect_hangar : CheckBox;
	  protected var use_UML_sound : CheckBox;

	  public var apply_button : SoundButtonEx;
	  public var reload_button : SoundButtonEx;
	  
	  public var remodels_filelist_label: LabelControl;
	  public var remodels_filelist: TextInput;
	  
	  internal var isStatic: Boolean = true;
	  // dynamic scrollable list component
	  public var profile_list : ScrollingListPx;
	  // static click-to-move component
	  public var forward_btn : SoundButtonEx;
	  public var backward_btn : SoundButtonEx;
	  public var profile_selector : DropdownMenu;
	  public var current_profile_name : LabelControl;
	  public var current_profile_enable : CheckBox;
	  public var current_profile_swapNPC : CheckBox;
	  public var current_profile_usewhitelist : CheckBox;
	  public var current_profile_target : TextInput;
	  public var current_profile_target_help : LabelControl;
	  public var current_profile_camo : DropdownMenu;
	  public var current_profile_camo_help : LabelControl;
	  public var current_profile_paint : DropdownMenu;
	  public var current_profile_paint_help : LabelControl;
	  public var delete_profile : SoundButtonEx;
	  
	  
	  public var help_vehicle_selector : LabelControl;
	  public var vehicle_nations : DropdownMenu;
	  public var vehicle_type : DropdownMenu;
	  public var vehicle_tier : DropdownMenu;
	  public var vehicle_selector : DropdownMenu;
	  public var vehicle_profile_field : TextInput;
	// button to add to the profile list or whitelist.
	  public var add_profile_btn : SoundButtonEx;
	  public var add_whitelist_btn : SoundButtonEx;
	  
	  // test
	  //public var profileIcon : UILoaderAlt
	  //protected var current_profile_index : Number = 0;
	  protected var list_profile_objects : Array;
	  protected var camo_paint_data : Object;
	  
      public var receiveStringConfigAtPy : Function = null; // this will receive config data from swf to python
	  public var getStringConfigFromPy : Function = null;	// this will get config data from python to swf
	  public var getVehicleSelectorDataFromPy : Function = null; // this will get permanent vehicle categories (nation, class, tier)
	  public var loadVehiclesWithCriteriaFromPy : Function = null; // this will load the list of vehicles fitting the filter above
	  public var loadVehicleProfileFromPy : Function = null;	  // this will convert the proper name into the accompanying text input
	  public var removeProfileAtPy : Function = null; // this will purge the profile on Python / XML end
	  public var loadCamoPaintDataFromPy : Function = null; // this will load the needed data to camo/paint dropdown

	  public function UML_MainGUI() {
		 super();
	  }
	  
	  override protected function onPopulate() : void {
		 super.onPopulate();
		 this.width = 800;
		 this.height = 400;
		 
		 this.moe_selector = createDropdown(35, 10);
		 this.moe_selector.dataProvider = new DataProvider(["Default MOE", "No MOE", "1 MOE", "2 MOE", "3 MOE"]);
		 
		 this.affect_hangar = createCheckbox("View UML in Hangar", 35, 35);
		 this.use_UML_sound = createCheckbox("Use UML sounds", 200, 35);
		 
		 this.apply_button = createButton("Apply", this.width - 200, this.height - 35);
		 this.reload_button = createButton("Reload", this.width - 385, this.height - 35);
		 this.apply_button.addEventListener(ButtonEvent.CLICK, this.sendStringConfigFromAS);
		 this.reload_button.addEventListener(ButtonEvent.CLICK, this.setStringConfigToAS); 
		 
		this.remodels_filelist_label = createLabel("Base Remodel files:", 325, 35)
		this.remodels_filelist = createTextInput("remodel_filelist_placeholder", 430, 30);
		
		//var mock_data : DataProvider = new DataProvider([{nation_name: "china", profile_name: "Ch01_Type59"}, {nation_name: "UML", profile_name: "Edweird_T-55A"}]);
		this.createProfileList();
		 
		 // update the state after initiation.
		 this.setStringConfigToAS();
	  }
	  
	  internal function createProfileList() : void {
		// try to create a profile list
		if(this.isStatic) {
			// button for forward/backward around the profile selector
			this.backward_btn = createButton("<", 35, 65, true);
			this.forward_btn = createButton(">", 205, 65, true);
			
			// menu to select profile to edit
			this.profile_selector = this.addChild(App.utils.classFactory.getComponent("DropdownMenuUI", DropdownMenu, 
					{ "x": 65, "y": 62, "itemRenderer": App.utils.classFactory.getClass("DropDownListItemRendererSound")})) as DropdownMenu
			this.profile_selector.dropdown = "DropdownMenu_ScrollingList";
			//this.profile_selector.dataProvider = new DataProvider(["option1", "option2"]);
			
			// format: profile name (label) - enable - whitelist
		   //this.profile_selector.dataProvider.invalidate();
		   this.current_profile_name = createLabel("profile_placeholder", 35, 105);
		   this.current_profile_name.autoSize = TextFieldAutoSize.LEFT;
		   this.current_profile_name.toolTip = "The full name of the profile.";
		   this.current_profile_target_help = createLabel("Enabled profiles:", 35 + 125, 105);
		   this.current_profile_target = createTextInput("whitelist_placeholder", 35 + 225, 102);
		   this.current_profile_enable = createCheckbox("Enabled", 35, 105 + 20);
		   this.current_profile_swapNPC = createCheckbox("Model swap NPC", 35 + 125, 105 + 20);
		   this.current_profile_camo_help = createLabel("Camouflage ID:", 35 + 125, 105 + 40);
		   
		   this.current_profile_camo = createDropdown(35 + 225, 102 + 40);
		   this.current_profile_paint_help = createLabel("Paint ID:", 35 + 125, 105 + 60);
		   this.current_profile_paint = createDropdown(35 + 225, 102 + 60);
		   this.delete_profile = createButton("Delete this Profile", 35 + 175, 105 + 85, true);
		   this.populatePaintCamo();
		   
		   // adding appropriate listeners
			this.forward_btn.addEventListener(ButtonEvent.CLICK, this.forwardProfileIndex);
			this.backward_btn.addEventListener(ButtonEvent.CLICK, this.backwardProfileIndex);
			this.profile_selector.addEventListener(ListEvent.INDEX_CHANGE, this.loadProfileAtCurrentIndex);
			// this.profile_selector.dataProvider = new DataProvider(["mock1", "mock2"]);
		   
			this.current_profile_enable.addEventListener(ButtonEvent.CLICK, this.onSetEnableProfile);
			this.current_profile_swapNPC.addEventListener(ButtonEvent.CLICK, this.onSetEnableProfileForNPC);
		    this.current_profile_target.addEventListener(FocusHandlerEvent.FOCUS_OUT, this.onWhitelistChange);
		    this.current_profile_camo.addEventListener(ListEvent.INDEX_CHANGE, this.onCamoChange);
		    this.current_profile_paint.addEventListener(ListEvent.INDEX_CHANGE, this.onPaintChange);
			this.delete_profile.addEventListener(ButtonEvent.CLICK, this.removeProfile);
			
			// adding the concerning VehicleSelector panel
			this.createVehicleSelector(35 + 385, 65);
		}
		else {
			// not working ATM; this version is interactable but do not display
			this.profile_list = addChild(App.utils.classFactory.getComponent(App.utils.classFactory.getClassName(ScrollingListPx), ScrollingListPx, {
				"x": 35, "y": 50, "width": this.width - 75, "height": this.height - 115, "itemRenderer": UML_Profile, "scrollBar": "ScrollBar", "scrollPosition": 0
			})) as ScrollingListPx;
		   this.profile_list.selectedIndex = -1;
		   this.profile_list.dataProvider.invalidate();
		   this.profile_list.visible = true;
		}
	  }
	  
	  internal function populatePaintCamo() : void {
		this.camo_paint_data = this.loadCamoPaintDataFromPy();
		// update with Remove & No change (-1, 0)
		this.camo_paint_data["camoName"].unshift("Remove", "No change");
		this.camo_paint_data["paintName"].unshift("Remove", "No change");
		this.camo_paint_data["camoID"].unshift(-1, 0);
		this.camo_paint_data["paintID"].unshift(-1, 0);
		
		this.current_profile_camo.dataProvider = new DataProvider(this.camo_paint_data["camoName"]);
		this.current_profile_paint.dataProvider = new DataProvider(this.camo_paint_data["paintName"]);
		this.current_profile_camo.invalidateData();
		this.current_profile_paint.invalidateData();
		this.current_profile_camo.selectedIndex = 1; // default to no changes
		this.current_profile_paint.selectedIndex = 1;
	  }
	  
	  internal function createVehicleSelector(x: Number, y: Number) : void {
		// multiple dropdown list concerning nation-class-tier-vehicle to show the corresponding profile name
		this.help_vehicle_selector = createLabel("Vehicle Selector", x, y);
		this.vehicle_nations = createDropdown(x, y + 25);
		this.vehicle_type = createDropdown(x + 135, y + 25);
		this.vehicle_tier = createDropdown(x, y + 50);
		this.vehicle_selector = createDropdown(x + 135, y + 50);
		this.vehicle_profile_field = createTextInput("vehicle_profile_name", x + 60, y + 75);
		// button to add to the profile list or whitelist.
		this.add_profile_btn = createButton("Add as new Profile", x + 15, y + 100, true);
		this.add_whitelist_btn = createButton("Add to Whitelist", x + 15 + 135, y + 100, true);
		
		var vsdata : Object = this.getVehicleSelectorDataFromPy();
		this.vehicle_nations.dataProvider = new DataProvider(vsdata["nations"]);
		this.vehicle_type.dataProvider = new DataProvider(vsdata["types"]);
		this.vehicle_tier.dataProvider = new DataProvider(vsdata["tiers"]);
		// this.vehicle_selector.dataProvider = new DataProvider(vsdata["tier"]);
		this.vehicle_nations.selectedIndex = 0;
		this.vehicle_type.selectedIndex = 0;
		this.vehicle_tier.selectedIndex = 0;
		
		// add all the necessary handler
		this.vehicle_nations.addEventListener(ListEvent.INDEX_CHANGE, this.loadVehiclesWithCriteriaToAS);
		this.vehicle_type.addEventListener(ListEvent.INDEX_CHANGE, this.loadVehiclesWithCriteriaToAS);
		this.vehicle_tier.addEventListener(ListEvent.INDEX_CHANGE, this.loadVehiclesWithCriteriaToAS);
		this.vehicle_selector.addEventListener(ListEvent.INDEX_CHANGE, this.loadVehicleProfileToAS);
		this.add_profile_btn.addEventListener(ButtonEvent.CLICK, this.addNewProfile);
		this.add_whitelist_btn.addEventListener(ButtonEvent.CLICK, this.addProfileToWhitelist);
	  }
	  
	  override protected function onDispose() : void
	  {
        this.apply_button.removeEventListener(ButtonEvent.CLICK, this.sendStringConfigFromAS);
		this.reload_button.removeEventListener(ButtonEvent.CLICK, this.setStringConfigToAS);
		if(this.isStatic) {
			this.forward_btn.removeEventListener(ButtonEvent.CLICK, this.forwardProfileIndex);
			this.backward_btn.removeEventListener(ButtonEvent.CLICK, this.backwardProfileIndex);
			this.profile_selector.removeEventListener(ListEvent.INDEX_CHANGE, this.loadProfileAtCurrentIndex);
			this.current_profile_enable.removeEventListener(ButtonEvent.CLICK, this.onSetEnableProfile);
		    this.current_profile_target.removeEventListener(ListEvent.INDEX_CHANGE, this.onWhitelistChange);
		    this.current_profile_camo.removeEventListener(ListEvent.INDEX_CHANGE, this.onCamoChange);
		    this.current_profile_paint.removeEventListener(ListEvent.INDEX_CHANGE, this.onPaintChange);
			
			this.vehicle_nations.removeEventListener(ListEvent.INDEX_CHANGE, this.loadVehiclesWithCriteriaToAS);
			this.vehicle_type.removeEventListener(ListEvent.INDEX_CHANGE, this.loadVehiclesWithCriteriaToAS);
			this.vehicle_tier.removeEventListener(ListEvent.INDEX_CHANGE, this.loadVehiclesWithCriteriaToAS);
			this.vehicle_selector.removeEventListener(ListEvent.INDEX_CHANGE, this.loadVehicleProfileToAS);
			this.add_profile_btn.removeEventListener(ButtonEvent.CLICK, this.addNewProfile);
			this.add_whitelist_btn.removeEventListener(ButtonEvent.CLICK, this.addProfileToWhitelist);
		}
		//this.profile_list.dataProvider.cleanUp();
		//this.profile_list = null;
		super.onDispose();
	  }
	  
	  // interaction with remodel lists function
	  public function forwardProfileIndex() : void {
		 //DebugUtils.LOG_WARNING("forwardProfiles called");
		 if(this.profile_selector.selectedIndex < (this.list_profile_objects.length-1))
			this.profile_selector.selectedIndex ++; 
	  }
	  
	  public function backwardProfileIndex() : void {
		 //DebugUtils.LOG_WARNING("backwardProfiles called");
		 if(this.profile_selector.selectedIndex > 0)
			this.profile_selector.selectedIndex --; 
	  }
	  
	  internal function loadProfileAtCurrentIndex() : void {
	    var current_idx : Number = this.profile_selector.selectedIndex;
		//DebugUtils.LOG_WARNING("loadProfileAtCurrentIndex called for idx:" + String(current_idx));
		// if topmost, disable backward; if at end, disable forward
		this.backward_btn.enabled = current_idx > 0;
		this.forward_btn.enabled = current_idx < (this.list_profile_objects.length-1);
		// load respective data into components
		var currentProfile : Object = this.list_profile_objects[current_idx];
		this.current_profile_name.text = currentProfile["name"];
		this.current_profile_enable.selected = currentProfile["enabled"];
		this.current_profile_swapNPC.selected = currentProfile["swapNPC"];
		if(currentProfile["useWhitelist"]) {
			this.current_profile_target.text = currentProfile["whitelist"];
		} else {
			this.current_profile_target.text = ""
		}
		this.current_profile_camo.selectedIndex = this.camo_paint_data["camoID"].indexOf(currentProfile["camouflageID"]);
		this.current_profile_paint.selectedIndex = this.camo_paint_data["paintID"].indexOf(currentProfile["paintID"]);
	  }
	  
	  internal function onSetEnableProfile() : void {
		this.list_profile_objects[this.profile_selector.selectedIndex]["enabled"] = this.current_profile_enable.selected;
	  }
	  
	  internal function onSetEnableProfileForNPC() : void {
		this.list_profile_objects[this.profile_selector.selectedIndex]["swapNPC"] = this.current_profile_swapNPC.selected;
	  }
	  
	  internal function onWhitelistChange() : void {
		var whitelist : String = StringUtil.trim(this.current_profile_target.text);
		if(whitelist == "") {
			this.list_profile_objects[this.profile_selector.selectedIndex]["useWhitelist"] = false;
		} else {
			this.list_profile_objects[this.profile_selector.selectedIndex]["useWhitelist"] = true;
			this.list_profile_objects[this.profile_selector.selectedIndex]["whitelist"] = whitelist;
		}
	  }
	  
	  internal function onCamoChange() : void {
		// retrieve matching ID from camoID
		this.list_profile_objects[this.profile_selector.selectedIndex]["camouflageID"] = this.camo_paint_data["camoID"][this.current_profile_camo.selectedIndex];
	  }
	  
	  internal function onPaintChange() : void {
		this.list_profile_objects[this.profile_selector.selectedIndex]["paintID"] = this.camo_paint_data["paintID"][this.current_profile_paint.selectedIndex];
	  }
	  
	  internal function loadVehiclesWithCriteriaToAS() : void {
		// attempt to load vehicles using nation, type and tier filtering
		var vehicles : Array = this.loadVehiclesWithCriteriaFromPy(this.vehicle_nations.selectedIndex, this.vehicle_type.selectedIndex, this.vehicle_tier.selectedIndex);
		this.vehicle_selector.dataProvider = new DataProvider(vehicles);
		this.vehicle_selector.selectedIndex = 0;
		this.loadVehicleProfileToAS();
	  }
	  
	  internal function loadVehicleProfileToAS() : void {
		// on clicking a vehicle within vehicle_selector, change the corresponding TextInput to the profile name
		if(this.vehicle_selector.selectedIndex == -1) // not selected
			this.vehicle_profile_field.text = "vehicle_profile_name"
		else
			this.vehicle_profile_field.text = this.loadVehicleProfileFromPy(this.vehicle_selector.dataProvider[this.vehicle_selector.selectedIndex]);
	  }
	  
	  internal function addNewProfile() : void {
	    if(this.vehicle_profile_field.text == "") return // do nothing if profile name is blank
		
		var profile_index_if_exist : Number = -1;
		for(var i:Number = 0; i < 0; i++) if(this.list_profile_objects[i]["name"] == this.vehicle_profile_field.text) { profile_index_if_exist = i; break; }
		
		if(profile_index_if_exist >= 0) {// if already exist, jump to profile instead of creating new
			this.profile_selector.selectedIndex = profile_index_if_exist;
			return
		} else { // create new object at the end and jump into it.
			var newProfile : Object = {"name": this.vehicle_profile_field.text, "enabled": false, "useWhitelist": true, "whitelist": "", "camouflageID": 0, "paintID": 0};
			this.list_profile_objects.push(newProfile);
			this.reloadProfileSelector();
			this.profile_selector.selectedIndex = this.list_profile_objects.length - 1;
		}
	  }
	  
	  internal function removeProfile() : void {
		var remove_index : Number = this.profile_selector.selectedIndex;
		// remove on Py side
		this.removeProfileAtPy( this.list_profile_objects[remove_index]["name"] );
		// remove on AS side 
		this.list_profile_objects.splice(remove_index, 1);
		this.reloadProfileSelector();
		if(remove_index >= this.profile_selector.dataProvider.length) { // if the removed index is last, reset to first.TODO Maybe reset to last instead?
			this.profile_selector.selectedIndex = 0;
		}
	  }
	  
	  internal function addProfileToWhitelist() : void {
		// on clicking a vehicle within vehicle_selector, change the corresponding TextInput to the profile name
		var current_whitelist : String = StringUtil.trim(this.current_profile_target.text);
		var profile_text : String = this.vehicle_profile_field.text;
		if(current_whitelist == "")
			this.current_profile_target.text = profile_text;
		else if(current_whitelist.indexOf(profile_text) < 0) // only add when profile not exist in whitelist
			this.current_profile_target.text = current_whitelist + ", " + profile_text;
		// call the update function for the focus out as well
		this.onWhitelistChange();
	  }
	  
	  internal function addProfileAsParent(): void {
		// TODO as option for further customization of profiles
	  }
	  
	  public function sendStringConfigFromAS() : void { // paired with receiveStringConfig
		  var dict : Object = { "affectHangar": this.affect_hangar.selected,
								"useUMLSound": this.use_UML_sound.selected,
								"remodelsFilelist": this.remodels_filelist.text,
								"MOErank": (this.moe_selector.selectedIndex - 1),
								"listProfileObjects": this.list_profile_objects };
          this.receiveStringConfigAtPy(App.utils.JSON.encode(dict))
	  }
	  
	  internal function reloadProfileSelector() : void {
		  var profile_names : Array = []
		  for(var i:int=0; i<this.list_profile_objects.length; i++) { profile_names[i] = this.list_profile_objects[i]["name"]; }
		  this.profile_selector.dataProvider = new DataProvider(profile_names);
		  this.profile_selector.invalidateData();
	  }
	  
	  public function setStringConfigToAS() : void { // paired with getStringConfig
		  var dict : Object = App.utils.JSON.decode(this.getStringConfigFromPy());
		  // set flags
		  this.affect_hangar.selected = dict["affectHangar"];
		  this.use_UML_sound.selected = dict["useUMLSound"];
		  this.remodels_filelist.text = dict["remodelsFilelist"]
		  // update profile list & index
		  if(this.isStatic) {
			  this.list_profile_objects = dict["listProfileObjects"]
			  this.reloadProfileSelector();
			  this.profile_selector.selectedIndex = 0;
			  this.loadProfileAtCurrentIndex();
		  }
		  // update current MOE rank; auto is -1 and goes from 0-3, therefore we can simply +1 before and after
		  this.moe_selector.selectedIndex = dict["MOErank"] + 1;
      }
	  
	  internal function createCheckbox(label: String, x: Number, y: Number) : CheckBox {
		return addChild(App.utils.classFactory.getComponent("CheckBox", CheckBox, { "x": x, "y": y, "label": label, "selected": false })) as CheckBox;
	  }
	  
	  internal function createButton(label: String, x: Number, y: Number, dynamicSizeByText: Boolean = false) : SoundButtonEx {
		return addChild(App.utils.classFactory.getComponent("ButtonNormal", SoundButtonEx, { "x": x, "y": y, "label": label,
				"dynamicSizeByText": dynamicSizeByText })) as SoundButtonEx;
	  }
	  
	  internal function createTextInput(lbltext: String, x: Number, y: Number) : TextInput {
		var textInput : TextInput = addChild(App.utils.classFactory.getComponent("TextInput", TextInput, { "x": x, "y": y, "text": lbltext })) as TextInput;
		TextFieldEx.setNoTranslate(textInput.textField, true);
		return textInput;
	  }
	  
	  internal function createLabel(lbltext: String, x: Number, y: Number) : LabelControl {
		return addChild(App.utils.classFactory.getComponent("LabelControl", LabelControl, { "x": x, "y": y, "autoSize": true, "text": lbltext })) as LabelControl;
	  }
	  
	  internal function createDropdown(x: Number, y: Number) : DropdownMenu {
		var dropdown : DropdownMenu = addChild(App.utils.classFactory.getComponent("DropdownMenuUI", DropdownMenu, { "x": x, "y": y, "itemRenderer": App.utils.classFactory.getClass("DropDownListItemRendererSound")
			})) as DropdownMenu;
		dropdown.dropdown = "DropdownMenu_ScrollingList";
		return dropdown
	  }
	}
}