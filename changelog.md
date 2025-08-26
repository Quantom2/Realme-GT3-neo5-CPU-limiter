1.4: UI/UX huge rework
- New test displaying system
  - Now script will check your screen width and allign all text with it
  - All text was fully reworked for new menu system
  - Now unsupported settings will be shown as UNAVALIBLE from start, than disabled after
- Huge improvements in menu: now all UNAVALIBLE options won't be shown
- Updated Screenoff service: now less drag and should be snappier
- Added new experimental settings:
  - Set governor to Powersave on sleep
  - Manually Enable/Disable cores via action
- Fully reworked experimental logging: now more flexible
  - New logging menu now allows you to flexibly choose what you want to log and what not.
  - New Result of action type of log for monitoring
- New feature with random tips during install and in module description
  - Added new Tip system that show tip on top when module is installing
  - Added module random description, on each boot it will be updated now!
- Fixed annoying bug when module install fails in the end
- Fixed module refusing to instal on Magisk
- Code optimisations

1.3: Experimental update!
- Added new Screenoff service
- Added new experimental settings:
  - Disable cores on sleep
  - Cut CPU frequency down on sleep
- Fully reworked logging
- Added Screenoff service own logging in /sdcard/Quantom_Screenoff.log
- Fixed bugs with settings restore
- Code optimisations

1.2: Compability update!
- Added a security check on install, to verify that phone is GT3/neo5
- If it isn't added a simple compability mode where you can't acces freq
- Added more checks and logging to be sure everything OK on install

1.1: Bugfix:
- Add a log on install;
- Fixed a bug when disabling cores;
- Script now executing after 90 seconds after boot;

1.0:
- Initial release