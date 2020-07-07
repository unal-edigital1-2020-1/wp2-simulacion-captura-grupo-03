`timescale 10ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// 
// Create Date:    13:34:31 10/22/2019 
// Design Name: 	 Ferney alberto Beltran Molina
// Module Name:    buffer_ram_dp 
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
// # Definir y sobreescribir parámetros [1, pág 211]
// Se usa para anchos de bits parametrizables
// Uso: <name_module> #(a,b,...) <nombre de instanciación> (a.(),b.(),...);
// Al instanciar sin #(a,b,...) se colocan los valores inicialmente definidos.
// AW se calcula como log_2(#pixeles)
// DW bits por cada pixel.

module buffer_ram_dp#( 
	parameter AW = 15, // Cantidad de bits  de la direccin 
	parameter DW = 12, // cantidad de Bits de los datos 
	parameter   imageFILE= "D:/UNAL/semester6/digitali/proyecto/wp2-simulacion-captura-grupo-03/src/project_1.srcs/sources_1/new/imagen.men")
	(  
	input  clk_w,     		  // Frecuencia de toma de datos de cada pixel.
	input  [AW-1: 0] addr_in, // Dirección entrada dada por el capturador.
	input  [DW-1: 0] data_in, // Datos que entran de la cámara.
	input  regwrite,		  // Enable
	
	input  clk_r, 				    // Reloj 25MHz VGA.
	input [AW-1: 0] addr_out, 		// Dirección de salida dada por VGA.
	output reg [DW-1: 0] data_out,	// Datos enviados a la VGA.	
	input reset
	);

// Calcular el numero de posiciones totales de memoria 
localparam NPOS = 2 ** AW; // Memoria

 reg [DW-1: 0] ram [0: NPOS-1]; 


//	 escritura  de la memoria port 1 
always @(posedge clk_w) begin 
       if (regwrite == 1) 
// Escribe los datos de entrada en la dirección que addr_in se lo indique.
             ram[addr_in] <= data_in;
end

//	 Lectura  de la memoria port 2 
always @(posedge clk_r) begin
// Se leen los datos de las direcciones addr_out y se sacan en data_out  		
		data_out <= ram[addr_out]; 
end


initial begin
// Lee en hexadecimal (readmemb lee en binario) dentro de ram [1, pág 217].
	$readmemh(imageFILE, ram);
	ram[15'b1111_1111_1111_111]=12'b0000_0000_0000;	// Ultima posicion en memoria, igual a 0
end

/*
always @(posedge clk_w) begin 
	if (reset) begin
		$readmemh(imageFILE, ram);
	end
end
*/

endmodule


// Refencias
// [1] S. Harris and D. Harry, Digital Design and Computer Architecture.p 211-212,217, 258.
// [2] recuperado de: https://file.org/extension/man#:~:text=Files%20that%20contain%20the%20.,in%20a%20plain%20text%20format.
