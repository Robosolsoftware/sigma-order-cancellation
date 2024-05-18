pageextension 70708 "ROC SalesOrder Archive Subform" extends "Sales Order Archive Subform"
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
                Caption = 'SO Cancelled';
                ApplicationArea = All;
                Editable = false;
                Visible = VisibleOnCancel;
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

    var
        VisibleOnCancel: Boolean;
        SalesRecSet: Record "Sales & Receivables Setup";

    trigger OnOpenPage()
    begin
        clear(VisibleOnCancel);
        SalesRecSet.Get();
        if not SalesRecSet."Cancel Sales Order Feature" then
            VisibleOnCancel := false
        else
            VisibleOnCancel := true;
    end;
}