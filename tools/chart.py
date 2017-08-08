import os
import pandas
import numpy as np

from bokeh.palettes import Viridis10 as palette
from bokeh.layouts import layout, column, row
from bokeh.plotting import figure, output_file, show, ColumnDataSource
from bokeh.models import HoverTool, Div, DataTable, TableColumn, NumberFormatter, LinearAxis, Select, CustomJS, Slider, Button

try:
    from functools import lru_cache
except ImportError:
    # Python 2 does stdlib does not have lru_cache so let's just
    # create a dummy decorator to avoid crashing
    print ("WARNING: Cache for this example is available on Python 3 only.")
    def lru_cache():
        def dec(f):
            def _(*args, **kws):
                return f(*args, **kws)
            return _
        return dec

csv_path = '../temp/Example_2D_3Labels/train/evaluation/membranes.csv'
csv_dir, csv_name = os.path.split(csv_path)
html_path = os.path.join(csv_dir, os.path.splitext(csv_name)[0] + '.html')


def main():
    df = pandas.read_csv(csv_path, index_col=0)

    # assuming all float values are metrics
    metrics = df.columns.to_series().groupby(df.dtypes).groups[np.dtype('float64')]

    # prepare moving average for each metrics
    for column_name in metrics:
        df['MA_' + column_name] = df[column_name]

    source = ColumnDataSource(data=df)

    show_page(source, metrics)


def show_page(source, choices):

    output_file(html_path)

    hover = custom_hover(choices)

    description = Div(text="""
        <h1>An Interactive Explorer for Evaluation Results</h1>
        <p>
        Interact with the widgets on the left to show correlations of metrics.
        </p>
        """, width=1000)

    select_label = show_selection(csv_dir)
    fig_correlation = show_correlation(source, choices)
    fig_series = show_series(source, choices, hover)
    fig_datatable = show_datatable(source, choices)
    l = layout([
        [description],
        select_label + fig_correlation,
        fig_series,
        fig_datatable
    ], sizing_mode='fixed')

    show(l)

def show_selection(csv_dir):

    desc = Div(text="""
        <h2>Labels</h2>
        <p>
        Choose label to evaluate.
        </p>
        """, width=200)

    labels = ('mitochondria', 'synapses', 'membranes')

    elements = [desc]

    for label in labels:
        b = Button(label=label)
        b.callback = CustomJS(code="""window.open("%s","_self");""" % (label+'.html'))
        elements.append(b)

    return [column(elements)]


def custom_hover(column_names):

    values_str = "<table><tr>" + \
                 "</tr><tr>".join(
                     map(lambda x: "<th align='right'>%s</th><th>= @%s{0.000}</th>" % (x, x), column_names)) + \
                 "</tr></table>"

    hover = HoverTool(tooltips="""
        <div>
            <div>
                <img
                    src="%s-sample@sample.jpg" height="330" alt="@pred_path" width="480"
                    style="text-align: left"
                    border="1"
                ></img>
            </div>
            <div>
                <span style="font-size: 14px; font-weight: bold;">%s</span>
                <span style="font-size: 14px; color: #966;"><br />[sample @sample]</span>
            </div>
        </div>
        """ % (csv_name, values_str))

    return hover


def show_correlation(source, choices):

    description = Div(text="""<h2>Correlations</h2>
        <p>Choose metrics to compare:</p>
        """, height=80)

    fig = figure(plot_width=350, plot_height=350, tools=['box_select', 'reset'])

    plot = fig.circle(choices[0], choices[1], size=2, source=source,
                      selection_color="orange", alpha=0.6, nonselection_alpha=0.1, selection_alpha=0.4)

    # widgets for selecting the data series for each axis
    ticker_xaxis = ticker_axis(source, choices, fig, plot, axis='x')
    ticker_yaxis = ticker_axis(source, choices, fig, plot, axis='y')

    # layout with description and widgets on left side
    widgets = column(description, ticker_xaxis, ticker_yaxis)

    return [widgets, fig]


def ticker_axis(source, choices, fig, plot, axis):

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

    callback1 = CustomJS(args=dict(source=source, axis=linear_axis, plot=plot),
                         code=axis_callback_code.format(axis=axis))

    ticker = Select(value=choices[initial_choice], options=choices, title=axis + '-axis')

    ticker.js_on_change('value', callback1)

    return ticker


def show_series(source, choices, hover):

    description = Div(text="""
        <h2>Series</h2>
        <p>Hover over the points to see more information about each sample.
        Click on legend items to hide/show series.</p>
        """, width=700, height=100)

    # figure with x axis expanded leftside that legend does not hide datapoints
    # TODO: place the legend outside of the plot area
    max_series = max(source.data['sample'])
    fig = figure(plot_width=1000, plot_height=400, tools=[hover, 'box_select', 'reset'],
                 x_range=(-0.25 * max_series, max_series))
    fig.xaxis.axis_label = "sample"
    fig.yaxis.axis_label = "value of metric"

    for column_name, column_color in zip(choices, palette):
        fig.scatter('sample', column_name, legend=dict(value=column_name), color=column_color, source=source)
        fig.line('sample', 'MA_' + column_name, legend=dict(value=column_name), color=column_color, source=source)

    # legend which can hide/select a specific metric
    fig.legend.location = "top_left"
    fig.legend.click_policy = "hide"

    # widgets: a slider for the moving average for each variable in choices
    slider = moving_average_slider(source, choices)

    # layout with description and widgets on top
    fig_series = column(row(description, slider), fig)

    return [fig_series]


def moving_average_slider(source, choices):

    callback = CustomJS(args=dict(source=source, args=ColumnDataSource({'column_names': choices})), code="""
        function simple_moving_averager(period) {
            var nums = [];
            return function(num) {
                nums.push(num);
                if (nums.length > period)
                    nums.splice(0,1);  // remove the first element of the array
                var sum = 0;
                for (var i in nums)
                    sum += nums[i];
                var n = period;
                if (nums.length < period)
                    n = nums.length;
                return(sum/n);
            }
        }

        var data = source.data;
        var column_names = args.data['column_names']

        for (var i in column_names){
            var column_name = column_names[i];
            data['MA_'+column_name]  = data[column_name].map(simple_moving_averager(cb_obj.value));
        }

        source.change.emit();
        """)

    slider = Slider(start=1, end=100, value=1, step=1, title="moving average window size")
    slider.js_on_change('value', callback)

    return slider


def show_datatable(source, choices):
    description = Div(text="""
        <h2>Data</h2>
        """, height=50)

    choosen_columns = map(lambda column_name: TableColumn(field=column_name,
                                                          title=column_name,
                                                          formatter=NumberFormatter(format="0.000")),
                          choices)

    data_table = DataTable(source=source, columns=choosen_columns, width=1000)

    # layout with title at top
    fig_datatable = column(description, data_table)

    return [fig_datatable]


if __name__ == "__main__":
    main()
