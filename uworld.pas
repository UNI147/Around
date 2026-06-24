unit uWorld;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, LCLType, uTypes, uConfig;

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
  worldSize: Double;
begin
  Randomize;
  worldSize := Config.WorldSize;
  SetLength(Terrain, Config.TerrainPoints);
  for i := 0 to Config.TerrainPoints - 1 do
  begin
    Terrain[i].X := (Random - 0.5) * worldSize;
    Terrain[i].Z := (Random - 0.5) * worldSize;
    Terrain[i].Color := RGBToColor(0, 64 + Round(Random * 128), 0);
  end;

  SetLength(Clouds, Config.CloudCount);
  for i := 0 to Config.CloudCount - 1 do
  begin
    Clouds[i].X := (Random - 0.5) * worldSize;
    Clouds[i].Y := 60 + Random * 80;
    Clouds[i].Z := (Random - 0.5) * worldSize;
    Clouds[i].Width := 30 + Round(Random * 60);
    Clouds[i].Height := 10 + Round(Random * 20);
  end;
end;

end.
