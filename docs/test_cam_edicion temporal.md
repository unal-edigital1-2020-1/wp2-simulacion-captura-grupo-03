Las señales amarillas de la Figura 2, se sustituyen por las señales rojas de la Figura 19, las senales en rojo emulan las senales en amarillo proporcionadas por la camara. Este esquema de simulación nos permite evaluar que todos los módulos funcionen adecuadamente una vez se logre implementar todo el proyecto. 

![Diagrama_test](./figs/Esquema.png)

*Figura 19. Diagrama de simulación*

En el módulo test_cam podemos observar que se compone del conjunto de módulos:

* cam_read.v
* clk24_25_nexys4.v
* buffer_ram_dp.v
* VGA_Driver.v (incluye el Módulo de convert addr)

Las señales de entrada y salida de este módulo son las conexiones de los modulos internos (conjunto de modulos que componen el modulo `test_cam.v`) y los externos ya sean las simulaciones de la cámara y la pantalla VGA o los componentes en fisico (la cámara y la pantalla).

#### Señales de de entrada y salida

* Señales de entrada 

Se sustituyó:
```verilog
	input CAM_PCLK,				// Sennal PCLK de la camara
	input CAM_HREF,				// Sennal HREF de la camara
	input CAM_VSYNC,				// Sennal VSYNC de la camara
``` 
Por:

```verilog
	input wire CAM_pclk,		// Sennal PCLK de la camara. 
	input wire CAM_href,		// Sennal HREF de la camara. 
	input wire CAM_vsync,		// Sennal VSYNC de la camara.
```
Para que fueran coherentes las entradas con la Figura 19.

Por otra parte, las entradas de los datos de la cámara,

```verilog
	input CAM_D0,					// Bit 0 de los datos del pixel
	input CAM_D1,					// Bit 1 de los datos del pixel
	input CAM_D2,					// Bit 2 de los datos del pixel
	input CAM_D3,					// Bit 3 de los datos del pixel
	input CAM_D4,					// Bit 4 de los datos del pixel
	input CAM_D5,					// Bit 5 de los datos del pixel
	input CAM_D6,					// Bit 6 de los datos del pixel
	input CAM_D7 					// Bit 7 de los datos del pixel
``` 

Fueron sustituidos por:

```verilog
input wire [7:0] CAM_px_data// Datos de entrada simulados
```
Ya que al simular se proporcionaba un bus de 8 bits.


* Señales de salida

Durante la simulación fue necesario agregar las siguientes señales de salida para comprobar el correcto funcionamiento de los distintos módulos intanciados, estas son:

```verilog 
    output wire clk25M, // 25MHz de la VGA
	output wire [14:0]  DP_RAM_addr_in,
	output wire [11:0] DP_RAM_data_in,
    output wire DP_RAM_regW, // Indica cuando un pixel esta completo.
	output wire [11:0] data_mem,	
	output reg [14:0] DP_RAM_addr_out,
``` 
* `clk25M` reloj de 25 MHz para la VGA_Driver

* Las señales `DP_RAM_data_in` y `DP_RAM_addr_in` son salidas del módulo `cam_read.v` que llevan los datos y las posiciones que utiliza el módulo `buffer_ram_dp.v` para almacenar temporalmente las capturas. `DP_RAM_data_in` puede ser escrito en `buffer_ram_dp.v` solo cuando `DP_RAM_regW` se lo permita, esto es cuando está en 1. 

* `data_mem` es el pixel de 12 bits que el módulo `buffer_ram_dp` le transfiere al módulo `VGA_Driver.v` en la ubicación `DP_RAM_addr_out`.

Finalmente, las entradas y salidas de módulo **test_cam** quedaron de la siguiente manera:

```verilog
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
	output reg  [14:0] DP_RAM_addr_out,	//Registro Captura de datos a DP_RAM Dirección en memoria 
    
    // Salidas de cam_read.v
    
    output wire [14:0] DP_RAM_addr_in,     //Cable Captura de datos a DP_RAM Dirección de memoria lectura 
	output wire [11:0] DP_RAM_data_in,	//Cable Captura de datos a DP_RAM Datos a guardar en la dirección de memoria 	
    output wire DP_RAM_regW, // Indica cuando un pixel esta completo.

	//CAMARA input/output conexiones de la camara al modulo principal ********************************

	output wire CAM_xclk,		// System  clock input de la cï¿½mara.
	output wire CAM_pwdn,		// Power down mode.
	output wire CAM_reset,		// Clear all registers of cam.
	input wire CAM_pclk,		// Sennal PCLK de la camara. 
	input wire CAM_href,		// Sennal HREF de la camara. 
	input wire CAM_vsync,		// Sennal VSYNC de la camara.
	input wire [7:0] CAM_px_data// Datos de entrada simulados 
```

##### Conexiones internas, señales de control y registros
Diferencias con la version original del módulo:

Este fragmento de codigo fue agregado a las señales presentes en el modulo.
```verilog
	output wire [11:0] data_mem,		//Conexión de buffer_ram_dp.v a VGA_Driver.v
	output reg  [14:0] DP_RAM_addr_out,	//Registro con las direcciones de los datos asociados a un pixel(valor del color RGB444)
```

* Conexiones de salida del módulo cam_read.v a buffer_ram_dp.v

Diferencias con la version original del módulo:

Este fragmento es agregado al codigo (dado a que el cam_read.v debe de ser 
diseñado/creado estas conexiones/señales no estan presentes el en original)

```verilog
    
	output wire [14:0] DP_RAM_addr_in,     //Señal que envia los datos de la dirección donde se encuentra el pixel RGB444
	output wire [11:0] DP_RAM_data_in,	//Señal con el valor de color del pixel RGB444 en la dirección de memoria 	
	output wire DP_RAM_regW,	//Señal de control la cual indica cuando un pixel esta completo.
```
* Entradas y Salidas de la camara (ya sea física o del módulo de simulación de la cámara)

Diferencias con la versión original del módulo:

Ninguna al codigo.



Se agregaron comentarios a algunas señales que no los tenían.
```verilog
	output wire CAM_xclk,		// System  clock input de la camara.
	output wire CAM_pwdn,		// Power down mode.
	output wire CAM_reset,		// Clear all registers of cam.
	input wire CAM_pclk,		// Señal PCLK de la camara. 
	input wire CAM_href,		// Señal HREF de la camara. 
	input wire CAM_vsync,		// Señal VSYNC de la camara.
	input wire [7:0] CAM_px_data	// Datos de salida de la camara (ya sean simulados o valores enviados por la captura de imagen de la camara.
	);
```
* Registros y señales internos del Módulo `test_cam.v`

Diferencias con la version original del módulo:

Se cambiaron algunos nombres de algunas conexiones y se eliminaron los parametros locales relacionados al color RGB332 presentes en el modulo original.

Se agregaron comentarios a algunas señales,registros y asignaciones que no los tenian.
```verilog
//Tamaño de la imagen seleccionado por su bajo requisito de memoria 
parameter CAM_SCREEN_X = 160; 		// 640 / 4. 
parameter CAM_SCREEN_Y = 120;    	// 480 / 4.

localparam AW=15; //Se determina de acuerdo al tamaño de la resolución Log(2)(160*120)=15
localparam DW=12; //Se determina de acuerdo al tamaño del dato del formato de color RGB444 = 12 bites.

```
En esta seccion del codigo se eliminaron los parametros locales del color RGB332 porque en se opto por usar la configuracion de color RGB444.
```verilog
localparam RED_VGA =   8'b11100000;//eliminado
localparam GREEN_VGA = 8'b00011100;//eliminado
localparam BLUE_VGA =  8'b00000011;//eliminado
```
Aqui se modificaron los nombre de:

El nombre del reloj clk32M a clk100M (dado a que el reloj de la nexys 4 usado es de 100Mhz).

El nombre de la conexion data_RGB332 a data_RGB444(dado a que se opto por la configuracion en la camara de RGB444).

Se agrego el parameto local imaSiz (que representa la posicion n+1 de la imagen)
```verilog
// conexiondes del clk24_25_nexys4.v
wire clk100M;           // Reloj de un puerto de la Nexys 4 DDR entrada.
wire clk25M;// Para guardar el dato del reloj de la Pantalla (VGA 680X240 y DP_RAM).
wire clk24M;		// Para guardar el dato del reloj de la camara.
// Conexion dual por ram
localparam imaSiz= CAM_SCREEN_X*CAM_SCREEN_Y;// Posición n+1 del tamaño del arreglo de pixeles de acuerdo al formato.
wire [AW-1: 0] DP_RAM_addr_in;		// Conexión  Direccion entrada.
wire [DW-1: 0] DP_RAM_data_in;      	// Conexion Dato entrada.
wire DP_RAM_regW;			// Enable escritura de dato en memoria .
reg  [AW-1: 0] DP_RAM_addr_out;		//Registro de la dirección de memoria.

// Conexion VGA Driver
wire [DW-1:0] data_mem;	    		// Salida de dp_ram al driver VGA
wire [DW-1:0] data_RGB444;  		// salida del driver VGA a la pantalla
wire [9:0] VGA_posX;			// Determinar la posición en X del pixel en la pantalla 
wire [9:0] VGA_posY;			// Determinar la posición de Y del pixel en la pantalla
```
Aqui tambien se modificó el nombre de la conexion data_RGB332 a data_RGB444.
```verilog
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
```
* instanciamiento de modulos 

Diferencias con la version original del módulo:

Se modifico por completo el bloque del cam_read.v

Se agregaron comentarios a las señales de cada bloque.


Aqui se agregaron comentarios a cada señal.
```verilog
/* ****************************************************************************
   Se uso "IP Catalog >FPGA Features and Desing > Clocking > Clocking Wizard"  y general el ip con Clocking Wizard
  el bloque genera un reloj de 25Mhz usado para el VGA  y un reloj de 24 MHz
  utilizado para la camara , a partir de una frecuencia de 100 Mhz que corresponde a la Nexys 4
**************************************************************************** */
clk24_25_nexys4 clk25_24(
  .CLK_IN1(clk),				//Reloj de la FPGA.
  .CLK_OUT1(clk25M),				//Reloj de la VGA.
  .CLK_OUT2(clk24M),				//Reloj de la cÃ¡mara.
  .RESET(rst)					//Reset.
 );
 ```
Este bloque fue modificado completamente con respecto al de la version original dada la forma en la que se diseño del modulo cam_read.v
 ```verilog
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
```
Aqui solo se agregaron comentarios a cada señal.
```verilog
/* ****************************************************************************
buffer_ram_dp buffer memoria dual port y reloj de lectura y escritura separados
Se debe configurar AW  segn los calculos realizados en el Wp01
**************************************************************************** */
buffer_ram_dp DP_RAM(
		// Entradas.
	.clk_w(CAM_pclk),	//Frecuencia de toma de datos de cada pixel.
	.addr_in(DP_RAM_addr_in),// Direccion entrada dada por el capturador.
	.data_in(DP_RAM_data_in),		// Datos que entran de la cÃ¡mara.
	.regwrite(DP_RAM_regW), 		// Enable.
	.clk_r(clk25M), 				// Reloj VGA.
	.addr_out(DP_RAM_addr_out),// Direccion salida dada por VGA.
		// Salida.
	.data_out(data_mem)			// Datos enviados a la VGA.
	//.reset(rst)                   //(Sin usar)
);
/* ****************************************************************************
VGA_Driver640x480
**************************************************************************** */
VGA_Driver VGA_640x480
(
	.rst(rst),
	.clk(clk25M), 				// 25MHz  para 60 hz de 160x120
	.pixelIn(data_mem),	// Entrada del valor de color  pixel RGB 444.
	.pixelOut(data_RGB444),		// Salida del datos a la VGA. (Pixeles). 
	.Hsync_n(VGA_Hsync_n),	// Sennal de sincronizacion en horizontal negada para la VGA.
	.Vsync_n(VGA_Vsync_n),	// Sennal de sincronizacion en vertical negada  para la VGA.
	.posX(VGA_posX), // Posicion en horizontal del pixel siguiente.
	.posY(VGA_posY) 			// posicinn en vertical  del pixel siguiente.
);
```
* Actualizacion del pixel

Diferencias con la version original del módulo:

Se modifico la igualdad del DP_RAM_addr_out dentro del la condicion if,de
DP_RAM_addr_out=15'b111111111111111; a DP_RAM_addr_out = imaSiz;.

```verilog
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
```

Esta parte, es el módulo `Convert addr` de la Figura 19.

