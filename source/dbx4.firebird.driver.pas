unit dbx4.firebird.driver;

interface

uses Classes, DBXCommon, DBXPlatform, firebird.client, dbx4.base, dbx4.firebird.base;

type
  TDBXDriver_Firebird = class(TDBXBase, IDBXDriver, IDBXDriver_Firebird)
  private
    FHandle: THandle;
    FVendorLib: WideString;
    FPath: IInterface;
    procedure LoadDriver;
  protected
    function Close: TDBXErrorCode; override;
    function GetErrorMessage(LastErrorCode: TDBXErrorCode; ErrorMessage:
        TDBXWideStringBuilder): TDBXErrorCode; override;
    function GetErrorMessageLength(LastErrorCode: TDBXErrorCode; out ErrorLen:
        TInt32): TDBXErrorCode; override;
    function Loaded: boolean;
    function NewLibrary: IFirebirdLibrary;
  public
    constructor Create(const Count: TInt32; Names, Values: TWideStringArray);
  end;

implementation

uses SysUtils, Windows;

function TDBXDriver_Firebird.Close: TDBXErrorCode;
var F: string;
    i: integer;
    h: THandle;
begin
  Sleep(1); {$Message 'In firebird embedded, this delay will make the FreeLibrary safer and won't cause unexpected error for massive LoadLibrary / FreeLibrary calls'}

  SetLength(F, 1000);
  i := GetModuleFileName(FHandle, PChar(F), 1000);
  Assert(i > 0);
  SetLength(F, i);

  if not FreeLibrary(FHandle) then
    Result := TDBXErrorCodes.DriverInitFailed
  else begin
    {$Message 'Firebird bug: http://tracker.firebirdsql.org/browse/CORE-2186'}
    h := GetModuleHandle(PChar(ExtractFilePath(F) + 'intl\fbintl.dll'));
    if h <> 0 then
      FreeLibrary(h);
    Result := TDBXErrorCodes.None;
  end;

  FPath := nil;
end;

constructor TDBXDriver_Firebird.Create(const Count: TInt32; Names,
  Values: TWideStringArray);
var i: integer;
begin
  inherited Create;
  for i := 0 to Count - 1 do begin
    if Names[i] = TDBXPropertyNames.VendorLib then
      FVendorLib := Values[i];
  end;
  LoadDriver;
end;

function TDBXDriver_Firebird.GetErrorMessage(LastErrorCode: TDBXErrorCode;
    ErrorMessage: TDBXWideStringBuilder): TDBXErrorCode;
begin
  Result := TDBXErrorCodes.None;
end;

function TDBXDriver_Firebird.GetErrorMessageLength(LastErrorCode:
    TDBXErrorCode; out ErrorLen: TInt32): TDBXErrorCode;
begin
  Result := TDBXErrorCodes.None;
end;

function TDBXDriver_Firebird.Loaded: boolean;
begin
  Result := FHandle <> 0;
end;

function TDBXDriver_Firebird.NewLibrary: IFirebirdLibrary;
begin
  Result := TFirebirdLibraryFactory.New(FHandle);
end;

procedure TDBXDriver_Firebird.LoadDriver;
var sDir: string;
    V: string;
var H: THandle;
    putenv: function(estr: PAnsiChar): integer; cdecl;
    S: string;
begin
  FPath := TFirebirdLibraryRootPath.CreateFromLibrary(FVendorLib);

  sDir := GetCurrentDir;
  try
    SetCurrentDir(ExtractFilePath(FVendorLib));
    V := FVendorLib;
    FHandle := LoadLibrary(PChar(V));
  finally
    SetCurrentDir(sDir);
  end;
end;

end.
