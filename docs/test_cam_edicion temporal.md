### Análisis de Módulo `test_cam.v`

Las señales amarillas de la Figura 2, se sustituyen por las señales rojas de la Figura 19, estas señales rojas emulan las proporcionadas por la cámara. Este esquema de simulación nos permite evaluar que todos los módulos funcionen adecuadamente una vez se logre implementar todo el proyecto. 

![Diagrama_test](./figs/Esquema.png)

*Figura 19. Diagrama de simulación*

Dado que el módulo test_cam.v es proporcionado por el docente, a continuacion se  presentan todos los cambios que se desarrollan en el mismo con la finalidad de desarrollar el sistema del presente trabajo con exito. 
#### módulo `test_cam.v` proporcionado por el docente (módulo presente en el paquete de trabajo 2 _work2-capturaDatos_)
```verilog
`timescale 1ns / 1ps
module test_cam(
    input wire clk,           // board clock: 32 MHz quacho/ 100 MHz nexys4 
    input wire rst,         	// reset button
	// VGA input/output  
    output wire VGA_Hsync_n,  // horizontal sync output
    output wire VGA_Vsync_n,  // vertical sync output
    output wire [3:0] VGA_R,	// 4-bit VGA red output
    output wire [3:0] VGA_G,  // 4-bit VGA green output
    output wire [3:0] VGA_B,  // 4-bit VGA blue output
	//cámara input/output
	output wire CAM_xclk,		// System  clock imput
	output wire CAM_pwdn,		// power down mode 
	output wire CAM_reset,		// clear all registers of cam
	// colocar aqui las entras  y salidas de la cámara  que hace falta
	input wire CAM_pclk,
	input wire CAM_vsync,
	input wire CAM_href,
	input wire [7:0] CAM_px_data
   /* **********************************************************************************
   En una version antigua del módulo, version final proporcionada en semestres pasados
   se encontraba el siguiente segmento de codigo, este representa las señales reales 
   proporcionados por la cámara,esta senal compone lo que es la senal CAM_px_data
   ********************************************************************************** */
    /*
    input CAM_D0,                   // Bit 0 de los datos del píxel
    input CAM_D1,                   // Bit 1 de los datos del píxel
    input CAM_D2,                   // Bit 2 de los datos del píxel
    input CAM_D3,                   // Bit 3 de los datos del píxel
    input CAM_D4,                   // Bit 4 de los datos del píxel
    input CAM_D5,                   // Bit 5 de los datos del píxel
    input CAM_D6,                   // Bit 6 de los datos del píxel
    input CAM_D7                    // Bit 7 de los datos del píxel
   */
);
// TAMAÑO DE ADQUISICIÓN DE LA cámara 
parameter CAM_SCREEN_X = 160;
parameter CAM_SCREEN_Y = 120;
localparam AW = 15; // LOG2(CAM_SCREEN_X*CAM_SCREEN_Y)
localparam DW = 12;
// El color es RGB 332
localparam RED_VGA =   8'b11100000;
localparam GREEN_VGA = 8'b00011100;
localparam BLUE_VGA =  8'b00000011;
// Clk 
wire clk32M;
wire clk25M;
wire clk24M;
// Conexión dual por ram
wire  [AW-1: 0] DP_RAM_addr_in;  
wire  [DW-1: 0] DP_RAM_data_in;
wire DP_RAM_regW;
reg  [AW-1: 0] DP_RAM_addr_out;  
// Conexión VGA Driver
wire [DW-1:0]data_mem;	   // Salida de dp_ram al driver VGA
wire [DW-1:0]data_RGB332;  // salida del driver VGA al puerto
wire [9:0]VGA_posX;		   // Determinar la pos de memoria que viene del VGA
wire [8:0]VGA_posY;		   // Determinar la pos de memoria que viene del VGA
/* ****************************************************************************
la pantalla VGA es RGB 444, pero el almacenamiento en memoria se hace 332
por lo tanto, los bits menos significactivos deben ser cero
**************************************************************************** */
	assign VGA_R = data_RGB332[11:8];
	assign VGA_G = data_RGB332[7:4];
	assign VGA_B = data_RGB332[3:0];
/* ****************************************************************************
Asignación de las señales de control xclk pwdn y reset de la cámara 
**************************************************************************** */
assign CAM_xclk=  clk24M;
assign CAM_pwdn=  0;			// power down mode 
assign CAM_reset=  0;
/* ****************************************************************************
  Este bloque se debe modificar según sea le caso. El ejemplo esta dado para
  fpga Spartan6 lx9 a 32MHz.
  usar "tools -> Core Generator ..."  y general el ip con Clocking Wizard
  el bloque genera un reloj de 25Mhz usado para el VGA  y un relo de 24 MHz
  utilizado para la cámara , a partir de una frecuencia de 32 Mhz
**************************************************************************** */
//assign clk32M =clk;
clk24_25_nexys4
  clk25_24(
  .CLK_IN1(clk),
  .CLK_OUT1(clk25M),
  .CLK_OUT2(clk24M),
  .RESET(rst)
 );
/* ****************************************************************************
buffer_ram_dp buffer memoria dual port y reloj de lectura y escritura separados
Se debe configurar AW  según los calculos realizados en el Wp01
se recomiendia dejar DW a 8, con el fin de optimizar recursos  y hacer RGB 332
**************************************************************************** */
buffer_ram_dp #( AW,DW)
	DP_RAM(  
	.clk_w(CAM_pclk), 
	.addr_in(DP_RAM_addr_in), 
	.data_in(DP_RAM_data_in),
	.regwrite(DP_RAM_regW), 
	.clk_r(clk25M), 
	.addr_out(DP_RAM_addr_out),
	.data_out(data_mem)
	);
/* ****************************************************************************
VGA_Driver640x480
**************************************************************************** */
VGA_Driver640x480 VGA640x480
(
	.rst(rst),
	.clk(clk25M), 				// 25MHz  para 60 hz de 640x480
	.píxelIn(data_mem), 		// entrada del valor de color  píxel RGB 332 
	.píxelOut(data_RGB332), // salida del valor píxel a la VGA 
	.Hsync_n(VGA_Hsync_n),	// señal de sincronizaciÓn en horizontal negada
	.Vsync_n(VGA_Vsync_n),	// señal de sincronizaciÓn en vertical negada 
	.posX(VGA_posX), 			// posición en horizontal del píxel siguiente
	.posY(VGA_posY) 			// posición en vertical  del píxel siguiente
);
/* ****************************************************************************
LÓgica para actualizar el píxel acorde con la buffer de memoria y el píxel de 
VGA si la imagen de la cámara es menor que el display  VGA, los píxeles 
adicionales seran iguales al color del último píxel de memoria 
**************************************************************************** */
always @ (VGA_posX, VGA_posY) begin
		if ((VGA_posX>CAM_SCREEN_X-1) || (VGA_posY>CAM_SCREEN_Y-1))
			DP_RAM_addr_out=15'b111111111111111;
		else
			DP_RAM_addr_out=VGA_posX+VGA_posY*CAM_SCREEN_Y;
end
/*****************************************************************************
**************************************************************************** */
 cam_read #(AW)ov7076_565_to_332(
		.pclk(CAM_pclk),
		.rst(rst),
		.vsync(CAM_vsync),
		.href(CAM_href),
		.px_data(CAM_px_data),

		.mem_px_addr(DP_RAM_addr_in),
		.mem_px_data(DP_RAM_data_in),
		.px_wr(DP_RAM_regW)
   );
 /* *********************************************************************************************
   En una version antigua del módulo, version final proporcionada en semestres pasados
   se encontraba el siguiente segmento de codigo, este representa el instanciamiento del
   módulo cam_read en ese momento concido como captura_de_datos_downsampler 
   donde la senal "D7-D0" es la senal de datos del color del píxel proporcionada por la cámara.
 ********************************************************************************************* */
 //captura_de_datos_downsampler Capture_Downsampler(
//	.PCLK(CAM_PCLK),
//	.HREF(CAM_HREF),
//	.VSYNC(CAM_VSYNC),
//	.D0(CAM_D0),
//	.D1(CAM_D1),
//	.D2(CAM_D2),
//	.D3(CAM_D3),
//	.D4(CAM_D4),
//	.D5(CAM_D5),
//	.D6(CAM_D6),
//	.D7(CAM_D7),
//	.DP_RAM_data_in(DP_RAM_data_in),
//	.DP_RAM_addr_in(DP_RAM_addr_in),
//	.DP_RAM_regW(DP_RAM_regW)
//	);
endmodule
```
#### módulo `test_cam.v` resultado final
```verilog
`timescale 10ns / 1ns		// Se puede cambiar por `timescale 1ns / 1ps.
// test_cam Main del proyeco
// se instanciaron los siguientes módulos: Captura de datos(cam_read), RAM,Divisor de freuencia PLL, driver_ VGA
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
	output reg  [14:0] DP_RAM_addr_out,	//Registro Captura de datos a DP_RAM DirecciÃ³n en memoria 
    // Salidas de cam_read.v
    output wire [14:0] DP_RAM_addr_in,     //Cable Captura de datos a DP_RAM DirecciÃ³n de memoria lectura 
	output wire [11:0] DP_RAM_data_in,	//Cable Captura de datos a DP_RAM Datos a guardar en la direcciÃ³n de memoria 	
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
	.regwrite(DPRAM_regW), 	       	// Enable.
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
#### Analisis de los cambios, adiciones y eliminaciones  
Para poder usar el módulo test_cam.v era necesario hacer cambios al módulo proporcionado por el docente en el _Work2-caprutaDatos_
estos cambios incluyen:

* Declaracion de senales faltantes

* Instanciamiento del módulo cam_read.v(el cual no estaba instanciado dado a que era el módulo a diseñar).

* Modificacion de parámetros
##### Señales de de entrada y salida
Estas son las senales que ingresan en el módulo y las senales  que salen del módulo gracias al control interno de las señales de entrada
###### Señales de entrada 
```verilog
//Entradas del test cam
    input wire clk,           	// Board clock: 100 MHz Nexys4DDR.
    input wire rst,	 	// Reset button. Externo
```
La declaracion de estas señales no fue modificada en el codigo sin embargo la señal del reloj (clk) es necesario tenerla encuenta ya que esta depende de la FPGA a trabajar (en este proyecto se trabajo con una `Nexys4DDR` el cual posee un reloj interno de 100Mhz).

###### Señales de salida
```verilog
    output wire VGA_Hsync_n,  // Horizontal sync output.
    output wire VGA_Vsync_n,  // Vertical sync output.
    output wire [3:0] VGA_R,  // 4-bit VGA red output.
    output wire [3:0] VGA_G,  // 4-bit VGA green output.
    output wire [3:0] VGA_B,  // 4-bit VGA blue output.
```
Estas son las senales que salen del módulo, las senales VGA_R,VGA_G,VGA_B
se pueden apreciar en la Figura 19. como las senales que salen del bloque RGB_444
el cual es un bloque interno del módulo `test_cam.v`.
Aunque las señales VGA_Hsync_n,VGA_Vsync_n salen del módulo`Driver_VAGA.v`(Figura 19.) a su vez salen del módulo `test_cam.v` por lo tanto se definen como señales de salida de este módulo.
###### Conexiones internas, señales de control y registros
Estas conexiones son las conexiones escenciales entre los módulos internos que componen el módulo `test_cam.v`.

* Conexiones del módulo `Driver_VGA`

```verilog
    output wire clk25M, // 25MHz de la VGA
    output wire [11:0] data_mem,           //Cable de DP_RAM a VGA 640X480
    output reg  [14:0] DP_RAM_addr_out,	//Registro Captura de datos a DP_RAM Direccion en memoria 
``` 
Como se puede apreciar en la Figura 19. el módulo `Driver_VGA.v` intercambia dos senales con el módulo `buffer_ram_dp.v` las culaes son data_mem el cual es una señal la cual lleva el registro de color de los píxeles en la memoria, y DP_RAM_addr_out, que como se puede apreciar en la Figura 19 esta señal sale del bloque `convert addr`(ese es un segmento de codigo interno en el módulo `test_cam.v`) y esta señal lleva con sigo el dato de la posición del píxel al cual se le assigna un color.

* Conexiones del módulo `cam_read.v`

```verilog
 output wire [14:0] DP_RAM_addr_in,     //Cable Captura de datos a DP_RAM DirecciÃ³n de memoria lectura 
	output wire [11:0] DP_RAM_data_in,	//Cable Captura de datos a DP_RAM Datos a guardar en la direcciÃ³n de memoria 	
    output wire DP_RAM_regW, // Indica cuando un píxel esta completo.
```
Estas señales son las que llevan los datos originales del píxel en la imagen(su color y su posición) y la señal de control que informa cuando los datos de un píxel se han transferido completamente.

* Conexiones de la cámara ya sea fisica o simulada
```verilog
    output wire CAM_xclk,		// System  clock input de la cÃ¯Â¿Â½mara.
	output wire CAM_pwdn,		// Power down mode.
	output wire CAM_reset,		// Clear all registers of cam.
	input wire CAM_pclk,		// Sennal PCLK de la cámara. 
	input wire CAM_href,		// Sennal HREF de la cámara. 
	input wire CAM_vsync,		// Sennal VSYNC de la cámara.
	input wire [7:0] CAM_px_data// Datos de entrada simulados 
```
Estos datos son proporcionados por la cámara e informan los valores originales generados por la cámara para cada píxel como lo es su referencia horizontal(posición horizontal) su sincronizacion vertical (informa del cambio en la posición vertival de una linea de píxeles) su dato de píxel(bus de datos que representa un color para un píxel).
Posee tres señales que entran en la cámara y salen del módulo `test_cam.v` y se pueden apreciar en la Figura 19, como el bloque interno `xclk/pwdn/reset`
los cuales se encargan de suministrar una señal para la cámara 

Power down mode : es una señal la cual al acivarse hace que la cámara disminuya las tensiones internas de esta exceptuando el reloj interno, gracias a esto la cmara no puede refrescar su memoria interna. Este modo es un modo de ahorro de energia/ bloqueo en el refresh de la memoria.

Reset: es una señal la cual indica a la cámara regresar a sus valores por defecto.

XCLK:reloj de la cámara de 24Mhz.

###### Registros, parámetros y señales internas del Módulo `test_cam.v`

En esta segccion del codigo se hace el tratamiento a las señales de entrada al módulo para transformarlas en las señales de salida, con ayuda de unos parameros locales los cuales son definidos segun las caracteristicas de la imagen.

* parámetrosy parámetros locales
```verlog
parameter CAM_SCREEN_X = 160; 		// 640 / 4. Elegido por preferencia, menos memoria usada.
parameter CAM_SCREEN_Y = 120;    	// 480 / 4.

localparam AW=15; // Se determina de acuerdo al tamaÃ±o de de la direcciÃ³n, de acuerdo a l arreglo de píxeles dado por el formato en este caso Log(2)(160*120)=15
localparam DW=12; // Se determina de acuerdo al tamaÃ±o de la data, formaro RGB444 = 12 bites.

localparam imaSiz= CAM_SCREEN_X*CAM_SCREEN_Y;// PosiciÃ³n n+1 del tamaÃ±p del arreglo de píxeles de acuerdo al formato.
```
Los parámetros CAM_SCREEN representan los valores de tamaño de la imagen capturada por la cámara(160X120)

El parámetro AW representa la cantidad de bits necesarios para representar las posciones de un píxel en la resolucion de 160x120=19.200 y la cantidad de bits necesarios para representar este numero =15

El parámetro DW representa el tamaño del color del píxel como el color es RGB444 osea 4bits en rojo,4 en verde y cuatro en azul se necesitan 12 bits para representar este espectro e color.

El parámetro imaSiz representa el final de el arreglo de dos dimensiones de 160x120 el cual va del 0 al 19.199 para un total de 19.200 posiciónes, imaSiz es la posición 19.200 del arreglo usada para almacenar aquellas posiciónes encontradas despues de que todo el arreglo de bits este completo.

* Señales
relojes:son los relojes de la FPGA(100MHZ),la cámara(24MHZ) y la pantalla VGA(25MHZ)
```verilog
wire clk100M;           // Reloj de un puerto de la Nexys 4 DDR entrada.
wire clk25M;	// Para guardar el dato del reloj de la Pantalla (VGA 680X240 y DP_RAM).
wire clk24M;		// Para guardar el dato del reloj de la cámara.
```
Valores del píxel: como se menciona anterior mente representan la posición y el tamaño de un píxel y la señal que representa que este píxel esta teminado.
```verilog
wire [AW-1: 0] DP_RAM_addr_in;		// ConexiÃ³n  Direccion entrada.
wire [DW-1: 0] DP_RAM_data_in;      	// Conexion Dato entrada.
wire DP_RAM_regW;
```
Conexiones a la pantalla VGA: son las señales del módulo `VGA_Driver`
```verilog
wire [DW-1:0] data_mem;	    		// Salida de dp_ram al driver VGA
wire [DW-1:0] data_RGB444;  		// salida del driver VGA a la pantalla
wire [9:0] VGA_posX;			// Determinar la posiciÃ³n en X del píxel en la pantalla 
wire [9:0] VGA_posY;			// Determinar la posiciÃ³n de Y del píxel en la pantalla
```
estos valores se encargan de enviar la informacion a la pantalla VGA 

El data_mem es el valor de color del píxel

El data_RGB444 es el valor de color que se va a transferir a la pantalla

Los valores posX y posY son la posición del píxel en la pantalla VGA

* assignaciones : son asiganciones de valores que se ejecutan constatntemente.
```verilog
assign VGA_R = data_RGB444[11:8]; 	//los 4 bites mÃ¡s significativos corresponden al color ROJO (RED) 
assign VGA_G = data_RGB444[7:4];  	//los 4 bites siguientes son del color VERDE (GREEN)
assign VGA_B = data_RGB444[3:0]; 	//los 4 bites menos significativos son del color AZUL(BLUE)
assign CAM_xclk = clk24M;		// AsignaciÃƒÂ³n reloj cÃƒÂ¡mara.
assign CAM_pwdn = 0;			// Power down mode.
assign CAM_reset = 0;			// Reset cÃƒÂ¡mara.
```
Estos valores son igualdades que se ejecutan constantemente

Data_RGB444 es asignado a los colores de la pantalla VGA

CAM_xclk es el reloj de 24MHZ del módulo `clk25_24`

Las señales CAM_pwdn y CAM_reset se mantienen en ceros debido a que no son necesarias 

##### Actualizacion del píxel
```verilog
always @ (VGA_posX, VGA_posY) begin
		if ((VGA_posX>CAM_SCREEN_X-1)|(VGA_posY>CAM_SCREEN_Y-1))
			//Posición n+1(160*120), en buffer_ram_dp.v se le asigna el color negro.
			DP_RAM_addr_out = imaSiz;
		else
			DP_RAM_addr_out = VGA_posX + VGA_posY * CAM_SCREEN_X;// Calcula posición.
end
endmodule
```
La actualizacion del píxel es el segmento de codigo que se encarga de calcular la posición de salida del píxel.

###### Instanciamiento de módulos 
En esta seccion se
* clk25_24: Instanciamiento del módulo del reloj diseñado memoria Clocking Wizard
```verilog
clk24_25_nexys4 clk25_24(
  .clk100M(clk),				//Reloj de la FPGA.
  .clk25M(clk25M),			//Reloj de la VGA.
  .clk24M(clk24M),			//Reloj de la cámara.
  .reset(rst)					//Reset.
 );
 ```
* Módulo cam_read.v: módulo que lee los valores de la cámara de color de la cámara
```verilog
cam_read #(AW,DW) cam_read
(
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
```

* Módulo buffer_ram_dp.v : módulo del buffer de memoria que almacena los valores del píxel de la imagen capurada por la cámara
```verilog
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
```
* Módulo VGA_Driver.v : para una pantalla de 640x480
```verilog
VGA_Driver VGA_640x480 // Necesitamos otro driver.
(
	.rst(rst),
	.clk(clk25M), 				// 25MHz  para 60 hz de 160x120.
	.píxelIn(data_mem), 		// Entrada del valor de color  píxel RGB 444.
	.píxelOut(data_RGB444),		// Salida de datos a la VGA. (píxeles). 
	.Hsync_n(VGA_Hsync_n),		// Sennal de sincronizacion en horizontal negada para la VGA.
	.Vsync_n(VGA_Vsync_n),		// Sennal de sincronizacion en vertical negada  para la VGA.
	.posX(VGA_posX), 			// Posición en horizontal del píxel siguiente.
	.posY(VGA_posY) 			// posicinn en vertical  del píxel siguiente.

);
```





