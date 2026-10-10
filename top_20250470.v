// top_20250470.v
// Modulo superior para simulacion. Conecta las tres instancias por nombre.
module top_20250470 (
    input  wire       a,
    input  wire       b,
    input  wire       c,
    input  wire       d,
    input  wire [3:0] A,
    input  wire [3:0] B,
    input  wire       clk,
    input  wire       rst,
    input  wire       en,
    output wire       u,
    output wire       v,
    output wire [3:0] Y,
    output wire       flag_comb,
    output wire [3:0] Q,
    output wire       flag_q
);

    control_logic u_control (
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .u(u),
        .v(v)
    );

    datapath u_datapath (
        .A(A),
        .B(B),
        .u(u),
        .v(v),
        .Y(Y),
        .flag_comb(flag_comb)
    );

    result_register u_result_register (
        .clk(clk),
        .rst(rst),
        .en(en),
        .Y(Y),
        .flag_comb(flag_comb),
        .Q(Q),
        .flag_q(flag_q)
    );

endmodule