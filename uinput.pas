unit uInput;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLType;

type
  TInput = class
  private
    FLeft, FRight, FUp, FDown, FJump: Boolean;
  public
    procedure KeyDown(Key: Word);
    procedure KeyUp(Key: Word);
    property Left: Boolean read FLeft;
    property Right: Boolean read FRight;
    property Up: Boolean read FUp;
    property Down: Boolean read FDown;
    property Jump: Boolean read FJump;
  end;

implementation

procedure TInput.KeyDown(Key: Word);
begin
  case Key of
    VK_LEFT, Ord('A'): FLeft := True;
    VK_RIGHT, Ord('D'): FRight := True;
    VK_UP, Ord('W'): FUp := True;
    VK_DOWN, Ord('S'): FDown := True;
    VK_SPACE: FJump := True;
  end;
end;

procedure TInput.KeyUp(Key: Word);
begin
  case Key of
    VK_LEFT, Ord('A'): FLeft := False;
    VK_RIGHT, Ord('D'): FRight := False;
    VK_UP, Ord('W'): FUp := False;
    VK_DOWN, Ord('S'): FDown := False;
    VK_SPACE: FJump := False;
  end;
end;

end.
