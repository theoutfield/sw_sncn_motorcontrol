/* PLEASE REPLACE "CORE_BOARD_REQUIRED" AND "IFM_BOARD_REQUIRED" WITH AN APPROPRIATE BOARD SUPPORT FILE FROM module_board-support */
#include <CORE_C21-rev-a.inc>
#include <IFM_DC100-rev-b.inc>


/**
 * @brief Test illustrates usage of module_commutation
 * @date 17/06/2014
 */

#include <platform.h>
#include <hall_server.h>
#include <pwm_service_inv.h>
#include <refclk.h>
#include <xscope.h>
#include <bldc_motor_config.h>
#include <watchdog.h>


#include <foc_base.h>
//#include <torque_control.h>

#ifdef AD7265
#include <adc_7265.h>
#else
#include <adc_client_ad7949.h>
#include <adc_server_ad7949.h>
#endif

on tile[IFM_TILE]:clock clk_adc = XS1_CLKBLK_1;
on tile[IFM_TILE]:clock clk_pwm = XS1_CLKBLK_REF;
on tile[IFM_TILE]:clock clk_biss = XS1_CLKBLK_2 ;

#define TORQUE 1000 //+/- 4095
#define Q_MAX 3000


void simple_torque_controller(client interface foc_base i_foc_base){
    delay_seconds(5);
    int torque_actual = 0, error = 0, setpoint = 0, feedforward = 200;
    while(1){
        error = TORQUE - i_foc_base.get_torque_actual();
        if (error > 0) setpoint++;
        else setpoint--;

        if (setpoint > Q_MAX) setpoint = Q_MAX;
        if (setpoint < -Q_MAX) setpoint = -Q_MAX;

        if((setpoint > 0)  && (setpoint < 50)) setpoint = 50;
        else if ((setpoint < 0)  && (setpoint > -50)) setpoint = -50;

        if (setpoint < feedforward) setpoint = feedforward;

        xscope_int(DEBUG_VALUE, setpoint);
        xscope_int(CONTROL_ERROR, error);

        i_foc_base.set_q(setpoint);
        delay_milliseconds(1);
    }
}


int main(void) {

    // Motor control channels
    chan c_hall_p1;  // hall channels
    chan c_pwm_ctrl, c_adctrig;                                             // pwm channels
    chan c_watchdog;

    chan c_adc;

    interface foc_base i_foc_base;


    par
    {

        on tile[APP_TILE]:
        {
 //           i_foc_base.set_q(TORQUE);

        }

        on tile[IFM_TILE]:
        {
            par
            {
                simple_torque_controller(i_foc_base);


                /* ADC Loop */
                adc_ad7949_triggered(c_adc, c_adctrig, clk_adc,\
                        p_ifm_adc_sclk_conv_mosib_mosia, p_ifm_adc_misoa,\
                        p_ifm_adc_misob);


                /* Watchdog Server */

                run_watchdog(c_watchdog, p_ifm_wd_tick, p_ifm_shared_leds_wden);

                /* PWM Loop */
                {
             //       do_pwm_inv(c_pwm_ctrl, p_ifm_motor_hi, p_ifm_motor_lo, clk_pwm);
                    do_pwm_inv_triggered(c_pwm_ctrl, c_adctrig, p_ifm_dummy_port,
                                         p_ifm_motor_hi, p_ifm_motor_lo, clk_pwm);
                }
                /* Motor Commutation loop */
                {
                    t_pwm_control s_pwm_control;
                    hall_par hall_params;
                    init_hall_param(hall_params);

                    FOC_base( i_foc_base, s_pwm_control,         p_ifm_coastn,   p_ifm_esf_rstn_pwml_pwmh, p_ifm_ff1, p_ifm_ff2,
                            c_pwm_ctrl,          c_adc,          c_hall_p1,  c_watchdog);

                }


                /* Hall Server */
                {
                    hall_par hall_params;
                    run_hall(c_hall_p1, null, null, null, null, null,
                            p_ifm_hall, hall_params); // channel priority 1,2..6

                }


            }
        }

    }

    return 0;
}
