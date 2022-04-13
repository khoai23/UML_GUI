import zipfile36 as zipfile
import io, sys, os

def load_files_to_wotmod(filenames, wotmod_name, pyc_mod_folder="res/scripts/client/gui/mods", swf_mod_folder="res/gui/flash"):
    """Add all pyc/swf files to designated folder (res/scripts/client/gui/mods for py and res/gui/flash for swf)"""
    with zipfile.ZipFile(wotmod_name, 'w', compression=zipfile.ZIP_STORED) as zf:
        for filename in filenames:
            basename = os.path.basename(filename)
            mod_folder = pyc_mod_folder if(basename[-4:] == ".pyc") else swf_mod_folder
            zf.write(filename, arcname=os.path.join(mod_folder, basename))
            #with io.open(filename, "rb") as infile, zf.open(os.path.join(pyc_mod_folder, filename), "wb") as outfile:
            #    outfile.write(infile.read())

if __name__ == "__main__":
    mod_name = next( (mn for mn in sys.argv[1:] if ".wotmod" in mn), "zipped_mod.wotmod")
    load_files_to_wotmod([f for f in sys.argv[1:] if f[-4:] in (".pyc", ".swf")], mod_name)