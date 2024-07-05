#ifndef CONV2D_1_H
#define CONV2D_1_H

#include "init.h"

// Convolution layer function declaration
void conv_layer(const fixed_type input[28][28][1], fixed_type output[26][26][32], const fixed_type weights[3][3][1][32], const fixed_type biases[32]);

#endif // CONV2D_1_H
