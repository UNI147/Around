unit uResources;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

// Загружает шрифт из файла
procedure LoadCustomFont(const FontFilePath: string);

implementation

uses
  Windows;

procedure LoadCustomFont(const FontFilePath: string);
begin
  {$IFDEF MSWINDOWS}
  if FileExists(FontFilePath) then
    AddFontResource(PChar(FontFilePath));
  {$ENDIF}
  // Для Linux можно использовать Fontconfig или установить шрифт системно
end;

end.
