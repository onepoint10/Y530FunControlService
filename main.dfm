object FanControlService: TFanControlService
  OldCreateOrder = False
  DisplayName = 'Fan fix control Lenovo Y530'
  OnContinue = ServiceContinue
  OnPause = ServicePause
  OnShutdown = ServiceShutdown
  OnStart = ServiceStart
  OnStop = ServiceStop
  Height = 112
  Width = 235
  object Timer1: TTimer
    Enabled = False
    Interval = 700
    OnTimer = Timer1Timer
    Left = 120
    Top = 24
  end
end
