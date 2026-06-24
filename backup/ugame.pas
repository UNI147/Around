unit uGame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, ExtCtrls,
  uWorld, uPlayer, uRenderer, uInput;

type
  TGame = class
  private
    FWorld: TWorld;
    FPlayer: TPlayer;
    FRenderer: TRenderer;
    FInput: TInput;
    FTimer: TTimer;
    FOnRender: TNotifyEvent; // для вызова Invalidate
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

uses
  Forms;

constructor TGame.Create(Owner: TComponent; OnRender: TNotifyEvent);
begin
  FWorld := TWorld.Create;
  FPlayer := TPlayer.Create;
  FRenderer := TRenderer.Create;
  FInput := TInput.Create;
  FOnRender := OnRender;

  FTimer := TTimer.Create(Owner);
  FTimer.Interval := 30;
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
const
  DT = 0.03;
begin
  Update(DT);
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
begin
  FullBmp := TBitmap.Create;
  try
    FullBmp.SetSize(VIEW_WIDTH, VIEW_HEIGHT);
    FullBmp.Canvas.Brush.Color := clBlack;
    FullBmp.Canvas.FillRect(0, 0, VIEW_WIDTH, VIEW_HEIGHT);

    TopHeight := (VIEW_HEIGHT * 2) div 3;

    TopRect := Rect(0, 0, VIEW_WIDTH div 2, TopHeight);
    SideRect := Rect(VIEW_WIDTH div 2, 0, VIEW_WIDTH, TopHeight);
    BottomRect := Rect(0, TopHeight, VIEW_WIDTH, VIEW_HEIGHT);

    FRenderer.DrawTopView(FullBmp, TopRect, FWorld, FPlayer);
    FRenderer.DrawSideView(FullBmp, SideRect, FWorld, FPlayer);

    // Нижняя панель
    FullBmp.Canvas.Brush.Color := $202020;
    FullBmp.Canvas.FillRect(BottomRect);
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
