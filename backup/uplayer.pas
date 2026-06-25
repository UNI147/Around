unit uPlayer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uConfig;

type
  TPlayer = class
  private
    FPosX, FPosY, FPosZ: Double;
    FVelocityY: Double;
    FSpeedX, FSpeedZ: Double;
    FOnGround: Boolean;
  public
    constructor Create;
    procedure Update(dt: Double; const MoveX, MoveZ: Double; Jump: Boolean);
    procedure SetPosition(X, Y, Z: Double);
    property PosX: Double read FPosX write FPosX;
    property PosY: Double read FPosY write FPosY;
    property PosZ: Double read FPosZ write FPosZ;
    property OnGround: Boolean read FOnGround;
  end;

implementation

constructor TPlayer.Create;
begin
  FPosX := 0; FPosY := 0; FPosZ := 0;
  FVelocityY := 0;
  FSpeedX := 0; FSpeedZ := 0;
  FOnGround := True;
end;

procedure TPlayer.Update(dt: Double; const MoveX, MoveZ: Double; Jump: Boolean);
var
  newY: Double;
begin
  // Используем параметры из конфига
  FSpeedX := MoveX * Config.MoveSpeed;
  FSpeedZ := MoveZ * Config.MoveSpeed;
  FPosX := FPosX + FSpeedX * dt;
  FPosZ := FPosZ + FSpeedZ * dt;

  if Jump and FOnGround then
  begin
    FVelocityY := Config.JumpSpeed;
    FOnGround := False;
  end;

  FVelocityY := FVelocityY - Config.Gravity * dt;
  newY := FPosY + FVelocityY * dt;
  if newY < 0 then
  begin
    newY := 0;
    FVelocityY := 0;
    FOnGround := True;
  end;
  FPosY := newY;

  // Границы мира
  if FPosX < -Config.WorldSize/2 then FPosX := -Config.WorldSize/2;
  if FPosX > Config.WorldSize/2 then FPosX := Config.WorldSize/2;
  if FPosZ < -Config.WorldSize/2 then FPosZ := -Config.WorldSize/2;
  if FPosZ > Config.WorldSize/2 then FPosZ := Config.WorldSize/2;
end;

procedure TPlayer.SetPosition(X, Y, Z: Double);
begin
  FPosX := X; FPosY := Y; FPosZ := Z;
end;

end.
