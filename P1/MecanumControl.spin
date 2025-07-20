{
  Project:      Mobile Platform - Build 1 (Mechanum Control)
  Platform:     Parallax Project USB Board
  Revision:     2.0
  Author:       SIT
  Date:         10 Feb 2024
  Log:
}


CON
  'Clock Settings
  _clkmode = xtal1 + pll16x                             'Standard clock mode * crystal frequency = 80 MHz
  _xinfreq = 5_000_000
  _ConClkFreq = ((_clkmode - xtal1) >> 6) * _xinfreq
  _Ms_001 = _ConClkFreq / 1_000

  'Motor Control Parameters (refer to page 55 of roboclaw_user_manual.pdf)
  throtMin      = 0
  throtMax      = 100
  motS1FwdRange = 63
  motS1Stop     = 64
  motS1RevRange = 63
  motS2FwdRange = 63
  motS2Stop     = 192
  motS2RevRange = 64

VAR

  LONG MotorCogID, MotorCogStack[64]
  BYTE Speed                                            'Normalised speed setting from 0% to 100%

OBJ

  Def           : "RxBoardDef.spin"
  SerialDriver  : "FDS4FC.spin"
  'Term          : "FullDuplexSerialExt.spin"            'Pins 31,  30 for Rx, Tx - For Debugging, use Term.Dec(var) to check value of a variable

PUB Main

  repeat

  'Serial to PC (For Debugging)
  'Term.Start(31,30,0,115200)
  'Pause(1000)


PUB ActMC(ReadyFlagPtr, MovementFlagPtr, SpeedFlagPtr, StopPtr) 'Activate and initialise core for motor controls

  StopCore                                              'Prevent stacking drivers
  MotorCogID := cognew(StartMC(ReadyFlagPtr, MovementFlagPtr, SpeedFlagPtr, StopPtr), @MotorCogStack) + 1  'Start new cog with Start method

  return MotorCogID                                     'Return cogID for tracking


PUB StopCore 'Stop active cog
  if MotorCogID                                         'Check for active cog
    cogstop(MotorCogID~)                                'Stop the cog

  return MotorCogID


PUB StartMC(ReadyFlagPtr, MovementFlagPtr, SpeedFlagPtr, StopPtr) | localSpd, Options

  SerialDriver.AddPort(0, Def#R1S2, Def#R1S1, SerialDriver#PINNOTUSED, SerialDriver#PINNOTUSED, SerialDriver#DEFAULTTHRESHOLD, %000000, Def#SSBaud)
  SerialDriver.AddPort(1, Def#R2S2, Def#R2S1, SerialDriver#PINNOTUSED, SerialDriver#PINNOTUSED, SerialDriver#DEFAULTTHRESHOLD, %000000, Def#SSBaud)
  SerialDriver.Start
  Pause(500)

{
  TestMotors(20, 2000)                                 'Remove these lines if testing of motors is no longer needed
  'BYTE[MovementFlagPtr] := 1
  'BYTE[SpeedFlagPtr] := 20
}

  repeat                                                'Movement Control based on Movement and Speed via MovementFlagPtr and SpeedFlagPtr
    'repeat while BYTE[ReadyFlagPtr] == 0               'Ensure XBee is up by checking Ready is on via ReadyFlagPtr before allowing movement
    if BYTE[StopPtr] == FALSE
      Speed := BYTE[SpeedFlagPtr]

      case BYTE[MovementFlagPtr]                          'Execute movement based on Movement flag
          0:
            StopAllMotors
          1:
            Forward(Speed)
          2:
            Reverse(Speed)
          9:
            Left(Speed)
          10:
            Right(Speed)
          5:
            DiagonalFowardLeft(Speed)
          6:
            DiagonalForwardRight(Speed)
          7:
            DiagonalBackwardLeft(Speed)
          8:
            DiagonalBackWardRight(Speed)
          3:
            StrafeLeft(Speed)
          4:
            StrafeRight(Speed)
    elseif BYTE[StopPtr] == TRUE
      StopAllMotors

  return


PUB TestMotors (testspeed, time)

  StopAllMotors
  Pause(time)

  Forward(testspeed)
  Pause(time)
  StopAllMotors
  Pause(1000)
  Reverse(testspeed)
  Pause(time)
  StopAllMotors
  Pause(1000)

  return


PUB StopAllMotors | R1S1Spd, R1S2Spd, R2S1Spd, R2S2Spd

  R1S1Spd := motS1Stop  'Stop front left wheel
  R1S2Spd := motS2Stop  'Stop front right wheel
  R2S1Spd := motS1Stop  'Stop left wheel
  R2S2Spd := motS2Stop  'Stop rear right wheel

  SerialDriver.Tx(0, R1S1Spd)  ' Control front left wheel
  SerialDriver.Tx(0, R1S2Spd)  ' Control front right wheel
  SerialDriver.Tx(1, R2S1Spd)  ' Control rear left wheel
  SerialDriver.Tx(1, R2S2Spd)  ' Control rear right wheel

  return


PUB Forward(throttle) | R1S1Spd, R1S2Spd, R2S1Spd, R2S2Spd

  throttle := throttle <#= throtMax
  throttle := throttle #>= throtMin
  R1S1Spd := motS1Stop + (throttle * motS1FwdRange)/throtMax  'Forward front left wheel
  R1S2Spd := motS2Stop + (throttle * motS2FwdRange)/throtMax  'Forward front right wheel
  R2S1Spd := motS1Stop + (throttle * motS1FwdRange)/throtMax  'Forward rear left wheel
  R2S2Spd := motS2Stop + (throttle * motS2FwdRange)/throtMax  'Forward rear right wheel

  SerialDriver.Tx(0, R1S1Spd)  ' Control front left wheel
  SerialDriver.Tx(0, R1S2Spd)  ' Control front right wheel
  SerialDriver.Tx(1, R2S1Spd)  ' Control rear left wheel
  SerialDriver.Tx(1, R2S2Spd)  ' Control rear right wheel

  return


PUB Reverse(throttle) | R1S1Spd, R1S2Spd, R2S1Spd, R2S2Spd

  throttle := throttle <#= throtMax
  throttle := throttle #>= throtMin
  R1S1Spd := motS1Stop - (throttle * motS1RevRange)/throtMax  'Reverse front left wheel
  R1S2Spd := motS2Stop - (throttle * motS2RevRange)/throtMax  'Reverse front right wheel
  R2S1Spd := motS1Stop - (throttle * motS1RevRange)/throtMax  'Reverse rear left wheel
  R2S2Spd := motS2Stop - (throttle * motS2RevRange)/throtMax  'Reverse rear right wheel

  SerialDriver.Tx(0, R1S1Spd)  ' Control front left wheel
  SerialDriver.Tx(0, R1S2Spd)  ' Control front right wheel
  SerialDriver.Tx(1, R2S1Spd)  ' Control rear left wheel
  SerialDriver.Tx(1, R2S2Spd)  ' Control rear right wheel

  return


PUB Left(throttle) | R1S1Spd, R1S2Spd, R2S1Spd, R2S2Spd

  throttle := throttle <#= throtMax
  throttle := throttle #>= throtMin
  R1S1Spd := motS1Stop - (throttle * motS1RevRange)/throtMax  'Forward front left wheel
  R1S2Spd := motS2Stop + (throttle * motS2FwdRange)/throtMax  'Forward front right wheel
  R2S1Spd := motS1Stop - (throttle * motS1RevRange)/throtMax  'Forward rear left wheel
  R2S2Spd := motS2Stop + (throttle * motS2FwdRange)/throtMax  'Forward rear right wheel

  SerialDriver.Tx(0, R1S1Spd)  ' Control front left wheel
  SerialDriver.Tx(0, R1S2Spd)  ' Control front right wheel
  SerialDriver.Tx(1, R2S1Spd)  ' Control rear left wheel
  SerialDriver.Tx(1, R2S2Spd)  ' Control rear right wheel

  return

PUB Right(throttle) | R1S1Spd, R1S2Spd, R2S1Spd, R2S2Spd

  throttle := throttle <#= throtMax
  throttle := throttle #>= throtMin
  R1S1Spd := motS1Stop + (throttle * motS1FwdRange)/throtMax  'Forward front left wheel
  R1S2Spd := motS2Stop - (throttle * motS2RevRange)/throtMax  'Forward front right wheel
  R2S1Spd := motS1Stop + (throttle * motS1FwdRange)/throtMax  'Forward rear left wheel
  R2S2Spd := motS2Stop - (throttle * motS2RevRange)/throtMax  'Forward rear right wheel

  SerialDriver.Tx(0, R1S1Spd)  ' Control front left wheel
  SerialDriver.Tx(0, R1S2Spd)  ' Control front right wheel
  SerialDriver.Tx(1, R2S1Spd)  ' Control rear left wheel
  SerialDriver.Tx(1, R2S2Spd)  ' Control rear right wheel

  return

PUB DiagonalFowardLeft(throttle) | R1S1Spd, R1S2Spd, R2S1Spd, R2S2Spd

  throttle := throttle <#= throtMax
  throttle := throttle #>= throtMin
  R1S1Spd := motS1Stop   'Stop front left wheel
  R1S2Spd := motS2Stop + (throttle * motS2FwdRange)/throtMax 'Forward front right wheel
  R2S1Spd := motS1Stop + (throttle * motS1FwdRange)/throtMax 'Forward rear left wheel
  R2S2Spd := motS2Stop   'Stop rear right wheel

  SerialDriver.Tx(0, R1S1Spd)  ' Control front left wheel
  SerialDriver.Tx(0, R1S2Spd)  ' Control front right wheel
  SerialDriver.Tx(1, R2S1Spd)  ' Control rear left wheel
  SerialDriver.Tx(1, R2S2Spd)  ' Control rear right wheel

  return

PUB DiagonalBackWardLeft(throttle) | R1S1Spd, R1S2Spd, R2S1Spd, R2S2Spd

  throttle := throttle <#= throtMax
  throttle := throttle #>= throtMin
  R1S1Spd := motS1Stop - (throttle * motS1RevRange)/throtMax  'Reverse front left wheel
  R1S2Spd := motS2Stop   'Stop front right wheel
  R2S1Spd := motS1Stop   'Stop rear left wheel
  R2S2Spd := motS2Stop - (throttle * motS2RevRange)/throtMax  'Reverse rear right wheel

  SerialDriver.Tx(0, R1S1Spd)  ' Control front left wheel
  SerialDriver.Tx(0, R1S2Spd)  ' Control front right wheel
  SerialDriver.Tx(1, R2S1Spd)  ' Control rear left wheel
  SerialDriver.Tx(1, R2S2Spd)  ' Control rear right wheel

  return

PUB DiagonalForwardRight(throttle) | R1S1Spd, R1S2Spd, R2S1Spd, R2S2Spd

  throttle := throttle <#= throtMax
  throttle := throttle #>= throtMin
  R1S1Spd := motS1Stop + (throttle * motS1FwdRange)/throtMax 'Forward front left wheel
  R1S2Spd := motS2Stop   'Stop front right wheel
  R2S1Spd := motS1Stop   'Stop rear left wheel
  R2S2Spd := motS2Stop + (throttle * motS2FwdRange)/throtMax 'Forward rear right wheel

  SerialDriver.Tx(0, R1S1Spd)  ' Control front left wheel
  SerialDriver.Tx(0, R1S2Spd)  ' Control front right wheel
  SerialDriver.Tx(1, R2S1Spd)  ' Control rear left wheel
  SerialDriver.Tx(1, R2S2Spd)  ' Control rear right wheel

  return

PUB DiagonalBackwardRight(throttle) | R1S1Spd, R1S2Spd, R2S1Spd, R2S2Spd

  throttle := throttle <#= throtMax
  throttle := throttle #>= throtMin
  R1S1Spd := motS1Stop   'Stop front left wheel
  R1S2Spd := motS2Stop - (throttle * motS2RevRange)/throtMax  'Reverse front right wheel
  R2S1Spd := motS1Stop - (throttle * motS1RevRange)/throtMax  'Reverse rear left wheel
  R2S2Spd := motS2Stop   'Stop rear right wheel

  SerialDriver.Tx(0, R1S1Spd)  ' Control front left wheel
  SerialDriver.Tx(0, R1S2Spd)  ' Control front right wheel
  SerialDriver.Tx(1, R2S1Spd)  ' Control rear left wheel
  SerialDriver.Tx(1, R2S2Spd)  ' Control rear right wheel

  return

PUB StrafeLeft(throttle) | R1S1Spd, R1S2Spd, R2S1Spd, R2S2Spd

  throttle := throttle <#= throtMax
  throttle := throttle #>= throtMin
  R1S1Spd := motS1Stop - (throttle * motS1RevRange)/throtMax  'Forward front left wheel
  R1S2Spd := motS2Stop + (throttle * motS2FwdRange)/throtMax  'Forward front right wheel
  R2S1Spd := motS1Stop + (throttle * motS1FwdRange)/throtMax  'Forward rear left wheel
  R2S2Spd := motS2Stop - (throttle * motS2RevRange)/throtMax  'Forward rear right wheel

  SerialDriver.Tx(0, R1S1Spd)  ' Control front left wheel
  SerialDriver.Tx(0, R1S2Spd)  ' Control front right wheel
  SerialDriver.Tx(1, R2S1Spd)  ' Control rear left wheel
  SerialDriver.Tx(1, R2S2Spd)  ' Control rear right wheel

  return

PUB StrafeRight(throttle) | R1S1Spd, R1S2Spd, R2S1Spd, R2S2Spd

  throttle := throttle <#= throtMax
  throttle := throttle #>= throtMin
  R1S1Spd := motS1Stop + (throttle * motS1FwdRange)/throtMax  'Forward front left wheel
  R1S2Spd := motS2Stop - (throttle * motS2RevRange)/throtMax  'Forward front right wheel
  R2S1Spd := motS1Stop - (throttle * motS1RevRange)/throtMax  'Forward rear left wheel
  R2S2Spd := motS2Stop + (throttle * motS2FwdRange)/throtMax  'Forward rear right wheel

  SerialDriver.Tx(0, R1S1Spd)  ' Control front left wheel
  SerialDriver.Tx(0, R1S2Spd)  ' Control front right wheel
  SerialDriver.Tx(1, R2S1Spd)  ' Control rear left wheel
  SerialDriver.Tx(1, R2S2Spd)  ' Control rear right wheel

  return


PRI Pause(ms) | t
  t := cnt - 1088
  repeat (ms #> 0)
    waitcnt(t += _Ms_001)

  return