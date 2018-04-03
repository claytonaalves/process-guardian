program Guardian;

{$mode objfpc}{$H+}

uses UGuardian;

{$R *.res}

var
   Application: TGuardian;

begin
   Application := TGuardian.Create(nil);
   Application.Title := 'Process Guardian';
   Application.Run;
   Application.Free;
end.

