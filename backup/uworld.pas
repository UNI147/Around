unit uWorld;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, LCLType, uTypes;

const
  WORLD_SIZE = 400;
  NUM_TERRAIN_POINTS = 1500;
  NUM_CLOUDS = 30;

type
  TWorld = class
  public
    Terrain: array of TTerrainPoint;
    Clouds: array of TCloud;
    constructor Create;
    procedure Generate;
  end;

implementation

constructor TWorld.Create;
begin
  Generate;
end;

procedure TWorld.Generate;
var
  i: Integer;
begin
  Randomize;
  SetLength(Terrain, NUM_TERRAIN_POINTS);
  for i := 0 to NUM_TERRAIN_POINTS - 1 do
  begin
    Terrain[i].X := (Random - 0.5) * WORLD_SIZE;
    Terrain[i].Z := (Random - 0.5) * WORLD_SIZE;
    Terrain[i].Color := LCLType.RGB(0, 64 + Round(Random * 128), 0); // явное указание модуля
  end;

  SetLength(Clouds, NUM_CLOUDS);
  for i := 0 to NUM_CLOUDS - 1 do
  begin
    Clouds[i].X := (Random - 0.5) * WORLD_SIZE;
    Clouds[i].Y := 60 + Random * 80;
    Clouds[i].Z := (Random - 0.5) * WORLD_SIZE;
    Clouds[i].Width := 30 + Round(Random * 60);
    Clouds[i].Height := 10 + Round(Random * 20);
  end;
end;

end.
