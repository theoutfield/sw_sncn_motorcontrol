
/**
 * \file
 * \brief Test illustrates usage of profile velocity control for brushed dc motor
 * \author Pavan Kanajar <pkanajar@synapticon.com>
 * \author Martin Schwarz <mschwarz@synapticon.com>
 * \version 0.9beta
 * \date 10/04/2014
 */

#include <xs1.h>
#include <platform.h>
#include <print.h>
#include <ioports.h>
#include <hall_server.h>
#include <qei_server.h>
#include <pwm_service_inv.h>
#include <brushed_dc_server.h>
#include "brushed_dc_client.h"
#include <refclk.h>
#include <velocity_ctrl_client.h>
#include <velocity_ctrl_server.h>
#include <xscope_wrapper.h>
#include <internal_config.h>
#include <bldc_motor_config.h>
#include <drive_config.h>
#include <profile_control.h>
#include <qei_client.h>
//#define ENABLE_xscope

#define IFM_TILE 3

on tile[IFM_TILE]: clock clk_adc = XS1_CLKBLK_1;
on tile[IFM_TILE]: clock clk_pwm = XS1_CLKBLK_REF;

void xscope_initialise_1()
{
    xscope_register(2, XSCOPE_CONTINUOUS, "0 actual_velocity", XSCOPE_INT,	"n",
                        XSCOPE_CONTINUOUS, "1 target_velocity", XSCOPE_INT, "n");
}


/* Test Profile Velocity function */
void profile_velocity_test(chanend c_velocity_ctrl)
{
	int target_velocity = 500;	 		// rpm
	int acceleration 	= 500;			// rpm/s
	int deceleration 	= 100;			// rpm/s

#ifdef ENABLE_xscope
	xscope_initialise_1();
#endif

	set_profile_velocity( target_velocity, acceleration, deceleration, MAX_PROFILE_VELOCITY, c_velocity_ctrl);

	//target_velocity = 0;				// rpm
	//set_profile_velocity( target_velocity, acceleration, deceleration, MAX_PROFILE_VELOCITY, c_velocity_ctrl);
}

int main(void)
{
	// Motor control channels
	chan c_qei_p1, c_qei_p2, c_qei_p3, c_qei_p4, c_qei_p5, c_hall_p6, c_qei_p6;		// qei channels
	chan c_hall_p1, c_hall_p2, c_hall_p3, c_hall_p4, c_hall_p5;						// hall channels
	chan c_voltage_p1, c_voltage_p2, c_voltage_p3, c_signal;						// motor drive channels
	chan c_pwm_ctrl, c_adctrig;														// pwm channels
	chan c_velocity_ctrl;															// velocity control channel
	chan c_watchdog; 																// watchdog channel

	par
	{
		/* Test Profile Velocity function */
		on tile[0]:
		{
			profile_velocity_test(c_velocity_ctrl);			// test PVM on node
		}

		on tile[0]:
		{
			/* Velocity Control Loop */
			{
				ctrl_par velocity_ctrl_params;
				filter_par sensor_filter_params;
				hall_par hall_params;
				qei_par qei_params;

				/* Initialize PID parameters for Velocity Control (defined in config/motor/bldc_motor_config.h) */
				init_velocity_control_param(velocity_ctrl_params);

				/* Initialize Sensor configuration parameters (defined in config/motor/bldc_motor_config.h) */
				init_qei_param(qei_params);

				/* Initialize sensor filter length */
				init_sensor_filter_param(sensor_filter_params);

				/* Control Loop */
				velocity_control(velocity_ctrl_params, sensor_filter_params, hall_params, \
					 qei_params, SENSOR_USED, c_hall_p2, c_qei_p2, c_velocity_ctrl, c_voltage_p2);
			}
		}

		/************************************************************
		 * IFM_CORE
		 ************************************************************/
		on tile[IFM_TILE]:
		{
			par
			{
				/* PWM Loop */
				do_pwm_inv_triggered(c_pwm_ctrl, c_adctrig, p_ifm_dummy_port,\
						p_ifm_motor_hi, p_ifm_motor_lo, clk_pwm);

				/* Brushed Motor Drive loop */

                bdc_loop(c_watchdog, c_signal, c_voltage_p1, c_voltage_p2, c_voltage_p3, c_pwm_ctrl,\
                        p_ifm_esf_rstn_pwml_pwmh, p_ifm_coastn, p_ifm_ff1, p_ifm_ff2);


				/* Watchdog Server */
				run_watchdog(c_watchdog, p_ifm_wd_tick, p_ifm_shared_leds_wden);

				/* Hall Server */
				{
					hall_par hall_params;
					init_hall_param(hall_params);
					run_hall(c_hall_p1, c_hall_p2, c_hall_p3, c_hall_p4, c_hall_p5, c_hall_p6, p_ifm_hall, hall_params);    // channel priority 1,2..5
				}

				/* QEI Server */
				{
					qei_par qei_params;
					init_qei_param(qei_params);
					run_qei(c_qei_p1, c_qei_p2, c_qei_p3, c_qei_p4, c_qei_p5, c_qei_p6, p_ifm_encoder, qei_params);         // channel priority 1,2..5
				}

			}
		}

	}

	return 0;
}
