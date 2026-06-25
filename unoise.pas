unit uNoise;
{$mode objfpc}{$H+}
interface
uses
Math;
function Noise2D(x, y: Double): Double;
function Noise3D(x, y, z: Double): Double;
function FBm2D(x, y: Double; octaves: Integer; persistence, lacunarity: Double): Double;
function FBm3D(x, y, z: Double; octaves: Integer; persistence, lacunarity: Double): Double;
implementation
function Fade(t: Double): Double; inline;
begin
Result := t * t * t * (t * (t * 6 - 15) + 10);
end;
function Lerp(t, a, b: Double): Double; inline;
begin
Result := a + t * (b - a);
end;
function Dot2D(gx, gy, x, y: Double): Double; inline;
begin
Result := gx * x + gy * y;
end;
function Dot3D(gx, gy, gz, x, y, z: Double): Double; inline;
begin
Result := gx * x + gy * y + gz * z;
end;
function Hash2D(ix, iy: Integer): Cardinal; inline;
var h: Cardinal;
begin
h := Cardinal(ix) * 374761393 + Cardinal(iy) * 668265263;
h := (h xor (h shr 13)) * 1274126177;
Result := h xor (h shr 16);
end;
function Hash3D(ix, iy, iz: Integer): Cardinal; inline;
var h: Cardinal;
begin
h := Cardinal(ix) * 374761393 + Cardinal(iy) * 668265263 + Cardinal(iz) * 1274126177;
h := (h xor (h shr 13)) * 1274126177;
Result := h xor (h shr 16);
end;
procedure RandomGradient2D(ix, iy: Integer; out gx, gy: Double); inline;
var h: Cardinal;
begin
h := Hash2D(ix, iy) and 7;
case h of
0: begin gx := 1; gy := 0; end;
1: begin gx := -1; gy := 0; end;
2: begin gx := 0; gy := 1; end;
3: begin gx := 0; gy := -1; end;
4: begin gx := 1; gy := 1; end;
5: begin gx := -1; gy := 1; end;
6: begin gx := 1; gy := -1; end;
7: begin gx := -1; gy := -1; end;
end;
end;
procedure RandomGradient3D(ix, iy, iz: Integer; out gx, gy, gz: Double); inline;
var h: Cardinal;
begin
h := Hash3D(ix, iy, iz) mod 12;
case h of
0: begin gx := 1; gy := 1; gz := 0; end;
1: begin gx := -1; gy := 1; gz := 0; end;
2: begin gx := 1; gy := -1; gz := 0; end;
3: begin gx := -1; gy := -1; gz := 0; end;
4: begin gx := 1; gy := 0; gz := 1; end;
5: begin gx := -1; gy := 0; gz := 1; end;
6: begin gx := 1; gy := 0; gz := -1; end;
7: begin gx := -1; gy := 0; gz := -1; end;
8: begin gx := 0; gy := 1; gz := 1; end;
9: begin gx := 0; gy := -1; gz := 1; end;
10: begin gx := 0; gy := 1; gz := -1; end;
11: begin gx := 0; gy := -1; gz := -1; end;
end;
end;
function Noise2D(x, y: Double): Double;
var
x0, y0, x1, y1: Integer;
dx0, dy0, dx1, dy1: Double;
gx00, gy00, gx01, gy01, gx10, gy10, gx11, gy11: Double;
n00, n01, n10, n11: Double;
u, v: Double;
begin
x0 := Floor(x); y0 := Floor(y);
x1 := x0 + 1; y1 := y0 + 1;
dx0 := x - x0; dy0 := y - y0;
dx1 := x - x1; dy1 := y - y1;
RandomGradient2D(x0, y0, gx00, gy00);
RandomGradient2D(x0, y1, gx01, gy01);
RandomGradient2D(x1, y0, gx10, gy10);
RandomGradient2D(x1, y1, gx11, gy11);
n00 := Dot2D(gx00, gy00, dx0, dy0);
n01 := Dot2D(gx01, gy01, dx0, dy1);
n10 := Dot2D(gx10, gy10, dx1, dy0);
n11 := Dot2D(gx11, gy11, dx1, dy1);
u := Fade(dx0);
v := Fade(dy0);
Result := Lerp(v, Lerp(u, n00, n10), Lerp(u, n01, n11));
end;
function Noise3D(x, y, z: Double): Double;
var
x0, y0, z0, x1, y1, z1: Integer;
dx0, dy0, dz0, dx1, dy1, dz1: Double;
gx000, gy000, gz000, gx001, gy001, gz001: Double;
gx010, gy010, gz010, gx011, gy011, gz011: Double;
gx100, gy100, gz100, gx101, gy101, gz101: Double;
gx110, gy110, gz110, gx111, gy111, gz111: Double;
n000, n001, n010, n011, n100, n101, n110, n111: Double;
u, v, w: Double;
i1, i2: Double;
begin
x0 := Floor(x); y0 := Floor(y); z0 := Floor(z);
x1 := x0 + 1; y1 := y0 + 1; z1 := z0 + 1;
dx0 := x - x0; dy0 := y - y0; dz0 := z - z0;
dx1 := x - x1; dy1 := y - y1; dz1 := z - z1;
RandomGradient3D(x0, y0, z0, gx000, gy000, gz000);
RandomGradient3D(x0, y0, z1, gx001, gy001, gz001);
RandomGradient3D(x0, y1, z0, gx010, gy010, gz010);
RandomGradient3D(x0, y1, z1, gx011, gy011, gz011);
RandomGradient3D(x1, y0, z0, gx100, gy100, gz100);
RandomGradient3D(x1, y0, z1, gx101, gy101, gz101);
RandomGradient3D(x1, y1, z0, gx110, gy110, gz110);
RandomGradient3D(x1, y1, z1, gx111, gy111, gz111);
n000 := Dot3D(gx000, gy000, gz000, dx0, dy0, dz0);
n001 := Dot3D(gx001, gy001, gz001, dx0, dy0, dz1);
n010 := Dot3D(gx010, gy010, gz010, dx0, dy1, dz0);
n011 := Dot3D(gx011, gy011, gz011, dx0, dy1, dz1);
n100 := Dot3D(gx100, gy100, gz100, dx1, dy0, dz0);
n101 := Dot3D(gx101, gy101, gz101, dx1, dy0, dz1);
n110 := Dot3D(gx110, gy110, gz110, dx1, dy1, dz0);
n111 := Dot3D(gx111, gy111, gz111, dx1, dy1, dz1);
u := Fade(dx0);
v := Fade(dy0);
w := Fade(dz0);
i1 := Lerp(v, Lerp(u, n000, n100), Lerp(u, n010, n110));
i2 := Lerp(v, Lerp(u, n001, n101), Lerp(u, n011, n111));
Result := Lerp(w, i1, i2);
end;
function FBm2D(x, y: Double; octaves: Integer; persistence, lacunarity: Double): Double;
var
i: Integer;
amplitude, frequency, maxVal, total: Double;
begin
total := 0; frequency := 1.0; amplitude := 1.0; maxVal := 0;
for i := 0 to octaves - 1 do
begin
total := total + Noise2D(x * frequency, y * frequency) * amplitude;
maxVal := maxVal + amplitude;
amplitude := amplitude * persistence;
frequency := frequency * lacunarity;
end;
Result := total / maxVal;
end;
function FBm3D(x, y, z: Double; octaves: Integer; persistence, lacunarity: Double): Double;
var
i: Integer;
amplitude, frequency, maxVal, total: Double;
begin
total := 0; frequency := 1.0; amplitude := 1.0; maxVal := 0;
for i := 0 to octaves - 1 do
begin
total := total + Noise3D(x * frequency, y * frequency, z * frequency) * amplitude;
maxVal := maxVal + amplitude;
amplitude := amplitude * persistence;
frequency := frequency * lacunarity;
end;
Result := total / maxVal;
end;
end.
