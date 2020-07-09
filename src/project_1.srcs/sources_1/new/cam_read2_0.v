`timescale 10ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:14:22 12/02/2019 
// Design Name: 
// Module Name:    cam_read 
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
module cam_read2_0 #(
		parameter AW = 15,  // Cantidad de bits  de la dirección
		parameter DW = 12 
		)
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
            end
               
         end
         
         BYTE1:begin
         DP_RAM_regW<=0;
         
         if(CAM_href)begin
         DP_RAM_data_in[11:8]<=CAM_px_data[3:0];
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
             DP_RAM_regW<=1;    
             status<=BYTE1;
         
         end
         
         NOTHING:begin
             
             if(CAM_href)begin
             status<=BYTE2;
             DP_RAM_data_in[11:8]<=CAM_px_data[3:0];
             end
             else if (CAM_vsync) status<=INIT;
             
         end
         
         default: status<=INIT;
    endcase
 end
end
		

/********************************************************************************

Por favor colocar en este archivo el desarrollo realizado por el grupo para la 
captura de datos de la camara 

debe tener en cuenta el nombre de las entradas  y salidad propuestas 

********************************************************************************/

endmodule
