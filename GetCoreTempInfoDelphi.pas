// Core Temp shared memory reader for Delphi
// Author: Michal Kokorceny
// Web:    http://74.cz
// E-mail: michal@74.cz
//
// Core Temp project home page:
// http://www.alcpu.com/CoreTemp

unit GetCoreTempInfoDelphi;

interface

{$IFDEF MSWINDOWS}

type
  CORE_TEMP_SHARED_DATA = packed record
    uiLoad: packed array [0 .. 255] of Cardinal;
    uiTjMax: packed array [0 .. 127] of Cardinal;
    uiCoreCnt: Cardinal;
    uiCPUCnt: Cardinal;
    fTemp: packed array [0 .. 255] of Single;
    fVID: Single;
    fCPUSpeed: Single;
    fFSBSpeed: Single;
    fMultipier: Single;
    sCPUName: packed array [0 .. 99] of AnsiChar;
    ucFahrenheit: ByteBool;
    ucDeltaToTjMax: ByteBool;
  end;

function fnGetCoreTempInfo(out Data: CORE_TEMP_SHARED_DATA): Boolean;

{$ENDIF}

implementation

{$IFDEF MSWINDOWS}

uses
  Windows;

const
  CoreTempSharedArea = 'CoreTempMappingObject';

function fnGetCoreTempInfo(out Data: CORE_TEMP_SHARED_DATA): Boolean;
var
  HCoreTempSharedArea: Cardinal;
  PCoreTempSharedArea: Pointer;
begin
  Result := False;
  HCoreTempSharedArea := OpenFileMapping(FILE_MAP_READ, True,
    CoreTempSharedArea);
  if HCoreTempSharedArea <> 0 then
    try
      PCoreTempSharedArea := MapViewOfFile(HCoreTempSharedArea, FILE_MAP_READ,
        0, 0, SizeOf(Data));
      if Assigned(PCoreTempSharedArea) then
        try
          FillChar(Data, SizeOf(Data), 0);
          Move(PCoreTempSharedArea^, Data, SizeOf(Data));
          Result := True;
        finally
          UnmapViewOfFile(PCoreTempSharedArea);
        end;
    finally
      CloseHandle(HCoreTempSharedArea);
    end;
end;

{$ENDIF}

end.
