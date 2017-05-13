
# Requre quartus project
package require ::quartus::project

# Set pin locations for LCD
set_location_assignment PIN_AF26 -to LT24_D[0]
set_location_assignment PIN_AF25 -to LT24_D[1]
set_location_assignment PIN_AE24 -to LT24_D[2]
set_location_assignment PIN_AE23 -to LT24_D[3]
set_location_assignment PIN_AJ27 -to LT24_D[4]
set_location_assignment PIN_AK29 -to LT24_D[5]
set_location_assignment PIN_AK28 -to LT24_D[6]
set_location_assignment PIN_AK27 -to LT24_D[7]
set_location_assignment PIN_AJ26 -to LT24_D[8]
set_location_assignment PIN_AK26 -to LT24_D[9]
set_location_assignment PIN_AH25 -to LT24_D[10]
set_location_assignment PIN_AJ25 -to LT24_D[11]
set_location_assignment PIN_AJ24 -to LT24_D[12]
set_location_assignment PIN_AK24 -to LT24_D[13]
set_location_assignment PIN_AG23 -to LT24_D[14]
set_location_assignment PIN_AK23 -to LT24_D[15]
set_location_assignment PIN_AD21 -to LT24_RESETn
set_location_assignment PIN_AH27 -to LT24_RS
set_location_assignment PIN_AH23 -to LT24_CSn
set_location_assignment PIN_AG26 -to LT24_RDn
set_location_assignment PIN_AH24 -to LT24_WRn
set_location_assignment PIN_AC22 -to LT24_LCD_ON

# Set pin location for Clock
set_location_assignment PIN_AA16 -to clock

# Set pin location for globalReset
set_location_assignment PIN_AA14 -to globalReset

# Commit assignments
export_assignments