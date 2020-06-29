`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.06.2020 18:52:26
// Design Name: 
// Module Name: captura_de_datos_downsampler
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module captura_datos_downsampler #(
	parameter AW = 15, // Cantidad de bits  de la direccin 
	parameter DW = 12,) // cantidad de Bits de los datos 
	(  
  // Sennales de entrada dadas por la camara.
  input PCLK, 
  input HREF, 
  input VSYNC, 
  input D0,
  input D1,
  input D2,
  input D3,
  input D4,
  input D5,
  input D6,
  input D7,
  
  output wire DP_RAM_regW,                // Enable.
  output wire [AW-1:0] DP_RAM_addr_in,    // Direccion entrada. (Donde se escribe).
  output reg [DW-1:0] DP_RAM_data_in);    // Dato entrada.
  
  reg [1:0] cont = 1`b0;  // Contador inicializado en 0.
  reg [7:0] color;        // Variable para guardar datos proporcionados por la camara.
  
  initial
    begin
      always @ (posedge pclk)
        begin
          if(HREF & ~VSYNC)
            begin
              color [0] = D0;
          	  color [1] = D1;
          	  color [2] = D2;
          	  color [3] = D3;
         	  color [4] = D4;
        	  color [5] = D5;
        	  color [6] = D6;
              color [7] = D7;
              if(cont == 0)
                begin
                  DP_RAM_data_in <= {color[3:0], DP_RAM_data_in[7:0]};
              	  DP_RAM_regW = 0;
                end
              else
            	begin
                  DP_RAM_data_in <= {DP_RAM_data_in[11:8], color[7:0]};
                  DP_RAM_regW = 1;
            	end
          	  cont = cont + 1;
        	end
       	end
      always @ (negedge pclk)
        begin
          if(HREF & ~VSYNC & (cont == 1)
            begin
              DP_RAM_addr_in = DP_RAM_addr_in + 1; 
            end
             if (DP_RAM_addr_in == 2**AW)
               DP_RAM_addr_in = 0;
        end
    end
endmodule
