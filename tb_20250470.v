// tb_20250470.v
// Testbench del Reto 15. Prueba combinacional (4096 vectores) con modelo
// independiente basado en listas de minterms y definiciones de operaciones,
// mas casos temporales del registro.
`timescale 1ns/1ps

module tb_20250470;

    reg        a, b, c, d;
    reg  [3:0] A, B;
    reg        clk, rst, en;
    wire       u, v;
    wire [3:0] Y;
    wire       flag_comb;
    wire [3:0] Q;
    wire       flag_q;

    top_20250470 dut (
        .a(a), .b(b), .c(c), .d(d),
        .A(A), .B(B),
        .clk(clk), .rst(rst), .en(en),
        .u(u), .v(v),
        .Y(Y), .flag_comb(flag_comb),
        .Q(Q), .flag_q(flag_q)
    );

    // reloj de 10 ns: flancos ascendentes en 5, 15, 25...
    initial clk = 1'b0;
    always #5 clk = ~clk;

    integer nvec, ncomp, nerr;
    integer ntemp, nterr;
    integer idx, ia, ib, k, j;

    // -------------------------------------------------------------
    // MODELO DE REFERENCIA (independiente del diseno)
    // -------------------------------------------------------------
    // u y v a partir de las listas de minterms
    function ref_u;
        input [3:0] i;
        begin
            case (i)
                4'd5, 4'd6, 4'd7, 4'd8, 4'd9,
                4'd12, 4'd13, 4'd14, 4'd15: ref_u = 1'b1;
                default:                    ref_u = 1'b0;
            endcase
        end
    endfunction

    function ref_v;
        input [3:0] i;
        begin
            case (i)
                4'd1, 4'd2, 4'd3, 4'd6, 4'd7,
                4'd9, 4'd11, 4'd13, 4'd15: ref_v = 1'b1;
                default:                   ref_v = 1'b0;
            endcase
        end
    endfunction

    // resultado Y segun {v,u}: 00 XOR, 01 RESTA, 10 SUMA, 11 MAYOR
    function [3:0] ref_y;
        input [1:0] sel;
        input integer x;
        input integer y;
        integer t, i;
        reg [3:0] r;
        begin
            r = 4'd0;
            case (sel)
                2'b00: begin
                    for (i = 0; i < 4; i = i + 1)
                        r[i] = (((x >> i) & 1) != ((y >> i) & 1));
                end
                2'b01: begin
                    t = x - y;
                    if (t < 0) t = t + 16;
                    r = t;
                end
                2'b10: begin
                    t = (x + y) % 16;
                    r = t;
                end
                default: begin
                    if (x > y) r = x; else r = y;
                end
            endcase
            ref_y = r;
        end
    endfunction

    // indicador segun {v,u}
    function ref_f;
        input [1:0] sel;
        input integer x;
        input integer y;
        integer i, cnt;
        reg [3:0] r;
        begin
            case (sel)
                2'b00: begin
                    r = ref_y(2'b00, x, y);
                    cnt = 0;
                    for (i = 0; i < 4; i = i + 1)
                        if (r[i]) cnt = cnt + 1;
                    ref_f = ((cnt % 2) == 1);
                end
                2'b01:   ref_f = (x < y);
                2'b10:   ref_f = ((x + y) > 15);
                default: ref_f = (x == y);
            endcase
        end
    endfunction

    // -------------------------------------------------------------
    // Comparacion combinacional
    // -------------------------------------------------------------
    task check_comb;
        input [3:0] i;
        input [3:0] xa;
        input [3:0] xb;
        reg       eu, ev, ef;
        reg [3:0] ey;
        begin
            eu = ref_u(i);
            ev = ref_v(i);
            ey = ref_y({ev, eu}, xa, xb);
            ef = ref_f({ev, eu}, xa, xb);
            ncomp = ncomp + 4;
            if (u !== eu) begin
                nerr = nerr + 1;
                $display("FALLA u: abcd=%b A=%0d B=%0d esperado=%b obtenido=%b", i, xa, xb, eu, u);
            end
            if (v !== ev) begin
                nerr = nerr + 1;
                $display("FALLA v: abcd=%b A=%0d B=%0d esperado=%b obtenido=%b", i, xa, xb, ev, v);
            end
            if (Y !== ey) begin
                nerr = nerr + 1;
                $display("FALLA Y: abcd=%b A=%0d B=%0d esperado=%b obtenido=%b", i, xa, xb, ey, Y);
            end
            if (flag_comb !== ef) begin
                nerr = nerr + 1;
                $display("FALLA flag_comb: abcd=%b A=%0d B=%0d esperado=%b obtenido=%b", i, xa, xb, ef, flag_comb);
            end
        end
    endtask

    // -------------------------------------------------------------
    // Comparacion del registro
    // -------------------------------------------------------------
    task check_q;
        input integer n;
        input [3:0] eq;
        input       ef;
        begin
            ntemp = ntemp + 1;
            if (Q === eq && flag_q === ef)
                $display("[caso %0d] OK   Q=%0d flag_q=%0b (t=%0t)", n, Q, flag_q, $time);
            else begin
                nterr = nterr + 1;
                $display("[caso %0d] FALLA esperado Q=%0d flag_q=%0b, obtenido Q=%b flag_q=%b (t=%0t)",
                         n, eq, ef, Q, flag_q, $time);
            end
        end
    endtask

    // captura una operacion: cambia entradas en el flanco de bajada (lejos del
    // flanco de captura), pone en=1, espera el flanco ascendente y comprueba Q
    // despues de que se aplicaron las asignaciones no bloqueantes
    task cap;
        input [3:0] i;
        input [3:0] xa;
        input [3:0] xb;
        input integer n;
        reg [1:0] s;
        reg [3:0] ey;
        reg       ef;
        begin
            @(negedge clk);
            {a, b, c, d} = i;
            A = xa;
            B = xb;
            en = 1'b1;
            s  = {ref_v(i), ref_u(i)};
            ey = ref_y(s, xa, xb);
            ef = ref_f(s, xa, xb);
            @(posedge clk);
            #1;
            check_q(n, ey, ef);
        end
    endtask

    // codigos abcd que activan XOR, RESTA, SUMA, MAYOR
    reg [3:0] opc [0:3];
    reg [3:0] pa  [0:6];
    reg [3:0] pb  [0:6];

    // -------------------------------------------------------------
    // Secuencia principal
    // -------------------------------------------------------------
    initial begin
        $dumpfile("20250470_wave.vcd");
        $dumpvars(0, tb_20250470);

        nvec = 0; ncomp = 0; nerr = 0; ntemp = 0; nterr = 0;
        a = 0; b = 0; c = 0; d = 0; A = 0; B = 0; rst = 0; en = 0;

        opc[0] = 4'b0000; // XOR    (v,u = 00)
        opc[1] = 4'b1000; // RESTA  (v,u = 01)
        opc[2] = 4'b0001; // SUMA   (v,u = 10)
        opc[3] = 4'b0111; // MAYOR  (v,u = 11)

        pa[0] = 4'd7;  pb[0] = 4'd7;   // A = B
        pa[1] = 4'd0;  pb[1] = 4'd7;   // A = 0
        pa[2] = 4'd7;  pb[2] = 4'd0;   // B = 0
        pa[3] = 4'd15; pb[3] = 4'd15;  // A = B = 15
        pa[4] = 4'd15; pb[4] = 4'd1;   // suma con acarreo
        pa[5] = 4'd0;  pb[5] = 4'd1;   // resta con prestamo
        pa[6] = 4'd0;  pb[6] = 4'd0;   // A = B = 0

        #20;

        // ---------- verificacion combinacional: 16 x 256 = 4096 ----------
        $display("=== Verificacion combinacional ===");
        for (idx = 0; idx < 16; idx = idx + 1) begin
            for (ia = 0; ia < 16; ia = ia + 1) begin
                for (ib = 0; ib < 16; ib = ib + 1) begin
                    {a, b, c, d} = idx;
                    A = ia;
                    B = ib;
                    #1;
                    check_comb(idx, ia, ib);
                    nvec = nvec + 1;
                end
            end
        end
        $display("Combinacional: vectores=%0d comparaciones=%0d errores=%0d", nvec, ncomp, nerr);

        // ---------- casos temporales ----------
        $display("=== Casos temporales ===");
        en = 1'b0; rst = 1'b0;
        {a, b, c, d} = 4'b0000; A = 4'd5; B = 4'd1;

        // (1) activar rst entre flancos (asincrono: Q = 0 sin flanco)
        @(negedge clk);
        #2;
        rst = 1'b1;
        #1;
        check_q(1, 4'd0, 1'b0);

        // (2) mantener rst con en = 1 durante un flanco
        @(negedge clk);
        {a, b, c, d} = 4'b0001; A = 4'd3; B = 4'd4; en = 1'b1;
        @(posedge clk);
        #1;
        check_q(2, 4'd0, 1'b0);

        // (3) liberar rst sin flanco; despues un flanco con en = 0 no captura
        @(negedge clk);
        en = 1'b0;
        #1;
        rst = 1'b0;
        #1;
        check_q(3, 4'd0, 1'b0);
        @(posedge clk);
        #1;
        check_q(3, 4'd0, 1'b0);

        // (4-7) una captura por operacion
        cap(opc[0], 4'd5, 4'd1, 4);   // XOR: 5^1 = 4, paridad impar -> 1
        cap(opc[1], 4'd0, 4'd1, 5);   // RESTA: 0-1 = 15, prestamo -> 1
        cap(opc[2], 4'd15, 4'd1, 6);  // SUMA: 15+1 = 0, acarreo -> 1
        cap(opc[3], 4'd9, 4'd4, 7);   // MAYOR: 9, distintos -> 0

        // (8) cambiar entradas con en = 0 y comprobar retencion en un flanco
        @(negedge clk);
        en = 1'b0;
        {a, b, c, d} = 4'b0001; A = 4'd2; B = 4'd3;
        @(posedge clk);
        #1;
        check_q(8, 4'd9, 1'b0);

        // (9) volver a habilitar y capturar (SUMA 2+3 = 5)
        @(negedge clk);
        en = 1'b1;
        @(posedge clk);
        #1;
        check_q(9, 4'd5, 1'b0);

        // (10) variar entradas entre flancos con en = 1: Q no cambia
        @(negedge clk);
        {a, b, c, d} = 4'b0111; A = 4'd12; B = 4'd3;
        #1;
        check_q(10, 4'd5, 1'b0);
        {a, b, c, d} = 4'b1000; A = 4'd1; B = 4'd1;
        #1;
        check_q(10, 4'd5, 1'b0);
        en = 1'b0;                   // se deshabilita antes del flanco
        @(posedge clk);
        #1;
        check_q(10, 4'd5, 1'b0);

        // (11) reiniciar entre flancos despues de almacenar un valor no nulo
        @(negedge clk);
        #2;
        rst = 1'b1;
        #1;
        check_q(11, 4'd0, 1'b0);
        @(negedge clk);
        rst = 1'b0;

        // (12) capturar nuevamente despues del reset (XOR 10^6 = 12)
        cap(opc[0], 4'd10, 4'd6, 12);

        // ---------- casos adicionales ----------
        $display("=== Casos adicionales (A=B, A=0, B=0, 15/15, acarreo, prestamo) ===");
        for (k = 0; k < 4; k = k + 1) begin
            for (j = 0; j < 7; j = j + 1) begin
                cap(opc[k], pa[j], pb[j], 13);
            end
        end

        #20;
        en = 1'b0;

        // ---------- resumen ----------
        $display("==========================================");
        $display("RESUMEN 20250470");
        $display("Vectores combinacionales : %0d", nvec);
        $display("Comparaciones (u,v,Y,flag): %0d", ncomp);
        $display("Errores combinacionales  : %0d", nerr);
        $display("Comprobaciones de registro: %0d", ntemp);
        $display("Errores de registro      : %0d", nterr);
        if (nerr == 0 && nterr == 0 && nvec == 4096)
            $display("RESULTADO FINAL: PASS");
        else
            $display("RESULTADO FINAL: FAIL");
        $display("==========================================");
        $finish;
    end

endmodule