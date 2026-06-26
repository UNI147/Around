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
procedure DrawClouds(Bitmap: TBitmap; const DestRect: TRect; Player: TPlayer; IsSideView: Boolean);
end;
implementation
procedure TRenderer.DrawTopView(Bitmap: TBitmap; const DestRect: TRect; World: TWorld; Player: TPlayer);
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
halfW := (DestRect.Right - DestRect.Left) div 2;
halfH := (DestRect.Bottom - DestRect.Top) div 2;
centerX := DestRect.Left + halfW;
centerY := DestRect.Top + halfH;
minWX := Floor(Player.PosX - halfW / BLOCK_SIZE) - 1;
maxWX := Ceil(Player.PosX + halfW / BLOCK_SIZE) + 1;
minWZ := Floor(Player.PosZ - halfH / BLOCK_SIZE) - 1;
maxWZ := Ceil(Player.PosZ + halfH / BLOCK_SIZE) + 1;
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
screenX := centerX + Round((wx - Player.PosX) * BLOCK_SIZE);
screenY := centerY + Round((wz - Player.PosZ) * BLOCK_SIZE);
if (screenX + BLOCK_SIZE > DestRect.Left) and (screenX < DestRect.Right) and
(screenY + BLOCK_SIZE > DestRect.Top) and (screenY < DestRect.Bottom) then
begin
Bitmap.Canvas.Brush.Color := blockColor;
Bitmap.Canvas.FillRect(screenX, screenY, screenX + BLOCK_SIZE, screenY + BLOCK_SIZE);
end;
end;
end;
end;
screenX := centerX; screenY := centerY;
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
CX, CZ, lx, lz: Integer;
Chunk: TChunk;
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
wz := Round(Player.PosZ);
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
screenX := centerX + Round((wx - Player.PosX) * BLOCK_SIZE);
screenY := centerY - Round((wy + 1 - Player.PosY) * BLOCK_SIZE);
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
screenX := centerX; screenY := centerY;
Bitmap.Canvas.Brush.Color := clRed;
Bitmap.Canvas.FillRect(screenX - 3, screenY - Round(1.8 * BLOCK_SIZE), screenX + 4, screenY);
end;

procedure TRenderer.DrawClouds(Bitmap: TBitmap; const DestRect: TRect; Player: TPlayer; IsSideView: Boolean);
var
  centerX, centerY, i: Integer;
  screenX, screenY, size: Integer;
  seed, h: Cardinal;
  baseX, baseY, relX, relZ, shiftX, shiftZ: Double;
  OldClipRect: TRect;
const
  parallaxFactor = 0.3; // Скорость движения облаков относительно игрока
  REPEAT_DIST = 170.0;  // Расстояние зацикливания (тайлинг)
begin
  OldClipRect := Bitmap.Canvas.ClipRect;
  Bitmap.Canvas.ClipRect := DestRect;

  centerX := DestRect.Left + (DestRect.Right - DestRect.Left) div 2;
  centerY := DestRect.Top + (DestRect.Bottom - DestRect.Top) div 2;

  for i := 0 to Config.CloudCount - 1 do
  begin
    seed := Cardinal(i) * 2654435761;
    h := (seed xor (seed shr 16)) * 2246822519;

    // Базовые координаты облака в мире
    baseX := (Integer(h and $1FFF) - 4096) * 0.02;
    baseY := (Integer((h shr 16) and $FFF) - 2048) * 0.02;
    size := 30 + Integer((h shr 24) and $1F);

    // Смещение мира с учетом параллакса
    shiftX := Player.PosX * parallaxFactor;
    shiftZ := Player.PosZ * parallaxFactor;

    // Относительные координаты с бесшовным зацикливанием
    relX := baseX - shiftX;
    relX := relX - REPEAT_DIST * Floor(relX / REPEAT_DIST + 0.5);

    if IsSideView then
    begin
      screenX := centerX + Round(relX * BLOCK_SIZE);
      screenY := centerY - Round((15 + baseY * 5) * BLOCK_SIZE); // Вариативность высоты
    end
    else
    begin
      relZ := baseY - shiftZ;
      relZ := relZ - REPEAT_DIST * Floor(relZ / REPEAT_DIST + 0.5);

      screenX := centerX + Round(relX * BLOCK_SIZE);
      screenY := centerY + Round(relZ * BLOCK_SIZE);
    end;

    // Отсечение невидимых
    if (screenX + size * 2 < DestRect.Left) or (screenX > DestRect.Right) then Continue;
    if (screenY + size < DestRect.Top) or (screenY > DestRect.Bottom) then Continue;

    // Отрисовка
    Bitmap.Canvas.Brush.Color := $F0F0F0;
    Bitmap.Canvas.Brush.Style := bsSolid;
    Bitmap.Canvas.Pen.Color := $E0E0E0;

    Bitmap.Canvas.Ellipse(screenX, screenY, screenX + size * 2, screenY + size);
    Bitmap.Canvas.Ellipse(screenX + size div 2, screenY - size div 3,
                          screenX + size * 2, screenY + size * 2 div 3);
  end;
  Bitmap.Canvas.ClipRect := OldClipRect;
end;

end.
