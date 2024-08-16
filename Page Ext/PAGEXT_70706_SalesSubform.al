pageextension 70706 SalesOrdSub extends "Sales Order Subform"
{
    layout
    {
        modify(Quantity)
        {
            Editable = not Rec.Cancelled = true;
        }

        modify("Variant Code")
        {
            Editable = not Rec.Cancelled = true;
        }
        modify("Qty. to Invoice")
        {
            Editable = not Rec.Cancelled = true;
        }
        modify("Qty. to Ship")
        {
            Editable = not Rec.Cancelled = true;
        }
        modify("Unit Price")
        {
            Editable = not Rec.Cancelled = true;
        }
        addafter(Quantity)
        {
            field("Original Order Quantity"; Rec."Original Order Quantity")
            {
                Visible = VisibleOnCancel;
                //Editable = not Rec.Cancelled = true;
                ApplicationArea = All;
                Editable = false;
            }
        }
        addlast(Control1)
        {
            field("Cancel Reason code"; Rec."Cancel Reason code")
            {
                Visible = VisibleOnCancel;
                Caption = 'Cancel Reason Code';
                Editable = not Rec.Cancelled = true;
                ApplicationArea = All;
            }
            field(Cancelled; Rec.Cancelled)
            {
                Caption = 'SO Cancelled';
                ApplicationArea = All;
                Editable = false;
                Visible = VisibleOnCancel;
            }
            field("Cancelled By"; Rec."Cancelled By")
            {
                Caption = 'SO Cancelled By';
                ApplicationArea = All;
                Editable = false;
                Visible = VisibleOnCancel;
            }
            field("Cancelled Date"; Rec."Cancelled Date")
            {
                Caption = 'SO Cancellation Date';
                ApplicationArea = All;
                Editable = false;
                Visible = VisibleOnCancel;
            }
        }
    }

    actions
    {
        addafter("&Line")
        {
            group("Cancel Sales Order")
            {
                Caption = 'Cancel Sales Order';
                Visible = VisibleonCancel;
                action("Cancel Line")
                {
                    ToolTip = 'Cancel the selected row';
                    Image = Cancel;
                    ApplicationArea = All;
                    Visible = VisibleOnCancel;
                    trigger OnAction()
                    var
                        L_SalesLine: Record "Sales Line";
                        ReleaseDoc: Codeunit "Release Sales Document";
                        WareShipLine: Record "Warehouse Shipment Line";
                        WareShipHeader: Record "Warehouse Shipment Header";
                        L_SalesHeader: Record "Sales Header";
                        VariantCOde: Code[20];
                        OriginalQty: Decimal;
                        OriginalUnitPrice: Decimal;
                        L_WarehouseActivityHeader: Record "Warehouse Activity Header";
                        L_KnappOrderResponse: Record "Knapp Order Response";
                        L_ItemVariant: Record "Item Variant";
                        L_SalesShipmentHeader: Record "Sales Shipment Header";
                    begin
                        //Check Setup++
                        SalesRecSet.Get();
                        if not SalesRecSet."Cancel Sales Order Feature" then begin
                            Error('Enable Cancel Sales order feature on Sales & Receivable setup to unlock this feature');
                        end;

                        //Confimation Box++
                        if not Confirm('Do you want to cancel selected line?', false) then
                            exit;

                        //Check Status++
                        L_SalesHeader.Reset();
                        L_SalesHeader.SetRange("Document Type", Rec."Document Type");
                        L_SalesHeader.SetRange("No.", Rec."Document No.");
                        if L_SalesHeader.FindFirst() then begin
                            if L_SalesHeader.Status = L_SalesHeader.Status::Released then
                                ReleaseDoc.PerformManualReopen(L_SalesHeader);
                            L_SalesHeader.TestField(Status, L_SalesHeader.Status::Open);
                        end;

                        //If Knapp Order Response is Available then do not cancel/delete the Sales Order
                        L_SalesShipmentHeader.Reset();
                        L_SalesShipmentHeader.SetRange("Order No.", Rec."Document No.");
                        if not L_SalesShipmentHeader.FindFirst() then begin
                            L_KnappOrderResponse.Reset();
                            L_KnappOrderResponse.SetRange("Document Type", L_KnappOrderResponse."Document Type"::Order);
                            L_KnappOrderResponse.SetRange("Document No.", Rec."Document No.");
                            if L_KnappOrderResponse.FindFirst() then
                                Error(StrSubstNo('Not able to Cancel/Delete Order %1 as it has Knapp Order Responses against it.', Rec."Document No."));
                        end;

                        L_SalesLine.Reset();
                        CurrPage.SetSelectionFilter(L_SalesLine);
                        L_SalesLine.SetFilter(Type, '%1|%2', L_SalesLine.Type::Item, L_SalesLine.Type::"G/L Account");
                        L_SalesLine.SetRange(Cancelled, false);
                        if L_SalesLine.FindSet() then begin
                            repeat
                                //Check Return Reason Code++
                                if L_SalesLine."Cancel Reason code" = '' then
                                    Error('Please Select Cancel Reason Code for Line No: %1', L_SalesLine."Line No.");

                                //If Variant is available on Sales Line but that variant is not there in Item Variant List then don't delete the Order.
                                if L_SalesLine."Variant Code" <> '' then begin
                                    L_ItemVariant.Reset();
                                    L_ItemVariant.SetRange("Item No.", L_SalesLine."No.");
                                    L_ItemVariant.SetFilter(Code, '%1', L_SalesLine."Variant Code");
                                    if not L_ItemVariant.FindFirst() then
                                        Error(StrSubstNo('Not able to Cancel/Delete Order %1 as Item %2 that has Variant %3 is not available in Item Variant.', L_SalesLine."Document No.", L_SalesLine."No.", L_SalesLine."Variant Code"));
                                end;

                                //Chcek Warehouse Shipment exists +++
                                WareShipLine.Reset();
                                WareShipLine.SETRANGE("Source Document", WareShipLine."Source Document"::"Sales Order");
                                WareShipLine.SetRange("Source No.", L_SalesLine."Document No.");
                                WareShipLine.SetRange("Source Line No.", L_SalesLine."Line No.");
                                if WareShipLine.FindFirst() then
                                    Error('Unable to process ... Warehouse shipment %1 exist for Order No.: %2 Line No.: %3', WareShipLine."No.", WareShipLine."Source No.", WareShipLine."Source Line No.");

                                //Check Inve Pick++
                                L_WarehouseActivityHeader.Reset();
                                L_WarehouseActivityHeader.SetRange(Type, L_WarehouseActivityHeader.Type::"Invt. Pick");
                                L_WarehouseActivityHeader.SetRange("Source Document", L_WarehouseActivityHeader."Source Document"::"Sales Order");
                                L_WarehouseActivityHeader.SetRange("Source No.", L_SalesLine."Document No.");
                                if L_WarehouseActivityHeader.FindFirst() then
                                    Error('Unable to process ... Inventory Pick %1 exist for Order No.: %2', L_WarehouseActivityHeader."No.", L_WarehouseActivityHeader."Source No.");

                                //Check Invoice Pending++
                                if L_SalesLine."Qty. Shipped Not Invoiced" > 0 then
                                    Error('Total %1 quantity shipped but invoiced quantity %2.Invoice is pending for Order No. : %3 Line No. : %4 ', L_SalesLine."Quantity Shipped", L_SalesLine."Quantity Invoiced", L_SalesLine."Document No.", L_SalesLine."Line No.");

                                //Update Sales Line++
                                if L_SalesLine.Type = L_SalesLine.Type::Item then begin
                                    //Delete Remaining Reservation Entries.
                                    DeleteReservationEntries(L_SalesLine);

                                    Clear(VariantCOde);
                                    Clear(OriginalQty);
                                    Clear(OriginalUnitPrice);
                                    VariantCOde := L_SalesLine."Variant Code";
                                    OriginalQty := L_SalesLine.Quantity;
                                    OriginalUnitPrice := L_SalesLine."Unit Price";

                                    L_SalesLine.Validate(Quantity, L_SalesLine."Quantity Shipped");
                                    L_SalesLine.Validate("Original Order Quantity", OriginalQty);
                                    L_SalesLine.Validate("Unit Price", OriginalUnitPrice);
                                    if VariantCOde <> '' then begin
                                        L_SalesLine."Variant Code" := VariantCOde;
                                        L_SalesLine.Validate("Variant Code");
                                    end;
                                    L_SalesLine.Cancelled := true;
                                    L_SalesLine."Cancelled By" := UserId;
                                    L_SalesLine."Cancelled Date" := Today;
                                    L_SalesLine."Completely Shipped" := true; //Prathamesh++
                                    L_SalesLine.Modify();
                                end else
                                    if L_SalesLine.Type = L_SalesLine.Type::"G/L Account" then begin
                                        Clear(OriginalQty);
                                        Clear(OriginalUnitPrice);
                                        OriginalQty := L_SalesLine.Quantity;
                                        OriginalUnitPrice := L_SalesLine."Unit Price";

                                        L_SalesLine.Validate(Quantity, L_SalesLine."Quantity Shipped");
                                        L_SalesLine.Validate("Original Order Quantity", OriginalQty);
                                        L_SalesLine.Validate("Unit Price", OriginalUnitPrice);
                                        L_SalesLine.Cancelled := true;
                                        L_SalesLine."Cancelled By" := UserId;
                                        L_SalesLine."Cancelled Date" := Today;
                                        L_SalesLine."Completely Shipped" := true; //Prathamesh++
                                        L_SalesLine.Modify();
                                    end;
                            until L_SalesLine.Next() = 0;
                        end;
                        Message('Selected Lines are cancelled');
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
    begin
        Clear(VarPageEditFlag);
        if Rec.Cancelled then
            VarPageEditFlag := false
        else
            VarPageEditFlag := true;
    end;

    trigger OnOpenPage()
    begin
        clear(VisibleOnCancel);
        SalesRecSet.Get();
        if not SalesRecSet."Cancel Sales Order Feature" then
            VisibleOnCancel := false
        else
            VisibleOnCancel := true;
    end;

    trigger OnAfterGetRecord()
    begin
        clear(VisibleOnCancel);
        SalesRecSet.Get();
        if not SalesRecSet."Cancel Sales Order Feature" then
            VisibleOnCancel := false
        else
            VisibleOnCancel := true;
    end;

    var
        VarPageEditFlag: Boolean;
        VisibleOnCancel: Boolean;
        SalesRecSet: Record "Sales & Receivables Setup";

    local procedure DeleteReservationEntries(_SalesLine: Record "Sales Line")
    var
        L_Reservation: Record "Reservation Entry";
    begin
        L_Reservation.Reset();
        L_Reservation.SetRange("Source Type", 37);
        L_Reservation.SetRange("Source Subtype", 1);
        L_Reservation.SetRange("Source ID", _SalesLine."Document No.");
        L_Reservation.SetRange("Source Ref. No.", _SalesLine."Line No.");
        if L_Reservation.FindSet() then
            L_Reservation.DeleteAll();
    end;
}