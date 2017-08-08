import os
import pandas
import numpy as np

import json


def main(test_path='temp/publication/loss_functions/test'):
    labels = ['membranes', 'synapses', 'mitochondria']

    # concatenate the evaluation and parameters for all runs
    dfs = []
    for label in labels:
        for run in range(1, 6*3+1):
            df = read_run_from_json_and_csv(test_path, run, label)
            dfs.append(df)
    data = pandas.concat(dfs)

    # save aggregated data (in long format)
    data.to_csv(os.path.join(test_path, 'summary_long.csv'))

    # convert long to wide: label x metric --> label_metric
    metrics = data.columns.to_series().groupby(data.dtypes).groups[np.dtype('float64')]
    data2 = data.pivot_table(index=['classic_loss', 'run', 'sample'], columns='label', values=metrics)
    data2.columns = ['{}_{}'.format(x, y) for x, y in
                     zip(data2.columns.get_level_values(1), data2.columns.get_level_values(0))]
    data2 = data2.reset_index()

    # save aggregated data (in wide format)
    data2.to_csv(os.path.join(test_path, 'summary_wide.csv'))

    # TODO: interactive plot with bokeh
    # bokeh_plot(data2, test_path)  # not fully functional, e.g. cannot change label and metric


def read_run_from_json_and_csv(test_path, run, label):

    # path to the test result for a particular model
    base_path = os.path.join(test_path, '%d' % run)

    # getting parameters from the options json file
    with open(os.path.join(base_path, "options.json")) as f:
        options = dict(json.loads(f.read()).items())
    classic_loss = options['Y_loss']

    # read evaluation results
    df = pandas.read_csv(os.path.join(base_path, 'evaluation/%s.csv' % label))  # no index_col

    # add parameters
    df['classic_loss'] = classic_loss
    df['label'] = label
    df['run'] = run

    return df



if __name__ == "__main__":
    main()

