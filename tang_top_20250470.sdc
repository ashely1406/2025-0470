// tang_top_20250470.sdc
// Reloj de la placa: oscilador de 50 MHz (periodo 20 ns), pin E2.
// Fuente: notas de pines de la Tang Primer 25K (ver informe). Verificar en el esquematico.
create_clock -name clk -period 20 -waveform {0 10} [get_ports {clk}]

// Entradas externas (interruptores y pulsador): son asincronas respecto a clk.
// Van directo a la primera etapa del sincronizador de 2 flip-flops (o al reset
// asincrono de rst_sync en el caso del pulsador), por eso no se analizan.
set_false_path -from [get_ports {sw_ctrl[*]}]
set_false_path -from [get_ports {sw_opa[*]}]
set_false_path -from [get_ports {sw_opb[*]}]
set_false_path -from [get_ports {sw_en}]
set_false_path -from [get_ports {btn_rst}]