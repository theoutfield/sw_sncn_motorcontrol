/* PLEASE REPLACE "CORE_BOARD_REQUIRED" AND "IFM_BOARD_REQUIRED" WITH AN APPROPRIATE BOARD SUPPORT FILE FROM module_board-support */
#include <CORE_C21-rev-a.inc>
#include <IFM_DC1K-rev-c2.inc>


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

#define NUM_OF_AMS_INTERFACES 2

on tile[IFM_TILE]: sensor_spi_interface p_rotary_sensor =
{
        {
            XS1_CLKBLK_2,
            XS1_CLKBLK_4,
            GPIO_D3, //D3,    //mosi
            GPIO_D1, //D1,    //sclk
            GPIO_D2  //D2     //miso
        },

        GPIO_D0 //D0         //slave select
};

#define VOLTAGE 500 //+/- 4095

#ifdef AD7265
on tile[IFM_TILE]: adc_ports_t adc_ports =
{
        {ADC_DATA_A, ADC_DATA_B},
        ADC_INT_CLK,
        ADC_SCLK,
        ADC_READY,
        ADC_MUX
};

void sample_data(client interface ADC i_adc){
    int sampling_time, phaseB, phaseC;
    while(1){
        {phaseB, phaseC, sampling_time} = i_adc.get_adc_measurements(1, 1);//port_id, config
        xscope_int(PHASE_B, phaseB);
        xscope_int(PHASE_C, phaseC);
        delay_microseconds(50);
    }
}
#endif


int main(void) {

    // Motor control channels
    chan c_qei_p1; // qei channels
    chan c_hall_p1, c_hall_p2, c_hall_p3, c_hall_p4, c_hall_p5, c_hall_p6; // hall channels
    chan c_commutation_p1, c_commutation_p2; // commutation channels
    chan c_pwm_ctrl, c_adctrig; // pwm channels
    chan c_watchdog;
    #ifdef AD7265
        interface ADC i_adc;
    #else
        chan c_adc;
    #endif
    interface AMS i_ams[NUM_OF_AMS_INTERFACES];


    par
    {

        on tile[APP_TILE]:
        {
            /* WARNING: only one blocking task is possible per tile. */
            /* Waiting for a user input blocks other tasks on the same tile from execution. */
            run_offset_tuning(VOLTAGE, c_commutation_p1, c_commutation_p2, i_ams[1], c_hall_p2);
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

                /* Watchdog Server */
#ifdef DC1K
                run_watchdog(c_watchdog, null, p_ifm_led_moton_wdtick_wden);
#else
                run_watchdog(c_watchdog, p_ifm_wd_tick, p_ifm_shared_leds_wden);
#endif

                /* PWM Loop */
                {
#ifdef DC1K
                    // Turning off all MOSFETs for for initialization
                    disable_fets(p_ifm_motor_hi, p_ifm_motor_lo, 4);
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
                    i_ams[0].configure(set_configuration());

                    commutation_sinusoidal(c_hall_p1, c_qei_p1, i_ams[0],
                            null, c_watchdog,
                            c_commutation_p1, c_commutation_p2, null,
                            c_pwm_ctrl,
#ifdef DC1K
                            null, null, null, null,
#else
                            p_ifm_esf_rstn_pwml_pwmh, p_ifm_coastn, p_ifm_ff1, p_ifm_ff2,
#endif
                            hall_params, qei_params,
                            commutation_params);
                }


                /* Hall Server */
                {
                    hall_par hall_params;
                    #ifdef DC1K
                    //connector 1
                    p_ifm_encoder_hall_select_ext_d4to5 <: SET_ALL_AS_HALL;
                    #endif
                    run_hall(c_hall_p1, c_hall_p2, c_hall_p3, c_hall_p4, c_hall_p5, c_hall_p6,
                            p_ifm_hall, hall_params); // channel priority 1,2..6

                }

                ams_sensor_server(i_ams, NUM_OF_AMS_INTERFACES, p_rotary_sensor);

                /*Current sampling*/
                // It is placed here only for an educational purpose. Sampling with XSCOPE can also be done inside the adc server.
                #ifdef AD7265
                sample_data(i_adc);
                #else
                {
                    calib_data I_calib;
                    do_adc_calibration_ad7949(c_adc, I_calib);
                    while (1) {
                        int b, c;
                        unsigned state;
                        {b, c} = get_adc_calibrated_current_ad7949(c_adc, I_calib);
                        state = get_hall_pinstate(c_hall_p2);
                        xscope_int(PHASE_B, b);
                        xscope_int(PHASE_C, c);
                        xscope_int(HALL_PINS, state);
                        delay_microseconds(10);
                    }
                }
                #endif
            }
        }

    }

    return 0;
}
