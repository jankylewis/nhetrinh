# App icon

Hirono (Pop Mart), pixel style, transparent. `_AppIcon.png` is the master; `AppIcon.icns` is built from it.

```sh
swiftc -O tools/lift.swift -o /tmp/lift && /tmp/lift src/_Hirono_photo.png src/Hirono_cutout.png
swiftc -O tools/_pixelate.swift -o /tmp/pixelate && /tmp/pixelate src/Hirono_cutout.png _AppIcon.png 80
tools/make_icns.sh   # _AppIcon.png -> AppIcon.icns
```
