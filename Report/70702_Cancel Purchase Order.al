//Not Required +++++

// report 70702 "Cancel Purchase Order"
// {
//     ApplicationArea = All;
//     Caption = 'Cancel Purchase Order';
//     UsageCategory = ReportsAndAnalysis;
//     ProcessingOnly = true;
//     dataset
//     {
//         dataitem(PurchaseHeader; "Purchase Header")
//         {
//             trigger OnPreDataItem()
//             begin
//                 SetFilter("Document Date", '%1..%2', StartDate, EndDate);
//             end;

//             trigger OnAfterGetRecord()
//             var
//                 L_PurchaseLine: Record "Purchase Line";
//                 L_PurchaseHeader: Record "Purchase Header";
//                 ReleaseDoc: Codeunit "Release Purchase Document";
//                 WhseRcptLine: Record "Warehouse Receipt Line";
//                 WhseRcptHeader: Record "Warehouse Receipt Header";
//                 L_CountWhseRcptLine: Record "Warehouse Receipt Line";
//                 L_PurchLine: Record "Purchase Line";
//                 VariantCOde: Code[20];
//                 OriginalQty: Decimal;
//                 OriginalUnitCost: Decimal;
//                 ArchiveManagement: Codeunit ArchiveManagement;
//                 L_ReceiptNo: Code[2000];
//             begin
//                 if (PurchaseHeader."Error exist" = false) AND (PurchaseHeader."PO Cancelled" = false) then begin

//                     //Reopen the order++
//                     if PurchaseHeader.Status = PurchaseHeader.Status::Released then
//                         ReleaseDoc.PerformManualReopen(PurchaseHeader);

//                     //Update Qty on Purchase Line+++
//                     L_PurchLine.Reset();
//                     L_PurchLine.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
//                     L_PurchLine.SetRange("Document No.", PurchaseHeader."No.");
//                     //L_PurchLine.SetRange(Type, L_PurchLine.Type::Item);
//                     L_PurchLine.SetRange("PO Cancelled", false);
//                     if L_PurchLine.FindSet() then begin
//                         repeat
//                             if L_PurchLine.Type = L_PurchLine.Type::Item then begin
//                                 //Delete Reservation++
//                                 DeleteReservationEntries(L_PurchLine);

//                                 Clear(VariantCOde);
//                                 Clear(OriginalQty);
//                                 Clear(OriginalUnitCost);
//                                 VariantCOde := L_PurchLine."Variant Code";
//                                 OriginalQty := L_PurchLine.Quantity;
//                                 OriginalUnitCost := L_PurchLine."Unit Cost";

//                                 L_PurchLine.Validate(Quantity, L_PurchLine."Quantity Received");
//                                 if L_PurchLine."PO Cancelled" = false then begin
//                                     L_PurchLine.Validate("Original Order Quantity", OriginalQty);
//                                     L_PurchLine.Validate("Unit Cost", OriginalUnitCost);
//                                 End;
//                                 L_PurchLine.Validate("Cancel Reason code", ReturnReasonCode);
//                                 if VariantCOde <> '' then begin
//                                     L_PurchLine."Variant Code" := VariantCOde;
//                                     L_PurchLine.Validate("Variant Code");
//                                 end;

//                                 L_PurchLine."PO Cancelled" := true;
//                                 L_PurchLine."PO Cancelled By" := UserId;
//                                 L_PurchLine."PO Cancellation Date" := Today;
//                                 L_PurchLine.Modify();
//                             end else
//                                 if L_PurchLine.Type = L_PurchLine.Type::"G/L Account" then begin
//                                     Clear(OriginalQty);
//                                     Clear(OriginalUnitCost);
//                                     OriginalQty := L_PurchLine.Quantity;
//                                     OriginalUnitCost := L_PurchLine."Unit Cost";

//                                     L_PurchLine.Validate(Quantity, L_PurchLine."Quantity Received");
//                                     if L_PurchLine."PO Cancelled" = false then begin
//                                         L_PurchLine.Validate("Original Order Quantity", OriginalQty);
//                                         L_PurchLine.Validate("Unit Cost", OriginalUnitCost);
//                                     End;
//                                     L_PurchLine.Validate("Cancel Reason code", ReturnReasonCode);

//                                     L_PurchLine."PO Cancelled" := true;
//                                     L_PurchLine."PO Cancelled By" := UserId;
//                                     L_PurchLine."PO Cancellation Date" := Today;
//                                     L_PurchLine.Modify();
//                                 end;
//                         until L_PurchLine.Next() = 0;
//                     end;

//                     if L_PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.") then begin
//                         L_PurchaseHeader."PO Cancelled" := true;
//                         L_PurchaseHeader."PO Cancelled By" := UserId;
//                         L_PurchaseHeader."PO Cancellation Date" := Today;
//                         L_PurchaseHeader.Modify();

//                         //ReleaseDoc.PerformManualRelease(L_PurchaseHeader);

//                         // //Send Canceled Order to Archive++
//                         // ArchiveManagement.StorePurchDocument(L_PurchaseHeader, false); //Send Canceled Order to Archive++

//                         //Delete Order++
//                         DeletePurchaseHeader(L_PurchaseHeader);
//                     end;
//                     // //Check Warehouse Reciept and delete++
//                     // Clear(L_ReceiptNo);
//                     // WhseRcptLine.Reset();
//                     // WhseRcptLine.SETRANGE("Source Document", WhseRcptLine."Source Document"::"Purchase Order");
//                     // WhseRcptLine.SetRange("Source No.", PurchaseHeader."No.");
//                     // WhseRcptLine.SetCurrentKey("No.");
//                     // WhseRcptLine.Ascending(true);
//                     // if WhseRcptLine.FindSet() then begin
//                     //     //Delete Line for seleceted PO+++
//                     //     WhseRcptLine."Request For Cancel" := true;
//                     //     WhseRcptLine.Modify();
//                     //     WhseRcptLine.Delete(true);

//                     //     //Get Receipt No for delete header++
//                     //     if L_ReceiptNo <> '' then begin
//                     //         if L_ReceiptNo <> WhseRcptLine."No." then
//                     //             L_ReceiptNo := L_ReceiptNo + '|' + WhseRcptLine."No.";

//                     //     end else
//                     //         L_ReceiptNo := WhseRcptLine."No.";


//                     //     //Delete Header if line is empty++
//                     //     WhseRcptHeader.Reset();
//                     //     WhseRcptHeader.SetFilter("No.", L_ReceiptNo);
//                     //     if WhseRcptHeader.FindSet() then
//                     //         repeat
//                     //             L_CountWhseRcptLine.Reset();
//                     //             L_CountWhseRcptLine.SetRange("No.", WhseRcptHeader."No.");
//                     //             if L_CountWhseRcptLine.IsEmpty then
//                     //                 WhseRcptHeader.Delete(true);
//                     //         until WhseRcptHeader.Next() = 0;


//                     //     //Update Qty on Purchase Line+++
//                     //     L_PurchLine.Reset();
//                     //     L_PurchLine.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
//                     //     L_PurchLine.SetRange("Document No.", PurchaseHeader."No.");
//                     //     //L_PurchLine.SetRange(Type, L_PurchLine.Type::Item);
//                     //     L_PurchLine.SetRange("PO Cancelled", false);
//                     //     if L_PurchLine.FindSet() then begin
//                     //         repeat
//                     //             if L_PurchLine.Type = L_PurchLine.Type::Item then begin
//                     //                 //Delete Reservation++
//                     //                 DeleteReservationEntries(L_PurchLine);

//                     //                 Clear(VariantCOde);
//                     //                 Clear(OriginalQty);
//                     //                 Clear(OriginalUnitCost);
//                     //                 VariantCOde := L_PurchLine."Variant Code";
//                     //                 OriginalQty := L_PurchLine.Quantity;
//                     //                 OriginalUnitCost := L_PurchLine."Unit Cost";

//                     //                 L_PurchLine.Validate(Quantity, L_PurchLine."Quantity Received");
//                     //                 if L_PurchLine."PO Cancelled" = false then begin
//                     //                     L_PurchLine.Validate("Original Order Quantity", OriginalQty);
//                     //                     L_PurchLine.Validate("Unit Cost", OriginalUnitCost);
//                     //                 End;
//                     //                 L_PurchLine.Validate("Cancel Reason code", ReturnReasonCode);
//                     //                 if VariantCOde <> '' then begin
//                     //                     L_PurchLine."Variant Code" := VariantCOde;
//                     //                     L_PurchLine.Validate("Variant Code");
//                     //                 end;

//                     //                 L_PurchLine."PO Cancelled" := true;
//                     //                 L_PurchLine."PO Cancelled By" := UserId;
//                     //                 L_PurchLine."PO Cancellation Date" := Today;
//                     //                 L_PurchLine.Modify();
//                     //             end else
//                     //                 if L_PurchLine.Type = L_PurchLine.Type::"G/L Account" then begin
//                     //                     Clear(OriginalQty);
//                     //                     Clear(OriginalUnitCost);
//                     //                     OriginalQty := L_PurchLine.Quantity;
//                     //                     OriginalUnitCost := L_PurchLine."Unit Cost";

//                     //                     L_PurchLine.Validate(Quantity, L_PurchLine."Quantity Received");
//                     //                     if L_PurchLine."PO Cancelled" = false then begin
//                     //                         L_PurchLine.Validate("Original Order Quantity", OriginalQty);
//                     //                         L_PurchLine.Validate("Unit Cost", OriginalUnitCost);
//                     //                     End;
//                     //                     L_PurchLine.Validate("Cancel Reason code", ReturnReasonCode);

//                     //                     L_PurchLine."PO Cancelled" := true;
//                     //                     L_PurchLine."PO Cancelled By" := UserId;
//                     //                     L_PurchLine."PO Cancellation Date" := Today;
//                     //                     L_PurchLine.Modify();
//                     //                 end;
//                     //         until L_PurchLine.Next() = 0;

//                     //         if L_PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.") then begin
//                     //             L_PurchaseHeader."PO Cancelled" := true;
//                     //             L_PurchaseHeader."PO Cancelled By" := UserId;
//                     //             L_PurchaseHeader."PO Cancellation Date" := Today;
//                     //             L_PurchaseHeader.Modify();

//                     //             //ReleaseDoc.PerformManualRelease(L_PurchaseHeader);

//                     //             //Send Canceled Order to Archive++
//                     //             ArchiveManagement.StorePurchDocument(L_PurchaseHeader, false); //Send Canceled Order to Archive++

//                     //             //Delete Order++
//                     //             DeletePurchaseHeader(L_PurchaseHeader);
//                     //         end;
//                     //     end;
//                     // end else begin
//                     //     //Update Qty on Purchase Line+++
//                     //     L_PurchLine.Reset();
//                     //     L_PurchLine.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
//                     //     L_PurchLine.SetRange("Document No.", PurchaseHeader."No.");
//                     //     //L_PurchLine.SetRange(Type, L_PurchLine.Type::Item);
//                     //     L_PurchLine.SetRange("PO Cancelled", false);
//                     //     if L_PurchLine.FindSet() then begin
//                     //         repeat
//                     //             if L_PurchLine.Type = L_PurchLine.Type::Item then begin
//                     //                 //Delete Reservation++
//                     //                 DeleteReservationEntries(L_PurchLine);

//                     //                 Clear(VariantCOde);
//                     //                 Clear(OriginalQty);
//                     //                 Clear(OriginalUnitCost);
//                     //                 VariantCOde := L_PurchLine."Variant Code";
//                     //                 OriginalQty := L_PurchLine.Quantity;
//                     //                 OriginalUnitCost := L_PurchLine."Unit Cost";

//                     //                 L_PurchLine.Validate(Quantity, L_PurchLine."Quantity Received");
//                     //                 if L_PurchLine."PO Cancelled" = false then begin
//                     //                     L_PurchLine.Validate("Original Order Quantity", OriginalQty);
//                     //                     L_PurchLine.Validate("Unit Cost", OriginalUnitCost);
//                     //                 End;
//                     //                 L_PurchLine.Validate("Cancel Reason code", ReturnReasonCode);
//                     //                 if VariantCOde <> '' then begin
//                     //                     L_PurchLine."Variant Code" := VariantCOde;
//                     //                     L_PurchLine.Validate("Variant Code");
//                     //                 end;

//                     //                 L_PurchLine."PO Cancelled" := true;
//                     //                 L_PurchLine."PO Cancelled By" := UserId;
//                     //                 L_PurchLine."PO Cancellation Date" := Today;
//                     //                 L_PurchLine.Modify();
//                     //             end else
//                     //                 if L_PurchLine.Type = L_PurchLine.Type::"G/L Account" then begin
//                     //                     Clear(OriginalQty);
//                     //                     Clear(OriginalUnitCost);
//                     //                     OriginalQty := L_PurchLine.Quantity;
//                     //                     OriginalUnitCost := L_PurchLine."Unit Cost";

//                     //                     L_PurchLine.Validate(Quantity, L_PurchLine."Quantity Received");
//                     //                     if L_PurchLine."PO Cancelled" = false then begin
//                     //                         L_PurchLine.Validate("Original Order Quantity", OriginalQty);
//                     //                         L_PurchLine.Validate("Unit Cost", OriginalUnitCost);
//                     //                     End;
//                     //                     L_PurchLine.Validate("Cancel Reason code", ReturnReasonCode);

//                     //                     L_PurchLine."PO Cancelled" := true;
//                     //                     L_PurchLine."PO Cancelled By" := UserId;
//                     //                     L_PurchLine."PO Cancellation Date" := Today;
//                     //                     L_PurchLine.Modify();
//                     //                 end;
//                     //         until L_PurchLine.Next() = 0;

//                     //         if L_PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.") then begin
//                     //             L_PurchaseHeader."PO Cancelled" := true;
//                     //             L_PurchaseHeader."PO Cancelled By" := UserId;
//                     //             L_PurchaseHeader."PO Cancellation Date" := Today;
//                     //             L_PurchaseHeader.Modify();

//                     //             //ReleaseDoc.PerformManualRelease(L_PurchaseHeader);

//                     //             //Send Canceled Order to Archive++
//                     //             ArchiveManagement.StorePurchDocument(L_PurchaseHeader, false); //Send Canceled Order to Archive++

//                     //             //Delete Order++
//                     //             DeletePurchaseHeader(L_PurchaseHeader);
//                     //         end;
//                     //     end;
//                     // end;
//                 end;
//             end;
//         }
//     }
//     requestpage
//     {
//         SaveValues = true;
//         layout
//         {

//             area(content)
//             {
//                 group(Filter)
//                 {
//                     field(StartDate; StartDate)
//                     {
//                         ApplicationArea = All;
//                         Caption = 'Start Date';
//                         ShowMandatory = true;
//                     }
//                     field(EndDate; EndDate)
//                     {
//                         ApplicationArea = all;
//                         Caption = 'End Date';
//                         ShowMandatory = true;
//                     }
//                     field(ReturnReasonCode; ReturnReasonCode)
//                     {
//                         ApplicationArea = All;
//                         Caption = 'Return Reason Code';
//                         TableRelation = "Return Reason";
//                         ShowMandatory = true;
//                     }
//                 }
//             }
//         }
//         actions
//         {
//             area(processing)
//             {
//             }
//         }
//     }
//     trigger OnPreReport()
//     var
//         L_ErrorFound: Boolean;
//         L_ErrorText: Text[100];
//         L_PurchLine: Record "Purchase Line";
//         TakeWhseActvityLine: Record "Warehouse Activity Line";
//         WhseRcptLine: Record "Warehouse Receipt Line";
//     begin
//         if ((StartDate = 0D) OR (EndDate = 0D)) then begin
//             Error('Start Date and End Date must not be blank.');
//         end;

//         if ReturnReasonCode = '' then
//             Error('Return Reason Code must have value.');

//         G_PurchaseHeader.Reset();
//         G_PurchaseHeader.SetFilter("Document Date", '%1..%2', StartDate, EndDate);
//         if G_PurchaseHeader.FindSet() then begin
//             repeat
//                 //Delete Error Logs++
//                 Clear(L_ErrorFound);
//                 G_ErrorBuff.Reset();
//                 G_ErrorBuff.SetRange("Document Type", G_PurchaseHeader."Document Type");
//                 G_ErrorBuff.SetRange("Document No.", G_PurchaseHeader."No.");
//                 if G_ErrorBuff.FindSet() then
//                     G_ErrorBuff.DeleteAll();

//                 // //For 1st Error++
//                 // if L_ErrorFound = false then begin
//                 //     Clear(L_ErrorText);
//                 //     if (G_PurchaseHeader.Status <> G_PurchaseHeader.Status::Open) AND (G_PurchaseHeader.Status <> G_PurchaseHeader.Status::Released) then begin
//                 //         L_ErrorText := StrSubstNo('Status should not be %1', G_PurchaseHeader.Status);
//                 //         InsertErrorLogCanceledOrder(G_PurchaseHeader, L_ErrorText);
//                 //         L_ErrorFound := true;
//                 //     end;
//                 // end;

//                 //For 2nd Error++
//                 if L_ErrorFound = false then begin
//                     Clear(L_PurchLine);
//                     L_PurchLine.Reset();
//                     L_PurchLine.SetRange("Document Type", G_PurchaseHeader."Document Type");
//                     L_PurchLine.SetRange("Document No.", G_PurchaseHeader."No.");
//                     L_PurchLine.SetRange(Type, L_PurchLine.Type::Item);
//                     L_PurchLine.SetRange("PO Cancelled", false);
//                     if L_PurchLine.FindSet() then
//                         repeat
//                             //Check if warehouse Receipt line exist++
//                             Clear(L_ErrorText);
//                             WhseRcptLine.Reset();
//                             WhseRcptLine.SETRANGE("Source Document", WhseRcptLine."Source Document"::"Purchase Order");
//                             WhseRcptLine.SetRange("Source No.", L_PurchLine."Document No.");
//                             WhseRcptLine.SetRange("Source Line No.", L_PurchLine."Line No.");
//                             if WhseRcptLine.FindFirst() then begin
//                                 L_ErrorText := StrSubstNo('Unable to process ... Warehouse Receipt %1 exist for Order No.: %2 Line No.: %3', WhseRcptLine."No.", WhseRcptLine."Source No.", WhseRcptLine."Source Line No.");
//                             end;


//                             //Check Put Away Available++
//                             Clear(L_ErrorText);
//                             TakeWhseActvityLine.Reset();
//                             TakeWhseActvityLine.SetRange("Source Document", TakeWhseActvityLine."Source Document"::"Purchase Order");
//                             TakeWhseActvityLine.SetRange("Source No.", L_PurchLine."Document No.");
//                             TakeWhseActvityLine.SetRange("Source Line No.", L_PurchLine."Line No.");
//                             TakeWhseActvityLine.SetRange("Activity Type", TakeWhseActvityLine."Activity Type"::"Put-away");
//                             if not TakeWhseActvityLine.IsEmpty then begin
//                                 L_ErrorText := StrSubstNo('Warehouse putaway no. %1 exists: in Purchase Line Document Type= %2,Document No.= %3,Line No.=%4', TakeWhseActvityLine."No.", L_PurchLine."Document Type", L_PurchLine."Document No.", L_PurchLine."Line No.");
//                                 InsertErrorLogCanceledOrder(G_PurchaseHeader, L_ErrorText);
//                                 L_ErrorFound := true;
//                             end;
//                         until (L_PurchLine.Next() = 0) AND (L_ErrorFound = false);
//                 end;

//                 //For 3rd Error++
//                 //Check Invoice Quantity++
//                 if L_ErrorFound = false then begin
//                     Clear(L_ErrorText);
//                     L_PurchLine.Reset();
//                     L_PurchLine.SetRange("Document Type", G_PurchaseHeader."Document Type");
//                     L_PurchLine.SetRange("Document No.", G_PurchaseHeader."No.");
//                     //L_PurchLine.SetRange(Type, L_PurchLine.Type::Item);
//                     L_PurchLine.SetRange("PO Cancelled", false);
//                     if L_PurchLine.FindSet() then begin
//                         repeat
//                             if L_PurchLine."Qty. Rcd. Not Invoiced" > 0 then begin
//                                 L_ErrorText := StrSubstNo('Total %1 quantity received but invoiced quantity %2.Invoice is pending for Order No. : %3 Line No. : %4 ', L_PurchLine."Quantity Received", L_PurchLine."Quantity Invoiced", L_PurchLine."Document No.", L_PurchLine."Line No.");
//                                 InsertErrorLogCanceledOrder(G_PurchaseHeader, L_ErrorText);
//                                 L_ErrorFound := true;
//                             end;
//                         until (L_PurchLine.Next() = 0) AND (L_ErrorFound = false);
//                     end;
//                 end;

//             until G_PurchaseHeader.Next() = 0;
//         end;
//     end;

//     trigger OnPostReport()
//     begin
//         //Message('Done.');
//     end;

//     local procedure InsertErrorLogCanceledOrder(PurhaseHeader: Record "Purchase Header"; ErrorText: Text)
//     var
//         L_PurchaseHeader: Record "Purchase Header";
//     begin
//         G_ErrorBuff.Init();
//         if G_ErrorBuff.FindLast() then
//             G_ErrorBuff."Entry No." += 1
//         Else
//             G_ErrorBuff."Entry No." := 1;
//         G_ErrorBuff."Clearance Error" := ErrorText + PurchaseHeader."No.";
//         G_ErrorBuff."Created Date" := Today;
//         G_ErrorBuff.Insert();

//         L_PurchaseHeader.Reset();
//         L_PurchaseHeader.SetFilter("Document Type", '%1', L_PurchaseHeader."Document Type"::Order);
//         L_PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
//         if L_PurchaseHeader.FindFirst() then begin
//             L_PurchaseHeader."Error exist" := true;
//             L_PurchaseHeader.Modify();
//         end;
//     end;

//     local procedure DeletePurchaseHeader(L_PurchaseHeader: Record "Purchase Header")
//     begin
//         if L_PurchaseHeader."PO Cancelled" = true then
//             L_PurchaseHeader.Delete(true);
//     end;

//     local procedure DeleteReservationEntries(_PurchaseLine: Record "Purchase Line")
//     var
//         L_Reservation: Record "Reservation Entry";
//     begin
//         L_Reservation.Reset();
//         L_Reservation.SetRange("Source Type", 39);
//         L_Reservation.SetRange("Source Subtype", 1);
//         L_Reservation.SetRange("Source ID", _PurchaseLine."Document No.");
//         L_Reservation.SetRange("Source Ref. No.", _PurchaseLine."Line No.");
//         if L_Reservation.FindSet() then
//             L_Reservation.DeleteAll();
//     end;

//     var
//         StartDate: Date;
//         EndDate: Date;
//         ReturnReasonCode: Code[50];
//         G_PurchaseHeader: Record "Purchase Header";
//         G_PurchaseLine: Record "Purchase Line";
//         G_ErrorBuff: Record "Error Log";
//         G_WhseRcptLine: Record "Warehouse Receipt Line";
// }
