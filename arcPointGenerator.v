module arcPointGenerator #( 

parameter lowerLimitY = ;
parameter lowerLimitX = ;
parameter upperLimitX = ;
parameter upperLimitY = ;

) 


(   

input [7:0] x,
input [8:0] y,
input [8:0] radius,

);



reg signed [8:0] bresenhamsLeft; //Behams left
reg signed [7:0] bresenhamsRight; //Behams right
reg signed [64:0] bresenhamsTotalLeftHandSide;

reg signed [7:0] CentreH;
reg signed [8:0] CentreK;


reg signed [7:0] signedXAddr;
reg signed [8:0] signedYAddr;

always @ (radius or signedXAddr) begin


		//ZONE 4 - Traffic Light RIGHT
		bresenhamsLeft<= (signedXAddr - CentreH)*(signedXAddr - CentreH);
		bresenhamsRight <= (signedYAddr - CentreK)*(signedYAddr - CentreK); 
		bresenhamsTotalLeftHandSide <= bresenhamsLeft + bresenhamsRight;
		
		if(bresenhamsTotalLeftHandSide<trafficLightRadiusSquared) begin
		pixelData[(PIXELDATALENGTH-1):0] <= GREEN_COLOUR; //DRAW ZONE 1 TRAFFIC RIGHT
		end



end //For always block


endmodule
