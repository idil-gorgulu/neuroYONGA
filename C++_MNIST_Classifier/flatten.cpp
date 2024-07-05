#include "flatten.h"
#include <iostream>

void flatten_layer(const fixed_type input[5][5][64], fixed_type output[1600]) {
    /*for(int i = 0; i < 5; i++){
        for(int j = 0; j < 64; j++){
            std::cout << "Layer Input[" << i << ", 0," << j << "]: " << input[i][0][j] << std::endl;
        }
    }*/

    int idx = 0;
    for (int i = 0; i < 5; ++i) {
        for (int j = 0; j < 5; ++j) {
            for (int k = 0; k < 64; ++k) {
                output[idx++] = input[i][j][k];
            }
        }
    }
}

