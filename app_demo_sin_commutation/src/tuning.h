/*
 * tuning.h
 *
 *  Created on: Jul 13, 2015
 *      Author: Synapticon GmbH
 */


#ifndef TUNING_H_
#define TUNING_H_

#include <platform.h>
#include <commutation_server.h>
#include <hall_server.h>
#include <pwm_service_inv.h>
#include <refclk.h>
#include <drive_modes.h>
#include <statemachine.h>
#include <xscope.h>
#include <bldc_motor_config.h>
#include <commutation_common.h>
#include <internal_config.h>

void set_commutation_offset_clk(chanend c_signal, unsigned offset);

void set_commutation_offset_cclk(chanend c_signal, unsigned offset);

void run_offset_tuning(int input_voltage, chanend c_commutation_p1, chanend c_commutation_p2);

#endif /* TUNING_H_ */
