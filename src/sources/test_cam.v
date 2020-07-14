`timescale 10ns / 1ns		// Se puede cambiar por `timescale 1ns / 1ps.
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    10:46:19 11/04/2019
// Design Name:
// Module Name:    test_cam
// Project Name:
// Target Devices:
// Tool versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
// captura_datos_downsampler= cam_read
module test_cam
(
    input wire clk,           // Board clock: 100 MHz Nexys4DDR.
    input wire rst,		   	  // Reset button. Externo

	// VGA input/output
    output wire VGA_Hsync_n,  // Horizontal sync output.
    output wire VGA_Vsync_n,  // Vertical sync output.
    output wire [3:0] VGA_R,  // 4-bit VGA red output.
    output wire [3:0] VGA_G,  // 4-bit VGA green output.
    output wire [3:0] VGA_B,  // 4-bit VGA blue output.

	 // Seï¿½ales de prueba *****************************************

	output wire [11:0] data_mem,
	output wire [14:0]  DP_RAM_addr_in,
	output wire [11:0] DP_RAM_data_in,
	output reg [14:0] DP_RAM_addr_out,


	//CAMARA input/output ********************************

	output wire CAM_xclk,		// System  clock input de la cï¿½mara.
	output wire CAM_pwdn,		// Power down mode.
	output wire CAM_reset,		// Clear all registers of cam.
	input wire CAM_pclk,		// Sennal PCLK de la camara. 
	input wire CAM_href,		// Sennal HREF de la camara. 
	input wire CAM_vsync,		// Sennal VSYNC de la camara.
	input wire [7:0] CAM_px_data		// Me parece que falta declarar [7:0] CAM_px_data.


//	input CAM_D0,					// Bit 0 de los datos del pixel
//	input CAM_D1,					// Bit 1 de los datos del pixel
//	input CAM_D2,					// Bit 2 de los datos del pixel
//	input CAM_D3,					// Bit 3 de los datos del pixel
//	input CAM_D4,					// Bit 4 de los datos del pixel
//	input CAM_D5,					// Bit 5 de los datos del pixel
//	input CAM_D6,					// Bit 6 de los datos del pixel
//	input CAM_D7 					// Bit 7 de los datos del pixel
   );

// TAMANNO DE ADQUISICION DE LA CAMARA
// Tamano de la imagne QQVGA

parameter CAM_SCREEN_X = 160; 		// 640 / 4. Elegido por preferencia, menos memoria usada.
parameter CAM_SCREEN_Y = 120;    	// 480 / 4.

/* // El color es RGB 332
localparam RED_VGA =   8'b11100000;
localparam GREEN_VGA = 8'b00011100;
localparam BLUE_VGA =  8'b00000011;
Creo que esto no va.
*/

// Clk
wire clk100M;       // Reloj de un puerto de la Nexys 4 DDR
wire clk25M;		// Para guardar el dato del reloj de la Pantalla.
wire clk24M;		// Para guardar el dato del reloj de la camara.

// Conexion dual por ram

localparam AW=15;
localparam DW=12;
localparam imaSiz= CAM_SCREEN_X*CAM_SCREEN_Y;// Posición n+1 

wire [AW-1: 0] DP_RAM_addr_in;		// Direccion entrada.
wire [DW-1: 0] DP_RAM_data_in;		// Dato entrada.
wire DP_RAM_regW;					// Enable escritura.


reg  [AW-1: 0] DP_RAM_addr_out;

// Conexion VGA Driver
wire [DW-1:0] data_mem;	   // Salida de dp_ram al driver VGA
wire [DW-1:0] data_RGB444;  // salida del driver VGA al puerto
wire [9:0] VGA_posX;		   // Determinar la pos de memoria que viene del VGA
wire [9:0] VGA_posY;		   // Determinar la pos de memoria que viene del VGA


/* ****************************************************************************
La pantalla VGA es RGB 444, pero el almacenamiento en memoria se hace 332
por lo tanto, los bits menos significactivos deben ser cero
**************************************************************************** */
/*

Todos los datos a manejar estan en formato RGB 444. Cuando se haga el driver
se hara este pedazo.

*/

assign VGA_R = data_RGB444[11:8];
assign VGA_G = data_RGB444[7:4];
assign VGA_B = data_RGB444[3:0];


/* ****************************************************************************
Asignacion de las seales de control xclk pwdn y reset de la camara
**************************************************************************** */

assign CAM_xclk = clk24M;		// AsignaciÃ³n reloj cÃ¡mara.
assign CAM_pwdn = 0;			// Power down mode.
assign CAM_reset = 0;			// Reset cÃ¡mara.

/* ****************************************************************************
  Este bloque se debe modificar segun sea le caso. El ejemplo esta dado para
  fpga Spartan6 lx9 a 32MHz.
  usar "tools -> Core Generator ..."  y general el ip con Clocking Wizard
  el bloque genera un reloj de 25Mhz usado para el VGA  y un relo de 24 MHz
  utilizado para la camara , a partir de una frecuencia de 32 Mhz
**************************************************************************** */
// assign clk100M =clk;			// Se guarda el reloj FPGA en variable. (No se esta usando).

clk24_25_nexys4 clk25_24(
  .CLK_IN1(clk),				//Reloj de la FPGA.
  .CLK_OUT1(clk25M),			//Reloj de la VGA.
  .CLK_OUT2(clk24M),			//Reloj de la cÃ¡mara.
  .RESET(rst)					//Reset.
 );

/* ****************************************************************************
captura_datos_downsampler
**************************************************************************** */
//captura_de_datos_downsampler

cam_read2_0 #(AW,DW) cam_read
// cam_read #(AW,DW) cam_read
(  // Captura?? Otro nombre??.	// Entradas.
        //entradas
		.CAM_px_data(CAM_px_data),
		.CAM_pclk(CAM_pclk),
		.CAM_vsync(CAM_vsync),
		.CAM_href(CAM_href),
		.rst(rst),

		//Salidas
		.DP_RAM_regW(DP_RAM_regW), //enable
		.DP_RAM_addr_in(DP_RAM_addr_in),
		.DP_RAM_data_in(DP_RAM_data_in)

	);


/* ****************************************************************************
buffer_ram_dp buffer memoria dual port y reloj de lectura y escritura separados
Se debe configurar AW  segn los calculos realizados en el Wp01
se recomiendia dejar DW a 8, con el fin de optimizar recursos  y hacer RGB 332
**************************************************************************** */
buffer_ram_dp DP_RAM(
		// Entradas.
	.clk_w(CAM_pclk),				//Frecuencia de toma de datos de cada pixel.
	.addr_in(DP_RAM_addr_in), 		// DirecciÃ³n entrada dada por el capturador.
	.data_in(DP_RAM_data_in),		// Datos que entran de la cÃ¡mara.
	.regwrite(DP_RAM_regW), 		// Enable.
	.clk_r(clk25M), 				// Reloj VGA.
	.addr_out(DP_RAM_addr_out),		// Direccion salida dada por VGA.
		// Salida.
	.data_out(data_mem)			// Datos enviados a la VGA.
	//.reset(rst)                   //(Sin usar)
);

/* ****************************************************************************
VGA_Driver640x480
**************************************************************************** */
VGA_Driver640x480 VGA640x480 // Necesitamos otro driver.
(
	.rst(rst),
	.clk(clk25M), 				// 25MHz  para 60 hz de 160x120
	.pixelIn(data_mem), 		// Entrada del valor de color  pixel RGB 444.
	.pixelOut(data_RGB444),		// Salida del datos a la VGA. (Pixeles). 
	.Hsync_n(VGA_Hsync_n),		// Sennal de sincronizacion en horizontal negada para la VGA.
	.Vsync_n(VGA_Vsync_n),		// Sennal de sincronizacion en vertical negada  para la VGA.
	.posX(VGA_posX), 			// Posicion en horizontal del pixel siguiente.
	.posY(VGA_posY) 			// posicinn en vertical  del pixel siguiente.

);


/* ****************************************************************************
Logica para actualizar el pixel acorde con la buffer de memoria y el pixel de
VGA si la imagen de la camara es menor que el display VGA, los pixeles
adicionales seran iguales al color del ultimo pixel de memoria
**************************************************************************** */
always @ (VGA_posX, VGA_posY) begin
		if ((VGA_posX>CAM_SCREEN_X-1)|(VGA_posY>CAM_SCREEN_Y-1))
			//Posición n+1(160*120), en buffer_ram_dp.v se le asignó el color negro.
			DP_RAM_addr_out = imaSiz;
		else
			DP_RAM_addr_out = VGA_posX + VGA_posY * CAM_SCREEN_X;// Calcula posicion.
end

endmodule
