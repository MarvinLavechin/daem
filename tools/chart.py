import os
import pandas
import numpy as np

from bokeh.palettes import Viridis10 as palette
from bokeh.layouts import layout, column, row
from bokeh.plotting import figure, output_file, show, ColumnDataSource
from bokeh.models import HoverTool, Div, DataTable, TableColumn, NumberFormatter, PreText, Select, CustomJS, Slider

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

df = pandas.read_csv(csv_path, index_col=0)
column_names = df.columns.to_series().groupby(df.dtypes).groups[np.dtype('float64')]
df['x']=df[column_names[0]]
df['y']=df[column_names[1]]
source = ColumnDataSource(data=df)
output_file(html_path)

# hover = HoverTool(
#     tooltips="""
#     <div>
#         <div>
#             <img
#                 src="@pred_path" height="256" alt="@pred_path" width="256"
#                 style="float: left; margin: 0px 15px 15px 0px;"
#                 border="2"
#             ></img>
#         </div>
#         <div>
#             <span style="font-size: 17px; font-weight: bold;">@recall</span>
#             <span style="font-size: 15px; color: #966;">[sample @sample]</span>
#         </div>
#     </div>
#     """
# )

values_str = "<br />".join(map(lambda x: "%s=@%s" % (x,x), column_names))

values_str = "<table><tr>" + \
             "</tr><tr>".join(map(lambda x: "<th align='right'>%s</th><th>= @%s{0.000}</th>" % (x,x), column_names)) + \
             "</tr></table>"


print values_str


hover = HoverTool(
    tooltips="""
    <div>
        <div>
            <img
                src="%s-sample@sample.jpg" height="275" alt="@pred_path" width="400"
                style="text-align: left"
                border="2"
            ></img>
        </div>
        <div>
            <span style="font-size: 14px; font-weight: bold;">%s</span>
            <span style="font-size: 14px; color: #966;"><br />[sample @sample]</span>
        </div>
    </div>
    """ % (csv_name, values_str)
)

# desc
desc = Div(text="""
<style>
h1 {
    margin: 1em 0 0 0;
    color: #2e484c;
    font-family: 'Julius Sans One', sans-serif;
    font-size: 1.8em;
    text-transform: uppercase;
}
a:link {
    font-weight: bold;
    text-decoration: none;
    color: #0d8ba1;
}
a:visited {
    font-weight: bold;
    text-decoration: none;
    color: #1a5952;
}
a:hover, a:focus, a:active {
    text-decoration: underline;
    color: #9685BA;
}
p {
    font: "Libre Baskerville", sans-serif;
    text-align: justify;
    text-justify: inter-word;
    width: 80%;
    max-width: 800;
}
</style>

<h1>An Interactive Explorer for Evaluation Results</h1>

<p>
Interact with the widgets on the left to show correlations of metrics.
Hover over the circles to see more information about each sample.
</p>
""", width=1000)

# set up widgets

callback1 = CustomJS(args=dict(source=source), code="""
    var data = source.data;
    var f = cb_obj.value
    console.log(f);
    data['x'] = data[f]
    source.change.emit();
""")

ticker1 = Select(value=column_names[0], options=column_names, title='x-axis')
ticker1.js_on_change('value', callback1)

callback2 = CustomJS(args=dict(source=source), code="""
    var data = source.data;
    var f = cb_obj.value
    console.log(f);
    data['y'] = data[f]
    source.change.emit();
""")

ticker2 = Select(value=column_names[1], options=column_names, title='y-axis')
ticker2.js_on_change('value', callback2)

# set up plots
corr = figure(plot_width=350, plot_height=350,
              tools='pan,wheel_zoom,box_select,reset')
corr.circle('x', 'y', size=2, source=source,
            selection_color="orange", alpha=0.6, nonselection_alpha=0.1, selection_alpha=0.4)

widgets = column(ticker1, ticker2)
main_row = row(corr, widgets)

# plot
data_plot = figure(plot_width=1000, plot_height=400, tools=[hover, 'pan','wheel_zoom','box_select','reset'], title="Mouse over the dots", x_range=(-0.25*max(df['sample']), max(df['sample'])))
for column_name, column_color in zip(column_names, palette):
    data_plot.scatter('sample', column_name, legend=dict(value=column_name), color=column_color, source=source)
data_plot.legend.location = "top_left"
data_plot.legend.click_policy= "hide"

# table
# columns = map(lambda column_name: TableColumn(field=column_name, title=column_name), ['sample',] + column_names)
columns = map(lambda column_name: TableColumn(field=column_name, title=column_name, formatter=NumberFormatter(format="0.000")), column_names)
data_table = DataTable(source=source, columns=columns, width=1000)

l = layout([
    [desc],
    [main_row],
    [data_plot],
    [data_table]
], sizing_mode='fixed')


show(l)
