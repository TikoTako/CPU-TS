library dllversion;

function LocalFree(hMem: THandle): THandle; stdcall; external 'kernel32.dll' name 'LocalFree';
procedure OutputDebugString(lpOutputString: PWideChar); stdcall; external 'kernel32.dll' name 'OutputDebugStringW';
//
function PowerGetActiveScheme(UserRootPowerKey: UIntPtr; var ActivePolicyGuid: PGUID): Cardinal; stdcall; external 'PowrProf.dll';
function PowerWriteACValueIndex(UserRootPowerKey: UIntPtr; const SchemeGuid, SubGroupOfPowerSettingsGuid, PowerSettingGuid: PGUID; AcValueIndex: Cardinal): Cardinal; stdcall; external 'PowrProf.dll';
function PowerWriteDCValueIndex(UserRootPowerKey: UIntPtr; const SchemeGuid, SubGroupOfPowerSettingsGuid, PowerSettingGuid: PGUID; DcValueIndex: Cardinal): Cardinal; stdcall; external 'PowrProf.dll';
function PowerSetActiveScheme(UserRootPowerKey: UIntPtr; const SchemeGuid: PGUID): Cardinal; stdcall; external 'PowrProf.dll';

{ Copypasta from delphi units }
const
  TwoDigitLookup : packed array[0..99] of array[1..2] of Char =
    ('00','01','02','03','04','05','06','07','08','09',
     '10','11','12','13','14','15','16','17','18','19',
     '20','21','22','23','24','25','26','27','28','29',
     '30','31','32','33','34','35','36','37','38','39',
     '40','41','42','43','44','45','46','47','48','49',
     '50','51','52','53','54','55','56','57','58','59',
     '60','61','62','63','64','65','66','67','68','69',
     '70','71','72','73','74','75','76','77','78','79',
     '80','81','82','83','84','85','86','87','88','89',
     '90','91','92','93','94','95','96','97','98','99');

function DivBy100(i: Cardinal): Cardinal;
{$IF Defined(WIN32) and Defined(ASSEMBLER) and Defined(CPUX86)}
asm
        MOV     ECX, 1374389535 // 1/100 * 2^(32+5)
        MUL     ECX
        MOV     EAX, EDX
        SHR     EAX, 5
end;
{$ELSEIF Defined(WIN64) and Defined(ASSEMBLER) and Defined(CPUX64)}
asm
        MOV     EAX, ECX
        IMUL    RAX, RAX, 1374389535
        SHR     RAX, 37
end;
{$ELSE}
inline;
begin
  Result := i div 100;
end;
{$ENDIF}

function _IntToStr32(Value: Cardinal; Negative: Boolean): string;
var
  I, K: Cardinal;
  Digits: Integer;
  P: PChar;
begin
  I := Value;
  if I >= 10000 then
    if I >= 1000000 then
      if I >= 100000000 then
        Digits := 9 + Byte(Ord(I >= 1000000000))
      else
        Digits := 7 + Byte(Ord(I >= 10000000))
    else
      Digits := 5 + Byte(Ord(I >= 100000))
  else
    if I >= 100 then
      Digits := 3 + Byte(Ord(I >= 1000))
    else
      Digits := 1 + Byte(Ord(I >= 10));
  SetLength(Result, Digits + Ord(Negative));
  P := Pointer(Result);
  P^ := '-';
  Inc(P, Ord(Negative));
  while Digits > 1 do
  begin
    K := I;
    I := DivBy100(I);
    Dec(K, I * 100);
    Dec(Digits, 2);
    PCardinal(@P[Digits])^ := Cardinal(TwoDigitLookup[K]);
  end;
  if Digits <> 0 then
    P^ := Char(I or Ord('0'));
end;

{ End Of Copypasta from delphi units }

function PrintR(s: PWideChar; r: Cardinal): Cardinal;
begin
  result := r;
  if r = 0 then
    OutputDebugString(PWideChar(s + ' ok'))
  else
    OutputDebugString(PWideChar(s + ' fail [' + _IntToStr32(r, false) + ']'))
end;

const
  GUID_PROCESSOR_SETTINGS_SUBGROUP: TGuid = '{54533251-82be-4824-96c1-47b60b740d00}';
  GUID_PROCESSOR_THROTTLE_MAXIMUM: TGuid = '{bc5038f7-23e0-4960-96da-33abaf5935ec}';
  GUID_PROCESSOR_THROTTLE_MINIMUM: TGuid = '{893dee8e-2bef-41e0-89c6-b55d0929964c}';

procedure SetSpeedPercent(percent: Cardinal); stdcall;
var
  ptrActiveGuid: PGUID;
begin
  ptrActiveGuid := nil;
  if PrintR('Get', PowerGetActiveScheme(0, ptrActiveGuid)) = 0 then
    try
      PrintR('AC min', PowerWriteACValueIndex(0, ptrActiveGuid, @GUID_PROCESSOR_SETTINGS_SUBGROUP, @GUID_PROCESSOR_THROTTLE_MINIMUM, percent));
      PrintR('AC max', PowerWriteACValueIndex(0, ptrActiveGuid, @GUID_PROCESSOR_SETTINGS_SUBGROUP, @GUID_PROCESSOR_THROTTLE_MAXIMUM, percent));
      PrintR('Set', PowerSetActiveScheme(0, ptrActiveGuid));
    finally
      LocalFree(THandle(ptrActiveGuid));
    end;
end;

exports SetSpeedPercent;

begin
  OutputDebugString(PWideChar('Y HALO THAR'));

end.
