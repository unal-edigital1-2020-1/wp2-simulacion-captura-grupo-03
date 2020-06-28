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


module captura_de_datos_downsampler(
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
output reg [11:0] DP_RAM_data_in,
output reg [16:0] DP_RAM_addr_in,
output reg DP_RAM_regW
    );
    reg cont=1'b0;
    reg [7:0] color;
    
    always@(posedge PCLK)
    begin
        if(HREF & ~VSYNC)
        begin
            color[0] = D0;
            color[0] = D1;
            color[0] = D2;
            color[0] = D3;
            color[0] = D4;
            color[0] = D5;
            color[0] = D6;
            color[0] = D7;
            if (cont==0)
            begin
                DP_RAM_data_in <= {color[3:0],DP_RAM_data_in[7:0]};
                DP_RAM_regW =0;
            end
            else
            begin
                DP_RAM_data_in <= {DP_RAM_data_in[11:8],color[7:0]};
                DP_RAM_regW =1;
            end
            cont = cont+1;
        end
    end
    always@(negedge PCLK)
    begin
        if(HREF & ~VSYNC & (cont==1))
        begin
            DP_RAM_addr_in=DP_RAM_addr_in+1;
        end
        if(DP_RAM_addr_in == 76800)
            DP_RAM_addr_in = 0;
        end
endmodule
