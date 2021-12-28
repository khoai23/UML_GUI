UML GUI using WoT's inbuilt flash. The concerning files to be built are `py/mod_UML_interface.pyc` and `as3/UML_MainGUI.swf`. You will need **FLEX's mxmlc** and **Python 2.7** to build each.

Once installed the prerequisite:
```
# Build swf from the main ActionScript file (UML_MainGUI.as)
{mxmlc}  -compiler.source-path=as3 -compiler.external-library-path+=as3\lib\common-1.0-SNAPSHOT.swc,as3\lib\gui_base-1.0-SNAPSHOT.swc -static-link-runtime-shared-libraries=true -o as3\UML_MainGUI.swf as3\uml\UML_MainGUI.as
# Compile the corresponding mod_UML_interface.pyc
{python2.7} -m compileall py\mod_UML_interface.py
# [Optional] Regenerate and rebuild tank_data.json from wiki.wargaming.com
{python3} py\crawler\tank_searcher.py
# Copy the two files to res_mods\{version}\gui\flash and res_mods\{version}\scripts\client\gui\mods respectively (or alternatively zip them into a wotmod)
# You must also copy tank_data.json (from either py/crawler or base directory) to mods\configs
```

JPEXS can be used to inspect the concerning `.swc` in `as3\lib`. Those are lifted straight from WoT's inbuilt data (`res\packages\gui-part1|2.pkg`, `gui\flash`)

TODO:
- [X] Localized TankID and name instead of relying on crawler data.
- [ ] StyleSet selection
- [ ] Completely new header w/ swapping component (hull/turret/gun)
- [X] Paint/Camo in selectable format (instead of specified IDs)
- [ ] Overhaul listing if manage to fix ScrollingListPx
- [ ] Updating nation / tier / type to use localized string