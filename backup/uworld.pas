unit uWorld;
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils, Contnrs, uTypes, uConfig, uNoise, Generics.Collections;

const
  WATER_LEVEL = 24;
  BASE_HEIGHT = 32;
  HEIGHT_VARIATION = 16;

type
  TChunk = class
    Blocks: array[0..CHUNK_SIZE_X-1, 0..CHUNK_SIZE_Y-1, 0..CHUNK_SIZE_Z-1] of TBlockID;
    HeightMap: array[0..CHUNK_SIZE_X-1, 0..CHUNK_SIZE_Z-1] of Integer;
    ChunkX, ChunkZ: Integer;
    constructor Create(AX, AZ: Integer);
  end;

  TChunkMap = specialize TDictionary<Int64, TChunk>;

  TWorld = class
  private
    FChunks: TObjectList;
    FChunkMap: TChunkMap;
  public
    constructor Create;
    destructor Destroy; override;
    function FindChunk(CX, CZ: Integer): TChunk;
    function GetBlock(X, Y, Z: Integer): TBlockID;
    procedure SetBlock(X, Y, Z: Integer; Value: TBlockID);
    function IsBlockSolid(X, Y, Z: Integer): Boolean;
    procedure EnsureChunkExists(CX, CZ: Integer);
    procedure GenerateChunk(CX, CZ: Integer);
  end;

implementation

function ChunkKey(CX, CZ: Integer): Int64; inline;
begin
  Result := (Int64(CX) shl 32) or (CZ and $FFFFFFFF);
end;

// ФУНКЦИЯ ПЕРЕНЕСЕНА СЮДА (она должна быть объявлена ДО GenerateChunk)
function DeterministicRand(x, z, seed: Integer; maxVal: Integer): Integer;
var
  h: Cardinal;
begin
  h := Cardinal(x) * 374761393 + Cardinal(z) * 668265263 + Cardinal(seed) * 2147483647;
  h := (h xor (h shr 13)) * 1274126177;
  Result := Integer(h and $7FFFFFFF) mod maxVal;
end;

constructor TChunk.Create(AX, AZ: Integer);
var
  lx, lz: Integer;
begin
  ChunkX := AX;
  ChunkZ := AZ;
  FillChar(Blocks, SizeOf(Blocks), 0);
  for lx := 0 to CHUNK_SIZE_X - 1 do
    for lz := 0 to CHUNK_SIZE_Z - 1 do
      HeightMap[lx, lz] := -1;
end;

constructor TWorld.Create;
begin
  FChunks := TObjectList.Create(True);
  FChunkMap := TChunkMap.Create;
end;

destructor TWorld.Destroy;
begin
  FChunkMap.Free;
  FChunks.Free;
  inherited;
end;

function TWorld.FindChunk(CX, CZ: Integer): TChunk;
begin
  if not FChunkMap.TryGetValue(ChunkKey(CX, CZ), Result) then
    Result := nil;
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
  wx, wz: Integer;
  baseHeight: Double;
  density: Double;
  caveNoise: Double;
  biomeNoise: Double;
  depth: Integer;
  b: TBlockID;
  // === ДОБАВЛЕНЫ НЕДОСТАЮЩИЕ ПЕРЕМЕННЫЕ ДЛЯ ДЕРЕВЬЕВ И КАМНЕЙ ===
  wy, treeHeight, ty, topY: Integer;
  dy, dx, dz, tx, tz: Integer;
begin
  Chunk := TChunk.Create(CX, CZ);

  // Базовая генерация рельефа
  for lx := 0 to CHUNK_SIZE_X - 1 do
    for lz := 0 to CHUNK_SIZE_Z - 1 do
    begin
      wx := CX * CHUNK_SIZE_X + lx;
      wz := CZ * CHUNK_SIZE_Z + lz;

      biomeNoise := FBm2D(wx * 0.005, wz * 0.005, 3, 0.5, 2.0);
      baseHeight := BASE_HEIGHT + biomeNoise * HEIGHT_VARIATION;
      baseHeight := baseHeight + FBm2D(wx * 0.02, wz * 0.02, 4, 0.5, 2.0) * 6.0;

      for ly := 0 to CHUNK_SIZE_Y - 1 do
      begin
        density := baseHeight - ly;
        density := density + FBm3D(wx * 0.03, ly * 0.03, wz * 0.03, 3, 0.5, 2.0) * 5.0;
        caveNoise := FBm3D(wx * 0.06, ly * 0.06, wz * 0.06, 2, 0.5, 2.0);

        if caveNoise > 0.4 then
          density := density - (caveNoise - 0.4) * 15.0;

        if ly < 2 then
          density := 10.0;

        if density > 0 then
        begin
          depth := Round(density);
          if ly <= WATER_LEVEL + 1 then
          begin
            if depth < 4 then b := Ord(btSand) else b := Ord(btStone);
          end
          else if biomeNoise > 0.3 then
          begin
            if depth = 1 then b := Ord(btSnow)
            else if depth < 4 then b := Ord(btDirt)
            else b := Ord(btStone);
          end
          else if biomeNoise < -0.3 then
          begin
            if depth < 5 then b := Ord(btSand) else b := Ord(btStone);
          end
          else
          begin
            if depth = 1 then b := Ord(btGrass)
            else if depth < 4 then b := Ord(btDirt)
            else b := Ord(btStone);
          end;

          Chunk.Blocks[lx, ly, lz] := b;
          if (b <> Ord(btAir)) and (Chunk.HeightMap[lx, lz] < ly) then
            Chunk.HeightMap[lx, lz] := ly;
        end
        else
        begin
          if ly <= WATER_LEVEL then
            Chunk.Blocks[lx, ly, lz] := Ord(btWater)
          else
            Chunk.Blocks[lx, ly, lz] := Ord(btAir);

          if (ly <= WATER_LEVEL) and (Chunk.HeightMap[lx, lz] < ly) then
            Chunk.HeightMap[lx, lz] := ly;
        end;
      end;
    end;

  // === Генерация деревьев и камней ===
  for lx := 2 to CHUNK_SIZE_X - 3 do
    for lz := 2 to CHUNK_SIZE_Z - 3 do
    begin
      wx := CX * CHUNK_SIZE_X + lx;
      wz := CZ * CHUNK_SIZE_Z + lz;

      wy := Chunk.HeightMap[lx, lz];
      if (wy < 1) or (wy >= CHUNK_SIZE_Y - 8) then Continue;

      b := Chunk.Blocks[lx, wy, lz];

      // Булыжники
      if (DeterministicRand(wx, wz, 1, 100) < 3) and
         (b in [Ord(btGrass), Ord(btDirt), Ord(btSand), Ord(btStone)]) then
      begin
        if (wy + 1 < CHUNK_SIZE_Y) and (Chunk.Blocks[lx, wy + 1, lz] = Ord(btAir)) then
        begin
          Chunk.Blocks[lx, wy + 1, lz] := Ord(btStone);
          if Chunk.HeightMap[lx, lz] < wy + 1 then Chunk.HeightMap[lx, lz] := wy + 1;

          // Шанс второго блока (валун)
          if (DeterministicRand(wx, wz, 4, 100) < 30) and (wy + 2 < CHUNK_SIZE_Y) and
             (Chunk.Blocks[lx, wy + 2, lz] = Ord(btAir)) then
          begin
            Chunk.Blocks[lx, wy + 2, lz] := Ord(btStone);
            if Chunk.HeightMap[lx, lz] < wy + 2 then Chunk.HeightMap[lx, lz] := wy + 2;
          end;
        end;
      end;

      // Деревья
      if (b = Ord(btGrass)) and (DeterministicRand(wx, wz, 2, 100) < 4) then
      begin
        if Chunk.Blocks[lx, wy + 1, lz] <> Ord(btAir) then Continue;

        treeHeight := 4 + DeterministicRand(wx, wz, 3, 2);
        for ty := 1 to treeHeight do
        begin
          if (wy + ty < CHUNK_SIZE_Y) then
          begin
            Chunk.Blocks[lx, wy + ty, lz] := Ord(btWood);
            if Chunk.HeightMap[lx, lz] < wy + ty then
              Chunk.HeightMap[lx, lz] := wy + ty;
          end;
        end;

        topY := wy + treeHeight;
        for dy := -1 to 1 do
          for dx := -2 to 2 do
            for dz := -2 to 2 do
            begin
              if (Abs(dx) = 2) and (Abs(dz) = 2) then Continue;
              tx := lx + dx; tz := lz + dz; ty := topY + dy;

              if (tx >= 0) and (tx < CHUNK_SIZE_X) and (tz >= 0) and (tz < CHUNK_SIZE_Z) and
                 (ty >= 0) and (ty < CHUNK_SIZE_Y) then
              begin
                if Chunk.Blocks[tx, ty, tz] = Ord(btAir) then
                begin
                  Chunk.Blocks[tx, ty, tz] := Ord(btLeaves);
                  if Chunk.HeightMap[tx, tz] < ty then
                    Chunk.HeightMap[tx, tz] := ty;
                end;
              end;
            end;
      end;

  FChunks.Add(Chunk);
  FChunkMap.Add(ChunkKey(CX, CZ), Chunk);
end;

function TWorld.GetBlock(X, Y, Z: Integer): TBlockID;
var
  CX, CZ, lx, lz: Integer;
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
  CX, CZ, lx, lz: Integer;
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
  begin
    Chunk.Blocks[lx, Y, lz] := Value;
    if (Value <> Ord(btAir)) and (Chunk.HeightMap[lx, lz] < Y) then
      Chunk.HeightMap[lx, lz] := Y;
  end;
end;

function TWorld.IsBlockSolid(X, Y, Z: Integer): Boolean;
var
  b: TBlockID;
begin
  b := GetBlock(X, Y, Z);
  // Листва (btLeaves) не должна быть твёрдой, чтобы сквозь неё можно было проходить
  Result := (b <> 0) and (b <> Ord(btWater)) and (b <> Ord(btLeaves));
end;

end.
