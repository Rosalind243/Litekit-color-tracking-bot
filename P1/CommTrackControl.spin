{
  Project:      Mobile Platform - Build 1 (Tracking Command Control)
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

  'Definition - Movement Commands (ensure it matches all same definitions in the other related code modules
  movCmdStart          = $7A  'Package Start/Identifier
  movCmdEnd            = $55  'Package End
  movCmdStopAll        = $00  'Stop all motors
  movCmdForward        = $01  'Forward
  movCmdReverse        = $02  'Reverse
  movCmdLeft           = $03
  movCmdRight          = $04
  movCmdDiagonalForwardLeft = $05
  movCmdDiagonalBackwardLeft = $07
  movCmdDiagonalForwardRight = $06
  movCmdDiagonalBackwardRight = $08
  movCmdStrafeLeft = $09
  movCmdStrafeRight = $0A



  'STM32 Communication
  UARTMode  = 0     'Communication to STM32 Mode set at 0
  UARTBaud  = 9600  'Communication to STM32 Baud set at 9600
  UARTTxPin = 22    'Communication to STM32 USART1_Rx - PA10
  UARTRxPin = 24    'Communication to STM32 USART1_Tx - PA9


OBJ
  Def   : "RxBoardDef.spin"
  Comm  : "FullDuplexSerialExt.spin"
  Mot   : "MecanumControl.spin"

VAR
  LONG CommCogID, CommCogStack[64]


PUB ActCT(ReadyFlagPtr, commMov, commSpd)

  StopCore
  CommCogID := cognew(StartCT(ReadyFlagPtr, commMov, commSpd), @CommCogStack) + 1
  return CommCogID


PUB StopCore 'Stop active cog
  if CommCogID                                         'Check for active cog
    cogstop(CommCogID~)                                'Stop the cog

  return CommCogID


PUB StartCT(ReadyFlagPtr, commMov, commSpd) | B1Start, B2Mov, B3Spd, B4CSum, B5End, checksum, commErrCnt

  'TxPin, RxPin, 0, CommBaud
  Comm.Start(UARTRxPin, UARTTxPin, UARTMode, UARTBaud)
  Pause(1000)

  commErrCnt := 0  'Initialise command communication error count
  repeat  'Loop indefinitely for Movement Command from STM32

    repeat while Comm.Rx <> movCmdStart 'Loop to search for Movement Command Start byte to align and start movement control
    B1Start := movCmdStart  'Byte 1 - Start byte
    B2Mov   := Comm.Rx      'Byte 2 - Movement byte
    B3Spd   := Comm.Rx      'Byte 3 - Speed byte
    B4CSum  := Comm.Rx      'Byte 4 - Checksum byte = XOR of Ubyte[0] to Ubyte[2] and Ubyte[4]
    B5End   := Comm.Rx      'Byte 5 - End byte

    if (B1Start == movCmdStart) and (B5End == movCmdEnd)

      'Compute checksum and check validity of package received
      checkSum := 0        'Initialise the value of the checkSum to be zero first
      checkSum ^= B1Start  'XOR B1Start, B2Mov, M3Spd, and B5End
      checkSum ^= B2Mov
      checkSum ^= B3Spd
      checkSum ^= B5End

      if checkSum == B4CSum 'if the value of the checkSum and the value of the checkSum received from the data packet matches AND if the value of B1 is equals to $7A, start control

        commErrCnt := 0  'Reset command communication error count

        BYTE[commSpd] := B3Spd  'Update global speed flag

        case B2Mov  'Check the movement command byte and set the global movement flag

          movCmdStopAll:
            BYTE[commMov] := movCmdStopAll              'All stop command

          movCmdForward :
            BYTE[commMov] := movCmdForward              'Forward command

          movCmdReverse:
            BYTE[commMov] := movCmdReverse              'Reverse command

          movCmdLeft:
           BYTE[commMov] := movCmdLeft                  'Strafe Left command

          movCmdRight:
           BYTE[commMov] := movCmdRight                 'Strafe Right command

          movCmdDiagonalForwardLeft:
           BYTE[commMov] := movCmdDiagonalForwardLeft   'Diagonal Forward Left command

          movCmdDiagonalForwardRight:
           BYTE[commMov] := movCmdDiagonalForwardRight  'Diagonal Forward Right command

          movCmdDiagonalBackwardLeft:
           BYTE[commMov] := movCmdDiagonalBackwardLeft  'Diagonal Reverse Left command

          movCmdDiagonalBackwardRight:
           BYTE[commMov] := movCmdDiagonalBackwardRight 'Diagonal Reverse Right command

      else
        commErrCnt += 1  'Record one communication incidence
        if commErrCnt > 10  'Check if there is persistent communication fault, stop all movement if yes
          BYTE[commMov] := movCmdStopAll  'Stop all movements
          BYTE[commSpd] := 0
          commErrCnt   := 0  'Reset command communication error count


PRI Pause(ms) | t
  t := cnt - 1088                                               ' sync with system counter
  repeat (ms #> 0)                                              ' delay must be > 0
    waitcnt(t += _Ms_001)
  return