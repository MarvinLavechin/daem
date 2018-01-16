# Dense reconstruction from electron microscope images

## Create environment `heuhaufen` and install requirements

Using conda (Anaconda Python distribution):

1) Mac OS-X without GPU

```bash
conda create --name heuhaufen python=2 scikit-learn scikit-image pandas=0.19.2 bokeh tensorflow
source activate heuhaufen
pip install tifffile

```

2) Linux with GPU + CudNN

*Note:* tested on Ubuntu 16.04.2 LTS

- Create environment and install everything except TensorFlow

```bash
conda create --name heuhaufen python=2 scikit-learn scikit-image pandas=0.19.2 bokeh
source activate heuhaufen
pip install tifffile
```

- Install TensorFlow

```bash
export TF_BINARY_URL=https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow-0.11.0rc0-cp27-none-linux_x86_64.whl
pip install --ignore-installed --upgrade $TF_BINARY_URL
```

- Test TensorFlow installation

```bash
python -c 'import tensorflow as tf; print(tf.__version__)'  # for Python 2
```


