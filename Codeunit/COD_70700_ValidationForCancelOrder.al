codeunit 70700 ValidationOnCancelOrder
{
    [EventSubscriber(ObjectType::Table, Database::"Warehouse Receipt Line", 'OnBeforeConfirmDelete', '', false, false)]
    local procedure OnBeforeConfirmDelete(var SkipConfirm: Boolean; var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
        if WarehouseReceiptLine."Request For Cancel" = true then
            SkipConfirm := true;
    end;

    // [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterInsertEvent', '', false, false)]
    // local procedure CheckPurchaseLineInsert(var Rec: Record "Purchase Line")
    // var
    //     RecPurchaseHeader: Record "Purchase Header";
    // begin
    //     RecPurchaseHeader.Reset();
    //     RecPurchaseHeader.SetRange("No.", Rec."Document No.");
    //     if RecPurchaseHeader.FindFirst() then begin
    //         if RecPurchaseHeader."PO Cancelled" = true then begin
    //             Error('Purchase Order/Line cancelled. Insert not allowed');
    //         end;
    //     end;
    // end;

    // [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnBeforeDeleteEvent', '', false, false)]
    // local procedure PurchLineDelete(var Rec: Record "Purchase Line")
    // var
    //     RecPurchaseHeader: Record "Purchase Header";
    // begin

    //     if Rec."PO Cancelled" = true then begin
    //         Error('Purchase Order/Line cancelled. Delete not allowed');
    //     end;

    //     RecPurchaseHeader.Reset();
    //     RecPurchaseHeader.SetRange("No.", Rec."Document No.");
    //     if RecPurchaseHeader.FindFirst() then begin
    //         if RecPurchaseHeader."PO Cancelled" = true then begin
    //             Error('Purchase Order/Line cancelled. Delete not allowed');
    //         end;
    //     end;
    // end;

    // [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterModifyEvent', '', false, false)]
    // local procedure CheckPurchaseLinemodify(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line")
    // var
    //     RecPurchaseHeader: Record "Purchase Header";
    //     RecPurchasline: Record "Purchase Line";
    // begin

    //     // if xRec.Cancel = true then begin
    //     //     Error('Access Denied');
    //     // end;
    //     RecPurchasline.Reset();
    //     RecPurchasline.SetRange("Document No.", Rec."Document No.");
    //     RecPurchasline.SetRange("Document Type", Rec."Document Type");
    //     RecPurchasline.SetRange("Line No.", Rec."Line No.");
    //     if RecPurchasline.FindFirst() then begin
    //         if RecPurchasline."PO Cancelled" = true then begin
    //             // Error('Access Denied');
    //         end;
    //     end;


    //     RecPurchaseHeader.Reset();
    //     RecPurchaseHeader.SetRange("No.", Rec."Document No.");
    //     if RecPurchaseHeader.FindFirst() then begin
    //         //if RecPurchaseHeader."PO Cancelled" = true then begin
    //         // Error('Purchase Order/Line cancelled. Modify not allowed');//Commented this line because it is causing issue when changing the global dimension
    //     end;
    // end;
}