# Mercury One.1 (Ender 5 Plus) — Duet 2 Ethernet configuration

RepRapFirmware 3.6 configuration for a [Zero G Mercury One.1](https://github.com/ZeroGRepo)
CoreXY conversion of a Creality Ender 5 Plus, running on a Duet 2 Ethernet.

- `sys/` — the live `/sys` folder (config.g, homing macros, probe macros, saved heater models)
- `FIRST-RUN.md` — commissioning checklist and status log
- `scripts/duet.sh` — pull/push/gcode helper over the Duet HTTP API
- `reference/ender5plus-cartesian-2020/` — the earlier Cartesian Ender 5 Plus config
  (see the public [Ender 5 Plus Duet repo](https://github.com/yincrash/Ender-5-Plus---Duet-2-Wifi-or-Ethernet-Configuration))

Private for now. A public README with a from-scratch first-run guide (motor direction
test, endstop check, probe test) is planned once the machine is printing.
