/**
 * \file
 * \brief Main project file
 *
 * parameter
 *
 * \author Martin Schwarz <mschwarz@synapticon.com>
 * \version 0.1 (2012-02-22 1850)
 * orgler 11/2013
 * \
 */

#ifndef _DC_MOTOR_CONFIG__H_
#define _DC_MOTOR_CONFIG__H_
//#pragma once




#define DC100

//#define DEBUG_XSCOPE

//=========================================================
//#define MOTOR_MAXON_EC55   //   439860 only hall 7 pole pairs hall + encoder
#define MOTOR_NANOTEC_DB57C01
//==========================================================

#define MAX_TEMPERATURE  7500   // 75 degrees


// Add your motor configuration here
//=============================================================
#ifdef  MOTOR_MAXON_EC55

//Select the desired sensor. Any combination is possible, including two together.
#define defHALL
//#define defENCODER


#define  START_TYPE_HALL_ENCODER        0     // 0=only HALL   1=only Encoder    2=start with HALL -> change automatically to ENCODER
										      // if only encoder we must run sensorless to found the zero reference
#define  START_SENSORLESS_RPM          50     // from  10 to  80
#define  START_SENSORLESS_UMOT        300     // from 100 to 600
//-----------------------------------------
#define MOTOR_POWER 			      60//100
#define POLE_PAIRS		  		        8//7
#define GEAR_RATIO		  		        4
//------------------------------------------
#define SPEED_MAX					 3500
#define TORQUE_MAX		  			 4000
#define TORQUE_NOMINAL        		 1000
//------------------------------------------
#define HALL_OFFSET                     0   // offset for hall angle 0 - 4095
//-------- test encoder on the workbench ---
#define ENCODER_OFFSET               3810         // !!!!  positive value = OFFSET from user   0 - 4095
#define ENCODER_RESOLUTION           4096
#define ENCODER_TYPE   				    3		  // 3=with zero refernce 3lines    2=without zero reference 2 lines
#define ENCODER_SPEED_DIRECTION         1         // 0=normal 1=direction inverted
#define ENCODER_COUNT_DIRECTION         0         // 0=normal 1=direction inverted
//======== current limits ==================
#define CURRENT_LIMIT_PWM_OFF         8000
#define NOMINAL_CURRENT               4800
#define NOMINAL_TORQUE				   700

#define SPEED_Kp		   	     	  2048			// 0 - 2048    0.0 .. 2,0
#define SPEED_Ki			     		40
#define SPEED_Kd                      1024          // derivative
//-------------------------------------------
#define TORQUE_Kp		   	           512			// 0 - 1024
#define TORQUE_Ki			            40
#define TORQUE_Kd			            32
#define TORQUE_FEED_FORWARD              0         // 0 - 1024
//=========================================
#define FIELD_Kp                        64
#define FIELD_Ki                        10
//=========================================
//=========================================
#define ACTUAL_POSITION_SOURCE           0         // source:  0=hall 1=encoder
#define POSITION_Kp                   1024         // speed_set = ( position_difference * POSITION_Kp ) / 1024
#define POSITION_MAX_SPEED            1000   	   // RPM
#define POSITION_MIN_SPEED              50   	   // RPM
//========================================
#define QUICK_DECELERATION              10   		// RPM/sec
#define RAMP_UMOT                      100          // msec  50 - 1000
#endif
//=====end of EC55 ===========================================

//==============MOTOR_NANOTEC_DB57C01==============//
#ifdef  MOTOR_NANOTEC_DB57C01

//Select the desired sensor. Any combination is possible, including two together.
#define defHALL
//#define defENCODER


#define  START_TYPE_HALL_ENCODER        0     // 0=only HALL   1=only Encoder    2=start with HALL -> change automatically to ENCODER
                                              // if only encoder we must run sensorless to found the zero reference
#define  START_SENSORLESS_RPM          50     // from  10 to  80
#define  START_SENSORLESS_UMOT        300     // from 100 to 600
//-----------------------------------------
#define MOTOR_POWER                   120
#define POLE_PAIRS                      2
#define GEAR_RATIO                      1
//------------------------------------------
#define SPEED_MAX                    3500
#define TORQUE_MAX                   4000
#define TORQUE_NOMINAL               1000
//------------------------------------------
#define HALL_OFFSET                     0   //2100       // offset for hall angle 0 - 4095
//-------- test encoder on the workbench ---
#define ENCODER_OFFSET               3810         // !!!!  positive value = OFFSET from user   0 - 4095
#define ENCODER_RESOLUTION           4096
#define ENCODER_TYPE                    3         // 3=with zero refernce 3lines    2=without zero reference 2 lines
#define ENCODER_SPEED_DIRECTION         1         // 0=normal 1=direction inverted
#define ENCODER_COUNT_DIRECTION         0         // 0=normal 1=direction inverted
//======== current limits ==================
#define CURRENT_LIMIT_PWM_OFF         8000
#define NOMINAL_CURRENT               5870
#define NOMINAL_TORQUE                3700

#define SPEED_Kp                      2048          // 0 - 2048    0.0 .. 2,0
#define SPEED_Ki                        40
#define SPEED_Kd                      1024          // derivative
//-------------------------------------------
#define TORQUE_Kp                      512          // 0 - 1024
#define TORQUE_Ki                       40
#define TORQUE_Kd                       32
#define TORQUE_FEED_FORWARD              0         // 0 - 1024
//=========================================
#define FIELD_Kp                        64
#define FIELD_Ki                        10
//=========================================
//=========================================
#define ACTUAL_POSITION_SOURCE           0         // source:  0=hall 1=encoder
#define POSITION_Kp                   1024         // speed_set = ( position_difference * POSITION_Kp ) / 1024
#define POSITION_MAX_SPEED            1000         // RPM
#define POSITION_MIN_SPEED              50         // RPM
//========================================
#define QUICK_DECELERATION              10          // RPM/sec
//#define RAMP_UMOT                       50          // msec  50 - 1000
#endif
//=====end of EC55 ===========================================

#endif
