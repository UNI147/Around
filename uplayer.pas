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
    FStepTargetY: Double;    // Целевая высота для шага
    FIsStepping: Boolean;    // Флаг процесса зашагивания
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
const
  EPS = 0.001;
  P_WIDTH = 0.3;
  P_HEIGHT = 1.8;
begin
  minX := Floor(X - P_WIDTH + EPS);
  maxX := Floor(X + P_WIDTH - EPS);
  minY := Floor(Y + EPS);         // Исключаем блок под ногами при идеальном касании
  maxY := Floor(Y + P_HEIGHT - EPS);
  minZ := Floor(Z - P_WIDTH + EPS);
  maxZ := Floor(Z + P_WIDTH - EPS);

  for bx := minX to maxX do
    for by := minY to maxY do
      for bz := minZ to maxZ do
        if FWorld.IsBlockSolid(bx, by, bz) then
          Exit(True);
  Result := False;
  FIsStepping := False;
  FStepTargetY := 0;
end;

procedure TPlayer.Update(dt: Double; const MoveX, MoveZ: Double; Jump: Boolean);
var
  newX, newY, newZ: Double;
  steps, i: Integer;
  stepDt, moveStep: Double;
  TargetSpeedX, TargetSpeedZ: Double;
const
  STEP_HEIGHT = 1.0; // Высота автоматического зашагивания
begin
  TargetSpeedX := MoveX * Config.MoveSpeed;
  TargetSpeedZ := MoveZ * Config.MoveSpeed;

  // Плавное физически корректное ускорение и торможение (инерция)
  if Abs(MoveX) > 0 then
    FSpeedX := TargetSpeedX + (FSpeedX - TargetSpeedX) * Exp(-dt * Config.MoveAccel)
  else
    FSpeedX := FSpeedX * Exp(-dt * Config.MoveFriction);

  if Abs(MoveZ) > 0 then
    FSpeedZ := TargetSpeedZ + (FSpeedZ - TargetSpeedZ) * Exp(-dt * Config.MoveAccel)
  else
    FSpeedZ := FSpeedZ * Exp(-dt * Config.MoveFriction);

  steps := Max(1, Ceil(Abs(FSpeedX * dt) / 0.3));
  stepDt := dt / steps;

  for i := 1 to steps do
  begin
    // Обработка X
    moveStep := FSpeedX * stepDt;
    newX := FPosX + moveStep;
    if not CollidesAt(newX, FPosY, FPosZ) then
      FPosX := newX
    else if FOnGround and (not FIsStepping) and (not CollidesAt(newX, FPosY + STEP_HEIGHT, FPosZ)) then
    begin
      // Пространство над препятствием свободно - начинаем зашагивать
      FIsStepping := True;
      FStepTargetY := FPosY + STEP_HEIGHT;
      FPosX := newX; // Продолжаем движение вперед
    end
    else FSpeedX := 0;

    // Обработка Z
    moveStep := FSpeedZ * stepDt;
    newZ := FPosZ + moveStep;
    if not CollidesAt(FPosX, FPosY, newZ) then
      FPosZ := newZ
    else if FOnGround and (not FIsStepping) and (not CollidesAt(FPosX, FPosY + STEP_HEIGHT, newZ)) then
    begin
      FIsStepping := True;
      FStepTargetY := FPosY + STEP_HEIGHT;
      FPosZ := newZ;
    end
    else FSpeedZ := 0;
  end;

  // Прыжок (игнорируем, если сейчас зашагиваем)
  if Jump and FOnGround and (not FIsStepping) then
  begin
    FVelocityY := Config.JumpSpeed;
    FOnGround := False;
  end;

  // Проверка опоры под ногами
  if FOnGround and (not FIsStepping) then
  begin
    if CollidesAt(FPosX, FPosY - 0.05, FPosZ) then
      FVelocityY := 0
    else
      FOnGround := False;
  end;

  // Гравитация
  if (not FOnGround) and (not FIsStepping) then
  begin
    FVelocityY := FVelocityY - Config.Gravity * dt;
    newY := FPosY + FVelocityY * dt;
    if not CollidesAt(FPosX, newY, FPosZ) then FPosY := newY
    else begin
      if FVelocityY < 0 then begin FPosY := Floor(newY) + 1.0; FOnGround := True; end
      else FPosY := Floor(newY + 1.8) - 1.8;
      FVelocityY := 0;
    end;
  end;

  // Анимация зашагивания
  if FIsStepping then
  begin
    FPosY := FPosY + (FStepTargetY - FPosY) * Min(1.0, dt * 12.0);
    if Abs(FPosY - FStepTargetY) < 0.05 then
    begin
      FPosY := FStepTargetY;
      FIsStepping := False;
      FOnGround := True;
      FVelocityY := 0;
    end
    else
    begin
      FVelocityY := 0;
      FOnGround := True; // Во время шага не падаем
    end;
  end;

  if FPosY < -10 then begin FPosY := 40; FVelocityY := 0; end;
end;

procedure TPlayer.SetPosition(X, Y, Z: Double);
begin
  FPosX := X; FPosY := Y; FPosZ := Z;
end;

end.
