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
module cam_read #(
		parameter AW = 15,  // Cantidad de bits  de la direcciï¿½n
		parameter DW = 12   //tamaÃ±o de la data 
		)
		(

		CAM_pclk,     //reloj 
		CAM_vsync,    //SeÃ±al Vsync para captura de datos
		CAM_href,	// SeÃ±al Href para la captura de datos
		rst,		//reset
		
		DP_RAM_regW, 	//Control de esctritura
		DP_RAM_addr_in,	//DirecciÃ³n de memoria de entrada
		DP_RAM_data_in,	//Data de entrada a la RAM
		
	    CAM_D0,                   // Bit 0 de los datos del píxel
        CAM_D1,                   // Bit 1 de los datos del píxel
        CAM_D2,                   // Bit 2 de los datos del píxel
        CAM_D3,                   // Bit 3 de los datos del píxel
        CAM_D4,                   // Bit 4 de los datos del píxel
        CAM_D5,                   // Bit 5 de los datos del píxel
        CAM_D6,                   // Bit 6 de los datos del píxel
        CAM_D7                    // Bit 7 de los datos del píxel
   );
	
	    input CAM_D0;                   // Bit 0 de los datos del píxel
        input CAM_D1;                   // Bit 1 de los datos del píxel
        input CAM_D2;                   // Bit 2 de los datos del píxel
        input CAM_D3;                   // Bit 3 de los datos del píxel
        input CAM_D4;                   // Bit 4 de los datos del píxel
        input CAM_D5;                   // Bit 5 de los datos del píxel
        input CAM_D6;                   // Bit 6 de los datos del píxel
        input CAM_D7;                    // Bit 7 de los datos del píxel
	
	
	    
		input CAM_pclk;		//Reloj de la camara
		input CAM_vsync;	//seÃ±al vsync de la camara
		input CAM_href;		//seÃ±al href de la camara
		input rst;		//reset de la camara 
		
		output reg DP_RAM_regW; 		//Registro del control de escritura 
	    output reg [AW-1:0] DP_RAM_addr_in;	// Registro de salida de la direcciÃ³n de memoria de entrada 
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
             if(~CAM_vsync&CAM_href)begin // cuando la seÃ±al vsync negada y href son, se empieza con la escritura de los datos en memoria.
                 status<=BYTE2;
                 DP_RAM_data_in[11:8]<=CAM_px_data[3:0]; //se asignan los 4 bits menos significativos de la informaciÃ³n que da la camara a los 4 bits mas significativos del dato a escribir
             end
             else begin
                 DP_RAM_data_in<=0;
                 DP_RAM_addr_in<=0;
                 DP_RAM_regW<=0;
             end 
         end
         
         BYTE1:begin
             DP_RAM_regW<=0; 					//Desactiva la escritura en memoria 
             if(CAM_href)begin					//si la seÃ±al Href esta arriva, evalua si ya llego a la ultima posicion en memoria
                     if(DP_RAM_addr_in==imaSiz) DP_RAM_addr_in<=0;			//Si ya llego al final, reinicia la posiciÃ³n en memoria. 
                     else DP_RAM_addr_in<=DP_RAM_addr_in+1;	//Si aun no ha llegado a la ultima posiciÃ³n sigue recorriendo los espacios en memoria y luego escribe en ellos cuan do pasa al estado Byte2
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
         
         NOTHING:begin						// es un estado de trnsiciÃ³n    
             if(CAM_href)begin					// verifica la seÃ±al href y se asigna los 4 bits mas significativos y se mueve una posiciÃ³n en memoria
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
		

/********************************************************************************

Por favor colocar en este archivo el desarrollo realizado por el grupo para la 
captura de datos de la camara 

debe tener en cuenta el nombre de las entradas  y salidad propuestas 

********************************************************************************/

endmodule
