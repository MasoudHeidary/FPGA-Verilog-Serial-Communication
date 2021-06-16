`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:47:37 06/16/2021 
// Design Name: 
// Module Name:    test_SerialReceiver 
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

module test_Receiver ();
    reg serial_line = 1;
    reg data_fetched = 0;
    wire data_available;
    wire data;

    reg clk = 0;
    always #5 clk = !clk;

    Receiver ut(
        serial_line,
        data_fetched,
        data_available,
        data,
        clk
    );

    initial
    begin

        serial_line <= 0;
        #50;
        serial_line <= 1;
        #200;
        serial_line <= 0;
        #200;
        
        serial_line <= 1;
        #10;
    end
endmodule