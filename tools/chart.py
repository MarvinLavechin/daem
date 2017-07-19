import os
import pandas
from bokeh.layouts import layout
from bokeh.plotting import figure, output_file, show, ColumnDataSource
from bokeh.models import HoverTool, Div

csv_path = '../temp/Example_2D_3Labels/train/evaluation/membranes.csv'
csv_dir, csv_name = os.path.split(csv_path)

html_path = os.path.join(csv_dir, os.path.splitext(csv_name)[0] + '.html')

df = pandas.read_csv(csv_path, index_col=0)
print df.head()
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

hover = HoverTool(
    tooltips="""
    <div>
        <div>
            <img
                src="%s-sample@sample.jpg" height="550" alt="@pred_path" width="800"
                style="float: left; margin: 0px 15px 15px 0px;"
                border="2"
            ></img>
        </div>
        <div>
            <span style="font-size: 17px; font-weight: bold;">RAND=@RAND, precision=@precision, recall=@recall</span>
            <span style="font-size: 15px; color: #966;">[sample @sample]</span>
        </div>
    </div>
    """ % csv_name
)

p = figure(plot_width=400, plot_height=400, tools=[hover],
           title="Mouse over the dots")

p.scatter('sample', 'recall', source=source)

l = layout([
    [Div(text="Text")],
    [p],
    [Div(text="Text")]
], sizing_mode='stretch_both')

show(l)
