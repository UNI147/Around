unit uPlayer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, uConfig, uWorld;

type
  TPlayer = class
  private
    FWorld: TWorld;
    FPosX, FPosY, FPosZ: Double;
    FVelocityX, FVelocityY, FVelocityZ: Double;
    FOnGround: Boolean;
    function CollidesAt(X, Y, Z: Double): Boolean;
  public
    constructor Create(AWorld: TWorld);
    procedure Update(dt: Double; const MoveX, MoveZ: Double; Jump: Boolean);
    procedure SetPosition(X, Y, Z: Double);
    property PosX: Double read FPosX write FPosX;
    property PosY: Double read FPosY write FPosY;
    property PosZ: Double read FPosZ write FPosZ;
    property OnGround: Boolean read FOnGround;
  end;

implementation

constructor TPlayer.Create(AWorld: TWorld);
begin
  FWorld := AWorld;
  FPosX := 0; FPosY := 40; FPosZ := 0;
  FVelocityX := 0; FVelocityY := 0; FVelocityZ := 0;
  FOnGround := False;
end;

function TPlayer.CollidesAt(X, Y, Z: Double): Boolean;
var
  minX, maxX, minY, maxY, minZ, maxZ: Integer;
  bx, by, bz: Integer;
begin
  minX := Floor(X - 0.3); maxX := Floor(X + 0.3);
  minY := Floor(Y); maxY := Floor(Y + 1.8);
  minZ := Floor(Z - 0.3); maxZ := Floor(Z + 0.3);

  for bx := minX to maxX do
    for by := minY to maxY do
      for bz := minZ to maxZ do
        if FWorld.IsBlockSolid(bx, by, bz) then
          Exit(True);
  Result := False;
end;

procedure TPlayer.Update(dt: Double; const MoveX, MoveZ: Double; Jump: Boolean);
var
  newX, newY, newZ: Double;
  targetSpeedX, targetSpeedZ: Double;
  accelX, accelZ: Double;
  frictionFactor: Double;
begin
  targetSpeedX := MoveX * Config.MoveSpeed;
  targetSpeedZ := MoveZ * Config.MoveSpeed;

  // Плавный разгон и трение по X
  if MoveX <> 0 then
  begin
    accelX := (targetSpeedX - FVelocityX) * Config.MoveAccel * dt / Config.MoveSpeed;
    FVelocityX := FVelocityX + accelX;
  end
  else
  begin
    frictionFactor := Exp(-Config.MoveFriction * dt);
    FVelocityX := FVelocityX * frictionFactor;
    if Abs(FVelocityX) < 0.1 then FVelocityX := 0;
  end;

  // Плавный разгон и трение по Z
  if MoveZ <> 0 then
  begin
    accelZ := (targetSpeedZ - FVelocityZ) * Config.MoveAccel * dt / Config.MoveSpeed;
    FVelocityZ := FVelocityZ + accelZ;
  end
  else
  begin
    frictionFactor := Exp(-Config.MoveFriction * dt);
    FVelocityZ := FVelocityZ * frictionFactor;
    if Abs(FVelocityZ) < 0.1 then FVelocityZ := 0;
  end;

  // Ось X
  newX := FPosX + FVelocityX * dt;
  if not CollidesAt(newX, FPosY, FPosZ) then FPosX := newX
  else FVelocityX := 0;

  // Ось Z
  newZ := FPosZ + FVelocityZ * dt;
  if not CollidesAt(FPosX, FPosY, newZ) then FPosZ := newZ
  else FVelocityZ := 0;

  // Ось Y (Гравитация и Прыжок)
  if Jump and FOnGround then
  begin
    FVelocityY := Config.JumpSpeed;
    FOnGround := False;
  end;

  FVelocityY := FVelocityY - Config.Gravity * dt;
  newY := FPosY + FVelocityY * dt;

  if not CollidesAt(FPosX, newY, FPosZ) then
  begin
    FPosY := newY;
    FOnGround := False;
  end
  else
  begin
    if FVelocityY < 0 then FOnGround := True;
    FVelocityY := 0;
  end;

  if FPosY < -10 then
  begin
    FPosY := 40;
    FVelocityY := 0;
  end;
end;

procedure TPlayer.SetPosition(X, Y, Z: Double);
begin
  FPosX := X; FPosY := Y; FPosZ := Z;
end;

end.
