`timescale 10ns / 1ns		// 'timescale unit/precision. Each unit in simulation has 10ns, and precision is 1ns.
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
// test_cam Main del proyeco
// se instanciaron los siguientes modulos: Captura de datos(cam_read), RAM,Divisor de freuencia PLL, driver_ VGA

module test_cam
(
	// Entradas del test cam.
	
    input wire clk,           // Board clock: 100 MHz Nexys4DDR.
    input wire rst,           // Reset button.

	// Salidas.
	
    output wire VGA_Hsync_n,  // Horizontal VGA sync output.
    output wire VGA_Vsync_n,  // Vertical VGA sync output.
    output wire [3:0] VGA_R,  // 4-bit VGA bus red output.
    output wire [3:0] VGA_G,  // 4-bit VGA bus green output.
    output wire [3:0] VGA_B,  // 4-bit VGA bus blue output.

// Conexiones *****************************************
    
    //  Algunas conexiones de Driver_VGA.
    
    output wire clk25M,                  // 25MHz VGA clock.
	output wire [11:0] data_mem,         // Cable de DP_RAM a VGA 640X480.
	output reg  [14:0] DP_RAM_addr_out,	 // Registro Captura de datos a DP_RAM Direccion en memoria. 
    
    // Salidas de cam_read.v
    
    output wire [14:0] DP_RAM_addr_in,   // Cable Captura de datos a DP_RAM Direccion de memoria lectura. 
	output wire [11:0] DP_RAM_data_in,	 // Cable Captura de datos a DP_RAM Datos a guardar en la direccion de memoria.
    output wire DP_RAM_regW,             // Indica cuando un pixel esta completo.

//CAMARA input/output conexiones de la camara al modulo principal ********************************

	output wire CAM_xclk,		// System  clock input de la camara.
	output wire CAM_pwdn,		// Power down mode.
	output wire CAM_reset,		// Clear all registers of cam.
	input wire CAM_pclk,		// Sennal PCLK de la camara. 
	input wire CAM_href,		// Sennal HREF de la camara. 
	input wire CAM_vsync,		// Sennal VSYNC de la camara.
	input wire [7:0] CAM_px_data// Datos de entrada simulados. 

   );

// TAMANO DE ADQUISICION DE LA CAMARA
// Tamano de la imagne QQVGA

parameter CAM_SCREEN_X = 160; 		// 640 / 4. Elegido por preferencia, menos memoria usada.
parameter CAM_SCREEN_Y = 120;    	// 480 / 4.

localparam AW=15; // Se determina de acuerdo al tamano de de la direccion, de acuerdo al arreglo de pixeles dado por el formato en este caso Log(2)(160*120)=15.
localparam DW=12; // Se determina de acuerdo al tamano de la data, formato RGB444 = 12 bits.

// conexiondes del Clk

wire clk100M;       // Reloj de un puerto de la Nexys 4 DDR entrada.
wire clk25M;        // Para guardar el dato del reloj de la Pantalla (VGA 680X240 y DP_RAM).
wire clk24M;		// Para guardar el dato del reloj de la camara.

// Conexion dual por ram

localparam imaSiz= CAM_SCREEN_X*CAM_SCREEN_Y; // Posicion n+1 del tamano del arreglo de pixeles de acuerdo al formato.

wire [AW-1: 0] DP_RAM_addr_in;		// Conexion  Direccion entrada.
wire [DW-1: 0] DP_RAM_data_in;      // Conexion Dato entrada.
wire DP_RAM_regW;			        // Enable escritura de dato en memoria .

reg  [AW-1: 0] DP_RAM_addr_out;		//Registro de la direccion de memoria. 
 
// Conexion VGA Driver

wire [DW-1:0] data_mem;	    		// Salida de dp_ram al driver VGA.
wire [DW-1:0] data_RGB444;  		// Salida del driver VGA a la pantalla.
wire [9:0] VGA_posX;			    // Determinar la posicion en X del pixel en la pantalla.
wire [9:0] VGA_posY;			    // Determinar la posicion de Y del pixel en la pantalla.

/* ****************************************************************************
Asignacion de la informacion de la salida del driver a la pantalla
del registro data_RGB444
**************************************************************************** */

assign VGA_R = data_RGB444[11:8]; 	// Los 4 bits mas significativos corresponden al color ROJO (RED). 
assign VGA_G = data_RGB444[7:4];  	// Los 4 bits siguientes son del color VERDE (GREEN).
assign VGA_B = data_RGB444[3:0]; 	// Los 4 bits menos significativos son del color AZUL (BLUE).

/* ****************************************************************************
Asignacion de las senales de control xclk pwdn y reset de la camara
**************************************************************************** */

assign CAM_xclk = clk24M;		// Asignacion reloj camara.
assign CAM_pwdn = 0;			// Power down mode.
assign CAM_reset = 0;			// Reset camara.

/* ****************************************************************************
  Mediante vivado acudiendo a la ruta: " Project manager > IP Catalog > FPGA Features and Desing > Clocking > Clocking Wizard " 
  se genera genera un reloj de 25Mhz, usado por la VGA,  y un reloj de 24 MHz, utilizado por la camara
  a partir de una frecuencia de 100 Mhz, la cual corresponde a la Nexys 4.
*****************************************************************************/

clk24_25_nexys4 clk25_24(
.clk24M(clk24M),
.clk25M(clk25M),
.reset(rst),
.clk100M(clk)
);



/*
clk24_25_nexys4_0 clk25_24(
  .CLK_IN1(clk),				//Reloj de la FPGA.
  .CLK_OUT1(clk25M),			//Reloj de la VGA.
  .CLK_OUT2(clk24M),			//Reloj de la camara.
  .RESET(rst)					//Reset.
 );
*/
/* ****************************************************************************
Modulo de captura de datos /captura_de_datos_downsampler = cam_read
**************************************************************************** */

cam_read #(AW,DW) cam_read
(
	// Inputs 
		.CAM_px_data(CAM_px_data),
		.CAM_pclk(CAM_pclk),
		.CAM_vsync(CAM_vsync),
		.CAM_href(CAM_href),
		.rst(rst),

	//outputs
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
VGA_Driver VGA_640x480 // Necesitamos otro driver.
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
