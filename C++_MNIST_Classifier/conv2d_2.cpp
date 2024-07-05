#include "conv2d_2.h"
#include <algorithm>
#include <iostream>

void conv_layer_2(const fixed_type input[13][13][32], fixed_type output[11][11][64], const fixed_type weights[3][3][32][64], const fixed_type biases[64]) {
    for (int m = 0; m < 64; m++) {  // Loop over each filter
        for (int i = 0; i < 11; i++) {  // Loop over output height
            for (int j = 0; j < 11; j++) {  // Loop over output width
                fixed_type sum = biases[m];
                for (int ki = 0; ki < 3; ki++) {  // Kernel height
                    for (int kj = 0; kj < 3; kj++) {  // Kernel width
                        for (int d = 0; d < 32; d++) {  // Depth from previous layer
                            sum += input[i + ki][j + kj][d] * weights[ki][kj][d][m];
                        }
                    }
                }
                output[i][j][m] = std::max(sum, 0.0f);  // Apply ReLU activation function
            }
        }
    }
}
