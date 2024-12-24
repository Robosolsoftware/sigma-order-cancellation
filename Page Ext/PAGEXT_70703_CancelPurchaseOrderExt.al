pageextension 70703 CancelPO extends "Purchase Order"
{
    layout
    {
        modify(Prepayment)
        {
            Editable = VarPageEditFlag;
        }
        modify("Shipping and Payment")
        {
            Editable = VarPageEditFlag;
        }
        modify("Invoice Details")
        {
            Editable = VarPageEditFlag;
        }
        modify(General)
        {
            Editable = VarPageEditFlag;
        }
        modify("Foreign Trade")
        {
            Editable = VarPageEditFlag;
        }
        modify(PurchLines)
        {
            Enabled = VarPageEditFlag;
        }
        addlast(General)
        {
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
        modify(Release)
        {
            trigger OnAfterAction()
            var
                L_PurchLine: Record "Purchase Line";
            begin
                L_PurchLine.Reset();
                L_PurchLine.SetRange("Document Type", L_PurchLine."Document Type"::Order);
                L_PurchLine.SetRange("Document No.", Rec."No.");
                L_PurchLine.SetRange(Type, L_PurchLine.Type::Item);
                if L_PurchLine.FindSet() then begin
                    repeat
                        L_PurchLine.Validate("Original Order Quantity", L_PurchLine.Quantity);
                        L_PurchLine.Modify();
                    until L_PurchLine.Next() = 0;
                end;
            end;
        }
        addafter("O&rder")
        {
            group("Cancel Purchase Order")
            {
                Caption = 'Cancel Purchase Order';
                Visible = VisibleonCancel;
                action("Cancel Order")
                {
                    ToolTip = 'Cancel purchase Order';
                    Image = Cancel;
                    ApplicationArea = All;
                    Visible = VisibleonCancel;
                    trigger OnAction()
                    var
                        L_PurchLine: Record "Purchase Line";
                        ReleaseDoc: Codeunit "Release Purchase Document";
                        WhseRcptHeader: Record "Warehouse Receipt Header";
                        WhseRcptLine: Record "Warehouse Receipt Line";
                        L_CountWhseRcptLine: Record "Warehouse Receipt Line";
                        TakeWhseActvityLine: Record "Warehouse Activity Line";
                        Canceled: Boolean;
                        RecPurchaseLine: Record "Purchase Line";//Azhar
                        PurchaseAndPayableSetup: Record "Purchases & Payables Setup";
                        VariantCOde: Code[20];
                        OriginalQty: Decimal;
                        OriginalUnitCost: Decimal;
                        L_PurchaseHeader: Record "Purchase Header";
                        ArchiveManagement: Codeunit ArchiveManagement;
                        L_ReceiptNo: Code[2000];
                    begin
                        //Check Setup++
                        PurchaseAndPayableSetup.Get();
                        if PurchaseAndPayableSetup."Cancel Purchase Order Feature" = false then
                            Error('Enable Cancel Purchase order feature on Purchase & Payables setup to unlock this feature');


                        //Confimation Box++
                        if not Confirm('Do you want to cancel this order?', false) then
                            exit;

                        //Check Status++
                        if Rec.Status = Rec.Status::Released then
                            ReleaseDoc.PerformManualReopen(Rec);
                        Rec.TestField(Status, Rec.Status::Open);


                        //Start Process++
                        L_PurchLine.Reset();
                        L_PurchLine.SetRange("Document Type", Rec."Document Type");
                        L_PurchLine.SetRange("Document No.", Rec."No.");
                        L_PurchLine.SetFilter(Type, '%1|%2', L_PurchLine.Type::Item, L_PurchLine.Type::"G/L Account");
                        L_PurchLine.SetRange("PO Cancelled", false);
                        if L_PurchLine.FindSet() then begin
                            repeat
                                //Check Cancel Reason++
                                if L_PurchLine."Cancel Reason code" = '' then
                                    Error('Please Select Cancel Reason Code for Item No:%1 Line No:%2', L_PurchLine."No.", L_PurchLine."Line No.");

                                //Check if warehouse Receipt line exist++
                                WhseRcptLine.Reset();
                                WhseRcptLine.SETRANGE("Source Document", WhseRcptLine."Source Document"::"Purchase Order");
                                WhseRcptLine.SetRange("Source No.", L_PurchLine."Document No.");
                                WhseRcptLine.SetRange("Source Line No.", L_PurchLine."Line No.");
                                if WhseRcptLine.FindFirst() then
                                    Error('Unable to process ... Warehouse Receipt No. %1 exist for Order No.: %2 Line No.: %3', WhseRcptLine."No.", WhseRcptLine."Source No.", WhseRcptLine."Source Line No.");

                                //Check Put Away Available++
                                TakeWhseActvityLine.Reset();
                                TakeWhseActvityLine.SetRange("Source Document", TakeWhseActvityLine."Source Document"::"Purchase Order");
                                TakeWhseActvityLine.SetRange("Source No.", L_PurchLine."Document No.");
                                TakeWhseActvityLine.SetRange("Source Line No.", L_PurchLine."Line No.");
                                TakeWhseActvityLine.SetRange("Activity Type", TakeWhseActvityLine."Activity Type"::"Put-away");
                                if TakeWhseActvityLine.FindFirst() then
                                    Error('Unable to process ... Warehouse putaway No. %1 exists: in Purchase Line Document Type= %2,Document No.= %3,Line No.=%4', TakeWhseActvityLine."No.", L_PurchLine."Document Type", L_PurchLine."Document No.", L_PurchLine."Line No.");

                                //Check Invoice Quantity++   
                                if L_PurchLine."Qty. Rcd. Not Invoiced" > 0 then
                                    Error('Total %1 quantity received but invoiced quantity %2.Invoice is pending for Order No. : %3 Line No. : %4 ', L_PurchLine."Quantity Received", L_PurchLine."Quantity Invoiced", L_PurchLine."Document No.", L_PurchLine."Line No.");

                                if L_PurchLine.Type = L_PurchLine.Type::Item then begin
                                    //Delete Reservation++
                                    DeleteReservationEntries(L_PurchLine);

                                    Clear(VariantCOde);
                                    Clear(OriginalQty);
                                    Clear(OriginalUnitCost);
                                    VariantCOde := L_PurchLine."Variant Code";
                                    OriginalQty := L_PurchLine.Quantity;
                                    OriginalUnitCost := L_PurchLine."Unit Cost";

                                    L_PurchLine.Validate(Quantity, L_PurchLine."Quantity Received");
                                    L_PurchLine.Validate("Original Order Quantity", OriginalQty);
                                    L_PurchLine.Validate("Unit Cost", OriginalUnitCost);
                                    if VariantCOde <> '' then begin
                                        L_PurchLine."Variant Code" := VariantCOde;
                                        L_PurchLine.Validate("Variant Code");
                                    end;

                                    L_PurchLine."PO Cancelled" := true;
                                    L_PurchLine."PO Cancelled By" := UserId;
                                    L_PurchLine."PO Cancellation Date" := Today;
                                    L_PurchLine.Modify();
                                    Canceled := true;
                                end else
                                    if L_PurchLine.Type = L_PurchLine.Type::"G/L Account" then begin
                                        Clear(OriginalQty);
                                        Clear(OriginalUnitCost);
                                        OriginalQty := L_PurchLine.Quantity;
                                        OriginalUnitCost := L_PurchLine."Unit Cost";

                                        L_PurchLine.Validate(Quantity, L_PurchLine."Quantity Received");
                                        L_PurchLine.Validate("Original Order Quantity", OriginalQty);
                                        L_PurchLine.Validate("Unit Cost", OriginalUnitCost);

                                        L_PurchLine."PO Cancelled" := true;
                                        L_PurchLine."PO Cancelled By" := UserId;
                                        L_PurchLine."PO Cancellation Date" := Today;
                                        L_PurchLine.Modify();
                                        Canceled := true;
                                    end;
                            until L_PurchLine.Next() = 0;
                        end;

                        //Update Header++
                        L_PurchLine.Reset();
                        L_PurchLine.SetRange("Document Type", Rec."Document Type");
                        L_PurchLine.SetRange("Document No.", Rec."No.");
                        L_PurchLine.SetFilter(Type, '%1|%2', L_PurchLine.Type::Item, L_PurchLine.Type::"G/L Account");
                        L_PurchLine.SetRange("PO Cancelled", false);
                        if not L_PurchLine.FindFirst() then begin
                            if L_PurchaseHeader.Get(Rec."Document Type", Rec."No.") then begin
                                L_PurchaseHeader."PO Cancelled" := true;
                                L_PurchaseHeader."PO Cancelled By" := UserId;
                                L_PurchaseHeader."PO Cancellation Date" := Today;
                                L_PurchaseHeader.Modify();

                                //ReleaseDoc.PerformManualRelease(L_PurchaseHeader);

                                // //Send Canceled Order to Archive++
                                // ArchiveManagement.StorePurchDocument(L_PurchaseHeader, false); //Send Canceled Order to Archive++

                                //Delete Order++
                                DeletePO(L_PurchaseHeader);
                            end;
                        end;
                    end;
                }
            }

        }

        addafter(Category_Category7)
        {
            group(Category_Category77)
            {
                Caption = 'Cancel Purchase Order';
                actionref(CancelOrder; "Cancel Order")
                {

                }
            }
        }
    }

    var
        VarPageEditFlag: Boolean;
        VisibleonCancel: Boolean;

        PurchNPay: Record "Purchases & Payables Setup";

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

    trigger OnOpenPage()
    begin
        Clear(VisibleonCancel);
        PurchNPay.Get();
        if PurchNPay."Cancel Purchase Order Feature" then
            VisibleonCancel := true
        else
            VisibleonCancel := false;
    end;

    procedure DeletePO(_PurchaseHeader: Record "Purchase Header")
    begin
        if _PurchaseHeader."PO Cancelled" = true then
            _PurchaseHeader.Delete(true);

    end;

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