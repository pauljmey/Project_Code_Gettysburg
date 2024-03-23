import sys, os



def main(
    args, center = {'lat': 39.829_602, 'long': -77.244_14} , lat_interval=0.029_228,
    long_interval=0.038_06, grid_dim=(100, 100), batch_limit = 400,
    row_offset = 0
):

    def get_file_name(fn_pref, fn_suf, start_r, start_c):
        return fn_pref + "_" + str(fn_suf) + '_r' + str(start_r) + '_c' + str(start_c) + '.txt'


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
    lat_start = center['lat'] + lat_interval
    long_start = center['long'] + long_interval
    cur_lat = lat_start
    cur_long = long_start
    fn_suffix = 1
    for r in range(rows):
        if r > 0: #easier to read at the top of the loop
            cur_lat -= lat_step

        for c in range(cols):
            if c > 0:
                cur_long -= long_step

            k_th_item = r * cols + c
            if k_th_item % batch_limit == 0:
                fname = get_file_name(fname_prefix, fn_suffix, r, c)
                fn_suffix += 1
                if os.path.exists(fname):
                    os.remove(fname)

            with open(fname, 'a') as out_fn:
                entry = str(cur_long) + ',' + str(cur_lat)
                out_fn.write(entry + '\n')















if __name__ == "__main__":
    main(sys.argv)
    output