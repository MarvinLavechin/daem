import os
import pandas
import numpy as np

from bokeh.palettes import Viridis4 as palette
from bokeh.layouts import layout, column, row
from bokeh.plotting import figure, output_file, show, ColumnDataSource
from bokeh.models import HoverTool, Div, DataTable, TableColumn, NumberFormatter, LinearAxis, Select, CustomJS, Slider, Button

import json    # must be imported after bokeh


def main(test_path='temp/publication/how_deep/test'):
    labels = ['membranes', 'synapses', 'mitochondria']

    # concatenate the evaluation and parameters for all runs
    dfs = []
    for label in labels:
        for run in range(1,21):
            df = read_run_from_json_and_csv(test_path, run, label)
            dfs.append(df)
    data = pandas.concat(dfs)

    # save aggregated data (in long format)
    data.to_csv(os.path.join(test_path, 'summary_long.csv'))

    # convert long to wide: label x metric --> label_metric
    metrics = data.columns.to_series().groupby(data.dtypes).groups[np.dtype('float64')]
    data2 = data.pivot_table(index=['generator', 'layers', 'sample'], columns='label', values=metrics)
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
    generator = options['generator']

    # calculate the number of layers depending on generator network and its specific parameters
    if generator == 'unet':
        layers = options['u_depth'] * 2  # 1 for down sampling and 1 for up sampling at each level
    elif generator == 'densenet':
        layers = options['n_dense_blocks'] * options['n_dense_layers'] + 6  # 3 for each encoder and decoder
    elif generator == 'resnet':
        layers = options['n_res_blocks'] * 2 + 6  # 2 for transformation, 3 for each encoder and decoder
    elif generator == 'highwaynet':
        layers = options['n_highway_units'] * 2 + 6  # 2 for transformation, 3 for each encoder and decoder

    # read evaluation results
    df = pandas.read_csv(os.path.join(base_path, 'evaluation/%s.csv' % label))  # no index_col

    # add parameters
    df['generator'] = generator
    df['layers'] = layers
    df['label'] = label
    df['run'] = run

    return df

def bokeh_plot(data, test_path):

    networks = ['unet', 'resnet', 'highwaynet', 'densenet']


    # assuming all float values are metrics
    metrics = data.columns.to_series().groupby(data.dtypes).groups[np.dtype('float64')]

    # calculate mean for each
    data_mean = data.groupby(['generator', 'layers'])[metrics].mean().reset_index()
    source = dict()
    source_mean = dict()
    for network in networks:
        source[network] = ColumnDataSource(data[data.generator == network])
        source_mean[network] = ColumnDataSource(data_mean[data_mean.generator == network])
    output_file(os.path.join(test_path, "select.html"))
    description = Div(text="""
        <h1>Evaluation of network type and depth for generator</h1>
        <p>
        Interact with the widgets to select metric and evaluated label.
        </p>
        """, width=1000)
    fig = figure(plot_width=1000, plot_height=1000, tools=['box_select', 'reset'])
    fig.xaxis.axis_label = "layers"
    fig.yaxis.axis_label = "value of metric"
    plots = []
    for network, column_color in zip(networks, palette):
        plot = fig.line('layers', metrics[0], legend=dict(value=network), color=column_color,
                        source=source_mean[network])
        plot = fig.scatter('layers', metrics[0], legend=dict(value=network), color=column_color, source=source[network])

    # legend which can hide/select a specific metric
    fig.legend.location = "bottom_right"
    fig.legend.click_policy = "hide"
    choices = metrics
    axis = 'y'
    axis_callback_code = """
        plot.glyph.{axis}.field = cb_obj.value
        axis.attributes.axis_label = cb_obj.value;
        axis.trigger('change');
        source.change.emit();
        """
    if axis == 'x':
        fig.xaxis.visible = None
        position = 'below'
        initial_choice = 0
    else:
        fig.yaxis.visible = None
        position = 'left'
        initial_choice = 1
    linear_axis = LinearAxis(axis_label=choices[initial_choice])
    fig.add_layout(linear_axis, position)
    callback1 = CustomJS(args=dict(source=source[network], axis=linear_axis, plot=plot),
                         code=axis_callback_code.format(axis=axis))
    ticker = Select(value=choices[initial_choice], options=choices, title=axis + '-axis')
    ticker.js_on_change('value', callback1)
    l = layout([
        [description],
        [ticker],
        [fig]
    ], sizing_mode='fixed')
    show(l)



if __name__ == "__main__":
    main()
else:
    main()
