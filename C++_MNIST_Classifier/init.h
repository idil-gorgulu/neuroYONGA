#ifndef INIT_H
#define INIT_H

#include <string>

typedef float fixed_type;

void load_weights(const std::string& file_name, fixed_type* data, int H, int W, int D, int M);
void load_biases(const std::string& file_name, fixed_type* data, int expected_count);

#endif // INIT_H
