CONST

  Fonts : array[0..4] of string[13] =
  ('DefaultFont', 'TriplexFont', 'SmallFont', 'SansSerifFont', 'GothicFont');

  { The five predefined line styles supported }
  LineStyles : array[0..4] of string[9] =
  ('SolidLn', 'DottedLn', 'CenterLn', 'DashedLn', 'UserBitLn');

  { The twelve predefined fill styles supported }
  FillStyles : array[0..11] of string[14] =
  ('EmptyFill', 'SolidFill', 'LineFill', 'LtSlashFill', 'SlashFill',
   'BkSlashFill', 'LtBkSlashFill', 'HatchFill', 'XHatchFill',
   'InterleaveFill', 'WideDotFill', 'CloseDotFill');

  { The two text directions available }
  TextDirect : array[0..1] of string[8] = ('HorizDir', 'VertDir');

  { The Horizontal text justifications available }
  HorizJust  : array[0..2] of string[10] = ('LeftText', 'CenterText', 'RightText');

  { The vertical text justifications available }
  VertJust   : array[0..2] of string[10] = ('BottomText', 'CenterText', 'TopText');


VAR
    GraphDriver : integer;  { The Graphics device driver }
    GraphMode   : integer;  { The Graphics mode value }
    MaxX, MaxY  : word;     { The maximum resolution of the screen }
    ErrorCode   : integer;  { Reports any graphics errors }
    MaxColor    : word;     { The maximum color value available }
    OldExitProc : Pointer;  { Saves exit procedure address }
    Choice: char;

{$F+}
procedure MyExitProc;
begin
  ExitProc := OldExitProc; { Restore exit procedure address }
  CloseGraph;
  TextColor(White);
  TextBackground(Black);
  ClrScr;
  Release(HeapOrg);
  Writeln('Thank you and have a nice day !');
end; { MyExitProc }
{$F-}

procedure Initialize;
{ Initialize graphics and report any errors that may occur }
var
  InGraphicsMode : boolean;
  PathToDriver   : string;  { Stores the DOS path to *.BGI & *.CHR }
begin
  { when using Crt and graphics, turn off Crt's memory-mapped writes }
  DirectVideo := False;
  PathToDriver := '';
  repeat

{$IFDEF Use8514}                          { check for Use8514 $DEFINE }
    GraphDriver := IBM8514;
    GraphMode := IBM8514Hi;
{$ELSE}
    GraphDriver := Detect;                { use autodetection }
{$ENDIF}

    InitGraph(GraphDriver, GraphMode, PathToDriver);
    ErrorCode := GraphResult;             { preserve error return }
    if ErrorCode <> grOK then             { error? }
    begin
      Writeln('Graphics error: ', GraphErrorMsg(ErrorCode));
      if ErrorCode = grFileNotFound then  { Can't find driver file }
      begin
        Writeln('Enter full path to BGI driver or type <Ctrl-Break> to quit:');
        Readln(PathToDriver);
        Writeln;
      end
      else
        Halt(1);                          { Some other error: terminate }
    end;
  until ErrorCode = grOK;
  Randomize;                { init random number generator }
  MaxColor := GetMaxColor;  { Get the maximum allowable drawing color }
  MaxX := GetMaxX;          { Get screen resolution values }
  MaxY := GetMaxY;
end; { Initialize }

(**************************************************************************)
FUNCTION FirstScreen(var Ch: char): char;
   {draws first screen}

VAR
    ViewPort: ViewPortType;

BEGIN  {fs}
   Initialize;
   SetBkColor(4);
   SetColor(3);
   ClearDevice;
   SetTextStyle(SansSerifFont,HorizDir,3);
   SetTextJustify(CenterText,TopText);
   SetViewPort(0,0,MaxX,MaxY,ClipOn);
   OutTextXY(MaxX div 2,2,'AUTOMATIC DOWNLOADING APPLICATION');
   SetViewPort(0,TextHeight('M')+4,MaxX,MaxY-(TextHeight('M')+4),ClipOn);
   SeTLineStyle(SolidLn,0,NormWidth);
   GetViewSettings(ViewPort);
   with ViewPort DO
      Rectangle(0,0,x2-x1,y2-y1);
   SetViewPort(1,TextHeight('M')+5,MaxX -1,MaxX-(TextHeight('M')+5),ClipOn);
   SetColor(14);
   SetTextStyle(SansSerifFont,HorizDir,1);
   SetTextJustify(LeftText,CenterText);
   OutTextXY(150,20,'1. Download Transfer Memo Files');
   OutTextXY(150,50,'2. Continue Downloading Tran Mem Files');
   OutTextXY(150,80,'3. Download Custom List Of Files');
   OutTextXY(150,110,'4. Add A File To List Of Transfer Memo Files');
   OutTextXY(150,140,'5. Delete A File From List Of Tran Mem Files');
   SetColor(2);
   OutTextXY(150,170,'Q. EXIT TO DOS');
   Ch := ReadKey;
   FirstScreen := Ch;
   ClearDevice;
   CloseGraph;
END;  {fs}

(**************************************************************************)
PROCEDURE CheckForSadVpur(var Queue: Qtype;
                              Cext,Pcext: string);
     {asks user if they would like to check for sadvpur file}

VAR Ch: char;
    Tf: TranType;

BEGIN {cfs}
   Initialize;
   ClearDevice;
   SetViewPort(0,0,MaxX,MaxY,ClipOn);
   SetTextStyle(SansSerifFont,HorizDir,1);
   OutTextXY(35,80,'Would you like to check for the SADVPUR file?');
   Ch := ReadKey;
   IF Ch IN ['Y','y']
   THEN BEGIN
          TF.Cmd := ('u=sadvpur.lwt  c=sadvpur.'+cext+'  p=div'+pcext);
          TF.Time := '00:05';
          TF.Attempts := 0;
          Enqueue(TF,Queue);
        END;
  ClearDevice;
  CloseGraph;
END; {cfs}

(**************************************************************************)
PROCEDURE VerifyDate(var Day: word);
     {verifies date calculated by computer}

VAR Ch: char;
    UName: string;

BEGIN {verify}
   Initialize;
   ClearDevice;
   SetViewPort(0,0,MaxX,MaxY,ClipOn);
   SetTextStyle(SansSerifFont,HorizDir,1);
   OutTextXY(35,30,'I will proceed to download files for julian day ');
   OutTextXY(450,30,ItoStr(Day));
   OutTextXY(35,60,'Is this correct ?');
   Ch := ReadKey;
   IF NOT (Ch IN ['Y','y'])
   THEN BEGIN
           ClearDevice;
           SetViewPort(0,0,MaxX,MaxY,ClipOn);
           OutTextXy(35,80,'Then enter the day you would like');
           ReadLn(Day);
        END;
   ClearDevice;
   SetViewPort(0,0,MaxX,MaxY,ClipOn);
   UName := ' ';
   OutTextXy(35,80,'Enter your name for approval of date verification');
   WHILE (UName = '') OR (UName = ' ') OR (UName = '  ') OR (Uname = '   ')
          OR (UName = '    ') OR  (UName = '     ') DO
        ReadLn(UName);
   Writeln(LogFile,UName,' Downloading ',Day);
   ClearDevice;
   CloseGraph;
END;  {verify}

(**************************************************************************)
