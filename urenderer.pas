unit uRenderer;

{$mode objfpc}{$H+}

interface

uses
  Graphics, Classes, SysUtils, Math, LCLType, uTypes, uWorld, uPlayer, uConfig;

type
  TRenderer = class
  public
    procedure DrawTopView(Bitmap: TBitmap; const DestRect: TRect; World: TWorld; Player: TPlayer);
    procedure DrawSideView(Bitmap: TBitmap; const DestRect: TRect; World: TWorld; Player: TPlayer);
  end;

implementation

procedure TRenderer.DrawTopView(Bitmap: TBitmap; const DestRect: TRect; World: TWorld; Player: TPlayer);
var
  wx, wz, wy: Integer;
  minWX, maxWX, minWZ, maxWZ: Integer;
  b: TBlockID;
  screenX, screenY: Integer;
  blockColor: TColor;
  halfW, halfH: Integer;
  centerX, centerY: Integer;
begin
  halfW := (DestRect.Right - DestRect.Left) div 2;
  halfH := (DestRect.Bottom - DestRect.Top) div 2;
  centerX := DestRect.Left + halfW;
  centerY := DestRect.Top + halfH;

  // Вычисляем границы мира, которые видны на экране
  minWX := Floor(Player.PosX - halfW / BLOCK_SIZE) - 1;
  maxWX := Ceil(Player.PosX + halfW / BLOCK_SIZE) + 1;
  minWZ := Floor(Player.PosZ - halfH / BLOCK_SIZE) - 1;
  maxWZ := Ceil(Player.PosZ + halfH / BLOCK_SIZE) + 1;

  Bitmap.Canvas.Brush.Color := $202020;
  Bitmap.Canvas.FillRect(DestRect);

  for wx := minWX to maxWX do
    for wz := minWZ to maxWZ do
    begin
      // Идем сверху вниз, чтобы найти только самый верхний блок (поверхность)
      for wy := CHUNK_SIZE_Y - 1 downto 0 do
      begin
        b := World.GetBlock(wx, wy, wz);
        if b <> 0 then
        begin
          blockColor := GetBlockColor(b);
          screenX := centerX + Round((wx - Player.PosX) * BLOCK_SIZE);
          screenY := centerY + Round((wz - Player.PosZ) * BLOCK_SIZE);

          if (screenX + BLOCK_SIZE > DestRect.Left) and (screenX < DestRect.Right) and
             (screenY + BLOCK_SIZE > DestRect.Top) and (screenY < DestRect.Bottom) then
          begin
            Bitmap.Canvas.Brush.Color := blockColor;
            Bitmap.Canvas.FillRect(screenX, screenY, screenX + BLOCK_SIZE, screenY + BLOCK_SIZE);
          end;
          Break; // Поверхность найдена, идем к следующему X/Z
        end;
      end;
    end;

  // Игрок (Вид сверху)
  screenX := centerX;
  screenY := centerY;
  Bitmap.Canvas.Brush.Color := clRed;
  Bitmap.Canvas.FillRect(screenX - 3, screenY - 3, screenX + 4, screenY + 4);
end;

procedure TRenderer.DrawSideView(Bitmap: TBitmap; const DestRect: TRect; World: TWorld; Player: TPlayer);
var
  wx, wy, wz: Integer;
  minWX, maxWX, minWY, maxWY: Integer;
  b: TBlockID;
  screenX, screenY: Integer;
  blockColor: TColor;
  halfW, halfH: Integer;
  centerX, centerY: Integer;
begin
  halfW := (DestRect.Right - DestRect.Left) div 2;
  halfH := (DestRect.Bottom - DestRect.Top) div 2;
  centerX := DestRect.Left + halfW;
  centerY := DestRect.Top + halfH;

  minWX := Floor(Player.PosX - halfW / BLOCK_SIZE) - 1;
  maxWX := Ceil(Player.PosX + halfW / BLOCK_SIZE) + 1;
  minWY := Floor(Player.PosY - halfH / BLOCK_SIZE) - 1;
  maxWY := Ceil(Player.PosY + halfH / BLOCK_SIZE) + 1;

  Bitmap.Canvas.Brush.Color := clSkyBlue;
  Bitmap.Canvas.FillRect(DestRect);

  wz := Round(Player.PosZ); // Срез мира, на котором стоит игрок

  for wx := minWX to maxWX do
    for wy := minWY to maxWY do
    begin
      b := World.GetBlock(wx, wy, wz);
      if b <> 0 then
      begin
        blockColor := GetBlockColor(b);
        screenX := centerX + Round((wx - Player.PosX) * BLOCK_SIZE);
        screenY := centerY - Round((wy - Player.PosY) * BLOCK_SIZE); // Ось Y направлена вверх

        if (screenX + BLOCK_SIZE > DestRect.Left) and (screenX < DestRect.Right) and
           (screenY + BLOCK_SIZE > DestRect.Top) and (screenY < DestRect.Bottom) then
        begin
          Bitmap.Canvas.Brush.Color := blockColor;
          Bitmap.Canvas.FillRect(screenX, screenY, screenX + BLOCK_SIZE, screenY + BLOCK_SIZE);
        end;
      end;
    end;

  // Игрок (Вид сбоку, рост 1.8 блока)
  screenX := centerX;
  screenY := centerY;
  Bitmap.Canvas.Brush.Color := clRed;
  Bitmap.Canvas.FillRect(screenX - 3, screenY - Round(1.8 * BLOCK_SIZE), screenX + 4, screenY);
end;

end.
