unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Dialogs, LCLType,
  Graphics, ExtCtrls, Types, uGame, uRenderer, uResources, uConfig;

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
  // CHANGED: размеры берутся из конфига
  ClientWidth := Config.ViewWidth;
  ClientHeight := Config.ViewHeight;
  // Загружаем шрифт из файла, указанного в конфиге
  LoadCustomFont(ExtractFilePath(ParamStr(0)) + Config.FontFileName);
  FGame := TGame.Create(Self, @OnGameRender);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FGame.Free;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  if Config.FullScreen then
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
    Bmp.SetSize(Config.ViewWidth, Config.ViewHeight);
    Bmp.Canvas.Brush.Color := clBlack;
    Bmp.Canvas.FillRect(0, 0, Config.ViewWidth, Config.ViewHeight);

    FGame.Render(Bmp, Rect(0, 0, Config.ViewWidth, Config.ViewHeight));

    // Масштабирование с сохранением пропорций
    if ClientWidth / ClientHeight > Config.ViewWidth / Config.ViewHeight then
    begin
      H := ClientHeight;
      W := Round(H * Config.ViewWidth / Config.ViewHeight);
    end
    else
    begin
      W := ClientWidth;
      H := Round(W * Config.ViewHeight / Config.ViewWidth);
    end;
    DestRect.Left := (ClientWidth - W) div 2;
    DestRect.Top := (ClientHeight - H) div 2;
    DestRect.Right := DestRect.Left + W;
    DestRect.Bottom := DestRect.Top + H;

    Canvas.Brush.Color := clBlack;
    Canvas.FillRect(ClientRect);
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
