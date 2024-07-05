#ifndef DENSE_H
#define DENSE_H

#include "init.h" 
fixed_type sigmoid(fixed_type x);
void dense_layer(const fixed_type input[], fixed_type output[], const fixed_type weights[][10], const fixed_type biases[], int input_size, int output_size) ;
#endif 


