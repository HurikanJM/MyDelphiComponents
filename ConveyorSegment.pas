unit ConveyorSegment;

interface
    { GC Komponenta je ta funkční, klasický Conv. nefunguje kvůli neprůhlednému pozadí byli určité funkce potlačeny, lehčí bylo část dědit.}
uses
  Windows, Messages, Classes, Graphics, Controls, Types, ExtCtrls, StdCtrls, Vcl.Themes, SysUtils;

type
  TFlowVisual    = (fvArrows, fvStripes);
  TConveyorState = (csOff, csRun, csBlocked, csFault, csMaintenance);
  TSegmentShape  = (skRect, skRoundRect, skLine);
  TFlowDir       = (fdLeftToRight, fdRightToLeft, fdTopToBottom, fdBottomToTop);
  TLabelPosition = (lpTop, lpBottom, lpLeft, lpRight);
  TMaintPlacement = (mpCenter, mpTopLeft, mpTopRight, mpBottomLeft, mpBottomRight, mpCustom);

  // Paleta barev pro stavy/obvod
  TConveyorPalette = class(TPersistent)
  private
    FOffColor, FRunColor, FBlockedColor, FFaultColor, FMaintenanceColor, FOutlineColor: TColor;
    FOnChange: TNotifyEvent;
    procedure DoChange;
    procedure SetOffColor(const Value: TColor);
    procedure SetRunColor(const Value: TColor);
    procedure SetBlockedColor(const Value: TColor);
    procedure SetFaultColor(const Value: TColor);
    procedure SetMaintenanceColor(const Value: TColor);
    procedure SetOutlineColor(const Value: TColor);
  public
    constructor Create; virtual;
    procedure Assign(Source: TPersistent); override;
  published
    property OffColor:         TColor read FOffColor         write SetOffColor         default $00B0B0B0; // BGR!
    property RunColor:         TColor read FRunColor         write SetRunColor         default clLime;
    property BlockedColor:     TColor read FBlockedColor     write SetBlockedColor     default $0080A0FF; // BGR!
    property FaultColor:       TColor read FFaultColor       write SetFaultColor       default clRed;
    property MaintenanceColor: TColor read FMaintenanceColor write SetMaintenanceColor default $00C0DCC0; // BGR!
    property OutlineColor:     TColor read FOutlineColor     write SetOutlineColor     default clGray;
    property OnChange:         TNotifyEvent read FOnChange   write FOnChange;
  end;

  // Události
  TSegmentClickEvent = procedure(Sender: TObject; const ConveyorID: string; SegmentIndex: Integer) of object;
  TStateChangedEvent = procedure(Sender: TObject; OldState, NewState: TConveyorState) of object;

  // ***********************
  //  VARIANTA S OKNEM (TCustomControl)
  // ***********************
  TConveyorSegment = class(TCustomControl)
  private
    //bmp (údržbová značka)
    FMaintBmp: TBitmap;
    FMarkSize: Integer;
    FMaintPlacement: TMaintPlacement;
    FMaintCustomPos: TPoint;

    // hot-track
    FHotTrack: Boolean;
    FHover: Boolean;
    FHoverOutlineColor: TColor;

    // vizualizace proudu
    FVisual: TFlowVisual;
    FStripeSpacing: Integer;
    FStripeThickness: Integer;

    // identita & stav
    FConveyorID: string;
    FSegmentIndex: Integer;
    FState: TConveyorState;
    FOnStateChanged: TStateChangedEvent;

    // rám
    FShapeKind: TSegmentShape;
    FCornerRadius: Integer;
    FOutlineWidth: Integer;
    FThickness: Integer;

    // šipky & animace
    FFlowDir: TFlowDir;
    FArrowSize: Integer;
    FArrowSpacing: Integer;
    FPhase: Integer;
    FTimer: TTimer;
    FAnimateOnRun: Boolean;
    FTimerInterval: Cardinal;
    FStepPx: Integer;

    // transparent
    FTransparent: Boolean;

    // paleta
    FPalette: TConveyorPalette;

    // připojený popisek (mimo komponentu)
    FShowLabel: Boolean;
    FLabel: TLabel;
    FLabelPosition: TLabelPosition;
    FLabelSpacing: Integer;

    // eventy
    FOnSegmentClick: TSegmentClickEvent;
    procedure InvalidateSelf;
    // setters / helpery
    procedure SetMaintBmp(const Value: TBitmap);
    procedure SetMarkSize(const Value: Integer);
    procedure SetMaintPlacement(const Value: TMaintPlacement);
    procedure SetMaintCustomPos(const Value: TPoint);

    procedure PaintParentToBitmap(ABmp: TBitmap);
    procedure UpdateWindowRgn;

    procedure SetConveyorID(const Value: string);
    procedure SetSegmentIndex(const Value: Integer);
    procedure SetState(const Value: TConveyorState);
    procedure SetShapeKind(const Value: TSegmentShape);
    procedure SetCornerRadius(const Value: Integer);
    procedure SetOutlineWidth(const Value: Integer);
    procedure SetThickness(const Value: Integer);
    procedure SetPalette(const Value: TConveyorPalette);
    procedure PaletteChanged(Sender: TObject);

    procedure SetFlowDir(const Value: TFlowDir);
    procedure SetArrowSize(const Value: Integer);
    procedure SetArrowSpacing(const Value: Integer);
    procedure SetAnimateOnRun(const Value: Boolean);
    procedure SetTimerInterval(const Value: Cardinal);
    procedure SetStepPx(const Value: Integer);
    procedure SetTransparent(const Value: Boolean);
    procedure SetVisual(const Value: TFlowVisual);
    procedure SetStripeSpacing(const Value: Integer);
    procedure SetStripeThickness(const Value: Integer);

    procedure SetShowLabel(const Value: Boolean);
    procedure SetLabelPosition(const Value: TLabelPosition);
    procedure SetLabelSpacing(const Value: Integer);
    procedure SetLabelText(const Value: string);
    function  GetLabelText: string;
    function  GetLabelFont: TFont;
    procedure SetLabelFont(const Value: TFont);

    // interní
    procedure TimerTick(Sender: TObject);
    procedure EnsureLabelParented;
    procedure UpdateLabelBounds;

    // backward-compat
    function GetDeprecatedCaption: string;
    procedure SetDeprecatedCaption(const Value: string);
    function GetDeprecatedCapiton: string;
    procedure SetDeprecatedCapiton(const Value: string);

    // kreslení
    function CurrentFillColor: TColor;
    procedure DrawFrame(ACanvas: TCanvas; const R: TRect);
    procedure DrawArrows(ACanvas: TCanvas; const R: TRect);
    procedure DrawStripes(ACanvas: TCanvas; const R: TRect);
    procedure DrawChevronH(ACanvas: TCanvas; XCenter, YCenter, HalfW, HalfH: Integer; Rightwards: Boolean);
    procedure DrawChevronV(ACanvas: TCanvas; XCenter, YCenter, HalfW, HalfH: Integer; Downwards: Boolean);
  protected
    procedure CreateWnd; override;
    procedure DrawMaintenanceMark;
    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure Paint; override;
    procedure Click; override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure ApplyState(AState: TConveyorState);
    procedure SetByBool(Run, Blocked, Fault: Boolean);
  published
    // --- Maintenance mark (BMP ruky) ---
    property MaintBitmap: TBitmap read FMaintBmp write SetMaintBmp;
    property MaintSize: Integer read FMarkSize write SetMarkSize default 32;
    property MaintPlacement: TMaintPlacement read FMaintPlacement write SetMaintPlacement default mpCenter;
    property MaintCustomPos: TPoint read FMaintCustomPos write SetMaintCustomPos;

    // identita
    property ConveyorID: string read FConveyorID write SetConveyorID;
    property SegmentIndex: Integer read FSegmentIndex write SetSegmentIndex default 0;
    property Caption: string read GetDeprecatedCaption write SetDeprecatedCaption stored False;
    property Capiton: string read GetDeprecatedCapiton write SetDeprecatedCapiton stored False;

    // vizualizace proudu
    property Visual: TFlowVisual read FVisual write SetVisual default fvArrows;
    property StripeSpacing: Integer read FStripeSpacing write SetStripeSpacing default 12;
    property StripeThickness: Integer read FStripeThickness write SetStripeThickness default 2;

    // rám & vzhled
    property State: TConveyorState read FState write SetState default csOff;
    property ShapeKind: TSegmentShape read FShapeKind write SetShapeKind default skRect;
    property CornerRadius: Integer read FCornerRadius write SetCornerRadius default 6;
    property OutlineWidth: Integer read FOutlineWidth write SetOutlineWidth default 1;
    property Thickness: Integer read FThickness write SetThickness default 6;
    property Palette: TConveyorPalette read FPalette write SetPalette;

    // směr & animace
    property FlowDir: TFlowDir read FFlowDir write SetFlowDir default fdLeftToRight;
    property ArrowSize: Integer read FArrowSize write SetArrowSize default 8;
    property ArrowSpacing: Integer read FArrowSpacing write SetArrowSpacing default 20;
    property AnimateOnRun: Boolean read FAnimateOnRun write SetAnimateOnRun default True;
    property TimerInterval: Cardinal read FTimerInterval write SetTimerInterval default 60;
    property StepPx: Integer read FStepPx write SetStepPx default 2;

    // transparentní pozadí
    property Transparent: Boolean read FTransparent write SetTransparent default True;

    // hot-track
    property HotTrack: Boolean read FHotTrack write FHotTrack default True;
    property HoverOutlineColor: TColor read FHoverOutlineColor write FHoverOutlineColor default clNavy;

    // připojený popisek
    property ShowLabel: Boolean read FShowLabel write SetShowLabel default False;
    property LabelText: string read GetLabelText write SetLabelText;
    property LabelFont: TFont read GetLabelFont write SetLabelFont;
    property LabelPosition: TLabelPosition read FLabelPosition write SetLabelPosition default lpBottom;
    property LabelSpacing: Integer read FLabelSpacing write SetLabelSpacing default 4;

    // standard
    property Align;
    property Anchors;
    property Constraints;
    property Hint;
    property ShowHint;
    property Visible;
    property Enabled;
    property Cursor;
    property PopupMenu;
    property OnClick;
    property OnDblClick;
    property OnContextPopup;
    property OnMouseDown;
    property OnMouseUp;
    property OnMouseMove;

    // eventy
    property OnSegmentClick: TSegmentClickEvent read FOnSegmentClick write FOnSegmentClick;
    property OnStateChanged: TStateChangedEvent read FOnStateChanged write FOnStateChanged;
  end;

  // ***********************
  //  VARIANTA PRŮHLEDNÁ (TGraphicControl) se SDÍLENÝM TIMEREM
  // ***********************
  TConveyorSegmentGC = class(TGraphicControl)
  private
    // vizualizace proudu
    FVisual: TFlowVisual;
    FStripeSpacing: Integer;
    FStripeThickness: Integer;

    // stav & vzhled
    FState: TConveyorState;
    FShapeKind: TSegmentShape;
    FCornerRadius: Integer;
    FOutlineWidth: Integer;
    FThickness: Integer;

    // šipky & animace
    FFlowDir: TFlowDir;
    FArrowSize: Integer;
    FArrowSpacing: Integer;
    FPhase: Integer;
    FAnimateOnRun: Boolean;
    FTimerInterval: Cardinal;
    FStepPx: Integer;

    // paleta
    FPalette: TConveyorPalette;

    // údržba (ruka)
    FMaintBmp: TBitmap;
    FMarkSize: Integer;
    FMaintPlacement: TMaintPlacement;
    FMaintCustomPos: TPoint;

    // sdílený timer volá toto:
    procedure DoTick;

    // settery
    procedure SetAnimateOnRunGC(const Value: Boolean);
    procedure SetVisualGC(const Value: TFlowVisual);
    procedure SetArrowSizeGC(const Value: Integer);
    procedure SetArrowSpacingGC(const Value: Integer);
    procedure SetStripeSpacingGC(const Value: Integer);
    procedure SetTimerIntervalGC(const Value: Cardinal);
    procedure SetStepPxGC(const Value: Integer);

    procedure PaletteChanged(Sender: TObject);
    procedure InvalidateSelf; // invaliduje můj obdélník u rodiče

    procedure SetStateGC(const Value: TConveyorState);
    procedure SetPaletteGC(const Value: TConveyorPalette);
    procedure SetMaintBmpGC(const Value: TBitmap);

    // kreslící helpery
    function  CurrentFillColor: TColor;
    procedure DrawFrame(ACanvas: TCanvas; const R: TRect);
    procedure DrawArrows(ACanvas: TCanvas; const R: TRect);
    procedure DrawStripes(ACanvas: TCanvas; const R: TRect);
    procedure DrawChevronH(ACanvas: TCanvas; XCenter, YCenter, HalfW, HalfH: Integer; Rightwards: Boolean);
    procedure DrawChevronV(ACanvas: TCanvas; XCenter, YCenter, HalfW, HalfH: Integer; Downwards: Boolean);
    procedure DrawMaintenanceMark;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    // stav
    property State: TConveyorState read FState write SetStateGC default csOff;

    // vizualizace
    property Visual: TFlowVisual read FVisual write SetVisualGC default fvArrows;
    property StripeThickness: Integer read FStripeThickness write FStripeThickness default 2;
    property ArrowSize: Integer read FArrowSize write SetArrowSizeGC default 8;
    property ArrowSpacing: Integer read FArrowSpacing write SetArrowSpacingGC default 20;
    property StripeSpacing: Integer read FStripeSpacing write SetStripeSpacingGC default 12;
    property AnimateOnRun: Boolean read FAnimateOnRun write SetAnimateOnRunGC default True;

    // rám
    property ShapeKind: TSegmentShape read FShapeKind write FShapeKind default skRect;
    property CornerRadius: Integer read FCornerRadius write FCornerRadius default 6;
    property OutlineWidth: Integer read FOutlineWidth write FOutlineWidth default 1;
    property Thickness: Integer read FThickness write FThickness default 6;

    // směr & animace
    property FlowDir: TFlowDir read FFlowDir write FFlowDir default fdLeftToRight;
    property TimerInterval: Cardinal read FTimerInterval write SetTimerIntervalGC default 60;
    property StepPx: Integer read FStepPx write SetStepPxGC default 2;

    // paleta
    property Palette: TConveyorPalette read FPalette write SetPaletteGC;

    // údržba
    property MaintBitmap: TBitmap read FMaintBmp write SetMaintBmpGC;
    property MaintSize: Integer read FMarkSize write FMarkSize default 32;
    property MaintPlacement: TMaintPlacement read FMaintPlacement write FMaintPlacement default mpCenter;
    property MaintCustomPos: TPoint read FMaintCustomPos write FMaintCustomPos;

    // standard
    property Align;
    property Anchors;
    property Constraints;
    property Hint;
    property ShowHint;
    property Visible;
    property Enabled;
    property Cursor;
    property PopupMenu;
    property OnClick;
    property OnDblClick;
    property OnContextPopup;
    property OnMouseDown;
    property OnMouseUp;
    property OnMouseMove;
  end;

procedure Register;

implementation

uses Math;

type
  TGCSharedTimerProxy = class(TComponent)
  public
    procedure OnTick(Sender: TObject);
  end;
{==========================
  Sdílený timer pro GC verzi
==========================}

var
  GCSharedTimer: TTimer = nil; // Globální Timer pro Dopravníky kde se bere vždy nejmenší hodnota pro všechny (Interval)
  GCInstances: TList = nil;
  GCProxy: TGCSharedTimerProxy = nil; // Timer

procedure TGCSharedTimerProxy.OnTick(Sender: TObject); //Pro vzátí hodnota Interval
var
  i: Integer;
  inst: TConveyorSegmentGC;
begin
  if (GCInstances = nil) then Exit;
  for i := 0 to GCInstances.Count - 1 do
  begin
    inst := TConveyorSegmentGC(GCInstances[i]);
    if inst.FAnimateOnRun and (inst.FState = csRun) then
      inst.DoTick;
  end;
end;

procedure GCRecalcTimer;  // Reset Timeru
var
  i: Integer;
  inst: TConveyorSegmentGC;
  minActive, minAny: Cardinal;
  anyActive: Boolean;
begin
  if (GCInstances = nil) or (GCInstances.Count = 0) then
  begin
    if Assigned(GCSharedTimer) then
      GCSharedTimer.Enabled := False;
    Exit;
  end;

  if GCSharedTimer = nil then  // Pro sdílení Timeru
  begin
  GCSharedTimer := TTimer.Create(nil);
  GCSharedTimer.Enabled := False;
  GCSharedTimer.Interval := 60;

  if GCProxy = nil then
    GCProxy := TGCSharedTimerProxy.Create(nil);  // Def. když chybí Interval
  GCSharedTimer.OnTimer := GCProxy.OnTick; // metoda objektu
  end;


  minActive := High(Cardinal);
  minAny := High(Cardinal);
  anyActive := False;

  for i := 0 to GCInstances.Count - 1 do
  begin
    inst := TConveyorSegmentGC(GCInstances[i]);
    if inst.FTimerInterval < minAny then
      minAny := inst.FTimerInterval;

    if inst.FAnimateOnRun and (inst.FState = csRun) then
    begin
      anyActive := True;
      if inst.FTimerInterval < minActive then
        minActive := inst.FTimerInterval;
    end;
  end;

  if anyActive then
  begin
    GCSharedTimer.Interval := Max(10, Integer(minActive));
    GCSharedTimer.Enabled := True;
  end
  else
  begin
    GCSharedTimer.Enabled := False;
    if minAny <> High(Cardinal) then
      GCSharedTimer.Interval := Max(10, Integer(minAny));
  end;
end;

procedure GCRegisterInstance(AInst: TConveyorSegmentGC);
begin
  if GCInstances = nil then
    GCInstances := TList.Create;

  if GCInstances.IndexOf(AInst) < 0 then
    GCInstances.Add(AInst);

  GCRecalcTimer;
end;

procedure GCUnregisterInstance(AInst: TConveyorSegmentGC);
var
  idx: Integer;
begin
  if GCInstances = nil then Exit;
  idx := GCInstances.IndexOf(AInst);
  if idx >= 0 then
    GCInstances.Delete(idx);

  if (GCInstances.Count = 0) then
  begin
  if Assigned(GCSharedTimer) then
    FreeAndNil(GCSharedTimer);

  if Assigned(GCProxy) then
    FreeAndNil(GCProxy);

  FreeAndNil(GCInstances);
  end
  else
  GCRecalcTimer;

end;

{ TConveyorPalette }

constructor TConveyorPalette.Create;
begin
  inherited Create;
  FOffColor         := $00B0B0B0;
  FRunColor         := clLime;
  FBlockedColor     := $0080A0FF;
  FFaultColor       := clRed;
  FMaintenanceColor := $00C0DCC0;
  FOutlineColor     := clGray;
end;

procedure TConveyorPalette.Assign(Source: TPersistent);
var P: TConveyorPalette;
begin
  if Source is TConveyorPalette then
  begin
    P := TConveyorPalette(Source);
    FOffColor         := P.OffColor;
    FRunColor         := P.RunColor;
    FBlockedColor     := P.BlockedColor;
    FFaultColor       := P.FaultColor;
    FMaintenanceColor := P.MaintenanceColor;
    FOutlineColor     := P.OutlineColor;
    DoChange;
  end
  else
    inherited;
end;

procedure TConveyorPalette.DoChange;
begin
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TConveyorPalette.SetOffColor(const Value: TColor);         begin if FOffColor <> Value then begin FOffColor := Value; DoChange; end; end;
procedure TConveyorPalette.SetRunColor(const Value: TColor);         begin if FRunColor <> Value then begin FRunColor := Value; DoChange; end; end;
procedure TConveyorPalette.SetBlockedColor(const Value: TColor);     begin if FBlockedColor <> Value then begin FBlockedColor := Value; DoChange; end; end;
procedure TConveyorPalette.SetFaultColor(const Value: TColor);       begin if FFaultColor <> Value then begin FFaultColor := Value; DoChange; end; end;
procedure TConveyorPalette.SetMaintenanceColor(const Value: TColor); begin if FMaintenanceColor <> Value then begin FMaintenanceColor := Value; DoChange; end; end;
procedure TConveyorPalette.SetOutlineColor(const Value: TColor);     begin if FOutlineColor <> Value then begin FOutlineColor := Value; DoChange; end; end;

{ ===========================
  TConveyorSegment (Control)
  =========================== }

constructor TConveyorSegment.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 100;
  Height := 28;

  ControlStyle := ControlStyle + [csDoubleClicks, csParentBackground];

  // paleta
  FPalette := TConveyorPalette.Create;
  FPalette.OnChange := PaletteChanged;

  // defaulty
  FHotTrack := True;
  FHover := False;
  FHoverOutlineColor := clNavy;

  FState := csOff;
  FShapeKind := skRect;
  FCornerRadius := 6;
  FOutlineWidth := 1;
  FThickness := 6;

  FFlowDir := fdLeftToRight;
  FArrowSize := 8;
  FArrowSpacing := 20;
  FPhase := 0;
  FAnimateOnRun := True;
  FTimerInterval := 60;
  FStepPx := 2;

  FVisual := fvArrows;
  FStripeSpacing := 12;
  FStripeThickness := 2;

  // label
  FShowLabel := False;
  FLabel := TLabel.Create(Self);
  FLabel.Visible := False;
  FLabel.AutoSize := True;
  FLabel.Transparent := True;
  FLabelPosition := lpBottom;
  FLabelSpacing := 4;

  // údržba
  FMaintBmp := TBitmap.Create;
  FMaintBmp.Transparent := True;
  FMarkSize := 32;
  FMaintPlacement := mpCenter;
  FMaintCustomPos := Point(0, 0);

  // timer
  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := FTimerInterval;
  FTimer.OnTimer := TimerTick;

  Cursor := crHandPoint;

  FTransparent := True;
  DoubleBuffered := True;
end;

destructor TConveyorSegment.Destroy;
begin
  FPalette.Free;
  FMaintBmp.Free;
  inherited;
end;

procedure TConveyorSegment.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  if FTransparent then
  begin
    Params.ExStyle := Params.ExStyle or WS_EX_TRANSPARENT;
    ControlStyle := ControlStyle - [csOpaque];
  end
  else
  begin
    Params.ExStyle := Params.ExStyle or WS_EX_COMPOSITED;
    ControlStyle := ControlStyle + [csOpaque];
  end;
end;

procedure TConveyorSegment.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  if FTransparent then
  begin
    Msg.Result := 1;
    Exit;
  end;
  inherited;
end;

function TConveyorSegment.GetDeprecatedCaption: string;
begin
  Result := LabelText;
end;

procedure TConveyorSegment.SetDeprecatedCaption(const Value: string);
begin
  LabelText := Value;
  ShowLabel := ShowLabel or (Value <> '');
end;

function TConveyorSegment.GetDeprecatedCapiton: string;
begin
  Result := '';
end;

procedure TConveyorSegment.SetDeprecatedCapiton(const Value: string);
begin
end;

procedure TConveyorSegment.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opInsert) and (AComponent = Parent) then
    EnsureLabelParented;
end;

procedure TConveyorSegment.UpdateWindowRgn;
var
  rgn: HRGN; d: Integer; R: TRect;
begin
  if (Handle = 0) then Exit;
  R := Rect(0, 0, Width, Height);
  InflateRect(R, -Max(1, FOutlineWidth), -Max(1, FOutlineWidth));
  d := Max(0, FCornerRadius) * 2;

  case FShapeKind of
    skRect:      rgn := CreateRectRgn(R.Left, R.Top, R.Right, R.Bottom);
    skRoundRect: rgn := CreateRoundRectRgn(R.Left, R.Top, R.Right, R.Bottom, d, d);
  else
    rgn := CreateRectRgn(R.Left, R.Top, R.Right, R.Bottom);
  end;

  SetWindowRgn(Handle, rgn, True);
end;

procedure TConveyorSegment.InvalidateSelf;
var R: TRect;
begin
  if Parent <> nil then
  begin
    R := BoundsRect;
    InvalidateRect(Parent.Handle, @R, True);
  end
  else
    Invalidate;
end;

procedure TConveyorSegment.EnsureLabelParented;
begin
  if Assigned(Parent) then FLabel.Parent := Parent else FLabel.Parent := nil;
  UpdateLabelBounds;
end;

procedure TConveyorSegment.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
  UpdateLabelBounds;
  UpdateWindowRgn;
  Invalidate;
end;

procedure TConveyorSegment.PaletteChanged(Sender: TObject);
begin
  Invalidate;
end;

procedure TConveyorSegment.SetConveyorID(const Value: string);
begin
  if FConveyorID <> Value then FConveyorID := Value;
end;

procedure TConveyorSegment.SetSegmentIndex(const Value: Integer);
begin
  if FSegmentIndex <> Value then FSegmentIndex := Value;
end;

procedure TConveyorSegment.SetState(const Value: TConveyorState);
var old: TConveyorState;
begin
  if FState <> Value then
  begin
    old := FState;
    FState := Value;

    if FAnimateOnRun and (FState = csRun) then FTimer.Enabled := True
    else FTimer.Enabled := False;

    InvalidateSelf; // << místo Invalidate
    if Assigned(FOnStateChanged) then FOnStateChanged(Self, old, FState);
  end;
end;

procedure TConveyorSegment.SetShapeKind(const Value: TSegmentShape);
begin
  if FShapeKind <> Value then
  begin
    FShapeKind := Value;
    UpdateWindowRgn;
    Invalidate;
  end;
end;

procedure TConveyorSegment.SetCornerRadius(const Value: Integer);
begin
  if FCornerRadius <> Value then
  begin
    FCornerRadius := Max(0, Value);
    UpdateWindowRgn;
    Invalidate;
  end;
end;

procedure TConveyorSegment.SetOutlineWidth(const Value: Integer);
begin
  if FOutlineWidth <> Value then
  begin
    FOutlineWidth := Max(0, Value);
    UpdateWindowRgn;
    Invalidate;
  end;
end;

procedure TConveyorSegment.SetThickness(const Value: Integer);
begin
  if FThickness <> Value then
  begin
    FThickness := Max(1, Value);
    Invalidate;
  end;
end;

procedure TConveyorSegment.SetPalette(const Value: TConveyorPalette);
begin
  if Value <> FPalette then
  begin
    FPalette.Assign(Value);
    Invalidate;
  end;
end;

procedure TConveyorSegment.SetFlowDir(const Value: TFlowDir);
begin
  if FFlowDir <> Value then
  begin
    FFlowDir := Value;
    Invalidate;
  end;
end;

procedure TConveyorSegment.SetArrowSize(const Value: Integer);
begin
  if FArrowSize <> Value then
  begin
    FArrowSize := Max(4, Value);
    FPhase := 0; Invalidate;
  end;
end;

procedure TConveyorSegment.SetArrowSpacing(const Value: Integer);
begin
  if FArrowSpacing <> Value then
  begin
    FArrowSpacing := Max(8, Value);
    FPhase := 0;
    Invalidate;
  end;
end;

procedure TConveyorSegment.SetAnimateOnRun(const Value: Boolean);
begin
  if FAnimateOnRun <> Value then
  begin
    FAnimateOnRun := Value;
    if not FAnimateOnRun then FTimer.Enabled := False
    else if FState = csRun then FTimer.Enabled := True;
  end;
end;

procedure TConveyorSegment.SetTimerInterval(const Value: Cardinal);
begin
  if FTimerInterval <> Value then
  begin
    FTimerInterval := Max(10, Value);
    FTimer.Interval := FTimerInterval;
  end;
end;

procedure TConveyorSegment.SetStepPx(const Value: Integer);
begin
  if FStepPx <> Value then FStepPx := Max(1, Value);
end;

procedure TConveyorSegment.SetTransparent(const Value: Boolean);
begin
  if FTransparent <> Value then
  begin
    FTransparent := Value;
    DoubleBuffered := True;
    RecreateWnd;
    Invalidate;
  end;
end;

procedure TConveyorSegment.CreateWnd;
begin
  inherited;
  UpdateWindowRgn;
end;

procedure TConveyorSegment.SetVisual(const Value: TFlowVisual);
begin
  if FVisual <> Value then
  begin
    FVisual := Value;
    FPhase := 0;
    Invalidate;
  end;
end;

procedure TConveyorSegment.SetMaintBmp(const Value: TBitmap);
begin
  if Assigned(Value) then FMaintBmp.Assign(Value)
  else FMaintBmp.SetSize(0, 0);
  Invalidate;
end;

procedure TConveyorSegment.SetMarkSize(const Value: Integer);
begin
  if Value <> FMarkSize then
  begin
    FMarkSize := Max(8, Value);
    Invalidate;
  end;
end;

procedure TConveyorSegment.SetMaintPlacement(const Value: TMaintPlacement);
begin
  if Value <> FMaintPlacement then
  begin
    FMaintPlacement := Value;
    Invalidate;
  end;
end;

procedure TConveyorSegment.SetMaintCustomPos(const Value: TPoint);
begin
  FMaintCustomPos := Value;
  if FMaintPlacement = mpCustom then Invalidate;
end;

procedure TConveyorSegment.DrawMaintenanceMark;
var
  W, H, X, Y, cw, ch: Integer;
  R: TRect;

  procedure PlaceByPreset(out AX, AY: Integer; aw, ah: Integer);
  begin
    case FMaintPlacement of
      mpCenter:      begin AX := (cw - aw) div 2; AY := (ch - ah) div 2; end;
      mpTopLeft:     begin AX := 0;             AY := 0;              end;
      mpTopRight:    begin AX := cw - aw;       AY := 0;              end;
      mpBottomLeft:  begin AX := 0;             AY := ch - ah;        end;
      mpBottomRight: begin AX := cw - aw;       AY := ch - ah;        end;
      mpCustom:      begin AX := FMaintCustomPos.X; AY := FMaintCustomPos.Y; end;
    end;
  end;

begin
  if (FMaintBmp = nil) or FMaintBmp.Empty then Exit;

  cw := ClientWidth;
  ch := ClientHeight;

  if FMaintBmp.Width >= FMaintBmp.Height then
  begin
    W := FMarkSize;
    H := MulDiv(FMarkSize, FMaintBmp.Height, FMaintBmp.Width);
  end
  else
  begin
    H := FMarkSize;
    W := MulDiv(FMarkSize, FMaintBmp.Width, FMaintBmp.Height);
  end;

  PlaceByPreset(X, Y, W, H);

  if X < 0 then X := 0;
  if Y < 0 then Y := 0;
  if X + W > cw then X := cw - W;
  if Y + H > ch then Y := ch - H;

  R := Rect(X, Y, X + W, Y + H);
  Canvas.StretchDraw(R, FMaintBmp);
end;

procedure TConveyorSegment.SetStripeSpacing(const Value: Integer);
begin
  if FStripeSpacing <> Value then
  begin
    FStripeSpacing := Max(6, Value);
    FPhase := 0;
    Invalidate;
  end;
end;

procedure TConveyorSegment.SetStripeThickness(const Value: Integer);
begin
  if FStripeThickness <> Value then
  begin
    FStripeThickness := Max(1, Value);
    Invalidate;
  end;
end;

procedure TConveyorSegment.SetShowLabel(const Value: Boolean);
begin
  if FShowLabel <> Value then
  begin
    FShowLabel := Value;
    EnsureLabelParented;
    FLabel.Visible := FShowLabel;
    UpdateLabelBounds;
  end;
end;

procedure TConveyorSegment.SetLabelPosition(const Value: TLabelPosition);
begin
  if FLabelPosition <> Value then begin FLabelPosition := Value; UpdateLabelBounds; end;
end;

procedure TConveyorSegment.SetLabelSpacing(const Value: Integer);
begin
  if FLabelSpacing <> Value then begin FLabelSpacing := Max(0, Value); UpdateLabelBounds; end;
end;

function TConveyorSegment.GetLabelText: string;
begin
  Result := FLabel.Caption;
end;

procedure TConveyorSegment.SetLabelText(const Value: string);
begin
  if FLabel.Caption <> Value then begin FLabel.Caption := Value; UpdateLabelBounds; end;
end;

function TConveyorSegment.GetLabelFont: TFont;
begin
  Result := FLabel.Font;
end;

procedure TConveyorSegment.SetLabelFont(const Value: TFont);
begin
  FLabel.Font.Assign(Value);
  UpdateLabelBounds;
end;

procedure TConveyorSegment.UpdateLabelBounds;
var x, y: Integer;
begin
  if not (FShowLabel and Assigned(FLabel) and Assigned(Parent)) then Exit;
  FLabel.AutoSize := True;

  case FLabelPosition of
    lpTop:    begin x := Left + (Width - FLabel.Width) div 2; y := Top - FLabel.Height - FLabelSpacing; end;
    lpBottom: begin x := Left + (Width - FLabel.Width) div 2; y := Top + Height + FLabelSpacing; end;
    lpLeft:   begin x := Left - FLabel.Width - FLabelSpacing; y := Top + (Height - FLabel.Height) div 2; end;
    lpRight:  begin x := Left + Width + FLabelSpacing; y := Top + (Height - FLabel.Height) div 2; end;
  end;

  FLabel.SetBounds(x, y, FLabel.Width, FLabel.Height);
  FLabel.BringToFront;
  BringToFront;
end;

procedure TConveyorSegment.TimerTick(Sender: TObject);
var span: Integer;
begin
  Inc(FPhase, FStepPx);
  if FVisual = fvArrows then span := Max(8, FArrowSpacing)
                        else span := Max(6, FStripeSpacing);
  if FPhase >= span then Dec(FPhase, span);
  Invalidate;           // ← sem PATŘÍ Invalidate (ne InvalidateSelf)
end;

function TConveyorSegment.CurrentFillColor: TColor;
begin
  case FState of
    csOff:         Result := FPalette.OffColor;
    csRun:         Result := FPalette.RunColor;
    csBlocked:     Result := FPalette.BlockedColor;
    csFault:       Result := FPalette.FaultColor;
    csMaintenance: Result := FPalette.MaintenanceColor;
  else
    Result := clBtnFace;
  end;
end;

procedure TConveyorSegment.DrawFrame(ACanvas: TCanvas; const R: TRect);
var d: Integer;
begin
  ACanvas.Brush.Style := bsClear;
  ACanvas.Pen.Width := Max(1, FOutlineWidth);
  ACanvas.Pen.Color := FPalette.OutlineColor;
  if FHover and FHotTrack then
    ACanvas.Pen.Color := FHoverOutlineColor;

  case FShapeKind of
    skRect:      ACanvas.Rectangle(R);
    skRoundRect: begin d := Max(0, FCornerRadius) * 2;
                       ACanvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, d, d);
                 end;
    skLine:      ACanvas.Rectangle(R);
  end;
end;

procedure TConveyorSegment.DrawChevronH(ACanvas: TCanvas; XCenter, YCenter, HalfW, HalfH: Integer; Rightwards: Boolean);
var pts: array[0..2] of TPoint;
begin
  if Rightwards then
  begin
    pts[0] := Point(XCenter - HalfW, YCenter - HalfH);
    pts[1] := Point(XCenter + HalfW, YCenter);
    pts[2] := Point(XCenter - HalfW, YCenter + HalfH);
  end
  else
  begin
    pts[0] := Point(XCenter + HalfW, YCenter - HalfH);
    pts[1] := Point(XCenter - HalfW, YCenter);
    pts[2] := Point(XCenter + HalfW, YCenter + HalfH);
  end;
  ACanvas.Polyline(pts);
end;

procedure TConveyorSegment.DrawChevronV(ACanvas: TCanvas; XCenter, YCenter, HalfW, HalfH: Integer; Downwards: Boolean);
var pts: array[0..2] of TPoint;
begin
  if Downwards then
  begin
    pts[0] := Point(XCenter - HalfW, YCenter - HalfH);
    pts[1] := Point(XCenter,        YCenter + HalfH);
    pts[2] := Point(XCenter + HalfW, YCenter - HalfH);
  end
  else
  begin
    pts[0] := Point(XCenter - HalfW, YCenter + HalfH);
    pts[1] := Point(XCenter,        YCenter - HalfH);
    pts[2] := Point(XCenter + HalfW, YCenter + HalfH);
  end;
  ACanvas.Polyline(pts);
end;

procedure TConveyorSegment.DrawArrows(ACanvas: TCanvas; const R: TRect);
var
  colorAr: TColor;
  cx, cy, pos, startPos, endPos, halfW, halfH: Integer;
  arrowGap: Integer;
  rightwards, downwards: Boolean;
begin
  colorAr := CurrentFillColor;
  ACanvas.Pen.Color := colorAr;
  ACanvas.Pen.Width := 2;
  ACanvas.Brush.Style := bsClear;

  arrowGap := Max(8, FArrowSpacing);

  case FFlowDir of
    fdLeftToRight:
      begin
        cy := (R.Top + R.Bottom) div 2;
        halfW := Max(3, FArrowSize);
        halfH := Max(2, FArrowSize div 2);
        rightwards := True;

        startPos := R.Left  + halfW + 4;
        endPos   := R.Right - halfW - 4;

        pos := startPos + (FPhase mod arrowGap);
        while pos <= endPos do
        begin
          cx := pos;
          DrawChevronH(ACanvas, cx, cy, halfW, halfH, rightwards);
          Inc(pos, arrowGap);
        end;
      end;

    fdRightToLeft:
      begin
        cy := (R.Top + R.Bottom) div 2;
        halfW := Max(3, FArrowSize);
        halfH := Max(2, FArrowSize div 2);
        rightwards := False;

        startPos := R.Left  + halfW + 4;
        endPos   := R.Right - halfW - 4;

        pos := endPos - (FPhase mod arrowGap);
        while pos >= startPos do
        begin
          cx := pos;
          DrawChevronH(ACanvas, cx, cy, halfW, halfH, rightwards);
          Dec(pos, arrowGap);
        end;
      end;

    fdTopToBottom:
      begin
        cx := (R.Left + R.Right) div 2;
        halfH := Max(3, FArrowSize);
        halfW := Max(2, FArrowSize div 2);
        downwards := True;

        startPos := R.Top    + halfH + 4;
        endPos   := R.Bottom - halfH - 4;

        pos := startPos + (FPhase mod arrowGap);
        while pos <= endPos do
        begin
          cy := pos;
          DrawChevronV(ACanvas, cx, cy, halfW, halfH, downwards);
          Inc(pos, arrowGap);
        end;
      end;

    fdBottomToTop:
      begin
        cx := (R.Left + R.Right) div 2;
        halfH := Max(3, FArrowSize);
        halfW := Max(2, FArrowSize div 2);
        downwards := False;

        startPos := R.Top    + halfH + 4;
        endPos   := R.Bottom - halfH - 4;

        pos := endPos - (FPhase mod arrowGap);
        while pos >= startPos do
        begin
          cy := pos;
          DrawChevronV(ACanvas, cx, cy, halfW, halfH, downwards);
          Dec(pos, arrowGap);
        end;
      end;
  end;
end;

procedure TConveyorSegment.DrawStripes(ACanvas: TCanvas; const R: TRect);
var
  gap, thick, x, y, offset: Integer;
  clr: TColor;
  p1, p2: TPoint;
begin
  clr := CurrentFillColor;
  gap := Max(6, FStripeSpacing);
  thick := Max(1, FStripeThickness);

  ACanvas.Pen.Color := clr;
  ACanvas.Pen.Width := thick;
  ACanvas.Brush.Style := bsClear;

  case FFlowDir of
    fdLeftToRight, fdRightToLeft:
      begin
        if FFlowDir = fdLeftToRight then offset :=  (FPhase mod gap)
                                    else offset := -(FPhase mod gap);

        for x := R.Left - R.Height to R.Right + R.Height do
          if ((x + offset) mod gap) = 0 then
          begin
            p1 := Point(x, R.Bottom);
            p2 := Point(x + R.Height, R.Top);
            ACanvas.MoveTo(p1.X, p1.Y);
            ACanvas.LineTo(p2.X, p2.Y);
          end;
      end;

    fdTopToBottom, fdBottomToTop:
      begin
        if FFlowDir = fdTopToBottom then offset :=  (FPhase mod gap)
                                    else offset := -(FPhase mod gap);

        for y := R.Top - R.Width to R.Bottom + R.Width do
          if ((y + offset) mod gap) = 0 then
          begin
            p1 := Point(R.Left,  y);
            p2 := Point(R.Right, y + R.Width);
            ACanvas.MoveTo(p1.X, p1.Y);
            ACanvas.LineTo(p2.X, p2.Y);
          end;
      end;
  end;
end;

procedure TConveyorSegment.PaintParentToBitmap(ABmp: TBitmap);
var SaveIdx: Integer; Ofs: TPoint;
begin
  if (Parent = nil) or (ABmp = nil) then Exit;
  ABmp.Canvas.Lock;
  try
    Ofs := Parent.ScreenToClient(ClientToScreen(Point(0, 0)));
    SaveIdx := SaveDC(ABmp.Canvas.Handle);
    try
      SetViewportOrgEx(ABmp.Canvas.Handle, -Ofs.X, -Ofs.Y, nil);
      if ThemeServices.ThemesEnabled then
        ThemeServices.DrawParentBackground(Handle, ABmp.Canvas.Handle, nil, False)
      else
      begin
        Parent.Perform(WM_ERASEBKGND, WPARAM(ABmp.Canvas.Handle), 0);
        Parent.Perform(WM_PAINT,      WPARAM(ABmp.Canvas.Handle), 0);
      end;
    finally
      RestoreDC(ABmp.Canvas.Handle, SaveIdx);
    end;
  finally
    ABmp.Canvas.Unlock;
  end;
end;

procedure TConveyorSegment.Paint;
var R: TRect; Bmp: TBitmap;
begin
  R := Rect(0, 0, Width, Height);
  InflateRect(R, -Max(1, FOutlineWidth), -Max(1, FOutlineWidth));

  // TRANSPARENT režim: kreslíme přímo
  if FTransparent then
  begin
    DrawFrame(Canvas, R);
    case FVisual of
      fvArrows:  DrawArrows(Canvas, R);
      fvStripes: DrawStripes(Canvas, R);
    end;
    if FState = csMaintenance then DrawMaintenanceMark;
    Exit;
  end;

  // NETRANSPARENT
  Bmp := TBitmap.Create;
  try
    Bmp.PixelFormat := pf32bit;
    Bmp.SetSize(Width, Height);
    Bmp.Canvas.Brush.Color := Color;
    Bmp.Canvas.Brush.Style := bsSolid;
    Bmp.Canvas.FillRect(Rect(0, 0, Width, Height));

    DrawFrame(Bmp.Canvas, R);
    case FVisual of
      fvArrows:  DrawArrows(Bmp.Canvas, R);
      fvStripes: DrawStripes(Bmp.Canvas, R);
    end;

    BitBlt(Canvas.Handle, 0, 0, Width, Height, Bmp.Canvas.Handle, 0, 0, SRCCOPY);
  finally
    Bmp.Free;
  end;

  if FState = csMaintenance then DrawMaintenanceMark;
end;

procedure TConveyorSegment.Click;
begin
  inherited;
  if Assigned(FOnSegmentClick) then
    FOnSegmentClick(Self, FConveyorID, FSegmentIndex);
end;

procedure TConveyorSegment.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
  if FHotTrack then
  begin
    FHover := True;
    Invalidate;
  end;
end;

procedure TConveyorSegment.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
  if FHotTrack then
  begin
    FHover := False;
    Invalidate;
  end;
end;

procedure TConveyorSegment.ApplyState(AState: TConveyorState);
begin
  State := AState;
end;

procedure TConveyorSegment.SetByBool(Run, Blocked, Fault: Boolean);
begin
  if Fault then State := csFault
  else if Blocked then State := csBlocked
  else if Run then State := csRun
  else State := csOff;
end;

{ ==============================
  TConveyorSegmentGC (GraphicControl) – sdílený timer  GC je ta funkční komponenta
  ============================== }

constructor TConveyorSegmentGC.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 100;
  Height := 28;

  FPalette := TConveyorPalette.Create;
  FPalette.OnChange := PaletteChanged;

  FState := csOff;
  FShapeKind := skRect;
  FCornerRadius := 6;
  FOutlineWidth := 1;
  FThickness := 6;

  FFlowDir := fdLeftToRight;
  FArrowSize := 8;
  FArrowSpacing := 20;
  FPhase := 0;
  FAnimateOnRun := True;
  FTimerInterval := 60;
  FStepPx := 2;

  FVisual := fvArrows;
  FStripeSpacing := 12;
  FStripeThickness := 2;

  FMaintBmp := TBitmap.Create;
  FMaintBmp.Transparent := True;
  FMarkSize := 32;
  FMaintPlacement := mpCenter;
  FMaintCustomPos := Point(0, 0);

  Cursor := crHandPoint;

  // registrace do sdíleného timeru
  GCRegisterInstance(Self); // TIMER aby se inic.
end;

destructor TConveyorSegmentGC.Destroy; // uvolnění komponenty
begin
  // odregistrace
  GCUnregisterInstance(Self);

  FMaintBmp.Free;
  FPalette.Free;
  inherited;
end;

procedure TConveyorSegmentGC.DoTick;  // Pro param. když je RUN animace
var span: Integer;
begin
  Inc(FPhase, FStepPx);
  if FVisual = fvArrows then span := Max(8, FArrowSpacing)
                        else span := Max(6, FStripeSpacing);
  if FPhase >= span then Dec(FPhase, span);
  InvalidateSelf;
end;

procedure TConveyorSegmentGC.PaletteChanged(Sender: TObject);
begin
  InvalidateSelf;
end;

function TConveyorSegmentGC.CurrentFillColor: TColor; // Barvičky pro stavy dopr.
begin
  case FState of
    csOff:         Result := FPalette.OffColor;
    csRun:         Result := FPalette.RunColor;
    csBlocked:     Result := FPalette.BlockedColor;
    csFault:       Result := FPalette.FaultColor;
    csMaintenance: Result := FPalette.MaintenanceColor;
  else
    Result := clBtnFace;
  end;
end;

procedure TConveyorSegmentGC.DrawFrame(ACanvas: TCanvas; const R: TRect); // Vytvoření a nakreslení Frame, + mody sk Pro line neřeším tolik
var d: Integer;
begin
  ACanvas.Brush.Style := bsClear;
  ACanvas.Pen.Width := Max(1, FOutlineWidth);
  ACanvas.Pen.Color := FPalette.OutlineColor;

  case FShapeKind of
    skRect:      ACanvas.Rectangle(R);
    skRoundRect: begin d := Max(0, FCornerRadius) * 2;
                       ACanvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, d, d);
                 end;
    skLine:      ACanvas.Rectangle(R);
  end;
end;

procedure TConveyorSegmentGC.DrawChevronH(ACanvas: TCanvas; XCenter, YCenter, HalfW, HalfH: Integer; Rightwards: Boolean);
var pts: array[0..2] of TPoint; //Nakreslení šipek
begin
  if Rightwards then
  begin
    pts[0] := Point(XCenter - HalfW, YCenter - HalfH);
    pts[1] := Point(XCenter + HalfW, YCenter);
    pts[2] := Point(XCenter - HalfW, YCenter + HalfH);
  end
  else
  begin
    pts[0] := Point(XCenter + HalfW, YCenter - HalfH);
    pts[1] := Point(XCenter - HalfW, YCenter);
    pts[2] := Point(XCenter + HalfW, YCenter + HalfH);
  end;
  ACanvas.Polyline(pts);
end;

procedure TConveyorSegmentGC.DrawChevronV(ACanvas: TCanvas; XCenter, YCenter, HalfW, HalfH: Integer; Downwards: Boolean); // Pro obrácené chování TopToBottom | pro šrafování
var pts: array[0..2] of TPoint;
begin
  if Downwards then
  begin
    pts[0] := Point(XCenter - HalfW, YCenter - HalfH);
    pts[1] := Point(XCenter,        YCenter + HalfH);
    pts[2] := Point(XCenter + HalfW, YCenter - HalfH);
  end
  else
  begin
    pts[0] := Point(XCenter - HalfW, YCenter + HalfH);
    pts[1] := Point(XCenter,        YCenter - HalfH);
    pts[2] := Point(XCenter + HalfW, YCenter + HalfH);
  end;
  ACanvas.Polyline(pts);
end;

procedure TConveyorSegmentGC.DrawArrows(ACanvas: TCanvas; const R: TRect);// Pro obrácené chování TopToBottom | šipky
var
  colorAr: TColor;
  cx, cy, pos, startPos, endPos, halfW, halfH: Integer;
  arrowGap: Integer;
  rightwards, downwards: Boolean;
begin
  colorAr := CurrentFillColor;
  ACanvas.Pen.Color := colorAr;
  ACanvas.Pen.Width := 2;
  ACanvas.Brush.Style := bsClear;

  arrowGap := Max(8, FArrowSpacing);

  case FFlowDir of
    fdLeftToRight:
      begin
        cy := (R.Top + R.Bottom) div 2;
        halfW := Max(3, FArrowSize);
        halfH := Max(2, FArrowSize div 2);
        rightwards := True;

        startPos := R.Left  + halfW + 4;
        endPos   := R.Right - halfW - 4;

        pos := startPos + (FPhase mod arrowGap);
        while pos <= endPos do
        begin
          cx := pos;
          DrawChevronH(ACanvas, cx, cy, halfW, halfH, rightwards);
          Inc(pos, arrowGap);
        end;
      end;

    fdRightToLeft:
      begin
        cy := (R.Top + R.Bottom) div 2;
        halfW := Max(3, FArrowSize);
        halfH := Max(2, FArrowSize div 2);
        rightwards := False;

        startPos := R.Left  + halfW + 4;
        endPos   := R.Right - halfW - 4;

        pos := endPos - (FPhase mod arrowGap);
        while pos >= startPos do
        begin
          cx := pos;
          DrawChevronH(ACanvas, cx, cy, halfW, halfH, rightwards);
          Dec(pos, arrowGap);
        end;
      end;

    fdTopToBottom:
      begin
        cx := (R.Left + R.Right) div 2;
        halfH := Max(3, FArrowSize);
        halfW := Max(2, FArrowSize div 2);
        downwards := True;

        startPos := R.Top    + halfH + 4;
        endPos   := R.Bottom - halfH - 4;

        pos := startPos + (FPhase mod arrowGap);
        while pos <= endPos do
        begin
          cy := pos;
          DrawChevronV(ACanvas, cx, cy, halfW, halfH, downwards);
          Inc(pos, arrowGap);
        end;
      end;

    fdBottomToTop:
      begin
        cx := (R.Left + R.Right) div 2;
        halfH := Max(3, FArrowSize);
        halfW := Max(2, FArrowSize div 2);
        downwards := False;

        startPos := R.Top    + halfH + 4;
        endPos   := R.Bottom - halfH - 4;

        pos := endPos - (FPhase mod arrowGap);
        while pos >= startPos do
        begin
          cy := pos;
          DrawChevronV(ACanvas, cx, cy, halfW, halfH, downwards);
          Dec(pos, arrowGap);
        end;
      end;
  end;
end;

procedure TConveyorSegmentGC.DrawStripes(ACanvas: TCanvas; const R: TRect); // Pro obrácené chování TopToBottom | šrafování
var gap, thick, x, y, offset: Integer; clr: TColor; p1, p2: TPoint;
begin
  clr := CurrentFillColor;
  gap := Max(6, FStripeSpacing);
  thick := Max(1, FStripeThickness);

  ACanvas.Pen.Color := clr;
  ACanvas.Pen.Width := thick;
  ACanvas.Brush.Style := bsClear;

  case FFlowDir of
    fdLeftToRight, fdRightToLeft:
      begin
        if FFlowDir = fdLeftToRight then offset :=  (FPhase mod gap)
                                    else offset := -(FPhase mod gap);

        for x := R.Left - R.Height to R.Right + R.Height do
          if ((x + offset) mod gap) = 0 then
          begin
            p1 := Point(x, R.Bottom);
            p2 := Point(x + R.Height, R.Top);
            ACanvas.MoveTo(p1.X, p1.Y);
            ACanvas.LineTo(p2.X, p2.Y);
          end;
      end;

    fdTopToBottom, fdBottomToTop:
      begin
        if FFlowDir = fdTopToBottom then offset :=  (FPhase mod gap)
                                    else offset := -(FPhase mod gap);

        for y := R.Top - R.Width to R.Bottom + R.Width do
          if ((y + offset) mod gap) = 0 then
          begin
            p1 := Point(R.Left,  y);
            p2 := Point(R.Right, y + R.Width);
            ACanvas.MoveTo(p1.X, p1.Y);
            ACanvas.LineTo(p2.X, p2.Y);
          end;
      end;
  end;
end;

procedure TConveyorSegmentGC.DrawMaintenanceMark;
var
  W, H, X, Y, cw, ch: Integer;
  R: TRect;

  procedure PlaceByPreset(out AX, AY: Integer; aw, ah: Integer);
  begin
    case FMaintPlacement of
      mpCenter:      begin AX := (cw - aw) div 2; AY := (ch - ah) div 2; end;
      mpTopLeft:     begin AX := 0;             AY := 0;              end;
      mpTopRight:    begin AX := cw - aw;       AY := 0;              end;
      mpBottomLeft:  begin AX := 0;             AY := ch - ah;        end;
      mpBottomRight: begin AX := cw - aw;       AY := ch - ah;        end;
      mpCustom:      begin AX := FMaintCustomPos.X; AY := FMaintCustomPos.Y; end;
    end;
  end;

begin
  if (FMaintBmp = nil) or FMaintBmp.Empty then Exit;

  cw := ClientWidth;
  ch := ClientHeight;

  if FMaintBmp.Width >= FMaintBmp.Height then
  begin
    W := FMarkSize;
    H := MulDiv(FMarkSize, FMaintBmp.Height, FMaintBmp.Width);
  end
  else
  begin
    H := FMarkSize;
    W := MulDiv(FMarkSize, FMaintBmp.Width, FMaintBmp.Height);
  end;

  PlaceByPreset(X, Y, W, H);

  if X < 0 then X := 0;
  if Y < 0 then Y := 0;
  if X + W > cw then X := cw - W;
  if Y + H > ch then Y := ch - H;

  R := Rect(X, Y, X + W, Y + H);
  Canvas.StretchDraw(R, FMaintBmp);
end;

procedure TConveyorSegmentGC.Paint;
var R: TRect;
begin
  // Parent prosvítá – nic nevyplňujeme
  R := Rect(0, 0, Width, Height);
  InflateRect(R, -Max(1, FOutlineWidth), -Max(1, FOutlineWidth));

  DrawFrame(Canvas, R);

  case FVisual of
    fvArrows:  DrawArrows(Canvas, R);
    fvStripes: DrawStripes(Canvas, R);
  end;

  if FState = csMaintenance then
    DrawMaintenanceMark;
end;

procedure TConveyorSegmentGC.InvalidateSelf;
var R: TRect;
begin
  if Parent <> nil then
  begin
    R := BoundsRect;
    InvalidateRect(Parent.Handle, @R, False); // False = nemaž pozadí → méně blikání
  end;
end;

procedure TConveyorSegmentGC.SetAnimateOnRunGC(const Value: Boolean);
begin
  if FAnimateOnRun <> Value then
  begin
    FAnimateOnRun := Value;
    GCRecalcTimer;
  end;
end;

procedure TConveyorSegmentGC.SetVisualGC(const Value: TFlowVisual);
begin
  if FVisual <> Value then begin FVisual := Value; FPhase := 0; InvalidateSelf; end;
end;

procedure TConveyorSegmentGC.SetArrowSizeGC(const Value: Integer);
begin
  if FArrowSize <> Value then begin FArrowSize := Max(4, Value); FPhase := 0; InvalidateSelf; end;
end;

procedure TConveyorSegmentGC.SetArrowSpacingGC(const Value: Integer);
begin
  if FArrowSpacing <> Value then begin FArrowSpacing := Max(8, Value); FPhase := 0; InvalidateSelf; end;
end;

procedure TConveyorSegmentGC.SetStripeSpacingGC(const Value: Integer);
begin
  if FStripeSpacing <> Value then begin FStripeSpacing := Max(6, Value); FPhase := 0; InvalidateSelf; end;
end;

procedure TConveyorSegmentGC.SetTimerIntervalGC(const Value: Cardinal);
begin
  if FTimerInterval <> Value then
  begin
    FTimerInterval := Max(10, Value);
    GCRecalcTimer;
  end;
end;

procedure TConveyorSegmentGC.SetStepPxGC(const Value: Integer);
begin
  if FStepPx <> Value then
    FStepPx := Max(1, Value);
end;

procedure TConveyorSegmentGC.SetStateGC(const Value: TConveyorState);
begin
  if FState <> Value then
  begin
    FState := Value;
    InvalidateSelf;
    GCRecalcTimer;
  end;
end;

procedure TConveyorSegmentGC.SetPaletteGC(const Value: TConveyorPalette);
begin
  if Assigned(Value) then
  begin
    FPalette.Assign(Value);
    FPalette.OnChange := PaletteChanged;
    InvalidateSelf;
  end;
end;

procedure TConveyorSegmentGC.SetMaintBmpGC(const Value: TBitmap);
begin
  if Assigned(Value) then
    FMaintBmp.Assign(Value)
  else
    FMaintBmp.SetSize(0, 0);
  InvalidateSelf;
end;

{ Registrace }

procedure Register;
begin
  RegisterComponents('SCADA/Conveyor', [TConveyorSegment, TConveyorSegmentGC]);
end;

end.

