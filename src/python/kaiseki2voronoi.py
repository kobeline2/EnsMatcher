import os
import json
import xarray as xr
import geopandas as gpd
from shapely import MultiPoint, Polygon, Point, normalize, difference, voronoi_polygons

# use config_d4pdf2voronoi.json
def main(config):
    # read config.json
    basin_path = config['basin_path']
    output_path = config['output_path']
    nc_path = config['nc_path']
    lon_min = config['lon_min']
    lon_max = config['lon_max']
    lat_min = config['lat_min']
    lat_max = config['lat_max']
    epsg = config['epsg']

    # read data
    xrin = xr.open_dataset(nc_path) 
    basin = gpd.read_file(basin_path)

    # make output directory if not exist
    if not os.path.exists(output_path):
        os.makedirs(output_path)

    # create a list of points
    flon = xrin.variables["flon"].values[:] 
    flat = xrin.variables['flat'].values[:]
    points = []
    for i in range(0, len(flon[:, 0])):
        for j in range(0, len(flon[0, :])):
            points.append(Point(flon[i, j], flat[i, j]))
    points = gpd.GeoDataFrame(geometry=points, crs="EPSG:6668")
    points['id'] = points.index + 1

    # create voronoi polygons
    area = Polygon([(lon_min, lat_min), (lon_max, lat_min), (lon_max, lat_max), (lon_min, lat_max)])
    isin_area = points.intersection(area)
    points_in_area = points[isin_area.is_empty == False]
    points_in_area.reset_index(drop=True, inplace=True)
    voronoi = normalize(voronoi_polygons(MultiPoint(points_in_area.geometry), only_edges=True))
    voronoi = voronoi.buffer(1e-4)

    # separate basin based on voronoi polygons
    diff = difference(basin.geometry[0], voronoi)
    diff = list(diff.geoms)
    diff = gpd.GeoDataFrame(diff, columns=['geometry'], crs=6668)
    diff['area'] = diff.to_crs(epsg).area/1e6 # km2

    # add id to each voronoi polygon
    area_ref = normalize(difference(area, voronoi))
    area_ref = gpd.GeoDataFrame(list(area_ref.geoms), columns=['geometry'], crs=6668)
    area_ref = area_ref.sjoin(points_in_area, how='left').drop(columns=['index_right'])
    area_ref = diff.sjoin(area_ref, how='left').drop(columns=['index_right'])
    area_ref.to_file(os.path.join(output_path, 'area_per_kaisekicell.geojson'), index=False, driver='GeoJSON')
    area_ref.drop(columns=['geometry'], inplace=True)
    area_ref = area_ref.groupby('id').agg({'area': 'sum'}).reset_index()
    area_ref.to_csv(os.path.join(output_path, 'area_per_kaisekicell.csv'), index=False)

if __name__ == "__main__":
    path_config = input("Input the path of the config_d4pdf2voronoi.json file: ")
    with open(path_config, 'r') as file:
        config = json.load(file)
    main(config)