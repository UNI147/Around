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
  steps, i: Integer;
  stepDt, moveStep: Double;
begin
  FSpeedX := MoveX * Config.MoveSpeed;
  FSpeedZ := MoveZ * Config.MoveSpeed;

  // === Sub-stepping для плавного движения и корректных коллизий ===
  // Делим движение на подшаги, чтобы не проскакивать сквозь блоки
  steps := Max(1, Ceil(Abs(FSpeedX * dt) / 0.3)); // шаг не более 0.3 блока
  stepDt := dt / steps;

  for i := 1 to steps do
  begin
    // Ось X
    moveStep := FSpeedX * stepDt;
    newX := FPosX + moveStep;
    if not CollidesAt(newX, FPosY, FPosZ) then
      FPosX := newX
    else
      FSpeedX := 0; // упираемся в стену — сбрасываем скорость по X

    // Ось Z (независимо от X — это даёт скольжение вдоль углов)
    moveStep := FSpeedZ * stepDt;
    newZ := FPosZ + moveStep;
    if not CollidesAt(FPosX, FPosY, newZ) then
      FPosZ := newZ
    else
      FSpeedZ := 0;
  end;

  // === Ось Y: гравитация и прыжок (без sub-stepping — достаточно точно) ===
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
    // При ударе о землю/потолок обнуляем вертикальную скорость
    if FVelocityY < 0 then
    begin
      // Приземление — «прилипаем» к поверхности блока
      FPosY := Floor(FPosY) + 1.0; // ноги точно на верхней грани блока
      FOnGround := True;
    end;
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
