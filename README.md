# Trade Sessions — Forex Session Watch Face for Garmin fēnix 7

A Garmin Connect IQ watch face for the **fēnix 7 / 7 Pro family** that shows the
major forex trading sessions on a 24-hour dial, inspired by
[TradingView's Trade Time clock](https://www.tradingview.com/tradetime/).

![Watch face preview](docs/preview.png)

## How to read it

- The bezel is a **24-hour UTC dial**: 00:00 UTC at the top, time runs
  clockwise, with a tick every hour and emphasized ticks at 00/06/12/18 UTC.
- Each colored arc is one trading session (outermost to innermost, in
  chronological order):

  | Session  | Color | UTC hours     |
  |----------|-------|---------------|
  | Sydney   | Amber | 22:00 – 07:00 |
  | Tokyo    | Red   | 00:00 – 09:00 |
  | London   | Blue  | 08:00 – 17:00 |
  | New York | Green | 13:00 – 22:00 |

- The **white radial marker** is the current UTC time. Any arc it crosses is a
  session that is **open right now** — overlaps (e.g. London/New York
  13:00–17:00 UTC) are immediately visible as two arcs under the marker.
- Center, top to bottom: battery, date, **local time**, UTC time, and a
  countdown to the next session open/close (e.g. `LDN closes 2h23`).
- The legend at the bottom (`SYD TYO LDN NYC`) lights up in the session color
  while that session is open and is gray while closed.

## Building

1. Install the [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/)
   via the SDK Manager, and generate a developer key
   (`Connect IQ: Generate a Developer Key` in VS Code, or
   `openssl genrsa -out developer_key.pem 4096` + convert per Garmin docs).
2. **VS Code (recommended):** install the *Monkey C* extension, open this
   folder, then run `Monkey C: Build Current Project` (or `Run` to launch the
   simulator) and pick your device, e.g. `fenix7pro`.
3. **CLI:**

   ```sh
   monkeyc -o bin/TradeSessions.prg -f monkey.jungle -y /path/to/developer_key.der -d fenix7pro
   ```

## Installing on the watch (sideload)

Connect the watch over USB and copy `bin/TradeSessions.prg` into the
`GARMIN/Apps` folder on the device, then eject. Select the watch face on the
watch under **Settings → Watch Face**.

Supported devices: fēnix 7, 7S, 7X, 7 Pro, 7S Pro, 7X Pro (incl. no-wifi variants).

## Notes & caveats

- **DST:** session hours are the commonly used fixed-UTC approximations. Real
  session opens shift by an hour with US/UK/AU daylight saving; a future
  version could adjust for DST or expose the hours as app settings.
- Session hours and colors are easy to tweak: see `_startHour`, `_endHour` and
  `_colors` at the top of `source/TradeSessionsView.mc`.
- The face only redraws once per minute (standard low-power watch face
  behavior), which is plenty for session tracking and battery friendly on the
  MIP display.
