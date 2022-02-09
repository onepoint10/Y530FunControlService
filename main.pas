unit main;
{$WARN SYMBOL_PLATFORM OFF}

interface

uses System.Classes, Vcl.ExtCtrls, Vcl.SvcMgr, System.UITypes, System.SysUtils,
  GetCoreTempInfoDelphi,
  System.Types, Winapi.Windows, System.IniFiles, ShellApi, DateUtils,
  Vcl.StdCtrls;

type

  TFanControlService = class(TService)
    Timer1: TTimer;
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    procedure ServicePause(Sender: TService; var Paused: Boolean);
    procedure ServiceContinue(Sender: TService; var Continued: Boolean);
    procedure Timer1Timer(Sender: TObject);
    procedure ServiceShutdown(Sender: TService);

  private
    { Private declarations }

  public
    function GetServiceController: TServiceController; override;
    procedure Logging(LogMessage: string);
    procedure InitPathExe;
    procedure SetAuto;
    procedure SetStopped;
    procedure SetColded;
    { Public declarations }
  end;

  tstate = (esauto, esstop, escolded);

var
  FanControlService: TFanControlService;
  stopResult, WhriteLogEnable: Boolean;
  LogFile: TextFile; // файл лога
  Log_way: string; // путь к файлу лога
  FPathExe: string;
  heattemp, coldtemp, deltatemp, delaytime, timerinterval, StartSleepTime: integer;
  Data: CORE_TEMP_SHARED_DATA;
  CPU, Core, Index: Cardinal;
  Degree: Char;
  Temp: Single;
  state: tstate;
  coldtime: Extended;
  count, countmax: Integer;

implementation

{$R *.dfm}

function StringToOem(const Str: string): AnsiString;
begin
  Result := AnsiString(Str);
  if Length(Result) > 0 then
    CharToOemA(PAnsiChar(Result), PAnsiChar(Result));
end;

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  FanControlService.Controller(CtrlCode);
end;

function TFanControlService.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TFanControlService.Logging(LogMessage: string);
begin
  if WhriteLogEnable then
  begin
    try
      WriteLn(LogFile, LogMessage);
    except

    end;
  end;
end;

procedure TFanControlService.InitPathExe;
var
  Buffer: array [0 .. MAX_PATH] of Char;
begin
  FillChar(Buffer, sizeof(Buffer), #0);
  GetModuleFileName(HInstance, Buffer, MAX_PATH);
  FPathExe := string(Buffer);
  FPathExe := StringReplace(FPathExe, 'Y530FunControlService.exe', '',
    [rfReplaceAll]);
end;

procedure TFanControlService.ServiceContinue(Sender: TService;
  var Continued: Boolean);
begin
  Logging(DateTimetoStr(Now) + ': ServiceContinue.');
  Timer1.Enabled := true;
end;

procedure TFanControlService.ServicePause(Sender: TService;
  var Paused: Boolean);
begin
  Logging(DateTimetoStr(Now) + ': ServicePause.');
  Timer1.Enabled := false;
  Logging(DateTimetoStr(Now) + ': Опрос измерительных модулей прерван.');
end;

procedure TFanControlService.ServiceShutdown(Sender: TService);
begin
  ShellExecute(HInstance, 'open',
      PChar('C:\Program Files (x86)\NoteBook FanControl\Fan_auto.bat'), nil,
      nil, SW_SHOWNORMAL);
  Logging(DateTimetoStr(Now) + ' :temp = ' + Temp.ToString + ' ; exit state auto');
  Timer1.Enabled := false;
  Logging(DateTimetoStr(Now) + ': service stopped because the system is shutdown');
  CloseFile(LogFile); // сохраняем лог-фаил
end;

procedure TFanControlService.ServiceStart(Sender: TService;
  var Started: Boolean);
var
  i, priority: integer;
  Year, Month, Day: Word;
  Ini: Tinifile;
  MetrologyLoadResult: integer;
begin
  InitPathExe;
  FormatSettings.DecimalSeparator := '.';
  FormatSettings.DateSeparator := '.';
  DecodeDate(Date, Year, Month, Day);
  if not DirectoryExists(FPathExe + 'logs') then
    CreateDir(FPathExe + 'logs');
  Log_way := FPathExe + 'logs\Log_file_Service_' +
    DateToStr(Date, FormatSettings) + '.txt';

  AssignFile(LogFile, Log_way, CP_UTF8);
  if not FileExists(Log_way) then
    Rewrite(LogFile)
  else
    Append(LogFile);

  Ini := Tinifile.create(FPathExe + 'settings.ini');
  // settings loading
  WhriteLogEnable := Ini.ReadBool('Main', 'WhriteLog', true);
  Logging('-----------------------New Start---------------------');
  Logging(DateTimetoStr(Now) + ':  Log created. Logway: ' + Log_way);

  heattemp := strtoint(Ini.ReadString('Special', 'heattemp', '75'));
  coldtemp := strtoint(Ini.ReadString('Special', 'coldtemp', '45'));
  deltatemp := strtoint(Ini.ReadString('Special', 'deltatemp', '0'));
  delaytime := strtoint(Ini.ReadString('Special', 'delaytime', '5000'));
  timerinterval := strtoint(Ini.ReadString('Special', 'timerinterval', '500'));
  countmax := strtoint(Ini.ReadString('Special', 'countmax', '180'));
  StartSleepTime := strtoint(Ini.ReadString('Special',
    'StartSleepTime', '5000'));
  Index := strtoint(Ini.ReadString('Special', 'core', '0'));;

  if FileExists('C:\Program Files\Core Temp\Core Temp.exe') then
  begin
    ShellExecute(HInstance, 'open',
      PChar('C:\Program Files\Core Temp\Core Temp.exe'), nil, nil,
      SW_SHOWNORMAL);
  end
  else
  begin
    Logging(DateTimetoStr(Now) +
      ' : File "C:\Program Files\Core Temp\Core Temp.exe" not found');
    ServiceStop(self, stopResult);
  end;

  Sleep(StartSleepTime);
  Logging(DateTimetoStr(Now) + ': service started');

  if Ini.ReadBool('Main', 'StartState', true) then
    SetAuto
  else
    SetStopped;
  Ini.Free;

  Timer1.Interval:= timerinterval;

  try
    if fnGetCoreTempInfo(Data) then
    begin
      Logging(DateTimetoStr(Now) + ' Processor  : ' + Data.sCPUName);
      Logging(DateTimetoStr(Now) + ' Core(s)    : ' + IntToStr(Data.uiCoreCnt));
      Logging(DateTimetoStr(Now) + ' CPU(s)     : ' + IntToStr(Data.uiCPUCnt));
      Logging(DateTimetoStr(Now) + ' CPU speed  : ' +
        FloatToStrF(Data.fCPUSpeed, ffFixed, 7, 0) + ' MHz');
      Timer1.Enabled := true;
      Logging(DateTimetoStr(Now) + ': control started');
    end
    else
    begin
      Logging(DateTimetoStr(Now) +
        ' Error: Core Temp''s shared memory could not be read');
      Logging(DateTimetoStr(Now) + ' Reason: ' +
        StringToOem(SysErrorMessage(GetLastError)));
      ServiceStop(self, stopResult);
    end;
  except
    on E: Exception do
    begin
      Logging(DateTimetoStr(Now) + E.Classname + ': ' + E.Message);
      ServiceStop(self, stopResult);
    end;
  end;
end;

procedure TFanControlService.ServiceStop(Sender: TService;
  var Stopped: Boolean);
begin
  ShellExecute(HInstance, 'open',
      PChar('C:\Program Files (x86)\NoteBook FanControl\Fan_auto.bat'), nil,
      nil, SW_SHOWNORMAL);
  Logging(DateTimetoStr(Now) + ' :temp = ' + Temp.ToString + ' ; exit state auto');
  Timer1.Enabled := false;
  Logging(DateTimetoStr(Now) + ': service stopped');
  CloseFile(LogFile); // сохраняем лог-фаил
end;

procedure TFanControlService.SetAuto;
begin
  if FileExists('C:\Program Files (x86)\NoteBook FanControl\Fan_auto.bat') then
  begin
    ShellExecute(HInstance, 'open',
      PChar('C:\Program Files (x86)\NoteBook FanControl\Fan_auto.bat'), nil,
      nil, SW_SHOWNORMAL);
    state := esauto;
    Logging(DateTimetoStr(Now) + ' :temp = ' + Temp.ToString + ' ; state auto');
  end
  else
  begin
    Logging(DateTimetoStr(Now) +
      ' : File "C:\Program Files (x86)\NoteBook FanControl\Fan_auto.bat" not found');
    self.ServiceStop(self, stopResult);
  end;
end;

procedure TFanControlService.SetColded;
begin
  coldtime := Now;
  state := escolded;
  Logging(DateTimetoStr(Now) + ' :temp = ' + Temp.ToString + ' ; state colded');
end;

procedure TFanControlService.SetStopped;
begin
  if FileExists('C:\Program Files (x86)\NoteBook FanControl\Fan_stop.bat') then
  begin
    ShellExecute(HInstance, 'open',
      PChar('C:\Program Files (x86)\NoteBook FanControl\Fan_stop.bat'), nil,
      nil, SW_SHOWNORMAL);
    state := esstop;
    Logging(DateTimetoStr(Now) + ' :temp = ' + Temp.ToString +
      ' ; state stopped');
  end
  else
  begin
    Logging(DateTimetoStr(Now) +
      ' : File "C:\Program Files (x86)\NoteBook FanControl\Fan_stop.bat" not found');
    self.ServiceStop(self, stopResult);
  end;
end;

procedure TFanControlService.Timer1Timer(Sender: TObject);
begin
  try
    if fnGetCoreTempInfo(Data) then
    begin
      if Data.ucDeltaToTjMax then
        Temp := Data.uiTjMax[CPU] - Data.fTemp[Index]
      else
        Temp := Data.fTemp[Index];
      case state of
        esstop:
        begin
          if (Temp > heattemp) then SetAuto;
          if (Temp < coldtemp) then inc(count);
          if count > countmax then
          begin
          SetAuto;
          Logging(DateTimetoStr(Now) + 'state set auto cause countmax is overflow');
          end;
        end;
        esauto:
          if Temp < coldtemp then
            SetColded;
        escolded:
          begin
            if Temp <= (coldtemp + deltatemp) then
            begin
              if MilliSecondsBetween(Now, coldtime) > delaytime then
                SetStopped;
                count:=0;
            end
            else
            begin
              state := esauto;
              Logging(DateTimetoStr(Now) + ' :temp = ' + Temp.ToString +
                ' ; state set auto cause not colded');
            end;
          end;
      end;
    end
    else
    begin
      Logging(DateTimetoStr(Now) +
        ' Error: Core Temp''s shared memory could not be read');
      Logging(DateTimetoStr(Now) + ' Reason: ' +
        StringToOem(SysErrorMessage(GetLastError)));
      self.ServiceStop(self, stopResult);
    end;
  except
    on E: Exception do
    begin
      Logging(DateTimetoStr(Now) + E.Classname + ': ' + E.Message);
      self.ServiceStop(self, stopResult);
    end;
  end;
end;

end.
