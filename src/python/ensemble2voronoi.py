import os
import json
import pandas as pd
import geopandas as gpd
from matplotlib import pyplot as plt
from shapely import MultiPoint, Polygon, Point, normalize, difference, voronoi_polygons


def divide_line_segment(x1, x2, n):
    total_length = x2 - x1
    segment_length = total_length / n
    centers = []
    for i in range(n):
        center_x = x1 + (segment_length * i) + (segment_length / 2)
        centers.append(center_x)
    return centers

def reverse_blocks(dataframe, n):
    blocks = [dataframe[i:i+n] for i in range(0, len(dataframe), n)]
    reversed_blocks = blocks[::-1]
    reversed_df = pd.concat(reversed_blocks)
    return reversed_df

def create_area_exterior(lon_min, lon_max, lat_min, lat_max, Ny, voronoi):
    area = Polygon([(lon_min, lat_min), (lon_max, lat_min), (lon_max, lat_max), (lon_min, lat_max)])
    area = normalize(difference(area, voronoi))
    area = gpd.GeoDataFrame(list(area.geoms), columns=['geometry'], crs=6668)
    area = reverse_blocks(area, Ny)
    area.reset_index(drop=True, inplace=True)
    area['id'] = area.index
    return area

def process_dataframe(df, maxid):
    # 全IDのリストを作成
    all_ids = pd.DataFrame({'id': range(maxid)})
    # データフレームをIDでマージし、欠損値は0で埋める
    merged_df = pd.merge(all_ids, df, on='id', how='left').fillna(0)
    # IDでグループ化し、areaを合計する
    result_df = merged_df.groupby('id').agg({'area': 'sum'}).reset_index()
    return result_df

def main(config):
    # read config.json
    basin_path = config['basin_path']
    output_path = config['output_path']
    Nx = config['Nx']
    Ny = config['Ny']
    lon_min = config['lon_min']
    lon_max = config['lon_max']
    lat_min = config['lat_min']
    lat_max = config['lat_max']
    epsg = config['epsg']

    # make output directory if not exist
    if not os.path.exists(output_path):
        os.makedirs(output_path)
    
    basin = gpd.read_file(basin_path)
    # make a grid of multipoints
    lon_list = divide_line_segment(lon_min, lon_max, Nx)
    lat_list = divide_line_segment(lat_min, lat_max, Ny)

    points = []
    for lon in lon_list:
        for lat in lat_list:
            points.append(Point(lon, lat))
    points = MultiPoint(points)
    voronoi = normalize(voronoi_polygons(points, only_edges=True))
    voronoi = voronoi.buffer(1e-4)
    diff = difference(basin.geometry[0], voronoi)
    diff = list(diff.geoms)
    diff = gpd.GeoDataFrame(diff, columns=['geometry'], crs=6668)
    diff['area'] = diff.to_crs(epsg).area/1e6 # km2
    diff.to_file(os.path.join(output_path,'area_per_enscell.geojson'), driver='GeoJSON') # added by S.Ono 2024/04/09 edited by S.Ono 2024/05/14

    area_exterior = create_area_exterior(lon_min, lon_max, lat_min, lat_max, Ny, voronoi)
    area_ref = diff.sjoin(area_exterior, how='left').drop(columns=['index_right', 'geometry'])
    area_ref = process_dataframe(area_ref, Nx*Ny)
    area_ref.to_csv(os.path.join(output_path, 'area_per_enscell.csv'), index=False) # edited by S.Ono 2024/05/14

if __name__ == "__main__":
    path_config = input("Input the path of the config.json file: ")
    with open(path_config, 'r') as file:
        config = json.load(file)
    main(config)