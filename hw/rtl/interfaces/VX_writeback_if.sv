`include "VX_define.vh"

interface VX_writeback_if ();

    wire                            valid;
    wire [`UP(`UUID_BITS)-1:0]      uuid;
    wire [`NUM_THREADS-1:0]         tmask;
    wire [`UP(`NW_BITS)-1:0]        wid; 
    wire [`XLEN-1:0]                PC;
    wire [`NR_BITS-1:0]             rd;
    wire [`NUM_THREADS-1:0][`XLEN-1:0]   data;
    wire                            eop;

    modport master (
        output valid,
        output uuid,
        output tmask,
        output wid,
        output PC,
        output rd,
        output data,
        output eop
    );

    modport slave (
        input  valid,
        input  uuid,
        input  tmask,
        input  wid,
        input  PC,
        input  rd,
        input  data,
        input  eop
    );

endinterface
