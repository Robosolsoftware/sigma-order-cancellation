pageextension 70705 POLists extends "Purchase Order List"
{
    layout
    {
        addafter("Location Code")
        {
            field("PO Cancelled"; Rec."PO Cancelled")
            {
                ApplicationArea = all;
                Visible = VisibleonCancel;
            }
            field("PO Cancellation Date"; Rec."PO Cancellation Date")
            {
                ApplicationArea = all;
                Visible = VisibleonCancel;
            }
            field("PO Cancelled By"; Rec."PO Cancelled By")
            {
                ApplicationArea = all;
                Visible = VisibleonCancel;
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
                        L_PurchaseHeader: Record "Purchase Header";
                        PurchaseAndPayableSetup: Record "Purchases & Payables Setup";
                        REP_CancelPurchaseOrder: Report "Cancel Purchase Order";
                    begin
                        //Check Setup++
                        PurchaseAndPayableSetup.Get();
                        if PurchaseAndPayableSetup."Cancel Purchase Order Feature" = false then
                            Error('Enable Cancel Purchase order feature on Purchase & Payables setup to unlock this feature');


                        //Confimation Box++
                        if not Confirm('Do you want to cancel this order?', false) then
                            exit;

                        Clear(REP_CancelPurchaseOrder);
                        L_PurchaseHeader.Reset();
                        CurrPage.SetSelectionFilter(L_PurchaseHeader);
                        if L_PurchaseHeader.FindSet() then begin
                            REP_CancelPurchaseOrder.SetTableView(L_PurchaseHeader);
                            REP_CancelPurchaseOrder.Run();
                        end;

                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        PurNPay.Get();
        if not PurNPay."Cancel Purchase Order Feature" then
            VisibleonCancel := false
        else
            VisibleonCancel := true;
    end;

    var
        VisibleonCancel: Boolean;
        PurNPay: Record "Purchases & Payables Setup";
}