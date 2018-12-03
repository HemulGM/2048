unit G2048.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, System.Generics.Collections, Direct2D, D2D1;

type
  TDoublePoint = record
   X, Y:Double;
  end;

  TGameCell = class
   private
    FValue:Cardinal;
    FTextValue:string;
    FFieldPos:TPoint;
    FNeedPos:TDoublePoint;
    FColor:TColor;
    procedure SetValue(Value:Cardinal);
    function GetEmpty:Boolean;
    procedure SetFieldPos(Value:TPoint);
   public
    Position:TDoublePoint;
    function StepPos:Boolean;
    property Value:Cardinal read FValue write SetValue;
    property Text:string read FTextValue;
    property Empty:Boolean read GetEmpty;
    property FieldPos:TPoint read FFieldPos write SetFieldPos;
    property Color:TColor read FColor;
    constructor Create(FPos:TPoint);
  end;

const
  FieldWidth = 4;
  FieldHeight = 4;
  CellWidth = 64;
  CellPlace = 5;
  StepSize = 5;

type
  TGameField = array[1..FieldWidth, 1..FieldHeight] of Cardinal;
  TGraphicCells = TList<TGameCell>;
  TDirection = (tdLeft, tdUp, tdRight, tdDown);

  TFormMain = class(TForm)
    TimerRedraw: TTimer;
    procedure TimerRedrawTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FD2Canvas:TDirect2DCanvas;
    FDrawRect:TRect;
    FStepping:Boolean;
    FBitmap:TBitmap;
    FGameField:TGameField;
    FCells:TGraphicCells;
    procedure Step;
    function FindCell(X, Y:Word):Integer;
  public
    procedure NewCell;
    procedure PlayerStep(Direction:TDirection);
    procedure Paint; override;
    procedure Redraw;
    constructor Create(AOwner: TComponent); override;
  end;

const
  colorEmpty = $00B4C0CD;
  colorField = $00A0ADBB;

var
  FormMain: TFormMain;
  FDrawing:Boolean;

implementation
 uses Math, Main.CommonFunc;

{$R *.dfm}

constructor TFormMain.Create(AOwner: TComponent);
var x, y:Integer;
begin
 inherited;
 FDrawRect:=Rect(0, 0, ClientWidth, ClientHeight);
 FBitmap:=TBitmap.Create;
 FBitmap.PixelFormat:=pf24bit;
 FBitmap.Width:=ClientWidth;
 FBitmap.Height:=ClientHeight;
 FBitmap.Canvas.Pen.Color:=colorField;
 FBitmap.Canvas.Brush.Color:=colorField;
 FBitmap.Canvas.FillRect(FDrawRect);
 FCells:=TGraphicCells.Create;
 for x:= 1 to FieldWidth do for y:= 1 to FieldHeight do FGameField[x, y]:=0;
end;

function TFormMain.FindCell(X, Y: Word): Integer;
var i:Integer;
begin
 Result:=-1;
 if FCells.Count > 0 then
  for i:= 0 to FCells.Count - 1 do
   if FCells[i].FieldPos = Point(X, Y) then Exit(i);
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
 Randomize;
 Redraw;
 NewCell;
end;

procedure TFormMain.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
 case Key of
  VK_UP:PlayerStep(tdUp);
  VK_DOWN:PlayerStep(tdDown);
  VK_LEFT:PlayerStep(tdLeft);
  VK_RIGHT:PlayerStep(tdRight);
 end;
end;

procedure TFormMain.NewCell;
var X, Y, Empty:Cardinal;
    Cell:TGameCell;
begin
 Empty:=0;
 for X:= 1 to FieldWidth do
  for Y:= 1 to FieldHeight do
   if FGameField[X, Y] = 0 then Inc(Empty);
 if Empty >= 2 then
  begin
   for Empty:= 1 to 2 do
    begin
     repeat
      X:=RandomRange(1, FieldWidth+1);
      Y:=RandomRange(1, FieldWidth+1);
     until FGameField[X, Y] = 0;
     FGameField[X, Y]:=2;
     Cell:=TGameCell.Create(Point(X, Y));
     Cell.Value:=FGameField[X, Y];
     FCells.Add(Cell);
     //Cell.Free;
    end;
  end;
end;

procedure TFormMain.Paint;
begin
 inherited;
 Canvas.Draw(0, 0, FBitmap);
end;

procedure TFormMain.PlayerStep(Direction: TDirection);
var X, Y, NX, NY:Cardinal;
    Active:Boolean;

procedure SetCellValue(X, Y:Word; Value:Cardinal);
var fCell:Integer;
begin
 fCell:=FindCell(X, Y);
 if fCell < 0 then Exit;
 FCells[fCell].Value:=Value;
end;

procedure SetCellPos(X, Y:Word; NewPos:TPoint);
var fCell:Integer;
begin
 fCell:=FindCell(X, Y);
 if fCell < 0 then Exit;
 FCells[fCell].FieldPos:=NewPos;
end;

procedure DeleteCell(X, Y:Word);
var fCell:Integer;
begin
 fCell:=FindCell(X, Y);
 if fCell < 0 then Exit;
 FCells.Delete(fCell);
end;

begin
 Active:=True;
 while Active do
  begin
   Active:=False;
   for Y:= 1 to FieldHeight do
    for X:= 1 to FieldWidth do
     begin
      case Direction of
       tdLeft:  if X < 2 then Continue;
       tdUp:    if Y < 2 then Continue;
       tdRight: if X > FieldWidth-1  then Continue;
       tdDown:  if Y > FieldHeight-1 then Continue;
      end;
      if FGameField[X, Y] = 0 then Continue;
      case Direction of
       tdLeft:  begin NX:=X-1; NY:=Y; end;
       tdRight: begin NX:=X+1; NY:=Y; end;
       tdUp:    begin NX:=X; NY:=Y-1; end;
       tdDown:  begin NX:=X; NY:=Y+1; end;
      end;

      if FGameField[NX, NY] = FGameField[X, Y] then
       begin
        FGameField[NX, NY]:=FGameField[NX, NY] * 2;
        FGameField[X, Y]:=0;
        DeleteCell(NX, NY);
        SetCellValue(X, Y, FGameField[NX, NY]);
        SetCellPos(X, Y, Point(NX, NY));
        Active:=True;
        Continue;
       end;
      if FGameField[NX, NY] = 0 then
       begin
        FGameField[NX, NY]:=FGameField[X, Y];
        FGameField[X, Y]:=0;
        SetCellPos(X, Y, Point(NX, NY));
        Active:=True;
        Continue;
       end;
     end;
  end;
 Step;
 NewCell;
end;

procedure TFormMain.Redraw;
var X, Y:Cardinal;
    FPos:TDoublePoint;
    CellRect, TextR:TRect;
    Str:string;
begin
 FD2Canvas:=TDirect2DCanvas.Create(FBitmap.Canvas, FDrawRect);
 with FD2Canvas do
  begin
   RenderTarget.BeginDraw;
   Pen.Color:=colorField;
   Brush.Color:=colorField;
   FillRect(FDrawRect);

   for X:= 1 to FieldWidth do
    for Y:= 1 to FieldHeight do
     begin
      FPos.X:=((X - 1) * CellWidth) + (X * CellPlace);
      FPos.Y:=((Y - 1) * CellWidth) + (Y * CellPlace);
      CellRect:=Rect(Round(FPos.X), Round(FPos.Y), Round(FPos.X + CellWidth), Round(FPos.Y + CellWidth));
      Pen.Color:=colorEmpty;
      Brush.Color:=colorEmpty;
      RoundRect(CellRect, 2, 2);
     end;

   if FCells.Count > 0 then
   for X:= 0 to FCells.Count - 1 do
    begin
     FPos:=FCells[X].Position;
     Pen.Color:=FCells[X].Color;
     Brush.Color:=FCells[X].Color;
     CellRect:=Rect(Round(FPos.X), Round(FPos.Y), Round(FPos.X + CellWidth), Round(FPos.Y + CellWidth));
     RoundRect(CellRect, 2, 2);

     Font.Size:=18;
     Font.Name:='Comic Sans MS';
     Font.Style:=[fsBold];
     Font.Color:=$00F7FAF9;
     Str:=FCells[X].Text;
     TextRect(CellRect, Str, [tfCenter, tfVerticalCenter, tfSingleLine]);
    end;

   RenderTarget.EndDraw;
  end;
 FD2Canvas.Free;
 Repaint;
end;

procedure TFormMain.Step;
var X, Y:Cardinal;
    DoStep:Boolean;
begin
 if FStepping then Exit;
 if FCells.Count <= 0 then Exit;
 FStepping:=True;
 DoStep:=True;
 while DoStep do
  begin
   DoStep:=False;
   for X:= 0 to FCells.Count - 1 do
    begin
     if FCells[X].StepPos then DoStep:=True;
    end;
   Redraw;
   Sleep(5);
  end;
 FStepping:=False;
end;

procedure TFormMain.TimerRedrawTimer(Sender: TObject);
begin
 Redraw;
end;

{ TGameCell }

constructor TGameCell.Create(FPos: TPoint);
begin
 FieldPos:=FPos;
 Position:=FNeedPos;
 Value:=0;
end;

function TGameCell.GetEmpty:Boolean;
begin
 Result:=FValue = 0;
end;

procedure TGameCell.SetFieldPos(Value: TPoint);
begin
 FFieldPos:=Value;
 FNeedPos.X:=((FFieldPos.X - 1) * CellWidth) + (FFieldPos.X * CellPlace);
 FNeedPos.Y:=((FFieldPos.Y - 1) * CellWidth) + (FFieldPos.Y * CellPlace);
end;

procedure TGameCell.SetValue(Value: Cardinal);
begin
 FValue:=Value;
 if FValue > 0 then
  begin
   FTextValue:=IntToStr(FValue);
   FColor:=$00AB84B7;
   if FValue <= 8 then FColor:=$0079B1F2
   else
    if FValue <= 32 then FColor:=$005F7CF6
    else
     if FValue <= 128 then FColor:=$0073CEED
     else
      if FValue <= 1024 then FColor:=$003E3CFF;

   FColor:=ColorDarker(FColor, FValue div 4);//FValue * 100;
  end
 else
  begin
   FTextValue:='Пусто';
   FColor:=colorEmpty;
  end;
end;

function TGameCell.StepPos:Boolean;
begin
 if Abs(FNeedPos.X - Position.X) > StepSize then
  begin
   if FNeedPos.X < Position.X then Position.X:=Position.X - StepSize
   else Position.X:=Position.X + StepSize;
  end
 else Position.X:=FNeedPos.X;

 if Abs(FNeedPos.Y - Position.Y) > StepSize then
  begin
   if FNeedPos.Y < Position.Y then Position.Y:=Position.Y - StepSize
   else Position.Y:=Position.Y + StepSize;
  end
 else Position.Y:=FNeedPos.Y;
 Result:=(Position.X <> FNeedPos.X) or (Position.Y <> FNeedPos.Y);
end;

end.
