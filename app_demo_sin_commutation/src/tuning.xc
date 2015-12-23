/*
 * tuning.xc
 *
 *  Created on: Jul 13, 2015
 *      Author: Synapticon GmbH
 */
#include <tuning.h>
#include <stdio.h>
#include <ctype.h>

void set_commutation_offset_clk(chanend c_signal, unsigned offset){
    c_signal <: COMMUTATION_CMD_SET_PARAMS;
    c_signal <: (60 * 4096) / (POLE_PAIRS * 2 * 360);
    c_signal <: MAX_NOMINAL_SPEED;
    c_signal <: offset;
    c_signal <: COMMUTATION_OFFSET_CCLK;
    c_signal <: WINDING_TYPE;

}

void set_commutation_offset_cclk(chanend c_signal, unsigned offset){
    c_signal <: COMMUTATION_CMD_SET_PARAMS;
    c_signal <: (60 * 4096) / (POLE_PAIRS * 2 * 360);
    c_signal <: MAX_NOMINAL_SPEED;
    c_signal <: COMMUTATION_OFFSET_CLK;
    c_signal <: offset;
    c_signal <: WINDING_TYPE;

}


void run_offset_tuning(int input_voltage, chanend c_commutation_p2, client interface AMS ?i_ams, chanend ?c_hall_){
    int absolute_position_singleturn = 0;
    unsigned angle_electrical = 0;
    delay_seconds(1);

    if(!isnull(i_ams)){
        printf("setting to zero\n");
        set_to_zero_angle(c_commutation_p2, 200);
        printf("done\n");
        while(1){
            printf("%i\n", i_ams.get_absolute_position_singleturn());
        }
    }

//    if(!isnull(i_ams)){
//        set_to_zero_angle(c_commutation_p1, 200);
//        delay_seconds(3);
//        for (int i = 0; i < 20; i++){
//            absolute_position_singleturn += i_ams.get_absolute_position_singleturn();
//           // printf("%i\n",i_ams.get_absolute_position_singleturn());
//        }
//        int offset = absolute_position_singleturn/20;
//        printf("AMS offset: %i\n", offset);
//
// //       ams_config_params_t params = i_ams.get_configuration();
//  //      params.sensor_placement_offset = absolute_position_singleturn/20;
//        i_ams.set_offset(offset);
//    //   i_ams.configure(params);
//    }

    if(!isnull(c_hall_)){
        angle_electrical = get_hall_pinstate(c_hall_);
    }

    printf (" Please enter an offset value different from %d, then press enter\n",
            (input_voltage > 0) ? ((WINDING_TYPE == 1) ? COMMUTATION_OFFSET_CLK : COMMUTATION_OFFSET_CCLK) : ((WINDING_TYPE == 1) ? COMMUTATION_OFFSET_CCLK : COMMUTATION_OFFSET_CLK)  );
    fflush(stdout);
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
        if (input_voltage > 0)
        {        //star winding
            if (WINDING_TYPE == 1) set_commutation_offset_clk(c_commutation_p2, value);//910
            else set_commutation_offset_cclk(c_commutation_p2, value);//2460
        }
        else
        {
            if (WINDING_TYPE == 1) set_commutation_offset_cclk(c_commutation_p2, value);//2460
            else set_commutation_offset_clk(c_commutation_p2, value);//910
        }

        delay_milliseconds(10);
    }

}

void perform_ramp(int input_voltage, chanend c_commutation){
    int sign = 1;
    if (input_voltage < 0) sign = -1;

    for (int ramp = 0; ramp < abs(input_voltage); ramp++){
        set_commutation_sinusoidal(c_commutation, ramp * sign);
        delay_milliseconds(3);
    }
}
