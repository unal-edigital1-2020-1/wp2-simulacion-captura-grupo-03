
## Implementación
Para lograr la implementación en la FPGA (Nexys 4) fue necesario modificar algunos módulos para poder leer los datos enviados por la cámara los cuales son 8 datos enviados en paralelo los cuales representan un Byte.

### Módulos
#### test_cam
##### version para simulación
```verilog
`timescale 10ns / 1ns		// Se puede cambiar por `timescale 1ns / 1ps.
// test_cam Main del proyecto
// se instanciaron los siguientes módulos: Captura de datos(cam_read), RAM,Divisor de frecuencia PLL, driver_ VGA
module test_cam
(
	//Entradas del test cam
    input wire clk,           	// Board clock: 100 MHz Nexys4DDR.
    input wire rst,	 	// Reset button. Externo
	// Salida
    output wire VGA_Hsync_n,  // Horizontal sync output.
    output wire VGA_Vsync_n,  // Vertical sync output.
    output wire [3:0] VGA_R,  // 4-bit VGA red output.
    output wire [3:0] VGA_G,  // 4-bit VGA green output.
    output wire [3:0] VGA_B,  // 4-bit VGA blue output.
	 // Conexiones *****************************************
    //  Algunas conexiones de Driver_VGA.
    output wire clk25M, // 25MHz de la VGA
	output wire [11:0] data_mem,           //Cable de DP_RAM a VGA 640X480
	output reg  [14:0] DP_RAM_addr_out,	//Registro Captura de datos a DP_RAM DirecciónÃ³n en memoria 
    // Salidas de cam_read.v
    output wire [14:0] DP_RAM_addr_in,     //Cable Captura de datos a DP_RAM DirecciónÃ³n de memoria lectura 
	output wire [11:0] DP_RAM_data_in,	//Cable Captura de datos a DP_RAM Datos a guardar en la direcciónÃ³n de memoria 	
    output wire DP_RAM_regW, // Indica cuando un píxel esta completo.
	//cámara input/output conexiones de la cámara al módulo principal ********************************
	output wire CAM_xclk,		// System  clock input de la cÃ¯Â¿Â½mara.
	output wire CAM_pwdn,		// Power down mode.
	output wire CAM_reset,		// Clear all registers of cam.
	input wire CAM_pclk,		// Sennal PCLK de la cámara. 
	input wire CAM_href,		// Sennal HREF de la cámara. 
	input wire CAM_vsync,		// Sennal VSYNC de la cámara.
	input wire [7:0] CAM_px_data// Datos de entrada simulados 
   );
// TAMANO DE ADQUIsición DE LA cámara
// Tamano de la imagne QQVGA
parameter CAM_SCREEN_X = 160; 		// 640 / 4. Elegido por preferencia, menos memoria usada.
parameter CAM_SCREEN_Y = 120;    	// 480 / 4.
localparam AW=15; // Se determina de acuerdo al tamaÃ±o de de la direcciÃ³n, de acuerdo a l arreglo de píxeles dado por el formato en este caso Log(2)(160*120)=15
localparam DW=12; // Se determina de acuerdo al tamaÃ±o de la data, formaro RGB444 = 12 bites.
// conexiondes del Clk
wire clk100M;           // Reloj de un puerto de la Nexys 4 DDR entrada.
wire clk25M;	// Para guardar el dato del reloj de la Pantalla (VGA 680X240 y DP_RAM).
wire clk24M;		// Para guardar el dato del reloj de la cámara.
// Conexion dual por ram
localparam imaSiz= CAM_SCREEN_X*CAM_SCREEN_Y;// PosiciÃ³n n+1 del tamaÃ±p del arreglo de píxeles de acuerdo al formato.
wire [AW-1: 0] DP_RAM_addr_in;		// ConexiÃ³n  Direccion entrada.
wire [DW-1: 0] DP_RAM_data_in;      	// Conexion Dato entrada.
wire DP_RAM_regW;			// Enable escritura de dato en memoria .
reg  [AW-1: 0] DP_RAM_addr_out;		//Registro de la direcciÃ³n de memoria. 
// Conexion VGA Driver
wire [DW-1:0] data_mem;	    		// Salida de dp_ram al driver VGA
wire [DW-1:0] data_RGB444;  		// salida del driver VGA a la pantalla
wire [9:0] VGA_posX;			// Determinar la posiciÃ³n en X del píxel en la pantalla 
wire [9:0] VGA_posY;			// Determinar la posiciÃ³n de Y del píxel en la pantalla
/* ****************************************************************************
AsignaciÃ³n de la informaciÃ³n de la salida del driver a la pantalla
del regisro data_RGB444
**************************************************************************** */
assign VGA_R = data_RGB444[11:8]; 	//los 4 bites mÃ¡s significativos corresponden al color ROJO (RED) 
assign VGA_G = data_RGB444[7:4];  	//los 4 bites siguientes son del color VERDE (GREEN)
assign VGA_B = data_RGB444[3:0]; 	//los 4 bites menos significativos son del color AZUL(BLUE)
/* ****************************************************************************
Asignacion de las seales de control xclk pwdn y reset de la cámara
**************************************************************************** */
assign CAM_xclk = clk24M;		// AsignaciÃƒÂ³n reloj cÃƒÂ¡mara.
assign CAM_pwdn = 0;			// Power down mode.
assign CAM_reset = 0;			// Reset cÃƒÂ¡mara.
/* ****************************************************************************
   Se uso "IP Catalog >FPGA Features and Desing > Clocking > Clocking Wizard"  y general el ip con Clocking Wizard
  el bloque genera un reloj de 25Mhz usado para el VGA  y un reloj de 24 MHz
  utilizado para la cámara , a partir de una frecuencia de 100 Mhz que corresponde a la Nexys 4
**************************************************************************** */
clk24_25_nexys4 clk25_24(
  .clk100M(clk),				//Reloj de la FPGA.
  .clk25M(clk25M),			//Reloj de la VGA.
  .clk24M(clk24M),			//Reloj de la cámara.
  .reset(rst)					//Reset.
 );
/* ****************************************************************************
módulo de captura de datos /captura_de_datos_downsampler = cam_read
**************************************************************************** */
cam_read #(AW,DW) cam_read(
	// Inputs 
		.CAM_px_data(CAM_px_data),
		.CAM_pclk(CAM_pclk),
		.CAM_vsync(CAM_vsync),
		.CAM_href(CAM_href),
		.rst(rst),
	//outputs
		.DP_RAM_regW(DP_RAM_regW),        //enable
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
	.clk_w(CAM_pclk),				// Frecuencia de toma de datos de cada píxel.
	.addr_in(DP_RAM_addr_in), 		// Direccion entrada dada por el capturador.
	.data_in(DP_RAM_data_in),		// Datos que entran de la cámara.
	.regwrite(DP_RAM_regW), 	       	// Enable.
	.clk_r(clk25M), 				// Reloj VGA.
	.addr_out(DP_RAM_addr_out),		// Direccion salida dada por VGA.
	// Salida.
	.data_out(data_mem)			    // Datos enviados a la VGA.
	//.reset(rst)                   //(Sin usar)
);

/* ****************************************************************************
VGA_Driver640x480
**************************************************************************** */
VGA_Driver VGA_640x480(
	.rst(rst),
	.clk(clk25M), 				// 25MHz  para 60 hz de 160x120.
	.píxelIn(data_mem), 		// Entrada del valor de color  píxel RGB 444.
	.píxelOut(data_RGB444),		// Salida de datos a la VGA. (píxeles). 
	.Hsync_n(VGA_Hsync_n),		// Sennal de sincronizacion en horizontal negada para la VGA.
	.Vsync_n(VGA_Vsync_n),		// Sennal de sincronizacion en vertical negada  para la VGA.
	.posX(VGA_posX), 			// Posición en horizontal del píxel siguiente.
	.posY(VGA_posY) 			// posicinn en vertical  del píxel siguiente.
);
/* ****************************************************************************
Logica para actualizar el píxel acorde con la buffer de memoria y el píxel de
VGA si la imagen de la cámara es menor que el display VGA, los píxeles
adicionales seran iguales al color del ultimo píxel de memoria.
**************************************************************************** */
always @ (VGA_posX, VGA_posY) begin
		if ((VGA_posX>CAM_SCREEN_X-1)|(VGA_posY>CAM_SCREEN_Y-1))
			//Posición n+1(160*120), en buffer_ram_dp.v se le asigna el color negro.
			DP_RAM_addr_out = imaSiz;
		else
			DP_RAM_addr_out = VGA_posX + VGA_posY * CAM_SCREEN_X;// Calcula posición.
end
endmodule
```
##### version para Implementacion
```verilog
module test_cam
(
	//Entradas del test cam
    input wire clk,           	// Board clock: 100 MHz Nexys4DDR.
    input wire rst,	 	// Reset button. Externo
	// Salida
    output wire VGA_Hsync_n,  // Horizontal sync output.
    output wire VGA_Vsync_n,  // Vertical sync output.
    output wire [3:0] VGA_R,  // 4-bit VGA red output.
    output wire [3:0] VGA_G,  // 4-bit VGA green output.
    output wire [3:0] VGA_B,  // 4-bit VGA blue output.
	//CAMARA input/output conexiones de la camara al modulo principal ********************************
	output wire CAM_xclk,		// System  clock input de la cï¿½mara.
	output wire CAM_pwdn,		// Power down mode.
	output wire CAM_reset,		// Clear all registers of cam.
	input wire CAM_pclk,		// Sennal PCLK de la cámara. 
	input wire CAM_href,		// Sennal HREF de la cámara. 
	input wire CAM_vsync,		// Sennal VSYNC de la cámara.
    //Datos del pixel enviados por la camara (8 bits que en conjunto representan un Byte).
	input wire CAM_D0,                   // Bit 0 de los datos del pixel
    input wire CAM_D1,                   // Bit 1 de los datos del pixel
    input wire CAM_D2,                   // Bit 2 de los datos del pixel
    input wire CAM_D3,                   // Bit 3 de los datos del pixel
    input wire CAM_D4,                   // Bit 4 de los datos del pixel
    input wire CAM_D5,                   // Bit 5 de los datos del pixel
    input wire CAM_D6,                   // Bit 6 de los datos del pixel
    input wire CAM_D7                    // Bit 7 de los datos del pixel
    );
// TAMANO DE ADQUISICIÓN DE LA CÁMARA
// Tamaño de la imagen QQVGA
parameter CAM_SCREEN_X = 160; 		// 640 / 4. Elegido por preferencia, menos memoria usada.
parameter CAM_SCREEN_Y = 120;    	// 480 / 4.
localparam AW=15; // Se determina de acuerdo al tamaño de de la dirección, de acuerdo a l arreglo de pixeles dado por el formato en este caso Log(2)(160*120)=15
localparam DW=12; // Se determina de acuerdo al tamaño de la data, formaro RGB444 = 12 bites.
// conexiondes del Clk
wire clk100M;           // Reloj de un puerto de la Nexys 4 DDR entrada.
wire clk25M;	// Para guardar el dato del reloj de la Pantalla (VGA 680X240 y DP_RAM).
wire clk24M;		// Para guardar el dato del reloj de la camara.
// Conexion dual por ram
localparam imaSiz= CAM_SCREEN_X*CAM_SCREEN_Y;// Posición n+1 del tamaño del arreglo de pixeles de acuerdo al formato.
wire [AW-1: 0] DP_RAM_addr_in;		// Conexión  Dirección entrada.
wire [DW-1: 0] DP_RAM_data_in;      	// Conexion Dato entrada.
wire DP_RAM_regW;			// Enable escritura de dato en memoria .
reg  [AW-1: 0] DP_RAM_addr_out;		//Registro de la dirección de memoria. 
// Conexion VGA Driver
wire [DW-1:0] data_mem;	    		// Salida de dp_ram al driver VGA
wire [DW-1:0] data_RGB444;  		// salida del driver VGA a la pantalla
wire [9:0] VGA_posX;			// Determinar la posición en X del pixel en la pantalla 
wire [9:0] VGA_posY;			// Determinar la posición de Y del pixel en la pantalla
/* ****************************************************************************
Asignación de la información de la salida del driver a la pantalla
del regisro data_RGB444
**************************************************************************** */
assign VGA_R = data_RGB444[11:8]; 	//los 4 bites más significativos corresponden al color ROJO (RED) 
assign VGA_G = data_RGB444[7:4];  	//los 4 bites siguientes son del color VERDE (GREEN)
assign VGA_B = data_RGB444[3:0]; 	//los 4 bites menos significativos son del color AZUL(BLUE)
/* ****************************************************************************
Asignacion de las seales de control xclk pwdn y reset de la camara
**************************************************************************** */
assign CAM_xclk = clk24M;		// AsignaciÃ³n reloj cÃ¡mara.
assign CAM_pwdn = 0;			// Power down mode.
assign CAM_reset = 0;			// Reset cÃ¡mara.
/* ****************************************************************************
   Se uso "IP Catalog >FPGA Features and Desing > Clocking > Clocking Wizard"  y general el ip con Clocking Wizard
  el bloque genera un reloj de 25Mhz usado para el VGA  y un reloj de 24 MHz
  utilizado para la camara , a partir de una frecuencia de 100 Mhz que corresponde a la Nexys 4
**************************************************************************** */
clk24_25_nexys4 clk25_24(
.clk24M(clk24M),
.clk25M(clk25M),
.reset(rst),
.clk100M(clk)
);
/* ****************************************************************************
Modulo de captura de datos /captura_de_datos_downsampler = cam_read
**************************************************************************** */
cam_read #(AW,DW) cam_read
(
	// Inputs 
	    .CAM_D0(CAM_D0),                   // Bit 0 de los datos del p�xel
        .CAM_D1(CAM_D1),                   // Bit 1 de los datos del p�xel
        .CAM_D2(CAM_D2),                   // Bit 2 de los datos del p�xel
        .CAM_D3(CAM_D3),                   // Bit 3 de los datos del p�xel
        .CAM_D4(CAM_D4),                   // Bit 4 de los datos del p�xel
        .CAM_D5(CAM_D5),                   // Bit 5 de los datos del p�xel
        .CAM_D6(CAM_D6),                   // Bit 6 de los datos del p�xel
        .CAM_D7(CAM_D7),                    // Bit 7 de los datos del p�xel
		.CAM_pclk(CAM_pclk),
		.CAM_vsync(CAM_vsync),
		.CAM_href(CAM_href),
		.rst(rst),
	//outputs
		.DP_RAM_regW(DP_RAM_regW),        //enable
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
	.clk_w(CAM_pclk),				// Frecuencia de toma de datos de cada pixel.
	.addr_in(DP_RAM_addr_in), 		// Direccion entrada dada por el capturador.
	.data_in(DP_RAM_data_in),		// Datos que entran de la camara.
	.regwrite(DP_RAM_regW), 	       	// Enable.
	.clk_r(clk25M), 				// Reloj VGA.
	.addr_out(DP_RAM_addr_out),		// Direccion salida dada por VGA.
		// Salida.
	.data_out(data_mem)			    // Datos enviados a la VGA.
	//.reset(rst)                   //(Sin usar)
);
/* ****************************************************************************
VGA_Driver640x480
**************************************************************************** */
VGA_Driver VGA_640x480 // Necesitamos otro driver.
(
	.rst(rst),
	.clk(clk25M), 				// 25MHz  para 60 hz de 160x120.
	.pixelIn(data_mem), 		// Entrada del valor de color  pixel RGB 444.
	.pixelOut(data_RGB444),		// Salida de datos a la VGA. (Pixeles). 
	.Hsync_n(VGA_Hsync_n),		// Sennal de sincronizacion en horizontal negada para la VGA.
	.Vsync_n(VGA_Vsync_n),		// Sennal de sincronizacion en vertical negada  para la VGA.
	.posX(VGA_posX), 			// Posicion en horizontal del pixel siguiente.
	.posY(VGA_posY) 			// posicinn en vertical  del pixel siguiente.
);
/* ****************************************************************************
Logica para actualizar el pixel acorde con la buffer de memoria y el pixel de
VGA si la imagen de la camara es menor que el display VGA, los pixeles
adicionales seran iguales al color del ultimo pixel de memoria.
**************************************************************************** */
always @ (VGA_posX, VGA_posY) begin
		if ((VGA_posX>CAM_SCREEN_X-1)|(VGA_posY>CAM_SCREEN_Y-1))
			//Posicion n+1(160*120), en buffer_ram_dp.v se le asigna el color negro.
			DP_RAM_addr_out = imaSiz;
		else
			DP_RAM_addr_out = VGA_posX + VGA_posY * CAM_SCREEN_X;// Calcula posicion.
end
endmodule
```
##### Analisis de cambios
El cambio central de este modulo se dio en el hecho de que la camara no envia un bus de datos como se dispuso en la simulacion, la camara envia 8 datos simultaneamente de la camara.

* Seccion para los datos en la camara.

Se eliminaron las siguientes señales de las entradas y salidas a dado a queestas ya no se van a simular.
```verilog
    output wire clk25M, // 25MHz de la VGA
    output wire [11:0] data_mem,           //Cable de DP_RAM a VGA 640X480
    output reg  [14:0] DP_RAM_addr_out,	//Registro Captura de datos a DP_RAM DirecciÃ³n en memoria 
    // Salidas de cam_read.v
    output wire [14:0] DP_RAM_addr_in,     //Cable Captura de datos a DP_RAM DirecciÃ³n de memoria lectura 
	output wire [11:0] DP_RAM_data_in,	//Cable Captura de datos a DP_RAM Datos a guardar en la direcciÃ³n de memoria 	
    output wire DP_RAM_regW, // Indica cuando un píxel esta completo.
	//cámara input/output conexiones de la cámara al módulo principal ********************************
```
Se modifico el bus de datos:
```verilog
	input wire [7:0] CAM_px_data// Datos de entrada simulados 
``` 
De una señal de 8 bits a 8 señales de un bit para que las enradas coincidan con las señales proporcionadas por la camara:
```verilog
	input wire CAM_D0,                   // Bit 0 de los datos del pixel
    input wire CAM_D1,                   // Bit 1 de los datos del pixel
    input wire CAM_D2,                   // Bit 2 de los datos del pixel
    input wire CAM_D3,                   // Bit 3 de los datos del pixel
    input wire CAM_D4,                   // Bit 4 de los datos del pixel
    input wire CAM_D5,                   // Bit 5 de los datos del pixel
    input wire CAM_D6,                   // Bit 6 de los datos del pixel
    input wire CAM_D7                    // Bit 7 de los datos del pixel
```
* instanciamiento de modulos

Se modifico el instamciamiento del modulo`clk24_25` para que sus nombres se entiendan mejor en el codigo}
```verilog
clk24_25_nexys4 clk25_24(
.clk24M(clk24M),
.clk25M(clk25M),
.reset(rst),
.clk100M(clk)
);
```
Se modifico el insanciamiento del modulo `cam_read` para que concuerde con la captura de los 8 datos proporcionados por la camara
```verilog
cam_read #(AW,DW) cam_read
(
	// Inputs 
	    .CAM_D0(CAM_D0),                   // Bit 0 de los datos del p�xel
        .CAM_D1(CAM_D1),                   // Bit 1 de los datos del p�xel
        .CAM_D2(CAM_D2),                   // Bit 2 de los datos del p�xel
        .CAM_D3(CAM_D3),                   // Bit 3 de los datos del p�xel
        .CAM_D4(CAM_D4),                   // Bit 4 de los datos del p�xel
        .CAM_D5(CAM_D5),                   // Bit 5 de los datos del p�xel
        .CAM_D6(CAM_D6),                   // Bit 6 de los datos del p�xel
        .CAM_D7(CAM_D7),                    // Bit 7 de los datos del p�xel
		.CAM_pclk(CAM_pclk),
		.CAM_vsync(CAM_vsync),
		.CAM_href(CAM_href),
		.rst(rst),
	//outputs
		.DP_RAM_regW(DP_RAM_regW),        //enable
		.DP_RAM_addr_in(DP_RAM_addr_in),
		.DP_RAM_data_in(DP_RAM_data_in)
	);
	```
#### cam_read
##### version de simulacion
```verilog
module cam_read2_0 #(parameter AW = 15,parameter DW = 12 )
		(
		CAM_px_data,
		CAM_pclk,
		CAM_vsync,
		CAM_href,
		rst,
		
		DP_RAM_regW, 
		DP_RAM_addr_in,
		DP_RAM_data_in
   );
		input [7:0] CAM_px_data;
		input CAM_pclk;
		input CAM_vsync;
		input CAM_href;
		input rst;
		output reg DP_RAM_regW; //enable
		output reg [AW-1:0] DP_RAM_addr_in;
		output reg [DW-1:0] DP_RAM_data_in;
parameter INIT=0,BYTE1=1,BYTE2=2,NOTHING=3,imaSiz=19199;
reg [1:0]status=0;
reg readyPassed=0;
//reg [11:0]color= 12'b111100000000;
always @(posedge CAM_pclk)begin
    if(rst)begin
    status<=0;
     DP_RAM_data_in<=0;
     DP_RAM_addr_in<=0;
     DP_RAM_regW<=0;
     readyPassed<=0;
    end
    else begin
     case (status)
         INIT:begin 
            DP_RAM_data_in<=0;
            DP_RAM_addr_in<=0;
            DP_RAM_regW<=0;
            readyPassed<=0;   
            if(~CAM_vsync&CAM_href)begin
            status<=BYTE2;
            DP_RAM_data_in[11:8]<=CAM_px_data[3:0];
           //DP_RAM_data_in[11:8]<=color[11:8];
            end
         end
         BYTE1:begin
         DP_RAM_regW<=0;
         if(CAM_href)begin
         DP_RAM_data_in[11:8]<=CAM_px_data[3:0];
        // DP_RAM_data_in[11:8]<=color[11:8];
         DP_RAM_regW<=0;
         status<=BYTE2;
         end
         else status<=NOTHING;
         end
         BYTE2:begin
            if(DP_RAM_addr_in==imaSiz|(DP_RAM_addr_in==0&~readyPassed))
            begin
                DP_RAM_addr_in<=0;
                readyPassed<=1;
            end
            else begin
            DP_RAM_addr_in<=DP_RAM_addr_in+1;
            end
             DP_RAM_data_in[7:0]<=CAM_px_data;
           // DP_RAM_data_in[7:0]<=color[7:0];
             DP_RAM_regW<=1;    
             status<=BYTE1;
         end
         NOTHING:begin
	        if(CAM_href)begin
             status<=BYTE2;
             DP_RAM_data_in[11:8]<=CAM_px_data[3:0];
             //DP_RAM_data_in[11:8]<=color[11:8];
             end
             else if (CAM_vsync) status<=INIT;
         end
         default: status<=INIT;
    endcase
 end
end
endmodule

```
##### version para la implementacion
```verilog
module cam_read #(
		parameter AW = 15,  // Cantidad de bits  de la direcci�n
		parameter DW = 12   //tamaño de la data 
		)
		(
		CAM_pclk,     //reloj 
		CAM_vsync,    //Señal Vsync para captura de datos
		CAM_href,	// Señal Href para la captura de datos
		rst,		//reset
		DP_RAM_regW, 	//Control de esctritura
		DP_RAM_addr_in,	//Dirección de memoria de entrada
		DP_RAM_data_in,	//Data de entrada a la RAM
	    CAM_D0,                   // Bit 0 de los datos del p�xel
        CAM_D1,                   // Bit 1 de los datos del p�xel
        CAM_D2,                   // Bit 2 de los datos del p�xel
        CAM_D3,                   // Bit 3 de los datos del p�xel
        CAM_D4,                   // Bit 4 de los datos del p�xel
        CAM_D5,                   // Bit 5 de los datos del p�xel
        CAM_D6,                   // Bit 6 de los datos del p�xel
        CAM_D7                    // Bit 7 de los datos del p�xel
   );
	    input CAM_D0;                   // Bit 0 de los datos del p�xel
        input CAM_D1;                   // Bit 1 de los datos del p�xel
        input CAM_D2;                   // Bit 2 de los datos del p�xel
        input CAM_D3;                   // Bit 3 de los datos del p�xel
        input CAM_D4;                   // Bit 4 de los datos del p�xel
        input CAM_D5;                   // Bit 5 de los datos del p�xel
        input CAM_D6;                   // Bit 6 de los datos del p�xel
        input CAM_D7;                    // Bit 7 de los datos del p�xel
		input CAM_pclk;		//Reloj de la camara
		input CAM_vsync;	//señal vsync de la camara
		input CAM_href;		//señal href de la camara
		input rst;		//reset de la camara 
		output reg DP_RAM_regW; 		//Registro del control de escritura 
	    output reg [AW-1:0] DP_RAM_addr_in;	// Registro de salida de la dirección de memoria de entrada 
	    output reg [DW-1:0] DP_RAM_data_in;	// Registro de salida de la data a escribir en memoria
        wire [7:0] CAM_px_data={CAM_D7,CAM_D6,CAM_D5,CAM_D4,CAM_D3,CAM_D2,CAM_D1,CAM_D0};
//Maquina de estados
localparam INIT=0,BYTE1=1,BYTE2=2,NOTHING=3,imaSiz=19199;
reg [1:0]status=0;
always @(posedge CAM_pclk)begin
    if(rst)begin
        status<=0;
        DP_RAM_data_in<=0;
        DP_RAM_addr_in<=0;
        DP_RAM_regW<=0;
    end
    else begin
     case (status)
         INIT:begin 
             if(~CAM_vsync&CAM_href)begin // cuando la señal vsync negada y href son, se empieza con la escritura de los datos en memoria.
                 status<=BYTE2;
                 DP_RAM_data_in[11:8]<=CAM_px_data[3:0]; //se asignan los 4 bits menos significativos de la información que da la camara a los 4 bits mas significativos del dato a escribir
             end
             else begin
                 DP_RAM_data_in<=0;
                 DP_RAM_addr_in<=0;
                 DP_RAM_regW<=0;
             end 
         end
         BYTE1:begin
             DP_RAM_regW<=0; 					//Desactiva la escritura en memoria 
             if(CAM_href)begin					//si la señal Href esta arriva, evalua si ya llego a la ultima posicion en memoria
                     if(DP_RAM_addr_in==imaSiz) DP_RAM_addr_in<=0;			//Si ya llego al final, reinicia la posición en memoria. 
                     else DP_RAM_addr_in<=DP_RAM_addr_in+1;	//Si aun no ha llegado a la ultima posición sigue recorriendo los espacios en memoria y luego escribe en ellos cuan do pasa al estado Byte2
                 DP_RAM_data_in[11:8]<=CAM_px_data[3:0];
                 status<=BYTE2;
             end
             else status<=NOTHING;   
         end
         BYTE2:begin							//En este estado se habilita la escritura en memoria
             	DP_RAM_data_in[7:0]<=CAM_px_data;
             	DP_RAM_regW<=1;    
             	status<=BYTE1;
         end
         NOTHING:begin						// es un estado de trnsición    
             if(CAM_href)begin					// verifica la señal href y se asigna los 4 bits mas significativos y se mueve una posición en memoria
                 status<=BYTE2;
                 DP_RAM_data_in[11:8]<=CAM_px_data[3:0];
                 DP_RAM_addr_in<=DP_RAM_addr_in+1;
             end
             else if (CAM_vsync) status<=INIT;		// Si vsync esta arriba inicializa la maquina de estados    
         end
         default: status<=INIT;
    endcase
 end
end
endmodule
```
* Modificaciones

En este modulo se cambio la señal de entrada el 
```verilog
CAM_px_data,
```
Por las ocho señales proporcionados por la camara.
```verilog
CAM_D0,                   // Bit 0 de los datos del p�xel
CAM_D1,                   // Bit 1 de los datos del p�xel
CAM_D2,                   // Bit 2 de los datos del p�xel
CAM_D3,                   // Bit 3 de los datos del p�xel
CAM_D4,                   // Bit 4 de los datos del p�xel
CAM_D5,                   // Bit 5 de los datos del p�xel
CAM_D6,                   // Bit 6 de los datos del p�xel
CAM_D7                    // Bit 7 de los datos del p�xel
```
Y la señal `CAM_px_data` fue generada en la seccion interna del modulo como la concatenacion(union de datos) de las ocho señales individuales:
```verilog
 wire [7:0] CAM_px_data={CAM_D7,CAM_D6,CAM_D5,CAM_D4,CAM_D3,CAM_D2,CAM_D1,CAM_D0};}
```
#### Buffer_ram_DP

##### version de simulacion
```verilog
module buffer_ram_dp#(
	parameter AW = 15,		 // Cantidad de bits  de la direccion.
	parameter DW = 12,		 // Cantidad de Bits de los datos.
	parameter imageFILE = "C:/Users/jolec/Downloads/wp2-simulacion-captura-grupo-03-master/wp2-simulacion-captura-grupo-03-master/src/sources/imagen.men")
	(
	input clk_w,     		 // Frecuencia de toma de datos de cada pixel.
	input [AW-1: 0] addr_in, // DirecciÃ³n entrada dada por el capturador.
	input [DW-1: 0] data_in, // Datos que entran de la cÃ¡mara.
	input regwrite,		  	 // Enable.
	input clk_r, 				    // Reloj 25MHz VGA.
	input [AW-1: 0] addr_out, 		// DirecciÃ³n de salida dada por VGA.
	output reg [DW-1: 0] data_out	// Datos enviados a la VGA.
	//input reset					// De momento no se esta usando.
	);
// Calcular el numero de posiciones totales de memoria.
localparam NPOS = 2 ** AW; 			// Memoria.
localparam imaSiz=160*120;
 reg [DW-1: 0] ram [0: NPOS-1];
// Escritura  de la memoria port 1.
always @(posedge clk_w) begin
       if (regwrite == 1)
// Escribe los datos de entrada en la direcciÃ³n que addr_in se lo indique.
             ram[addr_in] <= data_in;
end
// Lectura  de la memoria port 2.
always @(*) begin
// Se leen los datos de las direcciones addr_out y se sacan en data_out.
		data_out <= ram[addr_out];
end
initial begin
// Lee en hexadecimal (readmemb lee en binario) dentro de ram [1, pÃ¡g 217].
	$readmemh(imageFILE, ram);
	// En la posición n+1 (160*120) se guarda el color negro
	ram[imaSiz] = 12'h0;
end
endmodule
```
##### version para implementacion
```verilog
module buffer_ram_dp#(
	parameter AW = 15,		 // Cantidad de bits  de la direccion.
	parameter DW = 12,		 // Cantidad de Bits de los datos.
	// Absolute address in Esteban's computer
	parameter imageFILE = "C:/Users/jolec/Downloads/wp2-simulacion-captura-grupo-03-master/wp2-simulacion-captura-grupo-03-master/src/sources/imagen.men")
	//parameter imageFILE = "D:/UNAL/semester6/digitali/proyecto/wp2-simulacion-captura-grupo-03/src/sources/imagen.men")
	// Absolute address in Niko's computer
	// parameter imageFILE = "C:/Users/LucasTheKitten/Desktop/Captura/wp2-simulacion-captura-grupo-03/src/sources/imagen.men")
	(
	input clk_w,     		 // Frecuencia de toma de datos de cada pixel.
	input [AW-1: 0] addr_in, // DirecciÃ³n entrada dada por el capturador.
	input [DW-1: 0] data_in, // Datos que entran de la cÃ¡mara.
	input regwrite,		  	 // Enable.
	input clk_r, 				    // Reloj 25MHz VGA.
	input [AW-1: 0] addr_out, 		// DirecciÃ³n de salida dada por VGA.
	output reg [DW-1: 0] data_out	// Datos enviados a la VGA.
	//input reset					// De momento no se esta usando.
	);
// Calcular el numero de posiciones totales de memoria.
localparam NPOS = 2 ** AW; 			// Memoria.
localparam imaSiz=160*120;
 reg [DW-1: 0] ram [0: NPOS-1];
// Escritura  de la memoria port 1.
always @(posedge clk_w) begin
       if (regwrite == 1)
// Escribe los datos de entrada en la direcciÃ³n que addr_in se lo indique.
             ram[addr_in] <= data_in;
end
// Lectura  de la memoria port 2.
always @(posedge clk_r) begin
// Se leen los datos de las direcciones addr_out y se sacan en data_out.
		data_out <= ram[addr_out];
end
initial begin
// Lee en hexadecimal (readmemb lee en binario) dentro de ram [1, pÃ¡g 217].
	$readmemh(imageFILE, ram);
	// En la posición n+1 (160*120) se guarda el color negro
	ram[imaSiz] = 12'h0;
end
endmodule
```
##### cambios
En este modulo se cambio la sincroniacion en el momento en que los datos en la ram en la posicion `addr_out` se guardan en el `data_out`.

Este se sincronizaba siempre que hubisese un cambio:
```verilog
always @(*) begin
// Se leen los datos de las direcciones addr_out y se sacan en data_out.
		data_out <= ram[addr_out];
```
Y se cambio a siempre que exista un flanco de subida en el reloj `clk_r` el cual es el reloj de 25Mhz de la pantalla VGA:
```verilog
always @(posedge clk_r) begin
// Se leen los datos de las direcciones addr_out y se sacan en data_out.
		data_out <= ram[addr_out];
```
#### test_cam_TB

##### version de simulacion
```verilog
module test_cam_TB;
	// Inputs
	reg clk;
	reg rst;
	reg pclk;
	reg CAM_vsync;
	reg CAM_href;
	reg [7:0] CAM_px_data;
	// Outputs
	wire VGA_Hsync_n;
	wire VGA_Vsync_n;
	wire [3:0] VGA_R;
	wire [3:0] VGA_G;
	wire [3:0] VGA_B;
	wire CAM_xclk;
	wire CAM_pwdn;
	wire CAM_reset;
    // Senales de prueba ******************************
    wire [11:0] data_mem;
	wire [14:0] DP_RAM_addr_in;
	wire [11:0] DP_RAM_data_in;
	wire [14:0] DP_RAM_addr_out;
    // Senales de prueba ******************************
// Absolute Address in Esteban's computer
localparam d="C:/Users/jolec/Documents/vga texto/test_vga.txt";
	// C:/Users/jolec/Downloads/wp2-simulacion-captura-grupo-03-master/wp2-simulacion-captura-grupo-03/src/test_vga.txt
	// Instantiate the Unit Under Test (UUT)
	test_cam uut (
		.clk(clk),
		.rst(rst),
		.VGA_Hsync_n(VGA_Hsync_n),
		.VGA_Vsync_n(VGA_Vsync_n),
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B),
		// se???ales de prueba *******************************************
	   .data_mem(data_mem),
	   .DP_RAM_addr_in(DP_RAM_addr_in),
	   .DP_RAM_data_in(DP_RAM_data_in),
	   .DP_RAM_addr_out(DP_RAM_addr_out),
		//Prueba *******************************************
		.CAM_xclk(CAM_xclk),
		.CAM_pwdn(CAM_pwdn),
		.CAM_reset(CAM_reset),
		.CAM_pclk(pclk),
		.CAM_vsync(CAM_vsync),
		.CAM_href(CAM_href),
		.CAM_px_data(CAM_px_data)
	);
	reg img_generate=0;
	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 1;
		pclk = 0;
		CAM_vsync = 1;
		CAM_href = 0;
		CAM_px_data = 8'h0f;
   	// Wait 100 ns for global reset to finish
		#20;
		rst = 0; // registros en f???sico para que reinicialicen.
		// #1_000_000;         // se puede quitar en simulacion, estoy esperando que la memoria se llene.
		img_generate=1; // Estaban pegados
	end
	always #0.5 clk  = ~clk;
 	always #2 pclk  = ~pclk;
	reg [8:0]line_cnt=0;   //2^9-1=511, TAM_LINE+BLACK_TAM_LINE=324  
	reg [6:0]row_cnt=0;    //2^7-1= 127, TAM_ROW+BLACK_TAM_ROW=124 
	parameter TAM_LINE=320;	// es 160x2 debido a que son dos pixeles de RGB
	parameter TAM_ROW=120;
	parameter BLACK_TAM_LINE=4;
	parameter BLACK_TAM_ROW=4;
	//registros de simulacion del color
    reg cont=0;
    parameter[3:0]R=4'b0000; //rojo del pixel RRRR
    parameter[3:0]G=4'b1111; //verde del pixel GGGG
    parameter[3:0]B=4'b0000; //azul del pixel BBBB
    reg [11:0]colorRGB444= {R[3:0],G[3:0],B[3:0]}; //color RRRR GGGG BBBB,first byte= XXXX RRRR, second byte= GGGG BBBB
	//simuacion de lineas de color
	always @(posedge pclk) begin
	if (row_cnt<15)begin
	colorRGB444=12'b111100001111;
	end
	else if (row_cnt<45)begin
	colorRGB444=12'b000011110000;
	end
	else if (row_cnt<75)begin
	colorRGB444=12'b111100001111;
	end
	else if (row_cnt<105)begin
	colorRGB444=12'b000011110000;
	end
	else if (row_cnt<120)begin
	colorRGB444=12'b111100001111;
	end
	end
	//simulacion del color
	// color =firstByte XXXX RRRR _ Second BYTE GGGG BBBB;
	always @(posedge pclk) begin
	cont=cont+1;
	if (cont ==0)begin//first Byte
	CAM_px_data[3:0]=colorRGB444[11:8];
	end
	if(cont == 1)begin//second Byte
	CAM_px_data = colorRGB444[7:0];
	end
	end
	/*simulaci???n de contador de pixeles para  general Href y vsync*/
	initial forever  begin
	    //CAM_px_data=~CAM_px_data;
		@(posedge pclk) begin
		if (img_generate==1) begin
			line_cnt=line_cnt+1;
			if (line_cnt >TAM_LINE-1+BLACK_TAM_LINE) begin
				line_cnt=0;
				row_cnt=row_cnt+1;
				if (row_cnt>TAM_ROW-1+BLACK_TAM_ROW) begin
					row_cnt=0;
				end
			end
		end
		end
	end
	/*simulaci???n de la se???al vsync generada por la camara*/
	initial forever  begin
		@(posedge pclk) begin
            if (img_generate==1) begin
                    if (row_cnt==0)begin
                        CAM_vsync  = 1;
                    end
                if (row_cnt==BLACK_TAM_ROW/2)begin
                    CAM_vsync  = 0;
                end
            end
		end
	end
	/*simulaci???n de la se???al href generada por la camara*/
	initial forever  begin
		@(negedge pclk) begin
            if (img_generate==1) begin
                if (row_cnt>BLACK_TAM_ROW-1)begin
                    if (line_cnt==0)begin
                        CAM_href  = 1;
						CAM_px_data =CAM_px_data;
						//CAM_px_data = ~ CAM_px_data;
                    end
                end
                if (line_cnt==TAM_LINE)begin
                    CAM_href  = 0;
                end
            end
		end
	end
	integer f;
	initial begin
      f = $fopen(d,"w");
   end
	reg clk_w =0;
	always #1 clk_w  = ~clk_w;
	/* ecsritura de log para cargar se cargados en https://ericeastwood.com/lab/vga-simulator/*/
	initial forever begin
	@(posedge clk_w)
		$fwrite(f,"%0t ps: %b %b %b %b %b\n",$time,VGA_Hsync_n, VGA_Vsync_n, VGA_R[3:0],VGA_G[3:0],VGA_B[3:0]);
	end
endmodule
```
##### version de prueba para la implementacion
```verilog
module test_cam_TB;
	// Inputs. Declare as reg because are in left part of initial statemet.
	reg clk;
	reg rst;
	reg pclk;
	reg CAM_vsync;
	reg CAM_href;
	reg [7:0] CAM_px_data;
	// Outputs
	wire VGA_Hsync_n;
	wire VGA_Vsync_n;
	wire [3:0] VGA_R;
	wire [3:0] VGA_G;
	wire [3:0] VGA_B;
	wire CAM_xclk;
	wire CAM_pwdn;
	wire CAM_reset;
   wire CAM_D0;
   wire CAM_D1;   
   wire CAM_D2;   
   wire CAM_D3;
   wire CAM_D4;
   wire CAM_D5;
   wire CAM_D6;
   wire CAM_D7;
    // Senales de prueba ******************************
// Absolute Address in Esteban's computer
localparam d="D:/UNAL/semester6/digitali/proyecto/wp2-simulacion-captura-grupo-03/src/test_vga.txt";
// Absolute address in Niko's computer
// localparam d="C:/Users/LucasTheKitten/Desktop/Captura/wp2-simulacion-captura-grupo-03/src/test_vga.txt";	
// Absolute address in Niko's mac computer
// localparam d="C:/Users/Nikolai/Desktop/wp2-simulacion-captura-grupo-03/src/test_vga.txt";	
	// Instantiate the Unit Under Test (UUT)
	test_cam uut (
		.clk(clk),
		.rst(rst),
		.VGA_Hsync_n(VGA_Hsync_n),
		.VGA_Vsync_n(VGA_Vsync_n),
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B),

		.CAM_xclk(CAM_xclk),
		.CAM_pwdn(CAM_pwdn),
		.CAM_reset(CAM_reset),
		.CAM_pclk(pclk),
		.CAM_vsync(CAM_vsync),
		.CAM_href(CAM_href),
	
		.CAM_D0(CAM_D0),
        .CAM_D1(CAM_D1),   
        .CAM_D2(CAM_D2),   
        .CAM_D3(CAM_D3),
        .CAM_D4(CAM_D4),
        .CAM_D5(CAM_D5),
        .CAM_D6(CAM_D6),
        .CAM_D7(CAM_D7) 
    );
	reg img_generate=0;
	assign CAM_D0=CAM_px_data[0]; 
	assign CAM_D1=CAM_px_data[1];
	assign CAM_D2=CAM_px_data[2];
	assign CAM_D3=CAM_px_data[3];
	assign CAM_D4=CAM_px_data[4];
	assign CAM_D5=CAM_px_data[5];
	assign CAM_D6=CAM_px_data[6];
	assign CAM_D7=CAM_px_data[7];
	initial begin // Do at start of test. 
		// Initialize Inputs
		clk = 0;
		rst = 1;				// Press rst.
		pclk = 0;
		CAM_vsync = 1;			// Empieza la imagen.
		CAM_href = 0;			// Empieza la imagen.
		CAM_px_data = 8'h0f;	// Red
   	// Wait 100 ns for global reset to finish
		#20;
		rst = 0; 				// registros en fisico para que reinicialicen.
		// #1_000_000;			// se puede quitar en simulacion, estoy esperando que la memoria se llene.
		img_generate=1;			// Estaban pegados
	end
	always #0.5 clk  = ~clk; // Cada 0.5 unidades de tiempo, cambia a su estado opuesto, reloj.
 	always #2 pclk  = ~pclk;
	reg [8:0]line_cnt=0;   //2^9-1=511, TAM_LINE+BLACK_TAM_LINE=324  
	reg [6:0]row_cnt=0;    //2^7-1= 127, TAM_ROW+BLACK_TAM_ROW=124 
	parameter TAM_LINE=320;	// 160x2 debido a que son dos pixeles de RGB
	parameter TAM_ROW=120;
	parameter BLACK_TAM_LINE=4;
	parameter BLACK_TAM_ROW=4;
	/* //ejemplo para la simulacion de 4 secciones(de dos colore donde se empieza y se termina con media ssecion de color
	//simuacion de lineas de color para 4 secciones se divide el largo en 4 120/4=30 lineas
	always @(posedge pclk) begin
	if (row_cnt<15)begin //para tener media seccion al principio se cuentan 15 posiciones verticales
	colorRGB444=12'b111100001111; //color rosa
	end
	else if (row_cnt<45)begin //cuando se superan las 15 lineas pero esta por debajo de las 45 (una seccion de 30 depues de la media de 15)
	colorRGB444=12'b000011110000;//color verde
	end
	else if (row_cnt<75)begin//cuando se superan las 45 lineas pero esta por debajo de las 75
	colorRGB444=12'b111100001111;//color rosa
	end
	else if (row_cnt<105)begin//cuando se superan las 75 lineas pero esta por debajo de las 105 
	colorRGB444=12'b000011110000;//color verde
	end
	else if (row_cnt<120)begin//cuando se superan las 105 lineas pero esta por debajo de las 120 (media seccion de 15 depues de las 105 lineas)
	colorRGB444=12'b111100001111;//color rosa
	end
	end
	*/
	/*simulacion de color(propuesta 2)
	//registros de simulacion del color
    	reg cont=0;
    	parameter[3:0]R=4'b0000; //rojo del pixel RRRR
    	parameter[3:0]G=4'b0000; //verde del pixel GGGG
    	parameter[3:0]B=4'b0000; //azul del pixel BBBB
    	reg [11:0]colorRGB444= {R[3:0],G[3:0],B[3:0]}; //color RRRR GGGG BBBB,first byte= XXXX RRRR, second byte= GGGG BBBB
	//asignacion del color
	always @(posedge pclk) begin
	cont=cont+1;
	if (cont ==0)begin//first Byte
	CAM_px_data[3:0]=colorRGB444[11:8];
	end
	if(cont == 1)begin//second Byte
	CAM_px_data = colorRGB444[7:0];
	end
	end
	*/
	// Color azul
/*	reg cont=0;   

    initial forever  begin
		@(negedge pclk) begin
            if(cont==0) begin 
                CAM_px_data<=8'h0;
            end
            else begin
                CAM_px_data<=8'h0f;
            end
			cont=cont+1;
         end
	end
 */

// Color rojo.

/*
reg cont=0;   

    initial forever  begin
		@(negedge pclk) begin
            if(cont==0) begin 
                CAM_px_data<=8'h0f;		// First byte red.
            end
            else begin
                CAM_px_data<=8'h00;		// Second byte 
            end
			cont=cont+1;
         end
	end
*/
// Azul y verde cada dos pixeles.
	reg [2:0]cont=0;   

    initial forever  begin
		@(negedge pclk) begin
            if(~CAM_href) cont=0;			// Cada vez que termina una fila Negro. 

            if(cont==0|cont==2) begin		// First byte Black
                CAM_px_data<=8'h0;
            end
            else if(cont==1|cont==3) begin	// Second byte blue.
                CAM_px_data<=8'h0f;
            end
            else if(cont==4|cont==6) begin	// Black first byte.
                CAM_px_data<=8'h00;
            end
            else if(cont==5|cont==7) begin	// Green second byte.
                CAM_px_data<=8'hf0;
            end
			cont=cont+1;
         end
	end
	*/
	/* Simulacion de contador de pixeles para generar Href y vsync. */
	initial forever  begin
	    //CAM_px_data=~CAM_px_data;
		@(posedge pclk) begin
		if (img_generate==1) begin	// Mientras se genere una imagen.
			line_cnt=line_cnt+1;	// Cada pclk aumenta line_cnt.
			if (line_cnt >TAM_LINE-1+BLACK_TAM_LINE) begin	// Termina una fila.
				line_cnt=0;									// Reinicia contador.
				row_cnt=row_cnt+1;							// Aumenta numero de fila.
				if (row_cnt>TAM_ROW-1+BLACK_TAM_ROW) begin	// Termina de recorrer todas las filas.
					row_cnt=0;								// Empieza de nuevo.
				end
			end
		end
		end
	end
	/*simulaci�n de la se�al vsync generada por la camara*/
	initial forever  begin
		@(posedge pclk) begin
            if (img_generate==1) begin
                    if (row_cnt==0)begin	// Antes del delay previo a la primera fila, no comparte. 
                        CAM_vsync  = 1;
                    end
                if (row_cnt==BLACK_TAM_ROW/2)begin
                    CAM_vsync  = 0;			// row_cnt = 2, luego del delay, empieza a compartir.
                end
            end
		end
	end
	/*simulaci�n de la se�al href generada por la camara*/
	initial forever  begin
		@(negedge pclk) begin
            if (img_generate==1) begin
                if (row_cnt>BLACK_TAM_ROW-1)begin // Como es negedge. Ya paso dos posedge, parte negra antes compartir href.
                    if (line_cnt==0)begin
                        CAM_href  = 1;			  // Empieza fila.
                    end
                end
                if (line_cnt==TAM_LINE)begin
                    CAM_href  = 0;				// debe empezar nueva fila.
                end
            end
		end
	end
	/* log para cargar de archivo*/
	integer f;
	initial begin
      f = $fopen(d,"w");
   end
	reg clk_w =0;
	always #1 clk_w  = ~clk_w;
	/* ecsritura de log para cargar se cargados en https://ericeastwood.com/lab/vga-simulator/*/
	initial forever begin
	@(posedge clk_w)
		$fwrite(f,"%0t ps: %b %b %b %b %b\n",$time,VGA_Hsync_n, VGA_Vsync_n, VGA_R[3:0],VGA_G[3:0],VGA_B[3:0]); // En binario VGA sync and RGB.
	end
endmodule
```
##### cambios
El cambio mas significativo aplicado para la prueba en la implementacion fue el simular las 8 señales que proporcionaria la camara para eso se creo registro `CAM_px_data` de 8 bits y cada bit pertenece a una señal.
```verilog
reg [7:0] CAM_px_data;
//
//
//
	assign CAM_D0=CAM_px_data[0]; 
	assign CAM_D1=CAM_px_data[1];
	assign CAM_D2=CAM_px_data[2];
	assign CAM_D3=CAM_px_data[3];
	assign CAM_D4=CAM_px_data[4];
	assign CAM_D5=CAM_px_data[5];
	assign CAM_D6=CAM_px_data[6];
	assign CAM_D7=CAM_px_data[7];
```
Estas señales se actualizan constantemente mediante el comando `assign`.

La señal de salida `CAM_px_data(CAM_px_data)`
```verilog
test_cam uut (
		.clk(clk),
		.rst(rst),
		.VGA_Hsync_n(VGA_Hsync_n),
		.VGA_Vsync_n(VGA_Vsync_n),
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B),
		// se???ales de prueba *******************************************
	   .data_mem(data_mem),
	   .DP_RAM_addr_in(DP_RAM_addr_in),
	   .DP_RAM_data_in(DP_RAM_data_in),
	   .DP_RAM_addr_out(DP_RAM_addr_out),
		//Prueba *******************************************
		.CAM_xclk(CAM_xclk),
		.CAM_pwdn(CAM_pwdn),
		.CAM_reset(CAM_reset),
		.CAM_pclk(pclk),
		.CAM_vsync(CAM_vsync),
		.CAM_href(CAM_href),

		.CAM_px_data(CAM_px_data)
	);
```
fue remplavada por `CAM_D0 a CAM_D7`. 
```verilog
test_cam uut (
		.clk(clk),
		.rst(rst),
		.VGA_Hsync_n(VGA_Hsync_n),
		.VGA_Vsync_n(VGA_Vsync_n),
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B),
		.CAM_xclk(CAM_xclk),
		.CAM_pwdn(CAM_pwdn),
		.CAM_reset(CAM_reset),
		.CAM_pclk(pclk),
		.CAM_vsync(CAM_vsync),
		.CAM_href(CAM_href),

		.CAM_D0(CAM_D0),
        .CAM_D1(CAM_D1),   
        .CAM_D2(CAM_D2),   
        .CAM_D3(CAM_D3),
        .CAM_D4(CAM_D4),
        .CAM_D5(CAM_D5),
        .CAM_D6(CAM_D6),
        .CAM_D7(CAM_D7) 
    );
	```

