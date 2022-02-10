#!/srv/manage/download/venv/bin/python3
import sys
import numpy
import pandas
import lzma
import warnings
import pickle

pickle.HIGHEST_PROTOCOL = 4

if len(sys.argv) != 3:
    print('Invalid arguments')
    sys.exit(-1)

input_path = sys.argv[1]
output_path = sys.argv[2]

index = []
sizes = []
hashes = []

with lzma.open(input_path, 'rb') as f:
    for line in f:
        line = line.decode('utf-8').strip()
        if not line:
            continue
        elems = line.split(maxsplit=2)
        if '/' not in elems[2]:
            continue
        index.append(elems[2])
        sizes.append(int(elems[1]))
        hashes.append(bytes(bytearray.fromhex(elems[0])))

df = pandas.DataFrame(index=index)
df['size'] = sizes
df['sha256'] = hashes

df['subid'] = [s.split('/', 1)[0] for s in df.index]

for subid in numpy.unique(df['subid']):
    dfs = df.loc[df['subid'] == subid].copy()
    del dfs['subid']

    dfs.index = [s.split('/', 1)[1] for s in dfs.index]

    with warnings.catch_warnings():
        warnings.filterwarnings("ignore")
        dfs.to_hdf(output_path, key=subid, complevel=9, complib='blosc:zstd')
