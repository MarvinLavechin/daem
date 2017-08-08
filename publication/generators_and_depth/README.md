# Dense reconstruction from electron microscope images
## Comparing different generators and depths

|u net|residual net|
|---|---|
|![unet](adapted_RAND_u_net.jpg)|![unet](adapted_RAND_res_net.jpg)|

|highway net|dense net|
|---|---|
|![highwaynet](adapted_RAND_highway_net.jpg)|![densenet](adapted_RAND_dense_net.jpg)|

The residual net with 9 residual layers (= total 24 layers) performs best on membranes, mitochondria and synapses.

### Reproduce results

Download the VNC dataset (if necessary)

Run the training, test and aggregate the data

```bash
bash publication/how_deep/how_deep.sh
```

There will be two files in the folder `temp/publication/how_deep/test`: `summary_long.csv` and `summary_wide.scv`.
The above diagrams are created from the F-score (=adapted RAND score) for each test image. The curves represent a fit with a quadratic function for the number of layers.

*Note:*

|network|Number of layers|
|---|---|
|u net|u_depth * 2|
|residual net|3 + 2 * n_res_blocks + 3|
|highway net|3 + 2 * n_highway_units + 3|
|dense net|3 + 2 * n_dense_blocks * n_dense_layers + 3|

The additional 6 layers for residual, highway and dense net correspond to the 3 encoder and 3 decoder layers.

The u net contains fewer layers, but has a filter size of 64 instead of 32 for residual, highway and dense net.