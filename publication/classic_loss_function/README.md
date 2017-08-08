# Dense reconstruction from electron microscope images
## Comparing different classic loss functions

![loss_functions](adapted_RAND_classic_loss_functions.jpg)

Mean and standard deviation of the adapted RAND score of 4 test images for 3 model trained on 3 different splits for the train and test sets.

A residual net with 9 residual layers (= total 24 layers) was used for the generator.

All loss functions perform well for the membrane label.
The mitochondria label is also well recognized, except  with the (original pix2pix) hinge loss.
For the synapse label, the best performance is obtained using the square loss and the softmax cross entropy loss. However, the softmax cross entropy is not well justified, because the synapses and membrane label are not mutually exclusive.


### Reproduce results

Download the VNC dataset (if necessary)

Run the training, test and aggregate the data

```bash
bash publication/loss_functions/survery_loss_functions.sh
```

There will be two files in the folder `temp/publication/loss_functions/test`: `summary_long.csv` and `summary_wide.scv`.
The above diagrams are created from the F-score (=adapted RAND score) for each test image. The curves represent a fit with a quadratic function for the number of layers.

*Notes:*

Loss functions:
- cross entropy (approximated)
- dice
- hinge
- logistic
- softmax cross entropy
- square


