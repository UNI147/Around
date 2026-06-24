unit uPlayer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uResources;

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
  // Используем константы из uResources
  FSpeedX := MoveX * PLAYER_MOVE_SPEED;
  FSpeedZ := MoveZ * PLAYER_MOVE_SPEED;
  FPosX := FPosX + FSpeedX * dt;
  FPosZ := FPosZ + FSpeedZ * dt;

  if Jump and FOnGround then
  begin
    FVelocityY := PLAYER_JUMP_SPEED;
    FOnGround := False;
  end;

  FVelocityY := FVelocityY - PLAYER_GRAVITY * dt;
  newY := FPosY + FVelocityY * dt;
  if newY < 0 then
  begin
    newY := 0;
    FVelocityY := 0;
    FOnGround := True;
  end;
  FPosY := newY;

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
