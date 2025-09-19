unit ToggleSwitch;

interface

uses
  Windows, Messages, Classes, Graphics, Controls, StdCtrls, SysUtils;

type
  TToggleSwitch = class(TCustomControl)
  private
    FChecked     : Boolean;
    FOnColor     : TColor;
    FOffColor    : TColor;
    FKnobColor   : TColor;
    FBorderColor : TColor;
    FOnChange    : TNotifyEvent;

    procedure SetChecked(Value: Boolean);
    procedure SetOnColor(Value: TColor);
    procedure SetOffColor(Value: TColor);
    procedure SetKnobColor(Value: TColor);
    procedure SetBorderColor(Value: TColor);

    procedure DoChange;

  protected
    procedure Paint; override;
    procedure Click; override;
    procedure KeyPress(var Key: Char); override;
    procedure CMEnabledChanged(var Msg: TMessage); message CM_ENABLEDCHANGED;
    procedure CMFocusChanged(var Msg: TMessage); message CM_FOCUSCHANGED;

  public
    constructor Create(AOwner: TComponent); override;

  published
    property Align;
    property Anchors;
    property Constraints;
    property TabStop default True;
    property TabOrder;

    property Checked: Boolean read FChecked write SetChecked default False;

    property OnColor: TColor read FOnColor write SetOnColor default clLime;
    property OffColor: TColor read FOffColor write SetOffColor default clSilver;
    property KnobColor: TColor read FKnobColor write SetKnobColor default clWhite;
    property BorderColor: TColor read FBorderColor write SetBorderColor default clGray;

    property OnClick;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Samples', [TToggleSwitch]);
end;

{ TToggleSwitch }

constructor TToggleSwitch.Create(AOwner: TComponent);
begin
  inherited;
  Width       := 48;
  Height      := 24;
  DoubleBuffered := True;

  ControlStyle := ControlStyle + [csOpaque, csClickEvents, csCaptureMouse, csDoubleClicks];

  TabStop     := True;

  // default barvy
  FChecked     := False;
  FOnColor     := clLime;
  FOffColor    := clSilver;
  FKnobColor   := clWhite;
  FBorderColor := clGray;
end;

procedure TToggleSwitch.CMEnabledChanged(var Msg: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TToggleSwitch.CMFocusChanged(var Msg: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TToggleSwitch.KeyPress(var Key: Char);
begin
  inherited;
  if Key in [#13, ' '] then // Enter nebo Space
  begin
    Checked := not Checked;
    Key := #0;
  end;
end;

procedure TToggleSwitch.Click;
begin
  Checked := not Checked;
  inherited;
end;

procedure TToggleSwitch.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TToggleSwitch.SetChecked(Value: Boolean);
begin
  if FChecked <> Value then
  begin
    FChecked := Value;
    Invalidate;
    DoChange;
  end;
end;

procedure TToggleSwitch.SetOnColor(Value: TColor);
begin
  if FOnColor <> Value then
  begin
    FOnColor := Value;
    Invalidate;
  end;
end;

procedure TToggleSwitch.SetOffColor(Value: TColor);
begin
  if FOffColor <> Value then
  begin
    FOffColor := Value;
    Invalidate;
  end;
end;

procedure TToggleSwitch.SetKnobColor(Value: TColor);
begin
  if FKnobColor <> Value then
  begin
    FKnobColor := Value;
    Invalidate;
  end;
end;

procedure TToggleSwitch.SetBorderColor(Value: TColor);
begin
  if FBorderColor <> Value then
  begin
    FBorderColor := Value;
    Invalidate;
  end;
end;

procedure TToggleSwitch.Paint;
var
  R: TRect;
  Radius: Integer;
  BkgColor: TColor;
  KnobLeft, KnobRight: Integer;
  SaveBrushColor, SavePenColor: TColor;
begin
  // pozadí controlu
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);

  R := ClientRect;
  Radius := R.Height; // round rect se stejným polomìrem ? ovál

  // vypoèet barvy pozadí pøepínaèe
  if Enabled then
  begin
  if FChecked then
    BkgColor := FOnColor
  else
    BkgColor := FOffColor;
  end
else
  BkgColor := clBtnFace;


  // uložit pùv. barvy
  SaveBrushColor := Canvas.Brush.Color;
  SavePenColor   := Canvas.Pen.Color;

  // tìlo pøepínaèe
  Canvas.Brush.Color := BkgColor;
  Canvas.Pen.Color := FBorderColor;
  Canvas.Pen.Width := 1;
  Canvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, Radius, Radius);

  // knob (koleèko)
  if FChecked then
  begin
    KnobLeft  := R.Right - R.Height;
    KnobRight := R.Right;
  end
  else
  begin
    KnobLeft  := R.Left;
    KnobRight := R.Left + R.Height;
  end;

  // lehký vnitøní padding
  Inc(KnobLeft, 2);
  Dec(KnobRight, 2);

  Canvas.Brush.Color := FKnobColor;
  Canvas.Pen.Color := FBorderColor;
  Canvas.Ellipse(KnobLeft, R.Top + 2, KnobRight, R.Bottom - 2);

  // focus rámeèek
  if Focused then
  begin
    Canvas.Pen.Color := clHighlight;
    Canvas.Brush.Style := bsClear;
    Canvas.Rectangle(R.Left, R.Top, R.Right, R.Bottom);
  end;

  // vrátit barvy
  Canvas.Brush.Color := SaveBrushColor;
  Canvas.Pen.Color := SavePenColor;
end;

end.

