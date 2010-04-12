uses

  XTypes,Objects,GView,Tools;

var
  T:TSystem;
  P:PWindow;
  R:TRect;
begin
  T.Init;
  R.Assign(0,0,320,200);
  New(P,Init(R,'Hello World (Alt-X to exit)'));
  P^.Options := P^.Options or Ocf_Centered;
  T.Insert(P);
  T.Run;
  T.Done;
end.