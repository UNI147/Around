unit uTypes;

{$mode objfpc}{$H+}

interface

uses Graphics;

type
  TTerrainPoint = record
    X, Z: Double;
    Color: TColor;
  end;

  TCloud = record
    X, Y, Z: Double;
    Width, Height: Integer;
  end;

implementation

end.
