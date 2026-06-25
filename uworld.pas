unit uWorld;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, Contnrs, uTypes, uConfig, uNoise;

const
  WATER_LEVEL = 24;
  BASE_HEIGHT = 32;
  HEIGHT_VARIATION = 16;

type
  TChunk = class
    Blocks: array[0..CHUNK_SIZE_X-1, 0..CHUNK_SIZE_Y-1, 0..CHUNK_SIZE_Z-1] of TBlockID;
    ChunkX, ChunkZ: Integer;
    constructor Create(AX, AZ: Integer);
  end;

  TWorld = class
  private
    FChunks: TObjectList;
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
  FChunks := TObjectList.Create(True);
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
begin
  Chunk := TChunk.Create(CX, CZ);
  for lx := 0 to CHUNK_SIZE_X - 1 do
    for lz := 0 to CHUNK_SIZE_Z - 1 do
    begin
      wx := CX * CHUNK_SIZE_X + lx;
      wz := CZ * CHUNK_SIZE_Z + lz;

      // 1. Генерация биома и базовой высоты (2D fBm)
      biomeNoise := FBm2D(wx * 0.005, wz * 0.005, 3, 0.5, 2.0); // Значения от -1 до 1
      baseHeight := BASE_HEIGHT + biomeNoise * HEIGHT_VARIATION;
      // Добавляем мелкие детали рельефа
      baseHeight := baseHeight + FBm2D(wx * 0.02, wz * 0.02, 4, 0.5, 2.0) * 6.0;

      for ly := 0 to CHUNK_SIZE_Y - 1 do
      begin
        // 2. Вычисление 3D плотности
        density := baseHeight - ly;
        // Добавляем 3D шум для создания неровностей, арок и нависаний
        density := density + FBm3D(wx * 0.03, ly * 0.03, wz * 0.03, 3, 0.5, 2.0) * 5.0;

        // 3. Вырезание пещер (3D fBm)
        caveNoise := FBm3D(wx * 0.06, ly * 0.06, wz * 0.06, 2, 0.5, 2.0);
        // Если шум превышает порог, мы вычитаем его из плотности, образуя полость
        if caveNoise > 0.4 then
          density := density - (caveNoise - 0.4) * 15.0;

        // Бедрок на самом дне
        if ly < 2 then
          density := 10.0;

        // 4. Определение типа блока
        if density > 0 then
        begin
          depth := Round(density);
          if ly <= WATER_LEVEL + 1 then
          begin
            // Пляж у воды
            if depth < 4 then b := Ord(btSand)
            else b := Ord(btStone);
          end
          else if biomeNoise > 0.3 then
          begin
            // Снежный биом (горы)
            if depth = 1 then b := Ord(btSnow)
            else if depth < 4 then b := Ord(btDirt)
            else b := Ord(btStone);
          end
          else if biomeNoise < -0.3 then
          begin
            // Пустынный биом
            if depth < 5 then b := Ord(btSand)
            else b := Ord(btStone);
          end
          else
          begin
            // Обычные равнины
            if depth = 1 then b := Ord(btGrass)
            else if depth < 4 then b := Ord(btDirt)
            else b := Ord(btStone);
          end;
          Chunk.Blocks[lx, ly, lz] := b;
        end
        else
        begin
          // Воздух или Вода
          if ly <= WATER_LEVEL then
            Chunk.Blocks[lx, ly, lz] := Ord(btWater)
          else
            Chunk.Blocks[lx, ly, lz] := Ord(btAir);
        end;
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
  Result := (b <> 0) and (b <> Ord(btWater));
end;

end.
