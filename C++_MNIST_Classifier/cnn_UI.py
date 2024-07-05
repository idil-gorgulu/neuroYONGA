"""FOR C++ INPUT """

import tkinter as tk
from tkinter import Button, Canvas
from PIL import Image, ImageDraw
import numpy as np

def submit():
    block_size = 20
    new_size = 28
    global pixel_data
    pixel_data = np.zeros((new_size, new_size), dtype=np.float32)

    # Convert the image to grayscale and invert colors
    pixels = np.array(pil_image.convert("L"), dtype=np.float32)
    pixels = 255 - pixels  # Invert the pixel values

    for i in range(new_size):
        for j in range(new_size):
            x_start = j * block_size
            y_start = i * block_size
            block = pixels[y_start:y_start + block_size, x_start:x_start + block_size]
            pixel_data[i, j] = np.mean(block)

    normalized_data = pixel_data / 255.0

    # Write to file
    with open('mnist_image.txt', 'w') as file:
        for row in normalized_data:
            file.write(' '.join(f"{int(val*255):3}" for val in row) + '\n')

    # Optional: Display the resized image for verification
    new_image = Image.fromarray(np.uint8(normalized_data * 255), 'L')
    new_image.show()

def clear():
    # Clear the canvas and reset the PIL image to white
    canvas.delete("all")
    global pil_image, draw, pixel_data
    pil_image = Image.new("RGB", (560, 560), "white")
    draw = ImageDraw.Draw(pil_image)
    pixel_data.fill(0)  # Reset the pixel data array to zero

# Main application window
root = tk.Tk()
root.title("MNIST Digit Classifier")

# Create a white PIL image for drawing
pil_image = Image.new("RGB", (560, 560), "white")
draw = ImageDraw.Draw(pil_image)

# Initialize the pixel data array
pixel_data = np.zeros((28, 28), dtype=np.float32)

# Create a canvas with a white background and bind drawing function
canvas = Canvas(root, width=560, height=560, bg="white")
canvas.pack()
canvas.bind("<B1-Motion>", lambda event: draw_on_canvas(event))

def draw_on_canvas(event):
    x1, y1 = (event.x - 10), (event.y - 10)
    x2, y2 = (event.x + 10), (event.y + 10)
    canvas.create_oval(x1, y1, x2, y2, fill="black", width=0)
    draw.ellipse([x1, y1, x2, y2], fill="black")


# Buttons for submitting and clearing the drawing
submit_button = Button(root, text="Submit", command=submit)
submit_button.pack(side=tk.LEFT)
clear_button = Button(root, text="Clear", command=clear)
clear_button.pack(side=tk.LEFT)

# Start the Tkinter event loop
root.mainloop()

""" FOR THE VHDL INPUT
import tkinter as tk
from tkinter import Button, Canvas
from PIL import Image, ImageDraw
import numpy as np

def float_to_q15_binary(value):
    # Step 1: Multiply by scaling factor
    scaled_value = int(round(value * 32768))
    # Step 2: Clamp the value to the range of a 16-bit signed integer
    if scaled_value < -32768:
        scaled_value = -32768
    elif scaled_value > 32767:
        scaled_value = 32767
    # Step 3: Convert to binary (two's complement for negative values)
    if scaled_value < 0:
        scaled_value = (1 << 16) + scaled_value  # Compute two's complement
    binary_value = format(scaled_value & 0xFFFF, '016b')  # Ensure it's 16-bit binary
    return binary_value

def submit():
    block_size = 20
    new_size = 28
    global pixel_data
    pixel_data = np.zeros((new_size, new_size), dtype=np.float32)

    # Convert the image to grayscale and invert colors
    pixels = np.array(pil_image.convert("L"), dtype=np.float32)
    pixels = 255 - pixels  # Invert the pixel values

    for i in range(new_size):
        for j in range(new_size):
            x_start = j * block_size
            y_start = i * block_size
            block = pixels[y_start:y_start + block_size, x_start:x_start + block_size]
            pixel_data[i, j] = np.mean(block)

    normalized_data = pixel_data / 255.0

    # Serialize the input, convert to Q0.15 binary, and write to a file
    binary_strings = []
    for row in normalized_data:
        for val in row:
            binary_value = float_to_q15_binary(val)
            reversed_binary_value = binary_value[::-1]  # Reverse the binary string
            binary_strings.append(reversed_binary_value)
    
    binary_string = ''.join(binary_strings)
    
    with open('manipulated_input.txt', 'w') as file:
        file.write(binary_string)

    # Optional: Display the resized image for verification
    new_image = Image.fromarray(np.uint8(normalized_data * 255), 'L')
    new_image.show()

def clear():
    # Clear the canvas and reset the PIL image to white
    canvas.delete("all")
    global pil_image, draw, pixel_data
    pil_image = Image.new("RGB", (560, 560), "white")
    draw = ImageDraw.Draw(pil_image)
    pixel_data.fill(0)  # Reset the pixel data array to zero

# Main application window
root = tk.Tk()
root.title("MNIST Digit Classifier")

# Create a white PIL image for drawing
pil_image = Image.new("RGB", (560, 560), "white")
draw = ImageDraw.Draw(pil_image)

# Initialize the pixel data array
pixel_data = np.zeros((28, 28), dtype=np.float32)

# Create a canvas with a white background and bind drawing function
canvas = Canvas(root, width=560, height=560, bg="white")
canvas.pack()
canvas.bind("<B1-Motion>", lambda event: draw_on_canvas(event))

def draw_on_canvas(event):
    x1, y1 = (event.x - 10), (event.y - 10)
    x2, y2 = (event.x + 10), (event.y + 10)
    canvas.create_oval(x1, y1, x2, y2, fill="black", width=0)
    draw.ellipse([x1, y1, x2, y2], fill="black")

# Buttons for submitting and clearing the drawing
submit_button = Button(root, text="Submit", command=submit)
submit_button.pack(side=tk.LEFT)
clear_button = Button(root, text="Clear", command=clear)
clear_button.pack(side=tk.LEFT)

# Start the Tkinter event loop
root.mainloop()
"""