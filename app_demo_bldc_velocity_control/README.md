Velocity Control Demo
=======================
![SYNAPTICON](https://s3-eu-west-1.amazonaws.com/synapticon-resources/images/logos/synapticon_fullname_blackoverwhite_280x48.png)

[test_velocity-ctrl.xc](https://github.com/synapticon/sc_sncn_motorctrl_sin/tree/master/test_velocity-ctrl/src) illustrates usage of [module_ctrl_loops][module_ctrl_loops] to do velocity control of a motor. Velocity Loop can be closed with position from either HALL sensor/ QEI Sensor or any other position sensor (if a drive server runs on IFM tile).

<table align="center" cellpadding="5" width="80%">
<tr>
    <th colspan="2">CORE use</th>
    <td rowspan="3" width="1px"></td>
    <th colspan="3">HW compatibility</th>
</tr>
<tr>
    <td>Parallel THREADS</td>
    <td width="30px" align="center"> 7 </td>

    <th align="center">COM</th>
    <th align="center">CORE</th>
    <th align="center">IFM</th>
</tr>
<tr>
    <td>TILES used</td>
    <td width="30px" align="center"> 2 </td>

    <td rowspan="2" align="center">*</td>
    <td rowspan="2" align="center">C21-DX <br/> C22 </td>
    <td rowspan="2" align="center">Drive DC 100 <br/> Drive DC 300</td>
</tr>
</table>


- **THREADS**: Profile Velocity, Velocity Control Loop, PWM Server, Commutation Server, Hall Server, QEI Server, Watchdog Server


- **TILES**:
```
	#define TILE_ONE 0
	#define IFM_TILE 3
```

> **Do not forget to set properly your motor configuration when using this application**.

<!-- - [Configure your node]() -->
- [How to configure your motors](https://github.com/synapticon/sc_sncn_motorctrl_sin/blob/master/howto/HOW_TO_CONFIGURE_MOTORS.md)


###**TILE_ONE** 
This tile (0 by default) takes care of the client side functions and control loop. Since these functions do not require any port access, any free TILE could run them.
```
	on stdcore[TILE_ONE]:
```
- **Thread**: Profile Velocity client
```
	profile_velocity_test(c_velocity_ctrl);	// Test Velocity Profile Mode on slave side
```
Set new target velocity for the controller. Read more at [module_profile][module_profile].


- **Thread**: Velocity Control Loop
```
	ctrl_par velocity_ctrl_params; //Var definition
	filter_par sensor_filter_params;
	hall_par hall_params;
	qei_par qei_params;

	init_velocity_control_param(velocity_ctrl_params); //Initialization
	init_qei_param(qei_params);
	init_hall_param(hall_params);
	init_sensor_filter_param(sensor_filter_params);

	velocity_control(velocity_ctrl_params, sensor_filter_params, hall_params, 
			qei_params, SENSOR_USED, c_hall_p2, c_qei_p2, 
			c_velocity_ctrl, c_commutation_p2); //Control loop
```		
Read back actual velocity of the motor. Read more at [module_ctrl_loops][module_ctrl_loops] or [module_blocks][module_blocks].

###IFM_TILE 
This tile (3 by default) executes the server side functions, controlling the interfaces. These functions need access to the Interface Module (IFM), just the tile that provides access to the IFM ports can run these functions.  
```
	on stdcore[IFM_TILE]:
```				
- **Thread**: PWM Server.
```
	do_pwm_inv_triggered(c_pwm_ctrl, c_adctrig, p_ifm_dummy_port, p_ifm_motor_hi, p_ifm_motor_lo, clk_pwm);
```
Responsible for generating a Pulse-Width Modulation signal that drives the motors. Provided by the [module_pwm_symmetrical][module_pwm_symmetrical]@[sc_pwm][sc_pwm].

- **Thread**: Commutation Server 

```
	hall_par hall_params; //Var definition
	qei_par qei_params;
	commutation_par commutation_params;

	init_hall_param(hall_params); //Initialization
	init_qei_param(qei_params);

	commutation_sinusoidal(c_hall_p1,  c_qei_p2, c_signal, c_watchdog, c_commutation_p1,
				c_commutation_p2, c_commutation_p3, c_pwm_ctrl, hall_params,
				qei_params, commutation_params); //Read feedback
```

Responsible for proper BLDC motor drive. Read more at [module_commutation][module_commutation].

- **Thread**: Hall Server
```
	hall_par hall_params;
	run_hall(c_hall_p1, c_hall_p2, c_hall_p3, c_hall_p4, c_hall_p5,
			p_ifm_hall, hall_params); //Channel priority 1,2..5
```
To obtain information about motor position for position control loop, its use is mandatory since the motor commutation is Hall-based. Read more at [module_hall][module_hall].

- **Thread**: QEI Server
```
	qei_par qei_params;
	run_qei(c_qei_p1, c_qei_p2, c_qei_p3, c_qei_p4, c_qei_p5,
			p_ifm_encoder, qei_params);  	// channel priority 1,2..5
```
To obtain high precision information about motor position. Read more at [module_qei][module_qei].

- **Thread**: Watchdog Server
```
	run_watchdog(c_watchdog, p_ifm_wd_tick, p_ifm_shared_leds_wden);
```
A watchdog server is used to monitor IFM_TILE and disables motor in case of emergency. Read more at [module_watchdog][module_watchdog].


More information about Velocity Control Server/Client can be found at [module_ctrl_loops][module_ctrl_loops] documentation.

Other dependencies: [module_common][module_common] [module_sm][module_sm] [module_nodeconfig][module_nodeconfig]@[sc_somanet-base][sc_somanet-base] 

**See also**:

- [Getting started with SOMANET][getting_started_somanet]    


[sc_sncn_ethercat]:https://github.com/synapticon/sc_sncn_ethercat
[sc_pwm]: https://github.com/synapticon/sc_pwm
[sc_somanet-base]: https://github.com/synapticon/sc_somanet-base

[module_adc]: https://github.com/synapticon/sc_sncn_motorctrl_sin/tree/master/module_adc
[module_hall]: https://github.com/synapticon/sc_sncn_motorctrl_sin/tree/master/module_hall
[module_watchdog]: https://github.com/synapticon/sc_sncn_motorctrl_sin/tree/master/module_watchdog
[modle_ecat_drive]: https://github.com/synapticon/sc_sncn_motorctrl_sin/tree/master/module_ecat_drive
[module_ctrl_loops]: https://github.com/synapticon/sc_sncn_motorctrl_sin/tree/master/module_ctrl_loops
[module_blocks]: https://github.com/synapticon/sc_sncn_motorctrl_sin/tree/master/module_blocks
[module_qei]: https://github.com/synapticon/sc_sncn_motorctrl_sin/tree/master/module_qei
[module_commutation]: https://github.com/synapticon/sc_sncn_motorctrl_sin/tree/master/module_commutation
[module_gpio]: https://github.com/synapticon/sc_sncn_motorctrl_sin/tree/master/module_gpio
[module_common]: https://github.com/synapticon/sc_sncn_motorctrl_sin/tree/master/module_common
[module_sm]: https://github.com/synapticon/sc_sncn_motorctrl_sin/tree/master/module_sm
[module_homing]: https://github.com/synapticon/sc_sncn_motorctrl_sin/tree/master/test_homing

[module_ethercat]: https://github.com/synapticon/sc_sncn_ethercat/tree/master/module_ethercat

[module_pwm_symmetrical]: https://github.com/synapticon/sc_pwm/tree/master/module_pwm_symmetrical

[module_nodeconfig]: https://github.com/synapticon/sc_somanet-base/tree/master/module_nodeconfig

[how_to_configure_motors]: https://github.com/synapticon/sc_sncn_motorctrl_sin/blob/master/howto/HOW_TO_CONFIGURE_MOTORS.md
[getting_started_somanet]: http://doc.synapticon.com/wiki/index.php/Category:Getting_Started_with_SOMANET