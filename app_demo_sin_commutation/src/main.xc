/* PLEASE REPLACE "CORE_BOARD_REQUIRED" AND "IFM_BOARD_REQUIRED" WITH AN APPROPRIATE BOARD SUPPORT FILE FROM module_board-support */
#include <CORE_BOARD_REQUIRED>
#include <IFM_BOARD_REQUIRED>

/**
 * @brief Test illustrates usage of module_commutation
 * @date 17/06/2014
 */
#include <xs1.h>
#include <platform.h>
#include <hall_server.h>
#include <pwm_service_inv.h>
#include <commutation_server.h>
#include <refclk.h>
#include <drive_modes.h>
#include <statemachine.h>
#include <xscope.h>
#include <stdio.h>
#include <ctype.h>
#include <commutation_common.h>
#include <internal_config.h>
#include <bldc_motor_config.h>

on tile[IFM_TILE]:clock clk_adc = XS1_CLKBLK_1;
on tile[IFM_TILE]:clock clk_pwm = XS1_CLKBLK_REF;

#define VOLTAGE 2000 //+/- 4095

void xscope_user_init(void) {
   xscope_register(0, 0, "", 0, "");
//   xscope_config_io(XSCOPE_IO_TIMED);
}

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

int main(void) {

    // Motor control channels
    chan c_qei_p1; // qei channels
    chan c_hall_p1, c_hall_p2, c_hall_p3, c_hall_p4, c_hall_p5, c_hall_p6; // hall channels
    chan c_commutation_p1, c_commutation_p2, c_commutation_p3, c_signal; // commutation channels
    chan c_pwm_ctrl, c_adctrig; // pwm channels
    chan c_watchdog;

    par
    {
        on tile[0]:
        {
            set_commutation_sinusoidal(c_commutation_p1, VOLTAGE);

            /* Hall offset tuning app */
            {
                delay_seconds(1);
                printf (" Please enter an offset value different from %d, then press enter\n",
                        (VOLTAGE > 0) ? ((WINDING_TYPE == 1) ? COMMUTATION_OFFSET_CLK : COMMUTATION_OFFSET_CCLK) : ((WINDING_TYPE == 1) ? COMMUTATION_OFFSET_CCLK : COMMUTATION_OFFSET_CLK)  );
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
                    if (VOLTAGE > 0)
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
       }

        on tile[IFM_TILE]:
        {
            par
            {
                /* PWM Loop */
                do_pwm_inv_triggered(c_pwm_ctrl, c_adctrig, p_ifm_dummy_port,
                        p_ifm_motor_hi, p_ifm_motor_lo, clk_pwm);

                /* Motor Commutation loop */
                {
                    hall_par hall_params;
                    qei_par qei_params;
                    commutation_par commutation_params;
                    commutation_sinusoidal(c_hall_p1, c_qei_p1, c_signal,
                            c_watchdog, c_commutation_p1, c_commutation_p2,
                            c_commutation_p3, c_pwm_ctrl,
                            p_ifm_esf_rstn_pwml_pwmh, p_ifm_coastn, p_ifm_ff1,
                            p_ifm_ff2, hall_params, qei_params,
                            commutation_params);
                }

                /* Watchdog Server */
                run_watchdog(c_watchdog, p_ifm_wd_tick, p_ifm_shared_leds_wden);

                /* Hall Server */
                {
                    hall_par hall_params;
                    run_hall(c_hall_p1, c_hall_p2, c_hall_p3, c_hall_p4,
                            c_hall_p5, c_hall_p6, p_ifm_hall, hall_params); // channel priority 1,2..6
                }
            }
        }

    }

    return 0;
}
