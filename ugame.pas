unit uGame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, ExtCtrls,
  uWorld, uPlayer, uRenderer, uInput, uConfig;

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
  FPlayer := TPlayer.Create;
  // Устанавливаем начальную позицию из конфига
  FPlayer.SetPosition(Config.StartX, Config.StartY, Config.StartZ);
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
var
  FullBmp: TBitmap;
  TopRect, SideRect, BottomRect: TRect;
  TopHeight: Integer;
  vw, vh: Integer;
begin
  vw := Config.ViewWidth;
  vh := Config.ViewHeight;
  FullBmp := TBitmap.Create;
  try
    FullBmp.SetSize(vw, vh);
    FullBmp.Canvas.Brush.Color := clBlack;
    FullBmp.Canvas.FillRect(0, 0, vw, vh);

    TopHeight := (vh * 2) div 3;

    TopRect := Rect(0, 0, vw div 2, TopHeight);
    SideRect := Rect(vw div 2, 0, vw, TopHeight);
    BottomRect := Rect(0, TopHeight, vw, vh);

    FRenderer.DrawTopView(FullBmp, TopRect, FWorld, FPlayer);
    FRenderer.DrawSideView(FullBmp, SideRect, FWorld, FPlayer);

    // Нижняя панель
    FullBmp.Canvas.Brush.Color := $202020;
    FullBmp.Canvas.FillRect(BottomRect);

    // Шрифт из конфига
    FullBmp.Canvas.Font.Name := ChangeFileExt(ExtractFileName(Config.FontFileName), '');
    FullBmp.Canvas.Font.Color := clWhite;
    FullBmp.Canvas.TextOut(BottomRect.Left + 10, BottomRect.Top + 10, 'Интерфейс');
    FullBmp.Canvas.Font.Color := clYellow;
    FullBmp.Canvas.TextOut(BottomRect.Left + 10, BottomRect.Top + 30,
      Format('Позиция: X=%.1f Y=%.1f Z=%.1f', [FPlayer.PosX, FPlayer.PosY, FPlayer.PosZ]));

    Bitmap.Canvas.StretchDraw(DestRect, FullBmp);
  finally
    FullBmp.Free;
  end;
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
