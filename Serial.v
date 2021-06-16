`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:50:27 06/16/2021 
// Design Name: 
// Module Name:    Serial 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module test_Serial();

    reg [7:0] data;
    reg write = 0;
    wire serial_line;

    wire [7:0] data_output;
    wire no_data;
    reg read = 1;

    reg clk = 0;
    always #5 clk = !clk;

    SerialTransmitter s_t(
        data,
        write,
        serial_line,
        clk
    );

    SerialReceiver s_r(
        data_output,
        no_data,
        read,
        serial_line,
        clk
    );

    always #10
    begin
        if(!no_data)
            $display("output: %s", data_output);
    end

    initial begin
        #5;

        data <= "h";
        write <= 1;
        #20;

        data <= "e";
        #20;

        data <= "l";
        #20;
        #20

        data <= "o";
        #20;

        data <= " ";
        #20;

        write <= 0;
        #10010;

        write <= 1;
        data <= "w";
        #20;

        data <= "o";
        #20;

        data <= "r";
        #20;

        data <= "l";
        #20;

        data <= "d";
        #20;

        write <= 0;
    end

endmodule