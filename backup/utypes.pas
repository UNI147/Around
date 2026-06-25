unit uTypes;

{$mode objfpc}{$H+}

interface

uses
  Graphics;

const
  CHUNK_SIZE_X = 16;
  CHUNK_SIZE_Y = 64;
  CHUNK_SIZE_Z = 16;
  BLOCK_SIZE = 8; // Размер одного блока в пикселях на экране

type
  TBlockID = Byte;

  // 0: Air, 1: Grass, 2: Dirt, 3: Stone, 4: Sand, 5: Water
  TBlockType = (btAir=0, btGrass=1, btDirt=2, btStone=3, btSand=4, btWater=5);

function GetBlockColor(b: TBlockID): TColor;

implementation

function GetBlockColor(b: TBlockID): TColor;
begin
  case b of
    1: Result := clGreen;
    2: Result := RGBToColor(139, 90, 43); // Dirt
    3: Result := clGray;                  // Stone
    4: Result := RGBToColor(238, 214, 175); // Sand
    5: Result := clBlue;                  // Water
    else Result := clBlack;
  end;
end;

end.
