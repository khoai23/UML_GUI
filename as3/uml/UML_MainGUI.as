package uml
{
	import net.wg.infrastructure.base.AbstractWindowView;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import flash.text.TextFieldAutoSize;
	import scaleform.clik.events.ButtonEvent;
	import scaleform.clik.events.ListEvent;
	import scaleform.clik.events.FocusHandlerEvent;
	import scaleform.gfx.TextFieldEx;
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
	  public var moe_list : TextInput;
	  public var moe_nation : DropdownMenu;
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
	  public var current_profile_ignore: CheckBox;
	  public var current_profile_enable : CheckBox;
	  public var current_profile_swapNPC : CheckBox;
	  public var current_profile_alignToTurret : CheckBox;
	  public var current_profile_usewhitelist : CheckBox;
	  public var current_profile_target : TextInput;
	  public var current_profile_target_help : LabelControl;
	  public var current_profile_camo : DropdownMenu;
	  public var current_profile_camo_help : LabelControl;
	  public var current_profile_paint : DropdownMenu;
	  public var current_profile_paint_help : LabelControl;
	  public var current_profile_style : DropdownMenu;
	  public var current_profile_style_progression : TextInput;
	  public var current_profile_style_help : LabelControl;
	  public var current_profile_configString : TextInput;
	  public var current_profile_configString_help : LabelControl;
	  public var delete_profile : SoundButtonEx;
	  public var use_hangar_vehicle : SoundButtonEx;
	  
	  // hybrid section
	  public var hybrid_help : LabelControl;
	  public var profile_chassis_help : LabelControl;
	  public var profile_chassis : TextInput;
	  public var profile_chassis_style: DropdownMenu;
	  public var profile_hull_help : LabelControl;
	  public var profile_hull : TextInput;
	  public var profile_hull_from_selector: SoundButtonEx;
	  public var profile_hull_style: DropdownMenu;
	  public var profile_turret_help : LabelControl;
	  public var profile_turret : TextInput;
	  public var profile_turret_from_selector: SoundButtonEx;
	  public var profile_turret_style: DropdownMenu;
	  public var profile_gun_help : LabelControl;
	  public var profile_gun : TextInput;
	  public var profile_gun_from_selector: SoundButtonEx;
	  public var profile_gun_style: DropdownMenu;
	  
	  // additional setting section
	  public var keyboard_dict: Object;
	  public var remove_unhistorical: CheckBox;
	  public var remove_clan_logo: CheckBox;
	  public var force_clan_logo: TextInput;
	  public var remove_3d_style: CheckBox;
	  public var swap_friendly_enable: CheckBox;
	  public var swap_friendly: TextInput;
	  public var add_profile_friendly: SoundButtonEx;
	  public var swap_enemy_enable: CheckBox;
	  public var swap_enemy: TextInput;
	  public var add_profile_enemy: SoundButtonEx;
	  public var play_anim_fwd: TextInput;
	  public var play_anim_bwd: TextInput;
	  public var play_anim_gun: TextInput;
	
	  // vehicle selector
	  public var help_vehicle_selector : LabelControl;
	  public var vehicle_nations : DropdownMenu;
	  public var vehicle_type : DropdownMenu;
	  public var vehicle_tier : DropdownMenu;
	  public var vehicle_selector : DropdownMenu;
	  public var vehicle_profile_field : TextInput;
	  public var vehicle_selector_profiles : Array;
	// button to add to the profile list or whitelist.
	  public var add_profile_btn : SoundButtonEx;
	  public var add_whitelist_btn : SoundButtonEx;
	  public var profile_with_parent_field : TextInput;
	  public var add_profile_as_parent_btn : SoundButtonEx;
	  public var add_profile_to_moe_btn : SoundButtonEx;
	 
	  // debug component
	  public var debug_exec_field : TextInput;
	  public var debug_eval_field : TextInput;
	  public var debug_btn : SoundButtonEx;
	  
	 
	  // test
	  //public var profileIcon : UILoaderAlt
	  //protected var current_profile_index : Number = 0;
	  protected var list_all_profile_objects : Array;
	  protected var list_ignore_profiles : Array;
	  protected var list_profile_objects : Array;
	  protected var list_styles : Array = null;
	  protected var list_hybrid_parts_styles : Array = [new Array(), new Array(), new Array()];
	  protected var customization_data : Object;
	  
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
	  public var getValidKeyBindFromPy: Function = null // list keybinds that are available on UML.

	  public function UML_MainGUI() {
		 super();
	  }
	  
	  override protected function onPopulate() : void {
		 super.onPopulate();
		 
		 this.moe_selector = createDropdown(35, 10 - 3);
		 this.moe_selector.dataProvider = new DataProvider(["Default MOE", "No MOE", "1 MOE", "2 MOE", "3 MOE"]);
		 var moe_help_1 : LabelControl = createLabel("applied to: ", 35 + 135, 10);
		 this.moe_list = createTextInput("moe_list_placeholder", 35 + 195, 10 - 3);
		 this.add_profile_to_moe_btn = createButton("From Selector", 35 + 330, 10, true);
		 var moe_help_2 : LabelControl = createLabel("using texture: ", 35 + 330 + 95, 10);
		 this.moe_nation = createDropdown(35 + 330 + 95 + 85 , 10 - 3);
		 this.moe_nation.dataProvider = new DataProvider(["Default"]);
		 this.moe_nation.selectedIndex = 0;
		 this.moe_nation.enabled = false;
		 
		 this.affect_hangar = createCheckbox("View UML in Hangar", 35, 35);
		 this.use_UML_sound = createCheckbox("Use UML sounds", 200, 35);
		 
		this.remodels_filelist_label = createLabel("Base Remodel files:", 325, 35);
		this.remodels_filelist_label.width = 175;
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
		// bind to MOE button above.
		this.add_profile_to_moe_btn.addEventListener(ButtonEvent.CLICK, this.addProfileToMOE);
		 
		 // update the state after initiation.
		 this.setStringConfigToAS();
	  }
	  
	  internal function createProfileList(x: Number, y: Number) : Object {
		// try to create a profile list
		// TODO properly lock the values to currentX and currentY
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
			this.current_profile_name.width = 220;
			this.current_profile_ignore = createCheckbox("Ignore by GUI", 35 + 225, 105);
			// this.current_profile_name.autoSize = TextFieldAutoSize.LEFT;
			// this.current_profile_name.toolTip = "The full name of the profile.";
			this.current_profile_target_help = createLabel("Enabled profiles:", 35 + 125, 105 + 20);
			this.current_profile_target = createTextInput("whitelist_placeholder", 35 + 225, 105 + 20 - 3);
			this.current_profile_enable = createCheckbox("Enabled", 35, 105 + 20);
			this.current_profile_swapNPC = createCheckbox("Model swap NPC", 35, 105 + 40);
			this.current_profile_alignToTurret = createCheckbox("Align to Turret", 35, 105 + 60);

			this.current_profile_camo_help = createLabel("Camouflage ID:", 35 + 125, 105 + 40);
			this.current_profile_camo = createDropdown(35 + 225, 105 + 40 - 3);
			this.current_profile_camo.width = 180;
			this.current_profile_paint_help = createLabel("Paint ID:", 35 + 125, 105 + 60);
			this.current_profile_paint = createDropdown(35 + 225, 105 + 60 - 3);
			this.current_profile_paint.width = 180;

			this.current_profile_configString_help = createLabel("Config:", 35, 105 + 80)
			this.current_profile_configString = createTextInput("N/A", 35 + 50, 105 + 80 - 3);
			this.current_profile_configString.width = 60; this.current_profile_configString.maxChars = 4;
			this.current_profile_style_help = createLabel("(Progress) Style:", 35 + 125, 105 + 80);
			this.current_profile_style_progression = createTextInput("4", 35 + 225, 105 + 80 - 3);
			this.current_profile_style_progression.width = 30; this.current_profile_style_progression.maxChars = 1; this.current_profile_style_progression.enabled = false;
			this.current_profile_style = createDropdown(35 + 225 + 35, 105 + 80 - 3);
			this.use_hangar_vehicle = createButton("Add hangar vehicle to Whitelist", 35 + 20, 105 + 105, true);
			this.delete_profile = createButton("Delete this Profile", 35 + 230, 105 + 105, true);
			this.populatePaintCamo();
			
			this.hybrid_help = createLabel("Hybrid Vehicle Configuration", 35, 235)
			this.profile_chassis_help = createLabel("Chassis:", 35, 235 + 20);
			this.profile_chassis = createTextInput("N/A", 35 + 50, 235 + 20 - 3);
			this.profile_chassis_style = createDropdown(35, 235 + 40 - 3); this.profile_chassis_style.width = 120;
			this.profile_hull_help = createLabel("Hull:", 35 + 215, 235 + 20);
			this.profile_hull = createTextInput("N/A", 35 + 215 + 35, 235 + 20 - 3);
			this.profile_hull_style = createDropdown(35 + 215, 235 + 40 - 3); this.profile_hull_style.width = 120;
			this.profile_hull_from_selector = createButton("From Selector", 35 + 215 + 120, 235 + 40, true);
			this.profile_turret_help = createLabel("Turret:", 35, 235 + 60);
			this.profile_turret = createTextInput("N/A", 35 + 50, 235 + 60 - 3);
			this.profile_turret_style = createDropdown(35, 235 + 80 - 3); this.profile_turret_style.width = 120;
			this.profile_turret_from_selector = createButton("From Selector", 35 + 120, 235 + 80, true);
			this.profile_gun_help = createLabel("Gun:", 35 + 215, 235 + 60);
			this.profile_gun = createTextInput("N/A", 35 + 215 + 35, 235 + 60 - 3);
			this.profile_gun_style = createDropdown(35 + 215, 235 + 80 - 3); this.profile_gun_style.width = 120;
			this.profile_gun_from_selector = createButton("From Selector", 35 + 215 + 120, 235 + 80, true);
			this.profile_chassis.enabled = false;

			// adding appropriate listeners
			this.forward_btn.addEventListener(ButtonEvent.CLICK, this.forwardProfileIndex);
			this.backward_btn.addEventListener(ButtonEvent.CLICK, this.backwardProfileIndex);
			this.profile_selector.addEventListener(ListEvent.INDEX_CHANGE, this.loadProfileAtCurrentIndex);
			this.toggle_show_ignore.addEventListener(ButtonEvent.CLICK, this.reloadProfileSelector);
			// this.profile_selector.dataProvider = new DataProvider(["mock1", "mock2"]);

			this.current_profile_enable.addEventListener(ButtonEvent.CLICK, this.onSetEnableProfile);
			this.current_profile_swapNPC.addEventListener(ButtonEvent.CLICK, this.onSetEnableProfileForNPC);
			this.current_profile_alignToTurret.addEventListener(ButtonEvent.CLICK, this.onSetAlignToTurret);
			this.current_profile_ignore.addEventListener(ButtonEvent.CLICK, this.onIgnoreChange);
			this.current_profile_target.addEventListener(FocusHandlerEvent.FOCUS_OUT, this.onWhitelistChange);
			this.current_profile_camo.addEventListener(ListEvent.INDEX_CHANGE, this.onCamoChange);
			this.current_profile_paint.addEventListener(ListEvent.INDEX_CHANGE, this.onPaintChange);
			this.current_profile_style.addEventListener(ListEvent.INDEX_CHANGE, this.onStyleChange);
			this.current_profile_style_progression.addEventListener(FocusHandlerEvent.FOCUS_OUT, this.onProgressionChange);
			this.current_profile_configString.addEventListener(FocusHandlerEvent.FOCUS_OUT, this.onConfigStringChange);
			this.delete_profile.addEventListener(ButtonEvent.CLICK, this.removeProfile);
			this.use_hangar_vehicle.addEventListener(ButtonEvent.CLICK, this.addHangarVehicleToWhitelist);

			this.profile_hull.addEventListener(FocusHandlerEvent.FOCUS_OUT, this.updateHybridParts);
			this.profile_turret.addEventListener(FocusHandlerEvent.FOCUS_OUT, this.updateHybridParts);
			this.profile_gun.addEventListener(FocusHandlerEvent.FOCUS_OUT, this.updateHybridParts);
			this.profile_hull_from_selector.addEventListener(ButtonEvent.CLICK, this.updateHybridParts);
			this.profile_turret_from_selector.addEventListener(ButtonEvent.CLICK, this.updateHybridParts);
			this.profile_gun_from_selector.addEventListener(ButtonEvent.CLICK, this.updateHybridParts);
			this.profile_chassis_style.addEventListener(ListEvent.INDEX_CHANGE, this.onStyleChange);
			this.profile_hull_style.addEventListener(ListEvent.INDEX_CHANGE, this.onStyleChange);
			this.profile_turret_style.addEventListener(ListEvent.INDEX_CHANGE, this.onStyleChange);
			this.profile_gun_style.addEventListener(ListEvent.INDEX_CHANGE, this.onStyleChange);
			// 
			currentX = x + 425; // 460
			currentY = y + 305; // 350
			
			// adding the concerning VehicleSelector panel
			var altCurrentY : Number = y;
			altCurrentY = this.createAdditionalSettings(currentX, altCurrentY)
			var sizeObject : Object = this.createVehicleSelector(currentX, altCurrentY);
			currentX = sizeObject.x;
			currentY = (currentY > sizeObject.y) ? currentY : sizeObject.y; // take the longest Y (height)
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
	  
	  internal function createVehicleSelector(x: Number, y: Number) : Object {
		// multiple dropdown list concerning nation-class-tier-vehicle to show the corresponding profile name
		this.help_vehicle_selector = createLabel("Vehicle Selector", x, y);
		this.vehicle_nations = createDropdown(x, y + 20);
		this.vehicle_type = createDropdown(x + 135, y + 20);
		this.vehicle_tier = createDropdown(x, y + 45);
		this.vehicle_selector = createDropdown(x + 135, y + 45);
		this.vehicle_profile_field = createTextInput("vehicle_profile_name", x + 60, y + 70);
		// button to add to the profile list or whitelist.
		this.add_profile_btn = createButton("Add as new Profile", x + 15, y + 95, true);
		this.add_whitelist_btn = createButton("Add to Whitelist", x + 15 + 135, y + 95, true);
		// button to add as a new profile
		this.add_profile_as_parent_btn = createButton("Add as Parent to ", x + 20, y + 120, true);
		this.profile_with_parent_field = createTextInput("profile_with_parent_placeholder", x + 135, y + 120 - 2);
		
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
		
		return {x: x + 270, y: y + 145}; // 650
	  }
	  
	  internal function createAdditionalSettings(x: Number, y: Number): Number {
		// these don't need listener, since they are strictly updated on Apply anyway. Except the add button.
		var additional_setting_help : LabelControl = createLabel("Additional Settings", x, y);
		this.remove_3d_style = createCheckbox("Remove all 3D Styles", x, y + 20);
		this.remove_unhistorical = createCheckbox("Remove Non-historical (incl. replays)", x + 150, y + 20);
		this.remove_clan_logo = createCheckbox("Remove Clan Logo", x, y + 40);
		var force_clan_logo_help : LabelControl = createLabel("Clan ID:", x + 150, y + 40);
		this.force_clan_logo = createTextInput("N/A", x + 210, y + 40 - 3); this.force_clan_logo.width = 75; this.force_clan_logo.enabled = false;
		this.swap_friendly_enable = createCheckbox("Swap ALL friendly vehicles", x, y + 60); this.swap_friendly_enable.width = 200;
		var swap_friendly_help : LabelControl = createLabel("Using:", x, y + 80);
		this.swap_friendly = createTextInput("swap_friendly_placeholder", x + 40, y + 80 - 3);
		this.add_profile_friendly = createButton("Add current Profile", x + 180, y + 80, true);
		this.swap_enemy_enable = createCheckbox("Swap ALL enemy vehicles", x, y + 100); this.swap_enemy_enable.width = 200;
		var swap_enemy_help : LabelControl = createLabel("Using:", x, y + 120);
		this.swap_enemy = createTextInput("swap_enemy_placeholder", x + 40, y + 120 - 3);
		this.add_profile_enemy = createButton("Add current Profile", x + 180, y + 120, true);
		
		this.add_profile_friendly.addEventListener(ButtonEvent.CLICK, this.addCurrentProfileToSwapList);
		this.add_profile_enemy.addEventListener(ButtonEvent.CLICK, this.addCurrentProfileToSwapList);
		
		return y + 140 + 10; // 410
	  }
	  
	  protected function addCurrentProfileToSwapList(event : Object) : void {
		var profile_name : String = this.list_profile_objects[this.profile_selector.selectedIndex]["name"];
		var current_swaplist : TextInput = (event.target == this.add_profile_friendly) ? this.swap_friendly : this.swap_enemy;
		if(current_swaplist.text == "")
			current_swaplist.text = profile_name;
		else if(current_swaplist.text.indexOf(profile_name) < 0) // only add when profile not exist in list
			current_swaplist.text = current_swaplist.text + ", " + profile_name;
		// DebugUtils.LOG_WARNING("[UML GUI][AS] Adding profile " + profile_name + " to " + (event.target == this.add_profile_friendly ? "friendly" : "enemy") + " with current text: " + current_swaplist.text );
	  }
	  
	  override protected function onDispose() : void  {
        this.apply_button.removeEventListener(ButtonEvent.CLICK, this.sendStringConfigFromAS);
		this.reload_button.removeEventListener(ButtonEvent.CLICK, this.setStringConfigToAS);
		if(this.isStatic) {
			this.forward_btn.removeEventListener(ButtonEvent.CLICK, this.forwardProfileIndex);
			this.backward_btn.removeEventListener(ButtonEvent.CLICK, this.backwardProfileIndex);
			this.profile_selector.removeEventListener(ListEvent.INDEX_CHANGE, this.loadProfileAtCurrentIndex);
			
			this.current_profile_enable.removeEventListener(ButtonEvent.CLICK, this.onSetEnableProfile);
			this.current_profile_alignToTurret.removeEventListener(ButtonEvent.CLICK, this.onSetAlignToTurret);
			this.current_profile_ignore.removeEventListener(ButtonEvent.CLICK, this.onIgnoreChange);
		    this.current_profile_target.removeEventListener(ListEvent.INDEX_CHANGE, this.onWhitelistChange);
		    this.current_profile_camo.removeEventListener(ListEvent.INDEX_CHANGE, this.onCamoChange);
		    this.current_profile_paint.removeEventListener(ListEvent.INDEX_CHANGE, this.onPaintChange);
			this.current_profile_style_progression.removeEventListener(FocusHandlerEvent.FOCUS_OUT, this.onProgressionChange);
			
			this.vehicle_nations.removeEventListener(ListEvent.INDEX_CHANGE, this.loadVehiclesWithCriteriaToAS);
			this.vehicle_type.removeEventListener(ListEvent.INDEX_CHANGE, this.loadVehiclesWithCriteriaToAS);
			this.vehicle_tier.removeEventListener(ListEvent.INDEX_CHANGE, this.loadVehiclesWithCriteriaToAS);
			this.vehicle_selector.removeEventListener(ListEvent.INDEX_CHANGE, this.loadVehicleProfileToAS);
			this.add_profile_btn.removeEventListener(ButtonEvent.CLICK, this.addNewProfile);
			this.add_whitelist_btn.removeEventListener(ButtonEvent.CLICK, this.addProfileToWhitelist);
		
			this.profile_hull.removeEventListener(FocusHandlerEvent.FOCUS_OUT, this.updateHybridParts);
			this.profile_turret.removeEventListener(FocusHandlerEvent.FOCUS_OUT, this.updateHybridParts);
			this.profile_gun.removeEventListener(FocusHandlerEvent.FOCUS_OUT, this.updateHybridParts);
			this.profile_hull_from_selector.removeEventListener(ButtonEvent.CLICK, this.updateHybridParts);
			this.profile_turret_from_selector.removeEventListener(ButtonEvent.CLICK, this.updateHybridParts);
			this.profile_gun_from_selector.removeEventListener(ButtonEvent.CLICK, this.updateHybridParts);
			this.profile_chassis_style.removeEventListener(ListEvent.INDEX_CHANGE, this.onStyleChange);
			this.profile_hull_style.removeEventListener(ListEvent.INDEX_CHANGE, this.onStyleChange);
			this.profile_turret_style.removeEventListener(ListEvent.INDEX_CHANGE, this.onStyleChange);
			this.profile_gun_style.removeEventListener(ListEvent.INDEX_CHANGE, this.onStyleChange);
			
			if(this.getIsDebugUMLFromPy()) {
				this.debug_btn.removeEventListener(ButtonEvent.CLICK, this.sendDebugCmdFromAS);
			}
			
			this.add_profile_friendly.removeEventListener(ButtonEvent.CLICK, this.addCurrentProfileToSwapList);
			this.add_profile_enemy.removeEventListener(ButtonEvent.CLICK, this.addCurrentProfileToSwapList);
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
	  
	  internal function toggleAvailabilityHybrid(enable : Boolean, profile_obj : Object = null) : void {
		// set enable/disable hybrid availability. Split to a function due to styleSet soft conflicting with hybrids.
		if(profile_obj == null) {
			profile_obj = this.list_profile_objects[this.profile_selector.selectedIndex];
			// DebugUtils.LOG_WARNING("[UML GUI][AS] Debug: profile_obj @toggleAvailabilityHybrid is null, recalling correct object using current selector.");
		}
		if((enable == this.profile_hull.enabled) && (enable == this.profile_turret.enabled) && (enable == this.profile_gun.enabled) && !enable) {
			return; // if the values are already correctly set for disabled, do not repeat 
		}
		if(enable) {
			this.updateStyleOption(profile_obj["chassisStyle"], this.profile_chassis_style);
			this.profile_hull.text = profile_obj["hull"]; this.profile_hull.enabled = true; this.profile_hull_from_selector.enabled = true;
			this.updateStyleOption(profile_obj["hullStyle"], this.profile_hull_style, profile_obj["hull"]);
			this.profile_turret.text = profile_obj["turret"]; this.profile_turret.enabled = true; this.profile_turret_from_selector.enabled = true;
			this.updateStyleOption(profile_obj["turretStyle"], this.profile_turret_style, profile_obj["turret"]);
			this.profile_gun.text = profile_obj["gun"]; this.profile_gun.enabled = true; this.profile_gun_from_selector.enabled = true;
			this.updateStyleOption(profile_obj["gunStyle"], this.profile_gun_style, profile_obj["gun"]);
		} else {
			this.profile_chassis_style.enabled = false; this.profile_chassis_style.selectedIndex = -1;
			this.profile_hull.text = "N/A"; this.profile_hull.enabled = false; 
			this.profile_hull_style.enabled = false; this.profile_hull_style.selectedIndex = -1; this.profile_hull_from_selector.enabled = false;
			this.profile_turret.text = "N/A"; this.profile_turret.enabled = false;
			this.profile_turret_style.enabled = false; this.profile_turret_style.selectedIndex = -1; this.profile_turret_from_selector.enabled = false;
			this.profile_gun.text = "N/A"; this.profile_gun.enabled = false;
			this.profile_gun_style.enabled = false; this.profile_gun_style.selectedIndex = -1; this.profile_gun_from_selector.enabled = false;
		}
	  }
	  
	  internal function loadProfileAtCurrentIndex() : void {
	    var current_idx : Number = this.profile_selector.selectedIndex;
		// if topmost, disable backward; if at end, disable forward
		this.backward_btn.enabled = current_idx > 0;
		this.forward_btn.enabled = current_idx < (this.list_profile_objects.length-1);
		// load respective data into components
		var currentProfile : Object = this.list_profile_objects[current_idx];
		//DebugUtils.LOG_WARNING("[UML GUI][AS] loadProfileAtCurrentIndex called for obj:" + App.utils.JSON.encode(currentProfile) + " at index " + String(current_idx));
		if("parent" in currentProfile) {
			this.current_profile_name.text = "[" + currentProfile["parent"] + "]" + currentProfile["name"];
			// custom name and section ONLY WHEN parents are not bound with their 3D styles
		} else {
			this.current_profile_name.text = currentProfile["name"];
			// this.toggleAvailabilityHybrid(false, currentProfile);
		}
		this.updateStyleOption(currentProfile["styleSet"], this.current_profile_style);
		if(this.list_styles == null) { // update viability of the progression TextInput
			this.current_profile_style_progression.enabled = false;
			this.current_profile_style_progression.text = "";
		} else {
			this.current_profile_style_progression.enabled = true;
			this.current_profile_style_progression.text = currentProfile["styleProgression"];
		}
		this.toggleAvailabilityHybrid(("parent" in currentProfile) && (this.current_profile_style.selectedIndex <= 0), currentProfile);
		this.current_profile_enable.selected = currentProfile["enabled"];
		this.current_profile_swapNPC.selected = currentProfile["swapNPC"];
		this.current_profile_ignore.selected = (this.list_ignore_profiles.indexOf(currentProfile["name"]) >= 0);
		this.current_profile_alignToTurret.selected = currentProfile["alignToTurret"];
		if(currentProfile["useWhitelist"]) {
			this.current_profile_target.text = currentProfile["whitelist"];
		} else {
			this.current_profile_target.text = ""
		}
		this.current_profile_camo.selectedIndex = this.customization_data["camoID"].indexOf(currentProfile["camouflageID"]);
		this.current_profile_paint.selectedIndex = this.customization_data["paintID"].indexOf(currentProfile["paintID"]);
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
	  
	  internal function onSetAlignToTurret() : void {
		this.list_profile_objects[this.profile_selector.selectedIndex]["alignToTurret"] = this.current_profile_alignToTurret.selected;
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
			/*if(this.profile_selector.selectedIndex >= this.list_profile_objects.length)
				this.profile_selector.selectedIndex = 0; // if ignore the last entry, circle to first. TODO go to new last?*/
		}
	  }
	  
	  internal function onProgressionChange() : void {
		this.list_profile_objects[this.profile_selector.selectedIndex]["styleProgression"] = this.current_profile_style_progression.text;
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
	  
	  internal function onStyleChange(event : Object, actual_target : DropdownMenu = null) : void {
		var current_profile : Object = this.list_profile_objects[this.profile_selector.selectedIndex];
		var style_selector_object : DropdownMenu = (actual_target ? actual_target : event.target) as DropdownMenu;
		var property_name : String;
		var list_styles : Array;
		switch(style_selector_object) {
			case this.current_profile_style:
				property_name = "styleSet"
				list_styles = this.list_styles;
				break;
			case this.profile_chassis_style:
				property_name = "chassisStyle"
				list_styles = this.list_styles;
				break;
			case this.profile_hull_style:
				property_name = "hullStyle"
				list_styles = this.list_hybrid_parts_styles[0];
				break;
			case this.profile_turret_style:
				property_name = "turretStyle"
				list_styles = this.list_hybrid_parts_styles[1];
				break;
			case this.profile_gun_style:
				property_name = "gunStyle"
				list_styles = this.list_hybrid_parts_styles[2];
				break;
			default:
				// should not happen; TODO log the needed info to debug
				return
		}
		if(style_selector_object.selectedIndex < 0) {
			// disabled from above for some reason; ignore
			return
		} else {
			if(style_selector_object.selectedIndex == 0) {
				current_profile[property_name] = "0";
			} else {
				current_profile[property_name] = list_styles[style_selector_object.selectedIndex];
			}
			// DebugUtils.LOG_WARNING("[UML GUI][AS] Debug: Updated property [" + property_name + "] of existing profile [" + current_profile["name"] + "(" + App.utils.JSON.encode(current_profile) + ")" + "] with index " + String(style_selector_object.selectedIndex));
		}
		if(style_selector_object == this.current_profile_style) {
			// selecting a 3D style (!=0) will disable hybrid vehicles
			this.toggleAvailabilityHybrid(this.current_profile_style.selectedIndex == 0);
		}
	  }
	  
	  internal function loadVehiclesWithCriteriaToAS() : void {
		// attempt to load vehicles using nation, type and tier filtering
		var vehicles_data : Array = this.loadVehiclesWithCriteriaFromPy(this.vehicle_nations.selectedIndex, this.vehicle_type.selectedIndex, this.vehicle_tier.selectedIndex);
		DebugUtils.LOG_WARNING("[UML GUI][AS] Debug: vehicle data received: " + App.utils.JSON.encode(vehicles_data) + ". Check to see what failed.");
		this.vehicle_selector_profiles = vehicles_data[0];
		this.vehicle_selector.dataProvider = new DataProvider(vehicles_data[1]);
		this.vehicle_selector.selectedIndex = 0;
		this.loadVehicleProfileToAS();
	  }
	  
	  internal function loadVehicleProfileToAS() : void {
		// on clicking a vehicle within vehicle_selector, change the corresponding TextInput to the profile name
		if(this.vehicle_selector.selectedIndex == -1) {// not selected
			this.vehicle_profile_field.text = "vehicle_profile_name";
			this.profile_with_parent_field.text = "profile_with_parent_placeholder";
		} else {
			this.vehicle_profile_field.text = this.vehicle_selector_profiles[this.vehicle_selector.selectedIndex];
			this.profile_with_parent_field.text =  "hybrid_" + this.vehicle_profile_field.text + "__" + String(_dateObject.time).substring(6); // unique identifier using timestamp
		}
	  }
	  
	  internal function addNewProfile(event: Event) : void {
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
		for(var i:Number = 0; i < this.list_profile_objects.length; i++) if(this.list_profile_objects[i]["name"] == profile_text) { profile_index_if_exist = i; break; }
		
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
		var remove_profile_name : String = this.list_profile_objects[remove_index]["name"];
		var true_remove_index : Number = -1;
		for(var i:Number = 0; i < this.list_all_profile_objects.length; i++) if(this.list_all_profile_objects[i]["name"] == remove_profile_name) { true_remove_index = i; break; }
		// remove on Py side
		this.removeProfileAtPy( remove_profile_name );
		// remove on AS side 
		if(true_remove_index < 0) {
			DebugUtils.LOG_WARNING("[UML GUI][AS] Issue: the list_all_profile_objects do not contain profile with name " + remove_profile_name + ". Skipping deletion.");
		} else {
			DebugUtils.LOG_WARNING("[UML GUI][AS] Debug: targetting " + remove_profile_name + " in-field index [" + String(remove_index) + "] true index [" + String(true_remove_index) + "].");
			this.list_all_profile_objects.splice(true_remove_index, 1);
		}
		// DebugUtils.LOG_WARNING("[UML GUI] debug selected index"
		if(remove_index >= this.profile_selector.dataProvider.length - 1) { // if the removed index is last, reset to first. TODO Maybe reset to last instead?
			this.profile_selector.selectedIndex = 0;
		}
		this.reloadProfileSelector(null, true);
	  }
	  
	  internal function addProfileToWhitelist(event: Event, profile_text: String = null) : void {
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
	  
	  internal function addProfileToMOE(event: Event, profile_text: String = null) : void {
		// on clicking a vehicle within vehicle_selector, change the corresponding TextInput to the profile name
		if(profile_text == null) {
			profile_text = this.vehicle_profile_field.text;
		}
		var current_moelist : String = StringUtil.trim(this.moe_list.text);
		if(current_moelist == "")
			this.moe_list.text = profile_text;
		else if(current_moelist.indexOf(profile_text) < 0) // only add when profile not exist in whitelist
			this.moe_list.text = current_moelist + ", " + profile_text;
	  }
	  
	  internal function addHangarVehicleToWhitelist() : void {
		// retrieve the hangar vehicle from Py side and add it to whitelist
		this.addProfileToWhitelist(null, this.getHangarVehicleFromPy());
	  }
	  
	  internal function updateStyleOption(style_index_or_name : String, target_dropdown : DropdownMenu, profile_name : String = null) : void {
	    if( profile_name == null ) { 
			profile_name = this.current_profile_name.text;
			if(profile_name.indexOf("[") >= 0) {
				// parented profile; split by bracketed term (parent)
				profile_name = profile_name.substring(profile_name.indexOf("[") + 1, profile_name.indexOf("]"));
			}
			// profile_name = ("parent" in targeted_profile) ? targeted_profile["parent"] : targeted_profile["name"] ; // always get parent if available
		}
		//DebugUtils.LOG_WARNING("debug: profile_name: " + profile_name);
		var list_styles : Array = this.getPossibleStyleOfProfileFromPy(profile_name);
		// attempt to parse to number; if not true, try to search in list of possible styles; if not found there either, safeguard to 0 (No style)
		// attempt to convert 
		// update corresponding styles: list_styles for current_profile_style and list_hybrid_parts_styles for others
		switch(target_dropdown) {
			case this.current_profile_style:
			case this.profile_chassis_style:
				this.list_styles = list_styles;
				break;
			case this.profile_hull_style:
				this.list_hybrid_parts_styles[0] = list_styles;
				break;
			case this.profile_turret_style:
				this.list_hybrid_parts_styles[1] = list_styles;
				break;
			case this.profile_gun_style:
				this.list_hybrid_parts_styles[2] = list_styles;
				break;
		}
		var selector_name : String =  (this.current_profile_style == target_dropdown || this.profile_hull_style == target_dropdown) ? ((this.current_profile_style == target_dropdown) ? "all" : "hull") : ((this.profile_gun_style == target_dropdown) ? "gun" : "turret") ;
		if(list_styles == null) {
			// no style, disable the selector
			// DebugUtils.LOG_WARNING("[UML GUI][AS] Debug: Style dropdown disabled for " + profile_name + "[" + selector_name + "]");
			target_dropdown.enabled = false;
			target_dropdown.selectedIndex = -1;
		} else {
			// possible style, update the selector
			var profile_idx : Number = Number(style_index_or_name);
			if(isNaN(profile_idx)) {
				profile_idx = list_styles.indexOf(style_index_or_name);
				if(profile_idx == -1) profile_idx = 0;
			}
			target_dropdown.enabled = true;
			// DebugUtils.LOG_WARNING("[UML GUI][AS] Debug: Style dropdown enabled for " + profile_name + "[" + selector_name + "] with following params: list styles: " + String(list_styles) + "; current style value " + String(style_index_or_name) + "; found index " + String(profile_idx));
			// target_dropdown.selectedIndex = -1; // try disabling the data beforehand
			target_dropdown.dataProvider = new DataProvider(list_styles);
			target_dropdown.invalidateData();
			target_dropdown.selectedIndex = profile_idx;
		}
	  }
	  
	  public function sendStringConfigFromAS() : void { // paired with receiveStringConfig
		  // DebugUtils.LOG_WARNING("Last profile selected to put to OM object: " + String(this.vehicle_selector.selectedIndex))
		  var dict : Object = { "affectHangar": this.affect_hangar.selected,
								"useUMLSound": this.use_UML_sound.selected,
								"remodelsFilelist": this.remodels_filelist.text,
								"MOErank": (this.moe_selector.selectedIndex - 1),
								"MOElist": this.moe_list.text,
								// "MOEnation": // sth to convert this.moe_nation.selectedIndex,
								"lastProfileSelectedIdx": this.profile_selector.selectedIndex,
								"listProfileObjects": this.list_all_profile_objects,
								"ignoreList": this.list_ignore_profiles,
								"remove3DStyle": this.remove_3d_style.selected,
								"removeClanLogo": this.remove_clan_logo.selected,
								"removeUnhistoricalContent": this.remove_unhistorical.selected,
								"swapAllFriendly": this.swap_friendly_enable.selected,
								"swapAllEnemy": this.swap_enemy_enable.selected,
								// "forceClanLogoID": this.force_clan_logo.text, // turn on when it works.
								"friendlyProfiles": this.swap_friendly.text,
								"enemyProfiles": this.swap_enemy.text
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
			// DebugUtils.LOG_WARNING("[UML GUI][AS] Debug: entering filtered profile @reloadProfileSelector, full count - non-ignore count: " + String(this.list_all_profile_objects.length) + " - " + String(this.list_profile_objects.length));
		}
		var profile_names : Array = []
		for(var i:int=0; i<this.list_profile_objects.length; i++) { 
			profile_names[i] = this.list_profile_objects[i]["name"]; 
		}
		this.profile_selector.dataProvider = new DataProvider(profile_names);
		if(reload_current_profile) {
			// validate and update index (if too large, snap to first profile)
			if(this.profile_selector.selectedIndex >= this.list_profile_objects.length)
				this.profile_selector.selectedIndex = 0;
			this.loadProfileAtCurrentIndex();
		}
		this.profile_selector.invalidateData();
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
			// DebugUtils.LOG_WARNING("[UML GUI][AS] Debug: ignoreList: " + String(this.list_ignore_profiles));
			this.reloadProfileSelector(null, false);
			this.profile_selector.selectedIndex = dict['lastProfileSelectedIdx'] < this.list_profile_objects.length ? dict['lastProfileSelectedIdx'] : 0; // prevent delete & no applying
			this.loadProfileAtCurrentIndex();
		}
		// update current MOE rank; auto is -1 and goes from 0-3, therefore we can simply +1 before and after
		this.moe_selector.selectedIndex = dict["MOErank"] + 1;
		this.moe_list.text = dict["MOElist"];
		// update all corresponding additional settings
		this.remove_3d_style.selected = dict["remove3DStyle"];
		this.remove_clan_logo.selected = dict["removeClanLogo"];
		this.remove_unhistorical.selected = dict["removeUnhistoricalContent"];
		this.swap_friendly_enable.selected = dict["swapAllFriendly"];
		this.swap_enemy_enable.selected = dict["swapAllEnemy"];
		// this.force_clan_logo.text = dict["forceClanLogoID"]; // turn on when it works.
		this.swap_friendly.text = dict["friendlyProfiles"];
		this.swap_enemy.text = dict["enemyProfiles"];
      }
	  
	  public function updateHybridParts(e : Event) : void {
		var targeted_profile : Object = this.list_profile_objects[this.profile_selector.selectedIndex];
		var targeted_field : String;
		var target_obj : Object = e.target;
		var target_style_obj : DropdownMenu;
		switch(target_obj) { // retrieve corresponding fields
			case this.profile_hull:
				targeted_field = "hull";
				target_style_obj = this.profile_hull_style;
				break;
			case this.profile_turret:
				targeted_field = "turret";
				target_style_obj = this.profile_turret_style;
				break;
			case this.profile_gun:
				targeted_field = "gun";
				target_style_obj = this.profile_gun_style;
				break;
			case this.profile_hull_from_selector:
				target_obj = this.profile_hull;
				this.profile_hull.text = this.vehicle_profile_field.text;
				targeted_field = "hull";
				target_style_obj = this.profile_hull_style;
				break;
			case this.profile_turret_from_selector:
				target_obj = this.profile_turret;
				this.profile_turret.text = this.vehicle_profile_field.text;
				targeted_field = "turret";
				target_style_obj = this.profile_turret_style;
				break;
			case this.profile_gun_from_selector:
				target_obj = this.profile_gun;
				this.profile_gun.text = this.vehicle_profile_field.text;
				targeted_field = "gun";
				target_style_obj = this.profile_gun_style;
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
		if(this.checkIsValidWoTVehicleAtPy(target_obj.text)) {
			// is valid, exchange and reload the style with default value (0)
			targeted_profile[targeted_field] = target_obj.text;
			this.updateStyleOption("0", target_style_obj, target_obj.text);
		} else {
			// is invalid, load the last value up and do not reload
			target_obj.text = targeted_profile[targeted_field]
		}
		// this.onStyleChange(null, target_style_obj);
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