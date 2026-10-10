// control_logic.v
// Funciones de control u y v (suma de productos minima, sacada con Karnaugh)
// Orden de variables: a (MSB), b, c, d. indice = 8a + 4b + 2c + d
// u = sum m(5,6,7,8,9,12,13,14,15) = a*c' + b*c + b*d
// v = sum m(1,2,3,6,7,9,11,13,15)  = a'*c + a*d + b'*d
module control_logic (
    input  wire a,
    input  wire b,
    input  wire c,
    input  wire d,
    output wire u,
    output wire v
);

    assign u = (a & ~c) | (b & c) | (b & d);
    assign v = (~a & c) | (a & d) | (~b & d);

endmodule