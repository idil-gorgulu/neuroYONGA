#include <cmath>
#include "dense.h"  


// Sigmoid activation function
typedef float fixed_type;  // You can change this to double or another type depending on your requirements

// Sigmoid activation function
fixed_type sigmoid(fixed_type x) {
    return 1.0 / (1.0 + exp(-x));
}

// Function to perform the dense layer operation with sigmoid activation
void dense_layer(const fixed_type input[], fixed_type output[], const fixed_type weights[][10], const fixed_type biases[], int input_size, int output_size) {
    for (int i = 0; i < output_size; ++i) {
        output[i] = biases[i];
        for (int j = 0; j < input_size; ++j) {
            output[i] += input[j] * weights[j][i];
        }
        // Apply sigmoid activation
        output[i] = sigmoid(output[i]);
    }
}

