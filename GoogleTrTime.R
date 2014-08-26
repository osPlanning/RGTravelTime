# Script queries the Google Maps API to fetch drive times between
# a random sample of travel zones. Example uses Puget Sound Regional
# Council data.
#
# Example usage: Rscript GoogleTrTime.R
#
# Dependencies:
# install.packages(c("ggmap", "plyr", "rgdal"))
library(ggmap)
library(plyr)
library(rgdal)

# Relative paths will work if running from a shell using Rscript, or
# if sourced in RStudio, loading the project file. Otherwise, you may
# need to set the working directory to this folder. See setwd().
#
# Input file is a shape file with the locations of the zone centroids
shapefileloc <- "./resources" # folder, no trailing slash
layername <- "zone" # corresponds to zone.shp

# Output is a csv with a list of randomly selected origins and destinations 
# and their travel times
outputmat <- "./zonetimes.csv"

# Read the shapefile. Note:
#   DSN is the containing folder, with no trailing slash
#   layer is the shapefile, e.g. "zone.shp", minus the ".shp"
zonecentroids <- readOGR(dsn=shapefileloc, layer=layername)

# Reproject to WGS84 get standard coordinates
zonecentroids <- spTransform(zonecentroids, CRSobj=CRS("+init=epsg:4326"))

# Hey look, there's the region!
plot(zonecentroids)


# Convert coords to a google friendly string, and dataframe it!
coords <- data.frame(id = zonecentroids@data$Scen_Node,
                     coords = apply(zonecentroids@coords, 1,
                                    function(x) paste(x[2], x[1], sep=", ")))

# Create a dataframe that is a random sample of origin / destination zones
samp <- coords[sample(nrow(coords), 200), ]
samp_o <- samp[1:100,] # we're splitting one sample in two here
samp_d <- samp[101:200, ]

inputdf <- cbind(samp_o, samp_d)
names(inputdf) <- c("OID", "OCoords", "DID", "DCoords")
row.names(inputdf) <- NULL


# "driving", "walking", and "bicycling" are all valid modes
google_results <- rbind.fill(
  apply(subset(inputdf, select=c("OCoords", "DCoords")), 1,
        function(x) mapdist(x[1], x[2], mode="driving")))

# Bind the results into something pretty
results <- cbind(OID=inputdf$OID, DID=inputdf$DID, google_results)

write.csv(results, outputmat, row.names=FALSE)
