#include "zscript/ui/widget_classes/ui_ddsmbutton.zs"
	#include "zscript/ui/widget_classes/ui_ddsmbutton_install.zs"
	#include "zscript/ui/widget_classes/ui_ddsmbutton_toglaug.zs"
	#include "zscript/ui/widget_classes/ui_ddsmbutton_usecell.zs"
	#include "zscript/ui/widget_classes/ui_ddsmbutton_upgrade.zs"
#include "zscript/ui/widget_classes/ui_ddlabel.zs"
#include "zscript/ui/widget_classes/ui_ddmultilinelabel.zs"
#include "zscript/ui/widget_classes/ui_ddscrollbar.zs"

#include "zscript/ui/widget_classes/ui_ddcanisteraugbutn.zs"
#include "zscript/ui/widget_classes/ui_ddinstalledaugbutn.zs"
#include "zscript/ui/widget_classes/ui_ddinstalledauglvldisp.zs"
#include "zscript/ui/widget_classes/ui_dditemframe.zs"
#include "zscript/ui/widget_classes/ui_ddbioelenergybar.zs"

class UI_Widget ui
{
	ui double x, y; // top-left coordinates of the widget
	// Should not be changed manually
	ui double w, h; // size of the whole widget (for input processing)

	ui bool hidden; // true if should be skipped during draw events.

	ui bool ui_init; // true if was renderered at least 1 time.

	// ------------------------
	// Widget management events
	// ------------------------

	// Called when added to a window
	virtual void init() {}
	// Called when first tried to render
	ui virtual void UIInit() {}

	// --------------
	// Drawing events
	// --------------

	// Called from RenderUnderlay() event
	ui virtual void drawUnderlay(RenderEvent e) {} 

	// Called from RenderOverlay() event
	ui virtual void drawOverlay(RenderEvent e) {}


	// ------------
	// Input events
	// ------------

	// Called from UiProcess() event,
	// and only if demandsUIProcessor == true for parent window.
	ui virtual void processUIInput(UiEvent e) {}

	// Called from InputProcess() event,
	// processes generic input.
	ui virtual void processInput(InputEvent e) {}

	// Called from UiTick() event.
	ui virtual void uiTick() {}
}
