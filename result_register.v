// result_register.v
// Registro de salida: reset asincrono activo en 1 con prioridad sobre en.
// Con rst = 0, en cada flanco ascendente: si en = 1 captura, si en = 0 retiene.
module result_register (
    input  wire       clk,
    input  wire       rst,
    input  wire       en,
    input  wire [3:0] Y,
    input  wire       flag_comb,
    output reg  [3:0] Q,
    output reg        flag_q
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            Q      <= 4'b0000;
            flag_q <= 1'b0;
        end else if (en) begin
            Q      <= Y;
            flag_q <= flag_comb;
        end
    end

endmodule