unit uRenderer;

{$mode objfpc}{$H+}

interface

uses
  Graphics, Classes, SysUtils, Math, LCLType, uTypes, uWorld, uPlayer, uConfig;

const
  PARALLAX_FACTOR = 0.3;
  REPEAT_DIST = 200.0;

type
  TRenderer = class
  public
    procedure DrawTopView(Bitmap: TBitmap; const DestRect: TRect; World: TWorld; Player: TPlayer; CamX, CamZ: Double);
    procedure DrawSideView(Bitmap: TBitmap; const DestRect: TRect; World: TWorld; Player: TPlayer; CamX, CamY, CamZ: Double);
    procedure DrawClouds(Bitmap: TBitmap; const DestRect: TRect; CamX, CamY, CamZ: Double; IsSideView: Boolean);
  end;

implementation

procedure TRenderer.DrawTopView(Bitmap: TBitmap; const DestRect: TRect; World: TWorld; Player: TPlayer; CamX, CamZ: Double);
var
  wx, wz: Integer;
  minWX, maxWX, minWZ, maxWZ: Integer;
  b: TBlockID;
  screenX, screenY: Integer;
  blockColor: TColor;
  halfW, halfH: Integer;
  centerX, centerY: Integer;
  CX, CZ, lx, lz, wy: Integer;
  Chunk: TChunk;
begin
  // СОХРАНЯЕМ старый клиппинг и УСТАНАВЛИВАЕМ жесткие границы текущего вида
  OldClipRect := Bitmap.Canvas.ClipRect;
  Bitmap.Canvas.ClipRect := DestRect;
  halfW := (DestRect.Right - DestRect.Left) div 2;
  halfH := (DestRect.Bottom - DestRect.Top) div 2;
  centerX := DestRect.Left + halfW;
  centerY := DestRect.Top + halfH;

  minWX := Floor(CamX - halfW / BLOCK_SIZE) - 1;
  maxWX := Ceil(CamX + halfW / BLOCK_SIZE) + 1;
  minWZ := Floor(CamZ - halfH / BLOCK_SIZE) - 1;
  maxWZ := Ceil(CamZ + halfH / BLOCK_SIZE) + 1;

  Bitmap.Canvas.Brush.Color := $202020;
  Bitmap.Canvas.FillRect(DestRect);

  for wx := minWX to maxWX do
    for wz := minWZ to maxWZ do
    begin
      CX := GetChunkCoord(wx, CHUNK_SIZE_X);
      CZ := GetChunkCoord(wz, CHUNK_SIZE_Z);
      Chunk := World.FindChunk(CX, CZ);
      if Chunk = nil then begin World.EnsureChunkExists(CX, CZ); Chunk := World.FindChunk(CX, CZ); end;

      if Assigned(Chunk) then
      begin
        lx := wx - CX * CHUNK_SIZE_X;
        lz := wz - CZ * CHUNK_SIZE_Z;
        wy := Chunk.HeightMap[lx, lz];
        if wy >= 0 then
        begin
          b := Chunk.Blocks[lx, wy, lz];
          blockColor := GetBlockColor(b);
          screenX := centerX + Round((wx - CamX) * BLOCK_SIZE);
          screenY := centerY + Round((wz - CamZ) * BLOCK_SIZE);

          if (screenX + BLOCK_SIZE > DestRect.Left) and (screenX < DestRect.Right) and
             (screenY + BLOCK_SIZE > DestRect.Top) and (screenY < DestRect.Bottom) then
          begin
            Bitmap.Canvas.Brush.Color := blockColor;
            Bitmap.Canvas.FillRect(screenX, screenY, screenX + BLOCK_SIZE, screenY + BLOCK_SIZE);
          end;
        end;
      end;
    end;

  screenX := centerX + Round((Player.PosX - CamX) * BLOCK_SIZE);
  screenY := centerY + Round((Player.PosZ - CamZ) * BLOCK_SIZE);
  Bitmap.Canvas.Brush.Color := clRed;
  Bitmap.Canvas.FillRect(screenX - 3, screenY - 3, screenX + 4, screenY + 4);
end;

procedure TRenderer.DrawSideView(Bitmap: TBitmap; const DestRect: TRect; World: TWorld; Player: TPlayer; CamX, CamY, CamZ: Double);
var
  wx, wy, wz: Integer;
  minWX, maxWX, minWY, maxWY: Integer;
  b: TBlockID;
  screenX, screenY: Integer;
  blockColor: TColor;
  halfW, halfH: Integer;
  centerX, centerY: Integer;
  CX, CZ, lx, lz: Integer;
  Chunk: TChunk;
begin
  halfW := (DestRect.Right - DestRect.Left) div 2;
  halfH := (DestRect.Bottom - DestRect.Top) div 2;
  centerX := DestRect.Left + halfW;
  centerY := DestRect.Top + halfH;

  minWX := Floor(CamX - halfW / BLOCK_SIZE) - 1;
  maxWX := Ceil(CamX + halfW / BLOCK_SIZE) + 1;
  minWY := Floor(CamY - halfH / BLOCK_SIZE) - 1;
  maxWY := Ceil(CamY + halfH / BLOCK_SIZE) + 1;

  Bitmap.Canvas.Brush.Color := clSkyBlue;
  Bitmap.Canvas.FillRect(DestRect);

  wz := Round(CamZ);
  CZ := GetChunkCoord(wz, CHUNK_SIZE_Z);

  for wx := minWX to maxWX do
  begin
    CX := GetChunkCoord(wx, CHUNK_SIZE_X);
    Chunk := World.FindChunk(CX, CZ);
    if Chunk = nil then begin World.EnsureChunkExists(CX, CZ); Chunk := World.FindChunk(CX, CZ); end;

    if Assigned(Chunk) then
    begin
      lx := wx - CX * CHUNK_SIZE_X;
      lz := wz - CZ * CHUNK_SIZE_Z;
      for wy := minWY to maxWY do
      begin
        if (wy >= 0) and (wy < CHUNK_SIZE_Y) then
        begin
          b := Chunk.Blocks[lx, wy, lz];
          if b <> 0 then
          begin
            blockColor := GetBlockColor(b);
            screenX := centerX + Round((wx - CamX) * BLOCK_SIZE);
            screenY := centerY - Round((wy - CamY) * BLOCK_SIZE);

            if (screenX + BLOCK_SIZE > DestRect.Left) and (screenX < DestRect.Right) and
               (screenY + BLOCK_SIZE > DestRect.Top) and (screenY < DestRect.Bottom) then
            begin
              Bitmap.Canvas.Brush.Color := blockColor;
              Bitmap.Canvas.FillRect(screenX, screenY, screenX + BLOCK_SIZE, screenY + BLOCK_SIZE);
            end;
          end;
        end;
      end;
    end;
  end;

  screenX := centerX + Round((Player.PosX - CamX) * BLOCK_SIZE);
  screenY := centerY - Round((Player.PosY - CamY) * BLOCK_SIZE);
  Bitmap.Canvas.Brush.Color := clRed;
  Bitmap.Canvas.FillRect(screenX - 3, screenY - Round(1.8 * BLOCK_SIZE), screenX + 4, screenY);
end;

procedure TRenderer.DrawClouds(Bitmap: TBitmap; const DestRect: TRect; CamX, CamY, CamZ: Double; IsSideView: Boolean);
var
  centerX, centerY: Integer;
  i: Integer;
  seed, h: Cardinal;
  baseX, baseZ, baseH: Double;
  relX, relZ: Double;
  shiftX, shiftZ: Double;
  screenX, screenY, size: Integer;
begin
  centerX := DestRect.Left + (DestRect.Right - DestRect.Left) div 2;
  centerY := DestRect.Top + (DestRect.Bottom - DestRect.Top) div 2;

  shiftX := CamX * PARALLAX_FACTOR;
  shiftZ := CamZ * PARALLAX_FACTOR;

  Bitmap.Canvas.Brush.Color := $E0E0E0;
  Bitmap.Canvas.Pen.Style := psClear;

  for i := 0 to Config.CloudCount - 1 do
  begin
    seed := Cardinal(i) * 2654435761;
    h := (seed xor (seed shr 16)) * 2246822519;

    baseX := (Integer(h and $1FFF) - 4096) * 0.02;
    baseZ := (Integer((h shr 16) and $FFF) - 2048) * 0.02;
    baseH := 50.0 + Integer((h shr 28) and $0F) * 2.0;
    size := 30 + Integer((h shr 24) and $1F);

    relX := baseX - shiftX;
    relX := relX - REPEAT_DIST * Floor(relX / REPEAT_DIST + 0.5);

    if IsSideView then
    begin
      screenX := centerX + Round(relX * BLOCK_SIZE);
      screenY := centerY - Round((baseH - CamY) * BLOCK_SIZE);
    end
    else
    begin
      relZ := baseZ - shiftZ;
      relZ := relZ - REPEAT_DIST * Floor(relZ / REPEAT_DIST + 0.5);

      screenX := centerX + Round(relX * BLOCK_SIZE);
      screenY := centerY + Round(relZ * BLOCK_SIZE);
    end;

    if (screenX < DestRect.Left - size) or (screenX > DestRect.Right + size) or
       (screenY < DestRect.Top - size) or (screenY > DestRect.Bottom + size) then
      Continue;

    Bitmap.Canvas.Ellipse(screenX - size, screenY - size div 2,
                          screenX + size, screenY + size div 2);
  end;
end;

end.
