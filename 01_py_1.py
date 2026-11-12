# Configuración inicial

# First steep 
# We need to install the library from pip or download it from
# https://pypi.org/project/pyvalhalla/
pip install pyvalhalla

# step 2
# the library has a configuration (a json file) so we need it
# and create a folder
import json
from pathlib import Path
from valhalla import get_config

work     = Path("valhalla")
tile_dir = work / "tiles"
cfg_path = work / "valhalla.json"

# get_config exige que exista
tile_dir.mkdir(parents=True, exist_ok=True)   

# tile_extract="" omite la validación, así no hace falta el .tar vacío
c = get_config(tile_extract="", tile_dir=tile_dir)
c["mjolnir"].pop("tile_extract", None)

with open(cfg_path, "w") as f:
    json.dump(c, f, indent=2)

print("Listo:", cfg_path, cfg_path.stat().st_size, "bytes")