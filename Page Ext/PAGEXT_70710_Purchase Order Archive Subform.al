pageextension 70710 "ROC Purchase Archive Subform" extends "Purchase Order Archive Subform"
{
    layout
    {
        addafter(Quantity)
        {
            field("Original Order Quantity"; Rec."Original Order Quantity")
            {
                ApplicationArea = All;
            }
        }
        addlast(Control1)
        {
            field("Cancel Reason code"; Rec."Cancel Reason code")
            {
                ApplicationArea = all;
                Visible = VisibleonCancel;
            }
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

    var
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