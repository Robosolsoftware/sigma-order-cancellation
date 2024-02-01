report 70701 "Cancel Sales Order"
{
    ApplicationArea = All;
    Caption = 'Cancel Sales Order';
    UsageCategory = ReportsAndAnalysis;
    ProcessingOnly = true;
    dataset
    {
        dataitem(SalesHeader; "Sales Header")
        {
            trigger OnPreDataItem()
            begin
                SetFilter("Posting Date", '%1..%2', StartDate, EndDate);
            end;

            trigger OnAfterGetRecord()
            var
                L_SalesLine: Record "Sales Line";
                L_SalesHeader: Record "Sales Header";
                ReleaseDoc: Codeunit "Release Sales Document";
                ArchiveManagement: Codeunit ArchiveManagement;
                VariantCOde: Code[20];
                OriginalQty: Decimal;
                OriginalUnitPrice: Decimal;
            begin
                if (SalesHeader."Error exist" = false) AND (SalesHeader.Cancel = false) then begin
                    if SalesHeader.Status = SalesHeader.Status::Released then
                        ReleaseDoc.PerformManualReopen(SalesHeader);

                    L_SalesLine.Reset();
                    L_SalesLine.SetRange("Document Type", L_SalesLine."Document Type"::Order);
                    L_SalesLine.SetRange("Document No.", "No.");
                    //L_SalesLine.SetRange(Type, L_SalesLine.Type::Item);
                    L_SalesLine.SetRange(Cancelled, false);
                    if L_SalesLine.FindSet() then begin
                        repeat
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
                                if L_SalesLine.Cancelled = false then begin
                                    L_SalesLine.Validate("Original Order Quantity", OriginalQty);
                                    L_SalesLine.Validate("Unit Price", OriginalUnitPrice);
                                End;
                                L_SalesLine.Validate("Cancel Reason code", ReturnReasonCode);
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
                                    if L_SalesLine.Cancelled = false then begin
                                        L_SalesLine.Validate("Original Order Quantity", OriginalQty);
                                        L_SalesLine.Validate("Unit Price", OriginalUnitPrice);
                                    End;
                                    L_SalesLine.Validate("Cancel Reason code", ReturnReasonCode);
                                    L_SalesLine.Cancelled := true;
                                    L_SalesLine."Cancelled By" := UserId;
                                    L_SalesLine."Cancelled Date" := Today;
                                    L_SalesLine."Completely Shipped" := true; //Prathamesh++
                                    L_SalesLine.Modify();
                                end;
                        until L_SalesLine.Next() = 0;
                    end;

                    if L_SalesHeader.Get(SalesHeader."Document Type"::Order, SalesHeader."No.") then begin
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
            end;
        }
    }
    requestpage
    {
        SaveValues = true;
        layout
        {
            area(content)
            {
                group(GroupName)
                {
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Start Date';
                        ShowMandatory = true;
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = all;
                        Caption = 'End Date';
                        ShowMandatory = true;
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
        actions
        {
            area(processing)
            {
            }
        }
    }
    trigger OnPreReport()
    var
        L_ErrorText: Text[100];
        L_ErrorFound: Boolean;
    begin
        if ((StartDate = 0D) OR (EndDate = 0D)) then begin
            Error('Start Date and End Date must not be blank.');
        end;

        if ReturnReasonCode = '' then
            Error('Return Reason Code must have value.');



        G_SalesHeader.Reset();
        G_SalesHeader.SetFilter("Document Date", '%1..%2', StartDate, EndDate);
        if G_SalesHeader.FindSet() then begin
            repeat
                Clear(L_ErrorFound);
                G_ErrorBuff.Reset();
                G_ErrorBuff.SetRange("Document Type", G_SalesHeader."Document Type");
                G_ErrorBuff.SetRange("Document No.", G_SalesHeader."No.");
                if G_ErrorBuff.FindSet() then
                    G_ErrorBuff.DeleteAll();

                //For 1st Error++
                Clear(L_ErrorFound);
                Clear(L_ErrorText);
                if (G_SalesHeader.Status <> G_SalesHeader.Status::Open) AND (G_SalesHeader.Status <> G_SalesHeader.Status::Released) then begin
                    L_ErrorText := StrSubstNo('Status should not be %1', G_SalesHeader.Status);
                    InsertErrorLogCanceledOrder(G_SalesHeader, L_ErrorText);
                    L_ErrorFound := true;
                end;

                //For 2nd Error++
                if L_ErrorFound = false then begin
                    Clear(L_ErrorText);
                    G_WhseShipmentLine.Reset();
                    G_WhseShipmentLine.SetRange("Source Document", G_WhseShipmentLine."Source Document"::"Sales Order");
                    G_WhseShipmentLine.SetRange("Source No.", G_SalesHeader."No.");
                    if G_WhseShipmentLine.FindFirst() then begin
                        L_ErrorText := StrSubstNo('Unable to process ... Warehouse shipment %1 exist for Order No.: %2 Line No.: %3', G_WhseShipmentLine."No.", G_WhseShipmentLine."Source No.", G_WhseShipmentLine."Source Line No.");
                        InsertErrorLogCanceledOrder(G_SalesHeader, L_ErrorText);
                        L_ErrorFound := true;
                    end;
                end;

                //For 3rd Error++
                if L_ErrorFound = false then begin
                    Clear(L_ErrorText);
                    G_SaLesLine.Reset();
                    G_SaLesLine.SetRange("Document Type", G_SaLesLine."Document Type"::Order);
                    G_SaLesLine.SetRange("Document No.", G_SalesHeader."No.");
                    G_SaLesLine.SetFilter(Type, '%1|%2', G_SaLesLine.Type::Item, G_SaLesLine.Type::"G/L Account");
                    G_SaLesLine.SetRange(Cancelled, false);
                    if G_SaLesLine.FindSet() then begin
                        repeat
                            Clear(L_ErrorText);
                            if G_SaLesLine."Qty. Shipped Not Invoiced" > 0 then begin
                                L_ErrorText := StrSubstNo('Total %1 quantity shipped but invoiced quantity %2.Invoice is pending for Order No. : %3 Line No. : %4 ', G_SaLesLine."Quantity Shipped", G_SaLesLine."Quantity Invoiced", G_SaLesLine."Document No.", G_SaLesLine."Line No.");
                                InsertErrorLogCanceledOrder(G_SalesHeader, L_ErrorText);
                                L_ErrorFound := true;
                            end;
                        until G_SaLesLine.Next() = 0;
                    end;
                end;
            until G_SalesHeader.Next() = 0;
        end;
    end;

    trigger OnPostReport()
    begin
        //Message('Done');
    end;

    local procedure InsertErrorLogCanceledOrder(SalesHeader: Record "Sales Header"; ErrorText: Text)
    var
        L_SalesHeader: Record "Sales Header";
    begin
        G_ErrorBuff.Init();
        if G_ErrorBuff.FindLast() then
            G_ErrorBuff."Entry No." += 1
        Else
            G_ErrorBuff."Entry No." := 1;
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

    local procedure DeleteSalesHeader(L_SalesHeader: Record "Sales Header")
    begin
        if L_SalesHeader.Cancel = true then
            L_SalesHeader.Delete(true);
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

    var
        StartDate: Date;
        EndDate: Date;
        G_SalesHeader: Record "Sales Header";
        G_SaLesLine: Record "Sales Line";
        G_ErrorBuff: Record "Error Log";
        G_WhseShipmentLine: Record "Warehouse Shipment Line";
        ReturnReasonCode: Code[50];
}
