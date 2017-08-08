import os
import pandas
import numpy as np

import json


def main(test_path='temp/publication/scaling/test'):
    labels = ['membranes', 'synapses', 'mitochondria']

    # concatenate the evaluation and parameters for all runs
    dfs = []
    for label in labels:
        for run in [1,2,4]:
            df = read_run_from_csv(test_path, run, label)
            dfs.append(df)
    data = pandas.concat(dfs)

    # save aggregated data (in long format)
    data.to_csv(os.path.join(test_path, 'summary_long.csv'))

    # convert long to wide: label x metric --> label_metric
    metrics = data.columns.to_series().groupby(data.dtypes).groups[np.dtype('float64')]
    data2 = data.pivot_table(index=['resolution', 'run', 'sample'], columns='label', values=metrics)
    data2.columns = ['{}_{}'.format(x, y) for x, y in
                     zip(data2.columns.get_level_values(1), data2.columns.get_level_values(0))]
    data2 = data2.reset_index()

    # save aggregated data (in wide format)
    data2.to_csv(os.path.join(test_path, 'summary_wide.csv'))


def read_run_from_csv(test_path, run, label):

    # path to the test result for a particular model
    base_path = os.path.join(test_path, '%d' % run)

    # read evaluation results
    df = pandas.read_csv(os.path.join(base_path, 'evaluation/%s.csv' % label))  # no index_col

    # add parameters
    df['resolution'] = 8/run   # pixel resolution: run 1 = 8nm, run 2 = 4nm, run 4 = 2nm
    df['label'] = label
    df['run'] = run

    return df

if __name__ == "__main__":
    main()

