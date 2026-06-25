unit uTypes;

{$mode objfpc}{$H+}

interface

uses
  Graphics;

const
  CHUNK_SIZE_X = 16;
  CHUNK_SIZE_Y = 64;
  CHUNK_SIZE_Z = 16;
  BLOCK_SIZE = 8;

type
  TBlockID = Byte;
  // Добавлены Snow, Wood, Leaves
  TBlockType = (btAir=0, btGrass=1, btDirt=2, btStone=3, btSand=4, btWater=5, btSnow=6, btWood=7, btLeaves=8);

function GetBlockColor(b: TBlockID): TColor;

implementation

function GetBlockColor(b: TBlockID): TColor;
begin
  case b of
    1: Result := clGreen;                   // Grass
    2: Result := RGBToColor(139, 90, 43);   // Dirt
    3: Result := clGray;                    // Stone
    4: Result := RGBToColor(238, 214, 175); // Sand
    5: Result := RGBToColor(30, 100, 200);  // Water (сделал чуть темнее для контраста)
    6: Result := clWhite;                   // Snow
    7: Result := RGBToColor(101, 67, 33);   // Wood
    8: Result := RGBToColor(0, 100, 0);     // Leaves
  else
    Result := clBlack;
  end;
end;

end.
