`include "VX_fpu_define.vh"

module VX_fpu_arb #(    
    parameter NUM_INPUTS     = 1,
    parameter NUM_OUTPUTS    = 1,
    parameter NUM_LANES      = 1,
    parameter TAG_WIDTH      = 1,
    parameter TAG_SEL_IDX    = 0,
    parameter BUFFERED_REQ   = 0,
    parameter BUFFERED_RSP   = 0,
    parameter `STRING ARBITER = "R"
) (
    input wire              clk,
    input wire              reset,

    VX_fpu_bus_if.slave     bus_in_if [NUM_INPUTS],
    VX_fpu_bus_if.master    bus_out_if [NUM_OUTPUTS]
);   
    
    localparam LOG_NUM_REQS  = `ARB_SEL_BITS(NUM_INPUTS, NUM_OUTPUTS);
    localparam NUM_REQS      = 1 << LOG_NUM_REQS;
    localparam TAG_OUT_WIDTH = TAG_WIDTH + LOG_NUM_REQS;
    localparam REQ_DATAW     = TAG_OUT_WIDTH + `INST_FPU_BITS + `INST_FMT_BITS + `INST_FRM_BITS + NUM_LANES * 3 * `XLEN;
    localparam RSP_DATAW     = TAG_WIDTH + NUM_LANES * (`XLEN + `FP_FLAGS_BITS) + 1;
    
    ///////////////////////////////////////////////////////////////////////

    wire [NUM_INPUTS-1:0]                 req_valid_in;
    wire [NUM_INPUTS-1:0][REQ_DATAW-1:0]  req_data_in;
    wire [NUM_INPUTS-1:0]                 req_ready_in;

    wire [NUM_OUTPUTS-1:0]                req_valid_out;
    wire [NUM_OUTPUTS-1:0][REQ_DATAW-1:0] req_data_out;
    wire [NUM_OUTPUTS-1:0]                req_ready_out;

    for (genvar i = 0; i < NUM_INPUTS; ++i) begin
        
        assign req_valid_in[i] = bus_in_if[i].req_valid;        
        assign bus_in_if[i].req_ready = req_ready_in[i];

        if (NUM_INPUTS > NUM_OUTPUTS) begin
            wire [TAG_OUT_WIDTH-1:0] req_tag_in;
            localparam r = i % NUM_REQS;
            VX_bits_insert #( 
                .N   (TAG_WIDTH),
                .S   (LOG_NUM_REQS),
                .POS (TAG_SEL_IDX)
            ) bits_insert (
                .data_in  (bus_in_if[i].req_tag),
                .sel_in   (LOG_NUM_REQS'(r)),
                .data_out (req_tag_in)
            );
            assign req_data_in[i] = {req_tag_in, bus_in_if[i].req_type, bus_in_if[i].req_fmt, bus_in_if[i].req_frm, bus_in_if[i].req_dataa, bus_in_if[i].req_datab, bus_in_if[i].req_datac};
        end else begin
            assign req_data_in[i] = {bus_in_if[i].req_tag, bus_in_if[i].req_type, bus_in_if[i].req_fmt, bus_in_if[i].req_frm, bus_in_if[i].req_dataa, bus_in_if[i].req_datab, bus_in_if[i].req_datac};
        end
    end

    VX_stream_arb #(            
        .NUM_INPUTS  (NUM_INPUTS),
        .NUM_OUTPUTS (NUM_OUTPUTS),
        .DATAW       (REQ_DATAW),        
        .ARBITER     (ARBITER),
        .BUFFERED    (BUFFERED_REQ),
        .MAX_FANOUT  (4)
    ) req_arb (
        .clk       (clk),
        .reset     (reset),
        .valid_in  (req_valid_in),        
        .ready_in  (req_ready_in),
        .data_in   (req_data_in),      
        .data_out  (req_data_out),
        .valid_out (req_valid_out),
        .ready_out (req_ready_out)
    );
    
    for (genvar i = 0; i < NUM_OUTPUTS; ++i) begin
        assign bus_out_if[i].req_valid = req_valid_out[i];
        assign {bus_out_if[i].req_tag, bus_out_if[i].req_type, bus_out_if[i].req_fmt, bus_out_if[i].req_frm, bus_out_if[i].req_dataa, bus_out_if[i].req_datab, bus_out_if[i].req_datac} = req_data_out[i];
        assign req_ready_out[i] = bus_out_if[i].req_ready;
    end

    ///////////////////////////////////////////////////////////////////////////

    wire [NUM_OUTPUTS-1:0]                rsp_valid_in;
    wire [NUM_OUTPUTS-1:0][RSP_DATAW-1:0] rsp_data_in;
    wire [NUM_OUTPUTS-1:0]                rsp_ready_in;

    wire [NUM_INPUTS-1:0]                 rsp_valid_out;
    wire [NUM_INPUTS-1:0][RSP_DATAW-1:0]  rsp_data_out;
    wire [NUM_INPUTS-1:0]                 rsp_ready_out;

    if (NUM_INPUTS > NUM_OUTPUTS) begin

        wire [NUM_OUTPUTS-1:0][LOG_NUM_REQS-1:0] rsp_sel_in;    

        for (genvar i = 0; i < NUM_OUTPUTS; ++i) begin
            wire [TAG_WIDTH-1:0] rsp_tag_out;

            VX_bits_remove #( 
                .N   (TAG_OUT_WIDTH),
                .S   (LOG_NUM_REQS),
                .POS (TAG_SEL_IDX)
            ) bits_remove (
                .data_in  (bus_out_if[i].rsp_tag),
                .data_out (rsp_tag_out)
            );

            assign rsp_valid_in[i] = bus_out_if[i].rsp_valid;
            assign rsp_data_in[i] = {rsp_tag_out, bus_out_if[i].rsp_result, bus_out_if[i].rsp_fflags, bus_out_if[i].rsp_has_fflags};
            assign bus_out_if[i].rsp_ready = rsp_ready_in[i];

            if (NUM_INPUTS > 1) begin
                assign rsp_sel_in[i] = bus_out_if[i].rsp_tag[TAG_SEL_IDX +: LOG_NUM_REQS];
            end else begin
                assign rsp_sel_in[i] = '0;
            end            
        end

        VX_stream_switch #(
            .NUM_INPUTS  (NUM_OUTPUTS),
            .NUM_OUTPUTS (NUM_INPUTS),        
            .DATAW       (RSP_DATAW),
            .BUFFERED    (BUFFERED_RSP),
            .MAX_FANOUT  (4)
        ) rsp_switch (
            .clk       (clk),
            .reset     (reset),
            .sel_in    (rsp_sel_in),
            .valid_in  (rsp_valid_in),            
            .ready_in  (rsp_ready_in),
            .data_in   (rsp_data_in),          
            .data_out  (rsp_data_out),
            .valid_out (rsp_valid_out),
            .ready_out (rsp_ready_out)
        );

    end else begin

        for (genvar i = 0; i < NUM_OUTPUTS; ++i) begin
            assign rsp_valid_in[i] = bus_out_if[i].rsp_valid;        
            assign rsp_data_in[i]  = {bus_out_if[i].rsp_tag, bus_out_if[i].rsp_result, bus_out_if[i].rsp_fflags, bus_out_if[i].rsp_has_fflags};
            assign bus_out_if[i].rsp_ready = rsp_ready_in[i];
        end

        VX_stream_arb #(            
            .NUM_INPUTS  (NUM_OUTPUTS),
            .NUM_OUTPUTS (NUM_INPUTS),
            .DATAW       (RSP_DATAW),            
            .ARBITER     (ARBITER),
            .BUFFERED    (BUFFERED_RSP),
            .MAX_FANOUT  (4)
        ) req_arb (
            .clk       (clk),
            .reset     (reset),
            .valid_in  (rsp_valid_in),            
            .ready_in  (rsp_ready_in),            
            .data_in   (rsp_data_in),
            .data_out  (rsp_data_out),
            .valid_out (rsp_valid_out),
            .ready_out (rsp_ready_out)
        );

    end
    
    for (genvar i = 0; i < NUM_INPUTS; ++i) begin
        assign bus_in_if[i].rsp_valid = rsp_valid_out[i];
        assign {bus_in_if[i].rsp_tag, bus_in_if[i].rsp_result, bus_in_if[i].rsp_fflags, bus_in_if[i].rsp_has_fflags} = rsp_data_out[i];        
        assign rsp_ready_out[i] = bus_in_if[i].rsp_ready;
    end

endmodule
