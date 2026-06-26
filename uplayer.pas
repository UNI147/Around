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
end;

procedure TPlayer.Update(dt: Double; const MoveX, MoveZ: Double; Jump: Boolean);
var
  newX, newY, newZ: Double;
  steps, i: Integer;
  stepDt, moveStep: Double;
  TargetSpeedX, TargetSpeedZ: Double;
const
  AccelFactor = 12.0; // Коэффициент плавности (чем больше, тем резче)
begin
  TargetSpeedX := MoveX * Config.MoveSpeed;
  TargetSpeedZ := MoveZ * Config.MoveSpeed;

  // Плавное ускорение и торможение
  FSpeedX := FSpeedX + (TargetSpeedX - FSpeedX) * Min(1.0, dt * AccelFactor);
  FSpeedZ := FSpeedZ + (TargetSpeedZ - FSpeedZ) * Min(1.0, dt * AccelFactor);

  steps := Max(1, Ceil(Abs(FSpeedX * dt) / 0.3));
  stepDt := dt / steps;

  for i := 1 to steps do
  begin
    moveStep := FSpeedX * stepDt;
    newX := FPosX + moveStep;
    if not CollidesAt(newX, FPosY, FPosZ) then FPosX := newX else FSpeedX := 0;

    moveStep := FSpeedZ * stepDt;
    newZ := FPosZ + moveStep;
    if not CollidesAt(FPosX, FPosY, newZ) then FPosZ := newZ else FSpeedZ := 0;
  end;

  if Jump and FOnGround then
  begin
    FVelocityY := Config.JumpSpeed;
    FOnGround := False;
  end;

  // Жесткая проверка опоры под ногами без применения гравитации
  if FOnGround then
  begin
    if CollidesAt(FPosX, FPosY - 0.05, FPosZ) then
    begin
      FVelocityY := 0;
      // Не трогаем FPosY, чтобы не телепортировать игрока вверх!
    end
    else
      FOnGround := False; // Сошли с уступа
  end;

  // Физика падения и прыжка
  if not FOnGround then
  begin
    FVelocityY := FVelocityY - Config.Gravity * dt;
    newY := FPosY + FVelocityY * dt;

    if not CollidesAt(FPosX, newY, FPosZ) then
    begin
      FPosY := newY;
    end
    else
    begin
      if FVelocityY < 0 then
      begin
        FPosY := Floor(newY) + 1.0; // Прилипаем к поверхности
        FOnGround := True;
      end
      else if FVelocityY > 0 then
      begin
        FPosY := Floor(newY + 1.8) - 1.8; // Удар головой о потолок
      end;
      FVelocityY := 0;
    end;
  end;

  if FPosY < -10 then begin FPosY := 40; FVelocityY := 0; end;
end;

procedure TPlayer.SetPosition(X, Y, Z: Double);
begin
  FPosX := X; FPosY := Y; FPosZ := Z;
end;

end.
