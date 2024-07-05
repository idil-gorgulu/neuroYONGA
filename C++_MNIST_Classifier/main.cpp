#include <iostream>
#include <fstream>
#include <iomanip>
#include <string>
#include "conv2d_1.h"
#include "conv2d_2.h"
#include "init.h"
#include "maxpooling_1.h"
#include "maxpooling_2.h"
#include "flatten.h"
#include "dense.h"

int main() {
    const int H1 = 3, W1 = 3, D1 = 1, M1 = 32;  // First conv layer constants
    const int H2 = 3, W2 = 3, D2 = 32, M2 = 64; // Second conv layer constants
    const int num_neurons = 10;  // Number of neurons in the dense layer

    // Initializing arrays for weights and biases
    fixed_type weights1[H1][W1][D1][M1], weights2[H2][W2][D2][M2];
    fixed_type biases1[M1], biases2[M2];
    fixed_type weights_dense[1600][10], biases_dense[10];  // Dense layer weights and biases

    // Loading weights and biases for the convolutional layers
    load_weights("conv2d_2_weights.txt", &weights1[0][0][0][0], H1, W1, D1, M1);
    load_biases("conv2d_2_biases.txt", biases1, M1);
    load_weights("conv2d_3_weights.txt", &weights2[0][0][0][0], H2, W2, D2, M2);
    load_biases("conv2d_3_biases.txt", biases2, M2);
    // Loading weights and biases for the dense layer
    load_weights("dense_1_weights.txt", &weights_dense[0][0], 1600, 10, 1, 1);
    load_biases("dense_1_biases.txt", biases_dense, 10);

    // Initialize the input array
    fixed_type input[28][28][1];

    // Load image from file
    std::ifstream imageFile("mnist_image.txt");
    if (!imageFile.is_open()) {
        std::cerr << "Error opening file mnist_image.txt" << std::endl;
        return -1;
    }
    for (int i = 0; i < 28; ++i) {
        for (int j = 0; j < 28; ++j) {
            imageFile >> input[i][j][0];
        }
    }
    imageFile.close();

    // Process the neural network layers
    fixed_type conv_output1[26][26][32];
    conv_layer(input, conv_output1, weights1, biases1);
    fixed_type pool_output1[13][13][32];
    max_pooling_layer(conv_output1, pool_output1);

    fixed_type conv_output2[11][11][64];
    conv_layer_2(pool_output1, conv_output2, weights2, biases2);
    fixed_type pool_output2[5][5][64];
    max_pooling_layer_2(conv_output2, pool_output2);

    fixed_type flattened_output[1600];
    flatten_layer(pool_output2, flattened_output);

    fixed_type dense_output[10];
    dense_layer(flattened_output, dense_output, weights_dense, biases_dense, 1600, 10);

    std::cout << "Dense layer output:" << std::endl;
    for (int i = 0; i < 10; ++i) {
        std::cout << "Dense Output[" << i << "]: " << dense_output[i] << std::endl;
    }

    int max_index = std::distance(dense_output, std::max_element(dense_output, dense_output + 10));
    std::cout << "Guess: " << max_index << std::endl;

    return 0;
}
