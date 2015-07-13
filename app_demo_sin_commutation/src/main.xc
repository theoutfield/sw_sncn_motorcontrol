/* PLEASE REPLACE "CORE_BOARD_REQUIRED" AND "IFM_BOARD_REQUIRED" WITH AN APPROPRIATE BOARD SUPPORT FILE FROM module_board-support */
#include <CORE_BOARD_REQUIRED>
#include <IFM_BOARD_REQUIRED>

/**
 * @brief Test illustrates usage of module_commutation
 * @date 17/06/2014
 */

#include <tuning.h>

#ifdef AD7265
#include <adc_7265.h>
#else
#include <adc_client_ad7949.h>
#include <adc_server_ad7949.h>
#endif

on tile[IFM_TILE]:clock clk_adc = XS1_CLKBLK_1;
on tile[IFM_TILE]:clock clk_pwm = XS1_CLKBLK_REF;

#define VOLTAGE 2000 //+/- 4095

#ifdef AD7265
on tile[IFM_TILE]: adc_ports_t adc_ports =
{
        {ADC_DATA_A, ADC_DATA_B},
        ADC_INT_CLK,
        ADC_SCLK,
        ADC_READY,
        ADC_MUX
};

void adc_client(client interface ADC i_adc, chanend c_hall_){
    int sampling_time, phaseB, phaseC;
    unsigned hall_state = 0;
    while(1){
        {phaseB, phaseC, sampling_time} = i_adc.get_adc_measurements(1, 1);//port_id, config
        hall_state = get_hall_pinstate(c_hall_);
        xscope_int(0, phaseB);
        xscope_int(1, phaseC);
        xscope_int(2, hall_state);
        delay_microseconds(50);
    }
}
#endif

void xscope_user_init(void) {
  xscope_register(3,
    XSCOPE_CONTINUOUS, "Phase B",  XSCOPE_INT, "_",
    XSCOPE_CONTINUOUS, "Phase C", XSCOPE_INT, "_",
    XSCOPE_CONTINUOUS, "HALL pins", XSCOPE_INT, "_"
  );
}


int main(void) {

    // Motor control channels
    chan c_qei_p1; // qei channels
    chan c_hall_p1, c_hall_p2, c_hall_p3, c_hall_p4, c_hall_p5, c_hall_p6; // hall channels
    chan c_commutation_p1, c_commutation_p2, c_commutation_p3, c_signal; // commutation channels
    chan c_pwm_ctrl, c_adctrig; // pwm channels
    chan c_watchdog;
    #ifdef AD7265
        interface ADC i_adc;
    #else
        chan c_adc;
    #endif

    par
    {

        on tile[APP_TILE]:
        {
            /* WARNING: only one blocking task is possible per tile. */
            /* Waiting for a user input blocks other tasks on the same tile from execution. */
            run_offset_tuning(VOLTAGE, c_commutation_p1, c_commutation_p2);
        }

        on tile[IFM_TILE]:
        {
            par
            {
                /* ADC Loop */
#ifdef AD7265
                foc_adc_7265_continuous_loop(i_adc, adc_ports);
#else
                adc_ad7949_triggered(c_adc, c_adctrig, clk_adc,\
                        p_ifm_adc_sclk_conv_mosib_mosia, p_ifm_adc_misoa,\
                        p_ifm_adc_misob);
#endif
                /* Watchdog Server */   //p_ifm_wd_tick, p_ifm_shared_leds_wden
                run_watchdog(c_watchdog, null, p_ifm_led_moton_wdtick_wden);


                /* PWM Loop */
                {
#ifdef DC1K
                    // Turning off all MOSFETs for for initialization
                    p_ifm_motor_hi[0] <: 0;
                    p_ifm_motor_hi[1] <: 0;
                    p_ifm_motor_hi[2] <: 0;
                    p_ifm_motor_hi[3] <: 0;
                    p_ifm_motor_lo[0] <: 0;
                    p_ifm_motor_lo[1] <: 0;
                    p_ifm_motor_lo[2] <: 0;
                    p_ifm_motor_lo[3] <: 0;

                    delay_milliseconds(1);
#endif
                    do_pwm_inv_triggered(c_pwm_ctrl, c_adctrig, p_ifm_dummy_port,
                                        p_ifm_motor_hi, p_ifm_motor_lo, clk_pwm);
                }
                /* Motor Commutation loop */
                {
                    hall_par hall_params;
                    qei_par qei_params;
                    commutation_par commutation_params;
                    init_hall_param(hall_params);
                    commutation_sinusoidal(c_hall_p1, c_qei_p1, c_signal,
                            c_watchdog, c_commutation_p1, c_commutation_p2,
                            c_commutation_p3, c_pwm_ctrl,
                            null, null, null,
                            null, hall_params, qei_params,
                            commutation_params);
                }


                /* Hall Server */
                {
                    hall_par hall_params;
                    #ifdef DC1K
                    //connector 1
                    p_ifm_encoder_hall_select_ext_d4to5 <: SET_ALL_AS_HALL;
                    run_hall(c_hall_p1, c_hall_p2, c_hall_p3, c_hall_p4, c_hall_p5, c_hall_p6,
                                            p_ifm_encoder_hall_1, hall_params); // channel priority 1,2..6

                    #else
                    run_hall(c_hall_p1, c_hall_p2, c_hall_p3, c_hall_p4, c_hall_p5, c_hall_p6,
                            p_ifm_hall, hall_params); // channel priority 1,2..6
                    #endif
                }

                /*Current sampling*/
                // It is placed here only for an educational purpose. Sampling with XSCOPE can also be done inside the adc server.
                #ifdef AD7265
                    adc_client(i_adc, c_hall_p2);
                #else
                {
                    calib_data I_calib;
                    do_adc_calibration_ad7949(c_adc, I_calib);
                    while (1) {
                        int b, c;
                        unsigned state;
                        {b, c} = get_adc_calibrated_current_ad7949(c_adc, I_calib);
                        state = get_hall_pinstate(c_hall_p2);
                        xscope_int(0, b);
                        xscope_int(1, c);
                        xscope_int(2, state);
                        delay_microseconds(10);
                    }
                }
                #endif
            }
        }

    }

    return 0;
}
