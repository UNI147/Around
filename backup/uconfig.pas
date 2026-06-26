unit uConfig;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles;

type
  TConfig = class
  private
    FIni: TIniFile;
    function GetMoveSpeed: Double;
    function GetJumpForce: Double;
    function GetGravity: Double;
    function GetCloudCount: Integer;
    function GetCameraSmoothing: Double;
  public
    constructor Create(const FileName: string);
    destructor Destroy; override;

    property MoveSpeed: Double read GetMoveSpeed;
    property JumpForce: Double read GetJumpForce;
    property Gravity: Double read GetGravity;
    property CloudCount: Integer read GetCloudCount;
    property CameraSmoothing: Double read GetCameraSmoothing;
  end;

var
  Config: TConfig;

implementation

{ TConfig }

constructor TConfig.Create(const FileName: string);
begin
  inherited Create;
  FIni := TIniFile.Create(FileName);
end;

destructor TConfig.Destroy;
begin
  FIni.Free;
  inherited Destroy;
end;

function TConfig.GetMoveSpeed: Double;
begin
  Result := FIni.ReadFloat('Player', 'MoveSpeed', 5.0);
end;

function TConfig.GetJumpForce: Double;
begin
  Result := FIni.ReadFloat('Player', 'JumpForce', 8.0);
end;

function TConfig.GetGravity: Double;
begin
  Result := FIni.ReadFloat('Physics', 'Gravity', 20.0);
end;

function TConfig.GetCloudCount: Integer;
begin
  Result := FIni.ReadInteger('World', 'CloudCount', 40);
end;

function TConfig.GetCameraSmoothing: Double;
begin
  // Чем выше значение, тем быстрее камера догоняет игрока.
  // Значение 8.0 дает приятную кинематографичную инерцию.
  Result := FIni.ReadFloat('Camera', 'Smoothing', 8.0);
end;

end.
