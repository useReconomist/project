library(tidyverse)
library(valh)
library(leaflet)
library(sf)

# this generate 3 functions
source("02_r_every_session.R")
source("02_a_new_functions.R")
# epsg get the EPSG for simplify the polygon en meters
# vh_decode6 this create the traslation into valh andR  
# vh_route_avoid: if you have some poly o multipolygon the tour avoid that polygons

points = sf::st_read("data_example/points_example.gpkg")


mapa = leaflet() |> 
  addProviderTiles(providers$OpenStreetMap) |> 
  addCircleMarkers(data=points,
    opacity = 1)

mapa

valh::vl_status()

route = vl_route(
  loc = points,
  server = "http://localhost:8002",
  costing = "pedestrian"
)

mapa |> 
  addPolylines(data=route)

zone_to_avoid = sf::st_read("data_example/zone_to_avoid.gpkg")

mapa |> 
  addPolylines(data=route) |> 
  addPolygons(data=zone_to_avoid,color="red",opacity = 1)



or = points[1,]
de = points[2,]

new_route = vh_route_avoid(
  p1 = or,
  p2 = de,
  zona = zone_to_avoid,
  costing = "pedestrian",
  server = "http://localhost:8002",
  tolerancia = 1500
)

mapa = mapa |> 
  addPolylines(data=route) |> 
  addPolygons(data=zone_to_avoid,color="red",opacity = 1) |> 
  addPolylines(data=new_route,color = "black",opacity = .5)

mapa
# as well isochrones
iso_1 = valh::vl_isochrone(loc = or,costing = "auto",times = c(15))

iso_2 = valh::vl_isochrone(loc = de,costing = "bicycle",times = c(15))


mapa |> 
  addPolygons(data=iso_1,weight = 1,color = "red") |> 
  addPolygons(data=iso_2,weight = 1,color = "red")
