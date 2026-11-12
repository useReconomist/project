

library(processx)

site_dir <- ".venv/Lib/site-packages"
bin_dir  <- file.path(site_dir, "valhalla", "bin")
cfg_path <- "valhalla/valhalla.json"

# DLLs al PATH (se pierde al cerrar R, por eso va cada vez)
dlls <- list.files(site_dir, pattern = "\\.dll$", recursive = TRUE, full.names = TRUE)
dll_dirs <- unique(dirname(dlls[grepl("valhalla", dlls, ignore.case = TRUE)]))
Sys.setenv(PATH = paste(c(normalizePath(c(bin_dir, dll_dirs), winslash = "\\"),
                          Sys.getenv("PATH")), collapse = ";"))

# Cerrar cualquier servidor anterior para que no choque con el puerto 8002
if (exists("srv") && srv$is_alive()) srv$kill()
system("taskkill /F /IM valhalla_service.exe", ignore.stdout = TRUE, ignore.stderr = TRUE)

# Levantar servidor con los tiles que ya existen
srv <- process$new(file.path(bin_dir, "valhalla_service.exe"),
                   c(cfg_path, "1"),
#                   stdout = "server.log",
                   stderr = "2>&1")

Sys.sleep(3)

srv$is_alive()   # TRUE = listo en localhost:8002
