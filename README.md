# Trade Sessions — Forex Session Watch Faces for Garmin fēnix 7

Two Garmin Connect IQ watch faces for the **fēnix 7 / 7 Pro family** that show
the major forex trading sessions, inspired by
[TradingView's Trade Time clock](https://www.tradingview.com/tradetime/).
Each face is its own small Connect IQ project — build and install both, then
pick one on the watch under **Settings → Watch Face**.

| `sessions-dial/` — 24h session dial | `sessions-lcd/` — digital / data-rich |
|---|---|
| ![Dial preview](docs/preview.png) | ![LCD preview](docs/preview_lcd.png) |

Both faces use the same sessions and colors:

| Session  | Color | UTC hours     |
|----------|-------|---------------|
| Sydney   | Amber | 22:00 – 07:00 |
| Tokyo    | Red   | 00:00 – 09:00 |
| London   | Blue  | 08:00 – 17:00 |
| New York | Green | 13:00 – 22:00 |

## Face 1: Trade Sessions (dial)

- The bezel is a **24-hour UTC dial**: 00:00 UTC at the top, time runs
  clockwise, ticks every hour, emphasized at 00/06/12/18 UTC.
- One colored arc per session; the **white radial marker** is current UTC
  time — every arc it crosses is a session open right now, and overlaps
  (e.g. London/New York 13:00–17:00 UTC) show as two arcs under the marker.
- Center: battery, date, local time, UTC time, countdown to the next session
  event, and a color legend that lights up for open sessions.

## Face 2: Trade Sessions LCD (digital)

A dense digital layout in the spirit of classic LCD faces:

- **Day-of-week strip** (`M T W T F S S`) with today marked, weekend in red.
- **Battery / heart rate / steps** row.
- Big **local time** (respects 12/24h setting), date and **UTC time**.
- A **linear 24-hour UTC bar** (midnight UTC left edge, one thin colored line
  per session) with a white now-marker — the linear version of the dial.
- A **session table**, one row per session:

  ```
  ▶ LDN   08-17   cls 2h23     <- open: bright, triangle, time to close
    SYD   22-07   opn 7h23     <- closed: dimmed, time to open
  ```

  So at a glance: which sessions are active, their UTC open–close hours, and
  exactly how long until each one opens or closes.

## Building

1. Install the [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/)
   via the SDK Manager and generate a developer key.
2. **VS Code (recommended):** install the *Monkey C* extension and open the
   face's folder (`sessions-dial/` or `sessions-lcd/`) as the workspace
   folder, then `Monkey C: Build Current Project` (or `Run` for the
   simulator) and pick your device, e.g. `fenix7pro`.
3. **CLI**, from the repo root:

   ```sh
   monkeyc -o bin/TradeSessions.prg    -f sessions-dial/monkey.jungle -y /path/to/developer_key.der -d fenix7pro
   monkeyc -o bin/TradeSessionsLcd.prg -f sessions-lcd/monkey.jungle  -y /path/to/developer_key.der -d fenix7pro
   ```

## Installing on the watch (sideload)

Connect the watch over USB and copy the built `.prg` file(s) into the
`GARMIN/Apps` folder on the device, then eject. Select the face on the watch
under **Settings → Watch Face**.

Supported devices: fēnix 7, 7S, 7X, 7 Pro, 7S Pro, 7X Pro (incl. no-wifi variants).

## Notes & caveats

- **DST:** session hours are the commonly used fixed-UTC approximations. Real
  session opens shift by an hour with US/UK/AU daylight saving; a future
  version could adjust for DST or expose the hours as app settings.
- Session hours and colors are easy to tweak: see `_startHour`, `_endHour`
  and `_colors` at the top of each face's `source/*View.mc`.
- Heart rate on the LCD face shows `--` until the optical sensor reports a
  reading; steps come from the daily activity monitor.
- Faces redraw once per minute (standard low-power watch face behavior),
  which is battery friendly on the MIP display.
