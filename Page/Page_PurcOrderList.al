pageextension 70705 POLists extends "Purchase Order List"
{
    layout
    {
        // Add changes to page layout here
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
        [InDataSet]
        VisibleonCancel: Boolean;
        PurNPay: Record "Purchases & Payables Setup";

}