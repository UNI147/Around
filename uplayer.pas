unit uPlayer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, uConfig, uWorld;

const
  EPSILON = 0.001; // Защита от застревания в текстурах

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
  FPosX := 0; FPosY := 40; FPosZ := 0;
  FVelocityY := 0; FSpeedX := 0; FSpeedZ := 0;
  FOnGround := False;
end;

function TPlayer.CollidesAt(X, Y, Z: Double): Boolean;
var
  minX, maxX, minY, maxY, minZ, maxZ: Integer;
  bx, by, bz: Integer;
begin
  // Хитбокс с учетом EPSILON для корректного определения опоры под ногами
  minX := Floor(X - 0.3 + EPSILON); maxX := Floor(X + 0.3 - EPSILON);
  minY := Floor(Y + EPSILON);       maxY := Floor(Y + 1.8 - EPSILON);
  minZ := Floor(Z - 0.3 + EPSILON); maxZ := Floor(Z + 0.3 - EPSILON);

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
  TargetSpeedX, TargetSpeedZ: Double;
  by: Integer;
begin
  // 1. Плавное ускорение и трение (инерция)
  TargetSpeedX := MoveX * Config.MoveSpeed;
  TargetSpeedZ := MoveZ * Config.MoveSpeed;

  if MoveX <> 0 then
    FSpeedX := FSpeedX + (TargetSpeedX - FSpeedX) * Min(1.0, Config.MoveAccel * dt / Max(Config.MoveSpeed, 0.1))
  else
    FSpeedX := FSpeedX * Exp(-Config.MoveFriction * dt);

  if MoveZ <> 0 then
    FSpeedZ := FSpeedZ + (TargetSpeedZ - FSpeedZ) * Min(1.0, Config.MoveAccel * dt / Max(Config.MoveSpeed, 0.1))
  else
    FSpeedZ := FSpeedZ * Exp(-Config.MoveFriction * dt);

  if Abs(FSpeedX) < 0.1 then FSpeedX := 0;
  if Abs(FSpeedZ) < 0.1 then FSpeedZ := 0;

  // 2. Движение по X с авто-шагом (Step-Up)
  newX := FPosX + FSpeedX * dt;
  if CollidesAt(newX, FPosY, FPosZ) then
  begin
    // Если на уровне головы свободно, а на уровне ног препятствие - зашагиваем
    if (not CollidesAt(newX, FPosY + 1.0, FPosZ)) and CollidesAt(newX, FPosY + 0.1, FPosZ) then
    begin
      FPosY := FPosY + 1.0;
      FVelocityY := 0;
      FOnGround := True;
      if not CollidesAt(newX, FPosY, FPosZ) then FPosX := newX;
    end;
  end
  else FPosX := newX;

  // 3. Движение по Z с авто-шагом
  newZ := FPosZ + FSpeedZ * dt;
  if CollidesAt(FPosX, FPosY, newZ) then
  begin
    if (not CollidesAt(FPosX, FPosY + 1.0, newZ)) and CollidesAt(FPosX, FPosY + 0.1, newZ) then
    begin
      FPosY := FPosY + 1.0;
      FVelocityY := 0;
      FOnGround := True;
      if not CollidesAt(FPosX, FPosY, newZ) then FPosZ := newZ;
    end;
  end
  else FPosZ := newZ;

  // 4. Гравитация и Прыжок
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
    if FVelocityY < 0 then // Приземление
    begin
      FOnGround := True;
      // Выравнивание по земле: ищем твердый блок и ставим ноги ровно на его верхнюю грань
      for by := Floor(FPosY) downto Floor(newY) do
      begin
        if FWorld.IsBlockSolid(Floor(FPosX), by, Floor(FPosZ)) then
        begin
          FPosY := by + 1.0; // Точное касание земли!
          Break;
        end;
      end;
    end
    else // Удар головой
    begin
      for by := Ceil(FPosY + 1.8) to Ceil(newY + 1.8) do
        if FWorld.IsBlockSolid(Floor(FPosX), by, Floor(FPosZ)) then
        begin
          FPosY := by - 1.8;
          Break;
        end;
    end;
    FVelocityY := 0;
  end;

  if FPosY < -10 then begin FPosY := 40; FVelocityY := 0; end;
end;

procedure TPlayer.SetPosition(X, Y, Z: Double);
begin
  FPosX := X; FPosY := Y; FPosZ := Z;
end;

end.
