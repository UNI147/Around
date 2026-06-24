unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, Windows, SysUtils, LResources, Forms, Controls, Dialogs, LCLType,
  Graphics, ExtCtrls;

type
  TTerrainPoint = record
    X, Z: Double;
    Color: TColor;
  end;

  TCloud = record
    X, Y, Z: Double;
    Width, Height: Integer;
  end;

  TForm1 = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormPaint(Sender: TObject);
    procedure TimerTick(Sender: TObject);
  private
    FPlayerX, FPlayerY, FPlayerZ: Double;
    FVelocityY: Double;
    FSpeedX, FSpeedZ: Double;
    FOnGround: Boolean;

    FGravity: Double;
    FMoveSpeed: Double;
    FJumpSpeed: Double;

    FTimer: TTimer;

    FKeyLeft, FKeyRight, FKeyUp, FKeyDown, FKeyJump: Boolean;

    FTerrain: array of TTerrainPoint;
    FClouds: array of TCloud;

    procedure UpdatePlayer(dt: Double);
    procedure GenerateWorld;
    procedure DrawTopView(Bitmap: TBitmap; const DestRect: TRect);
    procedure DrawSideView(Bitmap: TBitmap; const DestRect: TRect);
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

const
  WORLD_SIZE = 400;
  NUM_TERRAIN_POINTS = 1500;
  NUM_CLOUDS = 30;
  VIEW_WIDTH = 320;
  VIEW_HEIGHT = 200;

procedure TForm1.FormCreate(Sender: TObject);
begin
  DoubleBuffered := True;
  ClientWidth := 320;
  ClientHeight := 200;

  FPlayerX := 0;
  FPlayerY := 0;
  FPlayerZ := 0;
  FVelocityY := 0;
  FSpeedX := 0;
  FSpeedZ := 0;
  FOnGround := True;

  FGravity := 600.0;
  FMoveSpeed := 150.0;
  FJumpSpeed := 350.0;

  FTimer := TTimer.Create(Self);
  FTimer.Interval := 30;
  FTimer.OnTimer := @TimerTick;
  FTimer.Enabled := True;

  GenerateWorld;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  WindowState := wsFullScreen;
  Invalidate;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FTimer.Enabled := False;
  FTimer.Free;
end;

procedure TForm1.GenerateWorld;
var
  i: Integer;
begin
  Randomize;
  SetLength(FTerrain, NUM_TERRAIN_POINTS);
  for i := 0 to NUM_TERRAIN_POINTS - 1 do
  begin
    FTerrain[i].X := (Random - 0.5) * WORLD_SIZE;
    FTerrain[i].Z := (Random - 0.5) * WORLD_SIZE;
    FTerrain[i].Color := RGB(0, 64 + Round(Random * 128), 0);
  end;

  SetLength(FClouds, NUM_CLOUDS);
  for i := 0 to NUM_CLOUDS - 1 do
  begin
    FClouds[i].X := (Random - 0.5) * WORLD_SIZE;
    FClouds[i].Y := 60 + Random * 80;
    FClouds[i].Z := (Random - 0.5) * WORLD_SIZE;
    FClouds[i].Width := 30 + Round(Random * 60);
    FClouds[i].Height := 10 + Round(Random * 20);
  end;
end;

procedure TForm1.TimerTick(Sender: TObject);
const
  DT = 0.03;
begin
  FSpeedX := 0;
  FSpeedZ := 0;
  if FKeyLeft  then FSpeedX := -FMoveSpeed;
  if FKeyRight then FSpeedX :=  FMoveSpeed;
  if FKeyUp    then FSpeedZ := -FMoveSpeed;
  if FKeyDown  then FSpeedZ :=  FMoveSpeed;

  if FKeyJump and FOnGround then
  begin
    FVelocityY := FJumpSpeed;
    FOnGround := False;
    FKeyJump := False;
  end;

  UpdatePlayer(DT);
  Invalidate;
end;

procedure TForm1.UpdatePlayer(dt: Double);
var
  newY: Double;
begin
  FPlayerX := FPlayerX + FSpeedX * dt;
  FPlayerZ := FPlayerZ + FSpeedZ * dt;

  FVelocityY := FVelocityY - FGravity * dt;
  newY := FPlayerY + FVelocityY * dt;
  if newY < 0 then
  begin
    newY := 0;
    FVelocityY := 0;
    FOnGround := True;
  end;
  FPlayerY := newY;

  if FPlayerX < -WORLD_SIZE/2 then FPlayerX := -WORLD_SIZE/2;
  if FPlayerX > WORLD_SIZE/2 then FPlayerX := WORLD_SIZE/2;
  if FPlayerZ < -WORLD_SIZE/2 then FPlayerZ := -WORLD_SIZE/2;
  if FPlayerZ > WORLD_SIZE/2 then FPlayerZ := WORLD_SIZE/2;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_LEFT, Ord('A'): FKeyLeft := True;
    VK_RIGHT, Ord('D'): FKeyRight := True;
    VK_UP, Ord('W'): FKeyUp := True;
    VK_DOWN, Ord('S'): FKeyDown := True;
    VK_SPACE: FKeyJump := True;
    VK_ESCAPE: Close;
  end;
end;

procedure TForm1.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_LEFT, Ord('A'): FKeyLeft := False;
    VK_RIGHT, Ord('D'): FKeyRight := False;
    VK_UP, Ord('W'): FKeyUp := False;
    VK_DOWN, Ord('S'): FKeyDown := False;
    VK_SPACE: FKeyJump := False;
  end;
end;

procedure TForm1.DrawTopView(Bitmap: TBitmap; const DestRect: TRect);
var
  TempBmp: TBitmap;
  cx, cz: Double;
  px, pz: Integer;
  i: Integer;
begin
  TempBmp := TBitmap.Create;
  try
    TempBmp.SetSize(VIEW_WIDTH, VIEW_HEIGHT);
    TempBmp.Canvas.Brush.Color := clGreen;
    TempBmp.Canvas.FillRect(0, 0, VIEW_WIDTH, VIEW_HEIGHT);

    cx := FPlayerX;
    cz := FPlayerZ;

    for i := 0 to High(FTerrain) do
    begin
      px := Round(VIEW_WIDTH / 2 + (FTerrain[i].X - cx));
      pz := Round(VIEW_HEIGHT / 2 + (FTerrain[i].Z - cz));
      if (px >= 0) and (px < VIEW_WIDTH) and (pz >= 0) and (pz < VIEW_HEIGHT) then
        TempBmp.Canvas.Pixels[px, pz] := FTerrain[i].Color;
    end;

    TempBmp.Canvas.Pen.Color := clWhite;
    TempBmp.Canvas.Brush.Color := clWhite;
    for i := 0 to High(FClouds) do
    begin
      px := Round(VIEW_WIDTH / 2 + (FClouds[i].X - cx));
      pz := Round(VIEW_HEIGHT / 2 + (FClouds[i].Z - cz));
      if (px >= 0) and (px < VIEW_WIDTH) and (pz >= 0) and (pz < VIEW_HEIGHT) then
        TempBmp.Canvas.Ellipse(
          px - FClouds[i].Width div 2,
          pz - FClouds[i].Height div 2,
          px + FClouds[i].Width div 2,
          pz + FClouds[i].Height div 2
        );
    end;

    // Игрок – точка
    TempBmp.Canvas.Pen.Color := clBlack;
    TempBmp.Canvas.Brush.Color := clBlack;
    TempBmp.Canvas.Ellipse(VIEW_WIDTH div 2 - 3, VIEW_HEIGHT div 2 - 3,
                           VIEW_WIDTH div 2 + 3, VIEW_HEIGHT div 2 + 3);

    Bitmap.Canvas.StretchDraw(DestRect, TempBmp);
  finally
    TempBmp.Free;
  end;
end;

procedure TForm1.DrawSideView(Bitmap: TBitmap; const DestRect: TRect);
var
  TempBmp: TBitmap;
  cx, cy, cz: Double;
  px, py: Integer;
  i: Integer;
  GroundY: Integer;
  GrassHeight: Integer;
  HalfW, HalfH: Integer;
begin
  TempBmp := TBitmap.Create;
  try
    TempBmp.SetSize(VIEW_WIDTH, VIEW_HEIGHT);

    // Небо
    TempBmp.Canvas.Brush.Color := clSkyBlue;
    TempBmp.Canvas.FillRect(0, 0, VIEW_WIDTH, VIEW_HEIGHT);

    cx := FPlayerX;
    cy := FPlayerY;
    cz := FPlayerZ;

    // Уровень земли в экранных координатах
    GroundY := Round(VIEW_HEIGHT / 2 + cy);

    // Земля – коричневый цвет
    TempBmp.Canvas.Brush.Color := RGB(139, 90, 43); // SaddleBrown
    if GroundY < VIEW_HEIGHT then
      TempBmp.Canvas.FillRect(0, GroundY, VIEW_WIDTH, VIEW_HEIGHT)
    else
      TempBmp.Canvas.FillRect(0, 0, VIEW_WIDTH, VIEW_HEIGHT);

    HalfW := VIEW_WIDTH div 2;  // 160
    HalfH := VIEW_HEIGHT div 2; // 100

    // Рисуем траву (вертикальные линии)
    TempBmp.Canvas.Pen.Width := 1;
    for i := 0 to High(FTerrain) do
    begin
      // Проверка, что точка попадает в область видимости по X и Z
      if (Abs(FTerrain[i].X - cx) < HalfW) and (Abs(FTerrain[i].Z - cz) < HalfH) then
      begin
        px := Round(VIEW_WIDTH / 2 + (FTerrain[i].X - cx));
        // Высота травинки стабильна, зависит от координат точки
        GrassHeight := 4 + Round(Abs(Sin(FTerrain[i].X * 10 + FTerrain[i].Z * 7)) * 5);
        // Основание – на уровне земли
        py := GroundY;
        // Рисуем линию от земли вверх
        TempBmp.Canvas.Pen.Color := FTerrain[i].Color;
        TempBmp.Canvas.MoveTo(px, py);
        TempBmp.Canvas.LineTo(px, py - GrassHeight);
      end;
    end;

    // Рисуем облака только видимые
    TempBmp.Canvas.Pen.Color := clWhite;
    TempBmp.Canvas.Brush.Color := clWhite;
    for i := 0 to High(FClouds) do
    begin
      if (Abs(FClouds[i].X - cx) < HalfW) and (Abs(FClouds[i].Z - cz) < HalfH) then
      begin
        px := Round(VIEW_WIDTH / 2 + (FClouds[i].X - cx));
        py := Round(VIEW_HEIGHT / 2 - (FClouds[i].Y - cy));
        // Дополнительная проверка, что облако попадает в видимую область экрана
        if (px >= 0) and (px < VIEW_WIDTH) and (py >= 0) and (py < VIEW_HEIGHT) then
          TempBmp.Canvas.Ellipse(
            px - FClouds[i].Width div 2,
            py - FClouds[i].Height div 2,
            px + FClouds[i].Width div 2,
            py + FClouds[i].Height div 2
          );
      end;
    end;

    // Игрок – точка в центре
    TempBmp.Canvas.Pen.Color := clBlack;
    TempBmp.Canvas.Brush.Color := clBlack;
    TempBmp.Canvas.Ellipse(VIEW_WIDTH div 2 - 4, VIEW_HEIGHT div 2 - 4,
                           VIEW_WIDTH div 2 + 4, VIEW_HEIGHT div 2 + 4);

    Bitmap.Canvas.StretchDraw(DestRect, TempBmp);
  finally
    TempBmp.Free;
  end;
end;

procedure TForm1.FormPaint(Sender: TObject);
var
  FullBmp: TBitmap;
  TopRect, SideRect, BottomRect: TRect;
  TopHeight: Integer;
  DestRect: TRect;
  W, H: Integer;
begin
  if (ClientWidth <= 0) or (ClientHeight <= 0) then Exit;

  FullBmp := TBitmap.Create;
  try
    FullBmp.SetSize(320, 200);
    FullBmp.Canvas.Brush.Color := clBlack;
    FullBmp.Canvas.FillRect(0, 0, 320, 200);

    TopHeight := (200 * 2) div 3;

    TopRect := Classes.Rect(0, 0, 160, TopHeight);
    SideRect := Classes.Rect(160, 0, 320, TopHeight);
    BottomRect := Classes.Rect(0, TopHeight, 320, 200);

    DrawTopView(FullBmp, TopRect);
    DrawSideView(FullBmp, SideRect);

    // Нижняя панель
    FullBmp.Canvas.Brush.Color := $202020;
    FullBmp.Canvas.FillRect(BottomRect);
    FullBmp.Canvas.Font.Color := clWhite;
    FullBmp.Canvas.TextOut(BottomRect.Left + 10, BottomRect.Top + 10, 'Интерфейс');
    FullBmp.Canvas.Font.Color := clYellow;
    FullBmp.Canvas.TextOut(BottomRect.Left + 10, BottomRect.Top + 30,
      Format('Позиция: X=%.1f Y=%.1f Z=%.1f', [FPlayerX, FPlayerY, FPlayerZ]));

    // Пиксельный вывод без интерполяции
    if ClientWidth / ClientHeight > 320 / 200 then
    begin
      H := ClientHeight;
      W := Round(H * 320 / 200);
    end
    else
    begin
      W := ClientWidth;
      H := Round(W * 200 / 320);
    end;
    DestRect.Left := (ClientWidth - W) div 2;
    DestRect.Top := (ClientHeight - H) div 2;
    DestRect.Right := DestRect.Left + W;
    DestRect.Bottom := DestRect.Top + H;

    Canvas.Brush.Color := clBlack;
    Canvas.FillRect(ClientRect);

    SetStretchBltMode(Canvas.Handle, STRETCH_ANDSCANS);
    Canvas.StretchDraw(DestRect, FullBmp);
  finally
    FullBmp.Free;
  end;
end;

end.
