
module LT24Top (
    //
    // Global Clock/Reset
    // - Clock
    input              clock,
    // - Global Reset
    input              globalReset,
    // - Application Reset - for debug
    output             resetApp,
    //
    // LT24 Interface
    output             LT24_WRn,
    output             LT24_RDn,
    output             LT24_CSn,
    output             LT24_RS,
    output             LT24_RESETn,
    output [     15:0] LT24_D,
    output             LT24_LCD_ON
	 
);



//LOCAL PARAMETER DECLARATIONS
//-----------------------------------------------------------------------------------------------------
localparam WIDTH = 240;
localparam HEIGHT = 320;

localparam TRAFFICLIGHT_RADIUS = 5;
localparam TRAFFICLIGHT_SPACING = 10;

localparam CAR_SPEED_MAX_BIT = 4;

localparam XAXISMAXBITS = 8;
localparam MAX_X_MULT_BITS = 64;
localparam YAXISMAXBITS = 9;
localparam MAX_Y_MULT_BITS = 81;

localparam PIXELDATALENGTH = 16;

localparam DISTBTWNCARS = (WIDTH/16);
localparam ROADXMIDPOINT = (WIDTH/2);
localparam ROADYMIDPOINT = (HEIGHT/2);

localparam CARSIZE = 10; //Square
localparam HALFCARSIZE = CARSIZE/2;

localparam ZONE1XSTART = WIDTH-1-6;
localparam ZONE1YSTART = ((ROADYMIDPOINT/2)  + DISTBTWNCARS)-1+20;

localparam ZONE2XSTART = ((ROADXMIDPOINT/2) + DISTBTWNCARS)-1;
localparam ZONE2YSTART = 6; 

localparam ZONE3XSTART = 6;
localparam ZONE3YSTART = (ROADYMIDPOINT+DISTBTWNCARS)-1; 

localparam ZONE4XSTART = (ROADXMIDPOINT+DISTBTWNCARS)-1;
localparam ZONE4YSTART = HEIGHT-1-6; 

localparam ONE = 1;
localparam ZERO = 0;
localparam LONGZERO = 208'd0;
localparam WARNING_TIME_LENGTH = 2; //IN SECONDS

localparam TRAFFIC_STATE_DURATION_FACTOR = 7; //7 Seconds duration---max is 40 seconds...SHOULD NOT BE LESS THAN 2
localparam TRAFFIC_STATE_DURATION_FACTOR_REG_LENGTH = 8; //7 Seconds duration---max is 40 seconds
localparam CLOCK_SPEED = 50000000;
localparam CLOCK_COUNTER_REG_LENGTH = 26;
localparam TRAFFIC_STATE_DURATION_REG_LENGTH = 208;  //26*8---TRAFFIC STATE FACTOR SHOULD NOT BE MORE THAN 40...reg length of 31 will do tho 

localparam COMPUTED_WARNING_TIME = WARNING_TIME_LENGTH*CLOCK_SPEED;
reg [207:0] warningTime = 208'd1;

//LEFT CAR HOPS
localparam CAR_LEFT_ZONE1_HOP1X = 122;
localparam CAR_LEFT_ZONE1_HOP1Y = 153;
localparam CAR_LEFT_ZONE1_HOP2X = 113;
localparam CAR_LEFT_ZONE1_HOP2Y = 162;
localparam CAR_LEFT_ZONE1_HOP3X = 104;
localparam CAR_LEFT_ZONE1_HOP3Y = 189;

localparam CAR_LEFT_ZONE2_HOP1X = 113;
localparam CAR_LEFT_ZONE2_HOP1Y = 156;
localparam CAR_LEFT_ZONE2_HOP2X = 122;
localparam CAR_LEFT_ZONE2_HOP2Y = 165;
localparam CAR_LEFT_ZONE2_HOP3X = 149;
localparam CAR_LEFT_ZONE2_HOP3Y = 174;

localparam CAR_LEFT_ZONE3_HOP1X = 116;
localparam CAR_LEFT_ZONE3_HOP1Y = 165;
localparam CAR_LEFT_ZONE3_HOP2X = 125;
localparam CAR_LEFT_ZONE3_HOP2Y = 156;
localparam CAR_LEFT_ZONE3_HOP3X = 134;
localparam CAR_LEFT_ZONE3_HOP3Y = 129;

localparam CAR_LEFT_ZONE4_HOP1X = 125;
localparam CAR_LEFT_ZONE4_HOP1Y = 162;
localparam CAR_LEFT_ZONE4_HOP2X = 116;
localparam CAR_LEFT_ZONE4_HOP2Y = 153;
localparam CAR_LEFT_ZONE4_HOP3X = 89;
localparam CAR_LEFT_ZONE4_HOP3Y = 144;

localparam ZONE1_STOP_POSITION_X = 188-1; //ORIGINALLY 185 
localparam ZONE2_STOP_POSITION_Y = 92-1; //ORIGINALLY 95
localparam ZONE3_STOP_POSITION_X = 52-1;  //ORIGINALLY 55
localparam ZONE4_STOP_POSITION_Y = 228-1;  //ORIGINALLY 225

//PEDESTRIAN  START POSITIONS
localparam ZONE1_PEDESTRIAN_X_START = 179;
localparam ZONE1_PEDESTRIAN_Y_START = 99;
localparam ZONE2_PEDESTRIAN_X_START = 179;
localparam ZONE2_PEDESTRIAN_Y_START = 99;
localparam ZONE3_PEDESTRIAN_X_START = 59;
localparam ZONE3_PEDESTRIAN_Y_START = 99;
localparam ZONE4_PEDESTRIAN_X_START = 59;
localparam ZONE4_PEDESTRIAN_Y_START = 219;

//DECLARE PEDESTRIAN START POSITIONS
//-----------------------------------------------------------------------------------------------------------------

//FOR THE TRAFFIC LIGHTS START X AND Y POSITIONS
localparam ZONE1_TRAFFIC_XSTART = ROADXMIDPOINT + (ROADXMIDPOINT/2)+ TRAFFICLIGHT_SPACING -1;
localparam ZONE1_TRAFFIC_YSTART = ((ROADYMIDPOINT/2)  - TRAFFICLIGHT_SPACING)-1+20;

localparam ZONE2_TRAFFIC_XSTART = ((ROADXMIDPOINT/2) - TRAFFICLIGHT_SPACING)-1;
localparam ZONE2_TRAFFIC_YSTART = ((ROADYMIDPOINT/2)  - TRAFFICLIGHT_SPACING)-1+20; 

localparam ZONE3_TRAFFIC_XSTART = (ROADXMIDPOINT/2)- TRAFFICLIGHT_SPACING;
localparam ZONE3_TRAFFIC_YSTART = (ROADYMIDPOINT) + (ROADYMIDPOINT/2) + TRAFFICLIGHT_SPACING-1-20; 

localparam ZONE4_TRAFFIC_XSTART = ROADXMIDPOINT + (ROADXMIDPOINT/2)+ TRAFFICLIGHT_SPACING -1;
localparam ZONE4_TRAFFIC_YSTART = (ROADYMIDPOINT)+ (ROADYMIDPOINT/2)-20+TRAFFICLIGHT_SPACING -1;

//-------------------------------------------------------------------------------------------------------

//DECLARE TURNING POINT FOR RIGHT CARS
//-------------------------------------------------------------------------------------------------------
localparam CAR_RIGHT_Z1_TURNINGPOINT_X = ROADXMIDPOINT + DISTBTWNCARS + DISTBTWNCARS + DISTBTWNCARS-1; //(164,114)
localparam CAR_RIGHT_Z1_TURNINGPOINT_Y = ROADYMIDPOINT - DISTBTWNCARS - DISTBTWNCARS - DISTBTWNCARS-1;

localparam CAR_RIGHT_Z2_TURNINGPOINT_X = ROADXMIDPOINT - DISTBTWNCARS - DISTBTWNCARS - DISTBTWNCARS-1; //(74,114)
localparam CAR_RIGHT_Z2_TURNINGPOINT_Y =  ROADYMIDPOINT - DISTBTWNCARS - DISTBTWNCARS - DISTBTWNCARS-1; 

localparam CAR_RIGHT_Z3_TURNINGPOINT_X = ROADXMIDPOINT - DISTBTWNCARS - DISTBTWNCARS - DISTBTWNCARS-1;  //(74, 204)
localparam CAR_RIGHT_Z3_TURNINGPOINT_Y = ROADYMIDPOINT + DISTBTWNCARS + DISTBTWNCARS + DISTBTWNCARS-1;

localparam CAR_RIGHT_Z4_TURNINGPOINT_X = ROADXMIDPOINT + DISTBTWNCARS + DISTBTWNCARS + DISTBTWNCARS-1; //(164, 204)
localparam CAR_RIGHT_Z4_TURNINGPOINT_Y = ROADYMIDPOINT + DISTBTWNCARS + DISTBTWNCARS + DISTBTWNCARS-1;
 

 //LEFT CARS
localparam CAR_LEFT_Z1_TURNINGPOINT_X = ROADXMIDPOINT + DISTBTWNCARS + DISTBTWNCARS -1; //(149,144)
localparam CAR_LEFT_Z1_TURNINGPOINT_Y = ROADYMIDPOINT - DISTBTWNCARS - 1;

localparam CAR_LEFT_Z2_TURNINGPOINT_X = ROADXMIDPOINT - DISTBTWNCARS -1; //(104,129)
localparam CAR_LEFT_Z2_TURNINGPOINT_Y =  ROADYMIDPOINT - DISTBTWNCARS - DISTBTWNCARS -1; 

localparam CAR_LEFT_Z3_TURNINGPOINT_X = ROADXMIDPOINT - DISTBTWNCARS - DISTBTWNCARS - 1;  //(89, 174)
localparam CAR_LEFT_Z3_TURNINGPOINT_Y = ROADYMIDPOINT + DISTBTWNCARS - 1;

localparam CAR_LEFT_Z4_TURNINGPOINT_X = ROADXMIDPOINT + DISTBTWNCARS -1; //(134, 189)
localparam CAR_LEFT_Z4_TURNINGPOINT_Y = ROADYMIDPOINT + DISTBTWNCARS +  DISTBTWNCARS -1;
 
 

//-------------------------------------------------------------------------------------------------------

//DECLARE CAR SPEED
//--------------------------------------------------------------------------------------------------------
localparam ZONE1_CAR_LEFT_SPEED = 1;
localparam ZONE1_CAR_CENTRE_SPEED = 1;
localparam ZONE1_CAR_RIGHT_SPEED = 1;

localparam ZONE2_CAR_LEFT_SPEED = 1;
localparam ZONE2_CAR_CENTRE_SPEED = 1;
localparam ZONE2_CAR_RIGHT_SPEED = 1;

localparam ZONE3_CAR_LEFT_SPEED = 1;
localparam ZONE3_CAR_CENTRE_SPEED = 1;
localparam ZONE3_CAR_RIGHT_SPEED = 1;

localparam ZONE4_CAR_LEFT_SPEED = 1;
localparam ZONE4_CAR_CENTRE_SPEED = 1;
localparam ZONE4_CAR_RIGHT_SPEED = 1;


//Speed of 1 to 15 
reg [(CAR_SPEED_MAX_BIT-1):0] zone1CarLeftSpeed;
reg [(CAR_SPEED_MAX_BIT-1):0] zone1CarCentreSpeed ;  
reg [(CAR_SPEED_MAX_BIT-1):0] zone1CarRightSpeed ;  

reg [(CAR_SPEED_MAX_BIT-1):0] zone2CarLeftSpeed;
reg [(CAR_SPEED_MAX_BIT-1):0] zone2CarCentreSpeed ;  
reg [(CAR_SPEED_MAX_BIT-1):0] zone2CarRightSpeed ;  

reg [(CAR_SPEED_MAX_BIT-1):0] zone3CarLeftSpeed;
reg [(CAR_SPEED_MAX_BIT-1):0] zone3CarCentreSpeed ;  
reg [(CAR_SPEED_MAX_BIT-1):0] zone3CarRightSpeed ;  

reg [(CAR_SPEED_MAX_BIT-1):0] zone4CarLeftSpeed;
reg [(CAR_SPEED_MAX_BIT-1):0] zone4CarCentreSpeed ;  
reg [(CAR_SPEED_MAX_BIT-1):0] zone4CarRightSpeed ;           

//---------------------------------------------------------------------------------------------------------



//DECLARE CAR 1 MOVE BOOLEAN
//----------------------------------------------------------------------------------------------------------
//ZONE 1
reg zone1_car_left_moove_boolean;
reg zone1_car_centre_moove_boolean;
reg zone1_car_right_moove_boolean;
reg zone1_pedestrian_moove_boolean;

//ZONE 2
reg zone2_car_left_moove_boolean;
reg zone2_car_centre_moove_boolean;
reg zone2_car_right_moove_boolean;
reg zone2_pedestrian_moove_boolean;

//ZONE 3
reg zone3_car_left_moove_boolean;
reg zone3_car_centre_moove_boolean;
reg zone3_car_right_moove_boolean;
reg zone3_pedestrian_moove_boolean;

//ZONE 4
reg zone4_car_left_moove_boolean;
reg zone4_car_centre_moove_boolean;
reg zone4_car_right_moove_boolean;
reg zone4_pedestrian_moove_boolean;

//-----------------------------------------------------------------------------------------------------------

//DECLARE THE MOVEMENT TICKER/CLOCK FOR EACH OF THE CARS
//---------------------------------------------------------------------------------------------------------
//Ticker works as a ratio of the speed. A car with speed 6 will only be fired after 6 ticks
//Not initialized
reg [(CAR_SPEED_MAX_BIT-1):0] zone1CarLeftTicker;
reg [(CAR_SPEED_MAX_BIT-1):0] zone1CarCentreTicker;  
reg [(CAR_SPEED_MAX_BIT-1):0] zone1CarRightTicker;  

reg [(CAR_SPEED_MAX_BIT-1):0] zone2CarLeftTicker;
reg [(CAR_SPEED_MAX_BIT-1):0] zone2CarCentreTicker;  
reg [(CAR_SPEED_MAX_BIT-1):0] zone2CarRightTicker ;  

reg [(CAR_SPEED_MAX_BIT-1):0] zone3CarLeftTicker;
reg [(CAR_SPEED_MAX_BIT-1):0] zone3CarCentreTicker;  
reg [(CAR_SPEED_MAX_BIT-1):0] zone3CarRightTicker ;  

reg [(CAR_SPEED_MAX_BIT-1):0] zone4CarLeftTicker;
reg [(CAR_SPEED_MAX_BIT-1):0] zone4CarCentreTicker;  
reg [(CAR_SPEED_MAX_BIT-1):0] zone4CarRightTicker; 
//----------------------------------------------------------------------------------------------------------


//DECLARE TURNING POINTS
//----------------------------------------------------------------------------------------------------------

//RIGHT TURN 
 reg [(XAXISMAXBITS-1):0] carRightZone1TurningPointX;
 reg [(YAXISMAXBITS-1):0] carRightZone1TurningPointY; 
 
 reg [(XAXISMAXBITS-1):0] carRightZone2TurningPointX;
 reg [(YAXISMAXBITS-1):0] carRightZone2TurningPointY; 
 
 
 reg [(XAXISMAXBITS-1):0] carRightZone3TurningPointX;
 reg [(YAXISMAXBITS-1):0] carRightZone3TurningPointY; 
 
 reg [(XAXISMAXBITS-1):0] carRightZone4TurningPointX;
 reg [(YAXISMAXBITS-1):0] carRightZone4TurningPointY; 
 
 
 //LEFT TURN
 reg [(XAXISMAXBITS-1):0] carLeftZone1TurningPointX;
 reg [(YAXISMAXBITS-1):0] carLeftZone1TurningPointY; 
 
 reg [(XAXISMAXBITS-1):0] carLeftZone2TurningPointX;
 reg [(YAXISMAXBITS-1):0] carLeftZone2TurningPointY; 
 
 
 reg [(XAXISMAXBITS-1):0] carLeftZone3TurningPointX;
 reg [(YAXISMAXBITS-1):0] carLeftZone3TurningPointY; 
 
 reg [(XAXISMAXBITS-1):0] carLeftZone4TurningPointX;
 reg [(YAXISMAXBITS-1):0] carLeftZone4TurningPointY; 
//----------------------------------------------------------------------------------------------------------


//DECARE TURNING HOPS FOR LEFT TURN
//----------------------------------------------------------------------------------------------------------
reg [(XAXISMAXBITS-1):0] carLeftZone1TurningHop1X;
reg [(YAXISMAXBITS-1):0] carLeftZone1TurningHop1Y; 
reg [(XAXISMAXBITS-1):0] carLeftZone1TurningHop2X;
reg [(YAXISMAXBITS-1):0] carLeftZone1TurningHop2Y; 
reg [(XAXISMAXBITS-1):0] carLeftZone1TurningHop3X;
reg [(YAXISMAXBITS-1):0] carLeftZone1TurningHop3Y;

reg [(XAXISMAXBITS-1):0] carLeftZone2TurningHop1X;
reg [(YAXISMAXBITS-1):0] carLeftZone2TurningHop1Y; 
reg [(XAXISMAXBITS-1):0] carLeftZone2TurningHop2X;
reg [(YAXISMAXBITS-1):0] carLeftZone2TurningHop2Y; 
reg [(XAXISMAXBITS-1):0] carLeftZone2TurningHop3X;
reg [(YAXISMAXBITS-1):0] carLeftZone2TurningHop3Y;

reg [(XAXISMAXBITS-1):0] carLeftZone3TurningHop1X;
reg [(YAXISMAXBITS-1):0] carLeftZone3TurningHop1Y; 
reg [(XAXISMAXBITS-1):0] carLeftZone3TurningHop2X;
reg [(YAXISMAXBITS-1):0] carLeftZone3TurningHop2Y; 
reg [(XAXISMAXBITS-1):0] carLeftZone3TurningHop3X;
reg [(YAXISMAXBITS-1):0] carLeftZone3TurningHop3Y;

reg [(XAXISMAXBITS-1):0] carLeftZone4TurningHop1X;
reg [(YAXISMAXBITS-1):0] carLeftZone4TurningHop1Y; 
reg [(XAXISMAXBITS-1):0] carLeftZone4TurningHop2X;
reg [(YAXISMAXBITS-1):0] carLeftZone4TurningHop2Y; 
reg [(XAXISMAXBITS-1):0] carLeftZone4TurningHop3X;
reg [(YAXISMAXBITS-1):0] carLeftZone4TurningHop3Y; 
//--------------------------------------------------------------------------------------------------------------



//UNECCESSARY, BUT VERILOG REQUIRES IT
//-------------------------------------------------------------------------------------------------------
//ZONE 1 - CARS
localparam CARCENTREZONE1_Y_VAR = (ZONE1YSTART+DISTBTWNCARS);
localparam CARLEFTZONE1_Y_VAR =(ZONE1YSTART+DISTBTWNCARS+DISTBTWNCARS);
//TRAFFIC LIGHTS
localparam TRAFFIC_CENTRE_ZONE1_Y_VAR = (ZONE1_TRAFFIC_YSTART - TRAFFICLIGHT_SPACING );
localparam TRAFFIC_RIGHT_ZONE1_Y_VAR = (ZONE1_TRAFFIC_YSTART - TRAFFICLIGHT_SPACING - TRAFFICLIGHT_SPACING);
localparam TRAFFIC_PEDESTRIAN_ZONE1_Y_VAR = (ZONE1_TRAFFIC_YSTART - TRAFFICLIGHT_SPACING - TRAFFICLIGHT_SPACING - TRAFFICLIGHT_SPACING);


//ZONE 2 - CARS
localparam CARCENTREZONE2_X_VAR = (ZONE2XSTART+DISTBTWNCARS);
localparam CARLEFTZONE2_X_VAR = (ZONE2XSTART+DISTBTWNCARS+DISTBTWNCARS);
//TRAFFIC LIGHTS
localparam TRAFFIC_CENTRE_ZONE2_X_VAR = (ZONE2_TRAFFIC_XSTART - TRAFFICLIGHT_SPACING );
localparam TRAFFIC_RIGHT_ZONE2_X_VAR = (ZONE2_TRAFFIC_XSTART - TRAFFICLIGHT_SPACING - TRAFFICLIGHT_SPACING);
localparam TRAFFIC_PEDESTRIAN_ZONE2_X_VAR = (ZONE2_TRAFFIC_XSTART - TRAFFICLIGHT_SPACING - TRAFFICLIGHT_SPACING - TRAFFICLIGHT_SPACING);

//ZONE 3 - CARS
localparam CARRIGHTZONE3_Y_VAR = (ZONE3YSTART+DISTBTWNCARS+DISTBTWNCARS);
localparam CARCENTREZONE3_Y_VAR = (ZONE3YSTART+DISTBTWNCARS);
//TRAFFIC LIGHTS
localparam TRAFFIC_CENTRE_ZONE3_Y_VAR = (ZONE3_TRAFFIC_YSTART + TRAFFICLIGHT_SPACING );
localparam TRAFFIC_RIGHT_ZONE3_Y_VAR = (ZONE3_TRAFFIC_YSTART + TRAFFICLIGHT_SPACING + TRAFFICLIGHT_SPACING);
localparam TRAFFIC_PEDESTRIAN_ZONE3_Y_VAR = (ZONE3_TRAFFIC_YSTART + TRAFFICLIGHT_SPACING + TRAFFICLIGHT_SPACING + TRAFFICLIGHT_SPACING);


//ZONE 4 - CARS
localparam CARRIGHTZONE4_X_VAR = (ZONE4XSTART+DISTBTWNCARS+DISTBTWNCARS);
localparam CARCENTREZONE4_X_VAR =(ZONE4XSTART+DISTBTWNCARS);
//TRAFFIC LIGHTS
localparam TRAFFIC_CENTRE_ZONE4_X_VAR = (ZONE4_TRAFFIC_XSTART + TRAFFICLIGHT_SPACING );
localparam TRAFFIC_RIGHT_ZONE4_X_VAR = (ZONE4_TRAFFIC_XSTART + TRAFFICLIGHT_SPACING + TRAFFICLIGHT_SPACING);
localparam TRAFFIC_PEDESTRIAN_ZONE4_X_VAR = (ZONE4_TRAFFIC_XSTART + TRAFFICLIGHT_SPACING + TRAFFICLIGHT_SPACING + TRAFFICLIGHT_SPACING);
//-------------------------------------------------------------------------------------------------------------

reg  [ (XAXISMAXBITS-1):0] xAddr      ;
reg  [ (YAXISMAXBITS-1):0] yAddr      ;
reg  [(PIXELDATALENGTH-1):0] pixelData  ;
wire        pixelReady ;

reg [(YAXISMAXBITS-1):0] swipeCounter; //count from 0 to 319...9 bits needed
reg [(YAXISMAXBITS-1):0] singleXMovementTracker; //count from 0 to 239...8 bits needed

//CENTRE DASHES ON ROAD Y AXIS (10 PIXELS DRAW, 8 PIXELS DONT DRAW)
reg [(XAXISMAXBITS/2):0] yCentreLineTracker; //count from 0 to 17...5 bits needed - Vertical Line
reg [(XAXISMAXBITS/2):0] xCentreLineTracker; //count from 0 to 17...5 bits needed - Horizontal line

reg [(XAXISMAXBITS/2):0] yCentreLineTracker2; //count from 0 to 17...5 bits needed - Vertical Line
reg [(XAXISMAXBITS/2):0] xCentreLineTracker2; //count from 0 to 17...5 bits needed - Horizontal line

reg [24:0] oneSecondCounter;
reg [21:0] fiftyMilliSecondsCounter; //22 bits wide 0 to 2,500,000
reg movementClock;


//TRAFFIC CONTROLLER STATE MACHINE VARIABLES
reg reset = 1'b0;
reg [2:0] currentState; //state 0 to 4
reg [2:0] nextState;
localparam A = 3'd0;
localparam B = 3'd1;
localparam C = 3'd2;
localparam D = 3'd3;
localparam E = 3'd4;
localparam F = 3'd5;
reg [(TRAFFIC_STATE_DURATION_REG_LENGTH-1):0] stateDurationCounter; //Can count up to 350 Million for 7 seconds delay 
reg [(TRAFFIC_STATE_DURATION_REG_LENGTH-1):0] trafficStateDuration;
//CREATE VARIABLES NEEDED TO FORM TRAFFIC SIGN CIRCLE
//---------------------------------------------------------------------------------------------------------
reg signed [(YAXISMAXBITS-1):0] trafficLightRadius;
reg signed [(MAX_Y_MULT_BITS-1):0] trafficLightRadiusSquared;

//Declare Brehams Left for all traffic circles
reg signed [(MAX_Y_MULT_BITS-1):0] bresenhamsLeft_Z1_TLL; //Behams left, Zone 1_Traffic Light Left
reg signed [(MAX_Y_MULT_BITS-1):0] bresenhamsLeft_Z1_TLC; //Behams left, Zone 1_Traffic Light Centre
reg signed [(MAX_Y_MULT_BITS-1):0] bresenhamsLeft_Z1_TLR; //Behams left, Zone 1_Traffic Light Right
reg signed [(MAX_Y_MULT_BITS-1):0] bresenhamsLeft_Z1_TLP; //Behams left, Zone 1_Traffic Light Pedestrian

reg signed [(MAX_Y_MULT_BITS-1):0] bresenhamsLeft_Z2_TLL; //Behams left, Zone 2_Traffic Light Left
reg signed [(MAX_Y_MULT_BITS-1):0] bresenhamsLeft_Z2_TLC; //Behams left, Zone 2_Traffic Light Centre
reg signed [(MAX_Y_MULT_BITS-1):0] bresenhamsLeft_Z2_TLR; //Behams left, Zone 2_Traffic Light Right
reg signed [(MAX_Y_MULT_BITS-1):0] bresenhamsLeft_Z2_TLP; //Behams left, Zone 2_Traffic Light Pedestrian

reg signed [(MAX_Y_MULT_BITS-1):0] bresenhamsLeft_Z3_TLL; //Behams left, Zone 3_Traffic Light Left
reg signed [(MAX_Y_MULT_BITS-1):0] bresenhamsLeft_Z3_TLC; //Behams left, Zone 3_Traffic Light Centre
reg signed [(MAX_Y_MULT_BITS-1):0] bresenhamsLeft_Z3_TLR; //Behams left, Zone 3_Traffic Light Right
reg signed [(MAX_Y_MULT_BITS-1):0] bresenhamsLeft_Z3_TLP; //Behams left, Zone 3_Traffic Light Pedestrian

reg signed [(MAX_Y_MULT_BITS-1):0] bresenhamsLeft_Z4_TLL; //Behams left, Zone 4_Traffic Light Left
reg signed [(MAX_Y_MULT_BITS-1):0] bresenhamsLeft_Z4_TLC; //Behams left, Zone 4_Traffic Light Centre
reg signed [(MAX_Y_MULT_BITS-1):0] bresenhamsLeft_Z4_TLR; //Behams left, Zone 4_Traffic Light Right
reg signed [(MAX_Y_MULT_BITS-1):0] bresenhamsLeft_Z4_TLP; //Behams left, Zone 4_Traffic Light Pedestrian


//Declare Brehams right for all traffic circles
reg signed [(MAX_X_MULT_BITS-1):0] bresenhamsRight_Z1_TLL; //Behams right, Zone 1_Traffic Light Left
reg signed [(MAX_X_MULT_BITS-1):0] bresenhamsRight_Z1_TLC; //Behams right, Zone 1_Traffic Light Centre
reg signed [(MAX_X_MULT_BITS-1):0] bresenhamsRight_Z1_TLR; //Behams right, Zone 1_Traffic Light Right
reg signed [(MAX_X_MULT_BITS-1):0] bresenhamsRight_Z1_TLP; //Behams right, Zone 1_Traffic Light Pedestrian

reg signed [(MAX_X_MULT_BITS-1):0] bresenhamsRight_Z2_TLL; //Behams right, Zone 2_Traffic Light Left
reg signed [(MAX_X_MULT_BITS-1):0] bresenhamsRight_Z2_TLC; //Behams right, Zone 2_Traffic Light Centre
reg signed [(MAX_X_MULT_BITS-1):0] bresenhamsRight_Z2_TLR; //Behams right, Zone 2_Traffic Light Right
reg signed [(MAX_X_MULT_BITS-1):0] bresenhamsRight_Z2_TLP; //Behams right, Zone 4_Traffic Light Pedestrian

reg signed [(MAX_X_MULT_BITS-1):0] bresenhamsRight_Z3_TLL; //Behams right, Zone 3_Traffic Light Left
reg signed [(MAX_X_MULT_BITS-1):0] bresenhamsRight_Z3_TLC; //Behams right, Zone 3_Traffic Light Centre
reg signed [(MAX_X_MULT_BITS-1):0] bresenhamsRight_Z3_TLR; //Behams right, Zone 3_Traffic Light Right
reg signed [(MAX_X_MULT_BITS-1):0] bresenhamsRight_Z3_TLP; //Behams right, Zone 4_Traffic Light Pedestrian

reg signed [(MAX_X_MULT_BITS-1):0] bresenhamsRight_Z4_TLL; //Behams right, Zone 4_Traffic Light Left
reg signed [(MAX_X_MULT_BITS-1):0] bresenhamsRight_Z4_TLC; //Behams right, Zone 4_Traffic Light Centre
reg signed [(MAX_X_MULT_BITS-1):0] bresenhamsRight_Z4_TLR; //Behams right, Zone 4_Traffic Light Right
reg signed [(MAX_X_MULT_BITS-1):0] bresenhamsRight_Z4_TLP; //Behams right, Zone 4_Traffic Light Pedestrian


//Declare total left reg for berhams
reg signed [(MAX_Y_MULT_BITS):0] bresenhamsTotalLeftHandSide_Z1_TLL;   //Behams total left hand side, Zone 1, traffic light left
reg signed [(MAX_Y_MULT_BITS):0] bresenhamsTotalLeftHandSide_Z1_TLC;   //Behams total left hand side, Zone 1, traffic light centre
reg signed [(MAX_Y_MULT_BITS):0] bresenhamsTotalLeftHandSide_Z1_TLR;   //Behams total left hand side, Zone 1, traffic light right
reg signed [(MAX_Y_MULT_BITS):0] bresenhamsTotalLeftHandSide_Z1_TLP;   //Behams total left hand side, Zone 1, traffic light pedestrian

reg signed [(MAX_Y_MULT_BITS):0] bresenhamsTotalLeftHandSide_Z2_TLL;   //Behams total left hand side, Zone 2, traffic light left
reg signed [(MAX_Y_MULT_BITS):0] bresenhamsTotalLeftHandSide_Z2_TLC;   //Behams total left hand side, Zone 2, traffic light centre
reg signed [(MAX_Y_MULT_BITS):0] bresenhamsTotalLeftHandSide_Z2_TLR;   //Behams total left hand side, Zone 2, traffic light right
reg signed [(MAX_Y_MULT_BITS):0] bresenhamsTotalLeftHandSide_Z2_TLP;   //Behams total left hand side, Zone 2, traffic light pedestrian

reg signed [(MAX_Y_MULT_BITS):0] bresenhamsTotalLeftHandSide_Z3_TLL;   //Behams total left hand side, Zone 3, traffic light left
reg signed [(MAX_Y_MULT_BITS):0] bresenhamsTotalLeftHandSide_Z3_TLC;   //Behams total left hand side, Zone 3, traffic light centre
reg signed [(MAX_Y_MULT_BITS):0] bresenhamsTotalLeftHandSide_Z3_TLR;   //Behams total left hand side, Zone 3, traffic light right
reg signed [(MAX_Y_MULT_BITS):0] bresenhamsTotalLeftHandSide_Z3_TLP;   //Behams total left hand side, Zone 3, traffic light pedestrian

reg signed [(MAX_Y_MULT_BITS):0] bresenhamsTotalLeftHandSide_Z4_TLL;   //Behams total left hand side, Zone 4, traffic light left
reg signed [(MAX_Y_MULT_BITS):0] bresenhamsTotalLeftHandSide_Z4_TLC;   //Behams total left hand side, Zone 4, traffic light centre
reg signed [(MAX_Y_MULT_BITS):0] bresenhamsTotalLeftHandSide_Z4_TLR;   //Behams total left hand side, Zone 4, traffic light right
reg signed [(MAX_Y_MULT_BITS):0] bresenhamsTotalLeftHandSide_Z4_TLP;   //Behams total left hand side, Zone 4, traffic light pedestrian


reg signed [(XAXISMAXBITS-1):0] signedXAddr;
reg signed [(YAXISMAXBITS-1):0] signedYAddr;

//ZONE 1 TRAFFIC CIRCLE CENTRE VARIABLE DECLARATION
reg signed [(XAXISMAXBITS-1):0] zone1TrafficCircleLeftCentreH;
reg signed [(YAXISMAXBITS-1):0] zone1TrafficCircleLeftCentreK;

reg signed [(XAXISMAXBITS-1):0] zone1TrafficCircleCentreCentreH;
reg signed [(YAXISMAXBITS-1):0] zone1TrafficCircleCentreCentreK;

reg signed [(XAXISMAXBITS-1):0] zone1TrafficCircleRightCentreH;
reg signed [(YAXISMAXBITS-1):0] zone1TrafficCircleRightCentreK;

reg signed [(XAXISMAXBITS-1):0] zone1TrafficCirclePedestrianCentreH;
reg signed [(YAXISMAXBITS-1):0] zone1TrafficCirclePedestrianCentreK;

//ZONE 2 TRAFFIC CIRCLE CENTRE VARIABLE DECLARATION
reg signed [(XAXISMAXBITS-1):0] zone2TrafficCircleLeftCentreH;
reg signed [(YAXISMAXBITS-1):0] zone2TrafficCircleLeftCentreK;

reg signed [(XAXISMAXBITS-1):0] zone2TrafficCircleCentreCentreH;
reg signed [(YAXISMAXBITS-1):0] zone2TrafficCircleCentreCentreK;

reg signed [(XAXISMAXBITS-1):0] zone2TrafficCircleRightCentreH;
reg signed [(YAXISMAXBITS-1):0] zone2TrafficCircleRightCentreK;

reg signed [(XAXISMAXBITS-1):0] zone2TrafficCirclePedestrianCentreH;
reg signed [(YAXISMAXBITS-1):0] zone2TrafficCirclePedestrianCentreK;

//ZONE 3 TRAFFIC CIRCLE CENTRE VARIABLE DECLARATION
reg signed [(XAXISMAXBITS-1):0] zone3TrafficCircleLeftCentreH;
reg signed [(YAXISMAXBITS-1):0] zone3TrafficCircleLeftCentreK;

reg signed [(XAXISMAXBITS-1):0] zone3TrafficCircleCentreCentreH;
reg signed [(YAXISMAXBITS-1):0] zone3TrafficCircleCentreCentreK;

reg signed [(XAXISMAXBITS-1):0] zone3TrafficCircleRightCentreH;
reg signed [(YAXISMAXBITS-1):0] zone3TrafficCircleRightCentreK;

reg signed [(XAXISMAXBITS-1):0] zone3TrafficCirclePedestrianCentreH;
reg signed [(YAXISMAXBITS-1):0] zone3TrafficCirclePedestrianCentreK;


//ZONE 4 TRAFFIC CIRCLE CENTRE VARIABLE DECLARATION
reg signed [(XAXISMAXBITS-1):0] zone4TrafficCircleLeftCentreH;
reg signed [(YAXISMAXBITS-1):0] zone4TrafficCircleLeftCentreK;

reg signed [(XAXISMAXBITS-1):0] zone4TrafficCircleCentreCentreH;
reg signed [(YAXISMAXBITS-1):0] zone4TrafficCircleCentreCentreK;

reg signed [(XAXISMAXBITS-1):0] zone4TrafficCircleRightCentreH;
reg signed [(YAXISMAXBITS-1):0] zone4TrafficCircleRightCentreK;

reg signed [(XAXISMAXBITS-1):0] zone4TrafficCirclePedestrianCentreH;
reg signed [(YAXISMAXBITS-1):0] zone4TrafficCirclePedestrianCentreK;


//Create Signed version of x and y address and afix colours also
always begin
signedXAddr <= xAddr;
signedYAddr <= yAddr;

BROWN_COLOUR <= 16'hFC08; 
SKYE_BLUE_COLOUR <= 16'h87FF; 
DARK_BLUE_COLOUR <= 16'h001F; 
RED_COLOUR <= 16'hF800; 
GREEN_COLOUR <= 16'h87E0; 
YELLOW_COLOUR <= 16'hFFE0; 
BLUISH_GREEN_COLOUR <= 16'h87F0; 
DRY_BLUE_COLOUR <= 16'h0210;
ORANGE_COLOUR <= 16'hFC00;

//INITIALIZE WARNING TIME SPEED
warningTime <= 208'd100000000; // 2 seconds of delay

end

//----------------------------------------------------------------------------------------------------------------------------------



//CREATE START CO-ORDINATE VARIABLES FOR 3 CARS PER ZONE. IN TOTAL, FOUR ZONES
//----------------------------------------------------------------------------------------
//ZONE 1
reg  [(XAXISMAXBITS-1):0] carLeftZone1X;
reg  [(YAXISMAXBITS-1):0] carLeftZone1Y;

reg  [(XAXISMAXBITS-1):0] carCentreZone1X;
reg  [(YAXISMAXBITS-1):0] carCentreZone1Y;

reg  [(XAXISMAXBITS-1):0] carRightZone1X;
reg  [(YAXISMAXBITS-1):0] carRightZone1Y;


//ZONE 2
reg  [(XAXISMAXBITS-1):0] carLeftZone2X;
reg [(YAXISMAXBITS-1):0] carLeftZone2Y;

reg  [(XAXISMAXBITS-1):0] carCentreZone2X;
reg [(YAXISMAXBITS-1):0] carCentreZone2Y;

reg  [(XAXISMAXBITS-1):0] carRightZone2X;
reg [(YAXISMAXBITS-1):0] carRightZone2Y;

//ZONE 3
reg  [(XAXISMAXBITS-1):0] carLeftZone3X;
reg [(YAXISMAXBITS-1):0] carLeftZone3Y;

reg  [(XAXISMAXBITS-1):0] carCentreZone3X;
reg [(YAXISMAXBITS-1):0] carCentreZone3Y;

reg  [(XAXISMAXBITS-1):0] carRightZone3X;
reg [(YAXISMAXBITS-1):0] carRightZone3Y;


//ZONE 4
reg  [(XAXISMAXBITS-1):0] carLeftZone4X;
reg [(YAXISMAXBITS-1):0] carLeftZone4Y;

reg  [(XAXISMAXBITS-1):0] carCentreZone4X;
reg [(YAXISMAXBITS-1):0] carCentreZone4Y;

reg  [(XAXISMAXBITS-1):0] carRightZone4X;
reg [(YAXISMAXBITS-1):0] carRightZone4Y;
//------------------------------------------------------------------------------------------




//DECLARE POSSIBLE COLOURS FOR CARS
//------------------------------------------------------------------------------------------
reg [(PIXELDATALENGTH-1):0] BROWN_COLOUR = 16'hFC08; 
reg [(PIXELDATALENGTH-1):0] SKYE_BLUE_COLOUR = 16'h87FF; 
reg [(PIXELDATALENGTH-1):0] DARK_BLUE_COLOUR = 16'h001F; 
reg [(PIXELDATALENGTH-1):0] RED_COLOUR = 16'hF800; 
reg [(PIXELDATALENGTH-1):0] GREEN_COLOUR = 16'h87E0; 
reg [(PIXELDATALENGTH-1):0] YELLOW_COLOUR = 16'hFFE0; 
reg [(PIXELDATALENGTH-1):0] BLUISH_GREEN_COLOUR = 16'h87F0; 
reg [(PIXELDATALENGTH-1):0] DRY_BLUE_COLOUR = 16'h0210;
reg [(PIXELDATALENGTH-1):0] ORANGE_COLOUR = 16'hFC00;
//------------------------------------------------------------------------------------------

//DECLARE REGISTER TO SAVE TRAFFIC LIGHT COLOUR VALUES IN
//------------------------------------------------------------------------------------------
reg [(PIXELDATALENGTH-1):0] ZONE_1_TL_LEFT_COLOUR;
reg [(PIXELDATALENGTH-1):0] ZONE_1_TL_CENTRE_COLOUR;
reg [(PIXELDATALENGTH-1):0] ZONE_1_TL_RIGHT_COLOUR;
reg [(PIXELDATALENGTH-1):0] ZONE_1_TL_PEDESTRIAN_COLOUR;

reg [(PIXELDATALENGTH-1):0] ZONE_2_TL_LEFT_COLOUR;
reg [(PIXELDATALENGTH-1):0] ZONE_2_TL_CENTRE_COLOUR;
reg [(PIXELDATALENGTH-1):0] ZONE_2_TL_RIGHT_COLOUR;
reg [(PIXELDATALENGTH-1):0] ZONE_2_TL_PEDESTRIAN_COLOUR;

reg [(PIXELDATALENGTH-1):0] ZONE_3_TL_LEFT_COLOUR;
reg [(PIXELDATALENGTH-1):0] ZONE_3_TL_CENTRE_COLOUR;
reg [(PIXELDATALENGTH-1):0] ZONE_3_TL_RIGHT_COLOUR;
reg [(PIXELDATALENGTH-1):0] ZONE_3_TL_PEDESTRIAN_COLOUR;

reg [(PIXELDATALENGTH-1):0] ZONE_4_TL_LEFT_COLOUR;
reg [(PIXELDATALENGTH-1):0] ZONE_4_TL_CENTRE_COLOUR; 
reg [(PIXELDATALENGTH-1):0] ZONE_4_TL_RIGHT_COLOUR;
reg [(PIXELDATALENGTH-1):0] ZONE_4_TL_PEDESTRIAN_COLOUR;
//----------------------------------------------------------------------------------------------------





//------------------------------------------------------------------------------------------




//MAKE INITIALIZATIONS
//------------------------------------------------------------------------------------------
initial begin
xCentreLineTracker = 5'd0; //Initialize to zero
trafficLightRadius = 9'd5;

oneSecondCounter = 25'd0;
fiftyMilliSecondsCounter = 22'd0;
movementClock = 1'd0;

//CAR START POSITION INITIALIZATIONS
//-------------------------------------------------------------------------------------------
//ZONE 1
carLeftZone1X = ZONE1XSTART[(XAXISMAXBITS-1):0];
carLeftZone1Y = CARLEFTZONE1_Y_VAR[(YAXISMAXBITS-1):0];

carCentreZone1X = ZONE1XSTART[(XAXISMAXBITS-1):0];
carCentreZone1Y = CARCENTREZONE1_Y_VAR[(YAXISMAXBITS-1):0];

carRightZone1X = ZONE1XSTART[(XAXISMAXBITS-1):0];
carRightZone1Y = ZONE1YSTART[(YAXISMAXBITS-1):0];



//ZONE 2
carLeftZone2X = CARLEFTZONE2_X_VAR[(XAXISMAXBITS-1):0];
carLeftZone2Y = ZONE2YSTART[(YAXISMAXBITS-1):0];

carCentreZone2X = CARCENTREZONE2_X_VAR[(XAXISMAXBITS-1):0];
carCentreZone2Y = ZONE2YSTART[(YAXISMAXBITS-1):0];

carRightZone2X = ZONE2XSTART[(XAXISMAXBITS-1):0];
carRightZone2Y = ZONE2YSTART[(YAXISMAXBITS-1):0];


//ZONE 3
carLeftZone3X = ZONE3XSTART[(XAXISMAXBITS-1):0]; 
carLeftZone3Y = ZONE3YSTART[(YAXISMAXBITS-1):0];

carCentreZone3X = ZONE3XSTART[(XAXISMAXBITS-1):0]; 
carCentreZone3Y = CARCENTREZONE3_Y_VAR[(YAXISMAXBITS-1):0];

carRightZone3X = ZONE3XSTART[(XAXISMAXBITS-1):0];
carRightZone3Y = CARRIGHTZONE3_Y_VAR[(YAXISMAXBITS-1):0];

//ZONE 4
carLeftZone4X = ZONE4XSTART[(XAXISMAXBITS-1):0];
carLeftZone4Y =  ZONE4YSTART[(YAXISMAXBITS-1):0];

carCentreZone4X = CARCENTREZONE4_X_VAR[(XAXISMAXBITS-1):0]; 
carCentreZone4Y =ZONE4YSTART [(YAXISMAXBITS-1):0];

carRightZone4X = CARRIGHTZONE4_X_VAR[(XAXISMAXBITS-1):0];
carRightZone4Y =ZONE4YSTART[(YAXISMAXBITS-1):0];
//---------------------------------------------------------------------------------------------------------------


//INITIALIZE CAR SPEEDS
//--------------------------------------------------------------------------------------------------------------------
//ZONE 1 - CAR SPEED
zone1CarLeftSpeed =ZONE1_CAR_LEFT_SPEED[(CAR_SPEED_MAX_BIT-1):0];
zone1CarCentreSpeed =ZONE1_CAR_CENTRE_SPEED[(CAR_SPEED_MAX_BIT-1):0]; 
zone1CarRightSpeed =ZONE1_CAR_RIGHT_SPEED[(CAR_SPEED_MAX_BIT-1):0]; 

//ZONE 2 - CAR SPEED
zone2CarLeftSpeed =ZONE2_CAR_LEFT_SPEED[(CAR_SPEED_MAX_BIT-1):0];
zone2CarCentreSpeed =ZONE2_CAR_CENTRE_SPEED[(CAR_SPEED_MAX_BIT-1):0]; 
zone2CarRightSpeed =ZONE2_CAR_RIGHT_SPEED[(CAR_SPEED_MAX_BIT-1):0]; 

//ZONE 3 - CAR SPEED
zone3CarLeftSpeed =ZONE3_CAR_LEFT_SPEED[(CAR_SPEED_MAX_BIT-1):0];
zone3CarCentreSpeed =ZONE3_CAR_CENTRE_SPEED[(CAR_SPEED_MAX_BIT-1):0]; 
zone3CarRightSpeed =ZONE3_CAR_RIGHT_SPEED[(CAR_SPEED_MAX_BIT-1):0]; 

//ZONE 4 - CAR SPEED
zone4CarLeftSpeed =ZONE4_CAR_LEFT_SPEED[(CAR_SPEED_MAX_BIT-1):0];
zone4CarCentreSpeed =ZONE4_CAR_CENTRE_SPEED[(CAR_SPEED_MAX_BIT-1):0]; 
zone4CarRightSpeed =ZONE4_CAR_RIGHT_SPEED[(CAR_SPEED_MAX_BIT-1):0]; 

//--------------------------------------------------------------------------------------------------------------------


//INITIALIZE CAR MOVEMENT
//-------------------------------------------------------------------------------------------------------------------
//ZONE 1
zone1_car_left_moove_boolean = 1'd1;
zone1_car_left_moove_boolean= 1'd1;
zone1_car_left_moove_boolean= 1'd1;
zone1_pedestrian_moove_boolean= 1'd1;

//ZONE 2
zone2_car_left_moove_boolean= 1'd1;
zone2_car_left_moove_boolean= 1'd1;
zone2_car_left_moove_boolean= 1'd1;
zone2_pedestrian_moove_boolean= 1'd1;

//ZONE 3
zone3_car_left_moove_boolean= 1'd1;
zone3_car_left_moove_boolean= 1'd1;
zone3_car_left_moove_boolean= 1'd1;
zone3_pedestrian_moove_boolean= 1'd1;

//ZONE 4
zone4_car_left_moove_boolean= 1'd1;
zone4_car_left_moove_boolean= 1'd1;
zone4_car_left_moove_boolean= 1'd1;
zone4_pedestrian_moove_boolean= 1'd1;

//---------------------------------------------------------------------------------------------------------------------

//INITIALIZE TURNING POINTS
//-------------------------------------------------------------------------------------------------------------------
//RIGHT TURN
carRightZone1TurningPointX = CAR_RIGHT_Z1_TURNINGPOINT_X[(XAXISMAXBITS-1):0] ;
carRightZone1TurningPointY = CAR_RIGHT_Z1_TURNINGPOINT_Y[(YAXISMAXBITS-1):0]; 

carRightZone2TurningPointX = CAR_RIGHT_Z2_TURNINGPOINT_X[(XAXISMAXBITS-1):0] ;
carRightZone2TurningPointY = CAR_RIGHT_Z2_TURNINGPOINT_Y[(YAXISMAXBITS-1):0]; 

carRightZone3TurningPointX = CAR_RIGHT_Z3_TURNINGPOINT_X[(XAXISMAXBITS-1):0] ;
carRightZone3TurningPointY = CAR_RIGHT_Z3_TURNINGPOINT_Y[(YAXISMAXBITS-1):0]; 

carRightZone4TurningPointX = CAR_RIGHT_Z4_TURNINGPOINT_X[(XAXISMAXBITS-1):0];
carRightZone4TurningPointY = CAR_RIGHT_Z4_TURNINGPOINT_Y[(YAXISMAXBITS-1):0];

//LEFT TURN
carLeftZone1TurningPointX = CAR_LEFT_Z1_TURNINGPOINT_X[(XAXISMAXBITS-1):0] ;
carLeftZone1TurningPointY = CAR_LEFT_Z1_TURNINGPOINT_Y[(YAXISMAXBITS-1):0]; 

carLeftZone2TurningPointX = CAR_LEFT_Z2_TURNINGPOINT_X[(XAXISMAXBITS-1):0] ;
carLeftZone2TurningPointY = CAR_LEFT_Z2_TURNINGPOINT_Y[(YAXISMAXBITS-1):0]; 

carLeftZone3TurningPointX = CAR_LEFT_Z3_TURNINGPOINT_X[(XAXISMAXBITS-1):0] ;
carLeftZone3TurningPointY = CAR_LEFT_Z3_TURNINGPOINT_Y[(YAXISMAXBITS-1):0]; 

carLeftZone4TurningPointX = CAR_LEFT_Z4_TURNINGPOINT_X[(XAXISMAXBITS-1):0] ;
carLeftZone4TurningPointY = CAR_LEFT_Z4_TURNINGPOINT_Y[(YAXISMAXBITS-1):0];  
//--------------------------------------------------------------------------------------------------------------------

//INITIALIZE LEFT CAR TURNING HOPS
//-------------------------------------------------------------------------------------------------------------------
carLeftZone1TurningHop1X = CAR_LEFT_ZONE1_HOP1X[(XAXISMAXBITS-1):0];
carLeftZone1TurningHop1Y = CAR_LEFT_ZONE1_HOP1Y[(YAXISMAXBITS-1):0]; 
carLeftZone1TurningHop2X = CAR_LEFT_ZONE1_HOP2X[(XAXISMAXBITS-1):0] ;
carLeftZone1TurningHop2Y = CAR_LEFT_ZONE1_HOP2Y[(YAXISMAXBITS-1):0]; 
carLeftZone1TurningHop3X = CAR_LEFT_ZONE1_HOP3X[(XAXISMAXBITS-1):0];
carLeftZone1TurningHop3Y = CAR_LEFT_ZONE1_HOP3Y[(YAXISMAXBITS-1):0];


carLeftZone2TurningHop1X = CAR_LEFT_ZONE2_HOP1X[(XAXISMAXBITS-1):0];
carLeftZone2TurningHop1Y = CAR_LEFT_ZONE2_HOP1Y[(YAXISMAXBITS-1):0]; 
carLeftZone2TurningHop2X = CAR_LEFT_ZONE2_HOP2X[(XAXISMAXBITS-1):0] ;
carLeftZone2TurningHop2Y = CAR_LEFT_ZONE2_HOP2Y[(YAXISMAXBITS-1):0]; 
carLeftZone2TurningHop3X = CAR_LEFT_ZONE2_HOP3X[(XAXISMAXBITS-1):0];
carLeftZone2TurningHop3Y = CAR_LEFT_ZONE2_HOP3Y[(YAXISMAXBITS-1):0];


carLeftZone3TurningHop1X = CAR_LEFT_ZONE3_HOP1X[(XAXISMAXBITS-1):0];
carLeftZone3TurningHop1Y = CAR_LEFT_ZONE3_HOP1Y[(YAXISMAXBITS-1):0]; 
carLeftZone3TurningHop2X = CAR_LEFT_ZONE3_HOP2X[(XAXISMAXBITS-1):0] ;
carLeftZone3TurningHop2Y = CAR_LEFT_ZONE3_HOP2Y[(YAXISMAXBITS-1):0]; 
carLeftZone3TurningHop3X = CAR_LEFT_ZONE3_HOP3X[(XAXISMAXBITS-1):0];
carLeftZone3TurningHop3Y = CAR_LEFT_ZONE3_HOP3Y[(YAXISMAXBITS-1):0];


carLeftZone4TurningHop1X = CAR_LEFT_ZONE4_HOP1X[(XAXISMAXBITS-1):0];
carLeftZone4TurningHop1Y = CAR_LEFT_ZONE4_HOP1Y[(YAXISMAXBITS-1):0]; 
carLeftZone4TurningHop2X = CAR_LEFT_ZONE4_HOP2X[(XAXISMAXBITS-1):0] ;
carLeftZone4TurningHop2Y = CAR_LEFT_ZONE4_HOP2Y[(YAXISMAXBITS-1):0]; 
carLeftZone4TurningHop3X = CAR_LEFT_ZONE4_HOP3X[(XAXISMAXBITS-1):0];
carLeftZone4TurningHop3Y = CAR_LEFT_ZONE4_HOP3Y[(YAXISMAXBITS-1):0];

//-------------------------------------------------------------------------------------------------------------------



//TRAFFIC LIGHT INITIALIZATIONS
//--------------------------------------------------------------------------------------------------------------------
//ZONE 1 TRAFFIC CIRCLE
zone1TrafficCircleLeftCentreH = ZONE1_TRAFFIC_XSTART [(XAXISMAXBITS-1):0];
zone1TrafficCircleLeftCentreK = ZONE1_TRAFFIC_YSTART [(YAXISMAXBITS-1):0] ;

zone1TrafficCircleCentreCentreH = ZONE1_TRAFFIC_XSTART[(XAXISMAXBITS-1):0];
zone1TrafficCircleCentreCentreK = TRAFFIC_CENTRE_ZONE1_Y_VAR [(YAXISMAXBITS-1):0];

zone1TrafficCircleRightCentreH = ZONE1_TRAFFIC_XSTART[(XAXISMAXBITS-1):0];
zone1TrafficCircleRightCentreK = TRAFFIC_RIGHT_ZONE1_Y_VAR [(YAXISMAXBITS-1):0];

zone1TrafficCirclePedestrianCentreH = ZONE1_TRAFFIC_XSTART[(XAXISMAXBITS-1):0];
zone1TrafficCirclePedestrianCentreK = TRAFFIC_PEDESTRIAN_ZONE1_Y_VAR[(YAXISMAXBITS-1):0] ;

//ZONE 2 TRAFFIC CIRCLE CENTRE VARIABLE DECLARATION
zone2TrafficCircleLeftCentreH = ZONE2_TRAFFIC_XSTART[(XAXISMAXBITS-1):0];
zone2TrafficCircleLeftCentreK = ZONE2_TRAFFIC_YSTART[(YAXISMAXBITS-1):0];

zone2TrafficCircleCentreCentreH = TRAFFIC_CENTRE_ZONE2_X_VAR [(XAXISMAXBITS-1):0];
zone2TrafficCircleCentreCentreK = ZONE2_TRAFFIC_YSTART[(YAXISMAXBITS-1):0];

zone2TrafficCircleRightCentreH = TRAFFIC_RIGHT_ZONE2_X_VAR[(XAXISMAXBITS-1):0];
zone2TrafficCircleRightCentreK = ZONE2_TRAFFIC_YSTART[(YAXISMAXBITS-1):0];

zone2TrafficCirclePedestrianCentreH = TRAFFIC_PEDESTRIAN_ZONE2_X_VAR[(XAXISMAXBITS-1):0];
zone2TrafficCirclePedestrianCentreK = ZONE2_TRAFFIC_YSTART[(YAXISMAXBITS-1):0];

//ZONE 3 TRAFFIC CIRCLE CENTRE VARIABLE DECLARATION
zone3TrafficCircleLeftCentreH = ZONE3_TRAFFIC_XSTART [(XAXISMAXBITS-1):0];
zone3TrafficCircleLeftCentreK = ZONE3_TRAFFIC_YSTART[(YAXISMAXBITS-1):0];

zone3TrafficCircleCentreCentreH = ZONE3_TRAFFIC_XSTART [(XAXISMAXBITS-1):0] ;
zone3TrafficCircleCentreCentreK = TRAFFIC_CENTRE_ZONE3_Y_VAR[(YAXISMAXBITS-1):0];

zone3TrafficCircleRightCentreH = ZONE3_TRAFFIC_XSTART[(XAXISMAXBITS-1):0];
zone3TrafficCircleRightCentreK = TRAFFIC_RIGHT_ZONE3_Y_VAR[(YAXISMAXBITS-1):0];

zone3TrafficCirclePedestrianCentreH = ZONE3_TRAFFIC_XSTART[(XAXISMAXBITS-1):0];
zone3TrafficCirclePedestrianCentreK = TRAFFIC_PEDESTRIAN_ZONE3_Y_VAR[(YAXISMAXBITS-1):0];


//ZONE 4 TRAFFIC CIRCLE CENTRE VARIABLE DECLARATION
zone4TrafficCircleLeftCentreH = ZONE4_TRAFFIC_XSTART[(XAXISMAXBITS-1):0];
zone4TrafficCircleLeftCentreK = ZONE4_TRAFFIC_YSTART[(YAXISMAXBITS-1):0];

zone4TrafficCircleCentreCentreH = TRAFFIC_CENTRE_ZONE4_X_VAR[(XAXISMAXBITS-1):0];
zone4TrafficCircleCentreCentreK = ZONE4_TRAFFIC_YSTART[(YAXISMAXBITS-1):0];

zone4TrafficCircleRightCentreH = TRAFFIC_RIGHT_ZONE4_X_VAR[(XAXISMAXBITS-1):0];
zone4TrafficCircleRightCentreK = ZONE4_TRAFFIC_YSTART[(YAXISMAXBITS-1):0];

zone4TrafficCirclePedestrianCentreH = TRAFFIC_PEDESTRIAN_ZONE4_X_VAR[(XAXISMAXBITS-1):0];
zone4TrafficCirclePedestrianCentreK = ZONE4_TRAFFIC_YSTART[(YAXISMAXBITS-1):0];
//--------------------------------------------------------------------------------------------------------------------




//INITIALIZE TRAFFIC LIGHT COLOURS
//-------------------------------------------------------------------------------------------------------------------
ZONE_1_TL_LEFT_COLOUR = 16'hF800; //RED COLOUR
ZONE_1_TL_CENTRE_COLOUR = 16'hF800; 
ZONE_1_TL_RIGHT_COLOUR = 16'hF800;
ZONE_1_TL_PEDESTRIAN_COLOUR = 16'hF800;

ZONE_2_TL_LEFT_COLOUR = 16'hF800;
ZONE_2_TL_CENTRE_COLOUR = 16'hF800; 
ZONE_2_TL_RIGHT_COLOUR = 16'hF800;
ZONE_2_TL_PEDESTRIAN_COLOUR = 16'hF800;

ZONE_3_TL_LEFT_COLOUR = 16'hF800;
ZONE_3_TL_CENTRE_COLOUR = 16'hF800; 
ZONE_3_TL_RIGHT_COLOUR = 16'hF800;
ZONE_3_TL_PEDESTRIAN_COLOUR = 16'hF800;

ZONE_4_TL_LEFT_COLOUR = 16'hF800;
ZONE_4_TL_CENTRE_COLOUR = 16'hF800; 
ZONE_4_TL_RIGHT_COLOUR = 16'hF800;
ZONE_4_TL_PEDESTRIAN_COLOUR = 16'hF800;

//-------------------------------------------------------------------------------------------------------------------


//INITIALIZE PEDESTRIAN MOVEMENT
//--------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------


//INITIALIZE TRAFFIC LIGHT CHANGE SPEED
trafficStateDuration = TRAFFIC_STATE_DURATION_FACTOR[(TRAFFIC_STATE_DURATION_FACTOR_REG_LENGTH-1):0] *  CLOCK_SPEED[ (CLOCK_COUNTER_REG_LENGTH-1):0];


end //-End of initializaions
//----------------------------------------------------------------------------------------------------------------


LT24Display #(
    .WIDTH       (240        ),
    .HEIGHT      (320        ),
    .CLOCK_FREQ  (50000000   )
) Display (
    .clock       (clock      ),
    .globalReset (globalReset),
    .resetApp    (resetApp   ),
    .xAddr       (xAddr      ),
    .yAddr       (yAddr      ),
    .pixelData   (pixelData  ),
    .pixelWrite  (1'b1       ),
    .pixelReady  (pixelReady ),
	 .pixelRawMode(1'b0       ),
    .cmdData     (8'b0       ),
    .cmdWrite    (1'b0       ),
    .cmdDone     (1'b0       ),
    .cmdReady    (           ),
    .LT24_WRn    (LT24_WRn   ),
    .LT24_RDn    (LT24_RDn   ),
    .LT24_CSn    (LT24_CSn   ),
    .LT24_RS     (LT24_RS    ),
    .LT24_RESETn (LT24_RESETn),
    .LT24_D      (LT24_D     ),
    .LT24_LCD_ON (LT24_LCD_ON)
);

// X Counter
always @ (posedge clock or posedge resetApp) begin
    //If Reset button is pressed
	 if (resetApp) begin
        xAddr <= 8'b0;
		  
    end else if (pixelReady) begin
        if (xAddr < (WIDTH-1)) begin
            xAddr <= xAddr + 8'd1; //Increment xAddress by one each time
				singleXMovementTracker <=singleXMovementTracker +8'd1;
				xCentreLineTracker <= xCentreLineTracker+ 5'd1; //Increment central line tracker by one
				xCentreLineTracker2 <= xCentreLineTracker2+ 5'd1; //Increment central line tracker by one
				
				//Return xmovement counter back to zero after 18 counts or XAddr=0;
				if((xCentreLineTracker>=5'd18))begin
				xCentreLineTracker<=5'd0;
		end
		
			if((xCentreLineTracker2>=5'd18))begin
				xCentreLineTracker2<=5'd0;
		end
        end else begin
            xAddr <= 8'b0; //If addess overflows width, return to 0;
				singleXMovementTracker <=8'b0;
				xCentreLineTracker<=5'd0; //Return centre line tracker back to zero at XAddr=0;
				
				//Increment swipe scan by 1 i.e one complete horizontal scan completed
				swipeCounter <= swipeCounter + 9'd1;
			   yCentreLineTracker <= yCentreLineTracker +5'd1;	//Y-Center dotted white line tracker
					   yCentreLineTracker2 <= yCentreLineTracker2 +5'd1;	//Y-Center dotted white line tracker
				
				//Return Y center line tracker back to 0 after 18 counts or YAddr ==0
				if((yCentreLineTracker>=5'd18) || (yAddr==8'd0))begin
				yCentreLineTracker<=5'd0; 
				end
				
				//for pedestrian dotted lines
				if((yCentreLineTracker2>=5'd18))begin
				yCentreLineTracker2<=5'd0; 
				end
        end
    end
end

// Y Counter
always @ (posedge clock or posedge resetApp) begin
    if (resetApp) begin
        yAddr <= 9'b0;
    end else if (pixelReady && (xAddr == (WIDTH-1))) begin
        if (yAddr < (HEIGHT-1)) begin
            yAddr <= yAddr + 9'd1;
        end else begin
            yAddr <= 9'b0;
				swipeCounter <= 9'b0; 
        end
    end
end

always @ (posedge clock) begin
    //If refresh button is pressed, refresh display
	 if (resetApp) begin
        pixelData[4:0] <= 5'b0; 
  
    //When refresh button is released
	 //Paint green grasses on road side
	 //Each road is 120 pixels wide
	 end else if((((xAddr<=((WIDTH/4)-1)) && (yAddr<=(HEIGHT/4)-1+20)) || ((xAddr>=((WIDTH/4)+(WIDTH/2)-1)) && (yAddr<=(HEIGHT/4)-1+20)) || ((xAddr<=((WIDTH/4)-1)) && (yAddr>=(HEIGHT/4)+(HEIGHT/2)-1-20)) ||  ((xAddr>=((WIDTH/4)+(WIDTH/2)-1)) && (yAddr>=(HEIGHT/4)+(HEIGHT/2)-1-20))))		 begin	
		pixelData[(PIXELDATALENGTH-1):0] <= 16'h8400; //Paint Varandar Gold
    end else begin
	 pixelData[(PIXELDATALENGTH-1):0] <= 16'h0000; //Paint general black 
	 end
	 
	 
		
		//For the dotted line running downwards on the Y axix and Horizontally on the X axix	
		if(resetApp) begin
		//Do Nothing
		end else begin	
		if((xAddr==((WIDTH/2)-1)) && (yCentreLineTracker<=5'd9)) begin
			pixelData[(PIXELDATALENGTH-1):0] <= 16'hFFFF; //Paint white lines on the Y axis
		end else if	((yAddr==((HEIGHT/2)-1)) && (xCentreLineTracker<=5'd9))  begin
		pixelData[(PIXELDATALENGTH-1):0] <= 16'hFFFF; //Paint white lines on the X axis
		end
		
		
		end
		
		
		//For pedestrian crossing - zone 1
		if(zone1_pedestrian_moove_boolean==1'b1 && yAddr>=ZONE1_PEDESTRIAN_Y_START && yAddr<=ZONE1_PEDESTRIAN_Y_START+60 && xAddr==ZONE1_PEDESTRIAN_X_START &&  yCentreLineTracker<=5'd9) begin
		pixelData[(PIXELDATALENGTH-1):0]  = BLUISH_GREEN_COLOUR;
		end
		
		//For pedestrian crossing - zone 2
		if(zone2_pedestrian_moove_boolean==1'b1 && xAddr<=ZONE2_PEDESTRIAN_X_START && xAddr>=ZONE2_PEDESTRIAN_X_START-60 && yAddr==ZONE2_PEDESTRIAN_Y_START &&  xCentreLineTracker<=5'd9) begin
		pixelData[(PIXELDATALENGTH-1):0]  = BLUISH_GREEN_COLOUR;
		end
		
		//For pedestrian crossing - zone 3
		if(zone3_pedestrian_moove_boolean==1'b1 && yAddr>=ZONE3_PEDESTRIAN_Y_START && yAddr<=ZONE3_PEDESTRIAN_Y_START+60 && xAddr==ZONE3_PEDESTRIAN_X_START &&  yCentreLineTracker<=5'd9) begin
		pixelData[(PIXELDATALENGTH-1):0]  = BLUISH_GREEN_COLOUR;
		end
		
		//For pedestrian crossing - zone 4
		if(zone4_pedestrian_moove_boolean==1'b1 && xAddr>=ZONE4_PEDESTRIAN_X_START && xAddr<=ZONE4_PEDESTRIAN_X_START+60 && yAddr==ZONE4_PEDESTRIAN_Y_START &&  xCentreLineTracker<=5'd9) begin
		pixelData[(PIXELDATALENGTH-1):0]  = BLUISH_GREEN_COLOUR;
		end
		
	
//For the Cars -> 3 lanes per road side -> 3 squares, 4 zones
		//ZONE 1
		//Zone 1 Car Left
		if((((xAddr>=(carLeftZone1X - HALFCARSIZE [(XAXISMAXBITS-1):0]) )) && (xAddr<=(carLeftZone1X + HALFCARSIZE [(XAXISMAXBITS-1):0])))   && ((yAddr>=(carLeftZone1Y - HALFCARSIZE [(YAXISMAXBITS-1):0])) && (yAddr<=(carLeftZone1Y + HALFCARSIZE [(YAXISMAXBITS-1):0]))))  begin
		pixelData[(PIXELDATALENGTH-1):0] <= BROWN_COLOUR; //Car Left Zone 1 -> Brown
		end
		
		
		//Zone 1 Car Centre
		if((((xAddr>=(carCentreZone1X - HALFCARSIZE [(XAXISMAXBITS-1):0]) )) && (xAddr<=(carCentreZone1X + HALFCARSIZE [(XAXISMAXBITS-1):0])))   && ((yAddr>=(carCentreZone1Y - HALFCARSIZE [(YAXISMAXBITS-1):0])) && (yAddr<=(carCentreZone1Y + HALFCARSIZE [(YAXISMAXBITS-1):0]))))  begin
		pixelData[(PIXELDATALENGTH-1):0] <= DARK_BLUE_COLOUR; //Car Left Zone 1 -> Dark Blue
		end
		
		//Zone 1 Car Right
		if((((xAddr>=(carRightZone1X - HALFCARSIZE [(XAXISMAXBITS-1):0]) )) && (xAddr<=(carRightZone1X + HALFCARSIZE [(XAXISMAXBITS-1):0])))   && ((yAddr>=(carRightZone1Y - HALFCARSIZE [(YAXISMAXBITS-1):0])) && (yAddr<=(carRightZone1Y + HALFCARSIZE [(YAXISMAXBITS-1):0]))))  begin
		pixelData[(PIXELDATALENGTH-1):0] <= SKYE_BLUE_COLOUR; //Car Left Zone 1 -> Skye Blue
		end
		
	
		
		//ZONE 2
		//Zone 2 Car Left
		if((((xAddr>=(carLeftZone2X - HALFCARSIZE [(XAXISMAXBITS-1):0]) )) && (xAddr<=(carLeftZone2X + HALFCARSIZE [(XAXISMAXBITS-1):0])))   && ((yAddr>=(carLeftZone2Y - HALFCARSIZE [(YAXISMAXBITS-1):0])) && (yAddr<=(carLeftZone2Y + HALFCARSIZE [(YAXISMAXBITS-1):0]))))  begin
		pixelData[(PIXELDATALENGTH-1):0] <= DARK_BLUE_COLOUR; //Car Left Zone 1 -> Dark Blue
		end
		
		
		//Zone 2 Car Centre
		if((((xAddr>=(carCentreZone2X - HALFCARSIZE [(XAXISMAXBITS-1):0]) )) && (xAddr<=(carCentreZone2X + HALFCARSIZE [(XAXISMAXBITS-1):0])))   && ((yAddr>=(carCentreZone2Y - HALFCARSIZE [(YAXISMAXBITS-1):0])) && (yAddr<=(carCentreZone2Y + HALFCARSIZE [(YAXISMAXBITS-1):0]))))  begin
		pixelData[(PIXELDATALENGTH-1):0] <= BROWN_COLOUR; //Car Left Zone 1 -> Brown
		end
		
		//Zone 2 Car Right
		if((((xAddr>=(carRightZone2X - HALFCARSIZE [(XAXISMAXBITS-1):0]) )) && (xAddr<=(carRightZone2X + HALFCARSIZE [(XAXISMAXBITS-1):0])))   && ((yAddr>=(carRightZone2Y - HALFCARSIZE [(YAXISMAXBITS-1):0])) && (yAddr<=(carRightZone2Y + HALFCARSIZE [(YAXISMAXBITS-1):0]))))  begin
		pixelData[(PIXELDATALENGTH-1):0] <= SKYE_BLUE_COLOUR; //Car Left Zone 1 -> Skye_Blue
		end
		
		
		
			//ZONE 3
		//Zone 3 Car Left
		if((((xAddr>=(carLeftZone3X - HALFCARSIZE [(XAXISMAXBITS-1):0]) )) && (xAddr<=(carLeftZone3X + HALFCARSIZE [(XAXISMAXBITS-1):0])))   && ((yAddr>=(carLeftZone3Y - HALFCARSIZE [(YAXISMAXBITS-1):0])) && (yAddr<=(carLeftZone3Y + HALFCARSIZE [(YAXISMAXBITS-1):0]))))  begin
		pixelData[(PIXELDATALENGTH-1):0] <= DARK_BLUE_COLOUR; //Car Left Zone 1 -> Dark Blue
		end
		
		
		//Zone 3 Car Centre
		if((((xAddr>=(carCentreZone3X - HALFCARSIZE [(XAXISMAXBITS-1):0]) )) && (xAddr<=(carCentreZone3X + HALFCARSIZE [(XAXISMAXBITS-1):0])))   && ((yAddr>=(carCentreZone3Y - HALFCARSIZE [(YAXISMAXBITS-1):0])) && (yAddr<=(carCentreZone3Y + HALFCARSIZE [(YAXISMAXBITS-1):0]))))  begin
		pixelData[(PIXELDATALENGTH-1):0] <= SKYE_BLUE_COLOUR; //Car Left Zone 1 -> Skye Blue
		end
		
		//Zone 3 Car Right
		if((((xAddr>=(carRightZone3X - HALFCARSIZE [(XAXISMAXBITS-1):0]) )) && (xAddr<=(carRightZone3X + HALFCARSIZE [(XAXISMAXBITS-1):0])))   && ((yAddr>=(carRightZone3Y - HALFCARSIZE [(YAXISMAXBITS-1):0])) && (yAddr<=(carRightZone3Y + HALFCARSIZE [(YAXISMAXBITS-1):0]))))  begin
		pixelData[(PIXELDATALENGTH-1):0] <= BROWN_COLOUR; //Car Left Zone 1 -> Brown
		end
		
		
			//ZONE 4
		//Zone 4 Car Left
		if((((xAddr>=(carLeftZone4X - HALFCARSIZE [(XAXISMAXBITS-1):0]) )) && (xAddr<=(carLeftZone4X + HALFCARSIZE [(XAXISMAXBITS-1):0])))   && ((yAddr>=(carLeftZone4Y - HALFCARSIZE [(YAXISMAXBITS-1):0])) && (yAddr<=(carLeftZone4Y + HALFCARSIZE [(YAXISMAXBITS-1):0]))))  begin
		pixelData[(PIXELDATALENGTH-1):0] <= SKYE_BLUE_COLOUR; //Car Left Zone 1 -> Skye Blue
		end
		
		
		//Zone 4 Car Centre
		if((((xAddr>=(carCentreZone4X - HALFCARSIZE [(XAXISMAXBITS-1):0]) )) && (xAddr<=(carCentreZone4X + HALFCARSIZE [(XAXISMAXBITS-1):0])))   && ((yAddr>=(carCentreZone4Y - HALFCARSIZE [(YAXISMAXBITS-1):0])) && (yAddr<=(carCentreZone4Y + HALFCARSIZE [(YAXISMAXBITS-1):0]))))  begin
		pixelData[(PIXELDATALENGTH-1):0] <= BROWN_COLOUR; //Car Left Zone 1 -> Brown
		end
		
		//Zone 4 Car Right
		if((((xAddr>=(carRightZone4X - HALFCARSIZE [(XAXISMAXBITS-1):0]) )) && (xAddr<=(carRightZone4X + HALFCARSIZE [(XAXISMAXBITS-1):0])))   && ((yAddr>=(carRightZone4Y - HALFCARSIZE [(YAXISMAXBITS-1):0])) && (yAddr<=(carRightZone4Y + HALFCARSIZE [(YAXISMAXBITS-1):0]))))  begin
		pixelData[(PIXELDATALENGTH-1):0] <= DARK_BLUE_COLOUR; //Car Left Zone 1 -> Dark Blue
		end
		
		
		//Draw Traffic Light Circles
		//Calculate Using Bresenham Formular
		trafficLightRadiusSquared <= trafficLightRadius*trafficLightRadius;
		
		//DRAW ZONE 1 TRAFFIC LIGHTS
	   //------------------------------------------------------------------------------------
		//ZONE 1 - Traffic Light LEFT
		bresenhamsLeft_Z1_TLL <= (signedXAddr - zone1TrafficCircleLeftCentreH)*(signedXAddr - zone1TrafficCircleLeftCentreH);
		bresenhamsRight_Z1_TLL <= (signedYAddr - zone1TrafficCircleLeftCentreK)*(signedYAddr - zone1TrafficCircleLeftCentreK); 
		bresenhamsTotalLeftHandSide_Z1_TLL <= bresenhamsLeft_Z1_TLL + bresenhamsRight_Z1_TLL;	
		
		if(bresenhamsTotalLeftHandSide_Z1_TLL<=trafficLightRadiusSquared) begin
		pixelData[(PIXELDATALENGTH-1):0] <= ZONE_1_TL_LEFT_COLOUR; //DRAW ZONE 1 TRAFFIC LIGHT
		
		end
		
		//ZONE 1 - Traffic Light CENTRE
		bresenhamsLeft_Z1_TLC <= (signedXAddr - zone1TrafficCircleCentreCentreH)*(signedXAddr - zone1TrafficCircleCentreCentreH);
		bresenhamsRight_Z1_TLC <= (signedYAddr - zone1TrafficCircleCentreCentreK)*(signedYAddr - zone1TrafficCircleCentreCentreK); 
		bresenhamsTotalLeftHandSide_Z1_TLC <= bresenhamsLeft_Z1_TLC + bresenhamsRight_Z1_TLC;
		
		if(bresenhamsTotalLeftHandSide_Z1_TLC<=trafficLightRadiusSquared) begin
		pixelData[(PIXELDATALENGTH-1):0] <= ZONE_1_TL_CENTRE_COLOUR; //DRAW ZONE 1 TRAFFIC CENTRE
		end
		
		//ZONE 1 - Traffic Light RIGHT
		bresenhamsLeft_Z1_TLR <= (signedXAddr - zone1TrafficCircleRightCentreH)*(signedXAddr - zone1TrafficCircleRightCentreH);
		bresenhamsRight_Z1_TLR <= (signedYAddr - zone1TrafficCircleRightCentreK)*(signedYAddr - zone1TrafficCircleRightCentreK); 
		bresenhamsTotalLeftHandSide_Z1_TLR <= bresenhamsLeft_Z1_TLR + bresenhamsRight_Z1_TLR;
		
		if(bresenhamsTotalLeftHandSide_Z1_TLR<=trafficLightRadiusSquared) begin
		pixelData[(PIXELDATALENGTH-1):0] <= ZONE_1_TL_RIGHT_COLOUR; //DRAW ZONE 1 TRAFFIC RIGHT
		end
		
		//ZONE 1 - Traffic Light PEDESTRIAN
		bresenhamsLeft_Z1_TLP <= (signedXAddr - zone1TrafficCirclePedestrianCentreH)*(signedXAddr - zone1TrafficCirclePedestrianCentreH);
		bresenhamsRight_Z1_TLP <= (signedYAddr - zone1TrafficCirclePedestrianCentreK)*(signedYAddr - zone1TrafficCirclePedestrianCentreK); 
		bresenhamsTotalLeftHandSide_Z1_TLP <= bresenhamsLeft_Z1_TLP + bresenhamsRight_Z1_TLP;
		
		if(bresenhamsTotalLeftHandSide_Z1_TLP<=trafficLightRadiusSquared) begin
		pixelData[(PIXELDATALENGTH-1):0] <= ZONE_1_TL_PEDESTRIAN_COLOUR; //DRAW ZONE 1 TRAFFIC PEDESTRIAN
		end
		
//--------------------------------------------------------------------------------------------------------------------
		
		//DRAW ZONE 2 TRAFFIC LIGHTS
//--------------------------------------------------------------------------------------------------------------------
		//ZONE 2 - Traffic Light LEFT
		bresenhamsLeft_Z2_TLL <= (signedXAddr - zone2TrafficCircleLeftCentreH)*(signedXAddr - zone2TrafficCircleLeftCentreH);
		bresenhamsRight_Z2_TLL <= (signedYAddr - zone2TrafficCircleLeftCentreK)*(signedYAddr - zone2TrafficCircleLeftCentreK); 
		bresenhamsTotalLeftHandSide_Z2_TLL <= bresenhamsLeft_Z2_TLL + bresenhamsRight_Z2_TLL;	
		
		if(bresenhamsTotalLeftHandSide_Z2_TLL<=trafficLightRadiusSquared) begin
		pixelData[(PIXELDATALENGTH-1):0] <= ZONE_2_TL_LEFT_COLOUR; //DRAW ZONE 2 TRAFFIC LIGHT
		end
		
		//ZONE 2 - Traffic Light CENTRE
		bresenhamsLeft_Z2_TLC <= (signedXAddr - zone2TrafficCircleCentreCentreH)*(signedXAddr - zone2TrafficCircleCentreCentreH);
		bresenhamsRight_Z2_TLC <= (signedYAddr - zone2TrafficCircleCentreCentreK)*(signedYAddr - zone2TrafficCircleCentreCentreK); 
		bresenhamsTotalLeftHandSide_Z2_TLC <= bresenhamsLeft_Z2_TLC + bresenhamsRight_Z2_TLC;
		
		if(bresenhamsTotalLeftHandSide_Z2_TLC<=trafficLightRadiusSquared) begin
		pixelData[(PIXELDATALENGTH-1):0] <= ZONE_2_TL_CENTRE_COLOUR; //DRAW ZONE 2 TRAFFIC CENTRE
		end
		
		//ZONE 2 - Traffic Light RIGHT
		bresenhamsLeft_Z2_TLR <= (signedXAddr - zone2TrafficCircleRightCentreH)*(signedXAddr - zone2TrafficCircleRightCentreH);
		bresenhamsRight_Z2_TLR <= (signedYAddr - zone2TrafficCircleRightCentreK)*(signedYAddr - zone2TrafficCircleRightCentreK); 
		bresenhamsTotalLeftHandSide_Z2_TLR <= bresenhamsLeft_Z2_TLR + bresenhamsRight_Z2_TLR;
		
		if(bresenhamsTotalLeftHandSide_Z2_TLR<=trafficLightRadiusSquared) begin
		pixelData[(PIXELDATALENGTH-1):0] <= ZONE_2_TL_RIGHT_COLOUR; //DRAW ZONE 2 TRAFFIC RIGHT
		end
		
		//ZONE 2 - Traffic Light PEDESTRIAN
		bresenhamsLeft_Z2_TLP <= (signedXAddr - zone2TrafficCirclePedestrianCentreH)*(signedXAddr - zone2TrafficCirclePedestrianCentreH);
		bresenhamsRight_Z2_TLP <= (signedYAddr - zone2TrafficCirclePedestrianCentreK)*(signedYAddr - zone2TrafficCirclePedestrianCentreK); 
		bresenhamsTotalLeftHandSide_Z2_TLP <= bresenhamsLeft_Z2_TLP + bresenhamsRight_Z2_TLP;
		
		if(bresenhamsTotalLeftHandSide_Z2_TLP<=trafficLightRadiusSquared) begin
		pixelData[(PIXELDATALENGTH-1):0] <= ZONE_2_TL_PEDESTRIAN_COLOUR; //DRAW ZONE 2 TRAFFIC PEDESTRIAN
		end
//--------------------------------------------------------------------------------------------------------------------


//DRAW ZONE 3 TRAFFIC LIGHTS
//--------------------------------------------------------------------------------------------------------------------
		//ZONE 3 - Traffic Light LEFT
		bresenhamsLeft_Z3_TLL <= (signedXAddr - zone3TrafficCircleLeftCentreH)*(signedXAddr - zone3TrafficCircleLeftCentreH);
		bresenhamsRight_Z3_TLL <= (signedYAddr - zone3TrafficCircleLeftCentreK)*(signedYAddr - zone3TrafficCircleLeftCentreK); 
		bresenhamsTotalLeftHandSide_Z3_TLL <= bresenhamsLeft_Z3_TLL + bresenhamsRight_Z3_TLL;	
		
		if(bresenhamsTotalLeftHandSide_Z3_TLL<=trafficLightRadiusSquared) begin
		pixelData[(PIXELDATALENGTH-1):0] <= ZONE_3_TL_LEFT_COLOUR; //DRAW ZONE 3 TRAFFIC LIGHT
		end
		
		//ZONE 3 - Traffic Light CENTRE
		bresenhamsLeft_Z3_TLC <= (signedXAddr - zone3TrafficCircleCentreCentreH)*(signedXAddr - zone3TrafficCircleCentreCentreH);
		bresenhamsRight_Z3_TLC <= (signedYAddr - zone3TrafficCircleCentreCentreK)*(signedYAddr - zone3TrafficCircleCentreCentreK); 
		bresenhamsTotalLeftHandSide_Z3_TLC <= bresenhamsLeft_Z3_TLC + bresenhamsRight_Z3_TLC;
		
		if(bresenhamsTotalLeftHandSide_Z3_TLC<=trafficLightRadiusSquared) begin
		pixelData[(PIXELDATALENGTH-1):0] <= ZONE_3_TL_CENTRE_COLOUR; //DRAW ZONE 3 TRAFFIC CENTRE
		end
		
		//ZONE 3 - Traffic Light RIGHT
		bresenhamsLeft_Z3_TLR <= (signedXAddr - zone3TrafficCircleRightCentreH)*(signedXAddr - zone3TrafficCircleRightCentreH);
		bresenhamsRight_Z3_TLR <= (signedYAddr - zone3TrafficCircleRightCentreK)*(signedYAddr - zone3TrafficCircleRightCentreK); 
		bresenhamsTotalLeftHandSide_Z3_TLR <= bresenhamsLeft_Z3_TLR + bresenhamsRight_Z3_TLR;
		
		if(bresenhamsTotalLeftHandSide_Z3_TLR<=trafficLightRadiusSquared) begin
		pixelData[(PIXELDATALENGTH-1):0] <= ZONE_3_TL_RIGHT_COLOUR; //DRAW ZONE 3 TRAFFIC RIGHT
		end
		
			//ZONE 3 - Traffic Light PEDESTRIAN
		bresenhamsLeft_Z3_TLP <= (signedXAddr - zone3TrafficCirclePedestrianCentreH)*(signedXAddr - zone3TrafficCirclePedestrianCentreH);
		bresenhamsRight_Z3_TLP <= (signedYAddr - zone3TrafficCirclePedestrianCentreK)*(signedYAddr - zone3TrafficCirclePedestrianCentreK); 
		bresenhamsTotalLeftHandSide_Z3_TLP <= bresenhamsLeft_Z3_TLP + bresenhamsRight_Z3_TLP;
		
		if(bresenhamsTotalLeftHandSide_Z3_TLP<=trafficLightRadiusSquared) begin
		pixelData[(PIXELDATALENGTH-1):0] <= ZONE_3_TL_PEDESTRIAN_COLOUR; //DRAW ZONE 3 TRAFFIC PEDESTRIAN
		end
//--------------------------------------------------------------------------------------------------------------------



//DRAW ZONE 4 TRAFFIC LIGHTS
//--------------------------------------------------------------------------------------------------------------------
		//ZONE 4 - Traffic Light LEFT
		bresenhamsLeft_Z4_TLL <= (signedXAddr - zone4TrafficCircleLeftCentreH)*(signedXAddr - zone4TrafficCircleLeftCentreH);
		bresenhamsRight_Z4_TLL <= (signedYAddr - zone4TrafficCircleLeftCentreK)*(signedYAddr - zone4TrafficCircleLeftCentreK); 
		bresenhamsTotalLeftHandSide_Z4_TLL <= bresenhamsLeft_Z4_TLL + bresenhamsRight_Z4_TLL;	
		
		if(bresenhamsTotalLeftHandSide_Z4_TLL<=trafficLightRadiusSquared) begin
		pixelData[(PIXELDATALENGTH-1):0] <= ZONE_4_TL_LEFT_COLOUR; //DRAW ZONE 4 TRAFFIC LIGHT
		end
		
		//ZONE 4 - Traffic Light CENTRE
		bresenhamsLeft_Z4_TLC <= (signedXAddr - zone4TrafficCircleCentreCentreH)*(signedXAddr - zone4TrafficCircleCentreCentreH);
		bresenhamsRight_Z4_TLC <= (signedYAddr - zone4TrafficCircleCentreCentreK)*(signedYAddr - zone4TrafficCircleCentreCentreK); 
		bresenhamsTotalLeftHandSide_Z4_TLC <= bresenhamsLeft_Z4_TLC + bresenhamsRight_Z4_TLC;
		
		if(bresenhamsTotalLeftHandSide_Z4_TLC<=trafficLightRadiusSquared) begin
		pixelData[(PIXELDATALENGTH-1):0] <= ZONE_4_TL_CENTRE_COLOUR; //DRAW ZONE 4 TRAFFIC CENTRE
		end
		
		//ZONE 4 - Traffic Light RIGHT
		bresenhamsLeft_Z4_TLR <= (signedXAddr - zone4TrafficCircleRightCentreH)*(signedXAddr - zone4TrafficCircleRightCentreH);
		bresenhamsRight_Z4_TLR <= (signedYAddr - zone4TrafficCircleRightCentreK)*(signedYAddr - zone4TrafficCircleRightCentreK); 
		bresenhamsTotalLeftHandSide_Z4_TLR <= bresenhamsLeft_Z4_TLR + bresenhamsRight_Z4_TLR;
		
		if(bresenhamsTotalLeftHandSide_Z4_TLR<=trafficLightRadiusSquared) begin
		pixelData[(PIXELDATALENGTH-1):0] <= ZONE_4_TL_RIGHT_COLOUR; //DRAW ZONE 4 TRAFFIC RIGHT
		end
		
		
			//ZONE 3 - Traffic Light PEDESTRIAN
		bresenhamsLeft_Z4_TLP <= (signedXAddr - zone4TrafficCirclePedestrianCentreH)*(signedXAddr - zone4TrafficCirclePedestrianCentreH);
		bresenhamsRight_Z4_TLP <= (signedYAddr - zone4TrafficCirclePedestrianCentreK)*(signedYAddr - zone4TrafficCirclePedestrianCentreK); 
		bresenhamsTotalLeftHandSide_Z4_TLP <= bresenhamsLeft_Z4_TLP + bresenhamsRight_Z4_TLP;
		
		if(bresenhamsTotalLeftHandSide_Z4_TLP<=trafficLightRadiusSquared) begin
		pixelData[(PIXELDATALENGTH-1):0] <= ZONE_4_TL_PEDESTRIAN_COLOUR; //DRAW ZONE 1 TRAFFIC PEDESTRIAN
		end
//--------------------------------------------------------------------------------------------------------------------











//-------------------------------------------------------------------------------------------------------------------
		
end //For the always block





//USE THE 50MHZ CLOCK TO DRIVE CAR MOVEMENT
always @ (posedge clock) begin

if(clock) begin
//50 Mhz clock ticks every 2*10^-8 seconds
//It will take 50ms to complete 2.5 million ticks

fiftyMilliSecondsCounter = fiftyMilliSecondsCounter +22'd1;

if(fiftyMilliSecondsCounter == 22'd1250000) begin
movementClock <= !movementClock; //Clock will fire every 50 milliseconds second cos clock is on posedge
fiftyMilliSecondsCounter <= 22'd0; //Reset Clock back to zero;
end
end //End of it clock
end //End of the always block
 

 
 
 //CREATE ALWAYS BLOCK WHICH CLOCKS THE CAR MOVEMENT SPEED
 always @ (posedge movementClock) begin
//Fastest Speed is 50ms per move. Thats ratio 1
//Speed of 1 is the fasted, while speed of 15 is the slowest
 if(movementClock) begin
//Tick, to determine which sets of cars are to move now 
//------------------------------------------------------------------------
//ZONE 1 CARS
zone1CarLeftTicker <= zone1CarLeftTicker + ONE[(CAR_SPEED_MAX_BIT-1):0] ;
zone1CarCentreTicker <= zone1CarCentreTicker +ONE[(CAR_SPEED_MAX_BIT-1):0];  
zone1CarRightTicker <= zone1CarRightTicker  +ONE[(CAR_SPEED_MAX_BIT-1):0];  
 
 //ZONE 2 CARS
zone2CarLeftTicker <= zone2CarLeftTicker + ONE[(CAR_SPEED_MAX_BIT-1):0] ;
zone2CarCentreTicker <= zone2CarCentreTicker +ONE[(CAR_SPEED_MAX_BIT-1):0];  
zone2CarRightTicker <= zone2CarRightTicker  +ONE[(CAR_SPEED_MAX_BIT-1):0]; 

 //ZONE 3 CARS
zone3CarLeftTicker <= zone3CarLeftTicker + ONE[(CAR_SPEED_MAX_BIT-1):0] ;
zone3CarCentreTicker <= zone3CarCentreTicker +ONE[(CAR_SPEED_MAX_BIT-1):0];  
zone3CarRightTicker <= zone3CarRightTicker  +ONE[(CAR_SPEED_MAX_BIT-1):0]; 

 //ZONE 4 CARS
zone4CarLeftTicker <= zone4CarLeftTicker + ONE[(CAR_SPEED_MAX_BIT-1):0] ;
zone4CarCentreTicker <= zone4CarCentreTicker +ONE[(CAR_SPEED_MAX_BIT-1):0];  
zone4CarRightTicker <= zone4CarRightTicker  +ONE[(CAR_SPEED_MAX_BIT-1):0]; 
 //---------------------------------------------------------------------------
 
 
 //ACTUAL CAR MOVEVEMENT
 //-----------------------------------------------------------------------------

 
 
 
 
 //MOVING ALL ZONE 1 CARS--------------------------------------------------------------------------------------
 
 //Move Zone 1 CARS LEFT--------------------------------------------------------------------------------------------
 if(((zone1CarLeftTicker==zone1CarLeftSpeed) && (carLeftZone1X>ZONE1_STOP_POSITION_X)) || ((zone1CarLeftTicker==zone1CarLeftSpeed) && (zone1_car_left_moove_boolean==1'd1) && (carLeftZone1X<=ZONE1_STOP_POSITION_X)) || ((zone1CarLeftTicker==zone1CarLeftSpeed) && (zone1_car_left_moove_boolean==1'd0) && (carLeftZone1X<ZONE1_STOP_POSITION_X))  ) begin

 //Car movement happens here
if(carLeftZone1X>carLeftZone1TurningPointX) begin
 carLeftZone1X <= carLeftZone1X - ONE[(XAXISMAXBITS-1):0]; //Only moves backwards accross the x axis....y axix reain the same
end else if((carLeftZone1X<=carLeftZone1TurningPointX) && (carLeftZone1Y<carLeftZone1TurningHop3Y))begin  //if x
 //Where curve happens
 if(carLeftZone1Y==carLeftZone1TurningPointY) begin
  carLeftZone1X <= carLeftZone1TurningHop1X;
  carLeftZone1Y <= carLeftZone1TurningHop1Y;
 end else if(carLeftZone1Y == carLeftZone1TurningHop1Y) begin
   carLeftZone1X <= carLeftZone1TurningHop2X;
   carLeftZone1Y <= carLeftZone1TurningHop2Y;
 end else if(carLeftZone1Y == carLeftZone1TurningHop2Y) begin
   carLeftZone1X <= carLeftZone1TurningHop3X;
   carLeftZone1Y <= carLeftZone1TurningHop3Y;
 end 
end else if(carLeftZone1Y>=carLeftZone1TurningHop3Y && carLeftZone1Y<(HEIGHT-1)) begin //else if x+1
 carLeftZone1Y <= carLeftZone1Y+ONE[(YAXISMAXBITS-1):0];
end else if(carLeftZone1Y == (HEIGHT-1)) begin //else if x+2
//return back to the begining
  carLeftZone1X <= ZONE1XSTART[(XAXISMAXBITS-1):0];
  carLeftZone1Y <= CARLEFTZONE1_Y_VAR[(YAXISMAXBITS-1):0];
end

/*
curve
85. (122, 153)
86. (113, 162)
87. (104, 189)
88. (104, 190)- >Stable point
*/
 zone1CarLeftTicker <= ZERO[(CAR_SPEED_MAX_BIT-1):0]; //Return Ticker Back to Zero
end //End of Car Left Zone 1  Movement

//------------------------------------------------------------------------------------------------------------------ 

//MOVE ZONE 1 CAR CENTRE
//------------------------------------------------------------------------------------------------------------------
 if(((zone1CarCentreTicker==zone1CarCentreSpeed) && (carCentreZone1X>ZONE1_STOP_POSITION_X)) || ((zone1CarCentreTicker==zone1CarCentreSpeed) && (zone1_car_centre_moove_boolean==1'd1) && (carCentreZone1X<=ZONE1_STOP_POSITION_X)) || ((zone1CarCentreTicker==zone1CarCentreSpeed) && (zone1_car_centre_moove_boolean==1'd0) && (carCentreZone1X<ZONE1_STOP_POSITION_X))) begin
 if(carCentreZone1X>0)begin
carCentreZone1X = carCentreZone1X - ONE[(XAXISMAXBITS-1):0];
end else begin
 carCentreZone1X <= ZONE1XSTART[(XAXISMAXBITS-1):0];
  carCentreZone1Y <= CARCENTREZONE1_Y_VAR[(YAXISMAXBITS-1):0];
end
 zone1CarCentreTicker <= ZERO[(CAR_SPEED_MAX_BIT-1):0]; //Return Ticker Back to Zero
end //End of if  zone1 car centre ticker
//------------------------------------------------------------------------------------------------------------------
 
 
 
 //MOVE ZONE 1 CAR RIGHT
 //----------------------------------------------------------------------------------------------------------------
  if(((zone1CarRightTicker==zone1CarRightSpeed) && (carRightZone1X>ZONE1_STOP_POSITION_X)) || ((zone1CarRightTicker==zone1CarRightSpeed) && (zone1_car_right_moove_boolean==1'd1) && (carRightZone1X<=ZONE1_STOP_POSITION_X))|| ((zone1CarRightTicker==zone1CarRightSpeed) && (zone1_car_right_moove_boolean==1'd0) && (carRightZone1X<ZONE1_STOP_POSITION_X))) begin
 if(carRightZone1X>=(carRightZone1TurningPointX+1)  && carRightZone1Y==carRightZone1TurningPointY)begin
carRightZone1X = carRightZone1X - ONE[(XAXISMAXBITS-1):0];
end else if(carRightZone1X==carRightZone1TurningPointX && carRightZone1Y>0) begin
carRightZone1Y = carRightZone1Y - ONE[(YAXISMAXBITS-1):0];
end else begin
  carRightZone1X <= ZONE1XSTART[(XAXISMAXBITS-1):0];
  carRightZone1Y <= ZONE1YSTART[(YAXISMAXBITS-1):0];
end
 zone1CarRightTicker <= ZERO[(CAR_SPEED_MAX_BIT-1):0]; //Return Ticker Back to Zero
 end
 //----------------------------------------------------------------------------------------------------------------
 //END OF MOVING ALL CARS IN ZONE 1----------------------------------------------------------------------------------
 

 //MOVING ALL ZONE 2 CARS 
 //------------------------------------------------------------------------------------------------------------------
 //MOVE ZONE 2 CARS LEFT
//--------------------------------------------------------------------------------------------------------------------
 if(((zone2CarLeftTicker==zone2CarLeftSpeed) && (carLeftZone2Y<ZONE2_STOP_POSITION_Y)) || ((zone2CarLeftTicker==zone2CarLeftSpeed) && (zone2_car_left_moove_boolean==1'd1) && (carLeftZone2Y>=ZONE2_STOP_POSITION_Y)) || ((zone2CarLeftTicker==zone2CarLeftSpeed) && (zone2_car_left_moove_boolean==1'd0) && (carLeftZone2Y>ZONE2_STOP_POSITION_Y))) begin
 
 //Car movement happens here
if(carLeftZone2Y<carLeftZone2TurningPointY) begin
 carLeftZone2Y <= carLeftZone2Y + ONE[(YAXISMAXBITS-1):0]; 
end else if((carLeftZone2Y>=carLeftZone2TurningPointY) && (carLeftZone2X<carLeftZone2TurningHop3X))begin  //if x
 //Where curve happens
 if(carLeftZone2Y==carLeftZone2TurningPointY) begin
  carLeftZone2X <= carLeftZone2TurningHop1X;
  carLeftZone2Y <= carLeftZone2TurningHop1Y;
 end else if(carLeftZone2Y == carLeftZone2TurningHop1Y) begin
   carLeftZone2X <= carLeftZone2TurningHop2X;
   carLeftZone2Y <= carLeftZone2TurningHop2Y;
 end else if(carLeftZone2Y == carLeftZone2TurningHop2Y) begin
   carLeftZone2X <= carLeftZone2TurningHop3X;
   carLeftZone2Y <= carLeftZone2TurningHop3Y;
 end 
end else if(carLeftZone2Y>=carLeftZone2TurningHop3Y && carLeftZone2X<(WIDTH-1)) begin //else if x+1
 carLeftZone2X <= carLeftZone2X+ONE[(XAXISMAXBITS-1):0];
end else if(carLeftZone2X == (WIDTH-1)) begin //else if x+2
//return back to the begining
 carLeftZone2X = CARLEFTZONE2_X_VAR[(XAXISMAXBITS-1):0];
carLeftZone2Y = ZONE2YSTART[(YAXISMAXBITS-1):0];
end

 zone2CarLeftTicker <= ZERO[(CAR_SPEED_MAX_BIT-1):0]; //Return Ticker Back to Zero
end //End of Car Left Zone 2  Movement

//------------------------------------------------------------------------------------------------------------------ 
 
 //MOVE ZONE 2 CAR CENTRE
//------------------------------------------------------------------------------------------------------------------
 if(((zone2CarCentreTicker==zone2CarCentreSpeed) && (carCentreZone2Y<ZONE2_STOP_POSITION_Y)) || ((zone2CarCentreTicker==zone2CarCentreSpeed) && (zone2_car_centre_moove_boolean==1'd1) && (carCentreZone2Y>=ZONE2_STOP_POSITION_Y)) || ((zone2CarCentreTicker==zone2CarCentreSpeed) && (zone2_car_centre_moove_boolean==1'd0) && (carCentreZone2Y>ZONE2_STOP_POSITION_Y))) begin
 if(carCentreZone2Y< (HEIGHT-1))begin
carCentreZone2Y = carCentreZone2Y + ONE[(YAXISMAXBITS-1):0];
end else begin
carCentreZone2X = CARCENTREZONE2_X_VAR[(XAXISMAXBITS-1):0];
carCentreZone2Y = ZONE2YSTART[(YAXISMAXBITS-1):0];
end
 zone2CarCentreTicker <= ZERO[(CAR_SPEED_MAX_BIT-1):0]; //Return Ticker Back to Zero
end //End of if  zone 2 car centre ticker
//------------------------------------------------------------------------------------------------------------------
 
 //MOVE ZONE 2 CAR-RIGHT
 //----------------------------------------------------------------------------------------------------------------
  if(((zone2CarRightTicker==zone2CarCentreSpeed) && (carRightZone2Y<ZONE2_STOP_POSITION_Y)) || ((zone2CarRightTicker==zone2CarRightSpeed) && (zone2_car_right_moove_boolean==1'd1) && (carRightZone2Y>=ZONE2_STOP_POSITION_Y)) || ((zone2CarRightTicker==zone2CarRightSpeed) && (zone2_car_right_moove_boolean==1'd0) && (carRightZone2Y>ZONE2_STOP_POSITION_Y))) begin
 if(carRightZone2Y<=(carRightZone2TurningPointY-1)  && carRightZone2X==carRightZone2TurningPointX)begin
carRightZone2Y = carRightZone2Y + ONE[(YAXISMAXBITS-1):0];
end else if(carRightZone2Y==carRightZone2TurningPointY && carRightZone2X>0) begin
carRightZone2X = carRightZone2X - ONE[(XAXISMAXBITS-1):0];
end else begin
  carRightZone2X <= ZONE2XSTART[(XAXISMAXBITS-1):0];
  carRightZone2Y <= ZONE2YSTART[(YAXISMAXBITS-1):0];
end
 zone2CarRightTicker <= ZERO[(CAR_SPEED_MAX_BIT-1):0]; //Return Ticker Back to Zero
 end
 //------------------------------------------------------------------------------------------------------------------
 //-----------------------------------------------------------------------------------------------------------------
 //END OF MOVING ALL CARS IN ZONE 2
 
 
 
 
 
 
 //MOVE CARS ALL IN ZONE 3
 //-------------------------------------------------------------------------------------------------------------------
 
 //MOVE ZONE 3 CARS LEFT
//--------------------------------------------------------------------------------------------------------------------
 if(((zone3CarLeftTicker==zone3CarLeftSpeed) && (carLeftZone3X<ZONE3_STOP_POSITION_X)) || ((zone3CarLeftTicker==zone3CarLeftSpeed) && (zone3_car_left_moove_boolean==1'd1) && (carLeftZone3X>=ZONE3_STOP_POSITION_X)) || ((zone3CarLeftTicker==zone3CarLeftSpeed) && (zone3_car_left_moove_boolean==1'd0) && (carLeftZone3X>ZONE3_STOP_POSITION_X))) begin
 
 //Car movement happens here
if(carLeftZone3X<carLeftZone3TurningPointX) begin
 carLeftZone3X <= carLeftZone3X + ONE[(XAXISMAXBITS-1):0]; 
end else if((carLeftZone3X>=carLeftZone3TurningPointX) && (carLeftZone3Y>carLeftZone3TurningHop3Y))begin  //if x
 //Where curve happens
 if(carLeftZone3Y==carLeftZone3TurningPointY) begin
  carLeftZone3X <= carLeftZone3TurningHop1X;
  carLeftZone3Y <= carLeftZone3TurningHop1Y;
 end else if(carLeftZone3Y == carLeftZone3TurningHop1Y) begin
   carLeftZone3X <= carLeftZone3TurningHop2X;
   carLeftZone3Y <= carLeftZone3TurningHop2Y;
 end else if(carLeftZone3Y == carLeftZone3TurningHop2Y) begin
   carLeftZone3X <= carLeftZone3TurningHop3X;
   carLeftZone3Y <= carLeftZone3TurningHop3Y;
 end 
end else if(carLeftZone3Y<=carLeftZone3TurningHop3Y && carLeftZone3Y>0) begin //else if x+1
 carLeftZone3Y <= carLeftZone3Y-ONE[(YAXISMAXBITS-1):0];
end else if(carLeftZone3Y == 0) begin //else if x+2
//return back to the begining
 carLeftZone3X = ZONE3XSTART[(XAXISMAXBITS-1):0]; 
carLeftZone3Y = ZONE3YSTART[(YAXISMAXBITS-1):0];
end
 zone3CarLeftTicker <= ZERO[(CAR_SPEED_MAX_BIT-1):0]; //Return Ticker Back to Zero
end //End of Car Left Zone 3  Movement
//--------------------------------------------------------------------------------------------------------------------- 
 
 
 //MOVE ZONE 3 CAR CENTRE
//------------------------------------------------------------------------------------------------------------------
if(((zone3CarCentreTicker==zone3CarCentreSpeed) && (carCentreZone3X<ZONE3_STOP_POSITION_X)) || ((zone3CarCentreTicker==zone3CarCentreSpeed) && (zone3_car_centre_moove_boolean==1'd1) && (carCentreZone3X>=ZONE3_STOP_POSITION_X)) || ((zone3CarCentreTicker==zone3CarCentreSpeed) && (zone3_car_centre_moove_boolean==1'd0) && (carCentreZone3X>ZONE3_STOP_POSITION_X))) begin
if(carCentreZone3X<(WIDTH-1))begin
carCentreZone3X = carCentreZone3X + ONE[(XAXISMAXBITS-1):0];
end else begin
 carCentreZone3X = ZONE3XSTART[(XAXISMAXBITS-1):0]; 
carCentreZone3Y = CARCENTREZONE3_Y_VAR[(YAXISMAXBITS-1):0];
end
 zone3CarCentreTicker <= ZERO[(CAR_SPEED_MAX_BIT-1):0]; //Return Ticker Back to Zero
end //End of if  zone1 car centre ticker
//------------------------------------------------------------------------------------------------------------------ 
 //MOVE ZONE 3 CAR-RIGHT
 //----------------------------------------------------------------------------------------------------------------
 if(((zone3CarRightTicker==zone3CarRightSpeed) && (carRightZone3X<ZONE3_STOP_POSITION_X)) || ((zone3CarRightTicker==zone3CarRightSpeed) && (zone3_car_right_moove_boolean==1'd1) && (carRightZone3X>=ZONE3_STOP_POSITION_X)) || ((zone3CarRightTicker==zone3CarRightSpeed) && (zone3_car_right_moove_boolean==1'd0) && (carRightZone3X>ZONE3_STOP_POSITION_X))) begin
 if(carRightZone3X<=(carRightZone3TurningPointX-1)  && carRightZone3Y==carRightZone3TurningPointY)begin
carRightZone3X = carRightZone3X + ONE[(XAXISMAXBITS-1):0];
end else if(carRightZone3X==carRightZone3TurningPointX && carRightZone3Y<(HEIGHT-1)) begin
carRightZone3Y = carRightZone3Y + ONE[(YAXISMAXBITS-1):0];
end else begin
 carRightZone3X = ZONE3XSTART[(XAXISMAXBITS-1):0];
carRightZone3Y = CARRIGHTZONE3_Y_VAR[(YAXISMAXBITS-1):0];
end
 zone3CarRightTicker <= ZERO[(CAR_SPEED_MAX_BIT-1):0]; //Return Ticker Back to Zero
 end
 //------------------------------------------------------------------------------------------------------------------ 
 //-------------------------------------------------------------------------------------------------------------------
 //END OF MOVE ALL CARS IN ZONE 3



 
 
 
 //MOVE ALL ZONE 4 CARS
 //------------------------------------------------------------------------------------------------------------------
 //MOVE ZONE 4 CARS LEFT
//--------------------------------------------------------------------------------------------------------------------
if(((zone4CarLeftTicker==zone4CarLeftSpeed) && (carLeftZone4Y>ZONE4_STOP_POSITION_Y)) || ((zone4CarLeftTicker==zone4CarLeftSpeed) && (zone4_car_left_moove_boolean==1'd1) && (carLeftZone4Y<=ZONE4_STOP_POSITION_Y)) || ((zone4CarLeftTicker==zone4CarLeftSpeed) && (zone4_car_left_moove_boolean==1'd0) && (carLeftZone4Y<ZONE4_STOP_POSITION_Y))) begin
//Car movement happens here
if(carLeftZone4Y>carLeftZone4TurningPointY) begin
 carLeftZone4Y <= carLeftZone4Y - ONE[(YAXISMAXBITS-1):0]; 
end else if((carLeftZone4Y<=carLeftZone4TurningPointY) && (carLeftZone4X>carLeftZone4TurningHop3X))begin  //if x
 //Where curve happens
 if(carLeftZone4Y==carLeftZone4TurningPointY) begin
  carLeftZone4X <= carLeftZone4TurningHop1X;
  carLeftZone4Y <= carLeftZone4TurningHop1Y;
 end else if(carLeftZone4Y == carLeftZone4TurningHop1Y) begin
   carLeftZone4X <= carLeftZone4TurningHop2X;
   carLeftZone4Y <= carLeftZone4TurningHop2Y;
 end else if(carLeftZone4Y == carLeftZone4TurningHop2Y) begin
   carLeftZone4X <= carLeftZone4TurningHop3X;
   carLeftZone4Y <= carLeftZone4TurningHop3Y;
 end 
end else if(carLeftZone4Y<=carLeftZone4TurningHop3Y && carLeftZone4X>0) begin //else if x+1
 carLeftZone4X <= carLeftZone4X-ONE[(XAXISMAXBITS-1):0];
end else if(carLeftZone4X == 0) begin //else if x+2
//return back to the begining
carLeftZone4X = ZONE4XSTART[(XAXISMAXBITS-1):0];
carLeftZone4Y =  ZONE4YSTART[(YAXISMAXBITS-1):0];
end
 zone4CarLeftTicker <= ZERO[(CAR_SPEED_MAX_BIT-1):0]; //Return Ticker Back to Zero
end //End of Car Left Zone 3  Movement

//--------------------------------------------------------------------------------------------------------------------- 
 
 
 
 
  //MOVE ZONE 4 CAR CENTRE
//------------------------------------------------------------------------------------------------------------------
if(((zone4CarCentreTicker==zone4CarCentreSpeed) && (carCentreZone4Y>ZONE4_STOP_POSITION_Y)) || ((zone4CarCentreTicker==zone4CarCentreSpeed) && (zone4_car_centre_moove_boolean==1'd1) && (carCentreZone4Y<=ZONE4_STOP_POSITION_Y))|| ((zone4CarCentreTicker==zone4CarCentreSpeed) && (zone4_car_centre_moove_boolean==1'd0) && (carCentreZone4Y<ZONE4_STOP_POSITION_Y))) begin
if(carCentreZone4Y>0)begin
carCentreZone4Y = carCentreZone4Y - ONE[(YAXISMAXBITS-1):0];
end else begin
carCentreZone4X = CARCENTREZONE4_X_VAR[(XAXISMAXBITS-1):0]; 
carCentreZone4Y =ZONE4YSTART [(YAXISMAXBITS-1):0];
end
 zone4CarCentreTicker <= ZERO[(CAR_SPEED_MAX_BIT-1):0]; //Return Ticker Back to Zero
end //End of if  zone 2 car centre ticker
//------------------------------------------------------------------------------------------------------------------

 //MOVE ZONE 4 CAR-RIGHT
 //----------------------------------------------------------------------------------------------------------------
 if(((zone4CarRightTicker==zone4CarRightSpeed) && (carRightZone4Y>ZONE4_STOP_POSITION_Y)) || ((zone4CarRightTicker==zone4CarRightSpeed) && (zone4_car_right_moove_boolean==1'd1) && (carRightZone4Y<=ZONE4_STOP_POSITION_Y)) || ((zone4CarRightTicker==zone4CarRightSpeed) && (zone4_car_right_moove_boolean==1'd0) && (carRightZone4Y<ZONE4_STOP_POSITION_Y))) begin
 if(carRightZone4Y>=(carRightZone4TurningPointY+1)  && carRightZone4X==carRightZone4TurningPointX)begin
carRightZone4Y = carRightZone4Y - ONE[(YAXISMAXBITS-1):0];
end else if(carRightZone4Y==carRightZone4TurningPointY && carRightZone4X<(WIDTH-1)) begin
carRightZone4X = carRightZone4X + ONE[(XAXISMAXBITS-1):0];
end else begin
carRightZone4X = CARRIGHTZONE4_X_VAR[(XAXISMAXBITS-1):0];
carRightZone4Y =ZONE4YSTART[(YAXISMAXBITS-1):0];
end
 zone4CarRightTicker <= ZERO[(CAR_SPEED_MAX_BIT-1):0]; //Return Ticker Back to Zero
 end
 //------------------------------------------------------------------------------------------------------------------
 //-------------------------------------------------------------------------------------------------------------------
 //END OF MOVE ALL ZONE 4 CARS
 
 
end //End of if movement clock 
 end  //end of always block for car movement


 
 

 //TRAFFIC LIGHT CONTROLLER ALWAYS BLOCK
  //Using Mores State Machine Model
always @ (posedge clock) begin

case (currentState)

A: begin
if(stateDurationCounter<warningTime) begin
//ZONE 1
ZONE_1_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_1_TL_CENTRE_COLOUR <= RED_COLOUR; 
ZONE_1_TL_RIGHT_COLOUR <= RED_COLOUR;
ZONE_1_TL_PEDESTRIAN_COLOUR <= YELLOW_COLOUR;
//ZONE 2
ZONE_2_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_2_TL_CENTRE_COLOUR <= RED_COLOUR; 
ZONE_2_TL_RIGHT_COLOUR <= YELLOW_COLOUR;
ZONE_2_TL_PEDESTRIAN_COLOUR <= RED_COLOUR;
//ZONE 3
ZONE_3_TL_LEFT_COLOUR <= YELLOW_COLOUR;
ZONE_3_TL_CENTRE_COLOUR <= RED_COLOUR; 
ZONE_3_TL_RIGHT_COLOUR <= YELLOW_COLOUR;
ZONE_3_TL_PEDESTRIAN_COLOUR <= RED_COLOUR;
//ZONE 4
ZONE_4_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_4_TL_CENTRE_COLOUR <= YELLOW_COLOUR; 
ZONE_4_TL_RIGHT_COLOUR <= RED_COLOUR;
ZONE_4_TL_PEDESTRIAN_COLOUR <= RED_COLOUR;

end else if((stateDurationCounter>=warningTime) && (stateDurationCounter<(trafficStateDuration-warningTime))) begin 
//ZONE 1
ZONE_1_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_1_TL_CENTRE_COLOUR <= RED_COLOUR; 
ZONE_1_TL_RIGHT_COLOUR <= RED_COLOUR;
ZONE_1_TL_PEDESTRIAN_COLOUR <= GREEN_COLOUR;
//ZONE 2
ZONE_2_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_2_TL_CENTRE_COLOUR <= RED_COLOUR; 
ZONE_2_TL_RIGHT_COLOUR <= GREEN_COLOUR;
ZONE_2_TL_PEDESTRIAN_COLOUR <= RED_COLOUR;
//ZONE 3
ZONE_3_TL_LEFT_COLOUR <= GREEN_COLOUR;
ZONE_3_TL_CENTRE_COLOUR <= RED_COLOUR; 
ZONE_3_TL_RIGHT_COLOUR <= GREEN_COLOUR;
ZONE_3_TL_PEDESTRIAN_COLOUR <= RED_COLOUR;
//ZONE 4
ZONE_4_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_4_TL_CENTRE_COLOUR <= GREEN_COLOUR; 
ZONE_4_TL_RIGHT_COLOUR <= RED_COLOUR;
ZONE_4_TL_PEDESTRIAN_COLOUR <= RED_COLOUR;

//SET CARS MOVE BOOLEAN
//ZONE 1 - MOVEMENT BOOLEAN
zone1_car_left_moove_boolean = 1'd0;
zone1_car_centre_moove_boolean = 1'd0;
zone1_car_right_moove_boolean = 1'd0;
zone1_pedestrian_moove_boolean = 1'd1;
//ZONE 2- MOVEMENT BOOLEAN
zone2_car_left_moove_boolean = 1'd0;
zone2_car_centre_moove_boolean = 1'd0;
zone2_car_right_moove_boolean = 1'd1;
zone2_pedestrian_moove_boolean = 1'd0;
//ZONE 3- MOVEMENT BOOLEAN
zone3_car_left_moove_boolean = 1'd1;
zone3_car_centre_moove_boolean = 1'd0;
zone3_car_right_moove_boolean = 1'd1;
zone3_pedestrian_moove_boolean = 1'd0;
//ZONE 4- MOVEMENT BOOLEAN
zone4_car_left_moove_boolean = 1'd0;
zone4_car_centre_moove_boolean = 1'd1;
zone4_car_right_moove_boolean = 1'd0;
zone4_pedestrian_moove_boolean = 1'd0;

end else begin
//ZONE 1
ZONE_1_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_1_TL_CENTRE_COLOUR <= RED_COLOUR; 
ZONE_1_TL_RIGHT_COLOUR <= RED_COLOUR;
ZONE_1_TL_PEDESTRIAN_COLOUR <= YELLOW_COLOUR;
//ZONE 2
ZONE_2_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_2_TL_CENTRE_COLOUR <= RED_COLOUR; 
ZONE_2_TL_RIGHT_COLOUR <= YELLOW_COLOUR;
ZONE_2_TL_PEDESTRIAN_COLOUR <= RED_COLOUR;
//ZONE 3
ZONE_3_TL_LEFT_COLOUR <= YELLOW_COLOUR;
ZONE_3_TL_CENTRE_COLOUR <= RED_COLOUR; 
ZONE_3_TL_RIGHT_COLOUR <= YELLOW_COLOUR;
ZONE_3_TL_PEDESTRIAN_COLOUR <= RED_COLOUR;
//ZONE 4
ZONE_4_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_4_TL_CENTRE_COLOUR <= YELLOW_COLOUR; 
ZONE_4_TL_RIGHT_COLOUR <= RED_COLOUR;
ZONE_4_TL_PEDESTRIAN_COLOUR <= RED_COLOUR;
end
stateDurationCounter <= stateDurationCounter + 1'd1;

if(stateDurationCounter>=trafficStateDuration)begin
stateDurationCounter <= LONGZERO[(TRAFFIC_STATE_DURATION_REG_LENGTH-1):0];
currentState <=B;
end else begin
currentState <=A;
end
end //end of case

B: begin
if(stateDurationCounter<warningTime) begin

//ZONE 1
ZONE_1_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_1_TL_CENTRE_COLOUR <= YELLOW_COLOUR; 
ZONE_1_TL_RIGHT_COLOUR <= RED_COLOUR;
ZONE_1_TL_PEDESTRIAN_COLOUR <= RED_COLOUR;
//ZONE 2
ZONE_2_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_2_TL_CENTRE_COLOUR <= RED_COLOUR; 
ZONE_2_TL_RIGHT_COLOUR <= RED_COLOUR;
ZONE_2_TL_PEDESTRIAN_COLOUR <= YELLOW_COLOUR;
//ZONE 3
ZONE_3_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_3_TL_CENTRE_COLOUR <= YELLOW_COLOUR; 
ZONE_3_TL_RIGHT_COLOUR <= YELLOW_COLOUR;
ZONE_3_TL_PEDESTRIAN_COLOUR <= RED_COLOUR;
//ZONE 4
ZONE_4_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_4_TL_CENTRE_COLOUR <= RED_COLOUR; 
ZONE_4_TL_RIGHT_COLOUR <= YELLOW_COLOUR;
ZONE_4_TL_PEDESTRIAN_COLOUR <= RED_COLOUR;
end else if((stateDurationCounter>=warningTime) && (stateDurationCounter<(trafficStateDuration-warningTime))) begin 

//ZONE 1
ZONE_1_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_1_TL_CENTRE_COLOUR <= GREEN_COLOUR; 
ZONE_1_TL_RIGHT_COLOUR <= RED_COLOUR;
ZONE_1_TL_PEDESTRIAN_COLOUR <= RED_COLOUR;
//ZONE 2
ZONE_2_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_2_TL_CENTRE_COLOUR <= RED_COLOUR; 
ZONE_2_TL_RIGHT_COLOUR <= RED_COLOUR;
ZONE_2_TL_PEDESTRIAN_COLOUR <= GREEN_COLOUR;
//ZONE 3
ZONE_3_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_3_TL_CENTRE_COLOUR <= GREEN_COLOUR; 
ZONE_3_TL_RIGHT_COLOUR <= GREEN_COLOUR;
ZONE_3_TL_PEDESTRIAN_COLOUR <= RED_COLOUR;
//ZONE 4
ZONE_4_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_4_TL_CENTRE_COLOUR <= RED_COLOUR; 
ZONE_4_TL_RIGHT_COLOUR <= GREEN_COLOUR;
ZONE_4_TL_PEDESTRIAN_COLOUR <= RED_COLOUR;

//SET CARS MOVE BOOLEAN
//ZONE 1 - MOVEMENT BOOLEAN
zone1_car_left_moove_boolean = 1'd0;
zone1_car_centre_moove_boolean = 1'd1;
zone1_car_right_moove_boolean = 1'd0;
zone1_pedestrian_moove_boolean = 1'd0;
//ZONE 2- MOVEMENT BOOLEAN
zone2_car_left_moove_boolean = 1'd0;
zone2_car_centre_moove_boolean = 1'd0;
zone2_car_right_moove_boolean = 1'd0;
zone2_pedestrian_moove_boolean = 1'd1;
//ZONE 3- MOVEMENT BOOLEAN
zone3_car_left_moove_boolean = 1'd0;
zone3_car_centre_moove_boolean = 1'd1;
zone3_car_right_moove_boolean = 1'd1;
zone3_pedestrian_moove_boolean = 1'd0;
//ZONE 4- MOVEMENT BOOLEAN
zone4_car_left_moove_boolean = 1'd0;
zone4_car_centre_moove_boolean = 1'd0;
zone4_car_right_moove_boolean = 1'd1;
zone4_pedestrian_moove_boolean = 1'd0;
end else begin
//ZONE 1
ZONE_1_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_1_TL_CENTRE_COLOUR <= YELLOW_COLOUR; 
ZONE_1_TL_RIGHT_COLOUR <= RED_COLOUR;
ZONE_1_TL_PEDESTRIAN_COLOUR <= RED_COLOUR;
//ZONE 2
ZONE_2_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_2_TL_CENTRE_COLOUR <= RED_COLOUR; 
ZONE_2_TL_RIGHT_COLOUR <= RED_COLOUR;
ZONE_2_TL_PEDESTRIAN_COLOUR <= YELLOW_COLOUR;
//ZONE 3
ZONE_3_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_3_TL_CENTRE_COLOUR <= YELLOW_COLOUR; 
ZONE_3_TL_RIGHT_COLOUR <= YELLOW_COLOUR;
ZONE_3_TL_PEDESTRIAN_COLOUR <= RED_COLOUR;
//ZONE 4
ZONE_4_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_4_TL_CENTRE_COLOUR <= RED_COLOUR; 
ZONE_4_TL_RIGHT_COLOUR <= YELLOW_COLOUR;
ZONE_4_TL_PEDESTRIAN_COLOUR <= RED_COLOUR;
end

stateDurationCounter <= stateDurationCounter + 1'd1;
if(stateDurationCounter>=trafficStateDuration)begin
stateDurationCounter <= LONGZERO[(TRAFFIC_STATE_DURATION_REG_LENGTH-1):0];
currentState <=C;
end else begin
currentState <=B;
end
end//end of state 
C: begin
if(stateDurationCounter<warningTime) begin
//ZONE 1
ZONE_1_TL_LEFT_COLOUR <= YELLOW_COLOUR;
ZONE_1_TL_CENTRE_COLOUR <= RED_COLOUR; 
ZONE_1_TL_RIGHT_COLOUR <= YELLOW_COLOUR;
ZONE_1_TL_PEDESTRIAN_COLOUR <= RED_COLOUR;
//ZONE 2
ZONE_2_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_2_TL_CENTRE_COLOUR <= YELLOW_COLOUR; 
ZONE_2_TL_RIGHT_COLOUR <= RED_COLOUR;
ZONE_2_TL_PEDESTRIAN_COLOUR <= RED_COLOUR;
//ZONE 3
ZONE_3_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_3_TL_CENTRE_COLOUR <= RED_COLOUR; 
ZONE_3_TL_RIGHT_COLOUR <= RED_COLOUR;
ZONE_3_TL_PEDESTRIAN_COLOUR <= YELLOW_COLOUR;
//ZONE 4
ZONE_4_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_4_TL_CENTRE_COLOUR <= RED_COLOUR; 
ZONE_4_TL_RIGHT_COLOUR <= YELLOW_COLOUR;
ZONE_4_TL_PEDESTRIAN_COLOUR <= RED_COLOUR;
end else if((stateDurationCounter>=warningTime) && (stateDurationCounter<(trafficStateDuration-warningTime))) begin 
//ZONE 1
ZONE_1_TL_LEFT_COLOUR <= GREEN_COLOUR;
ZONE_1_TL_CENTRE_COLOUR <= RED_COLOUR; 
ZONE_1_TL_RIGHT_COLOUR <= GREEN_COLOUR;
ZONE_1_TL_PEDESTRIAN_COLOUR <= RED_COLOUR;
//ZONE 2
ZONE_2_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_2_TL_CENTRE_COLOUR <= GREEN_COLOUR; 
ZONE_2_TL_RIGHT_COLOUR <= RED_COLOUR;
ZONE_2_TL_PEDESTRIAN_COLOUR <= RED_COLOUR;
//ZONE 3
ZONE_3_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_3_TL_CENTRE_COLOUR <= RED_COLOUR; 
ZONE_3_TL_RIGHT_COLOUR <= RED_COLOUR;
ZONE_3_TL_PEDESTRIAN_COLOUR <= GREEN_COLOUR;
//ZONE 4
ZONE_4_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_4_TL_CENTRE_COLOUR <= RED_COLOUR; 
ZONE_4_TL_RIGHT_COLOUR <= GREEN_COLOUR;
ZONE_4_TL_PEDESTRIAN_COLOUR <= RED_COLOUR;


//SET CARS MOVE BOOLEAN
//ZONE 1 - MOVEMENT BOOLEAN
zone1_car_left_moove_boolean = 1'd1;
zone1_car_centre_moove_boolean = 1'd0;
zone1_car_right_moove_boolean = 1'd1;
zone1_pedestrian_moove_boolean = 1'd0;
//ZONE 2- MOVEMENT BOOLEAN
zone2_car_left_moove_boolean = 1'd0;
zone2_car_centre_moove_boolean = 1'd1;
zone2_car_right_moove_boolean = 1'd0;
zone2_pedestrian_moove_boolean = 1'd0;
//ZONE 3- MOVEMENT BOOLEAN
zone3_car_left_moove_boolean = 1'd0;
zone3_car_centre_moove_boolean = 1'd0;
zone3_car_right_moove_boolean = 1'd0;
zone3_pedestrian_moove_boolean = 1'd1;
//ZONE 4- MOVEMENT BOOLEAN
zone4_car_left_moove_boolean = 1'd0;
zone4_car_centre_moove_boolean = 1'd0;
zone4_car_right_moove_boolean = 1'd1;
zone4_pedestrian_moove_boolean = 1'd0;

end else begin

//ZONE 1
ZONE_1_TL_LEFT_COLOUR <= YELLOW_COLOUR;
ZONE_1_TL_CENTRE_COLOUR <= RED_COLOUR; 
ZONE_1_TL_RIGHT_COLOUR <= YELLOW_COLOUR;
ZONE_1_TL_PEDESTRIAN_COLOUR <= RED_COLOUR;
//ZONE 2
ZONE_2_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_2_TL_CENTRE_COLOUR <= YELLOW_COLOUR; 
ZONE_2_TL_RIGHT_COLOUR <= RED_COLOUR;
ZONE_2_TL_PEDESTRIAN_COLOUR <= RED_COLOUR;
//ZONE 3
ZONE_3_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_3_TL_CENTRE_COLOUR <= RED_COLOUR; 
ZONE_3_TL_RIGHT_COLOUR <= RED_COLOUR;
ZONE_3_TL_PEDESTRIAN_COLOUR <= YELLOW_COLOUR;
//ZONE 4
ZONE_4_TL_LEFT_COLOUR <= RED_COLOUR;
ZONE_4_TL_CENTRE_COLOUR <= RED_COLOUR; 
ZONE_4_TL_RIGHT_COLOUR <= YELLOW_COLOUR;
ZONE_4_TL_PEDESTRIAN_COLOUR <= RED_COLOUR;
end



stateDurationCounter <= stateDurationCounter + 1'd1;
if(stateDurationCounter>=trafficStateDuration)begin
stateDurationCounter <= LONGZERO[(TRAFFIC_STATE_DURATION_REG_LENGTH-1):0];
currentState <=D;
end else begin
currentState <=C;
end
end

D: begin
if(stateDurationCounter<warningTime) begin
//ZONE 1
ZONE_1_TL_LEFT_COLOUR = RED_COLOUR;
ZONE_1_TL_CENTRE_COLOUR = RED_COLOUR; 
ZONE_1_TL_RIGHT_COLOUR = YELLOW_COLOUR;
ZONE_1_TL_PEDESTRIAN_COLOUR = RED_COLOUR;
//ZONE 2
ZONE_2_TL_LEFT_COLOUR = YELLOW_COLOUR;
ZONE_2_TL_CENTRE_COLOUR = RED_COLOUR; 
ZONE_2_TL_RIGHT_COLOUR = YELLOW_COLOUR;
ZONE_2_TL_PEDESTRIAN_COLOUR = RED_COLOUR;
//ZONE 3
ZONE_3_TL_LEFT_COLOUR = RED_COLOUR;
ZONE_3_TL_CENTRE_COLOUR = YELLOW_COLOUR; 
ZONE_3_TL_RIGHT_COLOUR = RED_COLOUR;
ZONE_3_TL_PEDESTRIAN_COLOUR = RED_COLOUR;
//ZONE 4
ZONE_4_TL_LEFT_COLOUR = RED_COLOUR;
ZONE_4_TL_CENTRE_COLOUR = RED_COLOUR; 
ZONE_4_TL_RIGHT_COLOUR = RED_COLOUR;
ZONE_4_TL_PEDESTRIAN_COLOUR = YELLOW_COLOUR;
end else if((stateDurationCounter>=warningTime) && (stateDurationCounter<(trafficStateDuration-warningTime))) begin 

//ZONE 1
ZONE_1_TL_LEFT_COLOUR = RED_COLOUR;
ZONE_1_TL_CENTRE_COLOUR = RED_COLOUR; 
ZONE_1_TL_RIGHT_COLOUR = GREEN_COLOUR;
ZONE_1_TL_PEDESTRIAN_COLOUR = RED_COLOUR;
//ZONE 2
ZONE_2_TL_LEFT_COLOUR = GREEN_COLOUR;
ZONE_2_TL_CENTRE_COLOUR = RED_COLOUR; 
ZONE_2_TL_RIGHT_COLOUR = GREEN_COLOUR;
ZONE_2_TL_PEDESTRIAN_COLOUR = RED_COLOUR;
//ZONE 3
ZONE_3_TL_LEFT_COLOUR = RED_COLOUR;
ZONE_3_TL_CENTRE_COLOUR = GREEN_COLOUR; 
ZONE_3_TL_RIGHT_COLOUR = RED_COLOUR;
ZONE_3_TL_PEDESTRIAN_COLOUR = RED_COLOUR;
//ZONE 4
ZONE_4_TL_LEFT_COLOUR = RED_COLOUR;
ZONE_4_TL_CENTRE_COLOUR = RED_COLOUR; 
ZONE_4_TL_RIGHT_COLOUR = RED_COLOUR;
ZONE_4_TL_PEDESTRIAN_COLOUR = GREEN_COLOUR;


//SET CARS MOVE BOOLEAN
//ZONE 1 - MOVEMENT BOOLEAN
zone1_car_left_moove_boolean = 1'd0;
zone1_car_centre_moove_boolean = 1'd0;
zone1_car_right_moove_boolean = 1'd1;
zone1_pedestrian_moove_boolean = 1'd0;
//ZONE 2- MOVEMENT BOOLEAN
zone2_car_left_moove_boolean = 1'd1;
zone2_car_centre_moove_boolean = 1'd0;
zone2_car_right_moove_boolean = 1'd1;
zone2_pedestrian_moove_boolean = 1'd0;
//ZONE 3- MOVEMENT BOOLEAN
zone3_car_left_moove_boolean = 1'd0;
zone3_car_centre_moove_boolean = 1'd1;
zone3_car_right_moove_boolean = 1'd0;
zone3_pedestrian_moove_boolean = 1'd0;
//ZONE 4- MOVEMENT BOOLEAN
zone4_car_left_moove_boolean = 1'd0;
zone4_car_centre_moove_boolean = 1'd0;
zone4_car_right_moove_boolean = 1'd0;
zone4_pedestrian_moove_boolean = 1'd1;

end else begin
//ZONE 1
ZONE_1_TL_LEFT_COLOUR = RED_COLOUR;
ZONE_1_TL_CENTRE_COLOUR = RED_COLOUR; 
ZONE_1_TL_RIGHT_COLOUR = YELLOW_COLOUR;
ZONE_1_TL_PEDESTRIAN_COLOUR = RED_COLOUR;
//ZONE 2
ZONE_2_TL_LEFT_COLOUR = YELLOW_COLOUR;
ZONE_2_TL_CENTRE_COLOUR = RED_COLOUR; 
ZONE_2_TL_RIGHT_COLOUR = YELLOW_COLOUR;
ZONE_2_TL_PEDESTRIAN_COLOUR = RED_COLOUR;
//ZONE 3
ZONE_3_TL_LEFT_COLOUR = RED_COLOUR;
ZONE_3_TL_CENTRE_COLOUR = YELLOW_COLOUR; 
ZONE_3_TL_RIGHT_COLOUR = RED_COLOUR;
ZONE_3_TL_PEDESTRIAN_COLOUR = RED_COLOUR;
//ZONE 4
ZONE_4_TL_LEFT_COLOUR = RED_COLOUR;
ZONE_4_TL_CENTRE_COLOUR = RED_COLOUR; 
ZONE_4_TL_RIGHT_COLOUR = RED_COLOUR;
ZONE_4_TL_PEDESTRIAN_COLOUR = YELLOW_COLOUR;


end

stateDurationCounter <= stateDurationCounter + 1'd1;
if(stateDurationCounter>=trafficStateDuration)begin
stateDurationCounter <= LONGZERO[(TRAFFIC_STATE_DURATION_REG_LENGTH-1):0];
currentState <=E;
end else begin
currentState <=D;
end

end //end of state

E: begin
if(stateDurationCounter<warningTime) begin

//ZONE 1
ZONE_1_TL_LEFT_COLOUR = RED_COLOUR;
ZONE_1_TL_CENTRE_COLOUR = RED_COLOUR; 
ZONE_1_TL_RIGHT_COLOUR = YELLOW_COLOUR;
ZONE_1_TL_PEDESTRIAN_COLOUR = RED_COLOUR;
//ZONE 2
ZONE_2_TL_LEFT_COLOUR = RED_COLOUR;
ZONE_2_TL_CENTRE_COLOUR = RED_COLOUR; 
ZONE_2_TL_RIGHT_COLOUR = YELLOW_COLOUR;
ZONE_2_TL_PEDESTRIAN_COLOUR = RED_COLOUR;
//ZONE 3
ZONE_3_TL_LEFT_COLOUR = RED_COLOUR;
ZONE_3_TL_CENTRE_COLOUR = RED_COLOUR; 
ZONE_3_TL_RIGHT_COLOUR = RED_COLOUR;
ZONE_3_TL_PEDESTRIAN_COLOUR = RED_COLOUR;
//ZONE 4
ZONE_4_TL_LEFT_COLOUR = YELLOW_COLOUR;
ZONE_4_TL_CENTRE_COLOUR = YELLOW_COLOUR; 
ZONE_4_TL_RIGHT_COLOUR = RED_COLOUR;
ZONE_4_TL_PEDESTRIAN_COLOUR = RED_COLOUR;


end else if((stateDurationCounter>=warningTime) && (stateDurationCounter<(trafficStateDuration-warningTime))) begin 
//ZONE 1
ZONE_1_TL_LEFT_COLOUR = RED_COLOUR;
ZONE_1_TL_CENTRE_COLOUR = RED_COLOUR; 
ZONE_1_TL_RIGHT_COLOUR = GREEN_COLOUR;
ZONE_1_TL_PEDESTRIAN_COLOUR = RED_COLOUR;
//ZONE 2
ZONE_2_TL_LEFT_COLOUR = RED_COLOUR;
ZONE_2_TL_CENTRE_COLOUR = RED_COLOUR; 
ZONE_2_TL_RIGHT_COLOUR = GREEN_COLOUR;
ZONE_2_TL_PEDESTRIAN_COLOUR = RED_COLOUR;
//ZONE 3
ZONE_3_TL_LEFT_COLOUR = RED_COLOUR;
ZONE_3_TL_CENTRE_COLOUR = RED_COLOUR; 
ZONE_3_TL_RIGHT_COLOUR = RED_COLOUR;
ZONE_3_TL_PEDESTRIAN_COLOUR = RED_COLOUR;
//ZONE 4
ZONE_4_TL_LEFT_COLOUR = GREEN_COLOUR;
ZONE_4_TL_CENTRE_COLOUR = GREEN_COLOUR; 
ZONE_4_TL_RIGHT_COLOUR = RED_COLOUR;
ZONE_4_TL_PEDESTRIAN_COLOUR = RED_COLOUR;




//SET CARS MOVE BOOLEAN
//ZONE 1 - MOVEMENT BOOLEAN
zone1_car_left_moove_boolean = 1'd0;
zone1_car_centre_moove_boolean = 1'd0;
zone1_car_right_moove_boolean = 1'd1;
zone1_pedestrian_moove_boolean = 1'd0;
//ZONE 2- MOVEMENT BOOLEAN
zone2_car_left_moove_boolean = 1'd0;
zone2_car_centre_moove_boolean = 1'd0;
zone2_car_right_moove_boolean = 1'd1;
zone2_pedestrian_moove_boolean = 1'd0;
//ZONE 3- MOVEMENT BOOLEAN
zone3_car_left_moove_boolean = 1'd0;
zone3_car_centre_moove_boolean = 1'd0;
zone3_car_right_moove_boolean = 1'd0;
zone3_pedestrian_moove_boolean = 1'd0;
//ZONE 4- MOVEMENT BOOLEAN
zone4_car_left_moove_boolean = 1'd1;
zone4_car_centre_moove_boolean = 1'd1;
zone4_car_right_moove_boolean = 1'd0;
zone4_pedestrian_moove_boolean = 1'd0;

end else begin

//ZONE 1
ZONE_1_TL_LEFT_COLOUR = RED_COLOUR;
ZONE_1_TL_CENTRE_COLOUR = RED_COLOUR; 
ZONE_1_TL_RIGHT_COLOUR = YELLOW_COLOUR;
ZONE_1_TL_PEDESTRIAN_COLOUR = RED_COLOUR;
//ZONE 2
ZONE_2_TL_LEFT_COLOUR = RED_COLOUR;
ZONE_2_TL_CENTRE_COLOUR = RED_COLOUR; 
ZONE_2_TL_RIGHT_COLOUR = YELLOW_COLOUR;
ZONE_2_TL_PEDESTRIAN_COLOUR = RED_COLOUR;
//ZONE 3
ZONE_3_TL_LEFT_COLOUR = RED_COLOUR;
ZONE_3_TL_CENTRE_COLOUR = RED_COLOUR; 
ZONE_3_TL_RIGHT_COLOUR = RED_COLOUR;
ZONE_3_TL_PEDESTRIAN_COLOUR = RED_COLOUR;
//ZONE 4
ZONE_4_TL_LEFT_COLOUR = YELLOW_COLOUR;
ZONE_4_TL_CENTRE_COLOUR = YELLOW_COLOUR; 
ZONE_4_TL_RIGHT_COLOUR = RED_COLOUR;
ZONE_4_TL_PEDESTRIAN_COLOUR = RED_COLOUR;
end

stateDurationCounter <= stateDurationCounter + 1'd1;
if(stateDurationCounter>=trafficStateDuration)begin
stateDurationCounter <= LONGZERO[(TRAFFIC_STATE_DURATION_REG_LENGTH-1):0];
currentState <=F;
end else begin
currentState <=E;
end

end//end of case

F: begin
if(stateDurationCounter<warningTime) begin
//ZONE 1
ZONE_1_TL_LEFT_COLOUR = RED_COLOUR;
ZONE_1_TL_CENTRE_COLOUR = RED_COLOUR; 
ZONE_1_TL_RIGHT_COLOUR = YELLOW_COLOUR;
ZONE_1_TL_PEDESTRIAN_COLOUR = RED_COLOUR;

//ZONE 2
ZONE_2_TL_LEFT_COLOUR = GREEN_COLOUR;
ZONE_2_TL_CENTRE_COLOUR = RED_COLOUR; 
ZONE_2_TL_RIGHT_COLOUR = YELLOW_COLOUR;
ZONE_2_TL_PEDESTRIAN_COLOUR = RED_COLOUR;

//ZONE 3
ZONE_3_TL_LEFT_COLOUR = RED_COLOUR;
ZONE_3_TL_CENTRE_COLOUR = RED_COLOUR; 
ZONE_3_TL_RIGHT_COLOUR = RED_COLOUR;
ZONE_3_TL_PEDESTRIAN_COLOUR = RED_COLOUR;

//ZONE 4
ZONE_4_TL_LEFT_COLOUR = YELLOW_COLOUR;
ZONE_4_TL_CENTRE_COLOUR = YELLOW_COLOUR; 
ZONE_4_TL_RIGHT_COLOUR = RED_COLOUR;
ZONE_4_TL_PEDESTRIAN_COLOUR = RED_COLOUR;

end else if((stateDurationCounter>=warningTime) && (stateDurationCounter<(trafficStateDuration-warningTime))) begin 

//ZONE 1
ZONE_1_TL_LEFT_COLOUR = RED_COLOUR;
ZONE_1_TL_CENTRE_COLOUR = RED_COLOUR; 
ZONE_1_TL_RIGHT_COLOUR = GREEN_COLOUR;
ZONE_1_TL_PEDESTRIAN_COLOUR = RED_COLOUR;

//ZONE 2
ZONE_2_TL_LEFT_COLOUR = GREEN_COLOUR;
ZONE_2_TL_CENTRE_COLOUR = RED_COLOUR; 
ZONE_2_TL_RIGHT_COLOUR = GREEN_COLOUR;
ZONE_2_TL_PEDESTRIAN_COLOUR = RED_COLOUR;

//ZONE 3
ZONE_3_TL_LEFT_COLOUR = RED_COLOUR;
ZONE_3_TL_CENTRE_COLOUR = RED_COLOUR; 
ZONE_3_TL_RIGHT_COLOUR = RED_COLOUR;
ZONE_3_TL_PEDESTRIAN_COLOUR = RED_COLOUR;

//ZONE 4
ZONE_4_TL_LEFT_COLOUR = GREEN_COLOUR;
ZONE_4_TL_CENTRE_COLOUR = GREEN_COLOUR; 
ZONE_4_TL_RIGHT_COLOUR = RED_COLOUR;
ZONE_4_TL_PEDESTRIAN_COLOUR = RED_COLOUR;


//SET CARS MOVE BOOLEAN
//ZONE 1 - MOVEMENT BOOLEAN
zone1_car_left_moove_boolean = 1'd0;
zone1_car_centre_moove_boolean = 1'd0;
zone1_car_right_moove_boolean = 1'd1;
zone1_pedestrian_moove_boolean = 1'd0;
//ZONE 2- MOVEMENT BOOLEAN
zone2_car_left_moove_boolean = 1'd1;
zone2_car_centre_moove_boolean = 1'd0;
zone2_car_right_moove_boolean = 1'd1;
zone2_pedestrian_moove_boolean = 1'd0;
//ZONE 3- MOVEMENT BOOLEAN
zone3_car_left_moove_boolean = 1'd0;
zone3_car_centre_moove_boolean = 1'd0;
zone3_car_right_moove_boolean = 1'd0;
zone3_pedestrian_moove_boolean = 1'd0;
//ZONE 4- MOVEMENT BOOLEAN
zone4_car_left_moove_boolean = 1'd1;
zone4_car_centre_moove_boolean = 1'd1;
zone4_car_right_moove_boolean = 1'd0;
zone4_pedestrian_moove_boolean = 1'd0;


end else begin
//ZONE 1
ZONE_1_TL_LEFT_COLOUR = RED_COLOUR;
ZONE_1_TL_CENTRE_COLOUR = RED_COLOUR; 
ZONE_1_TL_RIGHT_COLOUR = YELLOW_COLOUR;
ZONE_1_TL_PEDESTRIAN_COLOUR = RED_COLOUR;

//ZONE 2
ZONE_2_TL_LEFT_COLOUR = GREEN_COLOUR;
ZONE_2_TL_CENTRE_COLOUR = RED_COLOUR; 
ZONE_2_TL_RIGHT_COLOUR = YELLOW_COLOUR;
ZONE_2_TL_PEDESTRIAN_COLOUR = RED_COLOUR;

//ZONE 3
ZONE_3_TL_LEFT_COLOUR = RED_COLOUR;
ZONE_3_TL_CENTRE_COLOUR = RED_COLOUR; 
ZONE_3_TL_RIGHT_COLOUR = RED_COLOUR;
ZONE_3_TL_PEDESTRIAN_COLOUR = RED_COLOUR;

//ZONE 4
ZONE_4_TL_LEFT_COLOUR = YELLOW_COLOUR;
ZONE_4_TL_CENTRE_COLOUR = YELLOW_COLOUR; 
ZONE_4_TL_RIGHT_COLOUR = RED_COLOUR;
ZONE_4_TL_PEDESTRIAN_COLOUR = RED_COLOUR;


end
stateDurationCounter <= stateDurationCounter + 1'd1;
if(stateDurationCounter>=trafficStateDuration)begin
stateDurationCounter <= LONGZERO[(TRAFFIC_STATE_DURATION_REG_LENGTH-1):0];
currentState <=A;
end else begin
currentState<=F;
end

end//end of case


default: begin nextState <= 3'bxxx ; end
endcase
end //End of Always Block

 
 
endmodule
