import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class TradeSessionsLcdApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [new TradeSessionsLcdView()];
    }

    //! Called when settings are changed from the Connect IQ phone app.
    function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }

    //! On-watch settings editor (watch face picker > Customize/Settings).
    function getSettingsView() as [Views] or [Views, InputDelegates] or Null {
        return [SessionConfig.buildSettingsMenu(), new SessionSettingsDelegate()];
    }
}
