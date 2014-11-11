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
#include <internal_config.h>
#include <bldc_motor_config.h>

on tile[IFM_TILE]:clock clk_adc = XS1_CLKBLK_1;
on tile[IFM_TILE]:clock clk_pwm = XS1_CLKBLK_REF;

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
            while (1) {
                set_commutation_sinusoidal(c_commutation_p1, 2000);
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
