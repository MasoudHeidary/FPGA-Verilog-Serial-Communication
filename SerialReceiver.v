`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: MasoudHeidaryDeveloper@gmail.com
// 
// Create Date:    00:47:11 06/16/2021 
// Design Name: 
// Module Name:    SerialReceiver 
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
module SerialReceiver(
    output [7:0] DataOutput,
    output NoData,
    input Read,
    input SerialLine,
    input clk
);

    wire data_fetched_by_controller;
    wire data_available;
    wire [8:0] data_receive_control;

    wire [7:0] data_controller_fifo;
    wire write_to_fifo;

    Receiver SR
    (
        SerialLine,
        data_fetched_by_controller,
        data_available,
        data_receive_control,
        clk
    );

    ReceiveController RC
    (
        data_available,
        data_controller_fifo,
        write_to_fifo,
        data_fetched_by_controller,
        data_receive_control,
        clk
    );

    FIFO RF
    (
        .DataI(data_controller_fifo),
        .DataO(DataOutput),
        .EF(NoData),
        .R(Read),
        .W(write_to_fifo),
        .clk(clk)
    );
    
endmodule

module ReceiverFIFO
#(
    parameter Depth = 9,
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



module ReceiveController
#(
    parameter Parity = 1,           // use parity ?
    parameter ParityEven = 1,       // if use parity,do use even parity?
    parameter DataLen = 8
)
(
    input  DataAvilable,
    output reg [DataLen - 1 : 0] DataOutput,
    output reg WriteData = 0,
    output reg  DataFetched = 0,
    input [DataLen + Parity -1:0] DataInput,
    input clk
);

    parameter pre_fetch_data = 0;
    parameter fetch_data = 1;
    parameter save_data = 2;
    parameter cancel_data = 3;
    reg [1:0] mode = pre_fetch_data;

    always @(posedge clk)
    begin
        if(mode == pre_fetch_data)
        begin
            if(DataAvilable)
            begin
                mode <= fetch_data;
                DataFetched <= 1;
            end
        end

        else if(mode == fetch_data)
        begin
            if(!Parity)
            begin
                DataOutput <= DataInput;
                WriteData <= 1;
                mode <= save_data;
            end
            else if(ParityEven)
            begin
                if(^DataInput == 0)
                begin
                    DataOutput <= DataInput[DataLen-2:0];
                    WriteData <= 1;
                end
                mode <= save_data;
            end
            else
            begin
                if(^DataInput == 1)
                begin
                    DataOutput <= DataInput[DataLen-2:0];
                    WriteData <= 1;
                end
                mode <= save_data;
            end
        end

        else if(mode == save_data)
        begin
            WriteData <= 0;
            DataFetched <= 0;
            mode <= pre_fetch_data;
        end
    end



endmodule


module Receiver
#(
    parameter ClkDivider = 5,
    parameter DataLen = 9,
    parameter StartBit = 1,
    parameter StopBit = 1
)
(
    input SerialLine,
    input DataFetched,
    output reg DataAvilable = 0,
    output reg [DataLen-1:0] Data = {0},
    input clk
);

    //data
    reg [DataLen-1:0] _data_temp = {0};
    reg [$clog2(DataLen)-1:0] _save_pointer = 0;
    reg [$clog2(StartBit + DataLen + StopBit) - 1:0] _receive_pointer = 0;

    //mode
    parameter receive_edge = 0;
    parameter receive_value = 1;
    parameter save = 2;
    parameter delay = 3;
    parameter save_wait = 4;
    reg [2:0] mode = receive_edge;

    //clk counter
    reg [$clog2(ClkDivider)-1:0] clk_divider = ClkDivider - 1;
    
    always @(posedge clk)
    begin

        if(mode == receive_edge)
        begin
            clk_divider = clk_divider + 1;
            if(clk_divider == ClkDivider)
            begin
                clk_divider = 0;

                _receive_pointer <= _receive_pointer + 1;
                if(_receive_pointer < StartBit)
                begin
                    if(SerialLine != 0)
                    begin
                        _receive_pointer <= 0;
                        clk_divider = ClkDivider - 1;
                    end
                end
                else if(_receive_pointer < StartBit + DataLen)
                begin
                    // mode <= receive_value;
                    _data_temp[_save_pointer] <= SerialLine;
                    _save_pointer <= _save_pointer + 1;
                end
                else if(_receive_pointer < StartBit + DataLen + StopBit)
                begin
                    //none
                    clk_divider = ClkDivider - 1;
                end
                else
                begin
                    _receive_pointer <= 0;
                    DataAvilable <= 1;
                    mode <= save;
                end
            end
        end

        // else if(mode == receive_value)
        // begin
        //     _save_pointer <= _save_pointer + 1;
        //     _data_temp[_save_pointer] <= SerialLine;
        //     mode <= receive_edge;
        // end

        // else if(mode == delay)
        // begin
        //     mode <= receive_edge;
        // end

        else if(mode == save)
        begin
            // DataAvilable <= 1;
            Data <= _data_temp;
            mode <= save_wait;
        end

        else if(mode == save_wait)
        begin
            if(DataFetched)
            begin
                DataAvilable <= 0;
                _save_pointer <= 0;
                mode <= receive_edge;
            end
        end
    end
endmodule