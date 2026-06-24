unit uRenderer;

{$mode objfpc}{$H+}

interface

uses
  Graphics, Classes, SysUtils, LCLType, uTypes, uWorld, uPlayer;

const
  VIEW_WIDTH = 320;
  VIEW_HEIGHT = 200;

type
  TRenderer = class
  public
    procedure DrawTopView(Bitmap: TBitmap; const DestRect: TRect; World: TWorld; Player: TPlayer);
    procedure DrawSideView(Bitmap: TBitmap; const DestRect: TRect; World: TWorld; Player: TPlayer);
  end;

implementation

procedure TRenderer.DrawTopView(Bitmap: TBitmap; const DestRect: TRect; World: TWorld; Player: TPlayer);
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

    cx := Player.PosX;
    cz := Player.PosZ;

    for i := 0 to High(World.Terrain) do
    begin
      px := Round(VIEW_WIDTH / 2 + (World.Terrain[i].X - cx));
      pz := Round(VIEW_HEIGHT / 2 + (World.Terrain[i].Z - cz));
      if (px >= 0) and (px < VIEW_WIDTH) and (pz >= 0) and (pz < VIEW_HEIGHT) then
        TempBmp.Canvas.Pixels[px, pz] := World.Terrain[i].Color;
    end;

    // Игрок
    TempBmp.Canvas.Pen.Color := clBlack;
    TempBmp.Canvas.Brush.Color := clBlack;
    TempBmp.Canvas.Ellipse(VIEW_WIDTH div 2 - 3, VIEW_HEIGHT div 2 - 3,
                           VIEW_WIDTH div 2 + 3, VIEW_HEIGHT div 2 + 3);

    // Облака
    TempBmp.Canvas.Pen.Color := clWhite;
    TempBmp.Canvas.Brush.Color := clWhite;
    for i := 0 to High(World.Clouds) do
    begin
      px := Round(VIEW_WIDTH / 2 + (World.Clouds[i].X - cx));
      pz := Round(VIEW_HEIGHT / 2 + (World.Clouds[i].Z - cz));
      if (px >= 0) and (px < VIEW_WIDTH) and (pz >= 0) and (pz < VIEW_HEIGHT) then
        TempBmp.Canvas.Ellipse(
          px - World.Clouds[i].Width div 2,
          pz - World.Clouds[i].Height div 2,
          px + World.Clouds[i].Width div 2,
          pz + World.Clouds[i].Height div 2
        );
    end;

    Bitmap.Canvas.StretchDraw(DestRect, TempBmp);
  finally
    TempBmp.Free;
  end;
end;

procedure TRenderer.DrawSideView(Bitmap: TBitmap; const DestRect: TRect; World: TWorld; Player: TPlayer);
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

    cx := Player.PosX;
    cy := Player.PosY;
    cz := Player.PosZ;

    GroundY := Round(VIEW_HEIGHT / 2 + cy);

    // Земля – используем LCLType.RGB для явного указания
    TempBmp.Canvas.Brush.Color := RGBToColor(139, 90, 43);
    if GroundY < VIEW_HEIGHT then
      TempBmp.Canvas.FillRect(0, GroundY, VIEW_WIDTH, VIEW_HEIGHT)
    else
      TempBmp.Canvas.FillRect(0, 0, VIEW_WIDTH, VIEW_HEIGHT);

    HalfW := VIEW_WIDTH div 2;
    HalfH := VIEW_HEIGHT div 2;

    // Трава
    TempBmp.Canvas.Pen.Width := 1;
    for i := 0 to High(World.Terrain) do
    begin
      if (Abs(World.Terrain[i].X - cx) < HalfW) and (Abs(World.Terrain[i].Z - cz) < HalfH) then
      begin
        px := Round(VIEW_WIDTH / 2 + (World.Terrain[i].X - cx));
        GrassHeight := 4 + Round(Abs(Sin(World.Terrain[i].X * 10 + World.Terrain[i].Z * 7)) * 5);
        py := GroundY;
        TempBmp.Canvas.Pen.Color := World.Terrain[i].Color;
        TempBmp.Canvas.MoveTo(px, py);
        TempBmp.Canvas.LineTo(px, py - GrassHeight);
      end;
    end;

    // Облака
    TempBmp.Canvas.Pen.Color := clWhite;
    TempBmp.Canvas.Brush.Color := clWhite;
    for i := 0 to High(World.Clouds) do
    begin
      if (Abs(World.Clouds[i].X - cx) < HalfW) and (Abs(World.Clouds[i].Z - cz) < HalfH) then
      begin
        px := Round(VIEW_WIDTH / 2 + (World.Clouds[i].X - cx));
        py := Round(VIEW_HEIGHT / 2 - (World.Clouds[i].Y - cy));
        if (px >= 0) and (px < VIEW_WIDTH) and (py >= 0) and (py < VIEW_HEIGHT) then
          TempBmp.Canvas.Ellipse(
            px - World.Clouds[i].Width div 2,
            py - World.Clouds[i].Height div 2,
            px + World.Clouds[i].Width div 2,
            py + World.Clouds[i].Height div 2
          );
      end;
    end;

    // Игрок
    TempBmp.Canvas.Pen.Color := clBlack;
    TempBmp.Canvas.Brush.Color := clBlack;
    TempBmp.Canvas.Ellipse(VIEW_WIDTH div 2 - 4, VIEW_HEIGHT div 2 - 4,
                           VIEW_WIDTH div 2 + 4, VIEW_HEIGHT div 2 + 4);

    Bitmap.Canvas.StretchDraw(DestRect, TempBmp);
  finally
    TempBmp.Free;
  end;
end;

end.
