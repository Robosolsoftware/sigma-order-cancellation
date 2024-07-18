//This is for Job Queue++
report 70703 "Cancel Back Sales Order"
{
    ApplicationArea = All;
    Caption = 'Cancel Back Sales Order';
    UsageCategory = ReportsAndAnalysis;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Integer; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            trigger OnAfterGetRecord()
            var
                L_SalesHeader: Record "Sales Header";
                L_ErrorText: Text[2000];
                L_ErrorFound: Boolean;
                L_SalesLine: Record "Sales Line";
                WareShipLine: Record "Warehouse Shipment Line";
                L_WarehouseActivityHeader: Record "Warehouse Activity Header";
                VariantCOde: Code[20];
                OriginalQty: Decimal;
                OriginalUnitPrice: Decimal;
                ArchiveManagement: Codeunit ArchiveManagement;
                Delete_SalesHeader: Record "Sales Header";
                Text_Date: Text;
                ReleaseDoc: Codeunit "Release Sales Document";
                L_ErrorBuff: Record "Error Log";
            begin
                //Prepare Sales Order to Cancel++
                Clear(Text_Date);
                Text_Date := '-' + Format(StartDate);
                L_SalesHeader.Reset();
                L_SalesHeader.SetRange("Document Type", L_SalesHeader."Document Type"::Order);
                L_SalesHeader.SetFilter("Shipment Date", '%1..%2', EndDate, CalcDate(Text_Date, WorkDate()));
                L_SalesHeader.SetRange(Cancel, false);
                L_SalesHeader.CalcFields("Drop/Special Order", "Special Order");
                L_SalesHeader.SetRange("Drop/Special Order", false); //Drop Shipment Order
                L_SalesHeader.SetRange("Special Order", false); //Special Order
                if L_SalesHeader.FindSet() then begin
                    repeat
                        Clear(L_ErrorFound);
                        Clear(L_ErrorText);

                        //Delete Error logs++
                        Clear(L_ErrorFound);
                        L_ErrorBuff.Reset();
                        L_ErrorBuff.SetRange("Document Type", L_SalesHeader."Document Type");
                        L_ErrorBuff.SetRange("Document No.", L_SalesHeader."No.");
                        if L_ErrorBuff.FindSet() then
                            L_ErrorBuff.DeleteAll();

                        //For 1st Error++
                        if L_ErrorFound = false then begin
                            if (L_SalesHeader.Status <> L_SalesHeader.Status::Open) AND (L_SalesHeader.Status <> L_SalesHeader.Status::Released) then begin
                                L_ErrorText := StrSubstNo('Status should not be %1', L_SalesHeader.Status);
                                InsertErrorLogCanceledOrder(L_SalesHeader, L_ErrorText);
                                L_ErrorFound := true;
                            end;
                        end;

                        //For 2nd Error++
                        if L_ErrorFound = false then begin
                            //Chcek Warehouse Shipment exists +++
                            Clear(L_ErrorText);
                            WareShipLine.Reset();
                            WareShipLine.SetRange("Source Document", WareShipLine."Source Document"::"Sales Order");
                            WareShipLine.SetRange("Source No.", L_SalesHeader."No.");
                            if WareShipLine.FindFirst() then begin
                                L_ErrorText := StrSubstNo('Unable to process ... Warehouse shipment %1 exist for Order No.: %2 Line No.: %3', WareShipLine."No.", WareShipLine."Source No.", WareShipLine."Source Line No.");
                                InsertErrorLogCanceledOrder(L_SalesHeader, L_ErrorText);
                                L_ErrorFound := true;
                            end;
                        end;

                        //For 3nd Error++
                        if L_ErrorFound = false then begin
                            //Check Inve Pick++
                            Clear(L_ErrorText);
                            L_WarehouseActivityHeader.Reset();
                            L_WarehouseActivityHeader.SetRange(Type, L_WarehouseActivityHeader.Type::"Invt. Pick");
                            L_WarehouseActivityHeader.SetRange("Source Document", L_WarehouseActivityHeader."Source Document"::"Sales Order");
                            L_WarehouseActivityHeader.SetRange("Source No.", L_SalesHeader."No.");
                            if L_WarehouseActivityHeader.FindFirst() then begin
                                L_ErrorText := StrSubstNo('Unable to process ... Inventory Pick %1 exist for Order No.: %2', L_WarehouseActivityHeader."No.", L_WarehouseActivityHeader."Source No.");
                                InsertErrorLogCanceledOrder(L_SalesHeader, L_ErrorText);
                                L_ErrorFound := true;
                            end;
                        end;

                        //For 4rd Error++
                        if L_ErrorFound = false then begin
                            Clear(L_ErrorText);
                            L_SalesLine.Reset();
                            L_SalesLine.SetRange("Document Type", L_SalesHeader."Document Type"::Order);
                            L_SalesLine.SetRange("Document No.", L_SalesHeader."No.");
                            L_SalesLine.SetFilter(Type, '%1|%2', L_SalesLine.Type::Item, L_SalesLine.Type::"G/L Account");
                            L_SalesLine.SetRange(Cancelled, false);
                            L_SalesLine.SetFilter("Qty. Shipped Not Invoiced", '>%1', 0);
                            if L_SalesLine.FindFirst() then begin
                                L_ErrorText := StrSubstNo('Total %1 quantity shipped but invoiced quantity %2.Invoice is pending for Order No. : %3 Line No. : %4 ', L_SalesLine."Quantity Shipped", L_SalesLine."Quantity Invoiced", L_SalesLine."Document No.", L_SalesLine."Line No.");
                                InsertErrorLogCanceledOrder(L_SalesHeader, L_ErrorText);
                                L_ErrorFound := true;
                            end;
                        end;

                        //Run Cancel Process++
                        if L_ErrorFound = false then begin
                            //Check Status++
                            if L_SalesHeader.Status = L_SalesHeader.Status::Released then
                                ReleaseDoc.PerformManualReopen(L_SalesHeader);
                            L_SalesHeader.TestField(Status, L_SalesHeader.Status::Open);

                            L_SalesLine.Reset();
                            L_SalesLine.SetRange("Document Type", L_SalesHeader."Document Type");
                            L_SalesLine.SetRange("Document No.", L_SalesHeader."No.");
                            L_SalesLine.SetFilter(Type, '%1|%2', L_SalesLine.Type::Item, L_SalesLine.Type::"G/L Account");
                            L_SalesLine.SetRange(Cancelled, false);
                            if L_SalesLine.FindSet() then begin
                                repeat
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
                                        L_SalesLine.Validate("Cancel Reason code", ReturnReasonCode);
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
                                            L_SalesLine.Validate("Cancel Reason code", ReturnReasonCode);
                                            L_SalesLine.Modify();
                                        end;
                                until L_SalesLine.Next() = 0;
                            end;

                            //Update Header++
                            L_SalesLine.Reset();
                            L_SalesLine.SetRange("Document Type", L_SalesHeader."Document Type");
                            L_SalesLine.SetRange("Document No.", L_SalesHeader."No.");
                            L_SalesLine.SetFilter(Type, '%1|%2', L_SalesLine.Type::Item, L_SalesLine.Type::"G/L Account");
                            L_SalesLine.SetRange(Cancelled, false);
                            if not L_SalesLine.FindFirst() then begin
                                Delete_SalesHeader.Reset();
                                if Delete_SalesHeader.Get(L_SalesHeader."Document Type"::Order, L_SalesHeader."No.") then begin
                                    Delete_SalesHeader.Cancel := true;
                                    Delete_SalesHeader."Cancelled By" := UserId;
                                    Delete_SalesHeader."Cancelled Date" := Today;
                                    Delete_SalesHeader.Modify();

                                    //ReleaseDoc.PerformManualRelease(Delete_SalesHeader); //Prathamesh++

                                    // //Send Canceled Order to Archive++
                                    // ArchiveManagement.StoreSalesDocument(Delete_SalesHeader, false);

                                    //Delete Order++
                                    DeleteSalesHeader(Delete_SalesHeader);
                                end;
                            end;
                        end;
                    until L_SalesHeader.Next() = 0;
                end;

            end;

            trigger OnPostDataItem()
            begin
                Message('Sales order is cancelled');
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Option)
                {
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Enter Back Shipment Date Period';
                        ShowMandatory = true;

                        trigger OnValidate()
                        var
                            Var_DateFormula: DateFormula;
                        begin
                            Clear(Var_DateFormula);
                            Clear(EndDate);
                            if StartDate = Var_DateFormula then begin
                                Error('Back Shipment Date Period should not be blank');
                            end else
                                EndDate := 19990101D;
                        end;
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = all;
                        Caption = 'End Date';
                        ShowMandatory = true;

                        trigger OnValidate()
                        var
                            Var_DateFormula: DateFormula;

                            Text_Date: Text;
                        begin
                            if EndDate <> 0D then begin
                                Clear(Var_DateFormula);
                                if StartDate = Var_DateFormula then
                                    Error('Back Shipment Date Period should not be blank');

                                Clear(Text_Date);
                                Text_Date := '-' + Format(StartDate);
                                if EndDate > CalcDate(Text_Date, WorkDate()) then
                                    Error('End Date should be less than %1', CalcDate(Text_Date, WorkDate()));
                            end;
                        end;
                    }
                    field(ReturnReasonCode; ReturnReasonCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Return Reason Code';
                        TableRelation = "Return Reason";
                        ShowMandatory = true;
                    }
                }
            }
        }

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        var
            Var_DateFormula: DateFormula;
        begin
            if CloseAction = CloseAction::OK then begin
                Clear(Var_DateFormula);
                if StartDate = Var_DateFormula then
                    Error('Back Shipment Date Period should not be blank');

                if EndDate = 0D then
                    Error('End Date should not be blank');


                if ReturnReasonCode = '' then
                    Error('Return Reason Code must have value');
            end;
        end;
    }


    local procedure InsertErrorLogCanceledOrder(SalesHeader: Record "Sales Header"; ErrorText: Text)
    var
        L_SalesHeader: Record "Sales Header";
        Last_ErrorLog: Record "Error Log";
    begin
        Clear(G_ErrorBuff);
        G_ErrorBuff.Init();

        Last_ErrorLog.Reset();
        if Last_ErrorLog.FindLast() then
            G_ErrorBuff."Entry No." := Last_ErrorLog."Entry No." + 1
        else
            G_ErrorBuff."Entry No." := 1;

        // if G_ErrorBuff.FindLast() then
        //     G_ErrorBuff."Entry No." += 1
        // Else
        //     G_ErrorBuff."Entry No." := 1;

        G_ErrorBuff."Clearance Error" := ErrorText;
        G_ErrorBuff."Created Date" := Today;
        G_ErrorBuff."Document No." := SalesHeader."No.";
        G_ErrorBuff."Document Type" := SalesHeader."Document Type";
        G_ErrorBuff.Insert();

        L_SalesHeader.Reset();
        L_SalesHeader.SetFilter("Document Type", '%1', L_SalesHeader."Document Type"::Order);
        L_SalesHeader.SetRange("No.", SalesHeader."No.");
        if L_SalesHeader.FindFirst() then begin
            L_SalesHeader."Error exist" := true;
            L_SalesHeader.Modify();
        end;
    end;

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
        if L_SalesHeader.Cancel = true then begin
            L_SalesHeader.Delete(true);
            Commit();
        end;
    end;


    var
        myInt: Integer;
        StartDate: DateFormula;
        EndDate: Date;
        G_ErrorBuff: Record "Error Log";
        ReturnReasonCode: Code[50];
        tes: Report 299;
}