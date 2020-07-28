`timescale 10ns / 1ns

////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:   09:45:24 12/04/2019
// Design Name:   test_cam
// Module Name:   C:/Users/UECCI/Desktop/pruebas camd2/hw/src/test_cam_TB.v
// Project Name:  test_cam
// Target Device:
// Tool versions:
// Description:
//
// Verilog Test Fixture created by ISE for module: test_cam
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
////////////////////////////////////////////////////////////////////////////////

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
    
    wire clk25M;
    wire [11:0] data_mem;
	wire [14:0] DP_RAM_addr_out;
    
    wire DP_RAM_regW;
    wire [14:0] DP_RAM_addr_in;
	wire [11:0] DP_RAM_data_in;

    // Senales de prueba ******************************
// Absolute Address in Esteban's computer
localparam d="D:/UNAL/semester6/digitali/proyecto/wp2-simulacion-captura-grupo-03/src/test_vga.txt";
// Absolute address in Niko's computer
// localparam d="C:/Users/LucasTheKitten/Desktop/Captura/wp2-simulacion-captura-grupo-03/src/test_vga.txt";	
	
	// Instantiate the Unit Under Test (UUT)
	test_cam uut (
		.clk(clk),
		.rst(rst),
		.VGA_Hsync_n(VGA_Hsync_n),
		.VGA_Vsync_n(VGA_Vsync_n),
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B),

		// se�ales de prueba *******************************************
	   
	     //  Algunas conexiones de Driver_VGA.
	   .clk25M(clk25M),
	   .data_mem(data_mem),
	   .DP_RAM_addr_out(DP_RAM_addr_out),
       
        // salidas de cam_read.v
       .DP_RAM_regW(DP_RAM_regW), 
       .DP_RAM_addr_in(DP_RAM_addr_in),
	   .DP_RAM_data_in(DP_RAM_data_in),
        
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
		rst = 0; // registros en f�sico para que reinicialicen.
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
	
	/*************************************************************************
			INICIO DE SIMULACION DE SE�ALES DE LA CAMARA
	**************************************************************************/
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

// Azul y verde cada dos pixeles.
	reg [2:0]cont=0;   

    initial forever  begin
		@(negedge pclk) begin
            if(~CAM_href) cont=0;
            
            if(cont==0|cont==2) begin 
                CAM_px_data<=8'h0;
            end
            else if(cont==1|cont==3) begin
                CAM_px_data<=8'h0f;
            end
            else if(cont==4|cont==6) begin
                CAM_px_data<=8'h00;
            end
            else if(cont==5|cont==7) begin
                CAM_px_data<=8'hf0;
            end
			cont=cont+1;
         end
	end
	
	
	
	
	/*simulaci�n de contador de pixeles para  general Href y vsync*/
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

	/*simulaci�n de la se�al vsync generada por la camara*/
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

	/*simulaci�n de la se�al href generada por la camara*/
	initial forever  begin
		@(negedge pclk) begin
            if (img_generate==1) begin
                if (row_cnt>BLACK_TAM_ROW-1)begin
                    if (line_cnt==0)begin
                        CAM_href  = 1;
                    end
                end
                if (line_cnt==TAM_LINE)begin
                    CAM_href  = 0;
                end
            end
		end
	end

	
    
	/*************************************************************************
			FIN SIMULACI�N DE SE�ALES DE LA CAMARA
	**************************************************************************/

	/*************************************************************************
			INICIO DE  GENERACION DE ARCHIVO test_vga
	**************************************************************************/

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
		$fwrite(f,"%0t ps: %b %b %b %b %b\n",$time,VGA_Hsync_n, VGA_Vsync_n, VGA_R[3:0],VGA_G[3:0],VGA_B[3:0]);
	end

endmodule
