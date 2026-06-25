unit uRenderer;

{$mode objfpc}{$H+}

interface

uses
  Graphics, Classes, SysUtils, LCLType, uTypes, uWorld, uPlayer, uConfig;

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
  vw, vh: Integer;
begin
  vw := Config.ViewWidth;
  vh := Config.ViewHeight;
  TempBmp := TBitmap.Create;
  try
    TempBmp.SetSize(vw, vh);
    TempBmp.Canvas.Brush.Color := clGreen;
    TempBmp.Canvas.FillRect(0, 0, vw, vh);

    cx := Player.PosX;
    cz := Player.PosZ;

    for i := 0 to High(World.Terrain) do
    begin
      px := Round(vw / 2 + (World.Terrain[i].X - cx));
      pz := Round(vh / 2 + (World.Terrain[i].Z - cz));
      if (px >= 0) and (px < vw) and (pz >= 0) and (pz < vh) then
        TempBmp.Canvas.Pixels[px, pz] := World.Terrain[i].Color;
    end;

    // Игрок
    TempBmp.Canvas.Pen.Color := clBlack;
    TempBmp.Canvas.Brush.Color := clBlack;
    TempBmp.Canvas.Ellipse(vw div 2 - 3, vh div 2 - 3,
                           vw div 2 + 3, vh div 2 + 3);

    // Облака
    TempBmp.Canvas.Pen.Color := clWhite;
    TempBmp.Canvas.Brush.Color := clWhite;
    for i := 0 to High(World.Clouds) do
    begin
      px := Round(vw / 2 + (World.Clouds[i].X - cx));
      pz := Round(vh / 2 + (World.Clouds[i].Z - cz));
      if (px >= 0) and (px < vw) and (pz >= 0) and (pz < vh) then
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
  vw, vh: Integer;
begin
  vw := Config.ViewWidth;
  vh := Config.ViewHeight;
  TempBmp := TBitmap.Create;
  try
    TempBmp.SetSize(vw, vh);

    // Небо
    TempBmp.Canvas.Brush.Color := clSkyBlue;
    TempBmp.Canvas.FillRect(0, 0, vw, vh);

    cx := Player.PosX;
    cy := Player.PosY;
    cz := Player.PosZ;

    GroundY := Round(vh / 2 + cy);

    // Земля
    TempBmp.Canvas.Brush.Color := RGBToColor(139, 90, 43);
    if GroundY < vh then
      TempBmp.Canvas.FillRect(0, GroundY, vw, vh)
    else
      TempBmp.Canvas.FillRect(0, 0, vw, vh);

    HalfW := vw div 2;
    HalfH := vh div 2;

    // Трава
    TempBmp.Canvas.Pen.Width := 1;
    for i := 0 to High(World.Terrain) do
    begin
      if (Abs(World.Terrain[i].X - cx) < HalfW) and (Abs(World.Terrain[i].Z - cz) < HalfH) then
      begin
        px := Round(vw / 2 + (World.Terrain[i].X - cx));
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
        px := Round(vw / 2 + (World.Clouds[i].X - cx));
        py := Round(vh / 2 - (World.Clouds[i].Y - cy));
        if (px >= 0) and (px < vw) and (py >= 0) and (py < vh) then
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
    TempBmp.Canvas.Ellipse(vw div 2 - 4, vh div 2 - 4,
                           vw div 2 + 4, vh div 2 + 4);

    Bitmap.Canvas.StretchDraw(DestRect, TempBmp);
  finally
    TempBmp.Free;
  end;
end;

end.
