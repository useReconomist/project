# vallalla 

library(processx)

site_dir <- ".venv/Lib/site-packages"
bin_dir  <- file.path(site_dir, "valhalla", "bin")
work     <- "valhalla"
cfg_path <- file.path(work, "valhalla.json")
tile_dir <- file.path(work, "tiles")
pbf <- "00_country_pbf/uruguay-261028.osm.pbf"


dlls <- list.files(site_dir, pattern = "\\.dll$", recursive = TRUE, full.names = TRUE)
dll_dirs <- unique(dirname(dlls[grepl("valhalla", dlls, ignore.case = TRUE)]))
Sys.setenv(PATH = paste(c(normalizePath(c(bin_dir, dll_dirs), winslash = "\\"),
                          Sys.getenv("PATH")), collapse = ";"))

# 1. Matar cualquier valhalla_service que siga vivo
if (exists("srv") && srv$is_alive()) srv$kill()
system("taskkill /F /IM valhalla_service.exe", ignore.stdout = TRUE, ignore.stderr = TRUE)

# 2. Borrar tiles viejos (obligatorio antes de cada build)
unlink(tile_dir, recursive = TRUE)
dir.create(tile_dir)

# 3. Build con log a archivo (México tarda, no lo interrumpas)
log_file <- file.path(work, "build.log")
st <- system2(file.path(bin_dir, "valhalla_build_tiles.exe"),
              c("-c", shQuote(cfg_path), shQuote(pbf)),
              stdout = log_file, stderr = log_file)

st # 0 = terminó bien
tail(readLines(log_file), 30)
