# 32-bit-IEEE-754-Floating-Point-Adder
A 32-bit floating point adder in IEEE-754 format implemented by verilog using only continuous assignment, resulting in a combinational circuit.

3 test bench files are also included for verification. The .hex file is needed for using the first test bench.

NOTE: In order to keep things simple and to focus on mathematical proccess (adding and subtracting), inputs and outputs in form of NaN or infinity are excluded. It means that the exponent part of them is never equal to 255.
