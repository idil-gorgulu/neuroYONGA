#include "init.h"
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>
#include <algorithm>

void load_weights(const std::string& file_name, fixed_type* data, int H, int W, int D, int M) {
    std::ifstream file(file_name);
    if (!file.is_open()) {
        std::cerr << "Could not open the file: " << file_name << std::endl;
        exit(EXIT_FAILURE);
    }

    std::string line;
    int index = 0;  // index to track the flat data array
    while (std::getline(file, line)) {
        // Remove brackets to simplify parsing
        line.erase(std::remove(line.begin(), line.end(), '['), line.end());
        line.erase(std::remove(line.begin(), line.end(), ']'), line.end());
        line.erase(std::remove(line.begin(), line.end(), ' '), line.end());

        std::istringstream stream(line);
        std::string number;

        while (std::getline(stream, number, ',')) {
            if (index < H * W * D * M) {  // Ensure we don't exceed the bounds of the data array
                std::istringstream numStream(number);
                fixed_type value;
                numStream >> value;
                data[index++] = value;
            }
        }
    }
    file.close();

    if (index != H * W * D * M) {
        std::cerr << "Error: Expected " << H * W * D * M << " weights, but only " << index << " were loaded." << std::endl;
        exit(EXIT_FAILURE);
    }
}


void load_biases(const std::string& file_name, fixed_type* data, int expected_count) {
    std::ifstream file(file_name);
    if (!file.is_open()) {
        std::cerr << "Could not open the file: " << file_name << std::endl;
        exit(EXIT_FAILURE);
    }

    int index = 0;
    std::string line;
    while (std::getline(file, line) && index < expected_count) {
        std::istringstream iss(line);
        fixed_type value;
        while (iss >> value) {
            data[index++] = value;
        }
    }
    file.close();
}
