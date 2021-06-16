`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:46:09 06/15/2021 
// Design Name: 
// Module Name:    test_SerialTransmitter 
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

module test_serial_transmitter ();

    reg [7:0] data;
    reg write;
    wire serial_line;

    reg clk = 0;
    always #5 clk = !clk;

    SerialTransmitter ut(
        data,
        write,
        serial_line,
        clk
    );

    initial begin
        #5;

        data <= 10;
        write <= 1;
        #10;

        data <= 20;
        write <= 1;
        #10;

        data <= 30;
        write <= 1;
        #10;

        write <= 0;
        #20;
    end
endmodule

module test_FIFO();

    reg [7:0] data_input = {0};
    reg r = 0;
    reg w = 0;
    wire [7:0] data_out;
    wire ff;
    wire ee;

    reg clk = 0;
    always #5 clk = !clk;

    FIFO ut(
        data_input,
        data_out,
        ff,
        ee,
        r,
        w,
        clk
    );

    initial begin
        #5;

        data_input <= 8'hF0;
        w <= 1;
        #20;

        data_input <= 8'h0F;
        w <= 1;
        #20;

        w <= 0;
        r <= 1;
        #20;

        #20;
    end
endmodule


module test_Controller ();

    wire data_available;
    wire [8:0]data_output;
    wire read_data;

    reg data_fetched_by_transmitter = 0;
    reg [7:0]data_input = {0};
    reg no_data = 1;

    reg clk = 0;
    always #5 clk = !clk;

    Controller ut(
        data_available,
        data_output,
        read_data,
        data_fetched_by_transmitter,
        data_input,
        no_data,
        clk
    );

    initial
    begin
        #5;
        #20;

        data_input <= 8'hF0;
        no_data <= 0;
        #20;

        no_data <= 1;
        #20;

        #100;
        data_fetched_by_transmitter <= 1;
        #20;
        data_fetched_by_transmitter <= 0;
        #20;

        #100;
        data_input <= 8'h01;
        no_data <= 0;
        #20;
        no_data <= 1;
        #20;

        #100;
        data_fetched_by_transmitter <= 1;
        #20;
        data_fetched_by_transmitter <= 0;
        #20;
    end

endmodule

module test_Transmitter();
    reg [8:0] data = 9'b0;
    reg data_available = 0;
    
    reg clk = 0;
    always #5 clk = !clk;

    wire serial_line;
    wire data_fetched;

    Transmitter
    #(
       .DataLen(8)
    )
    ut
    (
        serial_line,
        data_fetched,
        data_available,
        data,
        clk
    );

    initial
    begin
        #5;

        data <= 8'b00_1100_11;
        data_available <= 1;
        #20;

        data_available <= 0;
        #500;
        #10;

        data <= 8'h0F;
        data_available <= 1;
        #20;

        data_available <= 0;
        #10;
    end
endmodule
