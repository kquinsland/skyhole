Quick note about the `/opt/skyhole/pihole/*` directory.


The dirs/files there will be mounted directly into the `pihole` container at various points.

You can read about the syntax around that [here](https://docs.docker.com/compose/compose-file/#volumes)


You should stop `piHole` before making changes; you will need to reboot `piHole` to pick up the changes; watch the container logs to confirm you didn't mess anything up. `piHole` will dump the config error and hang. stop, fix, restart, repeat...

If in doubt, use any of the "harder to screw up" ways to configure `piHole` like the admin settings inthe web UI.

Having said that, the current [pihole Teleporter implementation](https://github.com/pi-hole/AdminLTE/blob/78d262d7b050db8aa96d0a8ec793f91f5fe93d6f/scripts/pi-hole/php/teleporter.php#L108) backs up `adlists.list` but does not restore it. Not sure if intentional or not, but my point is that teleporter does not restore everything it backs up so it may be worth your while to keep this dir in a git repo of your own.
