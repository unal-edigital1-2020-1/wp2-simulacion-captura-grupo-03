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

	 // Se�ales de prueba *****************************************

	output wire [11:0] data_mem,

	//CAMARA input/output ********************************

	output wire CAM_xclk,		// System  clock input de la c�mara.
	output wire CAM_pwdn,		// Power down mode.
	output wire CAM_reset,		// Clear all registers of cam.
	input wire CAM_pclk,		// Sennal PCLK de la camara. (wire?).
	input wire CAM_href,		// Sennal HREF de la camara. (wire?).
	input wire CAM_vsync,		// Sennal VSYNC de la camara. (wire?).
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
// Tamano de la imagne wcxwr
localparam wc=160;
localparam wr=120;

parameter CAM_SCREEN_X = wc; 		// 640 / 4. Elegido por preferencia, menos memoria usada.
parameter CAM_SCREEN_Y = wr;    	// 480 / 4.




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

wire [AW-1: 0] DP_RAM_addr_in;		// Direccion entrada.
wire [DW-1: 0] DP_RAM_data_in;		// Dato entrada.
wire DP_RAM_regW;					// Enable escritura.


reg  [AW-1: 0] DP_RAM_addr_out;

// Conexion VGA Driver
wire [DW-1:0] data_mem;	   // Salida de dp_ram al driver VGA
wire [DW-1:0] data_RGB444;  // salida del driver VGA al puerto
wire [8:0] VGA_posX;		   // Determinar la pos de memoria que viene del VGA
wire [7:0] VGA_posY;		   // Determinar la pos de memoria que viene del VGA


/* ****************************************************************************
La pantalla VGA es RGB 444, pero el almacenamiento en memoria se hace 332
por lo tanto, los bits menos significactivos deben ser cero
**************************************************************************** */
/*

Todos los datos a manejar estan en formato RGB 444. Cuando se haga el driver
se hara este pedazo.

*/

assign VGA_R = data_RGB444[11:7];
assign VGA_G = data_RGB444[7:4];
assign VGA_B = data_RGB444[3:0];


/* ****************************************************************************
Asignacion de las seales de control xclk pwdn y reset de la camara
**************************************************************************** */

assign CAM_xclk = clk24M;		// Asignación reloj cámara.
assign CAM_pwdn = 0;			// Power down mode.
assign CAM_reset = 0;			// Reset cámara.

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
  .CLK_OUT2(clk24M),			//Reloj de la cámara.
  .RESET(rst)					//Reset.
 );

/* ****************************************************************************
captura_datos_downsampler
**************************************************************************** */
//captura_de_datos_downsampler

cam_read #(AW,DW) cam_read
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
buffer_ram_dp #(AW,DW) DP_RAM(
		// Entradas.
	.clk_w(CAM_pclk),				//Frecuencia de toma de datos de cada pixel.
	.addr_in(DP_RAM_addr_in), 		// Dirección entrada dada por el capturador.
	.data_in(DP_RAM_data_in),		// Datos que entran de la cámara.
	.regwrite(DP_RAM_regW), 		// Enable.
	.clk_r(clk25M), 				// Reloj VGA.
	.addr_out(DP_RAM_addr_out),		// Direccion salida dada por VGA.
		// Salida.
	.data_out(data_mem),			// Datos enviados a la VGA.
	//.reset(rst)                   //(Sin usar)
);

/* ****************************************************************************
VGA_Driver640x480
**************************************************************************** */
VGA_Driver160x120 VGA640x480 // Necesitamos otro driver.
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
		if ((VGA_posX>CAM_SCREEN_X-1) || (VGA_posY>CAM_SCREEN_Y-1))
			DP_RAM_addr_out = 15'1111_1111_1111_111;		// Esta seria ultima posicion. Estaba asi DP_RAM_addr_out=CAM_SCREEN_X*CAM_SCREEN_Y;
		else
			DP_RAM_addr_out = VGA_posX + VGA_posY * CAM_SCREEN_Y;// Calcula posicion.
end

endmodule
