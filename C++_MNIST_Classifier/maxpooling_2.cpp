#include <algorithm>
#include "conv2d_1.h"

void max_pooling_layer_2(const fixed_type input[11][11][64], fixed_type output[5][5][64]) {
    for (int m = 0; m < 64; m++) {  // over each channel
        for (int i = 0; i < 5; i++) {  // over each output row
            for (int j = 0; j < 5; j++) {  // over each output column
                fixed_type max_value = input[i * 2][j * 2][m];
                max_value = std::max(max_value, input[i * 2][j * 2 + 1][m]);
                max_value = std::max(max_value, input[i * 2 + 1][j * 2][m]);
                max_value = std::max(max_value, input[i * 2 + 1][j * 2 + 1][m]);
                output[i][j][m] = max_value;
            }
        }
    }
}