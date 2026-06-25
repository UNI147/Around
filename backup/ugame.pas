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
begin
  FWorld := TWorld.Create;
  FPlayer := TPlayer.Create(FWorld);
  FPlayer.SetPosition(0, 40, 0);

  FRenderer := TRenderer.Create;
  FInput := TInput.Create;
  FOnRender := OnRender;
  FTimer := TTimer.Create(Owner);
  FTimer.Interval := Config.TimerInterval;
  FTimer.OnTimer := @TimerTick;
  FTimer.Enabled := True;
end;

destructor TGame.Destroy;
begin
  FTimer.Enabled := False;
  FTimer.Free;
  FInput.Free;
  FRenderer.Free;
  FPlayer.Free;
  FWorld.Free;
  inherited;
end;

procedure TGame.TimerTick(Sender: TObject);
begin
  Update(Config.DeltaTime);
  if Assigned(FOnRender) then FOnRender(Self);
end;

procedure TGame.Update(dt: Double);
var
  mx, mz: Double;
begin
  mx := 0; mz := 0;
  if FInput.Left then mx := -1;
  if FInput.Right then mx := 1;
  if FInput.Up then mz := -1;
  if FInput.Down then mz := 1;
  FPlayer.Update(dt, mx, mz, FInput.Jump);
end;

procedure TGame.Render(Bitmap: TBitmap; const DestRect: TRect);
const
  LEFT_MARGIN = 1;
  LINE_SPACING = 28;
var
  TopRect, SideRect, BottomRect: TRect;
  TopHeight: Integer;
  vw, vh: Integer;
  LineY: Integer;
begin
  vw := DestRect.Right - DestRect.Left;
  vh := DestRect.Bottom - DestRect.Top;

  Bitmap.Canvas.Brush.Color := clBlack;
  Bitmap.Canvas.FillRect(DestRect);

  TopHeight := (vh * 2) div 3;
  // Левая верхняя часть
  TopRect := Rect(DestRect.Left, DestRect.Top, DestRect.Left + vw div 2, DestRect.Top + TopHeight);
  // Правая верхняя часть
  SideRect := Rect(DestRect.Left + vw div 2, DestRect.Top, DestRect.Right, DestRect.Top + TopHeight);
  // Нижняя панель (UI)
  BottomRect := Rect(DestRect.Left, DestRect.Top + TopHeight, DestRect.Right, DestRect.Bottom);

  FRenderer.DrawTopView(Bitmap, TopRect, FWorld, FPlayer);
  FRenderer.DrawSideView(Bitmap, SideRect, FWorld, FPlayer);

  // UI
  Bitmap.Canvas.Brush.Color := $202020;
  Bitmap.Canvas.FillRect(BottomRect);

  Bitmap.Canvas.Font.Name := ChangeFileExt(ExtractFileName(Config.FontFileName), '');
  Bitmap.Canvas.Font.Color := clWhite;
  Bitmap.Canvas.Font.Size := 14;

  LineY := BottomRect.Top + 10;
  Bitmap.Canvas.TextOut(BottomRect.Left + LEFT_MARGIN, LineY, 'Прототип');

  LineY := LineY + LINE_SPACING;
  Bitmap.Canvas.Font.Color := clYellow;
  Bitmap.Canvas.TextOut(BottomRect.Left + LEFT_MARGIN, LineY,
    Format('Позиция: X=%.1f Y=%.1f Z=%.1f', [FPlayer.PosX, FPlayer.PosY, FPlayer.PosZ]));
end;

procedure TGame.HandleKeyDown(Key: Word);
begin
  FInput.KeyDown(Key);
end;

procedure TGame.HandleKeyUp(Key: Word);
begin
  FInput.KeyUp(Key);
end;

end.
