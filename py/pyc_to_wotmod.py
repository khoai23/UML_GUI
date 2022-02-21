import zipfile36 as zipfile
import io, sys, os

def load_pyc_to_wotmod(filenames, wotmod_name, pyc_mod_folder="res/scripts/client/gui/mods"):
    """Add all pyc files to designated folder (res/scripts/client/gui/mods)"""
    with zipfile.ZipFile(wotmod_name, 'w', compression=zipfile.ZIP_STORED) as zf:
        for filename in filenames:
            basename = os.path.basename(filename)
            zf.write(filename, arcname=os.path.join(pyc_mod_folder, basename))
            #with io.open(filename, "rb") as infile, zf.open(os.path.join(pyc_mod_folder, filename), "wb") as outfile:
            #    outfile.write(infile.read())

if __name__ == "__main__":
    mod_name = "zipped_mod.wotmod"
    load_pyc_to_wotmod([f for f in sys.argv[1:] if f[-4:] == ".pyc"], mod_name)