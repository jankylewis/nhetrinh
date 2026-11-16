# App icon

Hirono (Pop Mart), pixel style, transparent. `_AppIcon.png` (1024 px) is the master.
`bundle/` holds what ships in the app, built from it:
`AppIcon.icns` (Finder, Launchpad) and `_DockIcon.png` (256 px, set as the Dock icon at launch).
The Dock icon stays small: 1024 px cost 33 MB in the app process, 256 px nothing (NT-PRF-001).

```sh
swiftc -O tools/lift.swift -o /tmp/lift && /tmp/lift src/_Hirono_photo.png src/Hirono_cutout.png
swiftc -O tools/_pixelate.swift -o /tmp/pixelate && /tmp/pixelate src/Hirono_cutout.png _AppIcon.png 80
tools/make_icns.sh   # _AppIcon.png -> bundle/AppIcon.icns
swiftc -O tools/shrink.swift -o /tmp/shrink && /tmp/shrink _AppIcon.png bundle/_DockIcon.png 256
```
