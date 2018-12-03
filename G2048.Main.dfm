object FormMain: TFormMain
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = #1048#1075#1088#1072' 2048'
  ClientHeight = 281
  ClientWidth = 281
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PrintScale = poNone
  Scaled = False
  ScreenSnap = True
  Visible = True
  OnCreate = FormCreate
  OnKeyUp = FormKeyUp
  PixelsPerInch = 96
  TextHeight = 13
  object TimerRedraw: TTimer
    Enabled = False
    Interval = 10
    OnTimer = TimerRedrawTimer
    Left = 152
    Top = 136
  end
end
