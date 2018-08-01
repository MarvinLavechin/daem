# Dense reconstruction from electron microscope images

## Create environment `daem` and install requirements

Using conda (Anaconda Python distribution):

1) Mac OS-X without GPU

```bash
conda create --name daem python=2 scikit-learn scikit-image pandas=0.19.2 bokeh tensorflow
source activate daem
pip install tifffile

```

2) Linux with GPU + CudNN

*Note:* tested on Ubuntu 16.04.2 LTS

- Create environment and install everything except TensorFlow

```bash
conda create --name daem python=2 scikit-learn scikit-image pandas=0.19.2 bokeh numpy=1.14.0
source activate daem
pip install tifffile
```

- Install TensorFlow while precising the needed version of numpy.

```bash
pip install tensorflow==1.6.0 numpy==1.14
```

- Test TensorFlow installation

```bash
python -c 'import tensorflow as tf; print(tf.__version__)'  # for Python 2
```


