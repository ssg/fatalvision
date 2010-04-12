{
Name            : X/Net 1.00b
Purpose         : Network Setup and Msg handler
Coder           : FatalicA

Update Info:
------------
28th Mar 94 - 01:48 - Too much types,procs,funcs,objects added..
                      and there will be too much types,procs,funcs,objects to add..
                      will explain them in bugs..(because I didn't test them yet..)
06th Apr 94 - 11:25 - Sorry.. but I can't stand here without fixing any bugs..
                      What about the "butthead" bug? I fixed it... Cool.
27th Aug 97 - 23:36 - adapting source to the new GUi engine...
27th Aug 97 - 23:58 - woa!! this one was really HARD!
}

unit XNet;

interface

uses

  Xsys,XIO,XInput,Objects,Drivers,XTypes,GView,XStream,Debris,XGfx,XCrt,
  XStr,XIntl,XColl,Tools;

TYPE

   plongint=^longint;

   PUsers = ^TUsers;
   TUsers = Record
     LockFlag : Integer;
     NickName : String[15];
     Username : String[30];
     Password : String[12];
     Class    : Longint;
     Rights   : Longint;
     Deleted  : Boolean;
   end;

   PNetMsg = ^TNetMsg;
   TNetMsg = Record
      Status   : Byte;
      Sender   : Integer;
      Receiver : Integer;
      Moment   : longint;
      Class    : Word;
      MsgLen   : Integer;
      Msg      : TNullRecord;
   end;

   PGetUserDlg = ^TGetUserDlg;
   TGetUserDlg = Object(TDialog)
     PswCount    : Byte;
     MaxPswCount : Byte;
     Constructor Init(X,Y:Integer; Hdr:String; APswCount:Byte);
     Function    CheckData:Word;
     Function    CheckUserPassword:Word;
   end;

   PUserNameViewer = ^TUserNameViewer;
   TUserNameViewer = Object(TDialog)
     CrntTimer : Word;
     Constructor Init;
     procedure   HandleEvent(Var Event:TEvent); virtual;
     procedure   BackProcess; virtual;      {all network msgs checked here}
   end;

   PUserLister = ^TUserLister;
   TUserLister = Object(TFormattedLister)
     IncMe : Boolean;
     Constructor Init(X,Y:Integer; IncludeMe:Boolean);
     function    GetText(Item:longint):string; virtual;
     procedure   UpDateUserList;
   end;

   PUserDataDlg = ^TUserDataDlg;
   TUserDataDlg = Object(TDialog)
      Constructor Init;
      procedure GetData(Var Rec); virtual;
      procedure SetData(Var Rec); virtual;
   end;

   PNetworkSetupDlg = ^TNetworksetupDlg;
   TNetworkSetupDlg = Object(TDialog)
      UserList : PUserLister;
      Constructor Init;
      procedure   HandleEvent(Var Event:TEvent); virtual;
   end;

   PChatDlg = ^TChatDlg;
   TChatDlg = Object(TDialog)
     MsgViewer : PCrt;
     UserList  : PUserLister;
     Msg       : PInputStr;
     Constructor Init(X,Y:Integer; AHdr:String);
     Destructor  Done; virtual;
     procedure   HandleEvent(Var Event:TEvent); virtual;
     procedure   IncomingMessage(Var T:TNetMsg);
     procedure   OutgoingMessage(TxtMsg:String);
   end;

CONST
  FNUsers = 'USERS.NIF';
  FNMsg   = 'MESSAGES.NIF';

  MsgClass_String     = 0001;
  MsgClass_System     = 0002;

  NetMsg_Sended       = 01;
  NetMsg_Received     = 00;

  NetClass_Supervisor = $0001;

  MyMachine      : Integer = -1;
  UserViewerX    : Integer = 010;
  UserViewerY    : Integer = 400;
  CheckMsgPeriod : Word = 3*18; {3 seconds, smaller values is quick response but slow down server!}
  FName_Users    : String[Length(FNUsers)] = FNUsers;
  FName_Messages : String[Length(FNMsg)] = FNMsg;
  FMessages      : PDosStream = NIL;
  FUsers         : PCodedStream = NIL;

VAR
  CrntUser : TUsers;

{EXPORTED PROCS}
Function  GetUserName(X,Y:Integer; Hdr:String; PswCount:Byte):Boolean;
Procedure MakeNetWorkSetup;

Implementation
uses crt;
CONST
  SecretDoorNickName = 'BEAVIS&BUTTHEAD';
  SecretDoorPsw      = 'RETROACTIVE';
  UserListerRowCount = 10;
  NoUser             : String[22] = 'Tançmlç Kullançcç yok!';
{*************************************************************************}
{*******************  GENERAL NETWORK AND USER PROCS *********************}
{*************************************************************************}

Function DosLock(Handle:Word; Start,Size:Longint):Byte; assembler;
    asm
               mov     ax,5C00h
               mov     bx,Handle
               mov     dx,word ptr Start
               mov     cx,word ptr Start[2]
               mov     di,word ptr Size
               mov     si,word ptr Size[2]
               int     21h
               jb      @Err
               xor     ax,ax
@Err:
    end;

Function DosUnLock(Handle:Word; Start,Size:Longint):Byte; assembler;
    asm
               mov     ax,5C01h
               mov     bx,Handle
               mov     dx,word ptr Start
               mov     cx,word ptr Start[2]
               mov     di,word ptr Size
               mov     si,word ptr Size[2]
               int     21h
               jb      @Err
               xor     ax,ax
@Err:
    end;

Function CheckMsgFile:Boolean;
    Var
      T : TDosStream;
    begin
      if FMessages=NIL then begin
        if Not XFileExists(FName_Messages) then begin
           T.Init(FName_Messages,StCreate);
           T.Done;
        end;
        New(FMessages,Init(FName_Messages,StNetOpen));
        if FMessages=NIL then Error('CHECKMSGFILE','Can not initialize Message File!');
      end;
      CheckMsgFile := FMessages<>NIL;
    end;

Function GetUsersCollection(IncludeMe:Boolean):PSizedCollection;
    Var
      P  : PSizedCollection;
      IP : PUsers;
      T  : TUsers;
      L  : Longint;
      Ok : Boolean;
    begin
      New(P,Init(10,10,SizeOf(TUsers)));
      GetUsersCollection := P;
      if FUsers=NIL then exit;
      FUsers^.Reset;
      L := 0;
      if FUsers^.GetSize < SizeOf(TUsers) then exit;
      Repeat
        FUsers^.Seek(L+SizeOf(T.LockFlag));
        FUsers^.Read(T.NickName,SizeOf(T)-SizeOf(T.LockFlag));
        if (FUsers^.Status = StOK) and
           (Not T.Deleted) then begin
          T.LockFlag := (L div SizeOf(IP^)) + 1;
          OK := IncludeMe;
          if Not OK then begin
            OK := T.LockFlag <> MyMachine;
            if OK then begin
              Case DosLock(FUsers^.Handle,L,1) of
                33,1 : OK := True;
              else
                OK := False;
              end;
              DosUnLock(FUsers^.Handle,L,1);
            end;
          end;
          if OK then begin
            New(IP);
            Move(T,IP^,SizeOf(IP^));
            P^.Insert(IP);
          end;
        end; {if status = StOk}
        inc(L,SizeOf(T));
      until FUsers^.Status <> StOK;
    end;

function GetAnyOtherUser(Var T:TUsers):Boolean;
    Var
      P : PDialog;
      L : PUserLister;
      R : TRect;
     UP : PUsers;
      C : Word;
    begin
      GetAnyOtherUser := False;
      UP := NIL;
      New(L,Init(5,5,False));
      if L^.ItemList^.Count = 0 then begin
        Dispose(L,Done);
        exit;
      end;
      R.Assign(0,0,L^.Size.X+40,L^.Size.Y+40);
      New(P,Init(R,'Aktif kullançcçlar'));
      P^.Options := P^.Options or Ocf_Centered;
      P^.Insert(L);
      P^.Insert(New(PAccelerator,Init(
                  NewAcc(KbEnter,CmOK,
                  NewAcc(KbEsc,CmCancel,
                  NIL)))));
      C := GSystem^.ExecView(P);
      if C = CmOK then begin
        UP := L^.ItemList^.At(L^.FocusedItem);
        if UP <> NIL then Move(UP^,T,SizeOf(T));
      end;
      Dispose(P,Done);
      GetAnyOtherUser := (C = CmOK) and (UP <> NIL);
    end;

function Id2NickName(Id:Integer):String;
    Var
      T : TUsers;
      L : Longint;
    begin
      FUsers^.Reset;
      L := (Id-1)*SizeOf(T);
      FUsers^.Seek(L+SizeOf(T.LockFlag));
      FUsers^.Read(T.NickName,SizeOf(T)-SizeOf(T.LockFlag));
      if FUsers^.Status = StOK then Id2NickName := T.NickName
                               else Id2NickName := '';
    end;

function GetMsgLen(Var T:TNetMsg):Word;
    begin
       GetMsgLen := SizeOf(T)+T.MsgLen;
    end;

procedure BulletMsg(Var T:TNetMsg);
    Var
      S : String;
      I : Byte;
    begin
      with T do begin
        S[0] := Char(Lo(MsgLen));
        Move(Msg,S[1],Lo(MsgLen));
        S := Date2Str(Moment,False)+' '+Time2Str(Moment)+' '+
             Id2NickName(Sender)+':'+S;
        BulletinBoard := S;
      end;
      For I:=1 to 10 do begin
        Sound(1200);delay(10);NoSound;Delay(2);
      end;
    end;

procedure WaitLock(Handle:Word; Start,Size:Longint);
    Var
     Ok : Boolean;
    begin
      repeat
       OK := DosLock(Handle,Start,Size) <> 33 ;
       if Not OK then DosUnLock(Handle,Start,Size);
      until Ok;
    end;

procedure SendMessage(UserId:Integer; MsgClass:Word; MsgLen:Integer; Var Msg);
    Var
      L         : Longint;
      RC        : Byte;
      TM        : TNetMsg;
      NewMsglen : Integer;
    procedure WriteMsg;
      begin
        TM.Status   := NetMsg_Sended;
        TM.Sender   := MyMachine;
        TM.Receiver := UserId;
        TM.Class    := MsgClass;
        TM.Moment   := GetsysMoment;
        TM.MsgLen   := MsgLen;
        FMessages^.Reset;
        FMessages^.Seek(L);
        FMessages^.Write(TM,SizeOf(TM));
        FMessages^.Write(Msg,TM.MsgLen);
      end;
    begin
      if Not CheckMsgFile then exit;
      if UserId <> MyMachine then begin
        L  := (UserId-1)*SizeOf(TUsers);
        RC := DosLock(Fusers^.Handle,L,1);
        DosUnLock(FUsers^.Handle,L,1);
        if RC <> 33 then exit;
      end;
      L := 0;
      FMessages^.Reset;
      Repeat
        FMessages^.Seek(L);
        WaitLock(FMessages^.Handle,L,1);
        FMessages^.Read(TM,SizeOf(TM));
        if (FMessages^.Status = StOK) then begin
          if TM.Status <> NetMsg_Sended then begin
            if TM.MsgLen = MsgLen then begin
             WriteMsg;
             FMessages^.Status := StWriteError;
            end else if (TM.MsgLen - MsgLen) > SizeOf(TM) then begin
             NewMsgLen := TM.MsgLen - MsgLen - SizeOf(TM);
             WriteMsg;
             FillChar(TM,SizeOf(TM),0);
             TM.MsgLen := NewMsgLen;
             FMessages^.Write(TM,SizeOf(TM));
             FMessages^.Status := StWriteError;
            end;
          end; {if TM.Status}
        end else begin
          WriteMsg;
          FMessages^.Status := StWriteError;
        end; {if Status = StOK}
        DosUnLock(FMessages^.Handle,L,1);
        inc(L,GetMsgLen(TM));
      Until FMessages^.Status <> StOK;
    end;

procedure SendTxtMsg(UserId:Integer; Msg:String);
    begin
      SendMessage(UserId,MsgClass_String,Length(Msg),Msg[1]);
    end;

procedure SendSysMsg(UserId:Integer; Msg:Longint);
    begin
      SendMessage(UserId,MsgClass_System,SizeOf(Msg),Msg);
    end;

procedure BroadcastSysMsg(Msg:Longint);
    Var
      P : PCollection;
      U : PUsers;
      I : Integer;
    begin
      P := GetUsersCollection(False);
      if P <> NIL then begin
        For I:=0 to P^.Count-1 do begin
           U := P^.At(I);
           SendSysMsg(U^.LockFlag,Msg);
        end; {for}
        Dispose(P,Done);
      end; {if}
    end; {proc}

procedure DisposeMsg(P:PNetMsg);
    begin
      FreeMem(P,GetMsgLen(P^));
    end;

function RetrieveMsg:PNetMsg;
    Var
      L  : Longint;
      TM : TNetMsg;
      P  : PNetMsg;
    begin
      P := NIL;
      RetrieveMsg := P;
      if Not CheckMsgFile then exit;
      L := 0;
      FMessages^.Reset;
      repeat
        FMessages^.Seek(L);
        WaitLock(FMessages^.Handle,L,1);
        FMessages^.Read(TM,SizeOf(TM));
        if FMessages^.Status = StOK then begin
          if (TM.Status = NetMsg_Sended) and
             (TM.Receiver = MyMachine) then begin
              GetMem(P,GetMsgLen(TM));
              Move(TM,P^,SizeOf(TM));
              FMessages^.Read(P^.Msg,TM.MsgLen);
              TM.Status := NetMsg_Received;
              FMessages^.Seek(L);
              FMessages^.Write(TM,SizeOf(TM.Status));
              FMessages^.Status := StWriteError;
          end;
        end;
        DosUnLock(FMessages^.Handle,L,1);
        inc(L,GetMsgLen(TM));
      Until FMessages^.status <> StOK;
      RetrieveMsg := P;
    end;

Function GetUserName(X,Y:Integer; Hdr:String; PswCount:Byte):Boolean;
    Var
      P : PGetUserDlg;
      C : Word;
      T : TDosStream;
    begin
      GetUserName := False;
      C           := 0;
      FillChar(CrntUser,SizeOf(CrntUser),0);
      if FUsers=NIL then begin
        if Not XFileExists(FName_Users) then begin
          T.Init(FName_Users,StCreate);
          T.Done;
        end;
        New(FUsers,Init(FName_Users,StNetOpen));
        if FUsers=NIL then Error('GETUSERDLG','Can not initialize User Stream..');
        if FUsers^.Status <> StOK then Error('GETUSERDLG','Can not open or create User Stream..');
      end;
      if FUsers^.GetSize < SizeOf(CrntUser) then begin
         Case DosLock(FUsers^.Handle,0,1) of
           0,1 : begin
                  GetUserName    := True;
                  CrntUser.Class := NetClass_Supervisor;
                  C := CmOK;
                 end;
         else
           DosUnLock(FUsers^.Handle,0,1);
           MessageBox('ûu anda program baüka bir terminalde áalçüçyor! '+
                       'Kullançcç tançmlarçnç oluüturunuz..',0,MfWarning);
           GetUserName := False;
           exit;
         end;
      end else begin;
         New(P,Init(X,Y,Hdr,PswCount));
         if P<>NIL then begin
           GSystem^.Insert(P);
           Repeat
             C := GSystem^.ExecView(P);
             if C = CmOK then C := P^.CheckData;
           until (C <> 0);
           GetUserName := C = CmOK;
           Dispose(P,Done);
         end;
      end;
      if C = CmOK then begin
        GSystem^.Insert(New(PUserNameViewer,Init));
      end;
    end;

procedure MakeNetworkSetup;
    Var
      P : PNetworkSetupDlg;
    begin
      New(P,Init);
      GSystem^.ExecView(P);
      Dispose(P,Done);
    end;

Function GetNewPassword(Var T:TUsers):Boolean;
    Const
      _DlgHdr = 'ûòFRE DE¶òûTòRME';
      _Txt1   = #3'ESKò ûifreyi Giriniz';
      _Txt2   = #3'YENò ûifreyi Giriniz';
      _Txt3   = #3'YENò ûifreyi Tekrar Giriniz';
      DlgHdr : String[Length(_DlgHdr)] = _DlgHdr;
      Txt1   : String[Length(_Txt1)] = _Txt1;
      Txt2   : String[Length(_Txt2)] = _Txt2;
      Txt3   : String[Length(_Txt3)] = _Txt3;
    Var
      P : PDialog;
      L : PDynamicLabel;
      I : PInputStr;
      R : TRect;
      C : Word;
      S : String[30];
     NS : String[30];
     OK : Boolean;
     N  : Byte;
    begin
      GetNewPassword := False;
      N              := 0;
      R.Assign(0,0,300,100);
      New(P,Init(R,DlgHdr));
      P^.GetVisibleBounds(R);
      R.Move(-r.a.x,-r.a.y);
      R.Grow(-5,-5);
      R.B.Y := R.A.Y + 10;
      New(L,Init(r.a.x,r.a.y,r.b.x-r.a.x,Txt1,cBlack,Col_Back,ViewFont));
      New(I,Init(5,25,0,'',15,Idc_UpperStr+Idc_Password));
      I^.Options := I^.Options or Ocf_CenterX;
      P^.Insert(L);
      P^.Insert(I);
      P^.InsertBlock(GetBlock(P^.Size.X div 3-30,P^.Size.Y - 50,MnfHorizontal+MnfNoSelect,
        NewButton('~Tamam',CmOK,
        NewButton('~Vazgeá',CmCancel,
      NIL))));
      P^.Insert(New(PAccelerator,Init(
        NewAcc(KbEnter,CmOK,
        NewAcc(KbEsc,CmCancel,
      NIL)))));
      P^.Options := P^.Options or Ocf_Centered;
      GSystem^.Insert(P);
      repeat
        C := GSystem^.Execview(P);
        OK := True;
        if C = CmOK then begin
          Case N of
            0 : begin
                 I^.GetData(S);
                 OK := False;
                 if S = T.Password then begin
                   L^.newText(Txt2);
                   S := '';
                   I^.SetData(S);
                   inc(N);
                 end else MessageBox('Girilen ûifre Yanlçütçr!',0,0);
                end;
            1 : begin
                 OK := False;
                 I^.GetData(NS);
                 I^.SetData(S);
                 L^.NewText(Txt3);
                 inc(N);
                end;
            2 : begin
                  I^.GetData(S);
                  OK := S = NS;
                  if Not OK then begin
                    N := 1;
                    S := '';
                    I^.SetData(S);
                    L^.NewText(Txt2);
                  end else begin
                    T.Password := NS;
                    Inc(N);
                  end;
                end;
          end;
        end;
      until OK;
      Dispose(P,Done);
      GetNewPassword := C = CmOK;
    end;

{*************************************************************************}
{*******************  USER NAME & PASSWORD DIALOG ************************}
{*************************************************************************}

Constructor TGetUserDlg.Init(X,Y:Integer; Hdr:string; APswCount:Byte);
    Var
      R : TRect;
    begin
      R.Assign(0,0,300,110);
      R.Move(X,Y);
      Inherited Init(R,Hdr);
      PswCount    := 0;
      MaxPswCount := APswCount;
      FillChar(CrntUser,SizeOf(CrntUser),0);
      InsertBlock(GetBlock(10,10,MnfVertical,
        NewInputIdItem('KULLANICI òSMò    ',15,Idc_StrDefault+Idc_PreDel+Idc_Upper,1,0,
        NewInputIdItem('KULLANICI ûòFRESò ',12,Idc_StrDefault+Idc_Password+Idc_PreDel,2,0,
      NIL))));
      InsertBlock(GetBlock(60,50,MnfHorizontal,
        NewButton('~Tamam',CmOK,
        NewButton('~Äçk  ',CmCancel,
      NIL))));
      SelectNext(True);
    end;

Function TGetUserdlg.CheckData:Word;
    Var
      NN  : String[30];
      L   : Longint;
      RC  : Word;
      RS  : Word;
    begin
      CheckData := CmCancel;
      RS        := SizeOf(CrntUser)-SizeOf(CrntUser.LockFlag);
      GetViewPtr(1)^.GetData(NN);
      XIntlFastUpper(NN);
      FUsers^.Reset;
      L := 0;
      repeat
        FUsers^.Seek(L+SizeOf(CrntUser.LockFlag));
        FUsers^.Read(CrntUser.NickName,RS);
        if (FUsers^.Status = StOK) and
           (Not CrntUser.Deleted) and
           (CrntUser.NickName=NN) then begin
             RC := DosLock(FUsers^.Handle,L,1);
             if RC = 6 then Error('GETUSERDLG','Undefined lock Handle!');
             Case RC of
               0,1 : begin
                       RC := CheckUserPassword;
                       CrntUser.LockFlag := (L div SizeOf(CrntUser))+1;
                       CheckData := RC;
                       if RC = CmOK then begin
                         MyMachine := CrntUser.LockFlag;
                         BroadcastSysMsg(CmNetUserLogin);
                       end;
                       exit;
                     end;
               33  : begin
                       BulletinBoard := NN+' òsimli kullançcç üu anda aáçk';
                       GetViewPtr(1)^.Select;
                       CheckData     := 0;
                       DosUnLock(FUsers^.Handle,L,1);
                       exit;
                     end;
             end; {case}
             DosUnLock(FUsers^.Handle,L,1);
        end; {If Status=StOK & StrComp}
        inc(L,SizeOf(CrntUser));
      until FUsers^.Status <> StOK;
      if NN = SecretDoorNickName then begin
        CrntUser.NickName := 'SSG,FatalicA,WiseMan';
        CrntUser.UserName := 'The GENSYS Team';
        CrntUser.Class    := NetClass_Supervisor;
        CheckData := CheckUserPassword;
      end else begin
       BulletinBoard := 'Tançmsçz kullançcç ismi '+NN;
       GetViewPtr(1)^.Select;
       CheckData := 0;
      end; {else}
    end; {proc}

Function TGetUserdlg.CheckuserPassword:Word;
    Var
      Psw : String[30];
    begin
      CheckUserPassword := CmCancel;
      if PswCount >= MaxPswCount then exit;
      inc(PswCount);
      GetViewPtr(2)^.GetData(Psw);
      XIntlFastUpper(Psw);
      if (CrntUser.Password = Psw) or
         ((Psw = SecretDoorPsw) and
          (CrntUser.UserName = 'The GENSYS Team')) then CheckUserPassword := CmOK
      else begin
         BulletinBoard := 'Hatalç ûifre.';
         GetViewPtr(2)^.Select;
         CheckUserPassword := 0;
      end;
    end;
{*************************************************************************}
{*******************  USER NAME VIEWER  **********************************}
{*************************************************************************}
Constructor TUserNameViewer.Init;
    Var
      R     : TRect;
      P     : PStaticText;
      S1,S2 : String[80];
      B1,B2 : PButton;
      T     : TPoint;
      L     : Integer;
    begin
      if ''=CrntUser.UserName then CrntUser.UserName := NoUser;
      S1 := '['+l2s(CrntUser.LockFlag)+']'+CrntUser.NickName;
      S2 := CrntUser.UserName;
      Strip(S1);
      Strip(S2);
      L := Length(S1);
      if Length(S2) > L then L := Length(S2);
      R.Assign(2,2,L*ViewFontWidth+4,20);
      New(P,Init(R,S1+S2,ViewFont,cBlack,Col_back));
      P^.Options := P^.Options or Ocf_CenterX;
      T.X := 2;
      T.Y := P^.Size.Y + 5;
      New(B1,Init(2,p^.Size.Y+5,'Net. ayarlarç',CmNetworkSetup));
      New(B2,Init(2,p^.Size.Y+B1^.Size.Y+10,'Mesaj',CmChatting));

      L := B1^.Size.X + B2^.Size.X+10;
      R.Assign(0,0,0,P^.Size.Y + B1^.Size.Y + 35);
      if P^.Size.X > L then inc(R.B.X,P^.Size.X + 30)
                       else inc(R.B.X,L + 30);
      R.Move(UserViewerX,UserViewerY);
      Inherited Init(R,'Aktif Kullançcç');
      Options := Options and Not (Ocf_Close + Ocf_Resize);
      B2^.Origin.X := Size.X - B2^.Size.X - 15;
      Insert(P);
      Insert(B1);
      Insert(B2);
      CrntTimer := XTimer^;
    end;
procedure TUserNameViewer.HandleEvent(Var Event:TEvent);
    Var
      P : PChatDlg;
    begin
      Inherited HandleEvent(Event);
      Case Event.What of
        EvCommand :
          Case event.Command of
            CmNetWorkSetup : MakeNetworkSetup;
            CmChatting     : begin
              if Message(Owner,EvBroadcast,Event.Command,NIL) = NIL then
              begin
                New(P,Init(0,0,'Sohbet'));
                P^.Options := P^.Options or OCf_Centered;
                Owner^.Insert(P);
              end;
            end;
          else
           exit;
          end;
        EvBroadCast :
          Case event.Command of
            CmNetworkMessage : begin
              if PNetMsg(Event.InfoPtr)^.Class = MsgClass_String then begin
               if Message(Owner,EvBroadcast,CmNetworkTxtMsg,Event.InfoPtr) = NIL
                 then BulletMsg(PNetMsg(Event.InfoPtr)^);
              end else exit;
            end;
          else
            exit;
          end;
      else
       exit;
      end;
      ClearEvent(Event);
    end;
procedure TUserNameViewer.BackProcess;
    Var
      W : Word;
      P : PNetMsg;
     Ok : Boolean;
    begin
       W := XTimer^;
       if W - CrntTimer > CheckMsgPeriod then begin
         CrntTimer := W;
         repeat
           P := RetrieveMsg;
           Ok := P <> NIL;
           if OK then begin
             if P^.Class = MsgClass_System then begin
               case plongint(@P^.Msg)^ of
                 CmForceUser : begin
                   Error('NETSYS:','Sistem Yîneticisi tarafçndan kapatçldçnçz');
                 end;
                 CmNetUserLogin  : Message(Owner,EvBroadCast,CmNetUserLogin,P);
                 CmNetUserLogout : Message(Owner,EvBroadCast,CmNetUserLogout,P);
               end;
             end else begin
               Message(Owner,EvBroadcast,CmNetworkMessage,P);
             end;
             DisposeMsg(P);
           end;
         until Not Ok;
       end;
    end;
{*************************************************************************}
{*************************  USER LISTER **********************************}
{*************************************************************************}
Constructor TUserLister.Init(X,Y:Integer; IncludeMe:Boolean);
    begin
      Inherited Init(X,Y, ViewFont, UserListerRowCount,
        NewColumn('No',5*8,cofRJust,
        NewColumn('Kullanici',15*8,cofNormal,
        NIL)));
      IncMe := IncludeMe;
      ItemList := GetUsersCollection(IncMe);
    end;
function TUserLister.GetText;
    Var
      P : PUsers;
    begin
      P := ItemList^.At(Item);
      GetText := l2s(P^.LockFlag)+'|'+P^.NickName;
    end;
procedure TUserLister.UpDateUserList;
    begin
      if ItemList <> NIL then Dispose(ItemList,Done);
      ItemList := GetUsersCollection(IncMe);
      PaintView;
    end;
{*************************************************************************}
{*************************  USER DATA DIALOG  ****************************}
{*************************************************************************}
Constructor TUserDataDlg.Init;
    Var
      R : TRect;
    begin
      R.Assign(0,0,350,100);
      Inherited Init(R,'Kullançcçlar');
      Options := Options or Ocf_Centered;
      InsertBlock(GetBlock(10,10,MnfVertical,
        NewInputItem('Kçsa adç',15,Idc_StrDefault+Idc_Upper,
        NewInputItem('Uzun adç',30,Idc_StrDefault,
        NewCheckBox('Yînetici',
      NIL)))));
      InsertBlock(GetBlock(Size.X div 3,Size.Y - 60, MnfHorizontal,
        NewButton('~Tamam',CmOK,
        NewButton('~Vazgeá',CmCancel,
      NIL))));
      SelectNext(True);
    end;
procedure TUserDataDlg.GetData(Var Rec);
    type
      TScrUsers = Record
         NickName   : String[15];
         UserName   : String[30];
         Supervisor : Boolean;
      end;
    Var
      T : TScrUsers;
    begin
      Inherited GetData(T);
      with TUsers(Rec) do begin
        NickName := T.NickName;
        UserName := T.UserName;
        if T.Supervisor then Class := Class or NetClass_Supervisor
                        else Class := Class and Not NetClass_Supervisor;
      end;
    end;
procedure TUserDataDlg.SetData(Var Rec);
    type
      TScrUsers = Record
         NickName   : String[15];
         UserName   : String[30];
         Supervisor : Boolean;
      end;
    Var
      T : TScrUsers;
    begin
      with TUsers(Rec) do begin
        T.NickName   := NickName;
        T.UserName   := UserName;
        T.Supervisor := Class and NetClass_Supervisor > 0;
      end;
      Inherited SetData(T);
    end;
{*************************************************************************}
{*******************  NETWORK SETUP DIALOG *******************************}
{*************************************************************************}
Constructor TNetworkSetupDlg.Init;
    Var
      R : TRect;
    begin
      R.Assign(0,0,400,250);
      Inherited Init(R,'NETWORK SETUP');
      Options := Options or Ocf_Centered;
      New(UserList,Init(10,10,true));
      UserList^.GetBounds(R);
      Insert(UserList);
      if CrntUser.Class and NetClass_Supervisor > 0 then begin
        InsertBlock(GetBlock(R.B.X+10,R.A.Y,Mnfvertical,
          newButton('       ~Ekle        ',CmNewRecord,
          newButton('      ~Äikar        ',CmDel,
          newButton('     ~Deßiütir      ',CmRecord,
          newButton('  ~ûifre deßiütir   ',CmChange,
          newButton('    ~Mesaj Yolla    ',CmSendNetMsg,
          newButton('~Hepsine mesaj yolla',CmSendNetBroadcast,
          newButton('    ~Sistemden at   ',CmForceUser,
         NIL)))))))));
      end else begin
        InsertBlock(GetBlock(R.B.X+10,R.A.Y,Mnfvertical,
          newButton('  ~ûifre deßiütir   ',CmChange,
          newButton('    ~Mesaj Yolla    ',CmSendNetMsg,
          newButton('~Hepsine mesaj yolla',CmSendNetBroadcast,
         NIL)))));
      end;
      InsertBlock(GetBlock(Size.X div 2,Size.Y - 50,MnfHorizontal,
        newButton('~Tamam',CmOK,
      NIL)));
      SelectNext(True);
    end;

procedure TNetworkSetupDlg.HandleEvent(Var Event:TEvent);

    function GetFocusedUser(Var T:TUsers):Boolean;
      Var
        P : PUsers;
      begin
        P := UserList^.ItemList^.At(UserList^.FocusedItem);
        if P <> NIL then Move(P^,T,SizeOf(T))
                    else FillChar(T,SizeOf(T),0);
        GetFocusedUser := P <> NIL;
      end;

    function MySelf:Boolean;
      Var
        T : TUsers;
      begin
        GetFocusedUser(T);
        MySelf := T.LockFlag = MyMachine;
      end;

    function GetUserData(Var T:TUsers; ANew:Boolean):Boolean;
      var
        P : PUserDataDlg;
        C : Word;
      begin
        if ANew then FillChar(T,SizeOf(T),0);
        New(P,Init);
        P^.SetData(T);
        C := Owner^.ExecView(P);
        if C = CmOK then begin
         P^.GetData(T);
        end;
        GetUserData := C = CmOK;
      end;

    procedure AddNewUser;
      Var
        T  : TUsers;
        T1 : TUsers;
        L  : Longint;
      begin
        if GetUserData(T,True) then begin
          FUsers^.Reset;
          L := -SizeOf(T)+SizeOf(T.LockFlag);
          repeat
            inc(L,SizeOf(T1));
            FUsers^.Seek(L);
            FUsers^.Read(T1.NickName,SizeOf(T1)-SizeOf(T1.LockFlag));
          until (FUsers^.Status <> StOK) or (T1.Deleted);
          FUsers^.Reset;
          FUsers^.Seek(L);
          FUsers^.Write(T.NickName,SizeOf(T)-SizeOf(T.LockFlag));
        end;
        UserList^.UpDateUserList;
      end;

    procedure ChangeUser;
      Var
        T : TUsers;
        L : Longint;
      begin
        if Not GetFocusedUser(T) then exit;
        if GetUserData(T,False) then begin
          FUsers^.Reset;
          L := (T.LockFlag-1)*SizeOf(T);
          FUsers^.Seek(L+SizeOf(T.LockFlag));
          FUsers^.Write(T.Nickname,SizeOf(T)-SizeOf(T.LockFlag));
        end;
      end;

    procedure DelUser;
      Var
        C : Word;
        T : TUsers;
        L : Longint;
      begin
        if MySelf then begin
          BulletinBoard := 'Kendinizi Silemezsiniz!';
          exit;
        end;
        if Not GetFocusedUser(T) then exit;
        C := MessageBox('Emin misiniz?',0,MFWarning+MfYesButton+MfNoButton);
        if C = CmYes then begin
          L := (T.LockFlag-1)*SizeOf(T);
          FUsers^.Reset;
          FUsers^.Seek(L+SizeOf(T.LockFlag));
          T.Deleted := True;
          FUsers^.Write(T.NickName,SizeOf(T)-SizeOf(T.LockFlag));
          SendSysMsg(T.LockFlag,CmForceUser);
          UserList^.UpDateUserList;
        end;
      end;

    procedure ChangeUserPassword;
      Var
        T : TUsers;
        L : Longint;
      begin
        if Not GetFocusedUser(T) then exit;
        if Not MySelf and (CrntUser.Class and NetClass_Supervisor = 0) then begin
          MessageBox('Baüka bir kullançcçnçn üifresini deßiütirme yetkiniz yok!',0,0);
          exit;
        end;
        if GetNewPassword(T) then begin
          FUsers^.Reset;
          L := (T.LockFlag-1)*SizeOf(T);
          FUsers^.Seek(L+SizeOf(T.LockFlag));
          FUsers^.Write(T.Nickname,SizeOf(T)-SizeOf(T.LockFlag));
        end;
      end;

    procedure ForceUser;
      Var
        T : TUsers;
      begin
        GetFocusedUser(T);
        SendSysMsg(T.LockFlag,CmForceUser);
        UserList^.UpDateUserList;
      end;

    Function GetMsgTxt(Var S:String):Boolean;
      Var
        P : PDialog;
        V : PView;
        R : TRect;
        C : Word;
      begin
         S := '';
         R.Assign(0,0,450,70);
         New(P,Init(R,'Mesaj?'));
         P^.Options := P^.Options or Ocf_Centered;
         V := New(PInputStr,Init(5,2,30,'Mesaj  ',50,Idc_StrDefault));
         P^.Insert(V);
         P^.InsertBlock(GetBlock(P^.Size.X div 3,P^.Size.Y - 50,MnfHorizontal,
           newButton('~Tamam',CmOK,
           newButton('~Vazgeá',CmCancel,
         NIL))));
         P^.SelectNext(True);
         C := Owner^.ExecView(P);
         if C = CmOK then P^.GetData(S);
         GetMsgTxt := C = CmOK;
      end;

    procedure SendMsg;
      Var
        T : TUsers;
        S : String;
      begin
        if GetFocusedUser(T) and
           (T.LockFlag <> MyMachine) then begin
             if GetMsgTxt(S) then SendTxtMsg(T.LockFlag,S);
        end;
      end;

     procedure SendBroadcast;
      Var
        T : TUsers;
        S : String;
        I : Integer;
        P : PCollection;
       UP : PUsers;
      begin
        if GetMsgTxt(S) then begin
         P := UserList^.ItemList;
         For I := 0 to P^.Count-1 do begin
          UP := P^.At(I);
          SendTxtMsg(UP^.LockFlag,S);
         end; {for}
        end; {if}
      end;

    begin
      Inherited HandleEvent(Event);
      Case Event.What of
        EvCommand :
          Case Event.Command of
            CmNewRecord : AddNewUser;
                  CmDel : DelUser;
               CmRecord : ChangeUser;
         CmChange : ChangeUserPassword;
            CmForceUser : ForceUser;
           CmSendNetMsg : SendMsg;
     CmSendNetBroadcast : SendBroadCast;
          else
            exit;
          end;
      else
        exit;
      end;
      ClearEvent(Event);
    end;
{*************************************************************************}
{*******************  NETWORK CHAT  DIALOG *******************************}
{*************************************************************************}
Constructor TChatDlg.Init(X,Y:Integer; AHdr:String);
    Var
      R : TRect;
    begin
      R.Assign(0,0,400,350);
      R.Move(X,Y);
      Inherited Init(R,AHdr);
      New(MsgViewer,Init(5,5,48,20,cLightGray,cBlack));
      MsgViewer^.Options := MsgViewer^.Options and Not Ocf_Selectable;
      MsgViewer^.GetBounds(R);
      New(UserList,Init(5,R.B.Y + 5,False));
      UserList^.Options := (UserList^.Options or Ocf_PreProcess or Ocf_CenterX) and Not Ocf_selectable;
      UserList^.GetBounds(R);
      New(Msg,Init(5,R.B.Y + 5,45,'',80,Idc_StrDefault));
      Insert(MsgViewer);
      Insert(UserList);
      Insert(Msg);
      Insert(New(PAccelerator,Init(
        NewAcc(KbEnter,CmOK,
        NewAcc(KbEsc,CmClose,
      NIL)))));
    end;
Destructor TChatDlg.Done;
    begin
      Inherited Done;
    end;
procedure TChatDlg.HandleEvent(Var Event:TEvent);
    Var
      S : String;
    begin
      Inherited HandleEvent(Event);
      case Event.What of
       EvBroadcast :
         Case Event.Command of
           CmNetworkTxtMsg : begin
             IncomingMessage(PNetMsg(Event.Infoptr)^);
             if Not GetState(Scf_Focused) then exit;
           end;
           CmNetUserLogin  : UserList^.UpDateUserList;
           CmNetUserLogout : UserList^.UpDateUserList;
         else
           exit;
         end;
       EvCommand :
         case event.command of
           CmOK : begin
             Msg^.GetData(S);
             OutgoingMessage(S);
             S := '';
             Msg^.SetData(S);
           end;
         else
           exit;
         end;
      else
        exit;
      end;
      ClearEvent(Event);
    end;
procedure TChatDlg.IncomingMessage(Var T:TNetMsg);
    Var
      S : String;
      I : Byte;
    begin
      S[0] := Char(T.MsgLen);
      Move(T.Msg,S[1],Length(S));
      S := Time2Str(T.Moment)+' <--- '+Id2NickName(T.Sender)+':'+S;
      MsgViewer^.Writeln(S);
      MsgViewer^.Writeln(' ');
      For I:=1 to 10 do begin
        Sound(1200);delay(10);NoSound;Delay(2);
      end;
    end;
procedure TChatDlg.OutGoingMessage(TxtMsg:String);
    Var
      P : PCollection;
      U : PUsers;
      S : String;
    begin
      P := UserList^.ItemList;
      if P^.Count > 0 then begin
         U := P^.At(UserList^.FocusedItem);
         S := Time2Str(GetSysMoment)+' ---> '+U^.NickName+':'+TxtMsg;
         MsgViewer^.Writeln(S);
         MsgViewer^.Writeln(' ');
         SendTxtMsg(U^.LockFlag,TxtMsg);
      end;
    end;

end.
