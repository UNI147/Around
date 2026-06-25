unit uWorld;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, Contnrs, uTypes, uConfig;

type
  TChunk = class
    Blocks: array[0..CHUNK_SIZE_X-1, 0..CHUNK_SIZE_Y-1, 0..CHUNK_SIZE_Z-1] of TBlockID;
    ChunkX, ChunkZ: Integer;
    constructor Create(AX, AZ: Integer);
  end;

  TWorld = class
  private
    FChunks: TObjectList;
    function GetTerrainHeight(WorldX, WorldZ: Integer): Integer;
    function FindChunk(CX, CZ: Integer): TChunk;
  public
    constructor Create;
    destructor Destroy; override;
    function GetBlock(X, Y, Z: Integer): TBlockID;
    procedure SetBlock(X, Y, Z: Integer; Value: TBlockID);
    function IsBlockSolid(X, Y, Z: Integer): Boolean;
    procedure EnsureChunkExists(CX, CZ: Integer);
    procedure GenerateChunk(CX, CZ: Integer);
  end;

implementation

function GetChunkCoord(WorldCoord, ChunkSize: Integer): Integer; inline;
begin
  if WorldCoord >= 0 then
    Result := WorldCoord div ChunkSize
  else
    Result := (WorldCoord - ChunkSize + 1) div ChunkSize;
end;

constructor TChunk.Create(AX, AZ: Integer);
begin
  ChunkX := AX;
  ChunkZ := AZ;
  FillChar(Blocks, SizeOf(Blocks), 0);
end;

constructor TWorld.Create;
begin
  FChunks := TObjectList.Create(True); // True = автоматически освобождает память чанков
end;

destructor TWorld.Destroy;
begin
  FChunks.Free;
  inherited;
end;

function TWorld.FindChunk(CX, CZ: Integer): TChunk;
var
  i: Integer;
begin
  for i := 0 to FChunks.Count - 1 do
  begin
    Result := TChunk(FChunks[i]);
    if (Result.ChunkX = CX) and (Result.ChunkZ = CZ) then Exit;
  end;
  Result := nil;
end;

function TWorld.GetTerrainHeight(WorldX, WorldZ: Integer): Integer;
var
  h: Double;
begin
  // Простой процедурный шум на основе синусоид для холмов
  h := 20 + 8 * Sin(WorldX * 0.1) + 6 * Cos(WorldZ * 0.12) + 4 * Sin((WorldX + WorldZ) * 0.05);
  Result := Round(h);
  if Result < 2 then Result := 2;
  if Result >= CHUNK_SIZE_Y - 2 then Result := CHUNK_SIZE_Y - 3;
end;

procedure TWorld.EnsureChunkExists(CX, CZ: Integer);
begin
  if FindChunk(CX, CZ) = nil then
    GenerateChunk(CX, CZ);
end;

procedure TWorld.GenerateChunk(CX, CZ: Integer);
var
  Chunk: TChunk;
  lx, ly, lz: Integer;
  wx, wz, h: Integer;
begin
  Chunk := TChunk.Create(CX, CZ);
  for lx := 0 to CHUNK_SIZE_X - 1 do
    for lz := 0 to CHUNK_SIZE_Z - 1 do
    begin
      wx := CX * CHUNK_SIZE_X + lx;
      wz := CZ * CHUNK_SIZE_Z + lz;
      h := GetTerrainHeight(wx, wz);
      for ly := 0 to CHUNK_SIZE_Y - 1 do
      begin
        if ly > h then
          Chunk.Blocks[lx, ly, lz] := 0 // Air
        else if ly = h then
          Chunk.Blocks[lx, ly, lz] := 1 // Grass
        else if ly > h - 4 then
          Chunk.Blocks[lx, ly, lz] := 2 // Dirt
        else
          Chunk.Blocks[lx, ly, lz] := 3; // Stone
      end;
    end;
  FChunks.Add(Chunk);
end;

function TWorld.GetBlock(X, Y, Z: Integer): TBlockID;
var
  CX, CZ: Integer;
  lx, lz: Integer;
  Chunk: TChunk;
begin
  if (Y < 0) or (Y >= CHUNK_SIZE_Y) then Exit(0);

  CX := GetChunkCoord(X, CHUNK_SIZE_X);
  CZ := GetChunkCoord(Z, CHUNK_SIZE_Z);
  lx := X - CX * CHUNK_SIZE_X;
  lz := Z - CZ * CHUNK_SIZE_Z;

  Chunk := FindChunk(CX, CZ);
  if Chunk = nil then
  begin
    EnsureChunkExists(CX, CZ);
    Chunk := FindChunk(CX, CZ);
  end;

  if Assigned(Chunk) then
    Result := Chunk.Blocks[lx, Y, lz]
  else
    Result := 0;
end;

procedure TWorld.SetBlock(X, Y, Z: Integer; Value: TBlockID);
var
  CX, CZ: Integer;
  lx, lz: Integer;
  Chunk: TChunk;
begin
  if (Y < 0) or (Y >= CHUNK_SIZE_Y) then Exit;

  CX := GetChunkCoord(X, CHUNK_SIZE_X);
  CZ := GetChunkCoord(Z, CHUNK_SIZE_Z);
  lx := X - CX * CHUNK_SIZE_X;
  lz := Z - CZ * CHUNK_SIZE_Z;

  Chunk := FindChunk(CX, CZ);
  if Chunk = nil then
  begin
    EnsureChunkExists(CX, CZ);
    Chunk := FindChunk(CX, CZ);
  end;

  if Assigned(Chunk) then
    Chunk.Blocks[lx, Y, lz] := Value;
end;

function TWorld.IsBlockSolid(X, Y, Z: Integer): Boolean;
var
  b: TBlockID;
begin
  b := GetBlock(X, Y, Z);
  Result := (b <> 0) and (b <> Ord(btWater)); // Воздух и вода не твердые
end;

end.
