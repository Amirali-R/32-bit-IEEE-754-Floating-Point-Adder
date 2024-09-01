`timescale 1ns/1ns
module fp_adder(
    input [31:0] a,
    input [31:0] b,
    output [31:0] s
);

//-------declarations

wire S1;
wire S2;
wire [22:0] F1;
wire [22:0] F2;
wire [7:0] E1;
wire [7:0] E2;
wire [7:0] real_E1;                    // checks if the exponent is zero
wire [7:0] real_E2;                    // checks if the exponent is zero
wire Hidden1;
wire Hidden2;
wire [27:0] modified_F1;               // concatinating 2 zero bits to the end as Round and Gaurd bits, and two bits to the beginning as sign-extend
wire [27:0] modified_F2;               // concatinating 2 zero bits to the end as Round and Gaurd bits, and two bits to the beginning as sign-extend
wire [27:0] adder_input1;              // produced after comparing exponents
wire [27:0] adder_input2;              // produced after comparing exponents 
wire modified_S1;                      // produced after comparing exponents 
wire modified_S2;                      // produced after comparing exponents 
wire[27:0] Sticky_detection;           // stores the bits that have gotten out of number by shifting
wire Sticky;
wire [28:0] modified_adder_input1;     // produced after generating Sticky bit
wire [28:0] modified_adder_input2;     // produced after generating Sticky bit
wire [28:0] final_adder_input1;        // produced after taking two's complements (if necessary)
wire [28:0] final_adder_input2;        // produced after taking two's complements (if necessary)
wire [28:0] adder_output;
wire S_out;
wire [28:0] initial_F_out;             // produced after taking two's complements (if necessary)
wire [5:0] fixed_point;
wire [7:0] initial_E_out;              // after one shift to the right
wire [28:0] secondary_F_out;           // produced after shifting the number for the necessary amount
wire [7:0] secondary_E_out;            // produced after final shift and checking conditions
wire [24:0] tertiary_F_out;            // produced after rounding
wire [22:0] final_F_out;               // checking if the number has got denormalized again and correcting it
wire [7:0] final_E_out;                // checking if the number has got denormalized again and correcting it

//-------assignments

assign S1 = a[31];
assign S2 = b[31];
assign F1[22:0] = a[22:0]; 
assign F2[22:0] = b[22:0]; 
assign E1[7:0] = a[30:23];
assign E2[7:0] = b[30:23];
assign real_E1 = (E1==8'h00) ? 8'h01 : E1;
assign real_E2 = (E2==8'h00) ? 8'h01 : E2;
assign Hidden1 = (E1==8'h00) ? 1'b0 : 1'b1;
assign Hidden2 = (E2==8'h00) ? 1'b0 : 1'b1;
assign modified_F1[27:0] = {2'b00,Hidden1,F1[22:0],2'b00};
assign modified_F2[27:0] = {2'b00,Hidden2,F2[22:0],2'b00};
assign adder_input1 = (real_E1>=real_E2) ? modified_F1 : modified_F2;
assign adder_input2 = (real_E1>=real_E2) ? modified_F2 >> real_E1-real_E2 : modified_F1 >> real_E2-real_E1;
assign modified_S1 = (real_E1>=real_E2) ? S1 : S2;
assign modified_S2 = (real_E1>=real_E2) ? S2 : S1;
assign Sticky_detection = (real_E1>real_E2)&&(real_E1-real_E2<28)  ? modified_F2 << 28-(real_E1-real_E2) : 
                          (real_E1>real_E2)&&(real_E1-real_E2>=28) ? modified_F2 :
                          (real_E1<real_E2)&&(real_E2-real_E1<28)  ? modified_F1 << 28-(real_E2-real_E1) :
                          (real_E1<real_E2)&&(real_E2-real_E1>=28) ? modified_F1 : 1'b0;
assign Sticky = |Sticky_detection;
assign modified_adder_input1 = {adder_input1,1'b0};
assign modified_adder_input2 = {adder_input2,Sticky};
assign final_adder_input1 = modified_S1 ? ~modified_adder_input1 + 1'b1 : modified_adder_input1;
assign final_adder_input2 = modified_S2 ? ~modified_adder_input2 + 1'b1 : modified_adder_input2;
assign adder_output = final_adder_input1 + final_adder_input2;
assign S_out = adder_output[28] ? 1'b1 : 1'b0;
assign initial_F_out = S_out ? (~adder_output + 1'b1) >> 1 : adder_output >> 1;
assign initial_E_out = (real_E1>=real_E2) ? real_E1 + 1'b1 : real_E2 + 1'b1;
assign fixed_point = initial_F_out[26] ? 26 :
                     initial_F_out[25] ? 25 :
                     initial_F_out[24] ? 24 :
                     initial_F_out[23] ? 23 :
                     initial_F_out[22] ? 22 :
                     initial_F_out[21] ? 21 :
                     initial_F_out[20] ? 20 :
                     initial_F_out[19] ? 19 :
                     initial_F_out[18] ? 18 :
                     initial_F_out[17] ? 17 :
                     initial_F_out[16] ? 16 :
                     initial_F_out[15] ? 15 :
                     initial_F_out[14] ? 14 :
                     initial_F_out[13] ? 13 :
                     initial_F_out[12] ? 12 :
                     initial_F_out[11] ? 11 :
                     initial_F_out[10] ? 10 :
                     initial_F_out[ 9] ?  9 :
                     initial_F_out[ 8] ?  8 :
                     initial_F_out[ 7] ?  7 :
                     initial_F_out[ 6] ?  6 :
                     initial_F_out[ 5] ?  5 :
                     initial_F_out[ 4] ?  4 :
                     initial_F_out[ 3] ?  3 :
                     initial_F_out[ 2] ?  2 :
                     initial_F_out[ 1] ?  1 : 0;
assign secondary_E_out = (fixed_point == 1'b0) ? 0 :
                         (26-fixed_point<initial_E_out) ? initial_E_out-(26-fixed_point) : 0;
assign secondary_F_out = (26-fixed_point<initial_E_out) ? initial_F_out << 26-fixed_point : initial_F_out << initial_E_out - 1;
assign tertiary_F_out = (secondary_F_out[2] == 1'b0) ? secondary_F_out[27:3] :
                        (secondary_F_out[1] == 1'b1) ? secondary_F_out[27:3] + 1'b1 :
                        (secondary_F_out[0] == 1'b1) ? secondary_F_out[27:3] + 1'b1 : 
                        (Sticky == 1'b1) ? secondary_F_out[27:3] + 1'b1 : secondary_F_out[27:3] + secondary_F_out[3];
assign final_F_out = tertiary_F_out[24] ? tertiary_F_out[23:1] : tertiary_F_out[22:0]; 
assign final_E_out = tertiary_F_out[24] ? secondary_E_out + 1'b1 : secondary_E_out;
assign s = {S_out,final_E_out,final_F_out};

endmodule
