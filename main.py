import sys, os
import csv
import pandas as pd
import numpy as np
import requests
import datetime as dt

def get_file_name(fn_pref, fn_suf, start_r, start_c):
    return fn_pref + "_" + str(fn_suf) + '_r' + str(start_r) + '_c' + str(start_c) + '.txt'

elev_data_path = './data2'
#elev_data_path = './elev_data2'
target = "https://epqs.nationalmap.gov/v1/json"
csv_prefix = "elev_csv_"
reference_center = {'lat': '39.829602', 'long': '-77.244140'}
default_grid = (100, 100)

def main(
    args, center=reference_center, lat_interval=0.029_228,
    long_interval=0.038_06, grid_dim=default_grid, batch_limit = 400,
    row_offset = 0
):
    res_df = None
    fname_prefix = "elev_request"
    batch_size = 1
    batch_count = 1
    rows =  grid_dim[0]
    cols = grid_dim[1]
    assert batch_size * batch_count < rows * cols
    arg_count = len(args)

    if arg_count > 1:
        fname_prefix = args[1]
    if arg_count > 2:
        batch_size = args[2]
    if arg_count > 3:
        batch_count = args[3]

    lat_step = 2 * lat_interval / rows # lat_interval, long_interval = distance from center to edge
    assert rows % 2 == 0 # only handling even # of rows and columns
    #init_lat = last_step / 2

    long_step = 2 * long_interval / cols  #see previous comment
    assert cols % 2 == 0
    #init_long = long_step / 2

    # start at NW corner of grid
    lat_start = float(center['lat']) + lat_interval
    long_start = float(center['long']) - long_interval
    cur_lat = lat_start
    cur_long = long_start
    fn_suffix = 1
    print_to_file = False
    lat_precision = len(center['lat'])
    long_precision = len(center['long'])
    if not print_to_file:
        index = [str( lat_start + (-1) * r * lat_step )[:lat_precision].ljust(lat_precision, '0') for r in range(rows) ]
        n_index = [float(v) for v in index]
        col_names_long = [str( long_start + c * long_step )[:long_precision].ljust(long_precision, '0') for c in range(cols)]
        n_col_longs = [float(v) for v in col_names_long]
        init_vals = [[float(0) for c in range(cols)] for r in range(rows)]

        res_df = pd.DataFrame(init_vals, index=index, columns=col_names_long)

    for r in range(rows):
        if r > 0: #easier to read at the top of the loop
            cur_lat -= lat_step

        for c in range(cols):
            if c > 0:
                cur_long += long_step

            k_th_item = r * cols + c
            if print_to_file:
                if k_th_item % batch_limit == 0:
                    fname = get_file_name(fname_prefix, fn_suffix, r, c)
                    fname = os.path.join(elev_data_path, fname)
                    fn_suffix += 1
                    if os.path.exists(fname):
                        os.remove(fname)

                with open(fname, 'a') as out_fn:
                    entry = str(cur_long) + ',' + str(cur_lat)
                    out_fn.write(entry + '\n')
            else:
                if k_th_item % 100 == 0:
                    print(f'item {k_th_item}, r:{r}, c:{c}')
                params = {}
                params['x'] = res_df.columns[c]
                params['y'] = res_df.index[r]
                params['id'] = k_th_item
                params['units'] = "Meters"
                params['includeDate'] = 'true'
                x = requests.get(target, params)
                if x.ok:
                    val = x.json()['value']
                    res_df.at[index[r], col_names_long[c]] = float(val)
                    pass

    hook = 1
    save_fn = str(dt.datetime.now())
    save_fn = save_fn.split()[-1]
    save_fn = save_fn.split(sep=".")[0]
    save_fn = save_fn.replace(':', "_")
    save_fn = csv_prefix + save_fn + ".csv"
    res_df.to_csv(save_fn)
    return res_df


def get_data(fn):
    df = pd.read_csv(fn)
    #df = df['Elev(ft)']
    #df = df.to_numpy()
    #df_new = df.reshape(4, 100)
    #df_new = pd.DataFrame(df_new)
    return df


def write_to_netlogo2():

    dirs = os.listdir(elev_data_path)

    out_fn = 'elev-by-rc.txt'
    if os.path.exists(out_fn):
        os.remove(out_fn)
    max_val = None
    min_val = None
    fix_ups = {}
    for fn in dirs:
        if fn.startswith('bulk'):
            row_start = fn.split(sep='_r')[-1].split(sep='.')[0]
            row_start = int(row_start)
            df = get_data(os.path.join(elev_data_path, fn))
            elevs = df['Elev(m)']
            last_good = -1
            with open(out_fn, 'a') as out_thing:
                for idx in range(len(elevs)):
                    cur = elevs[idx]
                    abort = False
                    if abs(cur) > 1000:
                        #print(f'bad value: {cur} at {fn}:{idx}')
                        try:
                            cur = elevs[last_good]
                        except Exception:
                            hook = True

                        if fn not in fix_ups:
                            fix_ups[fn] = []

                        fix_ups[fn].append((idx, cur, last_good))
                    else:
                        if max_val is None:
                            max_val = cur
                        if min_val is None:
                            min_val = cur
                        last_good = idx

                    if abs(cur) > 1000:
                        hook2 = True

                    max_val = max_val if cur < max_val else cur
                    min_val = min_val if cur > min_val else cur
                    cur_row = row_start + (idx // 100)
                    cur_col = idx % 100

                    cur_row = 50 - cur_row
                    cur_col = cur_col - 50
                    entry = f'{cur_col} {cur_row} {cur}'
                    # out_thing.write(entry + '\n')

    for fn_key in fix_ups:
        err_total = len(fix_ups[fn_key])
        if err_total > 40:
            print(f"File {fn_key} MORE THAN 10%")
        else:
            print(f"File {fn_key} errors=> {err_total}")
            #for e in fix_ups[fn_key]:
            #    print(e)

    finish = False
    if finish:
        for fn in dirs:
            if fn.startswith('bulk'):
                row_start = fn.split(sep='_r')[-1].split(sep='.')[0]
                row_start = int(row_start)
                df = get_data(os.path.join(elev_data_path, fn))
                elevs = df['Elev(m)']
                last_good = -1
                with open(out_fn, 'a') as out_thing:
                    for idx in range(len(elevs)):
                        cur = elevs[idx]
                        if abs(cur) > 1000:
                            #print(f'bad value: {cur} at {fn}:{idx}')
                            cur = elevs[last_good]
                        else:
                            last_good = idx

                        cur = cur - min_val
                        cur_row = row_start + (idx // 100)
                        cur_col = idx % 100

                        cur_row = 50 - cur_row
                        cur_col = 50 - cur_col
                        entry = f'{cur_col} {cur_row} {cur}'
                        out_thing.write(entry + '\n')

    print(f'max = {max_val}, min = {min_val}, normalized: 0 - {max_val - min_val}')

def write_to_netlogo(df_stuff, rows, cols):

    out_fn = 'elev-by-rc.txt'
    if os.path.exists(out_fn):
        os.remove(out_fn)
    max_val = None
    min_val = None
    fix_ups = {}
    df = df_stuff[1]
    min_val = df.min().min()

    max_val = df.max().max()
    slope = df.pct_change()

    mean_val = df.mean().mean()
    hist = {}
    levels = [ .55, .50, .45, .4, .35, .3, .25, .2]
    for l in levels:
        hist[l] = []
        hist[-1 * l] = []


    with open(out_fn, 'a') as out_thing:
        for r in range(rows):
            for c in range(cols):
                elev = df.iloc[r, c]
                abort = False
                if r == 96 and c == 90:
                    hook = 1

                dist = abs(elev - mean_val) / mean_val
                for l in levels:
                    if dist > l:
                        info = (elev, elev * 3.28, df.index[r], float(df.columns[c]), r, c, slope.iloc[r,c])
                        if elev > mean_val:
                            hist[l].append(info)
                        else:
                            hist[-1 * l].append(info)
                        break

                if abs(elev) > 1000:
                    #print(f'bad value: {cur} at {fn}:{idx}')
                    try:
                        pass
                        #cur = elevs[last_good]
                    except Exception:
                        hook = True

                    #if fn not in fix_ups:
                    #    fix_ups[fn] = []

                    fix_ups["df read"].append((r, c, elev))

                cur_row = 50 - r
                cur_col = c - 50
                elev = (elev - min_val)
                entry = f'{cur_col} {cur_row} {elev}'
                out_thing.write(entry + '\n')

    #qs = df.quantile(.1)
    #print(qs)
    print(f'mean = {mean_val}, hist bins=')
    print([len(hist[k]) for k in hist])
    keys = list(hist.keys())
    keys.sort()
    for k in keys:
        print(f'hist:{k} = ')
        for v in hist[k]:
            print(v)

    for r in range(94, 100):
        row = [0] * (100-87)
        for c in range(87, 100):
            elev2 = df.iloc[r,c]
            dist = (elev2 - mean_val) / mean_val
            r2 = r - 94
            c2 = c - 87
            if r == 96 and c == 90:
                hook = 1

            if dist <= -.2:
                row[c2] = round(dist, 1)
            else:
                try:
                    row[c2] = elev2
                except ValueError:
                    hook = 1
                else:
                    hook = 2

        row = [str(round(v, 2)) for v in row]
        print(r, ' '.join(row))

    np.argmax(df)
    print(f'max = {max_val} ({str(max_val*3.28)[:6]} ft), min = {min_val}, normalized: 0 - {max_val - min_val}')

def write_list_to_netlogo(data):

    for k in data:
        out_fn = k + "-init-data.txt"
        if os.path.exists(out_fn):
            os.remove(out_fn)

        with open(out_fn, 'a') as out_thing:
            for t in data[k]:
                r = t[1]
                c = t[2]
                if r < 0 or c < 0:
                    continue

                cur_row = 50 - r
                cur_col = c  - 50
                entry = f'{cur_col} {cur_row}'
                out_thing.write(entry + '\n')
        print(f'Wrote to {out_fn}')

def get_df(f_path=None, fn=None):
    if not f_path:
        f_path = "./"

    res = []
    if not fn:
        for fn in os.listdir(f_path):
            if fn.endswith(".csv") and fn.startswith(csv_prefix):
                cur_df = pd.read_csv(fn, index_col=0)
                lat_precision = len(reference_center['lat'])
                new_index = [str(v)[:lat_precision].ljust(lat_precision, '0') for v in cur_df.index]
                res.append((fn, cur_df, new_index))
    return res

def find_grid_pos(info, cur_lat, cur_long):

    def find_value_pos(val, labels, asc=True):
        ret = -1
        for i, v in enumerate(labels):
            cur_border = float(v)
            if asc and val >= cur_border:
                continue
            elif not asc and val <= cur_border:
                continue
            else:
                if i == 0:
                    hint = 'larger than northernmost'
                    if asc: hint = 'smaller than westernmost'
                    print(f"{val} {hint} lat_labels[0], = {labels[0]}")
                ret = i - 1
                break

        if i == len(labels):
            hooks = 1

        return ret

    results = {}

    for cur_info in info:
        lat_labels = cur_info[2]

        try:
            long_labels = cur_info[1].columns
        except:
            hook = 1

        r = find_value_pos(cur_lat, lat_labels, asc=False)
        c = find_value_pos(cur_long, long_labels, asc=True)
        fn = cur_info[0]

        if fn not in results:
            results[fn] = []

        results[fn].append([r, c])

    return results

def convert_coords_to_grid(coords, f_path=None, fn=None, filter=None, startswith=True):
    def set_results(crd, fn, r, c):
        if crd not in ret_forward:
            ret_forward[crd] = []

        ret_forward[crd].append((fn, r, c))

        back_key = tuple([r, c])
        if back_key not in ret_back:
            ret_back[back_key] = dict()

        cur_back = dict()
        cur_back['file'] = fn
        cur_back['group'] = crd
        cur_back['lat'] = cur_lat
        cur_back['long'] = cur_long
        ret_back[back_key] = {k:v for k, v in cur_back.items()}

    info = get_df(f_path, fn)

    ret_forward = dict()
    ret_back = dict()
    assert(len(info) == 1)

    for k, v in coords.items():
        crd = k
        if isinstance(v, tuple) :
            cur_lat = v[0]
            cur_long = v[1]

            res_by_file = find_grid_pos(info, cur_lat, cur_long)
            for k in res_by_file:
                fn = k
                for cur_r_c in res_by_file[k]:
                    set_results(crd, fn, cur_r_c[0], cur_r_c[1])

        elif isinstance(v, list):
            for pt in v:
                cur_lat = pt[0]
                cur_long = pt[1]

                res_by_file = find_grid_pos(info, cur_lat, cur_long)
                for k in res_by_file:
                    fn = k
                    for cur_r_c in res_by_file[k]:
                        set_results(crd, fn, cur_r_c[0], cur_r_c[1])

        else:
            raise ValueError('Unknown type!')

    return ret_forward, ret_back

def interpolate(pts, divs = None):
    """
    Assume lat, long format, N of Eq and W of Greenwich (i.e. neg to the west)
    also assume grid has r,c === 0 at NW corner
    doing a linear interpolation, assuming long/lat difference are roughly linear in ground difference
    assume first point is NW of 2 point for line interpolation
    :param pt1:
    :param pt2:
    :return:
    """
    ret = []
    start = [pts[0][0], pts[0][1]]
    if len(pts) == 2:
        if not divs:
            return pts
        if divs == 1:
            return pts

        tick_marks = divs - 1
        long_size = (pts[0][1] - pts[1][1]) / divs
        lat_size = (pts[0][0] - pts[1][0]) / divs
        ret.append(start)
        for i in range(tick_marks):
            ret.append([start[0] - (i + 1) * lat_size, start[1] - (i + 1) * long_size])

        ret.append([pts[1][0], pts[1][1]])

    return ret

if __name__ == "__main__":

    #main(sys.argv)
    hook = 1

    write_csv = False
    if write_csv:
        results = get_df()
        write_to_netlogo(results[0], default_grid[0], default_grid[1])

    write_roads = True
    if write_roads:
        coords = {}
        coords['cashtown'] = (39.851951117300096, -77.28371303627033)
        coords['ch pike SE terminus'] = (39.83091075801213, -77.23668826869114)

        results = convert_coords_to_grid(coords)

        road = interpolate([coords['cashtown'], coords['ch pike SE terminus']], divs=8)
        cemetary_hill = (39.819792495059, -77.23043695946674)
        road2 = interpolate([coords['ch pike SE terminus'],  cemetary_hill], divs=3)
        road.extend(road2[1:])

        chambersburg_road = {"ChambersburgRoad": road}

        road_res = convert_coords_to_grid(chambersburg_road)
        write_list_to_netlogo(road_res[0])
        pass






