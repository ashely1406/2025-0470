module led_parpadeo (
    input wire clk,
    output reg led
);

    reg [31:0] contador = 0;

    always @(posedge clk) begin
        if (contador < 120000000 - 1) begin
            contador <= contador + 1;

            if (contador < 80000000)
                led <= 1'b1;
            else
                led <= 1'b0;

        end else begin
            contador <= 0;
            led <= 1'b1;
        end
    end

endmodule