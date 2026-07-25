import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

//! Session hours (UTC), shared by the drawing code, the on-watch settings
//! menu and the phone-app settings (properties.xml / settings.xml).
module SessionConfig {

    function openKeys() as Array<String> {
        return ["SydOpen", "TyoOpen", "LdnOpen", "NycOpen"];
    }

    function closeKeys() as Array<String> {
        return ["SydClose", "TyoClose", "LdnClose", "NycClose"];
    }

    function openDefaults() as Array<Number> {
        return [22, 0, 8, 13];
    }

    function closeDefaults() as Array<Number> {
        return [7, 9, 17, 22];
    }

    function names() as Array<String> {
        return ["Sydney", "Tokyo", "London", "New York"];
    }

    function readHour(key as String, def as Number) as Number {
        var v = null;
        try {
            v = Application.Properties.getValue(key);
        } catch (e) {
            v = null;
        }
        if (v instanceof Number && v >= 0 && v <= 23) {
            return v;
        }
        return def;
    }

    function openHour(i as Number) as Number {
        return readHour(openKeys()[i], openDefaults()[i]);
    }

    function closeHour(i as Number) as Number {
        return readHour(closeKeys()[i], closeDefaults()[i]);
    }

    function defaultFor(key as String) as Number {
        var ok = openKeys();
        var ck = closeKeys();
        for (var i = 0; i < 4; i++) {
            if (ok[i].equals(key)) {
                return openDefaults()[i];
            }
            if (ck[i].equals(key)) {
                return closeDefaults()[i];
            }
        }
        return 0;
    }

    function buildSettingsMenu() as Menu2 {
        var menu = new WatchUi.Menu2({:title => "Sessions UTC"});
        var nm = names();
        var ok = openKeys();
        var ck = closeKeys();
        for (var i = 0; i < 4; i++) {
            menu.addItem(new WatchUi.MenuItem(nm[i] + " open",
                openHour(i).format("%02d") + ":00 UTC", ok[i], null));
            menu.addItem(new WatchUi.MenuItem(nm[i] + " close",
                closeHour(i).format("%02d") + ":00 UTC", ck[i], null));
        }
        return menu;
    }
}

//! On-watch settings: selecting an item advances that session boundary by
//! one hour, wrapping at 24.
class SessionSettingsDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as MenuItem) as Void {
        var key = item.getId() as String;
        var v = (SessionConfig.readHour(key, SessionConfig.defaultFor(key)) + 1) % 24;
        Application.Properties.setValue(key, v);
        item.setSubLabel(v.format("%02d") + ":00 UTC");
    }
}
