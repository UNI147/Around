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
screenY := centerY - Round((wy - Player.PosY) * BLOCK_SIZE);
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
end.
