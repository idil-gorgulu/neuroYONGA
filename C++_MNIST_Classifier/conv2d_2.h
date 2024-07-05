#ifndef CONV2D_2_H
#define CONV2D_2_H

#include "init.h"

// Assuming fixed_type is defined in init.h
void conv_layer_2(const fixed_type input[13][13][32], fixed_type output[11][11][64], const fixed_type weights[3][3][32][64], const fixed_type biases[64]);

#endif // CONV2D_2_H
