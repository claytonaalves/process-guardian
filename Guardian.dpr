program Guardian;

uses
  SysUtils,
  Windows;

  procedure RunProgram(ProgramPath: String);
  var
     StartupInfo: TStartupInfo;
     ProcessInformation: TProcessInformation;
  begin
     FillChar(StartupInfo, SizeOf(StartupInfo), 0);

     with StartupInfo do begin
        cb := SizeOf(TStartupInfo);
        wShowWindow := SW_HIDE;
     end;

     if CreateProcess(nil, pchar(ProgramPath), nil, nil, true, CREATE_NO_WINDOW, nil, nil, StartupInfo, ProcessInformation) then begin
        WaitForSingleObject(ProcessInformation.hProcess, INFINITE);
        CloseHandle(ProcessInformation.hProcess);
        CloseHandle(ProcessInformation.hThread);
     end else begin
       RaiseLastOSError;
     end;
  end;

  procedure WriteToEventLog(AMessage: String);
  var
     EventHandle: THandle;
  begin
     EventHandle := RegisterEventSource(nil, PChar('Guardian'));
     if EventHandle=0 then Exit;
     try
        ReportEvent(EventHandle, 1, 0, 0, nil, 1, 0, @AMessage, nil);
     finally
        DeregisterEventSource(EventHandle);
     end;
  end;

var
  ActiveWindow: HWnd;
  ProgramPath: String;

begin
   ActiveWindow := GetActiveWindow;
   if ParamCount<2 then begin
      MessageBox(ActiveWindow, PChar('You have to informe the program path as first argument'), PChar('Error'), MB_ICONERROR );
      Exit;
   end;
   ProgramPath := ParamStr(1);
   while True do begin
      RunProgram(ProgramPath);
      WriteToEventLog('Restarting ' + ProgramPath);
   end;
end.
