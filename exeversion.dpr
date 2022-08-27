program exeversion;

{$APPTYPE CONSOLE}
{$R *.res}
function LocalFree(hMem: THandle): THandle; stdcall; external 'kernel32.dll' name 'LocalFree';

function PowerGetActiveScheme(UserRootPowerKey: UIntPtr; var ActivePolicyGuid: PGUID): Cardinal; stdcall; external 'PowrProf.dll';
function PowerWriteACValueIndex(UserRootPowerKey: UIntPtr; const SchemeGuid, SubGroupOfPowerSettingsGuid, PowerSettingGuid: PGUID; AcValueIndex: Cardinal): Cardinal; stdcall; external 'PowrProf.dll';
function PowerWriteDCValueIndex(UserRootPowerKey: UIntPtr; const SchemeGuid, SubGroupOfPowerSettingsGuid, PowerSettingGuid: PGUID; DcValueIndex: Cardinal): Cardinal; stdcall; external 'PowrProf.dll';
function PowerReadACValueIndex(UserRootPowerKey: UIntPtr; const SchemeGuid, SubGroupOfPowerSettingsGuid, PowerSettingGuid: PGUID; var AcValueIndex: Cardinal): Cardinal; stdcall; external 'PowrProf.dll';
function PowerReadDCValueIndex(UserRootPowerKey: UIntPtr; const SchemeGuid, SubGroupOfPowerSettingsGuid, PowerSettingGuid: PGUID; var DcValueIndex: Cardinal): Cardinal; stdcall; external 'PowrProf.dll';
function PowerSetActiveScheme(UserRootPowerKey: UIntPtr; const SchemeGuid: PGUID): Cardinal; stdcall; external 'PowrProf.dll';

function PrintR(s: string; r: Cardinal): Cardinal;
begin
  result := r;
  if r = 0 then
    writeln(s, ' ok')
  else
    writeln(s, ' fail [', r, ']');
end;

var
  vPGuid: PGUID;
  vDummy: string;
  vValueR, vValueW: Cardinal;

const
  GUID_PROCESSOR_SETTINGS_SUBGROUP: TGuid = '{54533251-82be-4824-96c1-47b60b740d00}';
  GUID_PROCESSOR_THROTTLE_MAXIMUM: TGuid = '{bc5038f7-23e0-4960-96da-33abaf5935ec}';
  GUID_PROCESSOR_THROTTLE_MINIMUM: TGuid = '{893dee8e-2bef-41e0-89c6-b55d0929964c}';

begin
  // i did this because i need only min and max set to 1 or 100
  // if you need to set AC/DC and min/max at different values you should use
  // the paramstr values
  // something like
  // exeversion.exe -ACmin 50 -ACmax 100 -DCmin 25 -DCmax 50
  // then
  // check paramcount mod 2
  // start with i=1
  // check paramstr(i) = one of -ACmin..-DCmax then the paramstr(i+1) to get the value
  // inc i by 2, check if hit paramcount if not repeat
  if paramcount < 1 then
  begin
    writeln('Settin MaX');
    vValueW := 100
  end
  else
  begin
    writeln('SETTIN MIN');
    vValueW := 1;
  end;

  try
    begin
      vPGuid := nil;
      if PrintR('Get', PowerGetActiveScheme(0, vPGuid)) = 0 then
        try
          PrintR('Read AC min', PowerReadACValueIndex(0, vPGuid, @GUID_PROCESSOR_SETTINGS_SUBGROUP, @GUID_PROCESSOR_THROTTLE_MINIMUM, vValueR));
          writeln('Current value > ', vValueR);
          PrintR('Read AC max', PowerReadACValueIndex(0, vPGuid, @GUID_PROCESSOR_SETTINGS_SUBGROUP, @GUID_PROCESSOR_THROTTLE_MAXIMUM, vValueR));
          writeln('Current value > ', vValueR);
          PrintR('Read DC min', PowerReadDCValueIndex(0, vPGuid, @GUID_PROCESSOR_SETTINGS_SUBGROUP, @GUID_PROCESSOR_THROTTLE_MINIMUM, vValueR));
          writeln('Current value > ', vValueR);
          PrintR('Read DC max', PowerReadDCValueIndex(0, vPGuid, @GUID_PROCESSOR_SETTINGS_SUBGROUP, @GUID_PROCESSOR_THROTTLE_MAXIMUM, vValueR));
          writeln('Current value > ', vValueR);

          PrintR('Write AC min', PowerWriteACValueIndex(0, vPGuid, @GUID_PROCESSOR_SETTINGS_SUBGROUP, @GUID_PROCESSOR_THROTTLE_MINIMUM, vValueW));
          PrintR('Write AC max', PowerWriteACValueIndex(0, vPGuid, @GUID_PROCESSOR_SETTINGS_SUBGROUP, @GUID_PROCESSOR_THROTTLE_MAXIMUM, vValueW));
          PrintR('Write DC min', PowerWriteDCValueIndex(0, vPGuid, @GUID_PROCESSOR_SETTINGS_SUBGROUP, @GUID_PROCESSOR_THROTTLE_MINIMUM, vValueW));
          PrintR('Write DC max', PowerWriteDCValueIndex(0, vPGuid, @GUID_PROCESSOR_SETTINGS_SUBGROUP, @GUID_PROCESSOR_THROTTLE_MAXIMUM, vValueW));
          PrintR('Set', PowerSetActiveScheme(0, vPGuid));
        finally
          LocalFree(THandle(vPGuid));
        end;
    end;
  except
    writeln('some error');
  end;
  writeln('Press enter to exit.');
  writeln('DABUMTHSSS.webm');
  readln(vDummy);

end.
