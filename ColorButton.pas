unit ColorButton;

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.UITypes,
  Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls;

type
  { TColorButton = TButton s volitelným owner-draw a vlastními barvami }
  TColorButton = class(TButton)
  private
    FUseCustomColors: Boolean;
    FNormalColor: TColor;
    FHotColor: TColor;
    FDownColor: TColor;
    FDisabledColor: TColor;
    FBorderColor: TColor;
    FTextColor: TColor;
    FIsFocused: Boolean;
    FHot: Boolean;
    procedure SetUseCustomColors(const Value: Boolean);
    procedure SetCol(var Field: TColor; const Value: TColor);
    procedure SetNormalColor(const Value: TColor);
    procedure SetHotColor(const Value: TColor);
    procedure SetDownColor(const Value: TColor);
    procedure SetDisabledColor(const Value: TColor);
    procedure SetBorderColor(const Value: TColor);
    procedure SetTextColor(const Value: TColor);
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure CNDrawItem(var Msg: TWMDrawItem); message CN_DRAWITEM;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure Loaded; override;
    procedure SetButtonStyle(ADefault: Boolean); override;
    procedure WndProc(var Message: TMessage); override;  // pøidáno funguje pro win blokaci
  public
    constructor Create(AOwner: TComponent); override;
  published
    property UseCustomColors: Boolean read FUseCustomColors write SetUseCustomColors default False;

    property NormalColor:   TColor read FNormalColor   write SetNormalColor   default $00F0F0F0; // svìtlá šedá
    property HotColor:      TColor read FHotColor      write SetHotColor      default $00E6F0FF; // hover
    property DownColor:     TColor read FDownColor     write SetDownColor     default $00D0E4FF; // pressed
    property DisabledColor: TColor read FDisabledColor write SetDisabledColor default $00EAEAEA;
    property BorderColor:   TColor read FBorderColor   write SetBorderColor   default $008A8A8A;
    property TextColor:     TColor read FTextColor     write SetTextColor     default clWindowText;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('MyComponents', [TColorButton]);
end;

{ TColorButton }

constructor TColorButton.Create(AOwner: TComponent);
begin
  inherited;
  FUseCustomColors := False;        // default = systém/VCL
  FNormalColor     := $00F0F0F0;
  FHotColor        := $00E6F0FF;
  FDownColor       := $00D0E4FF;
  FDisabledColor   := $00EAEAEA;
  FBorderColor     := $008A8A8A;
  FTextColor       := clWindowText;
end;

procedure TColorButton.CreateParams(var Params: TCreateParams);
begin
  inherited;
  if FUseCustomColors then
    Params.Style := Params.Style or BS_OWNERDRAW
  else
    Params.Style := Params.Style and not BS_OWNERDRAW;
end;

procedure TColorButton.CreateWnd;
begin
  inherited;
  // pojistka: po vytvoøení handle znovu vynutíme BS_OWNERDRAW
  if FUseCustomColors then
    SetWindowLong(Handle, GWL_STYLE, GetWindowLong(Handle, GWL_STYLE) or BS_OWNERDRAW);
end;

procedure TColorButton.Loaded;
begin
  inherited;
  // po naètení DFM pøegeneruj okno podle UseCustomColors
  if FUseCustomColors then
    RecreateWnd;
end;

procedure TColorButton.SetButtonStyle(ADefault: Boolean);
begin
  if FUseCustomColors then
  begin
    // nevolej inherited -> neshodíme BS_OWNERDRAW pøes BM_SETSTYLE
    if ADefault <> FIsFocused then
    begin
      FIsFocused := ADefault;
      Invalidate;
    end;
  end
  else
    inherited;
end;

procedure TColorButton.WndProc(var Message: TMessage);
begin
  // kdykoli nìkdo zkusí zmìnit styl tlaèítka, držíme BS_OWNERDRAW
  if FUseCustomColors then
  begin
    if Message.Msg = BM_SETSTYLE then
    begin
      Message.WParam := Message.WParam or BS_OWNERDRAW;
      // nepouštíme to dál? Mùžeme – ale s pøidaným BS_OWNERDRAW:
      inherited WndProc(Message);
      Exit;
    end;
  end;
  inherited WndProc(Message);
end;

procedure TColorButton.SetUseCustomColors(const Value: Boolean);
begin
  if FUseCustomColors <> Value then
  begin
    FUseCustomColors := Value;
    RecreateWnd; // pøepne BS_OWNERDRAW on/off
  end;
end;

procedure TColorButton.SetCol(var Field: TColor; const Value: TColor);
begin
  if Field <> Value then
  begin
    Field := Value;
    if FUseCustomColors then Invalidate;
  end;
end;

procedure TColorButton.SetNormalColor(const Value: TColor);
begin
  SetCol(FNormalColor, Value);
end;

procedure TColorButton.SetHotColor(const Value: TColor);
begin
  SetCol(FHotColor, Value);
end;

procedure TColorButton.SetDownColor(const Value: TColor);
begin
  SetCol(FDownColor, Value);
end;

procedure TColorButton.SetDisabledColor(const Value: TColor);
begin
  SetCol(FDisabledColor, Value);
end;

procedure TColorButton.SetBorderColor(const Value: TColor);
begin
  SetCol(FBorderColor, Value);
end;

procedure TColorButton.SetTextColor(const Value: TColor);
begin
  SetCol(FTextColor, Value);
end;

procedure TColorButton.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
  FHot := True;
  if FUseCustomColors then Invalidate;
end;

procedure TColorButton.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
  FHot := False;
  if FUseCustomColors then Invalidate;
end;

procedure TColorButton.CNDrawItem(var Msg: TWMDrawItem);
const
  DTFLAGS = DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS;
var
  R, RF: TRect;
  C: TCanvas;
  State: UINT;
  IsDown, IsDisabled, IsDefault: Boolean;
  bg: TColor;
begin
  if not FUseCustomColors then
  begin
    inherited;
    Exit;
  end;

  C := TCanvas.Create;
  try
    C.Handle := Msg.DrawItemStruct.hDC;
    R := Msg.DrawItemStruct.rcItem;
    State := Msg.DrawItemStruct.itemState;

    IsDown     := (State and ODS_SELECTED) <> 0;
    IsDisabled := (State and ODS_DISABLED) <> 0;
    IsDefault  := FIsFocused or ((State and ODS_FOCUS) <> 0);

    if IsDisabled then      bg := FDisabledColor
    else if IsDown then     bg := FDownColor
    else if FHot then       bg := FHotColor
    else                    bg := FNormalColor;

    C.Brush.Style := bsSolid;
    C.Brush.Color := bg;
    C.Pen.Color   := FBorderColor;
    C.Rectangle(R);

    InflateRect(R, -6, -3);
    if IsDown then OffsetRect(R, 1, 1);

    C.Brush.Style := bsClear;
    C.Font.Assign(Font);
    if IsDisabled then
      C.Font.Color := clGrayText
    else
      C.Font.Color := FTextColor;

    DrawText(C.Handle, PChar(Caption), -1, R, DTFLAGS);

    if IsDefault then
    begin
      RF := Msg.DrawItemStruct.rcItem;
      InflateRect(RF, -3, -3);
      DrawFocusRect(C.Handle, RF);
    end;
  finally
    C.Handle := 0;
    C.Free;
  end;
end;

end.

