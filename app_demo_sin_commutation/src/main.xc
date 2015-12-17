/* PLEASE REPLACE "CORE_BOARD_REQUIRED" AND "IFM_BOARD_REQUIRED" WITH AN APPROPRIATE BOARD SUPPORT FILE FROM module_board-support */
//#include <CORE_BOARD_REQUIRED>
//#include <IFM_BOARD_REQUIRED>
#include <CORE_C22-rev-a.inc>
//#include <IFM_DC100-rev-b.inc>
#include <IFM_DC1K-rev-c1.inc>


/**
 * @brief Test illustrates usage of module_commutation
 * @date 17/06/2014
 */

#include <tuning.h>
#include <biss_server.h>
#include <stdio.h>
#include <timer.h>

#ifdef AD7265
#include <adc_7265.h>
#else
#include <adc_client_ad7949.h>
#include <adc_server_ad7949.h>
#endif

on tile[IFM_TILE]:clock clk_adc = XS1_CLKBLK_1;
on tile[IFM_TILE]:clock clk_pwm = XS1_CLKBLK_REF;
on tile[IFM_TILE]:clock clk_biss = XS1_CLKBLK_2 ;
port out p_ifm_biss_clk = GPIO_D0;

#define VOLTAGE 1000 //+/- 4095

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
        xscope_int(PHASE_B, phaseB);
        xscope_int(PHASE_C, phaseC);
        xscope_int(HALL_PINS, hall_state);
        delay_microseconds(50);
    }
}
#endif

void pwm_output(buffered out port:32 p_pwm, buffered out port:32 p_pwm_inv, int duty, int period, int msec) {
    const unsigned delay = 5*USEC_FAST;
    timer t;
    unsigned int ts;
    if (msec) {
        t :> ts;
        msec = ts + msec*MSEC_FAST;
    }

    while(1) {
        p_pwm <: 0xffffffff;
        delay_ticks(period*duty);
        p_pwm <: 0x00000000;
        delay_ticks(delay);
        p_pwm_inv<: 0xffffffff;
        delay_ticks(period*(100-duty) + 2*delay);
        p_pwm_inv <: 0x00000000;
        delay_ticks(delay);

        if (msec) {
            t :> ts;
            if (timeafter(ts, msec))
                break;
        }
    }
}
void brake_release(buffered out port:32 p_pwm,  buffered out port:32 p_pwm_inv) {
    printf("*************************************\n        BRAKE RELEASE\n*************************************\n");
    p_pwm <: 0;
    p_pwm_inv <: 0;
    pwm_output(p_pwm, p_pwm_inv, 100, 100, 100);
    pwm_output(p_pwm, p_pwm_inv, 22, 10, 0);
}

/* Test BiSS Encoder Client */
void biss_test(client interface i_biss i_biss) {
    timer t;
    unsigned int start_time, end_time;
    int count = 0;
    int real_count = 0;
    int velocity = 0;
    unsigned int position = 0;
    unsigned int status = 0;

    //i_biss.set_count(0);

    while(1) {
        t :> start_time;

        /* get position from BiSS Encoder */
        { count, position, status } = i_biss.get_position();
        t :> end_time;
        { real_count, void, void } = i_biss.get_real_position();
        //real_count = i_biss.get_angle_electrical();

        /* get velocity from BiSS Encoder */
        velocity = i_biss.get_velocity();

        xscope_int(COUNT, count);                           //absolute count
        xscope_int(REAL_COUNT, real_count);                 //real internal absolute count
        xscope_int(POSITION, position);
        xscope_int(VELOCITY, velocity);
        xscope_int(ERROR_BIT, (status&0b10) * 500);         //error bit, should be 0
        xscope_int(WARNING_BIT, (status&0b01) * 1000);      //warning bit, should be 0
        xscope_int(TIME, (end_time-start_time)/USEC_STD);    //time to get the data in microseconds

        delay_milliseconds(1);
    }
}

int main(void) {

    // Motor control channels
    chan c_qei_p1; // qei channels
    chan c_hall_p1, c_hall_p2, c_hall_p3, c_hall_p4, c_hall_p5, c_hall_p6;  // hall channels
    chan c_commutation_p1, c_signal;                                        // commutation channels
    chan c_pwm_ctrl, c_adctrig;                                             // pwm channels
    chan c_watchdog;
    interface i_biss i_biss[3];                                             // biss interfaces
    #ifdef AD7265
        interface ADC i_adc;
    #else
        chan c_adc;
    #endif

    par
    {

        on tile[APP_TILE_1]:
        {
            /* WARNING: only one blocking task is possible per tile. */
            /* Waiting for a user input blocks other tasks on the same tile from execution. */
            run_offset_tuning(VOLTAGE, c_commutation_p1, i_biss[1], BISS);
        }

        /* Test BiSS Encoder Client */
        on tile[COM_TILE]: biss_test(i_biss[2]);

        on tile[IFM_TILE]:
        {
            par
            {
                /* ADC Loop */
#ifdef AD7265
                adc_7265_continuous_loop(i_adc, adc_ports);
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
                    disable_fets(p_ifm_motor_hi, p_ifm_motor_lo, 3);
#endif
                    do_pwm_inv_triggered(c_pwm_ctrl, c_adctrig, p_ifm_dummy_port,
                                        p_ifm_motor_hi, p_ifm_motor_lo, clk_pwm);
                }

                /* Brake release */
                brake_release(p_ifm_motor_hi_d, p_ifm_motor_lo_d);

                /* Motor Commutation loop */
                {
                    hall_par hall_params;
                    qei_par qei_params;
                    commutation_par commutation_params;
                    init_hall_param(hall_params);

                    commutation_sinusoidal(c_hall_p1, c_qei_p1, i_biss[0], c_signal,
                            c_watchdog, c_commutation_p1, null, null, c_pwm_ctrl,
#ifdef DC1K
                            null, null, null, null,
#else
                            p_ifm_esf_rstn_pwml_pwmh, p_ifm_coastn, p_ifm_ff1, p_ifm_ff2,
#endif
                            hall_params, qei_params,
                            commutation_params, BISS);
                }


                /* Hall Server */
                {
                    hall_par hall_params;
                    #ifdef DC1K
                    //connector 1
                    p_ifm_encoder_hall_select_ext_d4to5 <: SET_PORT1_AS_QEI_PORT2_AS_HALL;
                    #endif
                    run_hall(c_hall_p1, c_hall_p2, c_hall_p3, c_hall_p4, c_hall_p5, c_hall_p6,
                            p_ifm_hall, hall_params); // channel priority 1,2..6

                }

                /* biss server */
                {
                    biss_par biss_params;
                    run_biss(i_biss, 3, p_ifm_biss_clk, p_ifm_encoder, clk_biss, biss_params, BISS_FRAME_BYTES);
                }

                /*Current sampling*/
                // It is placed here only for an educational purpose. Sampling with XSCOPE can also be done inside the adc server.
                #ifdef AD7265
//                    adc_client(i_adc, c_hall_p2);
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
