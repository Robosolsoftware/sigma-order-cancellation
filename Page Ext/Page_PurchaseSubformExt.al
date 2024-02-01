pageextension 70704 PurchSubExt extends "Purchase Order Subform"
{
    layout
    {
        // Add changes to page layout here
        addafter(Quantity)
        {
            field("Original Order Quantity"; Rec."Original Order Quantity")
            {
                ApplicationArea = All;
                Visible = VisibleonCancel;
                Editable = false;
            }
        }
        modify(Quantity)
        {
            Editable = not Rec."PO Cancelled" = true;
        }
        modify("Variant Code")
        {
            Editable = not Rec."PO Cancelled" = true;
        }
        modify("Qty. to Invoice")
        {
            Editable = not Rec."PO Cancelled" = true;
        }
        modify("Qty. to Receive")
        {
            Editable = not Rec."PO Cancelled" = true;
        }

        addlast(Control1)
        {
            field("Cancel Reason code"; Rec."Cancel Reason code")
            {
                ApplicationArea = all;
                Visible = VisibleonCancel;
                Editable = not Rec."PO Cancelled" = true;
            }
            field("PO Cancelled"; Rec."PO Cancelled")
            {
                ApplicationArea = all;
                Visible = VisibleonCancel;
                Editable = false;
            }
            field("PO Cancellation Date"; Rec."PO Cancellation Date")
            {
                ApplicationArea = all;
                Visible = VisibleonCancel;
                Editable = false;
            }
            field("PO Cancelled By"; Rec."PO Cancelled By")
            {
                ApplicationArea = all;
                Visible = VisibleonCancel;
                Editable = false;
            }
        }
    }

    actions
    {
        addafter("&Line")
        {
            group("Cancel Purchase Order")
            {
                Caption = 'Cancel Purchase Order';
                Visible = VisibleonCancel;
                action("Cancel Order")
                {
                    ToolTip = 'Cancel the selected row';
                    Image = Cancel;
                    ApplicationArea = All;
                    Visible = VisibleonCancel;
                    trigger OnAction()
                    var
                        L_PurchLine: Record "Purchase Line";
                        ReleaseDoc: Codeunit "Release Purchase Document";
                        WhseRcptHeader: Record "Warehouse Receipt Header";
                        WhseRcptLine: Record "Warehouse Receipt Line";
                        L_PurchaseHeader: Record "Purchase Header";
                        Canceled: Boolean;
                        PurchaseAndPayableSetup: Record "Purchases & Payables Setup";
                        TakeWhseActvityLine: Record "Warehouse Activity Line";
                        VariantCOde: Code[20];
                        OriginalQty: Decimal;
                        OriginalUnitCost: Decimal;
                        L_ReceiptNo: Code[2000];
                        L_CountWhseRcptLine: Record "Warehouse Receipt Line";
                    begin
                        //Check Setup++
                        PurchaseAndPayableSetup.Get();
                        if PurchaseAndPayableSetup."Cancel Purchase Order Feature" = false then
                            Error('Enable Cancel Purchase order feature on Purchase & Payables setup to unlock this feature');

                        //Confimation Box++
                        if not Confirm('Do you want to cancel this order?', false) then
                            exit;

                        //Check Status++
                        L_PurchaseHeader.Reset();
                        L_PurchaseHeader.SetRange("Document Type", Rec."Document Type");
                        L_PurchaseHeader.SetRange("No.", Rec."Document No.");
                        if L_PurchaseHeader.FindFirst() then begin
                            if L_PurchaseHeader.Status = L_PurchaseHeader.Status::Released then
                                ReleaseDoc.PerformManualReopen(L_PurchaseHeader);
                            L_PurchaseHeader.TestField(Status, L_PurchaseHeader.Status::Open);
                        end;

                        L_PurchLine.Reset();
                        CurrPage.SetSelectionFilter(L_PurchLine);
                        L_PurchLine.SetRange("PO Cancelled", false);
                        if L_PurchLine.FindSet() then begin
                            repeat
                                //Check Reason Code++
                                if L_PurchLine."Cancel Reason code" = '' then
                                    Error('Please Select Cancel Reason Code for Product: %1', L_PurchLine."No.");

                                if L_PurchLine.Type = L_PurchLine.Type::Item then begin
                                    //Check if warehouse Receipt line exist++
                                    WhseRcptLine.Reset();
                                    WhseRcptLine.SETRANGE("Source Document", WhseRcptLine."Source Document"::"Purchase Order");
                                    WhseRcptLine.SetRange("Source No.", L_PurchLine."Document No.");
                                    WhseRcptLine.SetRange("Source Line No.", L_PurchLine."Line No.");
                                    if WhseRcptLine.FindFirst() then
                                        Error('Unable to process ... Warehouse Receipt %1 exist for Order No.: %2 Line No.: %3', WhseRcptLine."No.", WhseRcptLine."Source No.", WhseRcptLine."Source Line No.");

                                    // //Check if warehouse Recipet line exist++
                                    // WhseRcptLine.Reset();
                                    // WhseRcptLine.SETRANGE("Source Document", WhseRcptLine."Source Document"::"Purchase Order");
                                    // WhseRcptLine.SetRange("Source No.", L_PurchLine."Document No.");
                                    // WhseRcptLine.SetRange("Source Line No.", L_PurchLine."Line No.");
                                    // WhseRcptLine.SetCurrentKey("No.");
                                    // WhseRcptLine.Ascending(true);
                                    // if WhseRcptLine.FindSet() then begin
                                    //     repeat
                                    //         //Delete Line for seleceted PO+++
                                    //         WhseRcptLine."Request For Cancel" := true;
                                    //         WhseRcptLine.Modify();
                                    //         WhseRcptLine.Delete(true);

                                    //         //Get Receipt No for delete header++
                                    //         if L_ReceiptNo <> '' then begin
                                    //             if L_ReceiptNo <> WhseRcptLine."No." then
                                    //                 L_ReceiptNo := L_ReceiptNo + '|' + WhseRcptLine."No.";

                                    //         end else
                                    //             L_ReceiptNo := WhseRcptLine."No.";
                                    //     until WhseRcptLine.Next() = 0;

                                    //     //Delete Header if line is empty++
                                    //     WhseRcptHeader.Reset();
                                    //     WhseRcptHeader.SetFilter("No.", L_ReceiptNo);
                                    //     if WhseRcptHeader.FindSet() then
                                    //         repeat
                                    //             L_CountWhseRcptLine.Reset();
                                    //             L_CountWhseRcptLine.SetRange("No.", WhseRcptHeader."No.");
                                    //             if L_CountWhseRcptLine.IsEmpty then
                                    //                 WhseRcptHeader.Delete(true);
                                    //         until WhseRcptHeader.Next() = 0;
                                    // end;

                                    //Check Put Away Available++
                                    TakeWhseActvityLine.Reset();
                                    TakeWhseActvityLine.SetRange("Source Document", TakeWhseActvityLine."Source Document"::"Purchase Order");
                                    TakeWhseActvityLine.SetRange("Source No.", L_PurchLine."Document No.");
                                    TakeWhseActvityLine.SetRange("Source Line No.", L_PurchLine."Line No.");
                                    TakeWhseActvityLine.SetRange("Activity Type", TakeWhseActvityLine."Activity Type"::"Put-away");
                                    if TakeWhseActvityLine.FindFirst() then
                                        Error('Warehouse putaway no. %1 exists: in Purchase Line Document Type= %2,Document No.= %3,Line No.=%4', TakeWhseActvityLine."No.", L_PurchLine."Document Type", L_PurchLine."Document No.", L_PurchLine."Line No.");


                                    //Check Invoice Quantity++
                                    if L_PurchLine."Qty. Rcd. Not Invoiced" > 0 then
                                        Error('Total %1 quantity received but invoiced quantity %2.Invoice is pending for Order No. : %3 Line No. : %4 ', L_PurchLine."Quantity Received", L_PurchLine."Quantity Invoiced", L_PurchLine."Document No.", L_PurchLine."Line No.");


                                    //Delete Reservation++
                                    DeleteReservationEntries(L_PurchLine);

                                    Clear(VariantCOde);
                                    Clear(OriginalQty);
                                    Clear(OriginalUnitCost);
                                    VariantCOde := L_PurchLine."Variant Code";
                                    OriginalQty := L_PurchLine.Quantity;
                                    OriginalUnitCost := L_PurchLine."Unit Cost";

                                    L_PurchLine.Validate(Quantity, L_PurchLine."Quantity Received");
                                    if L_PurchLine."PO Cancelled" = false then begin
                                        L_PurchLine.Validate("Original Order Quantity", OriginalQty);
                                        L_PurchLine.Validate("Unit Cost", OriginalUnitCost);
                                    End;
                                    //L_PurchLine.Validate("Cancel Reason code", L_PurchLine."Cancel Reason code");
                                    if VariantCOde <> '' then begin
                                        L_PurchLine."Variant Code" := VariantCOde;
                                        L_PurchLine.Validate("Variant Code");
                                    end;
                                    L_PurchLine."PO Cancelled" := true;
                                    L_PurchLine."PO Cancelled By" := UserId;
                                    L_PurchLine."PO Cancellation Date" := Today;
                                    L_PurchLine.Modify();
                                end else
                                    if L_PurchLine.Type = L_PurchLine.Type::"G/L Account" then begin

                                        if L_PurchLine."Qty. Rcd. Not Invoiced" > 0 then begin
                                            Error('Total %1 quantity received but invoiced quantity %2.Invoice is pending for Order No. : %3 Line No. : %4 ', L_PurchLine."Quantity Received", L_PurchLine."Quantity Invoiced", L_PurchLine."Document No.", L_PurchLine."Line No.");
                                        end;

                                        Clear(OriginalQty);
                                        Clear(OriginalUnitCost);
                                        OriginalQty := L_PurchLine.Quantity;
                                        OriginalUnitCost := L_PurchLine."Unit Cost";

                                        L_PurchLine.Validate(Quantity, L_PurchLine."Quantity Received");
                                        if L_PurchLine."PO Cancelled" = false then begin
                                            L_PurchLine.Validate("Original Order Quantity", OriginalQty);
                                            L_PurchLine.Validate("Unit Cost", OriginalUnitCost);
                                        End;
                                        //L_PurchLine.Validate("Cancel Reason code", L_PurchLine."Cancel Reason code");

                                        L_PurchLine."PO Cancelled" := true;
                                        L_PurchLine."PO Cancelled By" := UserId;
                                        L_PurchLine."PO Cancellation Date" := Today;
                                        L_PurchLine.Modify();
                                    end;
                            until L_PurchLine.Next() = 0;
                        end;
                        Message('Purchase order cancelled..');
                    end;
                }
            }
        }

    }
    trigger OnOpenPage()
    begin
        Clear(VisibleonCancel);
        PurchNPay.Get();
        if PurchNPay."Cancel Purchase Order Feature" then
            VisibleonCancel := true
        else
            VisibleonCancel := false;
    end;

    trigger OnAfterGetRecord()
    begin
        Clear(VisibleonCancel);
        PurchNPay.Get();
        if PurchNPay."Cancel Purchase Order Feature" then
            VisibleonCancel := true
        else
            VisibleonCancel := false;
    end;

    //Azhar++
    trigger OnAfterGetCurrRecord()
    var
    begin
        Clear(VarPageEditFlag);
        if Rec."PO Cancelled" = true then begin
            VarPageEditFlag := false;
        end else begin
            VarPageEditFlag := true;
        end;


    end;
    //Azhar--

    var
        VarPageEditFlag: Boolean;//Azhar
        VisibleonCancel: Boolean;
        PurchNPay: Record "Purchases & Payables Setup";


    local procedure DeleteReservationEntries(_PurchaseLine: Record "Purchase Line")
    var
        L_Reservation: Record "Reservation Entry";
    begin
        L_Reservation.Reset();
        L_Reservation.SetRange("Source Type", 39);
        L_Reservation.SetRange("Source Subtype", 1);
        L_Reservation.SetRange("Source ID", _PurchaseLine."Document No.");
        L_Reservation.SetRange("Source Ref. No.", _PurchaseLine."Line No.");
        if L_Reservation.FindSet() then
            L_Reservation.DeleteAll();
    end;



}