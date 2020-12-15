(********************************************************************)
PROCEDURE CustomList;
   {will allow user to enter files they would like to download}



VAR Ans: char;
    TD,IFN,OFN: String;
    TDLoc,IFNLoc,OFNLoc: String;
    FName: Text;
    Line:  String;

BEGIN  {customlist}
   TextBackGround(Blue);
   TextColor(White);
   ClrScr;
   Assign(FName,'CFiles.dat');
   ReWrite(Fname);
   Ans := 'Y';
   Writeln;Writeln;Writeln;
   Writeln('                        Enter your download information: ');
   Writeln;Writeln;
   WHILE Ans IN ['Y','y'] DO
     BEGIN  {while}
        Write('Transform Definition: ');
        Readln(TD);
        Write('Central or User C/U: ');
        Readln(TDLoc);
        Writeln;Writeln;
        Write('Input File Name: ');
        Readln(IFN);
        Write('Central or User C/U: ');
        Readln(IFNLoc);
        Writeln;Writeln;
        Write('Output File Name: ');
        Readln(OFN);
        Write('Central, User, or PC C/U/P: ');
        Readln(OFNLoc);
        Writeln;Writeln;Writeln;Writeln;
        Write('                      Any more ? Y/N ');
        Ans := ReadKey;
        Line := TDLoc+'='+TD+'     '+IFNLoc+'='+IFN+'   '+OFNLoc+'='+OFN;
        Writeln(FName,Line);
        ClrScr;
     END;  {while}
     Close(Fname);
END;  {customlist}

(********************************************************************)
PROCEDURE AddFile;
      {allows user to add a file to list of transfer memo files}

VAR Ans: char;
    TD,IFN,OFN: String;
    TDLoc,IFNLoc: String;
    FName: Text;
    TransformDef,InputFile,OutputFile:  String;

BEGIN  {customlist}
   TextBackGround(Red);
   TextColor(White);
   ClrScr;
   Assign(FName,'Files.dat');
   Append(Fname);
   Ans := 'Y';
   REPEAT  {until info is correct}
     Writeln;Writeln;Writeln;
     Writeln('                   Enter your new download file information: ');
     Writeln;Writeln;
     Write('Transform Definition: ');
     Readln(TD);
     Write('Central or User C/U: ');
     Readln(TDLoc);
     Writeln;Writeln;
     Write('Input File Name: ');
     Readln(IFN);
     Write('Central or User C/U: ');
     Readln(IFNLoc);
     Writeln;Writeln;
     Write('3 to 5 Letter Name For Output File: ');
     Readln(OFN);
     Writeln;Writeln;Writeln;Writeln;
     Write('                 Is This Information Correct Y/N ');
     Ans := ReadKey;
     ClrScr;
     IF Ans IN ['Y','y']
     THEN BEGIN
           TransformDef := TDLoc+'='+TD+'.lwt'+'             ';
           InputFile := IFNLoc+'='+IFN+'.'+'            ';
           OutputFile := 'p='+OFN;
           Insert(InputFile,TransformDef,16);
           Insert(OutputFile,TransformDef,(35-Length(OutputFile)));
           Writeln(FName,TransformDef);
         END;  {if}
   UNTIL (Ans IN ['Y','y']);
   Close(Fname);
END;  {customlist}

(********************************************************************)
PROCEDURE DeleteFile(var Q: QType);
   {allows user to delete a file from transfer memo files}

VAR Line: string;
    FName: Text;
    TranRec: TranType;

BEGIN  {delete}
   CheckBreak := False;
   Assign(FName,'Files.dat');
   Rewrite(Fname);
   TextBackGround(Green);
   TextColor(Black);
   ClrScr;
   Writeln('Existing Download Files Are:');
   Writeln;
   PrintQ(Q);
   Writeln;Writeln;
   Writeln('For the file you would like to delete,');
   Writeln('type in enough of the line to make it unique.');
   Writeln('or # to quit');
   Readln(Line);
   REPEAT   {until queue is empty}
     DeQueue(TranRec,Q);
     IF Pos(Line,TranRec.Cmd) = 0
     THEN Writeln(FName,TranRec.Cmd)
     ELSE BEGIN
            ClrScr;
            Writeln;Writeln;
            Writeln(TranRec.Cmd);
            Writeln('has been successfully deleted.');
            Writeln;Writeln;
            Writeln('                       PRESS ENTER TO CONTINUE');
            Readln;
          END;  {else}
   UNTIL (EmptyQueue(Q));
   Close(FName);
   CheckBreak := True;
END;  {delete}

(********************************************************************)
