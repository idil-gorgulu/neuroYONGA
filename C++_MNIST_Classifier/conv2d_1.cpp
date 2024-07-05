#include "conv2d_1.h"
#include <algorithm>
#include <iostream>

#include <algorithm> // For std::max
#include <iostream>

void conv_layer(const fixed_type input[28][28][1], fixed_type output[26][26][32], const fixed_type weights[3][3][1][32], const fixed_type biases[32]) {
    for (int m = 0; m < 32; m++) {
        for (int i = 0; i < 26; i++) {
            for (int j = 0; j < 26; j++) {
                fixed_type sum = biases[m];
                for (int ki = 0; ki < 3; ki++) {
                    for (int kj = 0; kj < 3; kj++) {
                        sum += input[i + ki][j + kj][0] * weights[ki][kj][0][m];
                    }
                }
                output[i][j][m] = std::max(sum, 0.0f);  
            }
        }
    }
}


