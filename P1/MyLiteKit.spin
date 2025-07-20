{
  ***************************************
  Mobile Platform (Xbee/Camera Control)
  ***************************************

  1.  Platform Chassis X 1
  2.  Roboclaw Motor Controllers X 2
  3.  Power Regulator Board X 1
  4.  Rechargable Batteries X 3
  5.  Propeller Project Board USB X 1
  6.  HC-SR04 X 2
  7.  VL6180X X 2
  8.  Xbee X 2
  9.  Driver: UltrasonicSensor.spin, ToFSensor.spin, i2cDriver.spin, FullDuplexSerialExt.spin, RxBoardDef.spin,
              FDS4FC.spin
}


CON
  'Clock Settings
  _clkmode = xtal1 + pll16x                             'Standard clock mode * crystal frequency = 80 MHz
  _xinfreq = 5_000_000
  _ConClkFreq = ((_clkmode - xtal1) >> 6) * _xinfreq
  _Ms_001 = _ConClkFreq / 1_000                         'Timer setting


VAR

  LONG  CTID, MCID                                       'cogID for tracking
  BYTE  Ready, Stop, Movement, Speed
  LONG  StopAll


OBJ

  Def   : "RxBoardDef.spin"
  Motor : "MecanumControl.spin"                         'RoboClaw Controller
  Comm  : "CommTrackControl.spin"
  'Term  : "FullDuplexSerialExt.spin"                    'Pins 31,  30 for Rx, Tx - For Debugging, use Term.Dec(var) to check value of a variable


PUB Main

  DIRA[17]~
  'Initialise all parameters
  Ready := 1                                            'Set Ready to 0 so that it does not start program till Xbee start
  Stop  := 3                                            'Enable all sensors on program start
  Movement := 0                                         'Default movement set at Stop
  Speed := 0                                            'Default normalised speed (throttle) set at 0%
  StopAll := FALSE

  'Activate all control modules in safe order
  CTID := Comm.ActCT(@Ready, @Movement, @Speed)         'Activate XBee and Track Control
  MCID := Motor.ActMC(@Ready, @Movement, @Speed, @StopAll)        'Activate Motor Control

  repeat
    if !INA[17]
      StopAll := TRUE
      repeat while !INA[17]

      Pause(3000)
      StopAll := FALSE
    else
      StopAll := FALSE


PRI Pause(ms) | t
  t := cnt - 1088
  repeat (ms #> 0)
    waitcnt(t += _Ms_001)

  return