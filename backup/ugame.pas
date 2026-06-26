unit uGame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, ExtCtrls, Math,
  uWorld, uPlayer, uRenderer, uInput, uConfig, uTypes;

type
  TGame = class
  private
    FWorld: TWorld;
    FPlayer: TPlayer;
    FRenderer: TRenderer;
    FInput: TInput;
    FTimer: TTimer;
    FOnRender: TNotifyEvent;
    FFrameCount: Integer;
    FLastFPSTime: UInt64;
    FFPS: Integer;
    FCameraX, FCameraY, FCameraZ: Double;
    procedure TimerTick(Sender: TObject);
  public
    constructor Create(Owner: TComponent; OnRender: TNotifyEvent);
    destructor Destroy; override;
    procedure Update(dt: Double);
    procedure Render(Bitmap: TBitmap; const DestRect: TRect);
    procedure HandleKeyDown(Key: Word);
    procedure HandleKeyUp(Key: Word);
    property World: TWorld read FWorld;
    property Player: TPlayer read FPlayer;
    property Input: TInput read FInput;
  end;

implementation

constructor TGame.Create(Owner: TComponent; OnRender: TNotifyEvent);
var
  spawnY, wy: Integer;
begin
  FWorld := TWorld.Create;
  FWorld.EnsureChunkExists(0, 0);
  spawnY := CHUNK_SIZE_Y - 1;
  for wy := CHUNK_SIZE_Y - 1 downto 0 do
  begin
    if FWorld.IsBlockSolid(0, wy, 0) then
    begin
      spawnY := wy + 2;
      Break;
    end;
  end;

  FPlayer := TPlayer.Create(FWorld);
  FPlayer.SetPosition(0, spawnY, 0);

  // Инициализация камеры
  FCameraX := FPlayer.PosX;
  FCameraY := FPlayer.PosY;
  FCameraZ := FPlayer.PosZ;

  FRenderer := TRenderer.Create;
  FInput := TInput.Create;
  FOnRender := OnRender;

  FTimer := TTimer.Create(Owner);
  FTimer.Interval := Config.TimerInterval;
  FTimer.OnTimer := @TimerTick;
  FTimer.Enabled := True;

  FFrameCount := 0;
  FLastFPSTime := TThread.GetTickCount64;
  FFPS := 0;
end;

destructor TGame.Destroy;
begin
  FTimer.Enabled := False; FTimer.Free;
  FInput.Free; FRenderer.Free; FPlayer.Free; FWorld.Free;
  inherited;
end;

procedure TGame.TimerTick(Sender: TObject);
var
  CurrentTime: UInt64;
  pcx, pcz, cx, cz: Integer;
begin
  Update(Config.DeltaTime);

  pcx := GetChunkCoord(Round(FPlayer.PosX), CHUNK_SIZE_X);
  pcz := GetChunkCoord(Round(FPlayer.PosZ), CHUNK_SIZE_Z);
  for cx := pcx - 1 to pcx + 1 do
    for cz := pcz - 1 to pcz + 1 do
      FWorld.EnsureChunkExists(cx, cz);

  Inc(FFrameCount);
  CurrentTime := TThread.GetTickCount64;
  if CurrentTime - FLastFPSTime >= 1000 then
  begin
    FFPS := FFrameCount;
    FFrameCount := 0;
    FLastFPSTime := CurrentTime;
  end;

  if Assigned(FOnRender) then FOnRender(Self);
end;

procedure TGame.Update(dt: Double);
var
  mx, mz: Double;
  smoothingFactor: Double;
begin
  mx := 0; mz := 0;
  if FInput.Left then mx := -1; if FInput.Right then mx := 1;
  if FInput.Up then mz := -1; if FInput.Down then mz := 1;

  FPlayer.Update(dt, mx, mz, FInput.Jump);

  // Плавное движение камеры (Exponential Smoothing)
  smoothingFactor := 1.0 - Exp(-Config.CameraSmoothing * dt);
  FCameraX := FCameraX + (FPlayer.PosX - FCameraX) * smoothingFactor;
  FCameraY := FCameraY + (FPlayer.PosY - FCameraY) * smoothingFactor;
  FCameraZ := FCameraZ + (FPlayer.PosZ - FCameraZ) * smoothingFactor;
end;

procedure TGame.Render(Bitmap: TBitmap; const DestRect: TRect);
const
  LEFT_MARGIN = 3; LINE_SPACING = 28;
var
  TopRect, SideRect, BottomRect: TRect;
  TopHeight, vw, vh, LineY, FPSY, TextW: Integer;
  FPSText: string;
begin
  vw := DestRect.Right - DestRect.Left; vh := DestRect.Bottom - DestRect.Top;
  Bitmap.Canvas.Brush.Color := clBlack; Bitmap.Canvas.FillRect(DestRect);

  TopHeight := (vh * 2) div 3;
  TopRect := Rect(DestRect.Left, DestRect.Top, DestRect.Left + vw div 2, DestRect.Top + TopHeight);
  SideRect := Rect(DestRect.Left + vw div 2, DestRect.Top, DestRect.Right, DestRect.Top + TopHeight);
  BottomRect := Rect(DestRect.Left, DestRect.Top + TopHeight, DestRect.Right, DestRect.Bottom);

  // Передаем координаты КАМЕРЫ вместо игрока
  FRenderer.DrawTopView(Bitmap, TopRect, FWorld, FPlayer, FCameraX, FCameraZ);
  FRenderer.DrawSideView(Bitmap, SideRect, FWorld, FPlayer, FCameraX, FCameraY);

  // Облака
  FRenderer.DrawClouds(Bitmap, TopRect, FCameraX, FCameraY, FCameraZ, False);
  FRenderer.DrawClouds(Bitmap, SideRect, FCameraX, FCameraY, FCameraZ, True);

  // UI
  Bitmap.Canvas.Brush.Color := $202020; Bitmap.Canvas.FillRect(BottomRect);
  Bitmap.Canvas.Font.Name := ChangeFileExt(ExtractFileName(Config.FontFileName), '');
  Bitmap.Canvas.Font.Color := clWhite; Bitmap.Canvas.Font.Size := 14;

  LineY := BottomRect.Top + 10;
  Bitmap.Canvas.TextOut(BottomRect.Left + LEFT_MARGIN, LineY, 'Прототип');

  LineY := LineY + LINE_SPACING;
  Bitmap.Canvas.Font.Color := clYellow;
  Bitmap.Canvas.TextOut(BottomRect.Left + LEFT_MARGIN, LineY,
    Format('Позиция: X=%.1f Y=%.1f Z=%.1f', [FPlayer.PosX, FPlayer.PosY, FPlayer.PosZ]));

  Bitmap.Canvas.Font.Color := clLime;
  FPSText := Format('FPS: %d', [FFPS]);
  TextW := Bitmap.Canvas.TextWidth(FPSText);
  FPSY := BottomRect.Top + 10;
  Bitmap.Canvas.TextOut(BottomRect.Right - TextW - LEFT_MARGIN, FPSY, FPSText);
end;

procedure TGame.HandleKeyDown(Key: Word); begin FInput.KeyDown(Key); end;
procedure TGame.HandleKeyUp(Key: Word); begin FInput.KeyUp(Key); end;

end.
