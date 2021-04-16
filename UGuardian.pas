unit UGuardian;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, CustApp, contnrs, process, IniFiles, Pipes;

type

  { TCustomProcess }

  TCustomProcess = class(TProcess)
  private
    FCheckNetwork: Boolean;
    FFailedRetries: Integer;
    FRetries: Integer;
  public
    property Retries: Integer read FRetries write FRetries;
    property FailedRetries: Integer read FFailedRetries write FFailedRetries;
    property CheckNetwork: Boolean read FCheckNetwork write FCheckNetwork;
  end;

  { TGuardian }

  TGuardian = class(TCustomApplication)
  private
    ProcessList: TObjectList;
    function CreateProcess(SectionName: String; Config: TIniFile): TCustomProcess;
    function InternetAvailable: Boolean;
    procedure LoadProcessDefinitions;
    procedure RunMain;
    procedure StartProcess(AProcess: TCustomProcess);
    procedure LogStdErr(AProcess: TCustomProcess);
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;

    procedure WriteHelp; virtual;
  end;

implementation

uses wininet;

{ TGuardian }

constructor TGuardian.Create(TheOwner: TComponent);
begin
   inherited Create(TheOwner);
   StopOnException := True;
   ProcessList := TObjectList.Create;
end;

destructor TGuardian.Destroy;
begin
   ProcessList.Free;
   inherited Destroy;
end;

procedure TGuardian.WriteHelp;
begin
   writeln('Usage: ', ExeName, ' -h');
end;

procedure TGuardian.DoRun;
var ErrorMsg: String;
begin
   ErrorMsg := CheckOptions('h', 'help');
   if ErrorMsg <> '' then begin
      ShowException(Exception.Create(ErrorMsg));
      Terminate;
      Exit;
   end;

   if HasOption('h', 'help') then begin
      WriteHelp;
      Terminate;
      Exit;
   end;

   RunMain;

   Terminate;
end;

procedure TGuardian.RunMain;
var
   i: Integer;
   Process: TCustomProcess;
begin
   LoadProcessDefinitions;
   while True do begin
      for i := 0 to ProcessList.Count - 1 do begin
         Process := TCustomProcess(ProcessList.Items[i]);
         if not Process.Running then begin
            StartProcess(Process);
         end;
      end;
      Sleep(1000);
   end;
end;

procedure TGuardian.StartProcess(AProcess: TCustomProcess);
begin
   if (AProcess.CheckNetwork) and (not InternetAvailable) then
      Exit;

   if (AProcess.Retries > 0) and (AProcess.FailedRetries >= AProcess.Retries) then
      Exit;

   try
      AProcess.Execute;
   except
     on E: EProcess do begin
        AProcess.FailedRetries := AProcess.FailedRetries + 1;
     end;
   end;

   if not AProcess.Running then begin
      LogStdErr(AProcess);
   end;
end;

procedure TGuardian.LogStdErr(AProcess: TCustomProcess);
var AStringList: TStringList;
begin
   AStringList := TStringList.Create;
   AStringList.LoadFromStream(AProcess.Stderr);
   AStringList.SaveToFile(AProcess.Name + '_stderr.log');
   AStringList.Free;
end;

procedure TGuardian.LoadProcessDefinitions;
var
  i: Integer;
  ini: TIniFile;
  Sections: TStrings;
  Process: TProcess;
begin
   Sections := TStringList.Create;
   ini := TIniFile.Create('guardian.ini');
   try
      ini.ReadSections(Sections);
      for i := 0 to Sections.Count -1 do begin
         Process := CreateProcess(Sections.Strings[i], ini);
         ProcessList.Add(Process);
      end;
   finally
     ini.Free;
     Sections.Free;
   end;
end;

function TGuardian.CreateProcess(SectionName: String; Config: TIniFile): TCustomProcess;
var Process: TCustomProcess;
begin
   Process := TCustomProcess.Create(nil);
   Process.Name := SectionName;
   Process.Options := [poNoConsole, poUsePipes];
   Process.Executable := Config.ReadString(SectionName, 'command', '');
   Process.Parameters.Delimiter := ' ';
   Process.Parameters.DelimitedText := Config.ReadString(SectionName, 'params', '');
   Process.CurrentDirectory := Config.ReadString(SectionName, 'working-dir', '.');
   Process.CheckNetwork := Config.ReadBool(SectionName, 'check-network', false);
   Process.Retries := Config.ReadInteger(SectionName, 'retries', 0);
   Result := Process;
end;

function TGuardian.InternetAvailable: Boolean;
begin
   Result := InternetCheckConnection('http://www.google.com', FLAG_ICC_FORCE_CONNECTION, 0);
end;

end.

(*

TODO:
  - add parameter to define log generation
  - add parameter to generate config file

*)
