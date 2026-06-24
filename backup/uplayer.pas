unit uPlayer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TPlayer = class
  private
    FPosX, FPosY, FPosZ: Double;
    FVelocityY: Double;
    FSpeedX, FSpeedZ: Double;
    FOnGround: Boolean;
    FGravity: Double;
    FJumpSpeed: Double;
    FMoveSpeed: Double;
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
  FGravity := 600.0;
  FJumpSpeed := 350.0;
  FMoveSpeed := 150.0;
end;

procedure TPlayer.Update(dt: Double; const MoveX, MoveZ: Double; Jump: Boolean);
var
  newY: Double;
begin
  // Горизонтальное движение
  FSpeedX := MoveX * FMoveSpeed;
  FSpeedZ := MoveZ * FMoveSpeed;
  FPosX := FPosX + FSpeedX * dt;
  FPosZ := FPosZ + FSpeedZ * dt;

  // Вертикаль
  if Jump and FOnGround then
  begin
    FVelocityY := FJumpSpeed;
    FOnGround := False;
  end;

  FVelocityY := FVelocityY - FGravity * dt;
  newY := FPosY + FVelocityY * dt;
  if newY < 0 then
  begin
    newY := 0;
    FVelocityY := 0;
    FOnGround := True;
  end;
  FPosY := newY;

  // Ограничение мира
  if FPosX < -WORLD_SIZE/2 then FPosX := -WORLD_SIZE/2;
  if FPosX > WORLD_SIZE/2 then FPosX := WORLD_SIZE/2;
  if FPosZ < -WORLD_SIZE/2 then FPosZ := -WORLD_SIZE/2;
  if FPosZ > WORLD_SIZE/2 then FPosZ := WORLD_SIZE/2;
end;

procedure TPlayer.SetPosition(X, Y, Z: Double);
begin
  FPosX := X; FPosY := Y; FPosZ := Z;
end;

end.
