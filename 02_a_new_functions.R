# extra functions
library(sf)
library(httr2)

# this scripts create these 2 functions
# vh_decode6
# vh_route_avoid

vh_decode6 <- function(s) {
  b <- utf8ToInt(s) - 63L
  n <- length(b); i <- 1L
  lat <- 0; lon <- 0
  out <- matrix(NA_real_, nrow = n, ncol = 2); k <- 0L
  while (i <= n) {
    v <- integer(2)
    for (j in 1:2) {
      res <- 0L; shift <- 0L
      repeat {
        x <- b[i]; i <- i + 1L
        res <- bitwOr(res, bitwShiftL(bitwAnd(x, 31L), shift))
        shift <- shift + 5L
        if (x < 32L) break
      }
      v[j] <- if (bitwAnd(res, 1L)) -bitwShiftR(res, 1L) - 1L else bitwShiftR(res, 1L)
    }
    lat <- lat + v[1]; lon <- lon + v[2]
    k <- k + 1L; out[k, ] <- c(lon, lat) / 1e6
  }
  out[seq_len(k), , drop = FALSE]
}



vh_route_avoid <- function(
    p1, p2, zona,
    costing = "pedestrian",
    server = "http://localhost:8002",
    tolerancia = 30
) {
 
  pts <- st_coordinates(
    st_transform(
      c(st_geometry(p1), st_geometry(p2)),
      4326
    )
  )
 
utm_epsg <- function(x) {
  ll <- st_coordinates(
    st_centroid(st_union(st_transform(st_geometry(x), 4326)))
  )
  zona <- floor((ll[1, "X"] + 180) / 6) + 1
  as.integer(if (ll[1, "Y"] >= 0) 32600 + zona else 32700 + zona)
}
  
epsg <- utm_epsg(zona) 
  
  # Simplificar zona en metros
  zona <- zona |>
    st_transform(epsg) |>           # UTM 14N, adecuado para CDMX
    st_simplify(
      dTolerance = tolerancia,
      preserveTopology = TRUE
    ) |>
    st_transform(4326)
 
  # Anillos exteriores
  zona <- st_cast(
    st_geometry(zona),
    "POLYGON"
  )
 
  rings <- lapply(zona, function(g) {
   
    m <- g[[1]][, 1:2]
   
    lapply(
      seq_len(nrow(m)),
      function(i) m[i, ]
    )
  })
 
  body <- list(
    locations = list(
      list(
        lon = pts[1, 1],
        lat = pts[1, 2]
      ),
      list(
        lon = pts[2, 1],
        lat = pts[2, 2]
      )
    ),
    costing = costing,
    exclude_polygons = rings,
    units = "kilometers"
  )
 
  res <- request(paste0(server, "/route")) |>
    req_body_json(body) |>
    req_error(is_error = \(r) FALSE) |>
    req_perform() |>
    resp_body_json()
 
  if (!is.null(res$error)) {
    stop("Valhalla: ", res$error)
  }
 
  coords <- do.call(
    rbind,
    lapply(
      res$trip$legs,
      \(l) vh_decode6(l$shape)
    )
  )
 
  st_sf(
    distance_km  = res$trip$summary$length,
    duration_min = res$trip$summary$time / 60,
    geometry = st_sfc(
      st_linestring(coords),
      crs = 4326
    )
  )
}

