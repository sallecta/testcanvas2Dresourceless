unit BGRAUnits;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, BGRABitmapTypes;

type
  TCSSUnit = (cuCustom, cuPixel,
              cuCentimeter, cuMillimeter,
              cuInch, cuPica, cuPoint,
              cuFontEmHeight, cuFontXHeight, cuPercent);
  TFloatWithCSSUnit = record
    value: single;
    CSSUnit: TCSSUnit;
  end;

function FloatWithCSSUnit(AValue: single; AUnit: TCSSUnit): TFloatWithCSSUnit;

const
  CSSUnitShortName: array[TCSSUnit] of string =
        ('','px',
         'cm','mm',
         'in','pc','pt',
         'em','ex','%');

type
  { TCSSUnitConverter }

  TCSSUnitConverter = class
  protected
    function GetDefaultUnitHeight: TFloatWithCSSUnit; virtual;
    function GetDefaultUnitWidth: TFloatWithCSSUnit; virtual;
    function GetDpiScaleTransform: string;
    function GetDpiX: single; virtual;
    function GetDpiY: single; virtual;
    function GetDPIScaled: boolean; virtual;
    function GetDpiScaleX: single; virtual;
    function GetDpiScaleY: single; virtual;
    function GetFontEmHeight: TFloatWithCSSUnit; virtual;
    function GetFontXHeight: TFloatWithCSSUnit; virtual;
    property FontEmHeight: TFloatWithCSSUnit read GetFontEmHeight;
    property FontXHeight: TFloatWithCSSUnit read GetFontXHeight;
    property DefaultUnitWidth: TFloatWithCSSUnit read GetDefaultUnitWidth;
    property DefaultUnitHeight: TFloatWithCSSUnit read GetDefaultUnitHeight;
  public
    function Convert(xy: single; sourceUnit, destUnit: TCSSUnit; dpi: single; containerSize: single = 0): single;
    function ConvertWidth(x: single; sourceUnit, destUnit: TCSSUnit; containerWidth: single = 0): single; overload;
    function ConvertHeight(y: single; sourceUnit, destUnit: TCSSUnit; containerHeight: single = 0): single; overload;
    function ConvertWidth(AValue: TFloatWithCSSUnit; destUnit: TCSSUnit; containerWidth: single = 0): TFloatWithCSSUnit; overload;
    function ConvertHeight(AValue: TFloatWithCSSUnit; destUnit: TCSSUnit; containerHeight: single = 0): TFloatWithCSSUnit; overload;
    function ConvertCoord(pt: TPointF; sourceUnit, destUnit: TCSSUnit; containerWidth: single = 0; containerHeight: single = 0): TPointF; virtual;
    class function parseValue(AValue: string; ADefault: TFloatWithCSSUnit): TFloatWithCSSUnit; overload;
    class function parseValue(AValue: string; ADefault: single): single; overload;
    class function formatValue(AValue: TFloatWithCSSUnit; APrecision: integer = 7): string; overload;
    class function formatValue(AValue: single; APrecision: integer = 7): string; overload;
    property DpiX: single read GetDpiX;
    property DpiY: single read GetDpiY;
    property DpiScaled: boolean read GetDPIScaled;
    property DpiScaleX: single read GetDpiScaleX;
    property DpiScaleY: single read GetDpiScaleY;
    property DpiScaleTransform: string read GetDpiScaleTransform;
  end;

implementation

var
  formats: TFormatSettings;

const InchFactor: array[TCSSUnit] of integer =
      (9600, 9600,
       254, 2540,
       100, 600, 7200,
       0, 0, 0);

function FloatWithCSSUnit(AValue: single; AUnit: TCSSUnit): TFloatWithCSSUnit;
begin
  result.value:= AValue;
  result.CSSUnit:= AUnit;
end;

{ TCSSUnitConverter }

function TCSSUnitConverter.GetDpiScaleX: single;
begin
  result := 1;
end;

function TCSSUnitConverter.GetDpiScaleY: single;
begin
  result := 1;
end;

function TCSSUnitConverter.GetFontEmHeight: TFloatWithCSSUnit;
begin
  result := FloatWithCSSUnit(0,cuCustom);
end;

function TCSSUnitConverter.GetFontXHeight: TFloatWithCSSUnit;
begin
  result := FloatWithCSSUnit(0,cuCustom);
end;

function TCSSUnitConverter.GetDPIScaled: boolean;
begin
  result := false;
end;

function TCSSUnitConverter.GetDpiScaleTransform: string;
begin
  result := 'scale('+formatValue(DpiScaleX)+','+
           formatValue(DpiScaleY)+')';
end;

function TCSSUnitConverter.GetDefaultUnitHeight: TFloatWithCSSUnit;
begin
  result := FloatWithCSSUnit(1,cuPixel);
end;

function TCSSUnitConverter.GetDefaultUnitWidth: TFloatWithCSSUnit;
begin
  result := FloatWithCSSUnit(1,cuPixel);
end;

function TCSSUnitConverter.GetDpiX: single;
begin
  result := 96;
end;

function TCSSUnitConverter.GetDpiY: single;
begin
  result := 96;
end;

function TCSSUnitConverter.Convert(xy: single; sourceUnit, destUnit: TCSSUnit;
  dpi: single; containerSize: single): single;
var sourceFactor, destFactor: integer;
begin
  //fallback values for cuCustom as pixels
  if sourceUnit = cuCustom then sourceUnit := cuPixel;
  if destUnit = cuCustom then destUnit := cuPixel;
  if (sourceUnit = destUnit) then
    result := xy
  else
  if sourceUnit = cuPercent then
  begin
    result := xy/100*containerSize;
  end else
  if sourceUnit = cuFontEmHeight then
  begin
    with FontEmHeight do result := Convert(xy*value,CSSUnit, destUnit, dpi);
  end else
  if sourceUnit = cuFontXHeight then
  begin
    with FontXHeight do result := Convert(xy*value,CSSUnit, destUnit, dpi);
  end else
  if destUnit = cuFontEmHeight then
  begin
    with FontEmHeight do
      if value = 0 then result := 0
      else result := Convert(xy/value,sourceUnit, CSSUnit, dpi);
  end else
  if destUnit = cuFontEmHeight then
  begin
    with FontXHeight do
      if value = 0 then result := 0
      else result := Convert(xy/value,sourceUnit, CSSUnit, dpi);
  end else
  if sourceUnit = cuPixel then
  begin
    if dpi = 0 then result := 0
    else result := xy*(InchFactor[sourceUnit]/(dpi*100));
  end else
  if destUnit = cuPixel then
  begin
    if dpi = 0 then result := 0
    else result := xy*((dpi*100)/InchFactor[sourceUnit]);
  end else
  begin
    sourceFactor := InchFactor[sourceUnit];
    destFactor := InchFactor[destUnit];
    if (sourceFactor = 0) or (destFactor = 0) then
      result := 0
    else
      result := xy*(destFactor/sourceFactor);
  end;
end;

function TCSSUnitConverter.ConvertWidth(x: single; sourceUnit,
  destUnit: TCSSUnit; containerWidth: single): single;
begin
  if sourceUnit = destUnit then
    result := x
  else if sourceUnit = cuCustom then
  with DefaultUnitWidth do
  begin
    result := x*ConvertWidth(value,CSSUnit, destUnit, containerWidth)
  end
  else if destUnit = cuCustom then
  with ConvertWidth(DefaultUnitWidth,sourceUnit) do
  begin
    if value = 0 then
      result := 0
    else
      result := x/value;
  end else
    result := Convert(x, sourceUnit, destUnit, DpiX, containerWidth);
end;

function TCSSUnitConverter.ConvertHeight(y: single; sourceUnit,
  destUnit: TCSSUnit; containerHeight: single): single;
begin
  if sourceUnit = cuCustom then
  with DefaultUnitHeight do
  begin
    result := y*ConvertHeight(value,CSSUnit, destUnit, containerHeight)
  end
  else if destUnit = cuCustom then
  with ConvertHeight(DefaultUnitHeight,sourceUnit) do
  begin
    if value = 0 then
      result := 0
    else
      result := y/value;
  end else
    result := Convert(y, sourceUnit, destUnit, DpiY, containerHeight);
end;

function TCSSUnitConverter.ConvertWidth(AValue: TFloatWithCSSUnit;
  destUnit: TCSSUnit; containerWidth: single): TFloatWithCSSUnit;
begin
  result.CSSUnit := destUnit;
  result.value:= ConvertWidth(AValue.value,AValue.CSSUnit,destUnit,containerWidth);
end;

function TCSSUnitConverter.ConvertHeight(AValue: TFloatWithCSSUnit;
  destUnit: TCSSUnit; containerHeight: single): TFloatWithCSSUnit;
begin
  result.CSSUnit := destUnit;
  result.value:= ConvertHeight(AValue.value,AValue.CSSUnit,destUnit,containerHeight);
end;

function TCSSUnitConverter.ConvertCoord(pt: TPointF; sourceUnit,
  destUnit: TCSSUnit; containerWidth: single; containerHeight: single): TPointF;
begin
  result.x := ConvertWidth(pt.x, sourceUnit, destUnit, containerWidth);
  result.y := ConvertHeight(pt.y, sourceUnit, destUnit, containerHeight);
end;

class function TCSSUnitConverter.parseValue(AValue: string;
  ADefault: TFloatWithCSSUnit): TFloatWithCSSUnit;
var cssUnit: TCSSUnit;
  errPos: integer;
begin
  AValue := trim(AValue);
  result.CSSUnit:= cuCustom;
  for cssUnit := succ(cuCustom) to high(cssUnit) do
    if (length(AValue)>=length(CSSUnitShortName[cssUnit])) and
     (CompareText(copy(AValue,length(AValue)-length(CSSUnitShortName[cssUnit])+1,length(CSSUnitShortName[cssUnit])),
        CSSUnitShortName[cssUnit])=0) then
    begin
      AValue := copy(AValue,1,length(AValue)-length(CSSUnitShortName[cssUnit]));
      result.CSSUnit := cssUnit;
      break;
    end;
  val(AValue,result.value,errPos);
  if errPos <> 0 then
    result := ADefault;
end;

class function TCSSUnitConverter.parseValue(AValue: string; ADefault: single): single;
var
  errPos: integer;
begin
  AValue := trim(AValue);
  val(AValue,result,errPos);
  if errPos <> 0 then
    result := ADefault;
end; 

class function TCSSUnitConverter.formatValue(AValue: TFloatWithCSSUnit; APrecision: integer = 7): string;
begin
  result := FloatToStrF(AValue.value,ffGeneral,APrecision,0,formats)+CSSUnitShortName[AValue.CSSUnit];
end;

class function TCSSUnitConverter.formatValue(AValue: single; APrecision: integer
  ): string;
begin
  result := FloatToStrF(AValue,ffGeneral,APrecision,0,formats);
end;

initialization

  formats := DefaultFormatSettings;
  formats.DecimalSeparator := '.';

end.

