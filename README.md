# Dense reconstruction from electron microscope images

![Result](examples/Example_2D_3Labels_eval_membranes.jpg)

### Prerequisites
- Linux or OSX
- Python 2 or Python 3
- CPU or NVIDIA GPU + CUDA CuDNN

### Requirements
- Tensorflow 1.0
- Scikit-learn 0.18
- Pandas
- Bokeh 12.6

### Preferred
- Anaconda Python distribution
- PyCharm

## Getting Started

- Install Tensorflow, e.g. [with Anaconda](https://www.tensorflow.org/install/install_mac#installing_with_anaconda)
- Clone this repository

```bash
git clone https://github.com/tbullmann/heuhaufen.git
```

- Clone other repositories used for computation and visualization if not yet installed

```bash
git clone https://github.com/tbullmann/imagetranslation-tensorflow.git
```

- Symlink repositories

```bash
cd heuhaufen
ln -s ../imagetranslation-tensorflow/ imagetranslation
```

- Create directories

```bash
mkdir datasets  # or symlink; for datasets
mkdir temp  # or symlink; for checkpoints, test results
```

- Download datasets
```bash
bash get-datasets.sh
```

- [Run the examples](examples/README.md)