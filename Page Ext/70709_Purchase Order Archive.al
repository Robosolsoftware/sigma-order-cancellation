pageextension 70709 "ROC Purchase Order Archive" extends "Purchase Order Archive"
{
    layout
    {
        // Add changes to page layout here
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
        // Add changes to page actions here
    }

    var
        myInt: Integer;
        VisibleonCancel: Boolean;
        PurchNPay: Record "Purchases & Payables Setup";


    trigger OnOpenPage()
    begin
        Clear(VisibleonCancel);
        PurchNPay.Get();
        if PurchNPay."Cancel Purchase Order Feature" then
            VisibleonCancel := true
        else
            VisibleonCancel := false;
    end;
}