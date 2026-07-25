import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

//! Data-rich digital ("LCD") forex sessions watch face.
//!
//! Top half mirrors a classic digital face: day-of-week strip with today
//! marked, battery / heart rate / steps row, big time, date + UTC line.
//! Bottom half is the trading panel: a linear 24-hour UTC session bar with a
//! now-marker, and one row per session showing its UTC open-close hours plus
//! a countdown — "cls 2h23" (time until it closes, session open) or
//! "opn 9h12" (time until it opens, session closed). Open sessions get a
//! triangle marker and bright text; closed rows are dimmed.
//!
//! The big time uses a custom 7-segment bitmap font. Session hours are
//! configurable; see SessionConfig in SettingsMenu.mc.
class TradeSessionsLcdView extends WatchUi.WatchFace {

    // Session start/end hours in UTC (defaults; overridden from settings).
    private var _abbrs as Array<String> = ["SYD", "TYO", "LDN", "NYC"];
    private var _startHour as Array<Number> = [22, 0, 8, 13];
    private var _endHour as Array<Number> = [7, 9, 17, 22];
    private var _colors as Array<Number> = [
        0xFFAA00,  // Sydney  - amber
        0xFF0000,  // Tokyo   - red
        0x00AAFF,  // London  - blue
        0x00FF55   // New York- green
    ];
    private var _dayLetters as Array<String> = ["M", "T", "W", "T", "F", "S", "S"];

    // Custom 7-segment bitmap font for the big time display.
    private var _segFont as FontResource?;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Dc) as Void {
        _segFont = WatchUi.loadResource(Rez.Fonts.SegFont) as FontResource;
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var cx = w / 2.0;
        // Layout tuned for 260x260; scaled for the 280x280 fenix 7X.
        var k = w / 260.0;

        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        for (var i = 0; i < 4; i++) {
            _startHour[i] = SessionConfig.openHour(i);
            _endHour[i] = SessionConfig.closeHour(i);
        }

        var clock = System.getClockTime();
        var utcMinutes = localToUtcMinutes(clock);
        var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);

        drawDayStrip(dc, cx, k, today);
        drawStatsRow(dc, cx, k);
        drawTime(dc, cx, k, clock);
        drawDateUtcLine(dc, cx, k, today, utcMinutes);
        drawSessionBar(dc, k, w, utcMinutes);
        drawSessionTable(dc, cx, k, utcMinutes);
    }

    private function localToUtcMinutes(clock as System.ClockTime) as Number {
        var localSec = clock.hour * 3600 + clock.min * 60 + clock.sec;
        var utcSec = localSec - clock.timeZoneOffset;
        utcSec = ((utcSec % 86400) + 86400) % 86400;
        return utcSec / 60;
    }

    private function isOpen(idx as Number, utcMinutes as Number) as Boolean {
        var start = _startHour[idx] * 60;
        var end = _endHour[idx] * 60;
        if (start < end) {
            return utcMinutes >= start && utcMinutes < end;
        }
        return utcMinutes >= start || utcMinutes < end;
    }

    //! "M T W T F S S" with weekend in red and a marker under today.
    private function drawDayStrip(dc as Dc, cx as Float, k as Float,
                                  today as Gregorian.Info) as Void {
        // FORMAT_MEDIUM gives day_of_week as a string; get the number instead.
        var short = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dow = short.day_of_week as Number;  // 1 = Sunday ... 7 = Saturday
        var todayIdx = (dow == 1) ? 6 : dow - 2;  // Monday-first index

        for (var i = 0; i < 7; i++) {
            var x = cx + (i - 3) * 16.0 * k;
            var color = (i >= 5) ? Graphics.COLOR_RED : Graphics.COLOR_LT_GRAY;
            if (i == todayIdx) {
                color = Graphics.COLOR_WHITE;
            }
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, 16.0 * k, Graphics.FONT_XTINY, _dayLetters[i],
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            if (i == todayIdx) {
                dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
                dc.fillPolygon([[x, 25.0 * k], [x - 4.0 * k, 30.0 * k],
                                [x + 4.0 * k, 30.0 * k]] as Array<Array<Numeric>>);
            }
        }
    }

    //! Battery, heart rate, steps.
    private function drawStatsRow(dc as Dc, cx as Float, k as Float) as Void {
        var y = 40.0 * k;
        var stats = System.getSystemStats();

        var hr = "--";
        var info = Activity.getActivityInfo();
        if (info != null && info.currentHeartRate != null) {
            hr = (info.currentHeartRate as Number).format("%d");
        }

        var steps = "--";
        var actInfo = ActivityMonitor.getInfo();
        if (actInfo.steps != null) {
            steps = (actInfo.steps as Number).format("%d");
        }

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 68.0 * k, y, Graphics.FONT_XTINY,
                    stats.battery.format("%d") + "%",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_XTINY, "HR " + hr,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx + 68.0 * k, y, Graphics.FONT_XTINY, steps,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawTime(dc as Dc, cx as Float, k as Float,
                              clock as System.ClockTime) as Void {
        var settings = System.getDeviceSettings();
        var hour = clock.hour;
        var suffix = "";
        if (!settings.is24Hour) {
            suffix = (hour < 12) ? "AM" : "PM";
            hour = hour % 12;
            if (hour == 0) {
                hour = 12;
            }
        }
        var timeStr = hour.format("%d") + ":" + clock.min.format("%02d");
        var y = 76.0 * k;
        var font = (_segFont != null) ? _segFont as FontType : Graphics.FONT_NUMBER_MEDIUM;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, font, timeStr,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        if (!suffix.equals("")) {
            var half = dc.getTextWidthInPixels(timeStr, font) / 2;
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx + half + 14.0 * k, y, Graphics.FONT_XTINY, suffix,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    private function drawDateUtcLine(dc as Dc, cx as Float, k as Float,
                                     today as Gregorian.Info, utcMinutes as Number) as Void {
        var dateStr = (today.day_of_week as String).toUpper() + " "
            + (today.day as Number).format("%d") + " "
            + (today.month as String).toUpper();
        var utcStr = "UTC " + (utcMinutes / 60).format("%02d") + ":"
            + (utcMinutes % 60).format("%02d");
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 113.0 * k, Graphics.FONT_TINY, dateStr + "  " + utcStr,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    //! Linear 24-hour UTC bar (00:00 left, 24:00 right), one thin line per
    //! session, with a white vertical marker at the current UTC time.
    private function drawSessionBar(dc as Dc, k as Float, w as Number,
                                    utcMinutes as Number) as Void {
        var xLeft = 26.0 * k;
        var xRight = w - 26.0 * k;
        var span = xRight - xLeft;

        for (var i = 0; i < 4; i++) {
            var y = (130.0 + i * 4.0) * k;
            dc.setColor(_colors[i], Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth((3.0 * k).toNumber());
            var s = _startHour[i];
            var e = _endHour[i];
            if (s < e) {
                dc.drawLine(xLeft + s / 24.0 * span, y, xLeft + e / 24.0 * span, y);
            } else {
                dc.drawLine(xLeft + s / 24.0 * span, y, xRight, y);
                dc.drawLine(xLeft, y, xLeft + e / 24.0 * span, y);
            }
        }

        var xNow = xLeft + utcMinutes / 1440.0 * span;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(xNow, 126.0 * k, xNow, 146.0 * k);
    }

    //! One row per session: [>] ABBR  hh-hh  cls/opn countdown.
    private function drawSessionTable(dc as Dc, cx as Float, k as Float,
                                      utcMinutes as Number) as Void {
        for (var i = 0; i < 4; i++) {
            var y = (160.0 + i * 19.0) * k;
            var open = isOpen(i, utcMinutes);

            if (open) {
                dc.setColor(_colors[i], Graphics.COLOR_TRANSPARENT);
                dc.fillPolygon([[cx - 92.0 * k, y - 4.0 * k],
                                [cx - 92.0 * k, y + 4.0 * k],
                                [cx - 85.0 * k, y]] as Array<Array<Numeric>>);
            }

            dc.setColor(_colors[i], Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx - 80.0 * k, y, Graphics.FONT_XTINY, _abbrs[i],
                        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

            dc.setColor(open ? Graphics.COLOR_WHITE : Graphics.COLOR_DK_GRAY,
                        Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx - 12.0 * k, y, Graphics.FONT_XTINY,
                        _startHour[i].format("%02d") + "-" + _endHour[i].format("%02d"),
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            dc.drawText(cx + 72.0 * k, y, Graphics.FONT_XTINY,
                        countdownText(i, open, utcMinutes),
                        Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    //! "cls 2h23" while open (time to close), "opn 9h12" while closed.
    private function countdownText(idx as Number, open as Boolean,
                                   utcMinutes as Number) as String {
        var target = (open ? _endHour[idx] : _startHour[idx]) * 60;
        var delta = ((target - utcMinutes) % 1440 + 1440) % 1440;
        if (delta == 0) {
            delta = 1440;
        }
        return (open ? "cls " : "opn ")
            + (delta / 60).format("%d") + "h" + (delta % 60).format("%02d");
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
