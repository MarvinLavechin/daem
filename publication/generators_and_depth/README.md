# Dense reconstruction from electron microscope images
## Comparing different generators and depths

|u net|residual net|
|---|---|
|![unet](adapted_RAND_u_net.jpg)|![unet](adapted_RAND_res_net.jpg)|

|highway net|dense net|
|---|---|
|![highwaynet](adapted_RAND_highway_net.jpg)|![densenet](adapted_RAND_dense_net.jpg)|


Download the VNC dataset (if necessary)

Run the training and test

```bash
bash publication/how_deep/how_deep.sh
```

Run the interactive visualization

```bash
pyhton publication/how_deep/bokeh_plot.py
```

