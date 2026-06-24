unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Dialogs, LCLType,
  Graphics, ExtCtrls, uGame, uRenderer;

type
  TForm1 = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormPaint(Sender: TObject);
    procedure OnGameRender(Sender: TObject);
  private
    FGame: TGame;
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  DoubleBuffered := True;
  ClientWidth := 320;
  ClientHeight := 200;
  FGame := TGame.Create(Self, @OnGameRender);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FGame.Free;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  WindowState := wsFullScreen;
  Invalidate;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  FGame.HandleKeyDown(Key);
  if Key = VK_ESCAPE then Close;
end;

procedure TForm1.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  FGame.HandleKeyUp(Key);
end;

procedure TForm1.FormPaint(Sender: TObject);
var
  Bmp: TBitmap;
  DestRect: TRect;
  W, H: Integer;
begin
  if (ClientWidth <= 0) or (ClientHeight <= 0) then Exit;

  Bmp := TBitmap.Create;
  try
    Bmp.SetSize(VIEW_WIDTH, VIEW_HEIGHT);
    Bmp.Canvas.Brush.Color := clBlack;
    Bmp.Canvas.FillRect(0, 0, VIEW_WIDTH, VIEW_HEIGHT);

    // Явно указываем модуль Types для Rect
    FGame.Render(Bmp, Types.Rect(0, 0, VIEW_WIDTH, VIEW_HEIGHT));

    // Масштабирование с сохранением пропорций и пиксельным выводом
    if ClientWidth / ClientHeight > VIEW_WIDTH / VIEW_HEIGHT then
    begin
      H := ClientHeight;
      W := Round(H * VIEW_WIDTH / VIEW_HEIGHT);
    end
    else
    begin
      W := ClientWidth;
      H := Round(W * VIEW_HEIGHT / VIEW_WIDTH);
    end;
    DestRect.Left := (ClientWidth - W) div 2;
    DestRect.Top := (ClientHeight - H) div 2;
    DestRect.Right := DestRect.Left + W;
    DestRect.Bottom := DestRect.Top + H;

    Canvas.Brush.Color := clBlack;
    Canvas.FillRect(ClientRect);
    // SetStretchBltMode удалён – StretchDraw сам справляется
    Canvas.StretchDraw(DestRect, Bmp);
  finally
    Bmp.Free;
  end;
end;

procedure TForm1.OnGameRender(Sender: TObject);
begin
  Invalidate;
end;

end.
