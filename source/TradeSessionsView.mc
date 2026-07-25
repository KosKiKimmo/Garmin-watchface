import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

//! Forex trading sessions watch face.
//!
//! Renders a 24-hour UTC dial (00:00 UTC at the top, time running clockwise)
//! with one colored arc per major forex session. A white radial marker shows
//! the current UTC time — every arc the marker crosses is a session that is
//! open right now. The center shows local time, date, UTC time, battery and
//! a countdown to the next session open/close.
class TradeSessionsView extends WatchUi.WatchFace {

    // Session start/end hours are in UTC. These are the commonly used
    // fixed-UTC approximations (see README for the DST caveat).
    private var _abbrs as Array<String> = ["SYD", "TYO", "LDN", "NYC"];
    private var _startHour as Array<Number> = [22, 0, 8, 13];
    private var _endHour as Array<Number> = [7, 9, 17, 22];
    private var _colors as Array<Number> = [
        0xFFAA00,  // Sydney  - amber
        0xFF0000,  // Tokyo   - red
        0x00AAFF,  // London  - blue
        0x00FF55   // New York- green
    ];

    function initialize() {
        WatchFace.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2.0;
        var cy = h / 2.0;
        // Scale factor so the layout tuned for 260x260 (fenix 7 / 7 Pro)
        // also fits the 280x280 fenix 7X.
        var k = w / 260.0;

        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var clock = System.getClockTime();
        var utcMinutes = localToUtcMinutes(clock);

        drawTicks(dc, cx, cy, w);
        drawSessionArcs(dc, cx, cy, k, utcMinutes);
        drawTimeMarker(dc, cx, cy, k, w, utcMinutes);
        drawCenterInfo(dc, cx, cy, k, clock, utcMinutes);
        drawLegend(dc, cx, cy, k, utcMinutes);
    }

    //! Minutes since midnight UTC, derived from local clock time.
    private function localToUtcMinutes(clock as System.ClockTime) as Number {
        var localSec = clock.hour * 3600 + clock.min * 60 + clock.sec;
        var utcSec = localSec - clock.timeZoneOffset;
        utcSec = ((utcSec % 86400) + 86400) % 86400;
        return utcSec / 60;
    }

    //! Dial angle in degrees for a given UTC hour position.
    //! 00:00 UTC is at the top (90 deg), time increases clockwise.
    private function hourToAngle(hour as Float) as Float {
        return 90.0 - hour * 15.0;
    }

    private function isOpen(idx as Number, utcMinutes as Number) as Boolean {
        var start = _startHour[idx] * 60;
        var end = _endHour[idx] * 60;
        if (start < end) {
            return utcMinutes >= start && utcMinutes < end;
        }
        return utcMinutes >= start || utcMinutes < end;
    }

    //! 24 hour ticks around the bezel; every 6th tick is emphasized.
    private function drawTicks(dc as Dc, cx as Float, cy as Float, w as Number) as Void {
        var rOuter = w / 2.0 - 2.0;
        for (var i = 0; i < 24; i++) {
            var major = (i % 6 == 0);
            var len = major ? 9.0 : 4.0;
            var angle = Math.toRadians(hourToAngle(i.toFloat()));
            var cosA = Math.cos(angle);
            var sinA = Math.sin(angle);
            dc.setColor(major ? Graphics.COLOR_WHITE : Graphics.COLOR_DK_GRAY,
                        Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(major ? 3 : 1);
            dc.drawLine(cx + (rOuter - len) * cosA, cy - (rOuter - len) * sinA,
                        cx + rOuter * cosA, cy - rOuter * sinA);
        }
    }

    //! One concentric arc per session, outermost first (chronological order).
    private function drawSessionArcs(dc as Dc, cx as Float, cy as Float,
                                     k as Float, utcMinutes as Number) as Void {
        for (var i = 0; i < 4; i++) {
            var r = (120.0 - 9.0 * i) * k;
            dc.setColor(_colors[i], Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(isOpen(i, utcMinutes) ? (7.0 * k).toNumber() : (4.0 * k).toNumber());
            dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE,
                       hourToAngle(_startHour[i].toFloat()),
                       hourToAngle(_endHour[i].toFloat()));
        }
    }

    //! White radial line at the current UTC time. The sessions whose arcs it
    //! crosses are the ones open right now.
    private function drawTimeMarker(dc as Dc, cx as Float, cy as Float,
                                    k as Float, w as Number, utcMinutes as Number) as Void {
        var angle = Math.toRadians(90.0 - utcMinutes * 360.0 / 1440.0);
        var cosA = Math.cos(angle);
        var sinA = Math.sin(angle);
        var rIn = 88.0 * k;
        var rOut = w / 2.0 - 4.0;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawLine(cx + rIn * cosA, cy - rIn * sinA,
                    cx + rOut * cosA, cy - rOut * sinA);
    }

    private function drawCenterInfo(dc as Dc, cx as Float, cy as Float, k as Float,
                                    clock as System.ClockTime, utcMinutes as Number) as Void {
        var settings = System.getDeviceSettings();
        var stats = System.getSystemStats();

        // Battery
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 80.0 * k, Graphics.FONT_XTINY,
                    stats.battery.format("%d") + "%",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Date, e.g. "Fri 25 Jul"
        var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 56.0 * k, Graphics.FONT_TINY,
                    today.day_of_week + " " + today.day.format("%d") + " " + today.month,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Local time, large
        var hour = clock.hour;
        if (!settings.is24Hour) {
            hour = hour % 12;
            if (hour == 0) {
                hour = 12;
            }
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 14.0 * k, Graphics.FONT_NUMBER_MEDIUM,
                    hour.format("%d") + ":" + clock.min.format("%02d"),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // UTC time
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 26.0 * k, Graphics.FONT_TINY,
                    "UTC " + (utcMinutes / 60).format("%02d") + ":" + (utcMinutes % 60).format("%02d"),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Countdown to the next session open/close
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 46.0 * k, Graphics.FONT_XTINY,
                    nextEventText(utcMinutes),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    //! e.g. "LDN closes 2h14" or "TYO opens 0h23"
    private function nextEventText(utcMinutes as Number) as String {
        var bestDelta = 100000;
        var bestText = "";
        for (var i = 0; i < 4; i++) {
            var boundaries = [_startHour[i] * 60, _endHour[i] * 60];
            var verbs = [" opens ", " closes "];
            for (var j = 0; j < 2; j++) {
                var delta = ((boundaries[j] - utcMinutes) % 1440 + 1440) % 1440;
                if (delta == 0) {
                    delta = 1440;
                }
                if (delta < bestDelta) {
                    bestDelta = delta;
                    bestText = _abbrs[i] + verbs[j]
                        + (delta / 60).format("%d") + "h"
                        + (delta % 60).format("%02d");
                }
            }
        }
        return bestText;
    }

    //! Session abbreviations along the bottom: colored while the session is
    //! open, dark gray while closed.
    private function drawLegend(dc as Dc, cx as Float, cy as Float,
                                k as Float, utcMinutes as Number) as Void {
        var spacing = 36.0 * k;
        for (var i = 0; i < 4; i++) {
            var x = cx + (i - 1.5) * spacing;
            dc.setColor(isOpen(i, utcMinutes) ? _colors[i] : Graphics.COLOR_DK_GRAY,
                        Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, cy + 64.0 * k, Graphics.FONT_XTINY, _abbrs[i],
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    function onShow() as Void {
    }

    function onHide() as Void {
    }

    function onExitSleep() as Void {
    }

    function onEnterSleep() as Void {
    }
}
