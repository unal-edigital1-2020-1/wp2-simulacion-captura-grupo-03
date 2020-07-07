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

reg status=0,byte1=0,byte2=0,reset=0;
parameter INIT=0,BYTE1=1,BYTE2=2,NOTHING=3,imaSiz=160*120;


always@(negedge CAM_pclk)begin
    if(byte1)begin
        DP_RAM_data_in={CAM_px_data[3:0],DP_RAM_data_in[7:0]};
        DP_RAM_regW=0;
    end
end

always@(negedge CAM_pclk)begin
    if(byte2)begin
        DP_RAM_data_in={DP_RAM_data_in[11:8],CAM_px_data};
        DP_RAM_regW=1;
        DP_RAM_addr_in=DP_RAM_addr_in+1;
    end
    if(DP_RAM_addr_in==imaSiz) DP_RAM_addr_in=0; 
end

always@(negedge CAM_pclk) begin
    if(reset|rst) begin
		DP_RAM_regW=0; //enable
		DP_RAM_addr_in=0;
		DP_RAM_data_in=0;
		status=INIT;
	end
end

		
always @(negedge CAM_pclk)
begin
 case (status)
     INIT:begin
        byte1=0;
        byte2=0;
        reset=1;
     
        if(~CAM_vsync&CAM_href)begin
        status=BYTE1;
        end
           
     end
     
     BYTE1:begin
      
         byte1=1;
         byte2=0;
         reset=0;
         
         if(~CAM_href) status=NOTHING;
         else if(CAM_vsync) status=INIT;
         else status=BYTE2;
     end
     NOTHING:begin
         byte1=0;
         byte2=0;
         reset=0;
         if(CAM_href) status=BYTE1;
         else if (CAM_vsync) status=INIT;
     end
     
     BYTE2:begin
         byte1=0;
         byte2=1;
         reset=0;
         status=BYTE1;
     end
     default: status=INIT;
 endcase
end
		
		
reg [1:0] cont = 1'b0;  // Contador inicializado en 0.

  always @ (posedge CAM_pclk)
  begin
    if(rst)
    begin
        DP_RAM_regW=0;
        DP_RAM_addr_in=0;
        DP_RAM_data_in=0;
    end
  
  end
 
      always @ (posedge CAM_pclk)
        begin
          if(CAM_href & ~CAM_vsync)
            begin
              if(cont == 0)
                begin
                  DP_RAM_data_in <= {CAM_px_data[3:0], DP_RAM_data_in[7:0]};
              	  DP_RAM_regW = 0;
                end
              else
            	begin
                  DP_RAM_data_in <= {DP_RAM_data_in[11:8], CAM_px_data[7:0]};
                  DP_RAM_regW = 1;
            	end
          	  cont = cont + 1;
        	end
       	end
       	
       	

      always @ (negedge CAM_pclk)
        begin
          if(CAM_href & ~CAM_vsync & (cont == 1))
            begin
              DP_RAM_addr_in = DP_RAM_addr_in + 1; 
            end
            
             if(DP_RAM_addr_in == 2**AW)
             begin
               DP_RAM_addr_in = 0;
             end
        end


/********************************************************************************

Por favor colocar en este archivo el desarrollo realizado por el grupo para la 
captura de datos de la camara 

debe tener en cuenta el nombre de las entradas  y salidad propuestas 

********************************************************************************/

endmodule
