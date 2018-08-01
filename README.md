# Dense reconstruction from electron microscope images

![Result](examples/2D_3Labels/Example_2D_3Labels_eval_membranes.jpg)

### Prerequisites
- Linux or OSX
- Python 2
- CPU or NVIDIA GPU + CUDA CuDNN

### Requirements
- Tensorflow 1.0
- Scikit-learn 0.18
- Scikit-image
- Pandas 0.18.2
- Bokeh 12.6

### Preferred
- Anaconda Python distribution
- PyCharm

## Getting Started

- Create environment `daem` and install requirements, see [instructions](CONDA.md). 
Make sure this environment is activated.
- Clone this repository

```bash
git clone https://github.com/MarvinLavechin/daem.git
```

- Clone other repositories used for computation and visualization if not yet installed

```bash
git clone https://github.com/MarvinLavechin/imagetranslation-tensorflow
```

- Symlink repositories

```bash
cd daem
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