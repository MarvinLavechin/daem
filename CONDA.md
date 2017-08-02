# Dense reconstruction from electron microscope images

## Create environment `heuhaufen` and install requirements

Using conda (Anaconda Python distribution):

1) Mac OS-X without GPU

```bash
conda create --name heuhaufen  python=2 tensorflow scikit-learn scikit-image pandas=0.19.2 bokeh=12.6
source activate heuhaufen
pip install tifffile

```

2) Linux with GPU + CudNN

(Soon)



