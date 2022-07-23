package uml
{
	import flash.events.Event;
	import scaleform.clik.events.ButtonEvent;
	import scaleform.clik.events.ListEvent;
	import scaleform.clik.events.FocusHandlerEvent;
	import mx.utils.StringUtil;
	
	import scaleform.clik.data.DataProvider;

	import scaleform.gfx.TextFieldEx;
	import net.wg.infrastructure.base.AbstractWindowView;
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
	
	public class ReplaceOwnCustomizationGUI extends AbstractWindowView
	{
		public var getCustomizationDictFromPy : Function = null; // load and update the dict using this 
		public var updateCustomizationDictAtPy : Function = null;
		public var loadCustomizationDataFromPy : Function = null; // this will load the needed data to camo/paint/decal/personalnumber dropdown
		
		
		protected var affect_hangar : CheckBox;
		protected var target_customization : DropdownMenu;
		protected var exclude_3D_styles: CheckBox;
		protected var first_emblem : DropdownMenu;
		protected var second_emblem : DropdownMenu;
		protected var force_both_emblem : CheckBox;
		protected var summer_camo : DropdownMenu;
		protected var winter_camo : DropdownMenu;
		protected var desert_camo : DropdownMenu;
		protected var summer_paint : DropdownMenu;
		protected var winter_paint : DropdownMenu;
		protected var desert_paint : DropdownMenu;
		protected var pnumber_id : DropdownMenu; 
		protected var pnumber : TextInput; 
		protected var bwlist_content : TextInput; 
		protected var bwlist_selector: DropdownMenu; 
		
		protected var customization_data : Object;
		protected var forced_customization : Object;
		
		internal var apply_button : SoundButtonEx;
		internal var reload_button : SoundButtonEx;
		internal var reload_from_disk_button : SoundButtonEx;
		
		public function ReplaceOwnCustomizationGUI() {
		 super();
		}

		override protected function onPopulate() : void {
			super.onPopulate();
			
			this.customization_data = this.loadCustomizationDataFromPy()
			
			this.width = 510;
			this.height = this.createForcedCustomizationSelector(10, 10) + 10 + 35; // = 180;
			
			this.apply_button = createButton("Apply", this.width - 10 - 55, this.height - 35, true);
			this.reload_button = createButton("Reload", this.width - 10 - 110, this.height - 35, true);
			this.reload_from_disk_button = createButton("Reload from File", this.width - 10 - 225, this.height - 35, true);
			this.apply_button.addEventListener(ButtonEvent.CLICK, this.updateCustomizationDictFromAS);
			this.reload_button.addEventListener(ButtonEvent.CLICK, this.loadCustomizationDictAtAS); 
			this.reload_from_disk_button.addEventListener(ButtonEvent.CLICK, this.loadCustomizationDictAtAS); 
			
			this.loadCustomizationDictAtAS(null, true);
			this.reloadForcedCustomization();
		}
		
		override protected function onDispose() : void {
			super.onDispose();
		}
		
		protected function loadCustomizationDictAtAS(e : Event, reload : Boolean = false) : void { // both load and reload
			var dataFromPy : String = this.getCustomizationDictFromPy(reload || e.target == this.reload_from_disk_button);
			DebugUtils.LOG_WARNING("[ROC][AS] Debug: loaded data from Python:" + dataFromPy + " (reload " + String(reload || e.target == this.reload_from_disk_button) + ")");
			var customizationDict : Object = App.utils.JSON.decode(dataFromPy);
			this.forced_customization = [customizationDict["player"], customizationDict["ally"], customizationDict["enemy"]];
		}
		
		protected function updateCustomizationDictFromAS() : void {
			var customizationDict : Object = {"player": this.forced_customization[0], "ally": this.forced_customization[1], "enemy": this.forced_customization[2]}
			var dataToPy : String = App.utils.JSON.encode(customizationDict);
			DebugUtils.LOG_WARNING("[ROC][AS] Debug: sending data to Python :" + dataToPy);
			this.updateCustomizationDictAtPy(dataToPy);
		}
		
		internal function createForcedCustomizationSelector(x: Number, y: Number): Number {
			// Dropdown list selecting: Target (player, ally, enemy); 
			//							first_emblem, second_emblem; camo set of 3; paint set of 3
			var help_forced_customization : LabelControl = createLabel("Force Customization", x, y);
			this.exclude_3D_styles = createCheckbox("Ignore 3D", x + 125, y);
			this.target_customization = createDropdown(x + 125 + 110, y - 3);
			this.target_customization.width = 80;
			this.affect_hangar = createCheckbox("Affect Hangar", x + 125 + 110 + 100, y);
			var emblem_help : LabelControl = createLabel("Emblems: ", x, y + 25);
			this.first_emblem = createDropdown(x + 95, y + 25 - 3);
			this.second_emblem = createDropdown(x + 95 + 130, y + 25 - 3);
			this.force_both_emblem = createCheckbox("Force both emblems", x + 95 + 260, y + 25);
			var camo_help : LabelControl = createLabel("Camo (S-W-D): ", x, y + 50);
			this.summer_camo = createDropdown(x + 95, y + 50 - 3);
			this.winter_camo = createDropdown(x + 95 + 130, y + 50 - 3);
			this.desert_camo = createDropdown(x + 95 + 260, y + 50 - 3);
			var paint_help : LabelControl = createLabel("Paint (S-W-D): ", x, y + 75);
			this.summer_paint = createDropdown(x + 95, y + 75 - 3);
			this.winter_paint = createDropdown(x + 95 + 130 , y + 75 - 3);
			this.desert_paint = createDropdown(x + 95 + 260, y + 75 - 3);
			// Number list setting: Dropdown for ingame ID + created number
			var number_help : LabelControl = createLabel("Personal Number: ", x, y + 100);
			this.pnumber_id = createDropdown(x + 115, y + 100 - 3);
			this.pnumber_id.width = 150;
			this.pnumber = createTextInput("placeholder_personal_number", x + 115 + 155, y + 100 - 3);
			this.pnumber.width = 70;
			// Blacklist/Whitelist options
			this.bwlist_content = createTextInput("placeholder_bwlist", x + 25, y + 125 - 3);
			this.bwlist_content.width = 150;
			var bwlist_help : LabelControl = createLabel("As", x + 25 + 155, y + 125);
			this.bwlist_selector = createDropdown(x + 25 + 155 + 25, y + 125 - 2);
			this.bwlist_selector.dataProvider = new DataProvider(["Blacklist", "Whitelist"]);
			
			// update values to help forced customization
			this.customization_data["camoName"].unshift("Remove", "No change"); this.customization_data["camoID"].unshift(-1, 0);
			this.customization_data["paintName"].unshift("Remove", "No change"); this.customization_data["paintID"].unshift(-1, 0);
			this.customization_data["decalName"].unshift("Remove", "No change"); this.customization_data["decalID"].unshift(-1, 0);
			
			this.customization_data["sec_camoName"] = this.customization_data["camoName"].concat(); this.customization_data["sec_camoName"].unshift("Same as Summer");
			this.customization_data["sec_paintName"] = this.customization_data["paintName"].concat(); this.customization_data["sec_paintName"].unshift("Same as Summer");
			this.customization_data["sec_decalName"] = this.customization_data["decalName"].concat(); this.customization_data["sec_decalName"].unshift("Same as First");
			this.customization_data["sec_camoID"] = this.customization_data["camoID"].concat(); this.customization_data["sec_camoID"].unshift(-2);
			this.customization_data["sec_paintID"] = this.customization_data["paintID"].concat(); this.customization_data["sec_paintID"].unshift(-2);
			this.customization_data["sec_decalID"] = this.customization_data["decalID"].concat(); this.customization_data["sec_decalID"].unshift(-2);
			
			this.customization_data["numberName"].unshift("Not used"); this.customization_data["numberID"].unshift(0);
			
			this.target_customization.dataProvider = new DataProvider(["Player", "Ally", "Enemy"]);
			this.first_emblem.dataProvider = new DataProvider(this.customization_data["decalName"]);
			this.second_emblem.dataProvider = new DataProvider(this.customization_data["sec_decalName"]);
			this.summer_camo.dataProvider = new DataProvider(this.customization_data["camoName"]);
			this.winter_camo.dataProvider = new DataProvider(this.customization_data["sec_camoName"]);
			this.desert_camo.dataProvider = new DataProvider(this.customization_data["sec_camoName"]);
			this.summer_paint.dataProvider = new DataProvider(this.customization_data["paintName"]);
			this.winter_paint.dataProvider = new DataProvider(this.customization_data["sec_paintName"]);
			this.desert_paint.dataProvider = new DataProvider(this.customization_data["sec_paintName"]);
			this.pnumber_id.dataProvider = new DataProvider(this.customization_data["numberName"]);
			
			this.target_customization.selectedIndex = 0;
			var customization_data : Object = this.customization_data;
			// var _updateCustomizationData : Function = updateCustomizationData;
			// event binding
			this.affect_hangar.addEventListener(ButtonEvent.CLICK, this.updateCustomizationData);
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
			this.pnumber_id.addEventListener(ListEvent.INDEX_CHANGE, this.updateCustomizationData);
			this.pnumber.addEventListener(FocusHandlerEvent.FOCUS_OUT, this.onPersonalNumberChange);
			this.bwlist_selector.addEventListener(ListEvent.INDEX_CHANGE, this.onBWListChange);
			this.bwlist_content.addEventListener(FocusHandlerEvent.FOCUS_OUT, this.onBWListChange);
			
			return y + 150; // 410
		}
		
		internal function reloadForcedCustomization() : void {
			//reload_dict = reload_dict == null ? this.forced_customization : reload_dict;
			var target_dict : Object = this.forced_customization[this.target_customization.selectedIndex];
			// DebugUtils.LOG_WARNING("debug @reloadForcedCustomization: " + App.utils.JSON.encode(target_dict));
			this.affect_hangar.selected = this.forced_customization[0]["affectHangar"];
			this.exclude_3D_styles.selected = target_dict["exclude3DStyle"];
			this.first_emblem.selectedIndex = this.customization_data["decalID"].indexOf(target_dict["forcedEmblem"][0]);
			this.second_emblem.selectedIndex = this.customization_data["sec_decalID"].indexOf(target_dict["forcedEmblem"][1]);
			this.force_both_emblem.selected = target_dict["forcedBothEmblem"];
			this.summer_camo.selectedIndex = this.customization_data["camoID"].indexOf(target_dict["forcedCamo"][0]);
			this.winter_camo.selectedIndex = this.customization_data["sec_camoID"].indexOf(target_dict["forcedCamo"][1]);
			this.desert_camo.selectedIndex = this.customization_data["sec_camoID"].indexOf(target_dict["forcedCamo"][2]);
			this.summer_paint.selectedIndex = this.customization_data["paintID"].indexOf(target_dict["forcedPaint"][0]);
			this.winter_paint.selectedIndex = this.customization_data["sec_paintID"].indexOf(target_dict["forcedPaint"][1]);
			this.desert_paint.selectedIndex = this.customization_data["sec_paintID"].indexOf(target_dict["forcedPaint"][2]);
			
			if(target_dict.hasOwnProperty("blacklist") && target_dict["blacklist"] != "") {
				// blacklist property exist as not-blank, use it
				this.bwlist_content.text = target_dict["blacklist"]
				this.bwlist_selector.selectedIndex = 0;
			} else {
				this.bwlist_content.text = target_dict["whitelist"]
				this.bwlist_selector.selectedIndex = 1;
			}
			
			this.pnumber_id.selectedIndex = this.customization_data["numberID"].indexOf(target_dict["personalNumberID"]);
			var pnumber : Number = target_dict["personalNumber"];
			this.pnumber.text = (pnumber == -999) ? "random" : ((pnumber == -239) ? "hash" : String(pnumber)) ;
		}
	  
		internal function updateCustomizationData(e : Event) : void {
			var target_dict : Object = this.forced_customization[this.target_customization.selectedIndex];
			// DebugUtils.LOG_WARNING("After target_dict");
			/*for(var key : String in this.customization_data) {
				DebugUtils.LOG_WARNING("debug @updateCustomizationData - key [" + key + "]; length " + String(this.customization_data[key].length));
			}*/
			if(this.affect_hangar == e.target) {
				this.forced_customization[0]["affectHangar"] = this.affect_hangar.selected;
			} else {
				switch(e.target) {
					case this.exclude_3D_styles:
						target_dict["exclude3DStyle"] = this.exclude_3D_styles.selected;
						break;
					case this.force_both_emblem:
						target_dict["forcedBothEmblem"] = this.force_both_emblem.selected;
						break;
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
					case this.pnumber_id:
						target_dict["personalNumberID"] = this.customization_data["numberID"][this.pnumber_id.selectedIndex];
						break;
				}
			}
		}
		
		internal function onPersonalNumberChange() : void {
			var target_dict : Object = this.forced_customization[this.target_customization.selectedIndex];
			var pnumber_str : String = StringUtil.trim(this.pnumber.text);
			var pnumber : Number;
			if(pnumber_str == "random")
				pnumber = -999 // random is -999
			else if(pnumber_str == "hash")
				pnumber = -239
			pnumber = Number(pnumber_str);
			if(isNaN(pnumber)) pnumber = 0;
			target_dict["personalNumber"] = pnumber;
		}
		
		internal function onBWListChange() : void {
			var target_dict : Object = this.forced_customization[this.target_customization.selectedIndex];
			if(this.bwlist_selector.selectedIndex == 0) {
				target_dict["blacklist"] = this.bwlist_content.text;
				target_dict["whitelist"] = "";
			} else if(this.bwlist_selector.selectedIndex == 1) {
				target_dict["whitelist"] = this.bwlist_content.text;
				target_dict["blacklist"] = "";
			} else {
				DebugUtils.LOG_WARNING("[ROC][AS] invalid index @this.bwlist_selector: " + String(this.bwlist_selector.selectedIndex));
			}
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