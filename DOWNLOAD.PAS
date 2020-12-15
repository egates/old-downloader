PROGRAM Transform(input,output);

{$M 5200,0,240000}

uses Dos,Crt,Graph;

{$I Queuepac.pas}

CONST Cutoff_Time = '05:30';

TYPE TranType = QEltType;
     Months = array[0..12] of integer;

VAR TranFiles: TranType;
    Queue    : QType;
    Year,Month,Day,DayOfWeek,Wday: word;
    SJunk,DTime,CentralExt,PCExt: string;
    Junk: Integer;
    MonthDays : Months;
    JDay : word;
    LogFile,FileName : text;

(**************************************************************************)
FUNCTION FName(s: string): string;
   {returns the input filename from queue - not entire command line}

BEGIN
  Fname := Copy(S,18,18);
END;

(**************************************************************************)
FUNCTION LeapYear(Yr: word): boolean;
    {checks to see if the year is a leap year}

BEGIN  {leapyear}
   IF (((Yr MOD 4 = 0) AND (Yr MOD 100 <> 0)) OR (Yr MOD 400 = 0))
   THEN LeapYear := True
   ELSE LeapYear := False;
END;  {leapYear}

(**************************************************************************)
FUNCTION itostr (n : word) : string;
    { itostr - convert integer n to string in s... }

VAR S: String;

begin (* itoc *)
   Str(N,S);
   IToStr := S;
end; (* itoc *)

(**************************************************************************)
{$I Screens.pas}

(**************************************************************************)
FUNCTION  JDate(var MonthDays: Months;
                    Year,Month,Wday: Word): word;
   (* create julian date *)

VAR JD : Word;
    I : Integer;

BEGIN  {Jdate}
   IF (Month <> 1)
   THEN  BEGIN  {then}
            JD := WDay;
            FOR I := 1 TO (Month - 1) DO
                 JD := JD + MonthDays[I];
         END  {then}
   ELSE JD := WDay;
   IF LeapYear(Year)
   THEN JDate := JD + 1
   ELSE JDate := JD;
END;   {jdate}

(**************************************************************************)
PROCEDURE AdjustForWeekend(var WDay, Month, Year: word;
                               Skip: integer);
  {adjusts for weekends - skip is # of days from current to friday}

BEGIN
  IF Month = 1
  THEN BEGIN  {then}
         Month := 13;
         Year := Year - 1;
       END;  {then}
  WDay := MonthDays[Month-1] - Skip;
  Month := Month - 1;
END;

(**************************************************************************)
PROCEDURE BuildDate(var MonthDays: Months;
                    var Wday,Year,Month,Day,DayOfWeek: Word);
    {returns the file extension for the current day files}

VAR   I : integer;

BEGIN  {builddate}

   (* initialize array with days in months *)
   MonthDays[0] := 31;  {dec prev year}
   MonthDays[1] := 31;  {jan}
   MonthDays[2] := 28;  {feb}
   MonthDays[3] := 31;  {mar}
   MonthDays[4] := 30;  {apr}
   MonthDays[5] := 31;  {may}
   MonthDays[6] := 30;  {jun}
   MonthDays[7] := 31;  {jul}
   MonthDays[8] := 31;  {aug}
   MonthDays[9] := 30;  {sep}
   MonthDays[10] := 31; {oct}
   MonthDays[11] := 30; {nov}
   MonthDays[12] := 31; {dec}

   (* get current date *)
   GetDate(Year,Month,Day,DayOfWeek);

   (* adjust days in february for leap years *)
   IF LeapYear(Year)
   THEN MonthDays[2] := 29;

   (* set work date, adjust for weekend if necessary *)
   CASE DayOfWeek OF
      0: IF Day = 1
         THEN AdjustForWeekend(WDay,Month,Year,1)
         ELSE IF Day = 2
              THEN AdjustForWeekend(WDay,Month,Year,0)
              ELSE WDay := Day - 2;

      1: IF Day = 1
         THEN AdjustForWeekend(WDay,Month,Year,2)
         ELSE IF Day = 2
              THEN AdjustForWeekend(WDay,Month,Year,1)
              ELSE IF Day = 3
                   THEN AdjustForWeekend(WDay,Month,Year,0)
                   ELSE WDay := Day - 3

      ELSE IF Day = 1
           THEN AdjustForWeekend(Wday,Month,Year,0)
           ELSE WDay := Day - 1;
   END;  {case}
END;  {Builddate}

(**************************************************************************)
PROCEDURE FindHolidays(var Yr,Mth,Dy,DOW: word;
                          CYr,HMth,DW,Daynum: word);
   {finds holidays that fall on different days each year}

VAR I,DowCnt: Integer;

BEGIN
   I := 1;
   DowCnt := 0;
   REPEAT
      SetDate(CYr,HMth,I);
      GetDate(Yr,Mth,Dy,DOW);
      IF DOW = DW
      THEN DowCnt := DowCnt + 1;
      I := I + 1;
   UNTIL DowCnt = DayNum;
END;
(**************************************************************************)
PROCEDURE CheckForHoliday(MonthDays: Months;
                          var Year,Month,WDay,JDay: word);
   (* adjust workdate for holidays *)


VAR NewYears,Presidents, Memorial,Independence : word;
    Labor, Turkey, Christmas : word;
    Yr, Mth, Dy, DOW: Word;
    CYr, CMth, CDy, CDOW: Word;

BEGIN  {cfh}
   GetDate(CYr,CMth,CDy,CDOW);

   (* Adjust for Leap year *)
   (* Set holidays with standard dates *)
   IF LeapYear(Year)
   THEN BEGIN
           NewYears := 1;
           Independence := 186;
           Christmas := 360;
        END
   ELSE BEGIN
           NewYears := 1;
           Independence := 185;
           Christmas := 359;
        END;

   (* find 3rd Mon of Feb - Presidents day *)
   FindHolidays(Yr,Mth,Dy,DOW,CYr,2,1,3);
   Presidents := JDate(MonthDays,Yr,Mth,Dy);

   (* find 4th Mon of May - Memorial day *)
   FindHolidays(Yr,Mth,Dy,DOW,CYr,5,1,4);
   IF LeapYear(Year)
   THEN Memorial := JDate(MonthDays,Yr,Mth,Dy) + 1
   ELSE Memorial := JDate(MonthDays,Yr,Mth,Dy);

   (* find 1st Mon of Sept - Labor Day *)
   FindHolidays(Yr,Mth,Dy,DOW,CYr,9,1,1);
   IF LeapYear(Year)
   THEN Labor := JDate(MonthDays,Yr,Mth,Dy) + 1
   ELSE Labor := JDate(MonthDays,Yr,Mth,Dy);

   (* find 4th Thur of Nov - Turkey Day *)
   FindHolidays(Yr,Mth,Dy,DOW,CYr,11,4,4);
   IF LeapYear(Year)
   THEN Turkey := JDate(MonthDays,Yr,Mth,Dy) + 1
   ELSE Turkey := JDate(MonthDays,Yr,Mth,Dy);

   (* reset date *)
   SetDate(CYr,CMth,CDy);

   (* set julian day *)
   JDay := (JDate(MonthDays,Year,Month,WDay));

   (* Adjust workday if it equals a holiday *)
   IF JDay = NewYears
   THEN BEGIN  {case NY}
           SetDate(Year,1,1);
           GetDate(Yr,Mth,Day,DOW);
           IF DOW = 1
           THEN IF LeapYear(Year - 1)
                THEN JDay := 364
                ELSE JDay := 363
           ELSE IF LeapYear(Year - 1)
                THEN JDay := 366
                ELSE JDay := 365;
           Month := 12;
           Year := Year - 1;
        END  {case NY}
   ELSE IF JDay = Presidents
        THEN JDay := JDay - 3
        ELSE IF JDay = Memorial
             THEN JDay := JDay - 3
             ELSE IF JDay = Independence
                  THEN BEGIN {case 7/4}
                         SetDate(Year,7,4);
                         GetDate(Yr,Mth,Day,DOW);
                         IF DOW = 1
                         THEN JDay := JDay - 3
                         ELSE JDay := JDay - 1;
                       END  {case 7/4}
                  ELSE IF JDay = Labor
                       THEN JDay := JDay - 3
                       ELSE IF JDay = Turkey
                            THEN JDay := JDay - 1
                            ELSE IF JDay = Christmas
                                 THEN BEGIN {case xmas}
                                        SetDate(Year,12,25);
                                        GetDate(Yr,Mth,Day,DOW);
                                        IF DOW = 1
                                        THEN JDay := JDay - 3
                                        ELSE JDay := JDay - 1;
                                      END;  {case xmas}
   SetDate(CYr,CMth,CDy);
END;  {cfh}

(**************************************************************************)
PROCEDURE BuildFile(    MonthDays: Months;
                        Year, Jday: Word;
                    var CExt, PExt: string);
   (* Build file extension for Central Library Files *)
   (* Adjust for work date of previous year *)

VAR TYear,TDate: String;
    Len : integer;

BEGIN {buildfile}
   TYear := IToStr(Year);
   Delete(TYear,1,2);
   TDate := IToStr(JDay);
   Len := Length(TDate);
   IF Len = 1
   THEN TDate := '00'+TDate
   ELSE IF Len = 2
        THEN TDate := '0'+TDate;
   Cext := '000'+TYear+TDate;

   (* Build file extension for PC Files *)
   PExt := TDate+'.DAT';
END;  {Builddate}

(**************************************************************************)
PROCEDURE BuildQ(var FileNames: text;
                 var Q: Qtype;
                     CExt,PExt: string);
   {creates the Q according to historical file creation order}


VAR NewFile  : QEltType;

BEGIN  {buildQ}
      (* prepare file containing filenames for reading *)
   WHILE NOT EOF(FileNames) DO
      BEGIN  {while}
          (* read from the file and insert the file extension for
             current day files *)
        Readln(FileNames,NewFile.Cmd);
        Insert(PExt,NewFile.Cmd,35);
        Insert(CExt,NewFile.Cmd,27);
        NewFile.Time := '00:05';
        NewFile.Attempts := 0;
        EnQueue(Newfile,Q);
      END;
   Close(Filenames);
END;  {buildQ}

(**************************************************************************)
FUNCTION LwCall(TFiles: TranType;
                DTime: string): boolean;
    {calls lw transform on the files FILE returns true if sucessful}

VAR CmdLine : String;

BEGIN  {lwcall}
   CmdLine := 'Call transform '+TFiles.Cmd;
   SwapVectors;
   Exec('C:\LW\LWF.EXE',CmdLine);
   SwapVectors;
   CASE DosError OF
      3 : BEGIN  {IF}
            LwCall := False;
            Writeln('LWF.EXE file not found');
            Writeln(LogFile,'LWF.EXE file not found');
            Writeln(LogFile,'Download stopped at',DTime);
            Halt;
          END;   {if}
      8: BEGIN
            LwCall := False;
            Writeln('Not Enough Memory to run LWF.EXE');
            Writeln(LogFile,'Not Enough Memory to run LWF.EXE');
            Writeln(LogFile,'Download stopped at',DTime);
            Halt;
         END;
      0: {else}
           CASE DosExitCode OF
              0:   BEGIN  { case 0 }
                      LwCall := True;
                      Writeln('File ',FName(Tfiles.Cmd),
                              ' successfully transformed');
                   END;  { case 0 }
              3:   BEGIN { case 3 }
                      LwCall := False;
                      Initialize;
                      ClearDevice;
                      SetTextStyle(SansSerifFont,HorizDir,1);
                      OutTextXY(10,10,'Not Logged On to VM or Bad Connection');
                      Writeln(LogFile,'Not Logged On to VM or Bad Connection');
                      OutTextXY(10,25,'Please make sure you are logged on');
                      OutTextXY(10,40,'Press return');
                      ReadLn;
                      CloseGraph;
                      Writeln('Press ALT-SCROLL LOCK and logon to vm ');
                      Write('When done, ALT-SCROLL LOCK back to the PC ');
                      Writeln(' and press RETURN');
                      Readln;
                      CloseGraph;
                   END;  { case 3 }
              57:  BEGIN { case 57 }
                      LwCall := False;
                      Writeln('Transform of ',FName(Tfiles.Cmd),
                              ' unsucessful - cancelled by user');
                      Writeln(LogFile,'Transform of ',FName(Tfiles.Cmd),
                              ' unsucessful - cancelled by user');
                      Halt;
                   END;  { case 57 }
              59:  BEGIN { case 59 }
                      LwCall := False;
                      Writeln('File ',FName(Tfiles.Cmd),
                              ' does not exist as of ',DTime);
                      Writeln(LogFile,'File ',FName(Tfiles.Cmd),
                              ' does not exist as of ',DTime);
                      Writeln('Will try again later.');
                   END;
              255: BEGIN  { case 255 }
                      LwCall := False;
                      Write('Central Library File is restricted for');
                      Writeln(FName(Tfiles.Cmd));
                   END
              ELSE BEGIN  { otherwise }
                      LwCall := False;
                      Writeln('Unidentified error transforming ',FName(Tfiles.Cmd));
                      Writeln('Error code was ',DosExitCode:3);
                      Halt;
                   END  { otherwise }
           END  {case}
      ELSE BEGIN {case doserror}
             LwCall := False;
             Writeln('Unidentifiable Error running LWF.EXE');
             Writeln(LogFile,'Unidentifiable error - download stopped at: ',
                     DTime);
             Writeln(LogFile,'Error code from DOS was ',DosError);
             Halt;
           END;  {case doserror}
   END; {case dosoerror}
END;  {lwcall}

(**************************************************************************)
FUNCTION CalcTime(var stime: String): String;
     {returns a string like 00:00 in parm and itself}

VAR Hr,Min,Sec,MSec: word;
    THr,TMin: string;

BEGIN  {ct}
   GetTime(Hr,Min,Sec,Msec);
   IF Hr < 10
   THEN THr := '0'+ItoStr(Hr)
   ELSE THr := ItoStr(Hr);
   IF Min < 10
   THEN TMin := '0'+ItoStr(Min)
   ELSE TMin := ItoStr(Min);
   STime := THr+':'+TMin;
   CalcTime := STime;
END;  {ct}

(**************************************************************************)
FUNCTION IncrementTime(var STime: string): string;
    {inceases time by 5 minutes}

VAR THr,TMin,TMin1,TMin2 : string;
    IHr,IMin1,IMin2,Code : integer;

BEGIN  {it}
   THr := STime;
   TMin := STime;
   Delete(THr,3,3);
   Delete(TMin,1,3);
   IF TMin > '54'
   THEN BEGIN  {if}
           IF THr = '23'
           THEN THr := '00'
           ELSE BEGIN  {else}
                   Val(THr,IHr,Code);
                   THr := ItoStr(IHr + 1);
                   IF IHr < 10
                   THEN Insert('0',THr,1);
                END;  {else}
           TMin1 := Tmin;
           TMin2 := Tmin;
           Delete(TMin1,2,1);
           Delete(TMin2,1,1);
           Val(TMin1,IMin1,Code);
           Val(TMin2,IMin2,Code);
           IMin2 := (IMin2 + 5) MOD 10;
           IMin1 := (IMin2 + 5) DIV 10;
           TMin  := ItoStr(IMin1)+ItoStr(IMin2);
        END  {if tmin > 54}
   ELSE BEGIN { else tmin <= 54}
           Val(TMin,IMin1,Code);
           IF IMin1 < 10
           THEN BEGIN
                  TMin := IToStr(IMin1 + 5);
                  Insert('0',TMin,1);
                  Delete(TMin,3,1);
                END  { min < 10 }
           ELSE TMin := ItoStr(IMin1 + 5);
        END;
   STime := THr+':'+TMin;
   IncrementTime := STime;
END;  {inc_time}

(**************************************************************************)
PROCEDURE HoldQueue(var Q: QType);
     {stops processing and writes leftover files out to files.tmp}
     {  in case user wants to restart }

VAR HoldFile: text;
    TF      : TranType;
    Time    : string;

BEGIN  {hold}
   Assign(HoldFile,'Files.Tmp');
   ReWrite(HoldFile);
   WHILE NOT EmptyQueue(Q) DO
     BEGIN  {while}
        DeQueue(TF,Q);
        Writeln(HoldFile,TF.Cmd);
     END;   {while}
   Writeln(LogFile,'Queue held at ',CalcTime(Time));
   Close(LogFile);
   Close(HoldFile);
   Halt;
END;  {hold}

(**************************************************************************)
PROCEDURE ReQueue(var TFile: TranType;
                  var Q: QType;
                  var T: String);
   {increments the time and puts file back on queue}

VAR FN: string;
    TI: string;

BEGIN  {Requeue}
   FN := Fname(TFile.CMD);
   Write(LogFile,Fn);
   Writeln(LogFile,' not available at ',T);
   TI := CalcTime(T);
   TFile.Time := IncrementTime(Ti);
   Writeln(LogFile,'Will attempt download again at ',TFile.Time);
   EnQueue(TFile,Q);
END;  {REQUEUE}

(**************************************************************************)
FUNCTION TooManyAttempts(var Q: Qtype;
                         var TFile: TranType): boolean;
   {checks to see how many attempts have been made at downloading
    a file}

CONST MaxAttempts = 3;

VAR OutStr : string;
    Ans    : char;
    Time   : string;

BEGIN
  TFile.Attempts := TFile.Attempts + 1;
  IF TFile.Attempts < MaxAttempts
  THEN TooManyAttempts := False
  ELSE BEGIN  {ask to continue trying this file}
         Initialize;
         REPEAT
            ClearDevice;
            SetTextStyle(SansSerifFont,HorizDir,1);
            OutStr := IToStr(TFile.Attempts)+' attempts have been made '+
                      'to download this file: '+FName(TFile.Cmd);
            OutTextXY(10,5,OutStr);
            OutTextXY(10,35,'Would you like to:');
            OutTextXY(130,85,'A.  Put This File Back In The Queue');
            OutTextXY(130,115,'B. Remove This File From Download Queue');
            OutTextXY(130,155,'C. Stop Downloading Files With The Option Of');
            OutTextXY(155,185,'Continuing At A Later Time');
            Ans := ReadKey;
         UNTIL Ans IN ['A','B','C','a','b','c'];
         CASE Ans OF
           'A','a': TooManyAttempts := False;
           'B','b': TooManyAttempts := True;
           'C','c': BEGIN  {case c}
                      Time := CalcTime(Time);
                      ReQueue(TFile,Q,Time);
                      HoldQueue(Q);
                    END   {case c}
         END;  {case}
         ClearDevice;
         CloseGraph;
       END;  {else}
END;  {tma}

(***********************************************************************)
{$I MoreDown.pas}
(**************************************************************************)
BEGIN {Main}
   OldExitProc := ExitProc;           { save previous exit proc }
   ExitProc := @MyExitProc;           { insert our exit proc in chain }
   WHILE NOT (FirstScreen(Choice) IN ['Q','q']) DO
     BEGIN  {while}
       CASE Choice OF
          '1','2': BEGIN
                     Assign(LogFile,'Download.log');
                     IF Choice = '1'
                     THEN ReWrite(LogFile)
                     ELSE Append(LogFile);
                     BuildDate(MonthDays,WDay,Year,Month,Day,DayOfWeek);
                     CheckForHoliday(MonthDays,Year,Month,WDay,JDay);
                     VerifyDate(JDay);
                     BuildFile(MonthDays,Year,Jday,CentralExt,PCExt);
                     MakeQueue(Queue);
                     IF Choice = '1'
                     THEN BEGIN  {choice 1}
                            Assign(FileName,'Files.Dat');
                            Reset(FileName);
                            BuildQ(FileName,Queue,CentralExt,PCExt);
                            CheckForSadvpur(Queue,CentralExt,PCExt);
                          END  {choice 1}
                     ELSE BEGIN  {Choice 2}
                            Assign(FileName,'Files.Tmp');
                            Reset(FileName);
                            BuildQ(FileName,Queue,'','');
                          END;  {choice 2}
                     WHILE ((CalcTime(DTime)<Cutoff_Time) AND NOT
                             EmptyQueue(Queue)) DO
                       BEGIN  {while}
                         Dequeue(TranFiles,Queue);
                         Writeln('Waiting until ',
                                 TranFiles.Time,' to download ',
                                 FName(TranFiles.Cmd));
                         WHILE (TranFiles.Time >= CalcTime(DTime)) DO; (* nothing *)
                         IF NOT LwCall(TranFiles,DTime)
                         THEN IF NOT TooManyAttempts(Queue,TranFiles)
                              THEN ReQueue(TranFiles,Queue,DTime)
                              ELSE Writeln(LogFile,Fname(TranFiles.Cmd),
                                           ' removed from queue')
                         ELSE Writeln(LogFile,'File ',FName(TranFiles.Cmd),
                                      ' downloaded at ',DTime)
                       END;  {while}
                     IF (NOT EmptyQueue(Queue))
                     THEN BEGIN { not empty }
                            Writeln('The following files where not ',
                                     'downloaded');
                            Writeln(LogFile,'The following files where ',
                                            'not downloaded');
                            WHILE NOT EmptyQueue(Queue) DO
                              BEGIN {While}
                                DeQueue(TranFiles,Queue);
                                Writeln('     ',FName(Tranfiles.cmd));
                                Writeln(LogFile,'     ',
                                         FName(Tranfiles.cmd));
                              END;  {while}
                          END {not empty}
                     ELSE BEGIN  {else}
                            Writeln('All file sucessfully transformed at ',
                                     DTime);
                            Writeln(LogFile,'All file sucessfully ',
                                    'transformed at ',DTime);
                          END;  {else}
                     Close(LogFile);
                   END;  {case 1}
    '3': BEGIN  {case 3}
            CustomList;
            Assign(LogFile,'CDown.log');
            ReWrite(LogFile);
            Assign(FileName,'CFiles.dat');
            Reset(FileName);
            MakeQueue(Queue);
            BuildQ(FileName,Queue,'','');
            WHILE NOT EmptyQueue(Queue) DO
             BEGIN  {while}
                SJunk := CalcTime(DTime);
                DeQueue(TranFiles,Queue);
                IF NOT LwCall(TranFiles,DTime)
                THEN IF NOT TooManyAttempts(Queue,TranFiles)
                     THEN ReQueue(TranFiles,Queue,DTime)
                     ELSE Writeln(LogFile,Fname(TranFiles.Cmd),
                                  ' removed from queue')
                ELSE Writeln(LogFile,'File ',FName(TranFiles.Cmd),
                             ' downloaded at ',DTime)
             END;  {while}
             Close(LogFile);
         END;  {case 3}
    '4': AddFile;
    '5': BEGIN {case 5}
            Assign(FileName,'Files.Dat');
            Reset(FileName);
            MakeQueue(Queue);
            BuildQ(FileName,Queue,'','');
            DeleteFile(Queue);
         END;  {case 5}
   END;  {case}
   END;  {while}
END.  {main}
