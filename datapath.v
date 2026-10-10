// datapath.v
// Ruta de datos combinacional. Seleccion con {v,u}:
//   00 = XOR, 01 = RESTA, 10 = SUMA, 11 = MAYOR
module datapath (
    input  wire [3:0] A,
    input  wire [3:0] B,
    input  wire       u,
    input  wire       v,
    output wire [3:0] Y,
    output wire       flag_comb
);

    // SUMA: 5 bits para tener el acarreo
    wire [4:0] suma_full = {1'b0, A} + {1'b0, B};
    wire [3:0] y_suma    = suma_full[3:0];
    wire       f_suma    = suma_full[4];

    // RESTA: A - B modulo 16, indicador de prestamo si A < B
    wire [3:0] y_resta   = A - B;
    wire       f_resta   = (A < B);

    // XOR bit a bit, indicador de paridad impar (reduccion XOR)
    wire [3:0] y_xor     = A ^ B;
    wire       f_xor     = ^y_xor;

    // MAYOR: el mayor de los dos, indicador de igualdad
    wire [3:0] y_mayor   = (A > B) ? A : B;
    wire       f_mayor   = (A == B);

    // Seleccion con el operador ?: segun {v,u}
    assign Y         = v ? (u ? y_mayor : y_suma)
                         : (u ? y_resta : y_xor);
    assign flag_comb = v ? (u ? f_mayor : f_suma)
                         : (u ? f_resta : f_xor);

endmodule