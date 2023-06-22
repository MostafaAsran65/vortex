`include "VX_define.vh"

interface VX_fpu_exe_if ();

    wire                            valid;
    wire [`UP(`UUID_BITS)-1:0]      uuid;
    wire [`UP(`NW_BITS)-1:0]        wid;
    wire [`NUM_THREADS-1:0]         tmask;
    wire [`XLEN-1:0]                PC;
    wire [`INST_FPU_BITS-1:0]       op_type;
    wire [`INST_FMT_BITS-1:0]       fmt;
    wire [`INST_FRM_BITS-1:0]       frm;
    wire [`NUM_THREADS-1:0][`XLEN-1:0] rs1_data;
    wire [`NUM_THREADS-1:0][`XLEN-1:0] rs2_data;
    wire [`NUM_THREADS-1:0][`XLEN-1:0] rs3_data;
    wire [`NR_BITS-1:0]             rd;   
    wire                            ready;

    modport master (
        output valid,
        output uuid,
        output wid,
        output tmask,
        output PC,
        output op_type,
        output fmt,
        output frm,
        output rs1_data,
        output rs2_data,
        output rs3_data,
        output rd,
        input  ready
    );

    modport slave (
        input  valid,
        input  uuid,
        input  wid,
        input  tmask,
        input  PC,
        input  op_type,
        input  fmt,
        input  frm,
        input  rs1_data,
        input  rs2_data,
        input  rs3_data,
        input  rd,
        output ready
    );

endinterface
