unit uResources;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, LCLType;

const
  // Размеры виртуального окна (вьюпорта)
  VIEW_WIDTH  = 320;
  VIEW_HEIGHT = 200;

  // Параметры мира
  WORLD_SIZE           = 400;
  NUM_TERRAIN_POINTS   = 1500;
  NUM_CLOUDS           = 30;

  // Параметры игрока
  PLAYER_GRAVITY     = 600.0;
  PLAYER_JUMP_SPEED  = 350.0;
  PLAYER_MOVE_SPEED  = 150.0;

  // Интервал таймера (в миллисекундах)
  TIMER_INTERVAL = 30;
  // Шаг времени для обновления (сек)
  DT = 0.03;

  // Имя шрифта для интерфейса (должен быть установлен в системе)
  // Для использования GothicRus.ttf из ресурсов см. процедуру LoadCustomFont
  FONT_NAME = 'GothicRus';

// Опционально: если шрифт нужно загрузить из файла (например, для Windows)
procedure LoadCustomFont(const FontFilePath: string);

implementation

uses
  Windows; // для AddFontResource

procedure LoadCustomFont(const FontFilePath: string);
begin
  {$IFDEF MSWINDOWS}
  // Добавляем шрифт в систему (временная установка)
  if FileExists(FontFilePath) then
    AddFontResource(PChar(FontFilePath));
  {$ENDIF}
  // Для Linux можно использовать Fontconfig или другие методы,
  // но проще установить шрифт в систему заранее.
end;

end.
