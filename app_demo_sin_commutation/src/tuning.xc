/*
 * tuning.xc
 *
 *  Created on: Jul 13, 2015
 *      Author: Synapticon GmbH
 */
#include <tuning.h>
#include <stdio.h>
#include <ctype.h>
#include <commutation_client.h>
#include <biss_server.h>
#include <biss_client.h>


void set_commutation_offset_clk(chanend c_commutation, unsigned offset){
    c_commutation <: COMMUTATION_CMD_SET_PARAMS;
    c_commutation <: (60 * 4096) / (POLE_PAIRS * 2 * 360);
    c_commutation <: MAX_NOMINAL_SPEED;
    c_commutation <: offset;
    c_commutation <: COMMUTATION_OFFSET_CCLK;
    c_commutation <: WINDING_TYPE;
}

void set_commutation_offset_cclk(chanend c_commutation, unsigned offset){
    c_commutation <: COMMUTATION_CMD_SET_PARAMS;
    c_commutation <: (60 * 4096) / (POLE_PAIRS * 2 * 360);
    c_commutation <: MAX_NOMINAL_SPEED;
    c_commutation <: COMMUTATION_OFFSET_CLK;
    c_commutation <: offset;
    c_commutation <: WINDING_TYPE;
}


void run_offset_tuning(int input_voltage, chanend c_commutation_p1, client interface i_biss ?i_biss, int sensor_select){

    delay_seconds(1);
    biss_par biss_params;
    //print some motor parameters
    if (WINDING_TYPE == STAR_WINDING)
        printf("Winding type: STAR  Poles pairs: %d\n", POLE_PAIRS);
    else
        printf("Winding type: DELTA  Poles pairs: %d\n", POLE_PAIRS);
    //set the sensor and start commutation
    set_commutation_sensor(c_commutation_p1, sensor_select);
    set_commutation_sinusoidal(c_commutation_p1, input_voltage);
    //prompt tuning
    if (sensor_select == HALL)
        printf ("Hall tuning. Voltage %d\nPlease enter an offset value different from %d, then press enter\n", input_voltage,
            (input_voltage > 0) ? ((WINDING_TYPE == 1) ? COMMUTATION_OFFSET_CLK : COMMUTATION_OFFSET_CCLK) : ((WINDING_TYPE == 1) ? COMMUTATION_OFFSET_CCLK : COMMUTATION_OFFSET_CLK)  );
    else if (sensor_select == BISS) {
        init_biss_param(biss_params);
        printf ("BiSS tuning. Voltage %d\nPlease enter an offset value different from %d, then press enter\n", input_voltage, BISS_OFFSET_ANGLE );
    }
    fflush(stdout);
    //read and adjust the offset
    while (1) {
        char c;
        unsigned value = 0;
        //reading user input. Only positive integers are accepted
        while((c = getchar ()) != '\n'){
            if(isdigit(c)>0){
                value *= 10;
                value += c - '0';
            }
        }
        printf("setting %i\n", value);
        //please note for the delta winding type offset_clk and offset_cclk are flipped
        if (sensor_select == BISS) {
            biss_params.offset_angle = value;
            i_biss.set_params(biss_params);
        } else {
            if (input_voltage > 0)
            {        //star winding
                if (WINDING_TYPE == 1)
                    set_commutation_offset_clk(c_commutation_p1, value);//910
                else
                    set_commutation_offset_cclk(c_commutation_p1, value);//2460
            }
            else
            {
                if (WINDING_TYPE == 1)
                    set_commutation_offset_cclk(c_commutation_p1, value);//2460
                else
                    set_commutation_offset_clk(c_commutation_p1, value);//910
            }
        }

        delay_milliseconds(10);
    }

}
