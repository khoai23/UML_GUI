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
	  public var toggle_show_activated: CheckBox;
	  
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
	  
	  public var current_profile_gunEffect : TextInput;
	  public var current_profile_gunEffect_help : LabelControl;
	  public var current_profile_soundChassis : TextInput;
	  public var current_profile_soundChassis_help : LabelControl;
	  public var current_profile_soundTurret : TextInput;
	  public var current_profile_soundTurret_help : LabelControl;
	  public var current_profile_soundEngine : TextInput;
	  public var current_profile_soundEngine_help : LabelControl;
	  
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
	  protected var customization_data : Object = null;
	  protected var localization_data: Object = null;
	  protected var position_data: Object = null;
	  
	  public var getIsDebugUMLFromPy : Function = null; 				// this will get UML's debug to decide showing debug fields (eval, exec) or not
	  public var forcedCustomizationIsAvailableAtPy : Function = null; 	// this will check if forcedCustomization module exist or not
      public var receiveStringConfigAtPy : Function = null; 			// this will receive config data from swf to python
	  public var getStringConfigFromPy : Function = null;				// this will get config data from python to swf
	  public var getVehicleSelectorDataFromPy : Function = null; 		// this will get permanent vehicle categories (nation, class, tier)
	  public var loadVehiclesWithCriteriaFromPy : Function = null; 		// this will load the list of vehicles fitting the filter above
	  public var loadVehicleProfileFromPy : Function = null;			// this will convert the proper name into the accompanying text input
	  public var removeProfileAtPy : Function = null; 					// this will purge the profile on Python / XML end
	  public var loadCustomizationDataFromPy : Function = null; 		// this will load the needed data to camo/paint dropdown
	  public var getHangarVehicleFromPy : Function = null; 				// this will retrieve the needed hangar vehicle to support addHangarVehicleToWhitelist
	  public var getPossibleStyleOfProfileFromPy : Function = null; 	// this will retrieve the needed profile style from the vehicle obj.
	  public var debugEvalCommand : Function = null; 					// eval and exec codes directly from GUI
	  public var checkIsValidWoTVehicleAtPy : Function = null; 			// check valid code to create hybrids
	  public var getValidKeyBindFromPy: Function = null; 				// list keybinds that are available on UML.
	  public var getStringLocalizationFromPy: Function = null;			// retrieve localizable dict to use 
	  public var getStringPositionFromPy: Function = null;				// retrieve customizable dictionary related to positions - 

	  public function UML_MainGUI() {
		 super();
	  }
	  
	  override protected function onPopulate() : void {
		 super.onPopulate();
		 this.localization_data = App.utils.JSON.decode(this.getStringLocalizationFromPy());
		 this.position_data = App.utils.JSON.decode(this.getStringPositionFromPy());
		 
		 var start_x: Number = this.position_data["start_x"]; 										// from left; default 35
		 var start_y: Number = this.position_data["start_y"]; 										// from top; default 10
		 var box_offset: Number = this.position_data["box_offset"]; 								// offset to minus the "box" (e.g dropdown, textinput) so that they align center to each other. Default -3
		 var item_spacing: Number = this.position_data["item_spacing"]; 							// spacing between row-item; default 10
		 var section_spacing: Number = this.position_data["section_spacing"];						// spacing between independent section; default 20
		 var row_increment: Number = this.position_data["row_increment"]; 							// increment when going down a row; default 20
		
		// build the meta section on span row 1
		var metaSectionSize: Object = this.createMetaSetting(start_x, start_y, item_spacing, row_increment, box_offset);
		// build the profile list on row 2 col 1
		var profileListSize: Object = this.createProfileList(start_x, start_y + metaSectionSize["height"] + section_spacing, item_spacing, row_increment, box_offset, this.position_data["profile_region_width"] as Array);
		// build the advanced profile option on row 3 col 1
		var additionalFieldsSize: Object = this.createProfileAdditionalFields(start_x, profileListSize["y"] + profileListSize["height"] + section_spacing, item_spacing, row_increment, box_offset, this.position_data["sound_region_width"] as Array, this.position_data["hybrid_region_width"] as Array, this.position_data["subsection_indent"]);
		// compare both col 1 option above; assert position for col 2
		var column_2_x: Number = start_x + Math.max(additionalFieldsSize["width"], profileListSize["width"]) + section_spacing;
		// build the UML additional setting on row 2 col 2
		var settingSize : Object = this.createAdditionalSettings(column_2_x, profileListSize["y"], item_spacing, row_increment, box_offset, this.position_data["swapall_width"]);
		// build the vehicle selector on row 3 col 2
		var vehicleSelectorSize : Object = this.createVehicleSelector(column_2_x, profileListSize["y"] + Math.max(profileListSize["height"], settingSize["height"]) + section_spacing, item_spacing, row_increment, box_offset, this.position_data["dropdown_width"]);
		
		// set dynamic width-height depending on possible options; adding components relying on those fields as needed after.
		this.width = Math.max(settingSize["x"] + settingSize["width"], vehicleSelectorSize["x"] + vehicleSelectorSize["width"]) + start_x;
		this.height = Math.max(additionalFieldsSize["y"] + additionalFieldsSize["height"], vehicleSelectorSize["y"] + vehicleSelectorSize["height"]) + start_y;
		 
		this.height = Math.max(additionalFieldsSize["y"] + additionalFieldsSize["height"], vehicleSelectorSize["y"] + vehicleSelectorSize["height"]) + start_y + row_increment*2;
		if(this.getIsDebugUMLFromPy()) {
			// debug
			this.debug_exec_field = createTextInput("debug_exec_field", 32,  this.height - row_increment - start_y);
			this.debug_eval_field = createTextInput("debug_eval_field", 162,  this.height - row_increment - start_y);
			this.debug_btn = createButton("Debug", 295,  this.height - row_increment - start_y, true);
			this.debug_btn.addEventListener(ButtonEvent.CLICK, this.sendDebugCmdFromAS);
		}

		this.apply_button = createButton("apply_btn", this.width - 200, this.height - row_increment - start_y);
		this.reload_button = createButton("reload_btn", this.width - 385, this.height - row_increment - start_y);
		this.apply_button.addEventListener(ButtonEvent.CLICK, this.sendStringConfigFromAS);
		this.reload_button.addEventListener(ButtonEvent.CLICK, this.setStringConfigToAS);
		// bind to MOE button above.
		this.add_profile_to_moe_btn.addEventListener(ButtonEvent.CLICK, this.addProfileToMOE);
		 
		 // update the state after initiation.
		 this.setStringConfigToAS();
	  }
	  
	  internal function createMetaSetting(section_x: Number, section_y: Number, item_spacing: Number, row_increment: Number, box_offset: Number) : Object {
		// build the Meta-related setting of UML (additional libs, MOE etc.)
		// value to record the bound of this setting box
		var x_bound: Number = section_x; var y_bound: Number = section_y; 
		// value to calculate the current item
		var current_x: Number = section_x; var current_y: Number = section_y;
		
		// row 1 - all this in one line.
		this.moe_selector = createDropdown(current_x, current_y - box_offset);
		this.moe_selector.dataProvider = new DataProvider(retrieveLocalized("moe_options", ["Default MOE", "No MOE", "1 MOE", "2 MOE", "3 MOE"]) as Array);
		
		current_x += this.moe_selector.width + item_spacing;
		var moe_help_1 : LabelControl = createLabel("moe_list_desc", current_x, current_y);
		
		current_x += moe_help_1.width + item_spacing;
		this.moe_list = createTextInput("moe_list_placeholder", current_x, current_y - box_offset);
		
		current_x += this.moe_list.width + item_spacing;
		this.add_profile_to_moe_btn = createButton("add_profile_to_moe_desc", current_x, current_y, true);
		
		current_x += this.add_profile_to_moe_btn.width + item_spacing;
		var moe_help_2 : LabelControl = createLabel("moe_texture_desc", current_x, current_y);
		
		current_x = current_x + moe_help_2.width + item_spacing;
		this.moe_nation = createDropdown(current_x, current_y - box_offset);
		this.moe_nation.dataProvider = new DataProvider(["Default"]);
		this.moe_nation.selectedIndex = 0;
		this.moe_nation.enabled = false;
		
		x_bound = current_x + this.moe_nation.width; y_bound = current_y + row_increment;

		// row 2 
		current_x = section_x;
		current_y = current_y + row_increment;
		this.affect_hangar = createCheckbox("affect_hangar_desc", current_x, current_y);
		
		current_x += this.affect_hangar.width + item_spacing;
		this.use_UML_sound = createCheckbox("use_uml_sound_desc", current_x, current_y);

		current_x += this.use_UML_sound.width + item_spacing;
		this.remodels_filelist_label = createLabel("remodels_filelist_desc", current_x, current_y);
		
		current_x += this.remodels_filelist_label.width + item_spacing;
		this.remodels_filelist = createTextInput("remodel_filelist_placeholder", current_x, current_y - box_offset);
		
		x_bound = Math.max(x_bound, current_x + this.remodels_filelist.width);
		y_bound = current_y + row_increment;
		
		return { x: section_x, y: section_y, width: x_bound - x, height: y_bound - y };
	  }
 	  
	  internal function createProfileList(section_x: Number, section_y: Number, item_spacing: Number, row_increment: Number, box_offset: Number, profile_region_width: Array) : Object {
		// build the basic per-profile setting of UML.
		var current_x : Number = section_x;
		var current_y : Number = section_y;
		// button for forward/backward around the profile selector
		this.backward_btn = createButton("<", current_x, current_y, true);
		// menu to select profile to edit
		current_x += 30 + item_spacing;
		this.profile_selector = this.createDropdown(current_x, current_y - box_offset);
		this.profile_selector.width = profile_region_width[0];
		current_x += profile_region_width[0] + item_spacing;
		this.forward_btn = createButton(">", current_x, current_y, true);
		
		// ignore list & activated list, both in same column	
		current_x += 30 + item_spacing;
		this.toggle_show_ignore = createCheckbox("toggle_show_ignore_desc", current_x, current_y);
		current_y += row_increment;
		this.toggle_show_activated = createCheckbox("toggle_show_activated_desc", current_x, current_y)
		//this.profile_selector.dataProvider = new DataProvider(["option1", "option2"]);
		
		// section is moved downward 2 row & returned to first column
		// profile_region_width will denote [checkbox region][field desc][field region]
		var first_column_x: Number = section_x;
		var second_column_x: Number = first_column_x + profile_region_width[0];
		var third_column_x: Number = second_column_x + profile_region_width[1];
		current_x = section_x; current_y += row_increment;
		// format: profile name (label) - enable - whitelist
		//this.profile_selector.dataProvider.invalidate();
		this.current_profile_name = createTextInput("profile_placeholder", current_x, current_y - box_offset);
		this.current_profile_name.editable = false;
		this.current_profile_name.width = profile_region_width[0] + profile_region_width[1] - item_spacing; // make this span 1+2 col, minus usual spacing.
		this.current_profile_ignore = createCheckbox("current_profile_ignore_desc", third_column_x, current_y);
		// this.current_profile_name.autoSize = TextFieldAutoSize.LEFT;
		// this.current_profile_name.toolTip = "The full name of the profile.";
		current_y += row_increment;
		this.current_profile_target_help = createLabel("current_profile_target_desc", first_column_x, current_y);
		this.current_profile_target = createTextInput("whitelist_placeholder", second_column_x, current_y - box_offset);
		this.current_profile_target.width = profile_region_width[1] + profile_region_width[2]; // make this span 2+3 col; spacing should be handled by the desc if any.
		
		current_y += row_increment;
		this.current_profile_enable = createCheckbox("current_profile_enable_desc", first_column_x, current_y);
		this.current_profile_camo_help = createLabel("current_profile_camo_desc", second_column_x, current_y);
		this.current_profile_camo = createDropdown(third_column_x, current_y - box_offset);
		this.current_profile_camo.width = profile_region_width[2];
		
		current_y += row_increment;	
		this.current_profile_swapNPC = createCheckbox("current_profile_swapNPC_desc", first_column_x, current_y);
		this.current_profile_paint_help = createLabel("current_profile_paint_desc", second_column_x, current_y);
		this.current_profile_paint = createDropdown(third_column_x, current_y - box_offset);
		this.current_profile_paint.width = profile_region_width[2];
		
		current_y += row_increment;	
		this.current_profile_alignToTurret = createCheckbox("current_profile_alignToTurret_desc", first_column_x, current_y);
		this.current_profile_style_help = createLabel("current_profile_style_progression_desc", second_column_x, current_y);
		this.current_profile_style_progression = createTextInput("4", third_column_x, current_y - box_offset);
		this.current_profile_style_progression.width = 30; this.current_profile_style_progression.maxChars = 1; this.current_profile_style_progression.enabled = false;
		this.current_profile_style = createDropdown(third_column_x + this.current_profile_style_progression.width + item_spacing, current_y - box_offset);
		this.current_profile_style.width = profile_region_width[2] - this.current_profile_style_progression.width - item_spacing;

		current_y += row_increment;	
		this.current_profile_configString_help = createLabel("current_profile_configString_desc", second_column_x, current_y)
		this.current_profile_configString = createTextInput("N/A", third_column_x, current_y - box_offset);
		this.current_profile_configString.width = 60; this.current_profile_configString.maxChars = 4;
		
		current_y += row_increment;
		this.use_hangar_vehicle = createButton("use_hangar_vehicle_btn", section_x + 20, current_y, true);
		this.delete_profile = createButton("delete_profile_btn", section_x + 230, current_y, true);
		
		current_y += row_increment;
		// building section finish; populate options.
		this.populatePaintCamo();
		

		// adding appropriate listeners
		this.forward_btn.addEventListener(ButtonEvent.CLICK, this.forwardProfileIndex);
		this.backward_btn.addEventListener(ButtonEvent.CLICK, this.backwardProfileIndex);
		this.profile_selector.addEventListener(ListEvent.INDEX_CHANGE, this.loadProfileAtCurrentIndex);
		this.toggle_show_ignore.addEventListener(ButtonEvent.CLICK, this.reloadProfileSelector);
		this.toggle_show_activated.addEventListener(ButtonEvent.CLICK, this.reloadProfileSelector);
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
		return {x: section_x, y: section_y, width: profile_region_width[0] + profile_region_width[1] + profile_region_width[2], height: current_y - section_y};
	  }
	  
	  
	  internal function createProfileAdditionalFields(section_x: Number, section_y: Number, item_spacing: Number, row_increment: Number, box_offset: Number, sound_region_width: Array, hybrid_region_width: Array, subsection_indent: Number): Object {
		// build the advanced (sound effect, hybrid) options of UML.
		var current_x : Number = section_x; var current_y : Number = section_y;
		var sound_effect_help: LabelControl = createLabel("sound_effect_desc", current_x + subsection_indent, current_y);
		
		var onetwo_soundcol_x: Number = current_x + sound_region_width[0];
		var twoone_soundcol_x: Number = onetwo_soundcol_x + sound_region_width[1] + item_spacing;
		var twotwo_soundcol_x: Number = twoone_soundcol_x + sound_region_width[0];
		// first row - 2 item (oneone, onetwo | twoone, twotwo)
		current_y += row_increment;
		this.current_profile_gunEffect_help = createLabel("current_profile_gunEffect_desc", current_x, current_y);
		this.current_profile_gunEffect = createTextInput("", onetwo_soundcol_x, current_y - box_offset); this.current_profile_gunEffect.width = sound_region_width[1];
		this.current_profile_soundTurret_help = createLabel("current_profile_soundTurret_desc", twoone_soundcol_x, current_y);
		this.current_profile_soundTurret = createTextInput("", twotwo_soundcol_x, current_y - box_offset); this.current_profile_soundTurret.width = sound_region_width[1];
		// second row, same thing
		current_y += row_increment;
		this.current_profile_soundChassis_help = createLabel("current_profile_soundChassis_desc", current_x, current_y);
		this.current_profile_soundChassis = createTextInput("", onetwo_soundcol_x, current_y - box_offset); this.current_profile_soundChassis.width = sound_region_width[1];
		this.current_profile_soundEngine_help = createLabel("current_profile_soundEngine_desc", twoone_soundcol_x, current_y);
		this.current_profile_soundEngine = createTextInput("", twotwo_soundcol_x, current_y - box_offset); this.current_profile_soundEngine.width = sound_region_width[1];
		
		current_y += row_increment;
		this.hybrid_help = createLabel("hybrid_desc", current_x + subsection_indent, current_y);
		// 1-1 (chassis)
		current_y += row_increment;
		this.profile_chassis_help = createLabel("profile_chassis_desc", current_x, current_y);
		this.profile_chassis = createTextInput("N/A", current_x + hybrid_region_width[0], current_y - box_offset);
		this.profile_chassis_style = createDropdown(current_x, current_y + row_increment - box_offset); this.profile_chassis_style.width = hybrid_region_width[2];
		// 1-2 (hull)
		current_x += hybrid_region_width[0] + hybrid_region_width[1] + item_spacing;
		this.profile_hull_help = createLabel("profile_hull_desc", current_x, current_y);
		this.profile_hull = createTextInput("N/A", current_x + hybrid_region_width[0], current_y - box_offset);
		this.profile_hull_style = createDropdown(current_x, current_y + row_increment - box_offset); this.profile_hull_style.width = hybrid_region_width[2];
		this.profile_hull_from_selector = createButton("profile_hull_from_selector_desc", current_x + hybrid_region_width[2] + item_spacing, current_y + row_increment, true);
		
		// 2-1 (turret)
		current_x = section_x; current_y += row_increment * 2;
		this.profile_turret_help = createLabel("profile_turret_desc", current_x, current_y);
		this.profile_turret = createTextInput("N/A", current_x + hybrid_region_width[0], current_y - box_offset);
		this.profile_turret_style = createDropdown(current_x, current_y + row_increment - box_offset); this.profile_turret_style.width = hybrid_region_width[2];
		this.profile_turret_from_selector = createButton("profile_turret_from_selector_desc", current_x + hybrid_region_width[2] + item_spacing, current_y + row_increment, true);
		// 2-2 (gun)
		current_x += hybrid_region_width[0] + hybrid_region_width[1] + item_spacing;
		this.profile_gun_help = createLabel("profile_gun_desc", current_x, current_y);
		this.profile_gun = createTextInput("N/A", current_x + hybrid_region_width[0], current_y - box_offset);
		this.profile_gun_style = createDropdown(current_x, current_y + row_increment - box_offset); this.profile_gun_style.width = hybrid_region_width[2];
		this.profile_gun_from_selector = createButton("profile_gun_from_selector_desc", current_x + hybrid_region_width[2] + item_spacing, current_y + row_increment, true);
		this.profile_chassis.enabled = false;
		// extra increment to allow outputting the full section region.
		current_x = section_x; current_y += row_increment * 2;
		
		this.current_profile_gunEffect.addEventListener(FocusHandlerEvent.FOCUS_OUT, this.onEffectChange);
		this.current_profile_soundTurret.addEventListener(FocusHandlerEvent.FOCUS_OUT, this.onEffectChange);
		this.current_profile_soundChassis.addEventListener(FocusHandlerEvent.FOCUS_OUT, this.onEffectChange);
		this.current_profile_soundEngine.addEventListener(FocusHandlerEvent.FOCUS_OUT, this.onEffectChange);
		
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
		
		return {x: section_x, y: section_y, width: Math.max((sound_region_width[0] + sound_region_width[1]) * 2 + item_spacing, (hybrid_region_width[0] + hybrid_region_width[1]) * 2 + item_spacing), height: current_y - section_y};
	  }
	  
	  internal function createVehicleSelector(section_x: Number, section_y: Number, item_spacing: Number, row_increment: Number, box_offset: Number, dropdown_width: Number) : Object {
		// multiple dropdown list concerning nation-class-tier-vehicle to show the corresponding profile name
		this.help_vehicle_selector = createLabel("vehicle_selector_desc", section_x, section_y);
		this.vehicle_nations = createDropdown(section_x, section_y + row_increment); this.vehicle_nations.width = dropdown_width;
		this.vehicle_type = createDropdown(section_x + dropdown_width + item_spacing, y + section_y + row_increment); this.vehicle_type.width = dropdown_width;
		this.vehicle_tier = createDropdown(section_x, section_y + row_increment * 2); this.vehicle_tier.width = dropdown_width;
		this.vehicle_selector = createDropdown(section_x + dropdown_width + item_spacing, section_y + row_increment * 2); this.vehicle_selector.width = dropdown_width;
		this.vehicle_profile_field = createTextInput("vehicle_profile_name", section_x + dropdown_width / 2 + item_spacing / 2, section_y + row_increment * 3);
		this.vehicle_profile_field.width = dropdown_width;
		// button to add to the profile list or whitelist.
		this.add_profile_btn = createButton("add_profile_btn", section_x, section_y + row_increment * 4, true);
		this.add_whitelist_btn = createButton("add_whitelist_btn", section_x + dropdown_width + item_spacing, section_y + row_increment * 4, true);
		// button to add as a new profile
		this.add_profile_as_parent_btn = createButton("add_profile_as_parent_btn", section_x, section_y + row_increment * 5, true);
		this.profile_with_parent_field = createTextInput("profile_with_parent_placeholder", section_x, section_y + row_increment * 6);
		
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
		
		return {x: section_x, y: section_y, width: dropdown_width * 2 + item_spacing, height: row_increment * 7}; // 650
	  }
	  
	  internal function createAdditionalSettings(section_x: Number, section_y: Number, item_spacing: Number, row_increment: Number, box_offset: Number, swapall_width: Number): Object {
		// these don't need listener, since they are strictly updated on Apply anyway. Except the add button.
		var additional_setting_help : LabelControl = createLabel("additional_setting_desc", section_x, section_y);
		this.remove_unhistorical = createCheckbox("remove_unhistorical_desc", section_x, section_y + row_increment);
		this.remove_3d_style = createCheckbox("remove_3d_style_desc", section_x, section_y + row_increment * 2);
		this.remove_clan_logo = createCheckbox("remove_clan_logo_desc", section_x, section_y + row_increment * 3);
		var force_clan_logo_help : LabelControl = createLabel("force_clan_logo_desc", section_x, section_y + row_increment * 4);
		this.force_clan_logo = createTextInput("N/A", section_x + force_clan_logo_help.width + item_spacing, section_y + row_increment * 4); this.force_clan_logo.width = 75; this.force_clan_logo.enabled = false;
		
		this.swap_friendly_enable = createCheckbox("swap_friendly_enable_desc", section_x, section_y + row_increment * 5);
		var swap_friendly_help : LabelControl = createLabel("swap_friendly_desc", section_x, section_y + row_increment * 6);
		this.swap_friendly = createTextInput("swap_friendly_placeholder", section_x + swap_friendly_help.width + item_spacing, section_y + row_increment * 6 - box_offset);
		this.swap_friendly.width = swapall_width;
		this.add_profile_friendly = createButton("add_profile_friendly_desc", section_x + swap_friendly_help.width + swapall_width + item_spacing * 2, section_y + row_increment * 6, true);
		
		this.swap_enemy_enable = createCheckbox("swap_enemy_enable_desc", section_x, section_y + row_increment * 7);
		var swap_enemy_help : LabelControl = createLabel("swap_enemy_desc", section_x, section_y + row_increment * 8);
		this.swap_enemy = createTextInput("swap_enemy_placeholder", section_x + swap_enemy_help.width + item_spacing, section_y + row_increment * 8 - box_offset);
		this.swap_enemy.width = swapall_width;
		this.add_profile_enemy = createButton("add_profile_enemy_desc", section_x + swap_enemy_help.width + swapall_width + item_spacing * 2, section_y + row_increment * 8, true);
		
		this.add_profile_friendly.addEventListener(ButtonEvent.CLICK, this.addCurrentProfileToSwapList);
		this.add_profile_enemy.addEventListener(ButtonEvent.CLICK, this.addCurrentProfileToSwapList);
		
		return {x: section_x, y: section_y, width: swap_friendly_help.width + swapall_width + item_spacing * 2 + this.add_profile_friendly.width, height: row_increment * 9}
	  }
	  
	  internal function populatePaintCamo() : void {
		this.customization_data = this.loadCustomizationDataFromPy();
		// update with Remove & No change (-1, 0)
		this.customization_data["camoName"].unshift(retrieveLocalizedString("camo_remove_option", "camo_remove_option"), retrieveLocalizedString("camo_no_change_option", "camo_no_change_option"));
		this.customization_data["paintName"].unshift(retrieveLocalizedString("paint_remove_option", "paint_remove_option"), retrieveLocalizedString("paint_no_change_option", "paint_no_change_option"));
		this.customization_data["decalName"].unshift(retrieveLocalizedString("decal_remove_option", "decal_remove_option"), retrieveLocalizedString("decal_no_change_option", "decal_no_change_option"));
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
			
			this.current_profile_gunEffect.removeEventListener(FocusHandlerEvent.FOCUS_OUT, this.onEffectChange);
			this.current_profile_soundTurret.removeEventListener(FocusHandlerEvent.FOCUS_OUT, this.onEffectChange);
			this.current_profile_soundChassis.removeEventListener(FocusHandlerEvent.FOCUS_OUT, this.onEffectChange);
			this.current_profile_soundEngine.removeEventListener(FocusHandlerEvent.FOCUS_OUT, this.onEffectChange);
			
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
	  
	  internal function loadPairedValues(field : TextInput, firstval : String, secondval : String, separator : String = "|") : void {
		// load paired values for PC/NPC and gunEffect/gunReload.
		if(firstval != "" || secondval != "") {
			if(firstval == secondval) {
				field.text = firstval; // duplicate value, display only one
			} else {
				field.text = firstval + separator + secondval; // non-duplicate, display both separatedly
			}
		} else {
			field.text = "N/A"; // both field not exist, display invalid
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
		loadPairedValues(this.current_profile_gunEffect, currentProfile["effectsGun"], currentProfile["effectsReload"]);
		this.current_profile_soundTurret.text = (currentProfile["soundTurret"] == "") ? "N/A" : currentProfile["soundTurret"];
		loadPairedValues(this.current_profile_soundChassis, currentProfile["soundChassisPC"], currentProfile["soundChassisNPC"]);
		loadPairedValues(this.current_profile_soundEngine, currentProfile["soundEnginePC"], currentProfile["soundEngineNPC"]);
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
	  
	  internal function onEffectChange(event : Object, actual_target : DropdownMenu = null, separator : String="|") : void {
		var current_profile : Object = this.list_profile_objects[this.profile_selector.selectedIndex];
		var effect_object : TextInput = (actual_target ? actual_target : event.target) as TextInput; 
		var firstTarget : String, secondTarget: String;
		switch (effect_object) {
			case this.current_profile_soundTurret: // only one field, escape
				current_profile["soundTurret"] = effect_object.text;
				return;
			case this.current_profile_gunEffect:
				firstTarget = "effectsGun", secondTarget = "effectsReload";
				break;
			case this.current_profile_soundChassis:
				firstTarget = "soundChassisPC", secondTarget = "soundChassisNPC";
				break;
			case this.current_profile_soundEngine:
				firstTarget = "soundEnginePC", secondTarget = "soundEngineNPC";
				break;
		}
		if(effect_object.text == "N/A") {
			current_profile[firstTarget] = ""; current_profile[secondTarget] = ""; // nothing
		} else if(effect_object.text.indexOf(separator) >= 0) {
			var splitted : Array = effect_object.text.split(separator); // splitted version
			current_profile[firstTarget] = splitted[0]; current_profile[secondTarget] = splitted[1];
		} else { // combined version (both are the same)
			current_profile[firstTarget] = effect_object.text;
			current_profile[secondTarget] = effect_object.text;
		}
	  }
	  
	  internal function loadVehiclesWithCriteriaToAS() : void {
		// attempt to load vehicles using nation, type and tier filtering
		var vehicles_data : Array = this.loadVehiclesWithCriteriaFromPy(this.vehicle_nations.selectedIndex, this.vehicle_type.selectedIndex, this.vehicle_tier.selectedIndex);
		// DebugUtils.LOG_WARNING("[UML GUI][AS] Debug: vehicle data received: " + App.utils.JSON.encode(vehicles_data) + ". Check to see what failed.");
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
			DebugUtils.LOG_DEBUG("[UML GUI][AS] Debug: targetting " + remove_profile_name + " in-field index [" + String(remove_index) + "] true index [" + String(true_remove_index) + "].");
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
			if(this.toggle_show_activated.selected) {
				// show only the activated ones
				this.list_profile_objects = [];
				for each (var ob : Object in this.list_all_profile_objects) {
					if(ob["enabled"]) this.list_profile_objects.push(ob)
				}
			} else {
				// show all profiles
				this.list_profile_objects = this.list_all_profile_objects;
			}
			//DebugUtils.LOG_WARNING("[UML GUI][AS] Debug: entering unfiltered profile @reloadProfileSelector");
		} else {
			// show un-ignored profiles
			this.list_profile_objects = [];
			for each(var o : Object in this.list_all_profile_objects) {
				if(this.list_ignore_profiles.indexOf(o["name"]) < 0 && (!this.toggle_show_activated.selected || o["enabled"])) { 
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
		// hack to make sure checkbox always show its full length
		var desc: String =  retrieveLocalizedString(label, label);
		return addChild(App.utils.classFactory.getComponent("CheckBox", CheckBox, { "x": x, "y": y, "label": desc, "selected": false, "width": 10 + (this.position_data["checkbox_width_per_char"] || 10) * desc.length })) as CheckBox;
	  }
	  
	  internal function createButton(label: String, x: Number, y: Number, dynamicSizeByText: Boolean = false) : SoundButtonEx {
		return addChild(App.utils.classFactory.getComponent("ButtonNormal", SoundButtonEx, { "x": x, "y": y, "label": retrieveLocalizedString(label, label),
				"dynamicSizeByText": dynamicSizeByText })) as SoundButtonEx;
	  }
	  
	  internal function createTextInput(lbltext: String, x: Number, y: Number) : TextInput {
		var textInput : TextInput = addChild(App.utils.classFactory.getComponent("TextInput", TextInput, { "x": x, "y": y, "text": lbltext })) as TextInput;
		TextFieldEx.setNoTranslate(textInput.textField, true);
		return textInput;
	  }
	  
	  internal function createLabel(lbltext: String, x: Number, y: Number) : LabelControl {
		return addChild(App.utils.classFactory.getComponent("LabelControl", LabelControl, { "x": x, "y": y, "autoSize": true, "text": retrieveLocalizedString(lbltext, lbltext) })) as LabelControl;
	  }
	  
	  internal function createDropdown(x: Number, y: Number) : DropdownMenu {
		var dropdown : DropdownMenu = addChild(App.utils.classFactory.getComponent("DropdownMenuUI", DropdownMenu, { "x": x, "y": y, "itemRenderer": App.utils.classFactory.getClass("DropDownListItemRendererSound")
			})) as DropdownMenu;
		dropdown.dropdown = "DropdownMenu_ScrollingList";
		return dropdown
	  }
	  
	  internal function retrieveLocalized(cue: String, default_: Object) : Object {
		// try to search for cue; if not exist, output default_str
		if(!(cue in this.localization_data)) {
			DebugUtils.LOG_WARNING("[UML GUI][AS] Cannot find localization for `" + cue + "`. Will use default: " + default_ + ".");
			return default_;
		}
		return this.localization_data[cue];
	  }
	  
	  internal function retrieveLocalizedString(cue: String, default_: String): String {
		return retrieveLocalized(cue, default_) as String;
	  }
	  
	  internal function updateText(item_name: String, lbltext: String, item_type: String) : Boolean  {
		if(!(item_name in this)) {
			DebugUtils.LOG_WARNING("[UML GUI][AS] Cannot find item `" + item_name + "`. Check if it's a correct property.");
			return false;
		}
		switch(item_type) {
			case "button":
				var correct_button : SoundButtonEx = this[item_name] as SoundButtonEx;
				correct_button.label = lbltext;
				return true;
			case "label":
				var correct_label : LabelControl = this[item_name] as LabelControl;
				correct_label.text = lbltext;
				return true;
			case "checkbox":
				var correct_checkbox: CheckBox = this[item_name] as CheckBox;
				correct_checkbox.label = lbltext;
			default:
				DebugUtils.LOG_WARNING("[UML GUI][AS] Item type `" + item_type + "`is not valid (must be button, label or checkbox).")
				return false;
		}
	  }
	  
	}
}
