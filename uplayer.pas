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
    FVelocityY: Double;
    FSpeedX, FSpeedZ: Double;
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
  FPosX := 0; FPosY := 40; FPosZ := 0; // Стартуем повыше, чтобы упасть на землю
  FVelocityY := 0;
  FSpeedX := 0; FSpeedZ := 0;
  FOnGround := False;
end;

function TPlayer.CollidesAt(X, Y, Z: Double): Boolean;
var
  minX, maxX, minY, maxY, minZ, maxZ: Integer;
  bx, by, bz: Integer;
begin
  // Хитбокс игрока: ширина 0.6, высота 1.8
  minX := Floor(X - 0.3);
  maxX := Floor(X + 0.3);
  minY := Floor(Y);
  maxY := Floor(Y + 1.8);
  minZ := Floor(Z - 0.3);
  maxZ := Floor(Z + 0.3);

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
begin
  FSpeedX := MoveX * Config.MoveSpeed;
  FSpeedZ := MoveZ * Config.MoveSpeed;

  // Ось X
  newX := FPosX + FSpeedX * dt;
  if not CollidesAt(newX, FPosY, FPosZ) then FPosX := newX;

  // Ось Z
  newZ := FPosZ + FSpeedZ * dt;
  if not CollidesAt(FPosX, FPosY, newZ) then FPosZ := newZ;

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
    if FVelocityY < 0 then FOnGround := True; // Ударились головой или приземлились
    FVelocityY := 0;
  end;

  // Защита от падения в бездну
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
