// tang_top_20250470.v
// Top para la Tang Primer 25K: sincroniza las 13 entradas de interruptores
// (2 flip-flops por senal), acondiciona rst (afirmacion asincrona, liberacion
// sincronizada) y adapta la polaridad de pulsador y LED.
//
// Orden de bits de los interruptores (rotular en el montaje):
//   sw_ctrl[3:0] = {a,b,c,d}   (sw_ctrl[3] = a, el MSB)
//   sw_opa[3:0]  = A[3:0]
//   sw_opb[3:0]  = B[3:0]
//   led[6:0]     = {v,u,flag_q,Q[3:0]}
module tang_top_20250470 #(
    parameter SW_ACTIVE_LOW  = 0,  // 1 si el interruptor da 0 cuando esta "activo"
    parameter BTN_ACTIVE_LOW = 0,  // 1 si el pulsador da 0 al presionarlo
    parameter LED_ACTIVE_LOW = 0   // 1 si el LED enciende con 0
) (
    input  wire       clk,         // reloj de la placa
    input  wire [3:0] sw_ctrl,
    input  wire [3:0] sw_opa,
    input  wire [3:0] sw_opb,
    input  wire       sw_en,
    input  wire       btn_rst,
    output wire [6:0] led
);

    // ---- polaridad de interruptores ----
    wire [12:0] sw_raw = SW_ACTIVE_LOW ? ~{sw_ctrl, sw_opa, sw_opb, sw_en}
                                       :  {sw_ctrl, sw_opa, sw_opb, sw_en};

    // ---- sincronizador de 2 flip-flops por entrada ----
    reg [12:0] sw_s1;
    reg [12:0] sw_s2;
    always @(posedge clk) begin
        sw_s1 <= sw_raw;
        sw_s2 <= sw_s1;
    end

    wire [3:0] ctl_s = sw_s2[12:9];
    wire [3:0] opa_s = sw_s2[8:5];
    wire [3:0] opb_s = sw_s2[4:1];
    wire       en_s  = sw_s2[0];

    // ---- reset: afirmacion asincrona, liberacion sincronizada ----
    wire rst_raw = BTN_ACTIVE_LOW ? ~btn_rst : btn_rst;
    reg  [1:0] rst_sync;
    always @(posedge clk or posedge rst_raw) begin
        if (rst_raw)
            rst_sync <= 2'b11;
        else
            rst_sync <= {rst_sync[0], 1'b0};
    end
    wire rst_i = rst_sync[1];

    // ---- sistema ----
    wire       u_w;
    wire       v_w;
    wire [3:0] y_w;
    wire       fc_w;
    wire [3:0] q_w;
    wire       fq_w;

    top_20250470 u_top (
        .a(ctl_s[3]),
        .b(ctl_s[2]),
        .c(ctl_s[1]),
        .d(ctl_s[0]),
        .A(opa_s),
        .B(opb_s),
        .clk(clk),
        .rst(rst_i),
        .en(en_s),
        .u(u_w),
        .v(v_w),
        .Y(y_w),
        .flag_comb(fc_w),
        .Q(q_w),
        .flag_q(fq_w)
    );

    // ---- LED ----
    wire [6:0] led_int = {v_w, u_w, fq_w, q_w};
    assign led = LED_ACTIVE_LOW ? ~led_int : led_int;

endmodule