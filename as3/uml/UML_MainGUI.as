package uml
{
   import net.wg.infrastructure.base.AbstractWindowView;
   import flash.utils.Dictionary;
   import flash.utils.getQualifiedClassName;
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
	  internal var _dateObject: Date = new Date();
	  
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
	  public var toggle_show_ignore: CheckBox;
	  
	  public var current_profile_name : TextInput;
	  public var current_profile_enable : CheckBox;
	  public var current_profile_swapNPC : CheckBox;
	  public var current_profile_ignore: CheckBox;
	  public var current_profile_usewhitelist : CheckBox;
	  public var current_profile_target : TextInput;
	  public var current_profile_target_help : LabelControl;
	  public var current_profile_camo : DropdownMenu;
	  public var current_profile_camo_help : LabelControl;
	  public var current_profile_paint : DropdownMenu;
	  public var current_profile_paint_help : LabelControl;
	  public var current_profile_style : DropdownMenu;
	  public var current_profile_style_help : LabelControl;
	  public var current_profile_configString : TextInput;
	  public var current_profile_configString_help : LabelControl;
	  public var delete_profile : SoundButtonEx;
	  public var use_hangar_vehicle : SoundButtonEx;
	  
	  public var hybrid_help : LabelControl;
	  public var profile_hull_help : LabelControl;
	  public var profile_hull : TextInput;
	  public var profile_chassis_help : LabelControl;
	  public var profile_chassis : TextInput;
	  public var profile_turret_help : LabelControl;
	  public var profile_turret : TextInput;
	  public var profile_gun_help : LabelControl;
	  public var profile_gun : TextInput;
	  
	  // vehicle selector
	  public var help_vehicle_selector : LabelControl;
	  public var vehicle_nations : DropdownMenu;
	  public var vehicle_type : DropdownMenu;
	  public var vehicle_tier : DropdownMenu;
	  public var vehicle_selector : DropdownMenu;
	  public var vehicle_profile_field : TextInput;
	// button to add to the profile list or whitelist.
	  public var add_profile_btn : SoundButtonEx;
	  public var add_whitelist_btn : SoundButtonEx;
	  public var profile_with_parent_field : TextInput;
	  public var add_profile_as_parent_btn : SoundButtonEx;
	 
	  // debug component
	  public var debug_exec_field : TextInput;
	  public var debug_eval_field : TextInput;
	  public var debug_btn : SoundButtonEx;
	 
	  // forcedCustomization component
	  public var help_forced_customization : LabelControl;
	  public var target_customization : DropdownMenu;
	  public var first_emblem : DropdownMenu;
	  public var second_emblem : DropdownMenu;
	  public var force_both_emblem : CheckBox;
	  public var summer_camo : DropdownMenu;
	  public var winter_camo : DropdownMenu;
	  public var desert_camo : DropdownMenu;
	  public var summer_paint : DropdownMenu;
	  public var winter_paint : DropdownMenu;
	  public var desert_paint : DropdownMenu;
	  
	 
	  // test
	  //public var profileIcon : UILoaderAlt
	  //protected var current_profile_index : Number = 0;
	  protected var list_all_profile_objects : Array;
	  protected var list_ignore_profiles : Array;
	  protected var list_profile_objects : Array;
	  protected var list_styles : Array = null;
	  protected var customization_data : Object;
	  protected var forced_customization : Array = null;
	  
	  public var getIsDebugUMLFromPy : Function = null; // this will get UML's debug to decide showing debug fields (eval, exec) or not
	  public var forcedCustomizationIsAvailableAtPy : Function = null; // this will check if forcedCustomization module exist or not
      public var receiveStringConfigAtPy : Function = null; // this will receive config data from swf to python
	  public var getStringConfigFromPy : Function = null;	// this will get config data from python to swf
	  public var getVehicleSelectorDataFromPy : Function = null; // this will get permanent vehicle categories (nation, class, tier)
	  public var loadVehiclesWithCriteriaFromPy : Function = null; // this will load the list of vehicles fitting the filter above
	  public var loadVehicleProfileFromPy : Function = null;	  // this will convert the proper name into the accompanying text input
	  public var removeProfileAtPy : Function = null; // this will purge the profile on Python / XML end
	  public var loadCustomizationDataFromPy : Function = null; // this will load the needed data to camo/paint dropdown
	  public var getHangarVehicleFromPy : Function = null; // this will retrieve the needed hangar vehicle to support addHangarVehicleToWhitelist
	  public var getPossibleStyleOfProfileFromPy : Function = null; // this will retrieve the needed profile style from the vehicle obj.
	  public var debugEvalCommand : Function = null; // eval and exec codes directly from GUI
	  public var checkIsValidWoTVehicleAtPy : Function = null // check valid code to create hybrids

	  public function UML_MainGUI() {
		 super();
	  }
	  
	  override protected function onPopulate() : void {
		 super.onPopulate();
		 
		 this.moe_selector = createDropdown(35, 10);
		 this.moe_selector.dataProvider = new DataProvider(["Default MOE", "No MOE", "1 MOE", "2 MOE", "3 MOE"]);
		 
		 this.affect_hangar = createCheckbox("View UML in Hangar", 35, 35);
		 this.use_UML_sound = createCheckbox("Use UML sounds", 200, 35);
		 
		this.remodels_filelist_label = createLabel("Base Remodel files:", 325, 35)
		this.remodels_filelist = createTextInput("remodel_filelist_placeholder", 430, 30);
		
		//var mock_data : DataProvider = new DataProvider([{nation_name: "china", profile_name: "Ch01_Type59"}, {nation_name: "UML", profile_name: "Edweird_T-55A"}]);
		var sizeObject : Object = this.createProfileList(35, 65);
		
		// set dynamic width-height depending on possible options; adding components relying on those fields as needed after.
		this.width = sizeObject.width + 35;// 800;
		this.height = sizeObject.height + 50;//400;
		 
		if(this.getIsDebugUMLFromPy()) { 
			// debug
			this.debug_exec_field = createTextInput("debug_exec_field", 32,  this.height - 35);
			this.debug_eval_field = createTextInput("debug_eval_field", 162,  this.height - 35);
			this.debug_btn = createButton("Debug", 295,  this.height - 35, true);
			this.debug_btn.addEventListener(ButtonEvent.CLICK, this.sendDebugCmdFromAS);
		}

		this.apply_button = createButton("Apply", this.width - 200, this.height - 35);
		this.reload_button = createButton("Reload", this.width - 385, this.height - 35);
		this.apply_button.addEventListener(ButtonEvent.CLICK, this.sendStringConfigFromAS);
		this.reload_button.addEventListener(ButtonEvent.CLICK, this.setStringConfigToAS); 
		 
		 // update the state after initiation.
		 this.setStringConfigToAS();
	  }
	  
	  internal function createProfileList(x: Number, y: Number) : Object {
		// try to create a profile list
		var currentX : Number = x;
		var currentY : Number = y;
		if(this.isStatic) {
			// button for forward/backward around the profile selector
			this.backward_btn = createButton("<", 35, 65, true);
			this.forward_btn = createButton(">", 205, 65, true);
			
			// menu to select profile to edit
			//this.profile_selector = this.addChild(App.utils.classFactory.getComponent("DropdownMenuUI", DropdownMenu, 
			//		{ "x": 65, "y": 62, "itemRenderer": App.utils.classFactory.getClass("DropDownListItemRendererSound")})) as DropdownMenu
			//this.profile_selector.dropdown = "DropdownMenu_ScrollingList";
			this.profile_selector = this.createDropdown(65, 65 - 3)
			// ignore list
			this.toggle_show_ignore = createCheckbox("Show ignored profiles", 235, 65);
			//this.profile_selector.dataProvider = new DataProvider(["option1", "option2"]);
			
			// format: profile name (label) - enable - whitelist
			//this.profile_selector.dataProvider.invalidate();
			this.current_profile_name = createTextInput("profile_placeholder", 35, 102);
			this.current_profile_name.editable = false;
			this.current_profile_name.width = 280;
			// this.current_profile_name.autoSize = TextFieldAutoSize.LEFT;
			// this.current_profile_name.toolTip = "The full name of the profile.";
			this.current_profile_target_help = createLabel("Enabled profiles:", 35 + 125, 105 + 20);
			this.current_profile_target = createTextInput("whitelist_placeholder", 35 + 225, 105 + 20 - 3);
			this.current_profile_enable = createCheckbox("Enabled", 35, 105 + 20);
			this.current_profile_swapNPC = createCheckbox("Model swap NPC", 35, 105 + 40);
			this.current_profile_ignore = createCheckbox("Ignore by GUI", 35, 105 + 60);

			this.current_profile_camo_help = createLabel("Camouflage ID:", 35 + 125, 105 + 40);
			this.current_profile_camo = createDropdown(35 + 225, 105 + 40 - 3);
			this.current_profile_camo.width = 180;
			this.current_profile_paint_help = createLabel("Paint ID:", 35 + 125, 105 + 60);
			this.current_profile_paint = createDropdown(35 + 225, 105 + 60 - 3);
			this.current_profile_paint.width = 180;

			this.current_profile_configString_help = createLabel("Config:", 35, 105 + 80)
			this.current_profile_configString = createTextInput("N/A", 35 + 50, 105 + 80 - 3);
			this.current_profile_configString.width = 60;
			this.current_profile_configString.enabled = false;
			this.current_profile_style_help = createLabel("Style:", 35 + 125, 105 + 80);
			this.current_profile_style = createDropdown(35 + 225, 102 + 80);
			this.use_hangar_vehicle = createButton("Add hangar vehicle to Whitelist", 35 + 20, 105 + 105, true);
			this.delete_profile = createButton("Delete this Profile", 35 + 230, 105 + 105, true);
			this.populatePaintCamo();
			
			this.hybrid_help = createLabel("Hybrid Vehicle Configuration", 35, 235)
			this.profile_chassis_help = createLabel("Chassis:", 35, 235 + 20);
			this.profile_chassis = createTextInput("N/A", 35 + 50, 235 + 20 - 3);
			this.profile_hull_help = createLabel("Hull:", 35 + 185, 235 + 20);
			this.profile_hull = createTextInput("N/A", 35 + 185 + 35, 235 + 20 - 3);
			this.profile_turret_help = createLabel("Turret:", 35, 235 + 40);
			this.profile_turret = createTextInput("N/A", 35 + 50, 235 + 40 - 3);
			this.profile_gun_help = createLabel("Gun:", 35 + 185, 235 + 40);
			this.profile_gun = createTextInput("N/A", 35 + 185 + 35, 235 + 40 - 3);
			this.profile_chassis.enabled = false;

			// adding appropriate listeners
			this.forward_btn.addEventListener(ButtonEvent.CLICK, this.forwardProfileIndex);
			this.backward_btn.addEventListener(ButtonEvent.CLICK, this.backwardProfileIndex);
			this.profile_selector.addEventListener(ListEvent.INDEX_CHANGE, this.loadProfileAtCurrentIndex);
			this.toggle_show_ignore.addEventListener(ButtonEvent.CLICK, this.reloadProfileSelector);
			// this.profile_selector.dataProvider = new DataProvider(["mock1", "mock2"]);

			this.current_profile_enable.addEventListener(ButtonEvent.CLICK, this.onSetEnableProfile);
			this.current_profile_swapNPC.addEventListener(ButtonEvent.CLICK, this.onSetEnableProfileForNPC);
			this.current_profile_ignore.addEventListener(ButtonEvent.CLICK, this.onIgnoreChange);
			this.current_profile_target.addEventListener(FocusHandlerEvent.FOCUS_OUT, this.onWhitelistChange);
			this.current_profile_camo.addEventListener(ListEvent.INDEX_CHANGE, this.onCamoChange);
			this.current_profile_paint.addEventListener(ListEvent.INDEX_CHANGE, this.onPaintChange);
			this.current_profile_style.addEventListener(ListEvent.INDEX_CHANGE, this.onStyleChange);
			this.current_profile_configString.addEventListener(FocusHandlerEvent.FOCUS_OUT, this.onConfigStringChange);
			this.delete_profile.addEventListener(ButtonEvent.CLICK, this.removeProfile);
			this.use_hangar_vehicle.addEventListener(ButtonEvent.CLICK, this.addHangarVehicleToWhitelist);

			this.profile_hull.addEventListener(FocusHandlerEvent.FOCUS_OUT, this.updateHybridParts);
			this.profile_turret.addEventListener(FocusHandlerEvent.FOCUS_OUT, this.updateHybridParts);
			this.profile_gun.addEventListener(FocusHandlerEvent.FOCUS_OUT, this.updateHybridParts);
			// 
			currentX = 35 + 425 // 460
			currentY = 310
			
			// adding the concerning VehicleSelector panel
			currentX = this.createVehicleSelector(currentX, 65);
			
			// adding forcedCustomization section if the mod is available
			if(this.forcedCustomizationIsAvailableAtPy()) {
				currentY = this.createForcedCustomizationSelector(35, currentY);
			}
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
		return {width: currentX, height: currentY};
	  }
	  
	  internal function populatePaintCamo() : void {
		this.customization_data = this.loadCustomizationDataFromPy();
		// update with Remove & No change (-1, 0)
		this.customization_data["camoName"].unshift("Remove", "No change");
		this.customization_data["paintName"].unshift("Remove", "No change");
		this.customization_data["decalName"].unshift("Remove", "No change");
		this.customization_data["camoID"].unshift(-1, 0);
		this.customization_data["paintID"].unshift(-1, 0);
		this.customization_data["decalID"].unshift(-1, 0);
		
		this.current_profile_camo.dataProvider = new DataProvider(this.customization_data["camoName"]);
		this.current_profile_paint.dataProvider = new DataProvider(this.customization_data["paintName"]);
		this.current_profile_camo.invalidateData();
		this.current_profile_paint.invalidateData();
		this.current_profile_camo.selectedIndex = 1; // default to no changes
		this.current_profile_paint.selectedIndex = 1;
	  }
	  
	  internal function createVehicleSelector(x: Number, y: Number) : Number {
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
		// button to add as a new profile
		this.add_profile_as_parent_btn = createButton("Add as Parent to ", x + 20, y + 125, true);
		this.profile_with_parent_field = createTextInput("profile_with_parent_placeholder", x + 135, y + 125 - 2);
		
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
		this.add_profile_as_parent_btn.addEventListener(ButtonEvent.CLICK, this.addNewProfile);
		// this.profile_with_parent_field.addEventListener(FocusHandlerEvent.FOCUS_OUT, this.addNewProfile); // don't need this one
		
		return x + 270; // 650
	  }
	  
	  internal function createForcedCustomizationSelector(x: Number, y: Number): Number {
		// Dropdown list selecting: Target (player, ally, enemy); 
		//							first_emblem, second_emblem; camo set of 3; paint set of 3
		this.help_forced_customization = createLabel("Force Customization", x, y);
		this.target_customization = createDropdown(x + 150, y - 2);
		this.first_emblem = createDropdown(x, y + 23);
		this.second_emblem = createDropdown(x + 130, y + 23);
		this.force_both_emblem = createCheckbox("Force both emblems", x + 260, y + 25);
		this.summer_camo = createDropdown(x, y + 48);
		this.winter_camo = createDropdown(x + 130, y + 48);
		this.desert_camo = createDropdown(x + 260, y + 48);
		this.summer_paint = createDropdown(x, y + 73);
		this.winter_paint = createDropdown(x + 130 , y + 73);
		this.desert_paint = createDropdown(x + 260, y + 73);
		
		// update values to help forced customization
		this.customization_data["sec_camoName"] = this.customization_data["camoName"].concat(); this.customization_data["sec_camoName"].unshift("Same as Summer");
		this.customization_data["sec_paintName"] = this.customization_data["paintName"].concat(); this.customization_data["sec_paintName"].unshift("Same as Summer");
		this.customization_data["sec_decalName"] = this.customization_data["decalName"].concat(); this.customization_data["sec_decalName"].unshift("Same as First");
		this.customization_data["sec_camoID"] = this.customization_data["camoID"].concat(); this.customization_data["sec_camoID"].unshift(-2);
		this.customization_data["sec_paintID"] = this.customization_data["paintID"].concat(); this.customization_data["sec_paintID"].unshift(-2);
		this.customization_data["sec_decalID"] = this.customization_data["decalID"].concat(); this.customization_data["sec_decalID"].unshift(-2);
		
		this.target_customization.dataProvider = new DataProvider(["Player", "Ally", "Enemy"]);
		this.first_emblem.dataProvider = new DataProvider(this.customization_data["decalName"]);
		this.second_emblem.dataProvider = new DataProvider(this.customization_data["sec_decalName"]);
		this.summer_camo.dataProvider = new DataProvider(this.customization_data["camoName"]);
		this.winter_camo.dataProvider = new DataProvider(this.customization_data["sec_camoName"]);
		this.desert_camo.dataProvider = new DataProvider(this.customization_data["sec_camoName"]);
		this.summer_paint.dataProvider = new DataProvider(this.customization_data["paintName"]);
		this.winter_paint.dataProvider = new DataProvider(this.customization_data["sec_paintName"]);
		this.desert_paint.dataProvider = new DataProvider(this.customization_data["sec_paintName"]);
		
		this.target_customization.selectedIndex = 0;
		var customization_data : Object = this.customization_data;
		var _updateCustomizationData : Function = updateCustomizationData;
		// event binding
		this.target_customization.addEventListener(ListEvent.INDEX_CHANGE, this.reloadForcedCustomization);
		this.first_emblem.addEventListener(ListEvent.INDEX_CHANGE, this.updateCustomizationData);
		this.second_emblem.addEventListener(ListEvent.INDEX_CHANGE, this.updateCustomizationData);
		this.force_both_emblem.addEventListener(ButtonEvent.CLICK, this.updateCustomizationData);
		this.summer_camo.addEventListener(ListEvent.INDEX_CHANGE, this.updateCustomizationData);
		this.winter_camo.addEventListener(ListEvent.INDEX_CHANGE, this.updateCustomizationData);
		this.desert_camo.addEventListener(ListEvent.INDEX_CHANGE, this.updateCustomizationData);
		this.summer_paint.addEventListener(ListEvent.INDEX_CHANGE, this.updateCustomizationData);
		this.winter_paint.addEventListener(ListEvent.INDEX_CHANGE, this.updateCustomizationData);
		this.desert_paint.addEventListener(ListEvent.INDEX_CHANGE, this.updateCustomizationData);
		
		return y + 100; // 410
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
			this.current_profile_ignore.removeEventListener(ButtonEvent.CLICK, this.onIgnoreChange);
		    this.current_profile_target.removeEventListener(ListEvent.INDEX_CHANGE, this.onWhitelistChange);
		    this.current_profile_camo.removeEventListener(ListEvent.INDEX_CHANGE, this.onCamoChange);
		    this.current_profile_paint.removeEventListener(ListEvent.INDEX_CHANGE, this.onPaintChange);
			
			this.vehicle_nations.removeEventListener(ListEvent.INDEX_CHANGE, this.loadVehiclesWithCriteriaToAS);
			this.vehicle_type.removeEventListener(ListEvent.INDEX_CHANGE, this.loadVehiclesWithCriteriaToAS);
			this.vehicle_tier.removeEventListener(ListEvent.INDEX_CHANGE, this.loadVehiclesWithCriteriaToAS);
			this.vehicle_selector.removeEventListener(ListEvent.INDEX_CHANGE, this.loadVehicleProfileToAS);
			this.add_profile_btn.removeEventListener(ButtonEvent.CLICK, this.addNewProfile);
			this.add_whitelist_btn.removeEventListener(ButtonEvent.CLICK, this.addProfileToWhitelist);
		
			this.profile_hull.removeEventListener(FocusHandlerEvent.FOCUS_OUT, this.updateHybridParts);
			this.profile_turret.removeEventListener(FocusHandlerEvent.FOCUS_OUT, this.updateHybridParts);
			this.profile_gun.removeEventListener(FocusHandlerEvent.FOCUS_OUT, this.updateHybridParts);
			
			if(this.getIsDebugUMLFromPy()) {
				this.debug_btn.removeEventListener(ButtonEvent.CLICK, this.sendDebugCmdFromAS);
			}
			
			if(this.forcedCustomizationIsAvailableAtPy()) { // currently left unused
				this.target_customization.removeEventListener(ListEvent.INDEX_CHANGE, this.reloadForcedCustomization);
				this.first_emblem.removeEventListener(ListEvent.INDEX_CHANGE, this.updateCustomizationData);
				this.second_emblem.removeEventListener(ListEvent.INDEX_CHANGE, this.updateCustomizationData);
				this.force_both_emblem.removeEventListener(ButtonEvent.CLICK, this.updateCustomizationData);
				this.summer_camo.removeEventListener(ListEvent.INDEX_CHANGE, this.updateCustomizationData);
				this.winter_camo.removeEventListener(ListEvent.INDEX_CHANGE, this.updateCustomizationData);
				this.desert_camo.removeEventListener(ListEvent.INDEX_CHANGE, this.updateCustomizationData);
				this.summer_paint.removeEventListener(ListEvent.INDEX_CHANGE, this.updateCustomizationData);
				this.winter_paint.removeEventListener(ListEvent.INDEX_CHANGE, this.updateCustomizationData);
				this.desert_paint.removeEventListener(ListEvent.INDEX_CHANGE, this.updateCustomizationData);
			}
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
		// if topmost, disable backward; if at end, disable forward
		this.backward_btn.enabled = current_idx > 0;
		this.forward_btn.enabled = current_idx < (this.list_profile_objects.length-1);
		// load respective data into components
		var currentProfile : Object = this.list_profile_objects[current_idx];
		//DebugUtils.LOG_WARNING("loadProfileAtCurrentIndex called for obj:" + String(currentProfile) + " at index " + String(current_idx));
		if("parent" in currentProfile) {
			// custom name and section
			this.current_profile_name.text = "[" + currentProfile["parent"] + "]" + currentProfile["name"];
			this.profile_hull.text = currentProfile["hull"]; this.profile_hull.enabled = true;
			this.profile_turret.text = currentProfile["turret"]; this.profile_turret.enabled = true;
			this.profile_gun.text = currentProfile["gun"]; this.profile_gun.enabled = true;
		} else {
			this.current_profile_name.text = currentProfile["name"];
			this.profile_hull.text = "N/A"; this.profile_hull.enabled = false;
			this.profile_turret.text = "N/A"; this.profile_turret.enabled = false;
			this.profile_gun.text = "N/A"; this.profile_gun.enabled = false;
		}
		this.current_profile_enable.selected = currentProfile["enabled"];
		this.current_profile_swapNPC.selected = currentProfile["swapNPC"];
		this.current_profile_ignore.selected = (this.list_ignore_profiles.indexOf(currentProfile["name"]) >= 0);
		if(currentProfile["useWhitelist"]) {
			this.current_profile_target.text = currentProfile["whitelist"];
		} else {
			this.current_profile_target.text = ""
		}
		this.current_profile_camo.selectedIndex = this.customization_data["camoID"].indexOf(currentProfile["camouflageID"]);
		this.current_profile_paint.selectedIndex = this.customization_data["paintID"].indexOf(currentProfile["paintID"]);
		this.updateStyleOptionInAS(currentProfile["styleSet"], currentProfile["name"]);
		if("configString" in currentProfile) {
			this.current_profile_configString.enabled = true;
			this.current_profile_configString.text = currentProfile["configString"];
		} else {
			this.current_profile_configString.enabled = false;
			this.current_profile_configString.text = "N/A";
		}
	  }
	  
	  internal function onSetEnableProfile() : void {
		this.list_profile_objects[this.profile_selector.selectedIndex]["enabled"] = this.current_profile_enable.selected;
	  }
	  
	  internal function onSetEnableProfileForNPC() : void {
		this.list_profile_objects[this.profile_selector.selectedIndex]["swapNPC"] = this.current_profile_swapNPC.selected;
	  }
	  
	  internal function onIgnoreChange() : void {
		var profile_name : String = this.list_profile_objects[this.profile_selector.selectedIndex]["name"];
		if(this.current_profile_ignore.selected) {
			// set ignore; add this profile name to the list of ignored profile
			this.list_ignore_profiles.push(profile_name);
		} else {
			// unset ignore; remove this profile name from the list (raising log if fail)
			var remove_idx : Number = this.list_ignore_profiles.indexOf(profile_name);
			if(remove_idx < 0) {
				DebugUtils.LOG_WARNING("[UML GUI][AS] Attempt to delete profile name [" + profile_name + 
					"] on list of ignore profiles [" + String(this.list_ignore_profiles) + "]. The operation is void.");
			} else { // remove
				this.list_ignore_profiles.splice(remove_idx, 1);
			}
		}
		// reload profile selector if necessary (ignored profiles are disabled)
		// also update the new profile
		if(!this.toggle_show_ignore.selected) {
			this.reloadProfileSelector(null, true);
		}
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
	  
	  internal function onConfigStringChange() : void {
		// only applies for those with existing configString param
		if("configString" in this.list_profile_objects[this.profile_selector.selectedIndex]) {
			this.list_profile_objects[this.profile_selector.selectedIndex]["configString"] = this.current_profile_configString.text;
		} else {
			DebugUtils.LOG_WARNING("[UML GUI][AS] Attempt to write configString [" + this.current_profile_configString.text + 
					"] on invalid profile name [" + this.current_profile_name.text + "] called. Check if needed.");
		}
	  }
	  
	  internal function onCamoChange() : void {
		// retrieve matching ID from camoID
		this.list_profile_objects[this.profile_selector.selectedIndex]["camouflageID"] = this.customization_data["camoID"][this.current_profile_camo.selectedIndex];
	  }
	  
	  internal function onPaintChange() : void {
		this.list_profile_objects[this.profile_selector.selectedIndex]["paintID"] = this.customization_data["paintID"][this.current_profile_paint.selectedIndex];
	  }
	  
	  internal function onStyleChange() : void {
		if(this.current_profile_style.selectedIndex < 0) {
			// disabled from above for some reason; ignore
			return
		} else if(this.current_profile_style.selectedIndex == 0) {
			this.list_profile_objects[this.profile_selector.selectedIndex]["styleSet"] = "0";
		} else {
			this.list_profile_objects[this.profile_selector.selectedIndex]["styleSet"] = this.list_styles[this.current_profile_style.selectedIndex];
		}
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
		if(this.vehicle_selector.selectedIndex == -1) {// not selected
			this.vehicle_profile_field.text = "vehicle_profile_name";
			this.profile_with_parent_field.text = "profile_with_parent_placeholder";
		} else {
			this.vehicle_profile_field.text = this.loadVehicleProfileFromPy(this.vehicle_selector.dataProvider[this.vehicle_selector.selectedIndex]);
			this.profile_with_parent_field.text =  "hybrid_" + this.vehicle_profile_field.text + "__" + String(_dateObject.time).substring(6); // unique identifier using timestamp
		}
	  }
	  
	  internal function addNewProfile(event: Object) : void {
		var profile_text: String;
		var new_profile : Object;
		if(event.target == this.add_profile_as_parent_btn) { // add a parent profile
			profile_text = this.profile_with_parent_field.text;
			new_profile = {"name": profile_text, "enabled": false, "useWhitelist": true, "whitelist": "", "camouflageID": 0, "paintID": 0, "configString": 9999,
							"parent": this.vehicle_profile_field.text, "hull": this.vehicle_profile_field.text, "turret": this.vehicle_profile_field.text, "gun": this.vehicle_profile_field.text};
		} else { // add as a direct profile
			profile_text =  this.vehicle_profile_field.text
			new_profile = {"name": profile_text, "enabled": false, "useWhitelist": true, "whitelist": "", "camouflageID": 0, "paintID": 0, "configString": 9999};
		}
	
		var profile_index_if_exist : Number = -1;
		for(var i:Number = 0; i < 0; i++) if(this.list_profile_objects[i]["name"] == profile_text) { profile_index_if_exist = i; break; }
		
		if(profile_index_if_exist >= 0) {// if already exist, jump to profile instead of creating new
			this.profile_selector.selectedIndex = profile_index_if_exist;
		} else { // create new object at the end and jump into it.
			this.list_all_profile_objects.push(new_profile);
			this.reloadProfileSelector(null, false);
			this.profile_selector.selectedIndex = this.list_profile_objects.length - 1;
		}
	  }
	  
	  internal function removeProfile() : void {
		var remove_index : Number = this.profile_selector.selectedIndex;
		// remove on Py side
		this.removeProfileAtPy( this.list_profile_objects[remove_index]["name"] );
		// remove on AS side 
		this.list_profile_objects.splice(remove_index, 1);
		// DebugUtils.LOG_WARNING("[UML GUI] debug selected index"
		if(remove_index >= this.profile_selector.dataProvider.length - 1) { // if the removed index is last, reset to first. TODO Maybe reset to last instead?
			this.profile_selector.selectedIndex = 0;
		}
		this.reloadProfileSelector(null, true);
	  }
	  
	  internal function addProfileToWhitelist(event: Object, profile_text: String = null) : void {
		// on clicking a vehicle within vehicle_selector, change the corresponding TextInput to the profile name
		if(profile_text == null) {
			profile_text = this.vehicle_profile_field.text;
		}
		var current_whitelist : String = StringUtil.trim(this.current_profile_target.text);
		// var profile_text : String =  (profile == null) ? this.vehicle_profile_field.text : profile; // if the profile is specified, use profile; else use the one in vehicle_profile_field
		if(current_whitelist == "")
			this.current_profile_target.text = profile_text;
		else if(current_whitelist.indexOf(profile_text) < 0) // only add when profile not exist in whitelist
			this.current_profile_target.text = current_whitelist + ", " + profile_text;
		// call the update function for the focus out as well
		this.onWhitelistChange();
	  }
	  
	  internal function addHangarVehicleToWhitelist() : void {
		// retrieve the hangar vehicle from Py side and add it to whitelist
		this.addProfileToWhitelist(null, this.getHangarVehicleFromPy());
	  }
	  
	  internal function updateStyleOptionInAS(style_index_or_name : String, profile_name : String = null) : void {
	    if( profile_name == null ) { 
			profile_name = this.current_profile_name.text;
			if(profile_name.indexOf("[") >= 0) {
				// parented profile; split by bracketed term (parent)
				profile_name = profile_name.substring(profile_name.indexOf("[") + 1, profile_name.indexOf("]"));
			}
			// profile_name = ("parent" in targeted_profile) ? targeted_profile["parent"] : targeted_profile["name"] ; // always get parent if available
		}
		//DebugUtils.LOG_WARNING("debug: profile_name: " + profile_name);
		this.list_styles = this.getPossibleStyleOfProfileFromPy(profile_name);
		// attempt to parse to number; if not true, try to search in list of possible styles; if not found there either, safeguard to 0 (No style)
		// attempt to convert 
		if(this.list_styles == null) {
			// no style, disable the selector
			this.current_profile_style.enabled = false;
			this.current_profile_style.selectedIndex = -1;
		} else {
			// possible style, update the selector
			var profile_idx : Number = Number(style_index_or_name);
			if(isNaN(profile_idx)) {
				profile_idx = this.list_styles.indexOf(style_index_or_name);
				if(profile_idx == -1) profile_idx = 0;
			}
			this.current_profile_style.enabled = true;
			this.current_profile_style.dataProvider = new DataProvider(this.list_styles);
			this.current_profile_style.selectedIndex = profile_idx;
		}
	  }
	  
	  public function sendStringConfigFromAS() : void { // paired with receiveStringConfig
		  // DebugUtils.LOG_WARNING("Last profile selected to put to OM object: " + String(this.vehicle_selector.selectedIndex))
		  var dict : Object = { "affectHangar": this.affect_hangar.selected,
								"useUMLSound": this.use_UML_sound.selected,
								"remodelsFilelist": this.remodels_filelist.text,
								"MOErank": (this.moe_selector.selectedIndex - 1),
								"lastProfileSelectedIdx": this.profile_selector.selectedIndex,
								"listProfileObjects": this.list_all_profile_objects,
								"ignoreList": this.list_ignore_profiles,
								"forcedCustomization": this.forced_customization
								};
          this.receiveStringConfigAtPy(App.utils.JSON.encode(dict))
	  }
	  
	  internal function reloadProfileSelector(event: Object = null, reload_current_profile: Boolean = true) : void {
		if(this.toggle_show_ignore.selected) {
			// show all profiles
			this.list_profile_objects = this.list_all_profile_objects;
			//DebugUtils.LOG_WARNING("[UML GUI][AS] Debug: entering unfiltered profile @reloadProfileSelector");
		} else {
			// show un-ignored profiles
			this.list_profile_objects = []
			for each(var o : Object in this.list_all_profile_objects) {
				if(this.list_ignore_profiles.indexOf(o["name"]) < 0) { 
					this.list_profile_objects.push(o)
				}
			}
			DebugUtils.LOG_WARNING("[UML GUI][AS] Debug: entering filtered profile @reloadProfileSelector, full count - non-ignore count: " + String(this.list_all_profile_objects.length) + " - " + String(this.list_profile_objects.length));
		}
		var profile_names : Array = []
		for(var i:int=0; i<this.list_profile_objects.length; i++) { 
			profile_names[i] = this.list_profile_objects[i]["name"]; 
		}
		this.profile_selector.dataProvider = new DataProvider(profile_names);
		this.profile_selector.invalidateData();
		if(reload_current_profile) {
			// validate and update index (if too large, snap to first profile)
			if(this.profile_selector.selectedIndex > this.list_profile_objects.length)
				this.profile_selector.selectedIndex = 0;
			this.loadProfileAtCurrentIndex();
		}
	  }
	  
	  public function setStringConfigToAS() : void { // paired with getStringConfig
		  var dict : Object = App.utils.JSON.decode(this.getStringConfigFromPy());
		  // set flags
		  this.affect_hangar.selected = dict["affectHangar"];
		  this.use_UML_sound.selected = dict["useUMLSound"];
		  this.toggle_show_ignore.selected = false;
		  this.remodels_filelist.text = dict["remodelsFilelist"]
		  // update profile list & index to the last selected profile 
		  if(this.isStatic) {
			  this.list_all_profile_objects = dict["listProfileObjects"];
			  this.list_ignore_profiles = dict["ignoreList"];
			  DebugUtils.LOG_WARNING("[UML GUI][AS] Debug: ignoreList: " + String(this.list_ignore_profiles));
			  this.reloadProfileSelector(null, false);
			  this.profile_selector.selectedIndex = dict['lastProfileSelectedIdx'] < this.list_profile_objects.length ? dict['lastProfileSelectedIdx'] : 0; // prevent delete & no applying
			  this.loadProfileAtCurrentIndex();
		  }
		  // update current MOE rank; auto is -1 and goes from 0-3, therefore we can simply +1 before and after
		  this.moe_selector.selectedIndex = dict["MOErank"] + 1;
		  // update forcedCustomization if available
		  this.forced_customization = dict["forcedCustomization"];
		  if(this.forced_customization != null) {
			  // pitfall: if the this.forced_customization dict is set and reload is called, the first selectedIndex change will attempt to reload and end up overwriting subsequent values with unset values (null).
			  // redone the reload fn; the above is no longer true.
			  this.reloadForcedCustomization();
			}
      }
	  
	  public function reloadForcedCustomization() : void {
		//reload_dict = reload_dict == null ? this.forced_customization : reload_dict;
		var target_dict : Object = this.forced_customization[this.target_customization.selectedIndex];
		// DebugUtils.LOG_WARNING("debug @reloadForcedCustomization: " + App.utils.JSON.encode(target_dict));
		this.first_emblem.selectedIndex = this.customization_data["decalID"].indexOf(target_dict["forcedEmblem"][0]);
		this.second_emblem.selectedIndex = this.customization_data["sec_decalID"].indexOf(target_dict["forcedEmblem"][1]);
		this.force_both_emblem.selected = target_dict["forcedBothEmblem"];
		this.summer_camo.selectedIndex = this.customization_data["camoID"].indexOf(target_dict["forcedCamo"][0]);
		this.winter_camo.selectedIndex = this.customization_data["sec_camoID"].indexOf(target_dict["forcedCamo"][1]);
		this.desert_camo.selectedIndex = this.customization_data["sec_camoID"].indexOf(target_dict["forcedCamo"][2]);
		this.summer_paint.selectedIndex = this.customization_data["paintID"].indexOf(target_dict["forcedPaint"][0]);
		this.winter_paint.selectedIndex = this.customization_data["sec_paintID"].indexOf(target_dict["forcedPaint"][1]);
		this.desert_paint.selectedIndex = this.customization_data["sec_paintID"].indexOf(target_dict["forcedPaint"][2]);
	  }
	  
	  public function updateCustomizationData(e : Event) : void {
		var target_dict : Object = this.forced_customization[this.target_customization.selectedIndex];
		// DebugUtils.LOG_WARNING("After target_dict");
		/*for(var key : String in this.customization_data) {
			DebugUtils.LOG_WARNING("debug @updateCustomizationData - key [" + key + "]; length " + String(this.customization_data[key].length));
		}*/
		if(this.force_both_emblem == e.target) {
			target_dict["forcedBothEmblem"] = this.force_both_emblem.selected;
		} else {
			switch(e.target) {
				case this.first_emblem:
					target_dict["forcedEmblem"][0] = this.customization_data["decalID"][this.first_emblem.selectedIndex];
					break;
				case this.second_emblem:
					target_dict["forcedEmblem"][1] = this.customization_data["sec_decalID"][this.second_emblem.selectedIndex];
					break;
				case this.summer_camo:
					target_dict["forcedCamo"][0] = this.customization_data["camoID"][this.summer_camo.selectedIndex];
					break;
				case this.winter_camo:
					target_dict["forcedCamo"][1] = this.customization_data["sec_camoID"][this.winter_camo.selectedIndex];
					break;
				case this.desert_camo:
					target_dict["forcedCamo"][2] = this.customization_data["sec_camoID"][this.desert_camo.selectedIndex];
					break;
				case this.summer_paint:
					target_dict["forcedPaint"][0] = this.customization_data["paintID"][this.summer_paint.selectedIndex];
					break;
				case this.winter_paint:
					target_dict["forcedPaint"][1] = this.customization_data["sec_paintID"][this.winter_paint.selectedIndex];
					break;
				case this.desert_paint:
					target_dict["forcedPaint"][2] = this.customization_data["sec_paintID"][this.desert_paint.selectedIndex];
					break;
			}
		}
	  }
	  
	  public function updateHybridParts(e : Event) : void {
		var targeted_profile : Object = this.list_profile_objects[this.profile_selector.selectedIndex];
		var targeted_field : String;
		switch(e.target) { // retrieve corresponding fields
			case this.profile_hull:
				targeted_field = "hull";
				break;
			case this.profile_turret:
				targeted_field = "turret";
				break;
			case this.profile_gun:
				targeted_field = "gun";
				break;
			default: // some weird call here? TODO add debugging options.
				return;
		}
		if( (targeted_field in targeted_profile) == false) {
			// this can only happen when there is fault during enable/disable fields. Check
			DebugUtils.LOG_WARNING("[UML GUI][AS] Field name [" + String(targeted_field) + 
					"] not exist in targeted_profile [" + App.utils.JSON.encode(targeted_profile) + "] Check if there is some failed logic.");
			return
		}
		if(this.checkIsValidWoTVehicleAtPy(e.target.text)) {
			// is valid, exchange
			targeted_profile[targeted_field] = e.target.text;
		} else {
			// is invalid, load the last value up
			e.target.text = targeted_profile[targeted_field]
		}
	  }
	  
	  public function sendDebugCmdFromAS() : void {
		this.debugEvalCommand(this.debug_exec_field.text, this.debug_eval_field.text)
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