pageextension 70701 CancelSOOrder extends "Sales Order"
{
    layout
    {
        addafter("Work Description")
        {
            field(Cancel; Rec.Cancel)
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
        modify(Control1900201301)
        {
            Editable = VarPageEditFlag;
        }
        modify("Print on Despatch")
        {
            Editable = VarPageEditFlag;
        }
        modify("Shipping and Billing")
        {
            Editable = VarPageEditFlag;
        }
        modify(SalesLines)
        {
            Enabled = VarPageEditFlag;
        }
    }

    actions
    {
        addafter("O&rder")
        {
            group("Cancel Sales Order")
            {
                Caption = 'Cancel Sales Order';
                Visible = VisibleonCancel;
                action("Cancel Order")
                {
                    ToolTip = 'Cancel Sales Order';
                    Image = Cancel;
                    ApplicationArea = All;
                    Visible = VisibleOnCancel;
                    trigger OnAction()
                    var
                        L_SalesLine: Record "Sales Line";
                        WareShipLine: Record "Warehouse Shipment Line";
                        WareShipHeader: Record "Warehouse Shipment Header";
                        ReleaseDoc: Codeunit "Release Sales Document";
                        TakeWhseActvityLine: Record "Warehouse Activity Line";
                        ReleaseWhseShptDoc: Codeunit "Whse.-Shipment Release";
                        Canceled: Boolean;
                        ArchiveManagement: Codeunit ArchiveManagement;
                        VariantCOde: Code[20];
                        OriginalQty: Decimal;
                        L_SalesHeader: Record "Sales Header";
                        OriginalUnitPrice: Decimal;

                        L_Location: Record Location;
                        L_WarehouseActivityHeader: Record "Warehouse Activity Header";
                    begin
                        //Check Setup++
                        SalesRecSet.Get();
                        if not SalesRecSet."Cancel Sales Order Feature" then begin
                            Error('Enable Cancel Sales order feature on Sales & Receivable setup to unlock this feature');
                        end;

                        //Confirmation Dialog++
                        if not Confirm('Do you want to cancel this order?', false) then
                            exit;

                        //Check Status++
                        if Rec.Status = Rec.Status::Released then
                            ReleaseDoc.PerformManualReopen(Rec);
                        Rec.TestField(Status, Rec.Status::Open);

                        //Start Process++
                        L_SalesLine.Reset();
                        L_SalesLine.SetRange("Document Type", Rec."Document Type");
                        L_SalesLine.SetRange("Document No.", Rec."No.");
                        L_SalesLine.SetFilter(Type, '%1|%2', L_SalesLine.Type::Item, L_SalesLine.Type::"G/L Account");
                        L_SalesLine.SetRange(Cancelled, false);
                        if L_SalesLine.FindSet() then begin
                            repeat
                                //Check Return Reason Code++
                                if L_SalesLine."Cancel Reason code" = '' then
                                    Error('Please Select Cancel Reason Code for Line No: %1', L_SalesLine."Line No.");

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

                        //Update Header++
                        L_SalesLine.Reset();
                        L_SalesLine.SetRange("Document Type", Rec."Document Type");
                        L_SalesLine.SetRange("Document No.", Rec."No.");
                        L_SalesLine.SetFilter(Type, '%1|%2', L_SalesLine.Type::Item, L_SalesLine.Type::"G/L Account");
                        L_SalesLine.SetRange(Cancelled, false);
                        if not L_SalesLine.FindFirst() then begin
                            if L_SalesHeader.Get(Rec."Document Type"::Order, Rec."No.") then begin
                                L_SalesHeader.Cancel := true;
                                L_SalesHeader."Cancelled By" := UserId;
                                L_SalesHeader."Cancelled Date" := Today;
                                L_SalesHeader.Modify();

                                //ReleaseDoc.PerformManualRelease(L_SalesHeader); //Prathamesh++

                                // //Send Canceled Order to Archive++
                                // ArchiveManagement.StoreSalesDocument(L_SalesHeader, false);

                                //Delete Order++
                                DeleteSalesHeader(L_SalesHeader);
                            end;
                        end;
                        Message('Sales order is cancelled');
                    end;
                }
            }
        }
        addafter(Category_Category7)
        {
            group(Category_Category77)
            {
                Caption = 'Cancel Sales Order';
                actionref(CancelOrder; "Cancel Order")
                {
                }
            }
        }
    }
    trigger OnAfterGetCurrRecord()
    var
    begin
        Clear(VarPageEditFlag);

        if Rec.Cancel then
            VarPageEditFlag := false
        else
            VarPageEditFlag := true;

    end;

    trigger OnOpenPage()
    begin
        Clear(VisibleOnCancel);
        SalesRecSet.Get();
        if not SalesRecSet."Cancel Sales Order Feature" then
            VisibleOnCancel := false
        else
            VisibleOnCancel := true;

    end;

    var

        VarPageEditFlag: Boolean;//Azhar

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

    local procedure DeleteSalesHeader(L_SalesHeader: Record "Sales Header")
    begin
        if L_SalesHeader.Cancel = true then
            L_SalesHeader.Delete(true);
    end;
}