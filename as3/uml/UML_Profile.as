package uml
{
	import flash.display.DisplayObject;
   import scaleform.clik.controls.Label;
   import scaleform.clik.controls.ListItemRenderer;
   
	import net.wg.gui.components.controls.SoundListItemRenderer;
	import net.wg.gui.components.controls.DragableListItemRenderer;
	import net.wg.gui.components.controls.UILoaderAlt;
	import net.wg.gui.events.UILoaderEvent;
	import net.wg.gui.components.controls.DropdownMenu;
	import net.wg.gui.components.controls.LabelControl;
   import flash.events.IOErrorEvent;
	public class UML_Profile extends SoundListItemRenderer {

		  // internal var profile_droplist : DropdownMenu;
		  public var profileIcon : UILoaderAlt;
		  public var profileNameTF : LabelControl;
		  
		  function UML_Profile () {
			super();
		    DebugUtils.LOG_WARNING("Object UML_Profile created.");
		  }
		  
		  override protected function configUI() : void {
			super.configUI();
		    DebugUtils.LOG_WARNING("UML_Profile configUI called for object: " + App.utils.JSON.encode(this.data));
			this.profileIcon = addChild(App.utils.classFactory.getComponent(App.utils.classFactory.getClassName(UILoaderAlt), UILoaderAlt, 
			{ "x": 0, "y": 0, "source": "gui/maps/icons/vehicle/noImage.png", "sourceAlt": "gui/maps/icons/vehicle/noImage.png"})) as UILoaderAlt;
			this.profileNameTF = addChild(App.utils.classFactory.getComponent(App.utils.classFactory.getClassName(LabelControl), LabelControl, 
			{ "x": 0, "y": 100, "text": "Placeholder profile label" })) as LabelControl;
			this.width = 1400;
			this.height = 160;
			this.preventAutosizing = true;
			this.profileNameTF.visible = true;
			// this.profileIcon.addEventListener(UILoaderEvent.COMPLETE,this.handleMapIconLoaded);
		  }
		  
		  override public function setData(objdata : Object) : void {
		    DebugUtils.LOG_WARNING("UML_Profile setData called for object: " + App.utils.JSON.encode(objdata));
			this.data = objdata;
			//this.profileNameTF.text = this.data.profile_name
			this.profileIcon.sourceAlt = "gui/maps/icons/vehicle/noImage.png";
			try {
				this.profileIcon.source = "gui/maps/icons/vehicle/" + this.data.nation_name + "-" + this.data.profile_name + ".png";  // should be 160x100 img
			} catch (e : Error) { // doesn't happen, but might as well.
				DebugUtils.LOG_ERROR("ProfileIcon load error, stack trace:"  + e.getStackTrace())
				this.profileIcon.startLoadAlt()
			}
			this.alpha = 1;
			this.visible = true;
			this.profileIcon.visible = true;
			this.enabled = false;
			//this.invalidateData();
		  }
		  
		  override protected function draw() : void {
			DebugUtils.LOG_WARNING("UML_Profile draw called for object: " + App.utils.JSON.encode(this.data));
			super.draw();
		  }
		  
		  override protected function updateAfterStateChange() : void {
		    DebugUtils.LOG_WARNING("UML_Profile updateAfterStateChange called for object: " + App.utils.JSON.encode(this.data));
            super.updateAfterStateChange();
        }
		  
		  override protected function onDispose() : void {
			this.data = null
			super.onDispose();
		  }
	}	  
}