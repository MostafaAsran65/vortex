// Copyright © 2019-2023
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

`include "VX_define.vh"

module VX_tcu_bhf_fmul #(
    parameter IN_EXPW  = 8,
    parameter IN_SIGW  = 24,    // Includes implicit bit
    parameter OUT_EXPW = 8,
    parameter OUT_SIGW = 24,    // Includes implicit bit
    parameter MUL_LATENCY = 1,
    parameter RND_LATENCY = 1,
    parameter IN_REC   = 0,     // 0: IEEE754, 1: recoded
    parameter OUT_REC  = 0,     // 0: IEEE754, 1: recoded
    parameter IN_RECW  = IN_EXPW + IN_SIGW + 1,
    parameter OUT_RECW = OUT_EXPW + OUT_SIGW + 1
) (
    input  wire             clk,
    input  wire             reset,
    input  wire             enable,
    input  wire [2:0]       frm,
    input  wire [IN_RECW-1:0] a,
    input  wire [IN_RECW-1:0] b,
    output logic [OUT_RECW-1:0] y,
    output logic [4:0]      fflags
);
    // Control signals
    wire control = `flControl_tininessAfterRounding; /// IEEE 754-2008

    wire [IN_RECW-1:0] a_rec, b_rec;
    wire s1_invalidExc, s1_isNaN, s1_isInf, s1_isZero, s1_sign;
    wire s2_invalidExc, s2_isNaN, s2_isInf, s2_isZero, s2_sign;
    wire signed [(IN_EXPW+2)-1:0] s1_sExp, s2_sExp;
    wire [(IN_SIGW*2)-1:0] s1_sig, s2_sig;
    wire [2:0] s2_frm;
    wire [OUT_RECW-1:0] s2_y_rec, s2_y;
    wire [4:0] s2_fflags;

    // Conversion to recoded format

    if (IN_REC) begin : g_in_rec
        assign a_rec = a;
        assign b_rec = b;
    end else begin : g_in_ieee
        fNToRecFN #(
            .expWidth (IN_EXPW),
            .sigWidth (IN_SIGW)
        ) from_ieee_a (
            .in  (a[IN_RECW-2:0]),
            .out (a_rec)
        );

        fNToRecFN #(
            .expWidth (IN_EXPW),
            .sigWidth (IN_SIGW)
        ) from_ieee_b (
            .in  (b[IN_RECW-2:0]),
            .out (b_rec)
        );
        `UNUSED_VAR ({a[IN_RECW-1], b[IN_RECW-1]});
    end

    // Raw multiplication

    mulRecFNToFullRaw #(
        .expWidth (IN_EXPW),
        .sigWidth (IN_SIGW)
    ) multiplier (
        .control   (control),
        .a         (a_rec),
        .b         (b_rec),
        .invalidExc(s1_invalidExc),
        .out_isNaN (s1_isNaN),
        .out_isInf (s1_isInf),
        .out_isZero(s1_isZero),
        .out_sign  (s1_sign),
        .out_sExp  (s1_sExp),
        .out_sig   (s1_sig)
    );

    VX_pipe_register #(
        .DATAW (5 + (IN_EXPW+2) + (IN_SIGW*2) + 3),
        .DEPTH (MUL_LATENCY)
    ) pipe_add (
        .clk     (clk),
        .reset   (reset),
        .enable  (enable),
        .data_in ({s1_invalidExc, s1_isNaN, s1_isInf, s1_isZero, s1_sign, s1_sExp, s1_sig, frm}),
        .data_out({s2_invalidExc, s2_isNaN, s2_isInf, s2_isZero, s2_sign, s2_sExp, s2_sig, s2_frm})
    );

    // Rounding

    roundAnyRawFNToRecFN #(
        .inExpWidth  (IN_EXPW),
        .inSigWidth  (IN_SIGW*2-1),
        .outExpWidth (OUT_EXPW),
        .outSigWidth (OUT_SIGW)
    ) rounding (
        .control       (control),
        .invalidExc    (s2_invalidExc),
        .infiniteExc   (1'b0),
        .in_isNaN      (s2_isNaN),
        .in_isInf      (s2_isInf),
        .in_isZero     (s2_isZero),
        .in_sign       (s2_sign),
        .in_sExp       (s2_sExp),
        .in_sig        (s2_sig),
        .roundingMode  (s2_frm),
        .out           (s2_y_rec),
        .exceptionFlags(s2_fflags)
    );

    // Conversion from recoded format

    if (OUT_REC) begin : g_out_rec
        assign s2_y = s2_y_rec;

        wire [OUT_RECW-2:0] tmp;
        recFNToFN #(
            .expWidth (OUT_EXPW),
            .sigWidth (OUT_SIGW)
        ) to_ieee (
            .in  (s2_y_rec),
            .out (tmp)
        );
        `UNUSED_VAR(tmp);
    end else begin : g_out_ieee
        recFNToFN #(
            .expWidth (OUT_EXPW),
            .sigWidth (OUT_SIGW)
        ) to_ieee (
            .in  (s2_y_rec),
            .out (s2_y[OUT_RECW-2:0])
        );
        assign s2_y[OUT_RECW-1] = 1'b0;
    end

    VX_pipe_register #(
        .DATAW (OUT_RECW + 5),
        .DEPTH (RND_LATENCY)
    ) pipe_rnd (
        .clk     (clk),
        .reset   (reset),
        .enable  (enable),
        .data_in ({s2_y, s2_fflags}),
        .data_out({y,    fflags})
    );

endmodule
