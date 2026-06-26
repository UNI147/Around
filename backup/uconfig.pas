unit uConfig;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, LCLType;

type
  TConfig = class
  private
    FIni: TIniFile;
    FFileName: string;
    function GetViewWidth: Integer;
    function GetViewHeight: Integer;
    function GetFullScreen: Boolean;
    function GetFontFileName: string;
    function GetWorldSize: Double;
    function GetTerrainPoints: Integer;
    function GetCloudCount: Integer;
    function GetGravity: Double;
    function GetJumpSpeed: Double;
    function GetMoveSpeed: Double;
    function GetStartX: Double;
    function GetStartY: Double;
    function GetStartZ: Double;
    function GetTimerInterval: Integer;
    function GetDeltaTime: Double;
    function GetMoveAccel: Double;
    function GetMoveFriction: Double;
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;
    // Свойства только для чтения
    property ViewWidth: Integer read GetViewWidth;
    property ViewHeight: Integer read GetViewHeight;
    property FullScreen: Boolean read GetFullScreen;
    property FontFileName: string read GetFontFileName;
    property WorldSize: Double read GetWorldSize;
    property TerrainPoints: Integer read GetTerrainPoints;
    property CloudCount: Integer read GetCloudCount;
    property Gravity: Double read GetGravity;
    property JumpSpeed: Double read GetJumpSpeed;
    property MoveSpeed: Double read GetMoveSpeed;
    property StartX: Double read GetStartX;
    property StartY: Double read GetStartY;
    property StartZ: Double read GetStartZ;
    property TimerInterval: Integer read GetTimerInterval;
    property DeltaTime: Double read GetDeltaTime;
    property MoveAccel: Double read GetMoveAccel;
    property MoveFriction: Double read GetMoveFriction;
  end;

var
  Config: TConfig;

implementation

constructor TConfig.Create(const AFileName: string);
begin
  FFileName := AFileName;
  FIni := TIniFile.Create(FFileName);
end;

destructor TConfig.Destroy;
begin
  FIni.Free;
  inherited;
end;

function TConfig.GetViewWidth: Integer;
begin
  Result := FIni.ReadInteger('Display', 'ViewWidth', 320);
end;

function TConfig.GetViewHeight: Integer;
begin
  Result := FIni.ReadInteger('Display', 'ViewHeight', 200);
end;

function TConfig.GetFullScreen: Boolean;
begin
  Result := FIni.ReadBool('Display', 'FullScreen', True);
end;

function TConfig.GetFontFileName: string;
begin
  Result := FIni.ReadString('Display', 'FontFile', 'GothicRus.ttf');
end;

function TConfig.GetWorldSize: Double;
begin
  Result := FIni.ReadFloat('World', 'Size', 400.0);
end;

function TConfig.GetTerrainPoints: Integer;
begin
  Result := FIni.ReadInteger('World', 'TerrainPoints', 1500);
end;

function TConfig.GetCloudCount: Integer;
begin
  Result := FIni.ReadInteger('World', 'CloudCount', 30);
end;

function TConfig.GetGravity: Double;
begin
  Result := FIni.ReadFloat('Player', 'Gravity', 20.0);
end;

function TConfig.GetJumpSpeed: Double;
begin
  Result := FIni.ReadFloat('Player', 'JumpSpeed', 9.0);
end;

function TConfig.GetMoveSpeed: Double;
begin
  Result := FIni.ReadFloat('Player', 'MoveSpeed', 150.0);
end;

function TConfig.GetStartX: Double;
begin
  Result := FIni.ReadFloat('Player', 'StartX', 0.0);
end;

function TConfig.GetStartY: Double;
begin
  Result := FIni.ReadFloat('Player', 'StartY', 0.0);
end;

function TConfig.GetStartZ: Double;
begin
  Result := FIni.ReadFloat('Player', 'StartZ', 0.0);
end;

function TConfig.GetTimerInterval: Integer;
begin
  Result := FIni.ReadInteger('Timer', 'Interval', 30);
end;

function TConfig.GetDeltaTime: Double;
begin
  Result := TimerInterval / 1000.0;
end;

initialization
  Config := TConfig.Create(ExtractFilePath(ParamStr(0)) + 'config.ini');
finalization
  Config.Free;
end.
