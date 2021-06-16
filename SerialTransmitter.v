`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: MasoudHeidaryDeveloper@gmail.com
// 
// Create Date:    20:58:45 06/15/2021 
// Design Name: 
// Module Name:    SerialTransmitter 
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
module SerialTransmitter
(
    input [7:0] DataInput,
    input Write,
    output SerialLine,
    input clk
);

    wire [7:0] data_fifo_control;
    wire no_data_fifo_control;
    wire read_data_fifo_control;

    wire data_available_control_trans;
    wire [8:0] data_control_trans;
    wire data_fetched_by_transmitter;

    FIFO u1(
        .DataI(DataInput),
        .DataO(data_fifo_control),
        .FF(),
        .EF(no_data_fifo_control),
        .R(read_data_fifo_control),
        .W(Write),
        .clk(clk)
    );

    Controller u2(
        data_available_control_trans,
        data_control_trans,
        read_data_fifo_control,
        data_fetched_by_transmitter,
        data_fifo_control,
        no_data_fifo_control,
        clk
    );

    Transmitter u3(
        SerialLine,
        data_fetched_by_transmitter,
        data_available_control_trans,
        data_control_trans,
        clk
    );
endmodule

module FIFO
#(
    parameter Depth = 8,
    parameter Width = 8
)
(
    input [Width-1 : 0] DataI,
    output reg [Width-1 : 0] DataO,
    output reg FF,  //full flag
    output reg EF,  //empty falg
    input R,    //read
    input W,    //write
    input clk
);

//pointers
    reg [$clog2(Depth)-1 : 0] _write_pointer = 0;
    reg [$clog2(Depth)-1 : 0] _read_pointer = 0;

//memory
    reg [Width-1 : 0] _memory[Depth-1: 0];

    always @(posedge clk)
    begin
        EF = 0;
        FF = 0;
        // ----------------------------------------------- read from FIFO
        if (R)
        begin
            if(_read_pointer != _write_pointer)
            begin
                DataO <= _memory[_read_pointer];
                _read_pointer <= _read_pointer + 1;
                if (_read_pointer == Depth)
                    _read_pointer <= 0;
            end
            else
            begin
                EF = 1;    
            end
        end
        // END----------------------------------------------- read from FIFO
        // ----------------------------------------------- write to FIFO
        if (W) 
        begin
            if(_write_pointer != Depth-1)
            begin
                if(_write_pointer+1 == _read_pointer)
                    FF = 1;
            end
            else if (_read_pointer == 0)
            begin
                FF = 1;
            end

            // if no error occur write data 
            if (!FF)
            begin
                _memory[_write_pointer] <= DataI;
                _write_pointer <= _write_pointer + 1;
                if (_write_pointer == Depth)
                begin
                    _write_pointer <= 0;
                end
            end
        end
        // END----------------------------------------------- write to FIFO
    end
endmodule


module Controller
#(
    parameter Parity = 1,           // use parity ?
    parameter ParityEven = 1,       // if use parity,do use even parity?
    parameter DataInputLen = 8
)
(
    output reg DataAvilable,
    output reg [DataInputLen + Parity -1 : 0] DataOutput,
    output reg ReadData,
    input DataFetchedByTransmitter,
    input [DataInputLen-1:0] DataInput,
    input NoData,
    input clk
);

    parameter read_data = 0;
    parameter read_data_wait = 1;
    parameter fetch_data = 2;
    parameter send_data = 3;
    // parameter data_been_sent = 4;
    reg [2:0] mode = read_data;

    always @(posedge clk)
    begin
        // -> want read data
        if(mode == read_data)
        begin
            ReadData <= 1;
            mode <= read_data_wait;
        end

        // -> wait to read data
        else if(mode == read_data_wait)
        begin
            mode <= fetch_data;
        end

        // -> data data(if available)
        else if(mode == fetch_data)
        begin
            if(NoData)
            begin
                //none
            end
            else 
            begin
                mode <= send_data;
                ReadData <= 0;
                if(!Parity)
                    DataOutput <= DataInput;
                else if(ParityEven)
                    DataOutput <= {^DataInput, DataInput};
                else
                    DataOutput <= {!(^DataInput), DataInput};
                DataAvilable <= 1;
            end
        end

        // -> wait to send data
        else if(mode == send_data)
        begin
            if(DataFetchedByTransmitter)
            begin
                mode <= read_data;
                DataAvilable <= 0;
            end
        end
    end

endmodule


module Transmitter
#(
    parameter ClkDivider = 5,
    parameter DataLen = 9,
    parameter StartBit = 1,
    parameter StopBit = 1
)
(
    output reg SerialLine = 1,
    output reg DataFetched = 0,
    input DataAvilable,
    input [DataLen-1:0] Data,
    input clk
);

    //data
    reg [DataLen-1:0] _data_temp = {0};
    reg [$clog2(StartBit + DataLen + StopBit) - 1:0] _sender_pointer = 0;

    //mode
    parameter fetch = 0;
    parameter ack_fetch = 1;
    parameter send = 2;
    reg [1:0] mode = fetch;

    //clk counter(for divider)
    reg [$clog2(ClkDivider)-1:0] clk_divider = ClkDivider - 1;

    always @(posedge clk)
    begin

        // first -> check have data avialable
        if((mode == fetch) & DataAvilable)
        begin
            mode <= ack_fetch;
            _data_temp <= Data;
            DataFetched <= 1;
        end
        else if(mode == ack_fetch)
        begin
            //none
            mode <= send;
        end
        else if(mode == send)
        begin
            DataFetched <= 0;
            
            //clk divider
            clk_divider = clk_divider + 1;
            if(clk_divider == ClkDivider)
            begin
                clk_divider = 0;

                _sender_pointer <= _sender_pointer + 1;
                //send data
                if(_sender_pointer < StartBit)
                    SerialLine <= 0;
                else if (_sender_pointer < StartBit + DataLen)
                    SerialLine <= _data_temp[_sender_pointer - StartBit];
                else if (_sender_pointer < StartBit + DataLen + StopBit)
                    SerialLine <= 1;
                else
                begin
                    mode <= fetch;
                    clk_divider = ClkDivider - 1;
                    _sender_pointer <= 0;
                end
                // END send data
            end
        end

    end

endmodule